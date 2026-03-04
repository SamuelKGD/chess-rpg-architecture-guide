# 💳 Flux de Paiement Hybride — Izly + CB (Stripe Connect)

## Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Diagramme de Décision](#diagramme-de-décision)
3. [Flux 1 : Paiement Izly Seul](#flux-1--paiement-izly-seul)
4. [Flux 2 : Paiement CB Seul (Stripe)](#flux-2--paiement-cb-seul-stripe)
5. [Flux 3 : Split Bill (Izly + CB)](#flux-3--split-bill-izly--cb)
6. [Gestion des Erreurs & Rollback](#gestion-des-erreurs--rollback)
7. [Architecture Backend](#architecture-backend)

---

## Vue d'Ensemble

Le module de paiement hybride gère trois scénarios :

| Scénario | Quand | Fournisseur(s) |
|----------|-------|-----------------|
| **Izly seul** | Repas RU, solde suffisant | Izly (S-Money) |
| **CB seule** | Achats hors CROUS, pas de solde Izly | Stripe Connect |
| **Split Bill** | Solde Izly insuffisant pour couvrir le total | Izly + Stripe |

---

## Diagramme de Décision

```
                    Utilisateur initie un paiement
                              │
                              ▼
                    ┌─────────────────┐
                    │  Type de service │
                    └────────┬────────┘
                             │
                 ┌───────────┼───────────┐
                 ▼           ▼           ▼
            Repas RU     Livraison    Marketplace
                 │           │           │
                 ▼           ▼           ▼
           Izly requis   CB ou Izly   CB uniquement
                 │           │           │
                 ▼           │           │
        ┌────────────┐      │           │
        │ Solde Izly │      │           │
        │ suffisant? │      │           │
        └─────┬──────┘      │           │
              │              │           │
         ┌────┴────┐        │           │
         ▼         ▼        │           │
        OUI       NON       │           │
         │         │        │           │
         ▼         ▼        ▼           ▼
    ┌─────────┐ ┌──────────────┐  ┌──────────┐
    │  Izly   │ │  Split Bill  │  │ Stripe   │
    │  seul   │ │ (Izly + CB)  │  │ Connect  │
    └─────────┘ └──────────────┘  └──────────┘
```

---

## Flux 1 : Paiement Izly Seul

### Cas d'usage
Repas au Restaurant Universitaire avec solde Izly suffisant.

### Séquence

```
Étudiant              App Flutter            Backend Supabase          Izly (Webview)
   │                      │                        │                        │
   │  1. Commande RU      │                        │                        │
   │     (3.30€)          │                        │                        │
   │─────────────────────>│                        │                        │
   │                      │                        │                        │
   │                      │  2. POST /orders       │                        │
   │                      │  { type: 'ru_meal',    │                        │
   │                      │    amount: 3.30 }      │                        │
   │                      │───────────────────────>│                        │
   │                      │                        │                        │
   │                      │  3. { order_id,        │                        │
   │                      │    payment_url }       │                        │
   │                      │<──────────────────────│                        │
   │                      │                        │                        │
   │  4. Webview Izly     │                        │                        │
   │<────────────────────│                        │                        │
   │                      │                        │                        │
   │  5. Login + Confirme │                        │                        │
   │─────────────────────────────────────────────────────────────────────>│
   │                      │                        │                        │
   │  6. Callback OK      │                        │                        │
   │<───────────────────────────────────────────────────────────────────│
   │                      │                        │                        │
   │                      │  7. POST /payments     │                        │
   │                      │     /confirm-izly      │                        │
   │                      │───────────────────────>│                        │
   │                      │                        │  8. Valide             │
   │                      │                        │─────────────────────>│
   │                      │                        │      ✅                │
   │                      │                        │<────────────────────│
   │                      │                        │                        │
   │                      │  9. { success }        │                        │
   │                      │<──────────────────────│                        │
   │                      │                        │                        │
   │  10. ✅ Repas payé   │                        │                        │
   │<────────────────────│                        │                        │
```

---

## Flux 2 : Paiement CB Seul (Stripe)

### Cas d'usage
Achat sur la marketplace ou livraison sans utiliser Izly.

### Séquence

```
Étudiant              App Flutter            Backend Supabase          Stripe
   │                      │                        │                     │
   │  1. Commande         │                        │                     │
   │     (12.50€)         │                        │                     │
   │─────────────────────>│                        │                     │
   │                      │                        │                     │
   │                      │  2. POST /orders       │                     │
   │                      │───────────────────────>│                     │
   │                      │                        │                     │
   │                      │                        │  3. Create          │
   │                      │                        │  PaymentIntent      │
   │                      │                        │───────────────────>│
   │                      │                        │                     │
   │                      │                        │  4. { client_secret │
   │                      │                        │       pi_xxx }      │
   │                      │                        │<──────────────────│
   │                      │                        │                     │
   │                      │  5. { client_secret }  │                     │
   │                      │<──────────────────────│                     │
   │                      │                        │                     │
   │  6. Stripe Payment   │                        │                     │
   │     Sheet            │                        │                     │
   │<────────────────────│                        │                     │
   │                      │                        │                     │
   │  7. CB + Confirme    │                        │                     │
   │────────────────────────────────────────────────────────────────>│
   │                      │                        │                     │
   │                      │                        │  8. Webhook         │
   │                      │                        │  payment_intent     │
   │                      │                        │  .succeeded         │
   │                      │                        │<──────────────────│
   │                      │                        │                     │
   │                      │  9. { success }        │                     │
   │                      │<──────────────────────│                     │
   │                      │                        │                     │
   │  10. ✅ Payé         │                        │                     │
   │<────────────────────│                        │                     │
```

---

## Flux 3 : Split Bill (Izly + CB)

### Cas d'usage
Commande de 15€, solde Izly de 8€ → paiement partiel Izly (8€) + complément CB (7€).

### Séquence Détaillée

```
Étudiant              App Flutter            Backend Supabase       Izly         Stripe
   │                      │                        │                  │             │
   │  1. Commande 15€     │                        │                  │             │
   │─────────────────────>│                        │                  │             │
   │                      │                        │                  │             │
   │                      │  2. POST /orders       │                  │             │
   │                      │  { amount: 15.00,      │                  │             │
   │                      │    split: true }       │                  │             │
   │                      │───────────────────────>│                  │             │
   │                      │                        │                  │             │
   │                      │  3. Calcul split :     │                  │             │
   │                      │  izly=8€, stripe=7€    │                  │             │
   │                      │  Crée 2 payments       │                  │             │
   │                      │  status='pending'      │                  │             │
   │                      │                        │                  │             │
   │                      │  4. { order_id,        │                  │             │
   │                      │    izly_amount: 8,     │                  │             │
   │                      │    stripe_amount: 7,   │                  │             │
   │                      │    izly_url,           │                  │             │
   │                      │    stripe_secret }     │                  │             │
   │                      │<──────────────────────│                  │             │
   │                      │                        │                  │             │
   │  ═══════════════════════════════════════════════════════════════════════════   │
   │  ║ ÉTAPE A : Paiement Izly (8€)                                          ║   │
   │  ═══════════════════════════════════════════════════════════════════════════   │
   │                      │                        │                  │             │
   │  5. Webview Izly     │                        │                  │             │
   │<────────────────────│                        │                  │             │
   │  6. Confirme 8€      │                        │                  │             │
   │──────────────────────────────────────────────────────────────>│             │
   │  7. Callback OK      │                        │                  │             │
   │<────────────────────────────────────────────────────────────│             │
   │                      │                        │                  │             │
   │                      │  8. Confirm izly part  │                  │             │
   │                      │───────────────────────>│                  │             │
   │                      │                        │  9. Valide       │             │
   │                      │                        │─────────────────>│             │
   │                      │                        │     ✅            │             │
   │                      │                        │<────────────────│             │
   │                      │                        │                  │             │
   │                      │  10. { izly: 'ok' }    │                  │             │
   │                      │<──────────────────────│                  │             │
   │                      │                        │                  │             │
   │  ═══════════════════════════════════════════════════════════════════════════   │
   │  ║ ÉTAPE B : Complément CB (7€)                                           ║   │
   │  ═══════════════════════════════════════════════════════════════════════════   │
   │                      │                        │                  │             │
   │  11. Stripe Sheet    │                        │                  │             │
   │<────────────────────│                        │                  │             │
   │  12. Confirme CB 7€  │                        │                  │             │
   │────────────────────────────────────────────────────────────────────────────>│
   │                      │                        │                  │             │
   │                      │                        │  13. Webhook     │             │
   │                      │                        │  succeeded       │             │
   │                      │                        │<───────────────────────────│
   │                      │                        │                  │             │
   │  ═══════════════════════════════════════════════════════════════════════════   │
   │  ║ FINALISATION                                                           ║   │
   │  ═══════════════════════════════════════════════════════════════════════════   │
   │                      │                        │                  │             │
   │                      │  14. Les 2 paiements   │                  │             │
   │                      │  confirmés → order     │                  │             │
   │                      │  status = 'paid'       │                  │             │
   │                      │                        │                  │             │
   │                      │  15. { success }       │                  │             │
   │                      │<──────────────────────│                  │             │
   │                      │                        │                  │             │
   │  16. ✅ 15€ payés    │                        │                  │             │
   │  (8€ Izly + 7€ CB)   │                        │                  │             │
   │<────────────────────│                        │                  │             │
```

---

## Gestion des Erreurs & Rollback

### Scénario : Izly OK mais Stripe Échoue

```
Backend détecte : payment_izly.status = 'confirmed'
                  payment_stripe.status = 'failed'
                         │
                         ▼
              ┌──────────────────────┐
              │  SAGA COMPENSATION   │
              │                      │
              │  1. Initier refund   │
              │     Izly (8€)        │
              │                      │
              │  2. Mettre order     │
              │     status='failed'  │
              │                      │
              │  3. Logger audit     │
              │                      │
              │  4. Notifier user    │
              │     (in-app)         │
              └──────────────────────┘
```

### Scénario : Stripe OK mais Izly Échoue

```
Backend détecte : payment_izly.status = 'failed'
                  payment_stripe.status = 'confirmed'
                         │
                         ▼
              ┌──────────────────────┐
              │  SAGA COMPENSATION   │
              │                      │
              │  1. Initier refund   │
              │     Stripe (7€)      │
              │                      │
              │  2. Mettre order     │
              │     status='failed'  │
              │                      │
              │  3. Logger audit     │
              │                      │
              │  4. Notifier user    │
              │     (in-app)         │
              └──────────────────────┘
```

### Table de Gestion des États

| État Izly | État Stripe | Action |
|-----------|-------------|--------|
| ✅ confirmed | ✅ confirmed | ✅ Order = paid |
| ✅ confirmed | ❌ failed | ↩️ Refund Izly, Order = failed |
| ❌ failed | ✅ confirmed | ↩️ Refund Stripe, Order = failed |
| ❌ failed | ❌ failed | Order = failed, notifier |
| ⏳ pending | ✅ confirmed | ⏳ Attendre 5min, puis refund Stripe si timeout |
| ✅ confirmed | ⏳ pending | ⏳ Attendre 5min, puis refund Izly si timeout |

---

## Architecture Backend

### Edge Function : Création de Commande Split

```typescript
// supabase/functions/create-split-order/index.ts

interface SplitOrderRequest {
  amount: number;
  izly_amount: number;
  order_type: 'ru_meal' | 'delivery' | 'marketplace';
}

serve(async (req) => {
  const { amount, izly_amount, order_type } = await req.json();
  const stripe_amount = amount - izly_amount;

  // 1. Créer l'order
  const { data: order } = await supabase.from('orders').insert({
    user_id: userId,
    total_amount: amount,
    izly_amount,
    stripe_amount,
    order_type,
    status: 'payment_processing',
  }).select().single();

  // 2. Créer les 2 entrées payments
  await supabase.from('payments').insert([
    {
      order_id: order.id,
      user_id: userId,
      provider: 'izly',
      amount: izly_amount,
      status: 'pending',
    },
    {
      order_id: order.id,
      user_id: userId,
      provider: 'stripe',
      amount: stripe_amount,
      status: 'pending',
    },
  ]);

  // 3. Créer le PaymentIntent Stripe
  const paymentIntent = await stripe.paymentIntents.create({
    amount: Math.round(stripe_amount * 100),
    currency: 'eur',
    metadata: { order_id: order.id },
  });

  // 4. Générer l'URL de paiement Izly
  const izlyUrl = generateSignedIzlyUrl(order.id, izly_amount);

  return new Response(JSON.stringify({
    order_id: order.id,
    izly_amount,
    stripe_amount,
    izly_payment_url: izlyUrl,
    stripe_client_secret: paymentIntent.client_secret,
  }));
});
```

### Webhook : Vérification de Complétion Split

```typescript
// supabase/functions/check-split-completion/index.ts

// Appelé après chaque confirmation de paiement (Izly ou Stripe)
async function checkSplitCompletion(orderId: string) {
  const { data: payments } = await supabase
    .from('payments')
    .select('*')
    .eq('order_id', orderId);

  const allConfirmed = payments.every(p => p.status === 'confirmed');
  const anyFailed = payments.some(p => p.status === 'failed');

  if (allConfirmed) {
    // Tous les paiements confirmés → commande payée
    await supabase.from('orders')
      .update({ status: 'paid' })
      .eq('id', orderId);
  } else if (anyFailed) {
    // Au moins un paiement a échoué → rollback
    await initiateSagaCompensation(orderId, payments);
  }
  // Sinon : encore en attente
}
```
