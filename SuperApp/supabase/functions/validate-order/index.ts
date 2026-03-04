// validate-order/index.ts
// Supabase Edge Function — Validation d'une commande
// Déployé via : supabase functions deploy validate-order

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Stripe from "https://esm.sh/stripe@14.11.0?target=deno";

interface OrderItem {
  product_id: string;
  quantity: number;
  customization?: Record<string, unknown>;
}

interface ValidateOrderRequest {
  items: OrderItem[];
  delivery_address: string;
  delivery_lat: number;
  delivery_lng: number;
  promo_code?: string;
}

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  // Récupération du token JWT de l'utilisateur
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } }
  );

  // Vérification de l'utilisateur et du statut étudiant
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const { data: userProfile, error: profileError } = await supabase
    .from("users")
    .select("id, is_student_verified")
    .eq("auth_id", user.id)
    .single();

  if (profileError || !userProfile?.is_student_verified) {
    return new Response(
      JSON.stringify({ error: "Student verification required" }),
      { status: 403, headers: { "Content-Type": "application/json" } }
    );
  }

  // Parsing du body
  let body: ValidateOrderRequest;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (!body.items || body.items.length === 0) {
    return new Response(
      JSON.stringify({ error: "Order must contain at least one item" }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }

  // Vérification de la disponibilité et du prix de chaque produit
  const productIds = body.items.map((item) => item.product_id);
  const { data: products, error: productsError } = await supabase
    .from("catalog")
    .select("id, vendor_id, name, price, is_available, stock_count")
    .in("id", productIds);

  if (productsError) {
    return new Response(
      JSON.stringify({ error: "Failed to fetch products" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  const productsMap = new Map(products!.map((p) => [p.id, p]));
  const validationErrors: string[] = [];
  let rawTotal = 0;

  // Regroupement des items par vendeur
  const vendorGroups = new Map<string, { items: OrderItem[]; subtotal: number }>();

  for (const item of body.items) {
    const product = productsMap.get(item.product_id);
    if (!product) {
      validationErrors.push(`Product ${item.product_id} not found`);
      continue;
    }
    if (!product.is_available) {
      validationErrors.push(`Product "${product.name}" is not available`);
      continue;
    }
    if (product.stock_count !== null && product.stock_count < item.quantity) {
      validationErrors.push(
        `Insufficient stock for "${product.name}" (available: ${product.stock_count})`
      );
      continue;
    }
    if (item.quantity <= 0) {
      validationErrors.push(`Invalid quantity for "${product.name}"`);
      continue;
    }

    const itemTotal = product.price * item.quantity;
    rawTotal += itemTotal;

    const vendorId = product.vendor_id;
    if (!vendorGroups.has(vendorId)) {
      vendorGroups.set(vendorId, { items: [], subtotal: 0 });
    }
    const group = vendorGroups.get(vendorId)!;
    group.items.push(item);
    group.subtotal += itemTotal;
  }

  if (validationErrors.length > 0) {
    return new Response(
      JSON.stringify({ error: "Validation failed", details: validationErrors }),
      { status: 422, headers: { "Content-Type": "application/json" } }
    );
  }

  // Application du code promo
  let discountAmount = 0;
  if (body.promo_code) {
    const { data: promo } = await supabase
      .from("promo_codes")
      .select("*")
      .eq("code", body.promo_code.toUpperCase())
      .eq("is_active", true)
      .single();

    if (promo) {
      const now = new Date();
      const validFrom = new Date(promo.valid_from);
      const validUntil = promo.valid_until ? new Date(promo.valid_until) : null;
      const usesOk = !promo.max_uses || promo.current_uses < promo.max_uses;

      if (
        now >= validFrom &&
        (!validUntil || now <= validUntil) &&
        rawTotal >= promo.min_order_amount &&
        usesOk
      ) {
        if (promo.discount_type === "percentage") {
          discountAmount = (rawTotal * promo.discount_value) / 100;
        } else {
          discountAmount = Math.min(promo.discount_value, rawTotal);
        }
      }
    }
  }

  // Calcul des frais de livraison via la fonction delivery-fee
  const deliveryFeeResponse = await fetch(
    `${Deno.env.get("SUPABASE_URL")}/functions/v1/delivery-fee`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: authHeader,
        apikey: Deno.env.get("SUPABASE_ANON_KEY")!,
      },
      body: JSON.stringify({
        vendor_ids: Array.from(vendorGroups.keys()),
        delivery_lat: body.delivery_lat,
        delivery_lng: body.delivery_lng,
      }),
    }
  );

  const { total_delivery_fee } = await deliveryFeeResponse.json();

  // Frais plateforme (5% du total commande)
  const platformFee = Math.round(rawTotal * 0.05 * 100) / 100;
  const totalAmount = rawTotal - discountAmount + total_delivery_fee + platformFee;

  // Création du PaymentIntent Stripe
  const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
    apiVersion: "2023-10-16",
  });

  const paymentIntent = await stripe.paymentIntents.create({
    amount: Math.round(totalAmount * 100), // en centimes
    currency: "eur",
    metadata: {
      user_id: userProfile.id,
      vendor_count: vendorGroups.size.toString(),
    },
  });

  return new Response(
    JSON.stringify({
      payment_intent_client_secret: paymentIntent.client_secret,
      order_summary: {
        raw_total: rawTotal,
        discount_amount: discountAmount,
        delivery_fee: total_delivery_fee,
        platform_fee: platformFee,
        total_amount: totalAmount,
        vendor_groups: Array.from(vendorGroups.entries()).map(([vendorId, group]) => ({
          vendor_id: vendorId,
          subtotal: group.subtotal,
          item_count: group.items.length,
        })),
      },
    }),
    { status: 200, headers: { "Content-Type": "application/json" } }
  );
});
