# 🎓 Architecture Fonctionnelle de l'Application Campus

**Une architecture modulaire au service de l'étudiant.**

> Chaque pilier possède son espace dédié, séparant clairement les flux sociaux,
> académiques et transactionnels pour une ergonomie sans faille.

---

## 🗂️ Vue d'Ensemble : Les 5 Piliers

| Pilier | Rôle | Classe principale |
|--------|------|-------------------|
| **Feed** | Le réseau social chronologique (Webtoon) | `FeedSystem` |
| **Hub** | L'espace d'excellence académique et IA | `RapidPollingSystem` |
| **Wallet** | La gestion de l'argent (CB + Izly) | `HybridWalletSystem` |
| **Events** | La billetterie et la vie démocratique | `SecureTicketingSystem` |
| **Profil** | Le graphe social et l'identité | `StudentProfile` |

---

## 🗳️ Pilier 2 : Le Hub Démocratique

### Simplifier l'engagement campus

Les votes pour le BDE, les syndicats ou le CA se font via une interface ludique.
**Un vote en un swipe**, avec des résultats diffusés en temps réel dans le Feed.

### Architecture

```
IPoll (Interface Strategy)
    └── RapidPollingSystem (MonoBehaviour)
            ├── Open()          → Ouvre le sondage
            ├── CastVote()      → Vote par swipe (1 étudiant = 1 vote)
            ├── GetLiveResults()→ Pourcentages en temps réel
            └── Close()         → Clôture + diffusion Feed
```

### Utilisation

```csharp
// 1. Créer et ouvrir un sondage
var polling = gameObject.AddComponent<RapidPollingSystem>();
polling.Open(
    id: "poll_artiste_jeudi",
    pollQuestion: "Quel artiste inviter jeudi ?",
    pollOptions: new List<PollOption>
    {
        new PollOption(0, "Artiste A", imageUrl: "artiste_a.png"),
        new PollOption(1, "Artiste B", imageUrl: "artiste_b.png")
    },
    anonymous: true,
    duration: 3600f
);

// 2. S'abonner aux résultats en temps réel (diffusion dans le Feed)
polling.OnPollClosed += (poll) =>
{
    feedSystem.PublishPollResult(poll);
};

// 3. Vote par swipe
polling.CastVote(studentProfile, optionIndex: 0);

// 4. Résultats live
var results = polling.GetLiveResults();
// → { 0: 65f, 1: 35f }
```

### Garanties de sécurité

- ✅ **Identité vérifiée obligatoire** : `StudentProfile.IsVerified`
- ✅ **1 vote par étudiant** : garanti par `StudentId` unique
- ✅ **Anonymat configurable** : `isAnonymous = true` par défaut
- ✅ **Clôture automatique** : timer configurable

---

## 💳 Pilier 3 : Le Wallet Hybride

### Paiement sans friction

Le Pass Universel intègre un portefeuille ultra-épuré.
**Un simple glissement de doigt** suffit pour basculer entre la carte bancaire et le solde Izly lors d'un achat.

### Architecture

```
IPaymentMethod (Interface Strategy)
    ├── BankCardPayment    → Carte bancaire classique (CB)
    └── IzlyPayment        → Solde Izly CROUS

HybridWalletSystem (MonoBehaviour)
    ├── SwitchPaymentMethod()           → Swipe CB ↔ Izly
    ├── Pay()                           → Paiement avec réductions auto
    └── ApplyPartnerDiscount()          → Statut étudiant vérifié → 0 code promo
```

### Utilisation

