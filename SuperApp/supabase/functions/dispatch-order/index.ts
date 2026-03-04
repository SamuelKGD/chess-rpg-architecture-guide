// dispatch-order/index.ts
// Supabase Edge Function — Dispatching de la commande aux vendeurs
// Déployé via : supabase functions deploy dispatch-order

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Stripe from "https://esm.sh/stripe@14.11.0?target=deno";

interface DispatchOrderRequest {
  order_id: string;
  payment_intent_id: string;
}

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Client Supabase avec les droits service_role pour les opérations d'écriture
  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const supabaseUser = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } }
  );

  // Vérification de l'identité
  const { data: { user }, error: authError } = await supabaseUser.auth.getUser();
  if (authError || !user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  let body: DispatchOrderRequest;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Vérification du paiement Stripe
  const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
    apiVersion: "2023-10-16",
  });

  const paymentIntent = await stripe.paymentIntents.retrieve(body.payment_intent_id);
  if (paymentIntent.status !== "succeeded") {
    return new Response(
      JSON.stringify({ error: "Payment not confirmed", payment_status: paymentIntent.status }),
      { status: 402, headers: { "Content-Type": "application/json" } }
    );
  }

  // Récupération de la commande et des sous-commandes
  const { data: order, error: orderError } = await supabaseAdmin
    .from("orders")
    .select(`
      *,
      sub_orders (
        id,
        vendor_id,
        subtotal,
        vendors (
          id, name, stripe_account_id, address, latitude, longitude
        )
      )
    `)
    .eq("id", body.order_id)
    .single();

  if (orderError || !order) {
    return new Response(JSON.stringify({ error: "Order not found" }), {
      status: 404,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (order.status !== "pending") {
    return new Response(
      JSON.stringify({ error: "Order already dispatched", current_status: order.status }),
      { status: 409, headers: { "Content-Type": "application/json" } }
    );
  }

  // Mise à jour du statut global de la commande
  await supabaseAdmin
    .from("orders")
    .update({ status: "confirmed", stripe_payment_intent_id: body.payment_intent_id })
    .eq("id", body.order_id);

  const dispatchResults = [];

  // Boucle de dispatch : 1 sous-commande par vendeur
  for (const subOrder of order.sub_orders) {
    const vendor = subOrder.vendors;

    // 1. Virement Stripe Connect vers le vendeur (90% du sous-total)
    let stripeTransferId: string | null = null;
    if (vendor.stripe_account_id) {
      try {
        const transfer = await stripe.transfers.create({
          amount: Math.round(subOrder.subtotal * 0.90 * 100), // en centimes
          currency: "eur",
          destination: vendor.stripe_account_id,
          transfer_group: body.order_id,
          metadata: { sub_order_id: subOrder.id, order_id: body.order_id },
        });
        stripeTransferId = transfer.id;
      } catch (transferError) {
        console.error(`Stripe transfer failed for vendor ${vendor.id}:`, transferError);
      }
    }

    // 2. Demande de livraison Stuart API
    let trackingUrl: string | null = null;
    let driverInfo: Record<string, unknown> | null = null;

    try {
      const stuartResponse = await fetch(
        `${Deno.env.get("STUART_API_URL")}/v2/jobs`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${Deno.env.get("STUART_API_KEY")}`,
          },
          body: JSON.stringify({
            job: {
              transport_type: "bike",
              pickups: [{
                address: vendor.address,
                comment: `Commande EduMarket #${body.order_id.slice(0, 8)}`,
                contact: { firstname: vendor.name, phone: "" },
              }],
              dropoffs: [{
                address: order.delivery_address,
                comment: order.notes ?? "",
                contact: { firstname: "Étudiant", phone: "" },
                end_customer_time_window_start: new Date().toISOString(),
                end_customer_time_window_end: new Date(
                  Date.now() + 90 * 60 * 1000
                ).toISOString(),
              }],
            },
          }),
        }
      );

      if (stuartResponse.ok) {
        const stuartJob = await stuartResponse.json();
        trackingUrl = stuartJob.tracking_url ?? null;
        driverInfo = stuartJob.deliveries?.[0]?.driver ?? null;
      }
    } catch (stuartError) {
      console.error(`Stuart dispatch failed for sub_order ${subOrder.id}:`, stuartError);
    }

    // 3. Mise à jour de la sous-commande
    await supabaseAdmin
      .from("sub_orders")
      .update({
        status: "confirmed",
        stripe_transfer_id: stripeTransferId,
        tracking_url: trackingUrl,
        driver_info: driverInfo,
      })
      .eq("id", subOrder.id);

    dispatchResults.push({
      sub_order_id: subOrder.id,
      vendor_id: vendor.id,
      vendor_name: vendor.name,
      stripe_transfer: stripeTransferId ? "success" : "skipped",
      delivery: trackingUrl ? "dispatched" : "pending_manual",
      tracking_url: trackingUrl,
    });
  }

  return new Response(
    JSON.stringify({
      order_id: body.order_id,
      status: "confirmed",
      dispatched_sub_orders: dispatchResults.length,
      results: dispatchResults,
    }),
    { status: 200, headers: { "Content-Type": "application/json" } }
  );
});
