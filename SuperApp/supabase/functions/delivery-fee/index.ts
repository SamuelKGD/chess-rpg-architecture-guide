// delivery-fee/index.ts
// Supabase Edge Function — Calcul dynamique des frais de livraison
// Déployé via : supabase functions deploy delivery-fee

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface DeliveryFeeRequest {
  vendor_ids: string[];
  delivery_lat: number;
  delivery_lng: number;
}

interface VendorDistance {
  vendor_id: string;
  distance_km: number;
  fee: number;
}

/** Calcule la distance Haversine en kilomètres entre deux points GPS */
function haversineDistance(
  lat1: number, lng1: number,
  lat2: number, lng2: number
): number {
  const R = 6371; // Rayon Terre en km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
    Math.cos((lat2 * Math.PI) / 180) *
    Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/** Calcule le frais de livraison selon la distance
 *  Barème :
 *  - 0-2 km   : 1.99 €
 *  - 2-5 km   : 2.99 €
 *  - 5-10 km  : 3.99 €
 *  - > 10 km  : 4.99 €
 */
function computeDeliveryFeeForDistance(distanceKm: number): number {
  if (distanceKm <= 2) return 1.99;
  if (distanceKm <= 5) return 2.99;
  if (distanceKm <= 10) return 3.99;
  return 4.99;
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

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } }
  );

  let body: DeliveryFeeRequest;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (!body.vendor_ids?.length || body.delivery_lat == null || body.delivery_lng == null) {
    return new Response(
      JSON.stringify({ error: "vendor_ids, delivery_lat and delivery_lng are required" }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }

  // Récupération des coordonnées GPS des vendeurs
  const { data: vendors, error } = await supabase
    .from("vendors")
    .select("id, latitude, longitude")
    .in("id", body.vendor_ids);

  if (error) {
    return new Response(
      JSON.stringify({ error: "Failed to fetch vendor locations" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  const distances: VendorDistance[] = [];
  let total_delivery_fee = 0;

  for (const vendor of vendors ?? []) {
    if (vendor.latitude == null || vendor.longitude == null) {
      // Frais par défaut si pas de coordonnées
      distances.push({ vendor_id: vendor.id, distance_km: 0, fee: 2.99 });
      total_delivery_fee += 2.99;
      continue;
    }

    const distanceKm = haversineDistance(
      vendor.latitude, vendor.longitude,
      body.delivery_lat, body.delivery_lng
    );
    const fee = computeDeliveryFeeForDistance(distanceKm);

    distances.push({
      vendor_id: vendor.id,
      distance_km: Math.round(distanceKm * 100) / 100,
      fee,
    });
    total_delivery_fee += fee;
  }

  // Arrondi à 2 décimales
  total_delivery_fee = Math.round(total_delivery_fee * 100) / 100;

  return new Response(
    JSON.stringify({
      total_delivery_fee,
      breakdown: distances,
    }),
    { status: 200, headers: { "Content-Type": "application/json" } }
  );
});
