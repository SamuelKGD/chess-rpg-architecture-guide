# 🔐 IZLY_INTEGRATION.md — Guide d'Intégration Izly & Authentification Tierce Sécurisée

## Table des Matières

1. [Contexte Izly](#contexte-izly)
2. [Stratégie d'Intégration](#stratégie-dintégration)
3. [Authentification Tierce Sécurisée](#authentification-tierce-sécurisée)
4. [Flux de Paiement Izly (Webview)](#flux-de-paiement-izly-webview)
5. [Flux de Paiement Izly (API S-Money)](#flux-de-paiement-izly-api-s-money)
6. [Sécurité & Bonnes Pratiques](#sécurité--bonnes-pratiques)
7. [Gestion des Erreurs](#gestion-des-erreurs)
8. [Faisabilité & Roadmap](#faisabilité--roadmap)

---

## Contexte Izly

**Izly** est le système de paiement du réseau CROUS, opéré par **S-Money** (filiale de **BPCE**). Il permet aux étudiants de payer les repas universitaires et certains services campus.

| Caractéristique | Détail |
|-----------------|--------|
| Opérateur | S-Money (groupe BPCE) |
| Cible | Étudiants inscrits au CROUS |
| Usages | Repas RU, distributeurs, services campus |
| Authentification | Identifiants Izly (email + mot de passe) |
| API publique | ❌ Non disponible publiquement |
| Webview | ✅ Portail web accessible (mon-espace.izly.fr) |

### Contraintes Techniques

- L'API S-Money n'est pas ouverte : un partenariat officiel est requis pour y accéder
- Le portail web Izly peut être encapsulé dans une Webview sécurisée (MVP)
- Les tokens d'authentification Izly sont gérés par S-Money, pas par notre backend

---

## Stratégie d'Intégration

### Phase MVP : Webview Sécurisée

Pour le MVP, l'intégration Izly repose sur une **Webview sécurisée** encapsulant le portail de paiement Izly. Cela évite de dépendre d'une API non publique.

```
┌─────────────────────────────────────────────────┐
│  App Flutter                                     │
│                                                  │
│  ┌───────────────────────────────────────────┐  │
│  │  Webview Sécurisée (InAppWebView)         │  │
│  │  URL: https://mon-espace.izly.fr/...      │  │
│  │                                           │  │
│  │  • Sandboxed (pas d'accès JS au host)     │  │
│  │  • HTTPS only                             │  │
│  │  • Certificate pinning                    │  │
│  │  • Intercepte les callbacks de paiement   │  │
│  └───────────────────────────────────────────┘  │
│                                                  │
│  onPaymentComplete(transactionId) ──────────────│──> Backend Supabase
│                                                  │
└─────────────────────────────────────────────────┘
```

### Phase Avancée : API S-Money Directe

Après obtention d'un partenariat avec BPCE/S-Money :

```
App Flutter ──> Backend Supabase ──> API S-Money (OAuth2)
                                          │
                                          ├── GET  /balance
                                          ├── POST /payment
                                          └── GET  /transactions
```

---

## Authentification Tierce Sécurisée

### Principes de Sécurité

L'authentification Izly est **entièrement déléguée** à S-Money. Notre app ne stocke **jamais** les identifiants Izly de l'utilisateur.

```
┌──────────┐     ┌──────────────┐     ┌─────────────┐
│  App     │     │  Backend     │     │  S-Money    │
│  Flutter │     │  Supabase    │     │  (Izly)     │
└────┬─────┘     └──────┬───────┘     └──────┬──────┘
     │                  │                    │
     │  1. Tap "Payer avec Izly"             │
     │──────────────────>                    │
     │                  │                    │
     │  2. Ouvrir Webview sécurisée          │
     │  (URL signée par le backend)          │
     │<─────────────────│                    │
     │                  │                    │
     │  3. L'utilisateur s'authentifie       │
     │     directement sur le portail Izly   │
     │──────────────────────────────────────>│
     │                  │                    │
     │  4. Izly confirme le paiement         │
     │     (redirect URL avec token)         │
     │<─────────────────────────────────────│
     │                  │                    │
     │  5. App intercepte le callback        │
     │     et envoie le token au backend     │
     │──────────────────>                    │
     │                  │                    │
     │                  │  6. Backend valide  │
     │                  │     le token auprès │
     │                  │     de S-Money      │
     │                  │───────────────────>│
     │                  │                    │
     │                  │  7. Confirmation    │
     │                  │<──────────────────│
     │                  │                    │
     │  8. Paiement confirmé                 │
     │<─────────────────│                    │
     │                  │                    │
```

### Implémentation Flutter (Webview)

```dart
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class IzlyPaymentWebview extends StatefulWidget {
  final double amount;
  final String orderId;
  final String signedPaymentUrl;

  const IzlyPaymentWebview({
    required this.amount,
    required this.orderId,
    required this.signedPaymentUrl,
  });

  @override
  State<IzlyPaymentWebview> createState() => _IzlyPaymentWebviewState();
}

class _IzlyPaymentWebviewState extends State<IzlyPaymentWebview> {
  late InAppWebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiement Izly')),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(widget.signedPaymentUrl),
        ),
        initialSettings: InAppWebViewSettings(
          // Sécurité : sandbox strict
          javaScriptCanOpenWindowsAutomatically: false,
          useShouldOverrideUrlLoading: true,
          // HTTPS uniquement
          mixedContentMode: MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
        ),
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final url = navigationAction.request.url.toString();

          // Intercepter le callback de paiement Izly
          if (url.startsWith('superapp://izly-callback')) {
            final uri = Uri.parse(url);
            final transactionId = uri.queryParameters['transaction_id'];
            final status = uri.queryParameters['status'];

            if (status == 'success' && transactionId != null) {
              await _confirmPayment(transactionId);
            } else {
              _handlePaymentError(status);
            }

            return NavigationActionPolicy.CANCEL;
          }

          return NavigationActionPolicy.ALLOW;
        },
        onWebViewCreated: (controller) {
          _controller = controller;
        },
      ),
    );
  }

  Future<void> _confirmPayment(String transactionId) async {
    // Envoyer le transactionId au backend pour validation
    // Le backend valide auprès de S-Money puis enregistre
    final response = await SupabaseClient.functions.invoke(
      'confirm-izly-payment',
      body: {
        'transaction_id': transactionId,
        'order_id': widget.orderId,
      },
    );

    if (response.status == 200) {
      Navigator.of(context).pop(PaymentResult.success);
    } else {
      Navigator.of(context).pop(PaymentResult.failed);
    }
  }

  void _handlePaymentError(String? status) {
    Navigator.of(context).pop(PaymentResult.failed);
  }
}
```

### Validation Backend (Supabase Edge Function)

```typescript
// supabase/functions/confirm-izly-payment/index.ts
import { serve } from 'https://deno.land/std/http/server.ts';
import { createClient } from '@supabase/supabase-js';

serve(async (req) => {
  const { transaction_id, order_id } = await req.json();

  // 1. Valider le token auprès de S-Money (simulé pour MVP)
  const izlyValid = await validateWithSMoney(transaction_id);

  if (!izlyValid) {
    return new Response(
      JSON.stringify({ error: 'Transaction Izly invalide' }),
      { status: 400 }
    );
  }

  // 2. Enregistrer la transaction dans notre base
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  const { error } = await supabase.from('payments').insert({
    order_id,
    provider: 'izly',
    external_transaction_id: transaction_id,
    status: 'confirmed',
    confirmed_at: new Date().toISOString(),
  });

  if (error) {
    return new Response(
      JSON.stringify({ error: 'Erreur enregistrement' }),
      { status: 500 }
    );
  }

  return new Response(
    JSON.stringify({ success: true }),
    { status: 200 }
  );
});

async function validateWithSMoney(transactionId: string): Promise<boolean> {
  // MVP : Simulation — à remplacer par l'appel réel API S-Money
  // En production, appel OAuth2 vers l'API S-Money pour valider
  // que la transaction existe et est confirmée.
  //
  // Exemple (post-partenariat) :
  // const response = await fetch('https://api.s-money.fr/v1/transactions/' + transactionId, {
  //   headers: { 'Authorization': 'Bearer ' + accessToken }
  // });
  // return response.ok;

  return transactionId.length > 0;
}
```

---

## Flux de Paiement Izly (Webview)

### Flux Standard (Solde Izly Suffisant)

```
Utilisateur          App Flutter           Backend Supabase        Izly (S-Money)
    │                    │                       │                       │
    │ "Payer 3.30€"     │                       │                       │
    │───────────────────>│                       │                       │
    │                    │ POST /create-order    │                       │
    │                    │──────────────────────>│                       │
    │                    │                       │ Génère signed URL     │
    │                    │ { paymentUrl }        │                       │
    │                    │<─────────────────────│                       │
    │                    │                       │                       │
    │ [Webview Izly]     │                       │                       │
    │<──────────────────│                       │                       │
    │                    │                       │                       │
    │ Login + Confirmer  │                       │                       │
    │───────────────────────────────────────────────────────────────────>│
    │                    │                       │                       │
    │ Callback success   │                       │                       │
    │<─────────────────────────────────────────────────────────────────│
    │                    │                       │                       │
    │                    │ POST /confirm-payment │                       │
    │                    │──────────────────────>│                       │
    │                    │                       │ Valide transaction    │
    │                    │                       │──────────────────────>│
    │                    │                       │       ✅ OK           │
    │                    │                       │<─────────────────────│
    │                    │  { success: true }    │                       │
    │                    │<─────────────────────│                       │
    │ ✅ Paiement OK     │                       │                       │
    │<──────────────────│                       │                       │
```

### Flux Split Bill (Izly + CB)

```
Utilisateur          App Flutter           Backend Supabase      Izly        Stripe
    │                    │                       │                 │            │
    │ "Payer 15€"        │                       │                 │            │
    │ (Solde Izly: 8€)   │                       │                 │            │
    │───────────────────>│                       │                 │            │
    │                    │ POST /create-split     │                 │            │
    │                    │──────────────────────>│                 │            │
    │                    │                       │                 │            │
    │                    │ { izly: 8€, cb: 7€ }  │                 │            │
    │                    │<─────────────────────│                 │            │
    │                    │                       │                 │            │
    │ [Webview Izly: 8€] │                       │                 │            │
    │<──────────────────│                       │                 │            │
    │ Confirme Izly      │                       │                 │            │
    │──────────────────────────────────────────────────────────>│            │
    │ ✅ Izly OK         │                       │                 │            │
    │<────────────────────────────────────────────────────────│            │
    │                    │                       │                 │            │
    │ [Stripe Sheet: 7€] │                       │                 │            │
    │<──────────────────│                       │                 │            │
    │ Confirme CB        │                       │                 │            │
    │──────────────────────────────────────────────────────────────────────>│
    │ ✅ Stripe OK       │                       │                 │            │
    │<───────────────────────────────────────────────────────────────────│
    │                    │                       │                 │            │
    │                    │ POST /confirm-split    │                 │            │
    │                    │──────────────────────>│                 │            │
    │                    │                       │ Vérifie les 2   │            │
    │                    │                       │ transactions    │            │
    │                    │  { success: true }    │                 │            │
    │                    │<─────────────────────│                 │            │
    │ ✅ Paiement total OK│                       │                 │            │
    │<──────────────────│                       │                 │            │
```

---

## Flux de Paiement Izly (API S-Money)

> ⚠️ Ce flux nécessite un partenariat officiel avec BPCE/S-Money.

### Authentification OAuth2

```
App Flutter           Backend Supabase           S-Money OAuth2
    │                       │                          │
    │ "Lier mon compte Izly"│                          │
    │──────────────────────>│                          │
    │                       │ GET /authorize            │
    │                       │ ?client_id=XXX            │
    │                       │ &redirect_uri=superapp:// │
    │                       │ &scope=payment,balance    │
    │                       │─────────────────────────>│
    │                       │                          │
    │ [Page login S-Money]  │                          │
    │<─────────────────────────────────────────────────│
    │                       │                          │
    │ L'utilisateur consent │                          │
    │─────────────────────────────────────────────────>│
    │                       │                          │
    │                       │ POST /token               │
    │                       │ { code, client_secret }   │
    │                       │─────────────────────────>│
    │                       │                          │
    │                       │ { access_token,           │
    │                       │   refresh_token }         │
    │                       │<────────────────────────│
    │                       │                          │
    │                       │ Stocke tokens chiffrés    │
    │                       │ (table izly_tokens)       │
    │                       │                          │
    │ ✅ Compte Izly lié    │                          │
    │<─────────────────────│                          │
```

### Stockage Sécurisé des Tokens

```sql
-- Les tokens Izly sont chiffrés côté serveur
-- Jamais exposés au client
CREATE TABLE izly_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    -- Tokens chiffrés avec clé serveur (AES-256-GCM)
    encrypted_access_token TEXT NOT NULL,
    encrypted_refresh_token TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- RLS : seul le backend (service role) accède à cette table
ALTER TABLE izly_tokens ENABLE ROW LEVEL SECURITY;
-- Aucune politique pour les utilisateurs = accès interdit côté client
```

---

## Sécurité & Bonnes Pratiques

### Règles Critiques

| Règle | Détail |
|-------|--------|
| **Jamais stocker les identifiants Izly** | L'authentification est déléguée à S-Money |
| **Tokens chiffrés côté serveur** | AES-256-GCM, clé dans les variables d'environnement |
| **Certificate pinning** | La Webview vérifie le certificat SSL d'Izly |
| **Signed URLs** | Les URLs de paiement sont signées par le backend (HMAC) |
| **Timeout strict** | Session Webview limitée à 5 minutes |
| **Idempotence** | Chaque paiement a un `order_id` unique pour éviter les doublons |
| **Atomicité Split Bill** | Si un des deux paiements échoue, rollback complet |

### Protection Anti-Fraude

```dart
// Vérifications avant d'initier un paiement
class PaymentGuard {
  static Future<bool> canInitiatePayment(String userId) async {
    // 1. Vérifier que l'utilisateur est un étudiant vérifié
    // 2. Vérifier le rate limiting (max 20 transactions/jour)
    // 3. Vérifier l'absence de flag fraude
    // 4. Vérifier la cohérence du montant
    return true; // Simplifié pour l'exemple
  }
}
```

### Logging & Audit

Chaque transaction est tracée :

```sql
CREATE TABLE payment_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    action TEXT NOT NULL, -- 'initiate', 'confirm', 'fail', 'refund'
    provider TEXT NOT NULL, -- 'izly', 'stripe'
    amount DECIMAL(10,2),
    metadata JSONB,
    ip_address INET,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Gestion des Erreurs

### Codes d'Erreur Paiement

| Code | Description | Action Utilisateur |
|------|-------------|-------------------|
| `IZLY_INSUFFICIENT_BALANCE` | Solde Izly insuffisant | Proposer Split Bill ou CB |
| `IZLY_AUTH_EXPIRED` | Session Izly expirée | Re-authentification |
| `IZLY_SERVICE_UNAVAILABLE` | Service Izly indisponible | Proposer CB comme fallback |
| `STRIPE_CARD_DECLINED` | CB refusée | Demander une autre CB |
| `SPLIT_PARTIAL_FAILURE` | Un des deux paiements a échoué | Rollback + message |
| `ORDER_ALREADY_PAID` | Commande déjà payée (idempotence) | Confirmer le paiement existant |

### Stratégie de Rollback (Split Bill)

```
Si Izly OK mais Stripe ÉCHOUE :
    → Initier remboursement Izly
    → Notifier l'utilisateur
    → Logger l'incident

Si Stripe OK mais Izly ÉCHOUE :
    → Initier remboursement Stripe
    → Notifier l'utilisateur
    → Logger l'incident
```

---

## Faisabilité & Roadmap

### Analyse de Faisabilité

| Composant | Faisabilité | Risque | Mitigation |
|-----------|-------------|--------|------------|
| **Webview Izly** | ✅ Haute | Changement d'URL par Izly | Monitoring + config distante |
| **API S-Money** | ⚠️ Moyenne | Partenariat requis | Commencer par Webview |
| **Lecture solde** | ⚠️ Moyenne | Dépend API | Scraping Webview en fallback |
| **Split Bill** | ✅ Haute | Atomicité | Saga pattern côté backend |
| **Stripe Connect** | ✅ Haute | Aucun | SDK mature et documenté |
| **Certificate Pinning** | ✅ Haute | Rotation certificats | Mise à jour via config distante |

### Roadmap d'Intégration

| Phase | Objectif | Durée estimée |
|-------|----------|---------------|
| **MVP** | Webview Izly + Stripe Connect + Split Bill | 4-6 semaines |
| **V1.1** | Partenariat BPCE, accès API S-Money | 3-6 mois (négociation) |
| **V1.2** | Lecture solde Izly native, rechargement in-app | 2-4 semaines post-API |
| **V2** | SDK natif Izly (si disponible) | À déterminer |

---

**Ce document sera mis à jour au fur et à mesure de l'avancement du partenariat avec BPCE/S-Money.**