```csharp
// 1. Initialiser le wallet
var wallet = gameObject.AddComponent<HybridWalletSystem>();
wallet.Initialize(studentProfile);

// 2. Basculer entre CB et Izly (swipe de l'utilisateur)
wallet.SwitchPaymentMethod();
// → "Basculement → Izly"

// 3. Payer (réductions partenaires automatiques)
var transaction = wallet.Pay(
    amount: 5.50f,
    merchantId: "resto_u",
    payer: studentProfile
);
// → Statut Étudiant : Vérifié ✓ → Réduction 68% Izly appliquée
// → transaction.Amount = 1.76€ (au lieu de 5.50€)

// 4. S'abonner aux événements
wallet.OnMethodSwitched += (type) =>
{
    Debug.Log($"Mode de paiement : {type}");
};
wallet.OnPaymentProcessed += (transaction) =>
{
    if (transaction.HadDiscount)
        Debug.Log($"Économisé : {transaction.DiscountApplied:F2}€");
};
```

### Réductions partenaires intégrées

| Partenaire | CB | Izly |
|------------|-----|------|
| Restaurant U | 10% | 68% |
| Cafétéria | — | 20% |
| BDE Shop | 15% | — |
| Librairie Campus | 10% | — |

> **Statut Étudiant : Vérifié ✓ → Réductions appliquées automatiquement (0 code promo)**

---

## 🎫 Pilier 4 : La Billetterie Sécurisée

### Sécurisée par la vraie identité

De l'organisation d'une révision en L1 Éco-Gestion jusqu'à la soirée d'intégration,
**l'écosystème lie chaque billet à l'identité vérifiée de l'étudiant**.

### Types d'événements

| # | Type | Accès |
|---|------|-------|
| **1** | **Soirées de Promo** | Restreintes par cohorte |
| **2** | **Sessions Académiques** | Groupes de révision exclusifs |
| **3** | **Clubs & Assos** | Ouverts au campus |

### Architecture

```
TicketData (ScriptableObject)
    ├── Initialize()        → Génère QR code sécurisé
    ├── MarkAsScanned()     → Scan à l'entrée
    └── HasPostPartyAlbumAccess → Déverrouillage album

SecureTicketingSystem (MonoBehaviour)
    ├── IssueTicket()       → Émet un billet vérifié
    ├── CanAttend()         → Vérifie cohort/groupe/identité
    ├── ScanTicket()        → Scan QR code + déverrouillage album
    └── HasPostPartyAlbumAccess() → Protection vie privée
```

### Utilisation

```csharp
// 1. Émettre un billet (accès vérifié automatiquement)
var ticket = ticketing.IssueTicket(
    student: studentProfile,
    eventId: "soiree_integration_l1",
    eventName: "Soirée d'Intégration L1",
    eventType: EventType.SoireesDePromo,
    cohortRestriction: "L1_ECO_GESTION"
);
// → Billet émis avec QR code unique lié à l'identité

// 2. Scan à l'entrée
bool success = ticketing.ScanTicket(ticket.TicketId);
// → Album post-party déverrouillé pour l'étudiant

// 3. Vérifier l'accès à l'album post-party
bool hasAccess = ticketing.HasPostPartyAlbumAccess(
    studentId: "STU_001",
    eventId: "soiree_integration_l1"
);
// → true uniquement si le billet a été scanné à l'entrée

// 4. Observer les événements
ticketing.OnTicketScanned += (ticket) =>
{
    feedSystem.PublishEventAnnouncement(ticket.EventName, ticket.Type, "Un ami est arrivé !");
};
ticketing.OnPostPartyAlbumUnlocked += (studentId, eventId) =>
{
    Debug.Log($"Album déverrouillé pour {studentId} → {eventId}");
};
```

### Garanties de sécurité

- ✅ **QR code unique** par billet (signé avec `studentId + ticketId + eventId`)
- ✅ **Identité vérifiée** requise pour tout billet
- ✅ **Restrictions de cohorte** pour les soirées de promo
- ✅ **Album post-party protégé** : uniquement pour billets scannés à l'entrée

---

## 📱 Pilier 1 : Le Feed Social

### Réseau social chronologique

Le Feed agrège publications étudiantes, résultats de sondages en direct
et annonces d'événements. Il est le point de convergence des 5 piliers.

