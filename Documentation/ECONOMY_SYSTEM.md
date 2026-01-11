# 💰 Système Économique - Octagonal Chess Tactics
## Gestion des Ressources (Or, Mana, Sagesse) avec Revenu Automatique

**Namespace:** `OctagonalChess.Economy`

---

## TABLE DES MATIÈRES

1. [Vue d'Ensemble](#1-vue-densemble)
2. [Structure des Données - ResourceBank](#2-structure-des-données--resourcebank)
3. [EconomyManager - Singleton Central](#3-economymanager--singleton-central)
4. [Système de Production - ProcessTurnIncome()](#4-système-de-production--processtturnincome)
5. [Mécaniques de Dépense](#5-mécaniques-de-dépense)
6. [Intégration Cases Bonus](#6-intégration-cases-bonus)
7. [Gestion UI avec Events](#7-gestion-ui-avec-events)
8. [Extensibilité - Nouvelles Ressources](#8-extensibilité--nouvelles-ressources)
9. [Exemples d'Utilisation](#9-exemples-dutilisation)
10. [Sécurité & Validation](#10-sécurité--validation)

---

## 1. VUE D'ENSEMBLE

### 🎮 Flux du Système Économique

```
╔════════════════════════════════════════════════════════════════╗
║           BOUCLE ÉCONOMIQUE (Chaque Tour)                      ║
╚════════════════════════════════════════════════════════════════╝

1. DÉBUT DU TOUR
   │
   ├─→ ProcessTurnIncome()
   │   ├─→ Vérifie Roi Marchand → +Or
   │   ├─→ Vérifie Fou Mystique → +Mana
   │   └─→ Vérifie Reine Philosophe → +Sagesse
   │
   ├─→ Appliquer bonus des cases
   │   └─→ Si case Bonus → doubler le gain
   │
   └─→ Émettre events
       └─→ UI se met à jour (barre d'or, mana, sagesse)

2. JEU NORMAL
   │
   └─→ Joueur dépense ressources
       ├─→ Invoquer créature (-Or)
       ├─→ Lancer sort (-Mana)
       └─→ Utiliser pouvoir philosophique (-Sagesse)

3. FIN DU TOUR
   │
   └─→ Vérifier ressources max atteintes
```

### 💳 Les 3 Ressources Principales

| Ressource | Production | Max | Utilisation |
|-----------|-----------|-----|------|
| **Or** | Roi Marchand : +1/tour | 100 | Invoquer créatures |
| **Mana** | Fou Mystique : +1/tour | 50 | Lancer sorts |
| **Sagesse** | Reine Philosophe : +1/tour | 30 | Pouvoirs spéciaux |

---

## 2. STRUCTURE DES DONNÉES - RESOURCEBANK

### 📦 ResourceBank.cs - Struct Optimisé

```csharp
using UnityEngine;
using OctagonalChess.Economy;

namespace OctagonalChess.Economy
{
    /// <summary>
    /// Struct immutable stockant 3 ressources avec vérifications.
    /// 
    /// Avantage: Plus léger qu'une classe, passe par valeur.
    /// Immutable = pas de risque de modification non intentionnelle.
    /// </summary>
    [System.Serializable]
    public struct ResourceBank
    {
        // ========== STOCKAGE ==========
        
        [SerializeField] private int gold;      // Or (0-100)
        [SerializeField] private int mana;      // Mana (0-50)
        [SerializeField] private int wisdom;    // Sagesse (0-30)
        
        // ========== LIMITES ==========
        
        public static readonly int MAX_GOLD = 100;
        public static readonly int MAX_MANA = 50;
        public static readonly int MAX_WISDOM = 30;
        
        // ========== PROPRIÉTÉS D'ACCÈS ==========
        
        public int Gold
        {
            get => gold;
            private set => gold = Mathf.Clamp(value, 0, MAX_GOLD);
        }
        
        public int Mana
        {
            get => mana;
            private set => mana = Mathf.Clamp(value, 0, MAX_MANA);
        }
        
        public int Wisdom
        {
            get => wisdom;
            private set => wisdom = Mathf.Clamp(value, 0, MAX_WISDOM);
        }
        
        // ========== CONSTRUCTEURS ==========
        
        /// <summary>
        /// Crée un ResourceBank avec des valeurs initiales.
        /// </summary>
        public ResourceBank(int initialGold = 10, int initialMana = 5, int initialWisdom = 3)
        {
            gold = Mathf.Clamp(initialGold, 0, MAX_GOLD);
            mana = Mathf.Clamp(initialMana, 0, MAX_MANA);
            wisdom = Mathf.Clamp(initialWisdom, 0, MAX_WISDOM);
        }
        
        // ========== OPÉRATIONS ==========
        
        /// <summary>
        /// Ajoute des ressources (clamped au max).
        /// </summary>
        public void AddResource(ResourceType type, int amount)
        {
            if (amount < 0)
            {
                Debug.LogWarning($"[ResourceBank] Cannot add negative amount: {amount}");
                return;
            }
            
            switch (type)
            {
                case ResourceType.Gold:
                    Gold += amount;
                    break;
                case ResourceType.Mana:
                    Mana += amount;
                    break;
                case ResourceType.Wisdom:
                    Wisdom += amount;
                    break;
            }
        }
        
        /// <summary>
        /// Essaie de dépenser une ressource.
        /// Retourne true si succès, false si insuffisant.
        /// </summary>
        public bool TrySpendResource(ResourceType type, int amount)
        {
            if (amount < 0)
            {
                Debug.LogWarning($"[ResourceBank] Cannot spend negative amount: {amount}");
                return false;
            }
            
            bool canSpend = type switch
            {
                ResourceType.Gold => gold >= amount,
                ResourceType.Mana => mana >= amount,
                ResourceType.Wisdom => wisdom >= amount,
                _ => false
            };
            
            if (!canSpend)
                return false;
            
            switch (type)
            {
                case ResourceType.Gold:
                    gold -= amount;
                    break;
                case ResourceType.Mana:
                    mana -= amount;
                    break;
                case ResourceType.Wisdom:
                    wisdom -= amount;
                    break;
            }
            
            return true;
        }
        
        /// <summary>
        /// Retourne la valeur actuelle d'une ressource.
        /// </summary>
        public int GetResourceAmount(ResourceType type)
        {
            return type switch
            {
                ResourceType.Gold => gold,
                ResourceType.Mana => mana,
                ResourceType.Wisdom => wisdom,
                _ => 0
            };
        }
        
        /// <summary>
        /// Retourne le max d'une ressource.
        /// </summary>
        public int GetResourceMax(ResourceType type)
        {
            return type switch
            {
                ResourceType.Gold => MAX_GOLD,
                ResourceType.Mana => MAX_MANA,
                ResourceType.Wisdom => MAX_WISDOM,
                _ => 0
            };
        }
        
        /// <summary>
        /// Retourne le pourcentage de remplissage (0-1).
        /// </summary>
        public float GetResourcePercent(ResourceType type)
        {
            int amount = GetResourceAmount(type);
            int max = GetResourceMax(type);
            return max > 0 ? (float)amount / max : 0f;
        }
        
        // ========== UTILITAIRES ==========
        
        /// <summary>
        /// Debug: affiche le contenu du wallet.
        /// </summary>
        public override string ToString()
        {
            return $"💰 Gold: {gold}/{MAX_GOLD} | 🔵 Mana: {mana}/{MAX_MANA} | ✨ Wisdom: {wisdom}/{MAX_WISDOM}";
        }
    }
    
    // ========== ENUMS ==========
    
    /// <summary>
    /// Types de ressources disponibles.
    /// Extensible pour ajouter "Souls", "Essence", etc.
    /// </summary>
    public enum ResourceType
    {
        Gold,      // Or - Marchandise
        Mana,      // Mana - Magie
        Wisdom,    // Sagesse - Philosophie
        // À ajouter plus tard:
        // Souls,
        // Essence,
        // Crystals
    }
}
```

---

## 3. ECONOMYMANAGER - SINGLETON CENTRAL

### 🏦 EconomyManager.cs - Gestionnaire Principal

```csharp
using UnityEngine;
using System;
using System.Collections.Generic;
using OctagonalChess.Core;
using OctagonalChess.Gameplay;

namespace OctagonalChess.Economy
{
    /// <summary>
    /// EconomyManager = Singleton centralisé gérant toutes les ressources du jeu.
    /// 
    /// Responsabilités:
    /// 1. Stocker le wallet (ResourceBank)
    /// 2. Valider les transactions (TrySpendResource)
    /// 3. Ajouter des ressources (AddResource)
    /// 4. Produire du revenu chaque tour (ProcessTurnIncome)
    /// 5. Émettre des events pour l'UI
    /// 
    /// Pattern: Singleton pour l'accès global.
    /// </summary>
    public class EconomyManager : MonoBehaviour
    {
        // ========== SINGLETON ==========
        
        private static EconomyManager instance;
        public static EconomyManager Instance
        {
            get
            {
                if (instance == null)
                {
                    instance = FindObjectOfType<EconomyManager>();
                    if (instance == null)
                    {
                        Debug.LogError("[EconomyManager] Aucune instance trouvée!");
                    }
                }
                return instance;
            }
        }
        
        // ========== CONFIGURATION ==========
        
        [Header("⚙️ Configuration Initiale")]
        [SerializeField] private int startingGold = 10;
        [SerializeField] private int startingMana = 5;
        [SerializeField] private int startingWisdom = 3;
        
        [Header("🎮 Références")]
        [SerializeField] private BoardManager boardManager;
        
        // ========== ÉTAT ==========
        
        private ResourceBank playerBank;        // Wallet du joueur
        private Dictionary<TeamColor, ResourceBank> teamBanks = new Dictionary<TeamColor, ResourceBank>();
        
        // ========== ÉVÉNEMENTS UI ==========
        
        /// <summary>
        /// Déclenché quand une ressource change.
        /// Param: (type, newAmount, oldAmount)
        /// </summary>
        public event Action<ResourceType, int, int> OnResourceChanged;
        
        /// <summary>
        /// Déclenché quand une dépense réussit.
        /// Param: (type, amount)
        /// </summary>
        public event Action<ResourceType, int> OnResourceSpent;
        
        /// <summary>
        /// Déclenché quand une dépense échoue (insuffisant).
        /// Param: (type, needed, available)
        /// </summary>
        public event Action<ResourceType, int, int> OnInsufficientResources;
        
        /// <summary>
        /// Déclenché au début du tour pour la production.
        /// Param: (goldProduced, manaProduced, wisdomProduced)
        /// </summary>
        public event Action<int, int, int> OnTurnIncomeProcessed;
        
        /// <summary>
        /// Déclenché quand une ressource atteint son max.
        /// Param: (type)
        /// </summary>
        public event Action<ResourceType> OnResourceMaxed;
        
        // ========== INITIALISATION ==========
        
        private void Awake()
        {
            if (instance == null)
                instance = this;
            else if (instance != this)
                Destroy(gameObject);
        }
        
        private void Start()
        {
            if (boardManager == null)
                boardManager = FindObjectOfType<BoardManager>();
            
            // Initialiser les wallets
            playerBank = new ResourceBank(startingGold, startingMana, startingWisdom);
            
            Debug.Log($"[EconomyManager] ✓ Initialisé: {playerBank}");
        }
        
        // ========== MÉTHODES TRANSACTIONNELLES ==========
        
        /// <summary>
        /// Ajoute une ressource au wallet.
        /// 
        /// Exemples:
        /// - AddResource(ResourceType.Gold, 5)     // +5 Or
        /// - AddResource(ResourceType.Mana, 2)     // +2 Mana
        /// - AddResource(ResourceType.Wisdom, 1)   // +1 Sagesse
        /// </summary>
        public void AddResource(ResourceType type, int amount)
        {
            if (amount < 0)
            {
                Debug.LogWarning($"[EconomyManager] Cannot add negative: {amount}");
                return;
            }
            
            int oldAmount = playerBank.GetResourceAmount(type);
            playerBank.AddResource(type, amount);
            int newAmount = playerBank.GetResourceAmount(type);
            
            // Émettre l'event si changement
            if (newAmount != oldAmount)
            {
                OnResourceChanged?.Invoke(type, newAmount, oldAmount);
                Debug.Log($"[EconomyManager] +{newAmount - oldAmount} {type} (new: {newAmount}/{playerBank.GetResourceMax(type)})");
                
                // Vérifier si max atteint
                if (newAmount == playerBank.GetResourceMax(type))
                    OnResourceMaxed?.Invoke(type);
            }
        }
        
        /// <summary>
        /// Essaie de dépenser une ressource.
        /// 
        /// Retourne true si succès, false si insuffisant.
        /// 
        /// Exemples:
        /// - if (TrySpendResource(Gold, 10))       // Invoquer créature (10 Or)
        /// - if (TrySpendResource(Mana, 5))        // Lancer sort (5 Mana)
        /// - if (TrySpendResource(Wisdom, 3))      // Pouvoir spécial (3 Sagesse)
        /// </summary>
        public bool TrySpendResource(ResourceType type, int amount)
        {
            if (amount < 0)
            {
                Debug.LogWarning($"[EconomyManager] Cannot spend negative: {amount}");
                return false;
            }
            
            // Vérifier suffisance
            int current = playerBank.GetResourceAmount(type);
            if (current < amount)
            {
                OnInsufficientResources?.Invoke(type, amount, current);
                Debug.LogWarning($"[EconomyManager] ❌ Insuffisant {type}: {current}/{amount}");
                return false;
            }
            
            // Dépenser
            if (!playerBank.TrySpendResource(type, amount))
                return false;
            
            int newAmount = playerBank.GetResourceAmount(type);
            OnResourceSpent?.Invoke(type, amount);
            OnResourceChanged?.Invoke(type, newAmount, current);
            
            Debug.Log($"[EconomyManager] -{amount} {type} (reste: {newAmount})");
            
            return true;
        }
        
        /// <summary>
        /// Force la dépense (ne vérifie pas si suffisant).
        /// À utiliser avec prudence (ex: événements spéciaux).
        /// </summary>
        public void ForceSpendResource(ResourceType type, int amount)
        {
            if (amount < 0)
            {
                Debug.LogWarning($"[EconomyManager] Cannot force spend negative: {amount}");
                return;
            }
            
            int oldAmount = playerBank.GetResourceAmount(type);
            playerBank.TrySpendResource(type, amount);
            int newAmount = playerBank.GetResourceAmount(type);
            
            OnResourceChanged?.Invoke(type, newAmount, oldAmount);
            
            Debug.Log($"[EconomyManager] FORCE -{amount} {type} (reste: {newAmount})");
        }
        
        // ========== PROPRIÉTÉS D'ACCÈS ==========
        
        public int GetResourceAmount(ResourceType type) => playerBank.GetResourceAmount(type);
        public int GetResourceMax(ResourceType type) => playerBank.GetResourceMax(type);
        public float GetResourcePercent(ResourceType type) => playerBank.GetResourcePercent(type);
        public ResourceBank GetWallet() => playerBank;
        
        /// <summary>
        /// Debug: affiche l'état actuel des ressources.
        /// </summary>
        public void PrintDebugInfo()
        {
            Debug.Log($"[EconomyManager] {playerBank}");
        }
    }
}
```

---

## 4. SYSTÈME DE PRODUCTION - PROCESSTTURNINCOME()

### 🏭 IncomeProcessor.cs - Producteur de Revenu

```csharp
using UnityEngine;
using System.Collections.Generic;
using OctagonalChess.Core;
using OctagonalChess.Gameplay;

namespace OctagonalChess.Economy
{
    /// <summary>
    /// IncomeProcessor = Logique de production des ressources chaque tour.
    /// 
    /// Règles (basées sur le PDF):
    /// 1. Roi Marchand vivant → +1 Or
    /// 2. Fou Mystique en état "Transe" → +1 Mana
    /// 3. Reine Philosophe immobile → +1 Sagesse
    /// 
    /// Bonus:
    /// - Case Bonus présente → doubler le gain
    /// 
    /// Cette classe est appelée par le TurnManager à chaque début de tour.
    /// </summary>
    public class IncomeProcessor : MonoBehaviour
    {
        [Header("🎮 Références")]
        [SerializeField] private BoardManager boardManager;
        [SerializeField] private EconomyManager economyManager;
        [SerializeField] private GridManager gridManager;  // Pour vérifier cases bonus
        
        [Header("📊 Production Base")]
        [SerializeField] private int merchantKingIncomePerTurn = 1;
        [SerializeField] private int mysticBishopIncomePerTurn = 1;
        [SerializeField] private int philosopherQueenIncomePerTurn = 1;
        
        [Header("🎁 Bonus Cases")]
        [SerializeField] private int bonusMultiplier = 2;  // Doubler les gains
        
        private void Start()
        {
            if (boardManager == null)
                boardManager = FindObjectOfType<BoardManager>();
            
            if (economyManager == null)
                economyManager = EconomyManager.Instance;
            
            if (gridManager == null)
                gridManager = FindObjectOfType<GridManager>();
        }
        
        /// <summary>
        /// Traite le revenu du tour.
        /// 
        /// À appeler au DÉBUT de chaque tour:
        /// TurnManager → IncomeProcessor.ProcessTurnIncome()
        /// </summary>
        public void ProcessTurnIncome()
        {
            Debug.Log("[IncomeProcessor] 💰 === DÉBUT TOUR - PRODUCTION RESSOURCES ===");
            
            int totalGoldProduced = 0;
            int totalManaProduced = 0;
            int totalWisdomProduced = 0;
            
            // ========== 1. DÉTECTION PIÈCES SPÉCIALES ==========
            
            // Chercher Roi Marchand
            var merchantKings = FindPiecesOfType("Roi_Marchand");
            foreach (var king in merchantKings)
            {
                if (!king.IsAlive) continue;
                
                int goldGain = merchantKingIncomePerTurn;
                
                // Bonus si case bonus
                if (IsOnBonusSquare(king))
                {
                    goldGain *= bonusMultiplier;
                    Debug.Log($"[IncomeProcessor] 🌟 {king.PieceName} sur case BONUS!");
                }
                
                economyManager.AddResource(ResourceType.Gold, goldGain);
                totalGoldProduced += goldGain;
                
                Debug.Log($"[IncomeProcessor] 👑 {king.PieceName} produit +{goldGain} Or");
            }
            
            // Chercher Fou Mystique en état "Transe"
            var mysticBishops = FindPiecesOfType("Fou_Mystique");
            foreach (var bishop in mysticBishops)
            {
                if (!bishop.IsAlive) continue;
                
                // Vérifier l'état "Transe" (à implémenter selon votre système d'état)
                if (!IsInTranceState(bishop)) continue;
                
                int manaGain = mysticBishopIncomePerTurn;
                
                if (IsOnBonusSquare(bishop))
                {
                    manaGain *= bonusMultiplier;
                    Debug.Log($"[IncomeProcessor] 🌟 {bishop.PieceName} sur case BONUS!");
                }
                
                economyManager.AddResource(ResourceType.Mana, manaGain);
                totalManaProduced += manaGain;
                
                Debug.Log($"[IncomeProcessor] 🔵 {bishop.PieceName} (Transe) produit +{manaGain} Mana");
            }
            
            // Chercher Reine Philosophe immobile
            var philosopherQueens = FindPiecesOfType("Reine_Philosophe");
            foreach (var queen in philosopherQueens)
            {
                if (!queen.IsAlive) continue;
                
                // Vérifier si immobile (n'a pas bougé ce tour)
                if (!IsIdle(queen)) continue;
                
                int wisdomGain = philosopherQueenIncomePerTurn;
                
                if (IsOnBonusSquare(queen))
                {
                    wisdomGain *= bonusMultiplier;
                    Debug.Log($"[IncomeProcessor] 🌟 {queen.PieceName} sur case BONUS!");
                }
                
                economyManager.AddResource(ResourceType.Wisdom, wisdomGain);
                totalWisdomProduced += wisdomGain;
                
                Debug.Log($"[IncomeProcessor] ✨ {queen.PieceName} (immobile) produit +{wisdomGain} Sagesse");
            }
            
            // ========== 2. ÉMETTRE L'ÉVÉNEMENT GLOBAL ==========
            
            Debug.Log($"[IncomeProcessor] 💰 TOTAL: +{totalGoldProduced} Or, +{totalManaProduced} Mana, +{totalWisdomProduced} Sagesse");
        }
        
        // ========== MÉTHODES AUXILIAIRES ==========
        
        /// <summary>
        /// Trouve toutes les pièces d'un type spécifique.
        /// </summary>
        private List<PieceInstance> FindPiecesOfType(string pieceName)
        {
            var results = new List<PieceInstance>();
            
            // À adapter selon votre système (parcourir BoardManager)
            // Exemple simplifié:
            var allPieces = FindObjectsOfType<PieceInstance>();
            foreach (var piece in allPieces)
            {
                if (piece.PieceName.Contains(pieceName) && piece.IsAlive)
                    results.Add(piece);
            }
            
            return results;
        }
        
        /// <summary>
        /// Vérifie si une pièce est sur une case bonus.
        /// </summary>
        private bool IsOnBonusSquare(PieceInstance piece)
        {
            if (gridManager == null)
                return false;
            
            // À adapter selon votre système de grid
            // Exemple: vérifier si position est dans liste des cases bonus
            return gridManager.IsBonusSquare(piece.transform.position);
        }
        
        /// <summary>
        /// Vérifie si une pièce est en état "Transe".
        /// </summary>
        private bool IsInTranceState(PieceInstance piece)
        {
            // À adapter selon votre système d'état
            // Pour l'instant: retourner true si aucun buff de mouvement
            // ou implémenter un StateManager
            return true;  // Placeholder
        }
        
        /// <summary>
        /// Vérifie si une pièce est immobile (n'a pas bougé ce tour).
        /// </summary>
        private bool IsIdle(PieceInstance piece)
        {
            // À adapter selon votre système de mouvement
            // Exemple: tracker lastMovedTurn et comparer à currentTurn
            return true;  // Placeholder
        }
    }
    
    // ========== EXTENSION: TYPES DE PIÈCES SPÉCIALES ==========
    
    /// <summary>
    /// Enum de tous les types de pièces avec pouvoirs économiques.
    /// </summary>
    public enum EconomicPieceType
    {
        MerchantKing,        // Roi Marchand → Or
        MysticBishop,        // Fou Mystique → Mana
        PhilosopherQueen,    // Reine Philosophe → Sagesse
        None                 // Pièce normale
    }
}
```

---

## 5. MÉCANIQUES DE DÉPENSE

### 💸 SpendingSystem.cs - Utilisation des Ressources

```csharp
using UnityEngine;
using OctagonalChess.Economy;

namespace OctagonalChess.Gameplay
{
    /// <summary>
    /// SpendingSystem = Gère les actions qui coûtent des ressources.
    /// 
    /// Exemples:
    /// - Invoquer une créature (coûte Or)
    /// - Lancer un sort (coûte Mana)
    /// - Activer un pouvoir (coûte Sagesse)
    /// </summary>
    public class SpendingSystem : MonoBehaviour
    {
        private EconomyManager economy = null;
        
        // ========== CONFIGURATION DES COÛTS ==========
        
        [Header("💰 Coûts en Or")]
        [SerializeField] private int summonBasicCreatureCost = 5;
        [SerializeField] private int summonEliteCreatureCost = 10;
        
        [Header("🔵 Coûts en Mana")]
        [SerializeField] private int castBasicSpellCost = 3;
        [SerializeField] private int castUltimateSpellCost = 15;
        
        [Header("✨ Coûts en Sagesse")]
        [SerializeField] private int activateWisdomPowerCost = 5;
        
        private void Start()
        {
            economy = EconomyManager.Instance;
        }
        
        // ========== ACTIONS COÛTEUSES ==========
        
        /// <summary>
        /// Invoque une créature basique (coûte 5 Or).
        /// </summary>
        public bool TrySummonBasicCreature()
        {
            if (economy.TrySpendResource(ResourceType.Gold, summonBasicCreatureCost))
            {
                Debug.Log($"[SpendingSystem] ✓ Créature basique invoquée (-{summonBasicCreatureCost} Or)");
                // Créer la créature ici
                return true;
            }
            
            Debug.LogWarning("[SpendingSystem] ❌ Pas assez d'Or pour invoquer une créature basique");
            return false;
        }
        
        /// <summary>
        /// Invoque une créature élite (coûte 10 Or).
        /// </summary>
        public bool TrySummonEliteCreature()
        {
            if (economy.TrySpendResource(ResourceType.Gold, summonEliteCreatureCost))
            {
                Debug.Log($"[SpendingSystem] ✓ Créature élite invoquée (-{summonEliteCreatureCost} Or)");
                return true;
            }
            
            Debug.LogWarning("[SpendingSystem] ❌ Pas assez d'Or pour invoquer une créature élite");
            return false;
        }
        
        /// <summary>
        /// Lance un sort basique (coûte 3 Mana).
        /// </summary>
        public bool TryCastBasicSpell()
        {
            if (economy.TrySpendResource(ResourceType.Mana, castBasicSpellCost))
            {
                Debug.Log($"[SpendingSystem] ✓ Sort basique lancé (-{castBasicSpellCost} Mana)");
                return true;
            }
            
            Debug.LogWarning("[SpendingSystem] ❌ Pas assez de Mana pour lancer un sort basique");
            return false;
        }
        
        /// <summary>
        /// Lance un sort ultime (coûte 15 Mana).
        /// </summary>
        public bool TryCastUltimateSpell()
        {
            if (economy.TrySpendResource(ResourceType.Mana, castUltimateSpellCost))
            {
                Debug.Log($"[SpendingSystem] ✓ Sort ultime lancé (-{castUltimateSpellCost} Mana)!");
                return true;
            }
            
            Debug.LogWarning("[SpendingSystem] ❌ Pas assez de Mana pour lancer un sort ultime");
            return false;
        }
        
        /// <summary>
        /// Active un pouvoir philosophique (coûte 5 Sagesse).
        /// </summary>
        public bool TryActivateWisdomPower()
        {
            if (economy.TrySpendResource(ResourceType.Wisdom, activateWisdomPowerCost))
            {
                Debug.Log($"[SpendingSystem] ✓ Pouvoir philosophique activé (-{activateWisdomPowerCost} Sagesse)");
                return true;
            }
            
            Debug.LogWarning("[SpendingSystem] ❌ Pas assez de Sagesse pour activer le pouvoir");
            return false;
        }
        
        // ========== UTILITAIRES ==========
        
        /// <summary>
        /// Retourne le coût d'une action spécifique.
        /// </summary>
        public int GetActionCost(ActionType action)
        {
            return action switch
            {
                ActionType.SummonBasic => summonBasicCreatureCost,
                ActionType.SummonElite => summonEliteCreatureCost,
                ActionType.CastBasicSpell => castBasicSpellCost,
                ActionType.CastUltimateSpell => castUltimateSpellCost,
                ActionType.ActivateWisdomPower => activateWisdomPowerCost,
                _ => 0
            };
        }
    }
    
    public enum ActionType
    {
        SummonBasic,
        SummonElite,
        CastBasicSpell,
        CastUltimateSpell,
        ActivateWisdomPower
    }
}
```

---

## 6. INTÉGRATION CASES BONUS

### 🎁 GridManager avec Détection Bonus

```csharp
using UnityEngine;
using System.Collections.Generic;

namespace OctagonalChess.Gameplay
{
    /// <summary>
    /// GridManager = Gère le plateau (cases, positions, bonus).
    /// 
    /// Cases Bonus: certaines cases doublent le revenu économique.
    /// </summary>
    public class GridManager : MonoBehaviour
    {
        [Header("🎮 Grille")]
        [SerializeField] private int gridWidth = 8;
        [SerializeField] private int gridHeight = 8;
        
        [Header("🎁 Cases Bonus")]
        [SerializeField] private List<Vector2Int> bonusSquares = new List<Vector2Int>();
        [SerializeField] private Material bonusSquareMaterial;  // Visual
        
        // Cache des cases bonus pour recherche rapide
        private HashSet<Vector3Int> bonusCache = new HashSet<Vector3Int>();
        
        private void Start()
        {
            // Initialiser le cache
            foreach (var bonus in bonusSquares)
            {
                bonusCache.Add(new Vector3Int(bonus.x, 0, bonus.y));
            }
            
            Debug.Log($"[GridManager] ✓ {bonusCache.Count} cases bonus détectées");
        }
        
        /// <summary>
        /// Vérifie si une position est une case bonus.
        /// </summary>
        public bool IsBonusSquare(Vector3 worldPos)
        {
            Vector3Int gridPos = GetGridPosition(worldPos);
            return bonusCache.Contains(gridPos);
        }
        
        /// <summary>
        /// Convertit une position mondiale en position grille.
        /// </summary>
        public Vector3Int GetGridPosition(Vector3 worldPos)
        {
            return new Vector3Int(
                Mathf.RoundToInt(worldPos.x),
                0,
                Mathf.RoundToInt(worldPos.z)
            );
        }
        
        /// <summary>
        /// Retourne la liste des cases bonus.
        /// </summary>
        public List<Vector2Int> GetBonusSquares() => bonusSquares;
    }
}
```

---

## 7. GESTION UI AVEC EVENTS

### 🎨 ResourceUI.cs - Affichage des Ressources

```csharp
using UnityEngine;
using UnityEngine.UI;
using OctagonalChess.Economy;

namespace OctagonalChess.UI
{
    /// <summary>
    /// ResourceUI = Met à jour l'interface des ressources en temps réel.
    /// 
    /// Utilise les events d'EconomyManager pour rester synchronisée.
    /// </summary>
    public class ResourceUI : MonoBehaviour
    {
        [Header("📊 Affichages Or")]
        [SerializeField] private Text goldText;           // "10/100"
        [SerializeField] private Slider goldSlider;       // Barre visuelle
        [SerializeField] private Image goldFillImage;     // Couleur barre
        
        [Header("🔵 Affichages Mana")]
        [SerializeField] private Text manaText;           // "5/50"
        [SerializeField] private Slider manaSlider;       // Barre visuelle
        [SerializeField] private Image manaFillImage;     // Couleur barre
        
        [Header("✨ Affichages Sagesse")]
        [SerializeField] private Text wisdomText;         // "3/30"
        [SerializeField] private Slider wisdomSlider;     // Barre visuelle
        [SerializeField] private Image wisdomFillImage;   // Couleur barre
        
        [Header("⚙️ Animations")]
        [SerializeField] private float updateDuration = 0.3f;
        
        private EconomyManager economy;
        
        private void Start()
        {
            economy = EconomyManager.Instance;
            
            // S'enregistrer aux events
            economy.OnResourceChanged += OnResourceChanged;
            economy.OnInsufficientResources += OnInsufficientResources;
            economy.OnResourceMaxed += OnResourceMaxed;
            
            // Initialiser l'affichage
            RefreshAllUI();
        }
        
        /// <summary>
        /// Met à jour l'UI pour une ressource spécifique.
        /// </summary>
        private void OnResourceChanged(ResourceType type, int newAmount, int oldAmount)
        {
            switch (type)
            {
                case ResourceType.Gold:
                    UpdateGoldUI(newAmount);
                    break;
                case ResourceType.Mana:
                    UpdateManaUI(newAmount);
                    break;
                case ResourceType.Wisdom:
                    UpdateWisdomUI(newAmount);
                    break;
            }
        }
        
        private void UpdateGoldUI(int currentGold)
        {
            int maxGold = economy.GetResourceMax(ResourceType.Gold);
            
            if (goldText != null)
                goldText.text = $"{currentGold}/{maxGold}";
            
            if (goldSlider != null)
            {
                goldSlider.maxValue = maxGold;
                goldSlider.value = currentGold;
            }
            
            if (goldFillImage != null)
            {
                // Gradient: vert → orange → rouge
                float percent = (float)currentGold / maxGold;
                goldFillImage.color = Color.Lerp(Color.red, Color.green, percent);
            }
        }
        
        private void UpdateManaUI(int currentMana)
        {
            int maxMana = economy.GetResourceMax(ResourceType.Mana);
            
            if (manaText != null)
                manaText.text = $"{currentMana}/{maxMana}";
            
            if (manaSlider != null)
            {
                manaSlider.maxValue = maxMana;
                manaSlider.value = currentMana;
            }
            
            if (manaFillImage != null)
            {
                float percent = (float)currentMana / maxMana;
                manaFillImage.color = Color.Lerp(new Color(0.2f, 0.2f, 1f), new Color(0, 1, 1), percent);
            }
        }
        
        private void UpdateWisdomUI(int currentWisdom)
        {
            int maxWisdom = economy.GetResourceMax(ResourceType.Wisdom);
            
            if (wisdomText != null)
                wisdomText.text = $"{currentWisdom}/{maxWisdom}";
            
            if (wisdomSlider != null)
            {
                wisdomSlider.maxValue = maxWisdom;
                wisdomSlider.value = currentWisdom;
            }
            
            if (wisdomFillImage != null)
            {
                float percent = (float)currentWisdom / maxWisdom;
                wisdomFillImage.color = Color.Lerp(new Color(1f, 1f, 0f), new Color(1, 0.5f, 0), percent);
            }
        }
        
        /// <summary>
        /// Affiche une alerte si ressource insuffisante.
        /// </summary>
        private void OnInsufficientResources(ResourceType type, int needed, int available)
        {
            Debug.LogWarning($"[ResourceUI] ❌ Insuffisant {type}: {available}/{needed}");
            
            // Animer l'alerte (ex: secouer la barre)
            StartCoroutine(ShakeResourceBar(type));
        }
        
        /// <summary>
        /// Animation quand une ressource atteint le max.
        /// </summary>
        private void OnResourceMaxed(ResourceType type)
        {
            Debug.Log($"[ResourceUI] 🌟 {type} MAXÉE!");
            
            // Animer (ex: particules, bruit)
            StartCoroutine(MaxedAnimation(type));
        }
        
        private System.Collections.IEnumerator ShakeResourceBar(ResourceType type)
        {
            Image barImage = type switch
            {
                ResourceType.Gold => goldFillImage,
                ResourceType.Mana => manaFillImage,
                ResourceType.Wisdom => wisdomFillImage,
                _ => null
            };
            
            if (barImage == null) yield break;
            
            Vector3 originalPos = barImage.transform.localPosition;
            float elapsed = 0f;
            
            while (elapsed < 0.3f)
            {
                barImage.transform.localPosition = originalPos + (Vector3)Random.insideUnitCircle * 5f;
                elapsed += Time.deltaTime;
                yield return null;
            }
            
            barImage.transform.localPosition = originalPos;
        }
        
        private System.Collections.IEnumerator MaxedAnimation(ResourceType type)
        {
            Image barImage = type switch
            {
                ResourceType.Gold => goldFillImage,
                ResourceType.Mana => manaFillImage,
                ResourceType.Wisdom => wisdomFillImage,
                _ => null
            };
            
            if (barImage == null) yield break;
            
            // Animation d'"éclat"
            for (int i = 0; i < 5; i++)
            {
                barImage.color = Color.white;
                yield return new WaitForSeconds(0.1f);
                barImage.color = Color.gray;
                yield return new WaitForSeconds(0.1f);
            }
            
            barImage.color = Color.white;
        }
        
        private void RefreshAllUI()
        {
            UpdateGoldUI(economy.GetResourceAmount(ResourceType.Gold));
            UpdateManaUI(economy.GetResourceAmount(ResourceType.Mana));
            UpdateWisdomUI(economy.GetResourceAmount(ResourceType.Wisdom));
        }
        
        private void OnDestroy()
        {
            if (economy != null)
            {
                economy.OnResourceChanged -= OnResourceChanged;
                economy.OnInsufficientResources -= OnInsufficientResources;
                economy.OnResourceMaxed -= OnResourceMaxed;
            }
        }
    }
}
```

---

## 8. EXTENSIBILITÉ - NOUVELLES RESSOURCES

### 🔮 Ajouter une 4e Ressource (Souls)

```csharp
// ÉTAPE 1: Ajouter à ResourceType enum
public enum ResourceType
{
    Gold,
    Mana,
    Wisdom,
    Souls  // ← NOUVEAU
}

// ÉTAPE 2: Ajouter à ResourceBank struct
public struct ResourceBank
{
    private int souls;  // ← NOUVEAU
    public static readonly int MAX_SOULS = 20;  // ← NOUVEAU
    
    // Ajouter properties et logique...
}

// ÉTAPE 3: Ajouter à EconomyManager
[SerializeField] private int startingSouls = 0;  // ← NOUVEAU

// ÉTAPE 4: Ajouter à IncomeProcessor
var necromancerQueens = FindPiecesOfType("Reine_Nécromancienne");
foreach (var queen in necromancerQueens)
{
    economyManager.AddResource(ResourceType.Souls, 1);  // ← NOUVEAU
}

// ÉTAPE 5: Ajouter à ResourceUI
[SerializeField] private Text soulsText;
[SerializeField] private Slider soulsSlider;
[SerializeField] private Image soulsFillImage;

// ✓ Système prêt pour nouvelles ressources!
```

---

## 9. EXEMPLES D'UTILISATION

### 📝 Scénario 1: Invoquer une Créature

```csharp
// Joueur clique sur bouton "Invoquer"
public void OnInvokeButtonClicked()
{
    var spendingSystem = GetComponent<SpendingSystem>();
    
    // Essayer de dépenser 10 Or
    if (spendingSystem.TrySummonBasicCreature())
    {
        // ✓ Succès: créature créée, Or déduit
        // UI se met à jour automatiquement via events
    }
    else
    {
        // ❌ Échec: pas assez d'Or
        // UI affiche alerte "Ressources insuffisantes"
    }
}
```

### 📝 Scénario 2: Début de Tour avec Production

```csharp
// TurnManager appelle IncomeProcessor au début du tour
public void OnTurnStart()
{
    // 1. Traiter le revenu
    incomeProcessor.ProcessTurnIncome();
    
    // Logs:
    // [IncomeProcessor] 👑 Roi_Marchand produit +1 Or
    // [IncomeProcessor] 🔵 Fou_Mystique (Transe) produit +1 Mana
    // [IncomeProcessor] ✨ Reine_Philosophe (immobile) produit +1 Sagesse
    
    // 2. UI se met à jour automatiquement
    // ResourceUI reçoit events et rafraîchit barres
    
    // 3. Continuer le tour
    StartPlayerTurn();
}
```

### 📝 Scénario 3: Revenu sur Case Bonus

```csharp
// Roi Marchand stand sur case bonus → revenu doublé

// Setup initial:
// - Roi Marchand à position (4, 4)
// - Case bonus à (4, 4)
// - gridManager.bonusSquares = [(4, 4)]

// Au début du tour:
incomeProcessor.ProcessTurnIncome();

// Résultat:
// [IncomeProcessor] 👑 Roi_Marchand produit +1 Or
// [IncomeProcessor] 🌟 Roi_Marchand sur case BONUS!
// [IncomeProcessor] 👑 Roi_Marchand produit +2 Or (au lieu de +1)
```

---

## 10. SÉCURITÉ & VALIDATION

### 🔒 Checklist de Sécurité

```csharp
// ✓ Ressources ne peuvent pas être négatives
if (amount < 0)
{
    Debug.LogWarning("[EconomyManager] Cannot add negative amount");
    return;  // Rejeter
}

// ✓ Ressources ne peuvent pas dépasser max
Gold = Mathf.Clamp(newValue, 0, MAX_GOLD);

// ✓ Dépense validée avant exécution
if (current < amount)
    return false;  // Insuffisant

// ✓ Transactions toutes loggées
Debug.Log($"[EconomyManager] -{amount} {type}");

// ✓ Events notifient l'UI (pas de polling)
OnResourceChanged?.Invoke(type, newAmount, oldAmount);

// ✓ Singleton centralisé (une seule source de vérité)
public static EconomyManager Instance { get; }
```

---

## RÉSUMÉ DE L'ARCHITECTURE

### 📦 Modules et Interactions

```
┌─────────────────────────────────────────────────────┐
│ ResourceBank (Struct)                               │
│ - Gold, Mana, Wisdom (avec max)                     │
│ - AddResource(), TrySpendResource()                 │
└────────┬────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────┐
│ EconomyManager (Singleton)                          │
│ - Gère le wallet du joueur                          │
│ - Valide transactions                               │
│ - Émet events pour l'UI                             │
└────────┬────────────────────────────────────────────┘
         │
    ┌────┴────┬─────────────────┐
    ▼         ▼                 ▼
    │         │                 │
    ▼         ▼                 ▼
IncomeProcessor  SpendingSystem  ResourceUI
(Production)      (Dépense)       (Affichage)
- Roi Marchand    - Invoquer      - Barres
- Fou Mystique    - Lancer sort   - Texte
- Reine Philo     - Pouvoir       - Alertes
```

---

**Architecture économique complète et prête pour production!** 🚀💰
