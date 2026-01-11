# 💸 Système Économique Avancé - Patterns Production
## Intégration Plateau, Stratégie, Logs & Optimisations

---

## TABLE DES MATIÈRES

1. [TurnManager - Orchestration](#1-turnmanager--orchestration)
2. [TransactionLogger - Audit](#2-transactionlogger--audit)
3. [TradeSystem - Échanges](#3-tradesystem--Échanges)
4. [EconomicWinConditions - Victoires](#4-economicwinconditions--victoires)
5. [Production Avancée - Synergies](#5-production-avancée--synergies)
6. [Performance & Optimisations](#6-performance--optimisations)
7. [Tests Unitaires](#7-tests-unitaires)

---

## 1. TURNMANAGER - ORCHESTRATION

### 📑 TurnManager.cs

```csharp
using UnityEngine;
using OctagonalChess.Economy;
using OctagonalChess.Gameplay;

namespace OctagonalChess.Gameplay
{
    /// <summary>
    /// TurnManager = Gère la boucle de jeu et appelle les systèmes dans l'ordre.
    /// 
    /// Ordre d'exécution d'un tour:
    /// 1. DÉBUT TOUR: Production économique
    /// 2. JEU: Actions du joueur
    /// 3. FIN TOUR: Cleanup et vérifications
    /// </summary>
    public class TurnManager : MonoBehaviour
    {
        [Header("🎮 Références")]
        [SerializeField] private IncomeProcessor incomeProcessor;
        [SerializeField] private EconomyManager economyManager;
        [SerializeField] private BoardManager boardManager;
        [SerializeField] private TransactionLogger transactionLogger;  // Pour logs
        
        private int currentTurn = 0;
        private bool isTurnActive = false;
        
        private void Start()
        {
            if (incomeProcessor == null)
                incomeProcessor = GetComponent<IncomeProcessor>();
            if (economyManager == null)
                economyManager = EconomyManager.Instance;
            if (transactionLogger == null)
                transactionLogger = GetComponent<TransactionLogger>();
            
            StartNewTurn();
        }
        
        /// <summary>
        /// Démarre un nouveau tour.
        /// </summary>
        public void StartNewTurn()
        {
            currentTurn++;
            isTurnActive = true;
            
            Debug.Log($"\n📦 \n\n===== TOUR {currentTurn} DéBUC =====\n📦 \n");
            
            // ========== ÉTAPE 1: PRODUCTION ÉCONOMIQUE ==========
            OnTurnStart_Production();
            
            // ========== ÉTAPE 2: JEU NORMAL ==========
            OnTurnActive();
        }
        
        private void OnTurnStart_Production()
        {
            Debug.Log("[TurnManager] 🎉 Phase 1: Production économique");
            
            // Traiter le revenu
            incomeProcessor.ProcessTurnIncome();
            
            // Logger la production
            transactionLogger?.LogProductionStart(currentTurn);
        }
        
        private void OnTurnActive()
        {
            Debug.Log("[TurnManager] 🎮 Phase 2: Joueur joue");
            
            isTurnActive = true;
            // Attendre les actions du joueur
            // (Ex: via InputManager qui appelle des actions)
        }
        
        /// <summary>
        /// Appelé quand le joueur veut terminer son tour.
        /// </summary>
        public void EndTurn()
        {
            if (!isTurnActive)
            {
                Debug.LogWarning("[TurnManager] Le tour n'est pas actif!");
                return;
            }
            
            Debug.Log("[TurnManager] ⏲ Phase 3: Fin du tour");
            
            isTurnActive = false;
            
            // Cleanup
            transactionLogger?.LogTurnEnd(currentTurn);
            
            // Démarrer le prochain tour
            StartNewTurn();
        }
        
        public int CurrentTurn => currentTurn;
        public bool IsTurnActive => isTurnActive;
    }
}
```

---

## 2. TRANSACTIONLOGGER - AUDIT

### 📄 TransactionLogger.cs

```csharp
using UnityEngine;
using System;
using System.Collections.Generic;
using OctagonalChess.Economy;

namespace OctagonalChess.Economy
{
    /// <summary>
    /// TransactionLogger = Journalise TOUTES les transactions économiques.
    /// 
    /// Utile pour:
    /// 1. Debug (retrouver où l'argent a disparu)
    /// 2. Replay (rejouer une partie)
    /// 3. Analytics (voir patterns de dépense)
    /// 4. Anti-cheat (vérifier intimité de jeu)
    /// </summary>
    public class TransactionLogger : MonoBehaviour
    {
        private List<Transaction> allTransactions = new List<Transaction>();
        private int maxLogSize = 1000;  // Limiter la taille du log
        
        // Événements pour UI (afficher le log)
        public event Action<Transaction> OnTransactionLogged;
        
        private void Start()
        {
            // S'enregistrer aux events d'EconomyManager
            var economy = EconomyManager.Instance;
            if (economy != null)
            {
                economy.OnResourceChanged += LogResourceChange;
                economy.OnResourceSpent += LogSpending;
            }
        }
        
        // ========== MÉTHODES DE LOGGING ==========
        
        public void LogProductionStart(int turn)
        {
            LogTransaction(new Transaction
            {
                Type = TransactionType.ProductionStart,
                Timestamp = Time.realtimeSinceStartup,
                Turn = turn,
                Message = $"Debut production turn {turn}"
            });
        }
        
        public void LogTurnEnd(int turn)
        {
            LogTransaction(new Transaction
            {
                Type = TransactionType.TurnEnd,
                Timestamp = Time.realtimeSinceStartup,
                Turn = turn,
                Message = $"Fin tour {turn}"
            });
        }
        
        private void LogResourceChange(ResourceType type, int newAmount, int oldAmount)
        {
            int delta = newAmount - oldAmount;
            
            LogTransaction(new Transaction
            {
                Type = delta > 0 ? TransactionType.Addition : TransactionType.Subtraction,
                ResourceType = type,
                Amount = Mathf.Abs(delta),
                OldAmount = oldAmount,
                NewAmount = newAmount,
                Timestamp = Time.realtimeSinceStartup,
                Message = $"{(delta > 0 ? "+" : "-")}{Mathf.Abs(delta)} {type}"
            });
        }
        
        private void LogSpending(ResourceType type, int amount)
        {
            LogTransaction(new Transaction
            {
                Type = TransactionType.Spending,
                ResourceType = type,
                Amount = amount,
                Timestamp = Time.realtimeSinceStartup,
                Message = $"-{amount} {type} (action spéciale)"
            });
        }
        
        private void LogTransaction(Transaction transaction)
        {
            allTransactions.Add(transaction);
            
            // Limiter la taille du log
            if (allTransactions.Count > maxLogSize)
                allTransactions.RemoveAt(0);
            
            // Émettre l'event
            OnTransactionLogged?.Invoke(transaction);
            
            Debug.Log($"[TransactionLogger] {transaction.Message}");
        }
        
        // ========== REQUÊTES ==========
        
        /// <summary>
        /// Retourne le total dépensé d'une ressource ce tour.
        /// </summary>
        public int GetTotalSpentThisTurn(ResourceType type, int currentTurn)
        {
            int total = 0;
            
            foreach (var trans in allTransactions)
            {
                if (trans.Turn == currentTurn && 
                    trans.ResourceType == type && 
                    trans.Type == TransactionType.Subtraction)
                {
                    total += trans.Amount;
                }
            }
            
            return total;
        }
        
        /// <summary>
        /// Retourne la liste de TOUTES les transactions pour UI.
        /// </summary>
        public List<Transaction> GetAllTransactions() => new List<Transaction>(allTransactions);
        
        /// <summary>
        /// Exporte le log en JSON pour analyse offline.
        /// </summary>
        public string ExportAsJSON()
        {
            return JsonUtility.ToJson(new TransactionLog { Transactions = allTransactions });
        }
    }
    
    [System.Serializable]
    public class Transaction
    {
        public TransactionType Type;
        public ResourceType ResourceType;
        public int Amount;           // Montant de la transaction
        public int OldAmount;        // Valeur précédente
        public int NewAmount;        // Nouvelle valeur
        public double Timestamp;     // Quand
        public int Turn;             // Quel tour
        public string Message;       // Description lisible
    }
    
    [System.Serializable]
    public class TransactionLog
    {
        public List<Transaction> Transactions;
    }
    
    public enum TransactionType
    {
        Addition,        // Production
        Subtraction,     // Dépense
        Spending,        // Action spéciale
        Transfer,        // Échange entre joueurs
        ProductionStart,
        TurnEnd
    }
}
```

---

## 3. TRADESYSTEM - ÉCHANGES

### 💶 TradeSystem.cs

```csharp
using UnityEngine;
using System;
using OctagonalChess.Economy;

namespace OctagonalChess.Gameplay
{
    /// <summary>
    /// TradeSystem = Permet les échanges entre joueurs.
    /// 
    /// Exemples:
    /// - Troquer 10 Or contre 5 Mana
    /// - Échanger des ressources de facon strategique
    /// </summary>
    public class TradeSystem : MonoBehaviour
    {
        private EconomyManager economy;
        
        // Événements
        public event Action<ResourceType, int, ResourceType, int> OnTradeExecuted;
        
        private void Start()
        {
            economy = EconomyManager.Instance;
        }
        
        /// <summary>
        /// Effectue un échange: donne X de resourceA, reçoit Y de resourceB.
        /// </summary>
        public bool ExecuteTrade(
            ResourceType giveResource,
            int giveAmount,
            ResourceType receiveResource,
            int receiveAmount)
        {
            // Vérifier sufisance
            if (!economy.TrySpendResource(giveResource, giveAmount))
            {
                Debug.LogWarning($"[TradeSystem] Insuffisant {giveResource}");
                return false;
            }
            
            // Donner la contrepartie
            economy.AddResource(receiveResource, receiveAmount);
            
            OnTradeExecuted?.Invoke(giveResource, giveAmount, receiveResource, receiveAmount);
            
            Debug.Log($"[TradeSystem] 🔄 Échange: -{giveAmount} {giveResource} pour +{receiveAmount} {receiveResource}");
            
            return true;
        }
        
        /// <summary>
        /// Taux de change fixe.
        /// </summary>
        public int GetExchangeRate(ResourceType from, ResourceType to)
        {
            return (from, to) switch
            {
                (ResourceType.Gold, ResourceType.Mana) => 2,      // 2 Or = 1 Mana
                (ResourceType.Mana, ResourceType.Gold) => 1,      // 1 Mana = 2 Or
                (ResourceType.Gold, ResourceType.Wisdom) => 3,    // 3 Or = 1 Sagesse
                (ResourceType.Wisdom, ResourceType.Gold) => 1,    // 1 Sagesse = 3 Or
                _ => 1  // Pas d'échange direct
            };
        }
    }
}
```

---

## 4. ECONOMICWINCONDITIONS - VICTOIRES

### 🌟 EconomicWinCondition.cs

```csharp
using UnityEngine;
using System;
using OctagonalChess.Economy;

namespace OctagonalChess.Gameplay
{
    /// <summary>
    /// EconomicWinCondition = Conditions de victoire basées sur l'économie.
    /// 
    /// Méchaniques:
    /// 1. Premier à accumuler X ressources gagne
    /// 2. Empêcher l'ennemi d'avoir acces aux ressources
    /// 3. Controle de territoire = contrôle des gains
    /// </summary>
    public class EconomicWinCondition : MonoBehaviour
    {
        [Header("🎁 Objectifs")]
        [SerializeField] private int goldWinTarget = 100;      // Accumulé 100 Or
        [SerializeField] private int manaWinTarget = 50;       // Accumulé 50 Mana
        [SerializeField] private int wisdomWinTarget = 30;     // Accumulé 30 Sagesse
        
        [Tooltip("Tous les objectifs doivent être atteints?")]
        [SerializeField] private bool requireAllTargets = false;
        
        private EconomyManager economy;
        
        public event Action<ResourceType> OnWinConditionMet;
        
        private void Start()
        {
            economy = EconomyManager.Instance;
            if (economy != null)
                economy.OnResourceChanged += CheckWinConditions;
        }
        
        private void CheckWinConditions(ResourceType type, int newAmount, int oldAmount)
        {
            // Vérifier chaque cible
            bool goldReached = economy.GetResourceAmount(ResourceType.Gold) >= goldWinTarget;
            bool manaReached = economy.GetResourceAmount(ResourceType.Mana) >= manaWinTarget;
            bool wisdomReached = economy.GetResourceAmount(ResourceType.Wisdom) >= wisdomWinTarget;
            
            if (requireAllTargets)
            {
                // TOUS les objectifs doivent être atteints
                if (goldReached && manaReached && wisdomReached)
                {
                    Debug.Log("[EconomicWinCondition] 🎉 VICTOIRE - TOUS LES OBJECTIFS ATTEINTS!");
                    TriggerWin();
                }
            }
            else
            {
                // UN SEUL objectif suffit
                if (goldReached || manaReached || wisdomReached)
                {
                    Debug.Log($"[EconomicWinCondition] 🎉 VICTOIRE - Objectif {type} atteint!");
                    OnWinConditionMet?.Invoke(type);
                    TriggerWin();
                }
            }
        }
        
        private void TriggerWin()
        {
            Time.timeScale = 0f;  // Pause le jeu
            Debug.Log("[EconomicWinCondition] === VICTOIRE ===");
            // Afficher écran de victoire, sons, etc.
        }
    }
}
```

---

## 5. PRODUCTION AVANCÉE - SYNERGIES

### 👋 SynergyBonus.cs

```csharp
using UnityEngine;
using System.Collections.Generic;
using OctagonalChess.Core;
using OctagonalChess.Economy;

namespace OctagonalChess.Gameplay
{
    /// <summary>
    /// SynergyBonus = Bonus quand plusieurs piéces spéciales sont présentes.
    /// 
    /// Exemples:
    /// - Si 2 Roi Marchands = +50% Or (au lieu de +100%)
    /// - Si Roi Marchand + Fou Mystique = +0.5 Mana bonus
    /// </summary>
    public class SynergyBonus : MonoBehaviour
    {
        [SerializeField] private IncomeProcessor incomeProcessor;
        
        /// <summary>
        /// Vérifie et applique les bonus de synergy.
        /// </summary>
        public (int goldBonus, int manaBonus, int wisdomBonus) CalculateSynergyBonus(
            List<PieceInstance> allyPieces)
        {
            int merchantKingCount = 0;
            int mysticBishopCount = 0;
            int philosopherQueenCount = 0;
            
            // Compter les piéces spéciales
            foreach (var piece in allyPieces)
            {
                if (piece.PieceName.Contains("Roi_Marchand"))
                    merchantKingCount++;
                else if (piece.PieceName.Contains("Fou_Mystique"))
                    mysticBishopCount++;
                else if (piece.PieceName.Contains("Reine_Philosophe"))
                    philosopherQueenCount++;
            }
            
            int goldBonus = 0, manaBonus = 0, wisdomBonus = 0;
            
            // Synergy: 2+ Roi Marchands = +50% Or
            if (merchantKingCount >= 2)
            {
                goldBonus = (merchantKingCount - 1) * 50 / 100;  // +1 Or par merchant supplémentaire
                Debug.Log($"[SynergyBonus] 👑 Synergy Rois Marchands: +{goldBonus} Or bonus!");
            }
            
            // Synergy: Roi Marchand + Fou Mystique = énergie créée
            if (merchantKingCount > 0 && mysticBishopCount > 0)
            {
                manaBonus += 1;
                Debug.Log("[SynergyBonus] 🔵 Synergy Marchand + Mystique: +1 Mana bonus!");
            }
            
            // Synergy: Tous les 3 en place = apothéose
            if (merchantKingCount > 0 && mysticBishopCount > 0 && philosopherQueenCount > 0)
            {
                goldBonus += 5;
                manaBonus += 2;
                wisdomBonus += 1;
                Debug.Log("[SynergyBonus] ✨ APOTHEOSE - Toutes les pièces en place!");
            }
            
            return (goldBonus, manaBonus, wisdomBonus);
        }
    }
}
```

---

## 6. PERFORMANCE & OPTIMISATIONS

### ⚡ Checklist Performance

```csharp
// ✅ Cache des données (pas de lookups chaque frame)
private Dictionary<ResourceType, int> resourceCache;

// ✅ Events au lieu de polling
economy.OnResourceChanged += UpdateUI;  // Au lieu de vérifier dans Update()

// ✅ Limiter la taille des logs
if (allTransactions.Count > maxLogSize)
    allTransactions.RemoveAt(0);

// ✅ Une seule instance du manager (Singleton)
public static EconomyManager Instance { get; }

// ✅ ResourceBank est un Struct (passé par valeur)
// Moins d'allocations mémoire que classe
public struct ResourceBank { }

// ✅ Clamp automatique (pas de vérification manuelle)
Gold = Mathf.Clamp(value, 0, MAX_GOLD);
```

### 🔐 Profiling Code

```csharp
using UnityEngine.Profiling;

public void ProcessTurnIncome()
{
    Profiler.BeginSample("IncomeProcessor.ProcessTurnIncome");
    
    // ... code ...
    
    Profiler.EndSample();
    
    // Dans Profiler window: Window → Analysis → Profiler
    // Voir le temps pris par ProcessTurnIncome()
}
```

---

## 7. TESTS UNITAIRES

### 🧪 EconomyTests.cs

```csharp
using UnityEngine;
using NUnit.Framework;
using OctagonalChess.Economy;

namespace OctagonalChess.Tests
{
    public class EconomyTests
    {
        private EconomyManager economy;
        private ResourceBank testBank;
        
        [SetUp]
        public void Setup()
        {
            economy = new GameObject().AddComponent<EconomyManager>();
            testBank = new ResourceBank(10, 5, 3);
        }
        
        [Test]
        public void TestAddResource_GoldIncreases()
        {
            testBank.AddResource(ResourceType.Gold, 5);
            Assert.AreEqual(15, testBank.Gold);
        }
        
        [Test]
        public void TestSpendResource_Success()
        {
            bool success = testBank.TrySpendResource(ResourceType.Gold, 5);
            Assert.IsTrue(success);
            Assert.AreEqual(5, testBank.Gold);
        }
        
        [Test]
        public void TestSpendResource_Insufficient()
        {
            bool success = testBank.TrySpendResource(ResourceType.Gold, 100);
            Assert.IsFalse(success);
            Assert.AreEqual(10, testBank.Gold);  // Non modifié
        }
        
        [Test]
        public void TestResourceClamping_MaxGold()
        {
            testBank.AddResource(ResourceType.Gold, 1000);
            Assert.AreEqual(ResourceBank.MAX_GOLD, testBank.Gold);
        }
        
        [Test]
        public void TestResourcePercent()
        {
            float percent = testBank.GetResourcePercent(ResourceType.Gold);
            Assert.AreEqual(10f / 100f, percent);
        }
        
        [TearDown]
        public void Teardown()
        {
            Object.Destroy(economy.gameObject);
        }
    }
}
```

---

## PATTERNS RECOMMANDÉS

### Pattern 1: Production Saisonnière

```csharp
// Chaque turn +1 Or
// Tous les 3 tours +2 Mana bonus (lune croissante)
// Tous les 5 tours +3 Sagesse bonus (apothéose)

if (currentTurn % 1 == 0)
    economy.AddResource(ResourceType.Gold, 1);

if (currentTurn % 3 == 0)
    economy.AddResource(ResourceType.Mana, 2);

if (currentTurn % 5 == 0)
    economy.AddResource(ResourceType.Wisdom, 3);
```

### Pattern 2: Encheres aux Ressources

```csharp
// Joueurs enchérissent avec leurs ressources
// Celui qui dépense le plus gagne le prix

public void RunAuction(ResourceType biddingResource)
{
    int maxBid = 0;
    EconomyManager winner = null;
    
    foreach (var player in allPlayers)
    {
        int bid = player.GetResourceAmount(biddingResource);
        if (bid > maxBid)
        {
            maxBid = bid;
            winner = player;
        }
    }
    
    // Gagnant reçoit le prix
    winner.AddResource(ResourceType.Gold, 50);
}
```

### Pattern 3: Taxes & Impôts

```csharp
// Chaque tour: perte de 5% des ressources

public void ApplyTaxes()
{
    for (float rate = 0.05f; rate > 0; rate -= 0.05f)
    {
        economy.ForceSpendResource(
            ResourceType.Gold,
            Mathf.RoundToInt(economy.GetResourceAmount(ResourceType.Gold) * rate)
        );
    }
}
```

---

## RÉCAPITULATIF ARCHITECTURE COMPLÈTE

### 🏗 Architecture Économique Complète

```
TURN STRUCTURE:
╔═══════════════════════════════════════════════════╗
║ TurnManager.StartNewTurn()                          ║
║   ├─→ IncomeProcessor.ProcessTurnIncome()               ║
║   │   ├─→ Find Roi Marchand → +Or                     ║
║   │   ├─→ Find Fou Mystique → +Mana                  ║
║   │   ├─→ Find Reine Philosophe → +Sagesse            ║
║   │   └─→ SynergyBonus.Calculate() → Bonus supplementaires ║
║   │                                                    ║
║   ├─→ EconomyManager.AddResource(...)                   ║
║   │   └─→ OnResourceChanged event                         ║
║   │       └─→ ResourceUI.Refresh()                         ║
║   │       └─→ TransactionLogger.Log()                     ║
║   │                                                    ║
║   └─→ TurnManager.OnTurnActive()                        ║
║       └─→ Joueur effectue actions                       ║
║           └─→ SpendingSystem.TryInvoke(...)               ║
║           └─→ EconomyManager.TrySpendResource(...)        ║
║           └─→ OnResourceSpent event                        ║
║                                                       ║
║   Player clicks "End Turn"                            ║
║   └─→ TurnManager.EndTurn()                           ║
║       └─→ TransactionLogger.LogTurnEnd()                ║
║       └─→ EconomicWinCondition.Check()                 ║
║       └─→ StartNewTurn() (boucle)                       ║
╚═══════════════════════════════════════════════════╘
```

### 💺 Responsabilités par Module

| Module | Responsabilité | Déclenche |
|--------|-----------------|------|
| ResourceBank | Stockage + Clamping | - |
| EconomyManager | Transactions centrales | OnResourceChanged, OnResourceSpent |
| IncomeProcessor | Production | AddResource() |
| SpendingSystem | Dépenses joueur | TrySpendResource() |
| TradeSystem | Échanges | ExecuteTrade() |
| TransactionLogger | Audit | Tous les events économiques |
| ResourceUI | Affichage | OnResourceChanged |
| EconomicWinCondition | Victoire économique | OnResourceChanged |

---

**Système économique production-ready complet!** 🚀💸