```csharp
// Publication automatique des résultats de vote
polling.OnPollClosed += (poll) => feedSystem.PublishPollResult(poll);

// Annonce d'événement
feedSystem.PublishEventAnnouncement(
    eventName: "Soirée Intégration",
    eventType: EventType.SoireesDePromo,
    description: "Rejoins ta promo !"
);

// Publication étudiante
feedSystem.PublishStudentPost(student, "Super conférence aujourd'hui !", mediaUrl: "photo.jpg");

// S'abonner au feed
feedSystem.OnFeedItemAdded += (item) =>
{
    // Mettre à jour l'UI du feed
};
```

---

## 👤 Pilier 5 : Le Profil & l'Identité

### Graphe social et identité

Le `StudentProfile` est l'identité centrale qui lie tous les piliers.

```csharp
// Créer et vérifier un profil
var profile = gameObject.AddComponent<StudentProfile>();
profile.Initialize("STU_001", "Alice Dupont", "alice@univ.fr", "L1_ECO", "Éco-Gestion", 1);
profile.VerifyIdentity();  // Requis pour Wallet Izly, Vote, Billets

// Graphe social
profile.Follow("STU_002");
profile.EnrollInGroup("groupe_revision_compta");

// Vérification d'accès intégrée
bool canVote = rapidPolling.CanVote(profile);         // true si vérifié + pas encore voté
bool canPayIzly = izlyPayment.CanPay(5.50f);          // true si vérifié + solde suffisant
bool canAttend = ticketing.CanAttend(profile, EventType.SoireesDePromo, "L1_ECO");
```

---

## 🔗 Intégration des 5 Piliers

Les 5 piliers communiquent via l'**Observer Pattern** pour un découplage total :

```csharp
public class CampusAppManager : MonoBehaviour
{
    [SerializeField] private FeedSystem feed;
    [SerializeField] private RapidPollingSystem polling;
    [SerializeField] private HybridWalletSystem wallet;
    [SerializeField] private SecureTicketingSystem ticketing;

    private void Start()
    {
        // Hub → Feed : résultats de vote en temps réel
        polling.OnPollClosed += (poll) => feed.PublishPollResult(poll);

        // Billetterie → Feed : annonces d'entrée
        ticketing.OnTicketScanned += (ticket) =>
            feed.PublishEventAnnouncement(ticket.EventName, ticket.Type, "Accès validé");

        // Wallet : suivi des transactions
        wallet.OnPaymentProcessed += (tx) =>
        {
            if (!tx.Success)
                Debug.Log("Paiement refusé : rechargez votre solde Izly");
        };
    }
}
```

---

## 📐 Patterns Architecturaux Utilisés

| Pattern | Utilisation |
|---------|-------------|
| **Strategy** | `IPaymentMethod` (CB / Izly), `IPoll` |
| **Observer** | Events C# sur tous les systèmes → Feed temps réel |
| **ScriptableObject** | `TicketData` → données immuables par billet |
| **Component** | Un MonoBehaviour par système, composés dans `CampusAppManager` |

---

## 📂 Structure des Scripts

```
Scripts/Campus/
├── Feed/
│   └── FeedSystem.cs              ❯ Réseau social chronologique
├── Hub/
│   ├── IPoll.cs                   ❯ Interface Strategy (sondages)
│   └── RapidPollingSystem.cs      ❯ Hub Démocratique : vote par swipe
├── Wallet/
│   ├── IPaymentMethod.cs          ❯ Interface Strategy (paiements)
│   └── HybridWalletSystem.cs      ❯ CB + Izly avec réductions auto
├── Events/
│   ├── TicketData.cs              ❯ ScriptableObject billet QR sécurisé
│   └── SecureTicketingSystem.cs   ❯ Billetterie par identité vérifiée
└── Profile/
    └── StudentProfile.cs          ❯ Identité centrale vérifiée
```
