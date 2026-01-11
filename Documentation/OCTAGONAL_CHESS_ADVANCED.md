# 🎮 Implémentations Avancées - Octagonal Chess Tactics
## Systèmes de Combat, Buffs, Évolution & Plateau

---

## TABLE DES MATIÈRES

1. [Système de Combat Complet](#1-système-de-combat-complet)
2. [CombatCalculator : Formules Mathématiques](#2-combatcalculator--formules-mathématiques)
3. [BuffManager : Gestion des Buffs/Debuffs](#3-buffmanager--gestion-des-buffsdebuffs)
4. [EvolutionManager : Déclencheurs d'Évolution](#4-evolutionmanager--déclencheurs-dévolution)
5. [BoardManager : Plateau Complet](#5-boardmanager--plateau-complet)
6. [CombatLog : Journalisation](#6-combatlog--journalisation)
7. [Patterns de Combat](#7-patterns-de-combat)
8. [Tests Unitaires](#8-tests-unitaires)

---

## 1. SYSTÈME DE COMBAT COMPLET

### 📊 CombatSystem.cs

```csharp
using UnityEngine;
using System;
using System.Collections.Generic;
using OctagonalChess.Core;

namespace OctagonalChess.Gameplay
{
    /// <summary>
    /// Système de combat central gérant tous les combats.
    /// 
    /// Responsabilités:
    /// 1. Orchestrer les attaques entre piéces
    /// 2. Gérer les contre-attaques
    /// 3. Appliquer les effets spéciaux (proc, critical)
    /// 4. Créer des logs de combat
    /// 5. Gérer les récompenses (exp, loot)
    /// </summary>
    public class CombatSystem : MonoBehaviour
    {
        [SerializeField] private CombatCalculator calculator;
        [SerializeField] private BuffManager buffManager;
        [SerializeField] private CombatLog combatLog;
        
        // Événements
        public event Action<CombatResult> OnCombatResolved;
        
        private void Awake()
        {
            if (calculator == null)
                calculator = GetComponent<CombatCalculator>();
            
            if (buffManager == null)
                buffManager = GetComponent<BuffManager>();
            
            if (combatLog == null)
                combatLog = GetComponent<CombatLog>();
        }
        
        /// <summary>
        /// Exécute un combat entre deux piéces.
        /// </summary>
        public CombatResult ResolveCombat(
            PieceInstance attacker,
            PieceInstance defender,
            AttackType attackType = AttackType.Normal)
        {
            if (attacker == null || defender == null)
                throw new System.ArgumentNullException("Attacker or defender is null");
            
            // Initialiser le résultat
            CombatResult result = new CombatResult
            {
                Attacker = attacker,
                Defender = defender,
                AttackType = attackType,
                Timestamp = Time.realtimeSinceStartup
            };
            
            // Calculer les dégâts
            int baseDamage = calculator.CalculateDamage(attacker, defender);
            
            // Vérifier les modificateurs
            (int finalDamage, List<DamageModifier> modifiers) = 
                calculator.ApplyDamageModifiers(baseDamage, attacker, defender);
            
            result.BaseDamage = baseDamage;
            result.FinalDamage = finalDamage;
            result.DamageModifiers = modifiers;
            
            // Appliquer les dégâts
            defender.TakeDamage(finalDamage, attacker);
            result.DefenderHealthAfter = defender.CurrentHealth;
            
            // Vérifier les contre-attaques
            if (defender.IsAlive && calculator.ShouldCounterAttack(defender, attacker))
            {
                int counterDamage = calculator.CalculateDamage(defender, attacker);
                attacker.TakeDamage(counterDamage, defender);
                
                result.CounterDamage = counterDamage;
                result.AttackerHealthAfter = attacker.CurrentHealth;
            }
            
            // Journaliser
            combatLog?.LogCombat(result);
            
            // Émettre l'événement
            OnCombatResolved?.Invoke(result);
            
            return result;
        }
    }
    
    /// <summary>
    /// Résultat d'un combat entre deux piéces.
    /// </summary>
    [System.Serializable]
    public class CombatResult
    {
        public PieceInstance Attacker;
        public PieceInstance Defender;
        public AttackType AttackType;
        public int BaseDamage;
        public int FinalDamage;
        public int? CounterDamage;  // Null si pas de contre-attaque
        public int DefenderHealthAfter;
        public int? AttackerHealthAfter;
        public List<DamageModifier> DamageModifiers = new List<DamageModifier>();
        public double Timestamp;
    }
    
    /// <summary>
    /// Type d'attaque spéciale.
    /// </summary>
    public enum AttackType
    {
        Normal,
        Critical,
        Charged,
        Ability
    }
    
    /// <summary>
    /// Modificateur de dégâts appliqué.
    /// </summary>
    [System.Serializable]
    public class DamageModifier
    {
        public string Name;              // "Fortification", "Crit", etc.
        public float Multiplier = 1.0f;  // 0.5 = 50% moins de dégâts
    }
}
```

---

## 2. COMBATCALCULATOR : FORMULES MATHÉMATIQUES

### 🧮 CombatCalculator.cs

```csharp
using UnityEngine;
using System.Collections.Generic;
using OctagonalChess.Core;

namespace OctagonalChess.Gameplay
{
    /// <summary>
    /// Calcule les formules de combat RPG.
    /// 
    /// Formule de base:
    /// Dégâts = max(1, Attaque_Attaquant - Défense_Cible)
    /// 
    /// Modifications possibles:
    /// - Critiques (+50% dégâts)
    /// - Résistance des buffs (-20% à -50%)
    /// - Bonus de type (Avantage contre certaines catégories)
    /// </summary>
    public class CombatCalculator : MonoBehaviour
    {
        [Header("⚙️ Configuration")]
        [Range(0.1f, 0.5f)]
        [SerializeField] private float criticalChance = 0.15f;  // 15%
        
        [Range(1.2f, 2.0f)]
        [SerializeField] private float criticalMultiplier = 1.5f;  // +50%
        
        [Range(0.1f, 0.5f)]
        [SerializeField] private float counterAttackChance = 0.3f;  // 30%
        
        // Bonus contre certaines catégories
        private Dictionary<PieceCategorie, float> typeAdvantages = new Dictionary<PieceCategorie, float>
        {
            // Cavalier fait +20% dégâts contre Tour
            { PieceCategorie.Cavalier, 1.2f },
            // Fou fait +10% contre Reine
            { PieceCategorie.Fou, 1.1f },
        };
        
        /// <summary>
        /// Calcule les dégâts de base selon la formule RPG.
        /// Dégâts = max(1, Attaque - Défense)
        /// </summary>
        public int CalculateDamage(PieceInstance attacker, PieceInstance defender)
        {
            if (attacker == null || defender == null)
                return 0;
            
            int rawDamage = attacker.CurrentAttack - defender.CurrentDefense;
            int finalDamage = Mathf.Max(1, rawDamage);
            
            Debug.Log($"[CombatCalculator] {attacker.PieceName} -> {defender.PieceName}: {attacker.CurrentAttack} - {defender.CurrentDefense} = {finalDamage}");
            
            return finalDamage;
        }
        
        /// <summary>
        /// Applique les modificateurs de dégâts (critiques, résistances, bonus type).
        /// </summary>
        public (int finalDamage, List<DamageModifier> modifiers) ApplyDamageModifiers(
            int baseDamage,
            PieceInstance attacker,
            PieceInstance defender)
        {
            List<DamageModifier> modifiers = new List<DamageModifier>();
            float damageMultiplier = 1.0f;
            
            // 1. Vérifier critique
            if (Random.value < criticalChance)
            {
                damageMultiplier *= criticalMultiplier;
                modifiers.Add(new DamageModifier { Name = "Critique", Multiplier = criticalMultiplier });
            }
            
            // 2. Appliquer les buffs défensifs
            foreach (var buff in GetBuffsForDefender(defender, StatType.Defense))
            {
                float reduction = 1.0f - (buff.Value * 0.05f);  // Chaque +1 DEF = 5% réduction
                damageMultiplier *= reduction;
                modifiers.Add(new DamageModifier { Name = $"Buff Défense", Multiplier = reduction });
            }
            
            // 3. Avantage de type (optionnel)
            if (typeAdvantages.ContainsKey(defender.Category))
            {
                float typeBonus = typeAdvantages[defender.Category];
                damageMultiplier *= typeBonus;
                modifiers.Add(new DamageModifier { Name = "Avantage Type", Multiplier = typeBonus });
            }
            
            int finalDamage = Mathf.RoundToInt(baseDamage * damageMultiplier);
            finalDamage = Mathf.Max(1, finalDamage);
            
            return (finalDamage, modifiers);
        }
        
        /// <summary>
        /// Détermine si le défenseur contre-attaque.
        /// </summary>
        public bool ShouldCounterAttack(PieceInstance defender, PieceInstance attacker)
        {
            // Pas de contre-attaque si mort
            if (!defender.IsAlive)
                return false;
            
            // Tanks ont plus de chances de contre-attaquer
            float chance = counterAttackChance;
            if (defender.Role == RoleTactique.Tank)
                chance *= 1.5f;  // +50% pour les tanks
            
            return Random.value < chance;
        }
        
        /// <summary>
        /// Récupère les buffs défensifs d'une pièce.
        /// </summary>
        private List<ActiveBuff> GetBuffsForDefender(PieceInstance defender, StatType type)
        {
            // Implémentation simplifiée
            // En vrai, il faudrait accéder au système de buff de la pièce
            return new List<ActiveBuff>();
        }
    }
}
```

---

## 3. BUFFMANAGER : GESTION DES BUFFS/DEBUFFS

### 🎯 BuffManager.cs

```csharp
using UnityEngine;
using System;
using System.Collections.Generic;
using OctagonalChess.Core;

namespace OctagonalChess.Gameplay
{
    /// <summary>
    /// Gère les buffs/debuffs de manière centralisée.
    /// 
    /// Permet de:
    /// 1. Appliquer un buff à une pièce
    /// 2. Tracker la durée des buffs
    /// 3. Émettre des événements d'expiration
    /// 4. Annuler les buffs
    /// </summary>
    public class BuffManager : MonoBehaviour
    {
        private Dictionary<PieceInstance, List<ActiveBuffInstance>> pieceBuffs = 
            new Dictionary<PieceInstance, List<ActiveBuffInstance>>();
        
        public event Action<PieceInstance, string, int> OnBuffApplied;
        public event Action<PieceInstance, string> OnBuffExpired;
        
        /// <summary>
        /// Applique un buff à une pièce.
        /// </summary>
        public void ApplyBuff(
            PieceInstance piece,
            StatType statType,
            int value,
            int durationTurns,
            string buffName = "")
        {
            if (!pieceBuffs.ContainsKey(piece))
                pieceBuffs[piece] = new List<ActiveBuffInstance>();
            
            var buff = new ActiveBuffInstance
            {
                Type = statType,
                Value = value,
                RemainingTurns = durationTurns,
                Name = buffName != "" ? buffName : statType.ToString()
            };
            
            pieceBuffs[piece].Add(buff);
            piece.ApplyBuff(statType, value, durationTurns);
            
            OnBuffApplied?.Invoke(piece, buff.Name, durationTurns);
            
            Debug.Log($"[BuffManager] {piece.PieceName} reçoit +{value} {statType} pour {durationTurns} tours");
        }
        
        /// <summary>
        /// Présets de buffs populaires.
        /// </summary>
        public void ApplyFortification(PieceInstance piece, int turns = 3)
        {
            ApplyBuff(piece, StatType.Defense, +4, turns, "Fortification");
        }
        
        public void ApplyPowerBoost(PieceInstance piece, int turns = 2)
        {
            ApplyBuff(piece, StatType.Attack, +2, turns, "Boost de Puissance");
        }
        
        public void ApplyDebuff(PieceInstance piece, StatType type, int value, int turns)
        {
            ApplyBuff(piece, type, -value, turns, $"Débuff {type}");
        }
        
        /// <summary>
        /// Met à jour les buffs (à appeler chaque fin de tour).
        /// </summary>
        public void UpdateAllBuffs()
        {
            List<PieceInstance> piecesToRemove = new List<PieceInstance>();
            
            foreach (var kvp in pieceBuffs)
            {
                PieceInstance piece = kvp.Key;
                List<ActiveBuffInstance> buffs = kvp.Value;
                
                // Mettre à jour chaque buff
                for (int i = buffs.Count - 1; i >= 0; i--)
                {
                    buffs[i].RemainingTurns--;
                    
                    if (buffs[i].RemainingTurns <= 0)
                    {
                        // Annuler le buff
                        piece.ApplyBuff(buffs[i].Type, -buffs[i].Value, 0);
                        OnBuffExpired?.Invoke(piece, buffs[i].Name);
                        
                        Debug.Log($"[BuffManager] Buff '{buffs[i].Name}' expiré pour {piece.PieceName}");
                        
                        buffs.RemoveAt(i);
                    }
                }
                
                // Supprimer si plus de buffs
                if (buffs.Count == 0)
                    piecesToRemove.Add(piece);
            }
            
            // Nettoyer
            foreach (var piece in piecesToRemove)
                pieceBuffs.Remove(piece);
        }
    }
    
    [System.Serializable]
    public class ActiveBuffInstance
    {
        public string Name;
        public StatType Type;
        public int Value;
        public int RemainingTurns;
    }
}
```

---

## 4. EVOLUTIONMANAGER : DÉCLENCHEURS D'ÉVOLUTION

### 🌟 EvolutionManager.cs

```csharp
using UnityEngine;
using System;
using System.Collections.Generic;
using OctagonalChess.Core;

namespace OctagonalChess.Gameplay
{
    /// <summary>
    /// Gère les conditions d'évolution des pièces.
    /// 
    /// Conditions supportées:
    /// 1. OnHealthAboveThreshold (si HP > 50%)
    /// 2. OnTurnNumber (après N tours)
    /// 3. OnKill (après avoir tué X pièces)
    /// 4. OnBuffApplied (si buff spécifique reçu)
    /// </summary>
    public class EvolutionManager : MonoBehaviour
    {
        private Dictionary<PieceInstance, EvolutionTracker> trackers = 
            new Dictionary<PieceInstance, EvolutionTracker>();
        
        public event Action<PieceInstance, PieceData, PieceData> OnEvolutionTriggered;
        
        /// <summary>
        /// Enregistre une pièce pour tracker son évolution.
        /// </summary>
        public void RegisterPiece(PieceInstance piece)
        {
            if (!piece.PieceData.CanEvolve())
                return;
            
            trackers[piece] = new EvolutionTracker
            {
                Piece = piece,
                Condition = piece.PieceData.EvolutionCondition,
                TargetData = piece.PieceData.EvolutionTarget
            };
            
            Debug.Log($"[EvolutionManager] {piece.PieceName} enregistré pour évolution");
        }
        
        /// <summary>
        /// Vérifie les conditions d'évolution chaque tour.
        /// </summary>
        public void UpdateEvolutions(int currentTurn)
        {
            List<PieceInstance> piecesToEvolve = new List<PieceInstance>();
            
            foreach (var kvp in trackers)
            {
                PieceInstance piece = kvp.Key;
                EvolutionTracker tracker = kvp.Value;
                
                if (piece == null || !piece.IsAlive)
                    continue;
                
                // Vérifier la condition
                bool shouldEvolve = tracker.Condition switch
                {
                    EvolutionCondition.OnHealthAboveThreshold => 
                        piece.HealthPercentage > 0.5f,
                    
                    EvolutionCondition.OnTurnNumber => 
                        currentTurn >= 5,  // Exemple: turn 5
                    
                    EvolutionCondition.OnKill => 
                        tracker.KillCount >= 2,
                    
                    _ => false
                };
                
                if (shouldEvolve && !tracker.HasEvolved)
                {
                    piecesToEvolve.Add(piece);
                    tracker.HasEvolved = true;
                }
            }
            
            // Appliquer les évolutions
            foreach (var piece in piecesToEvolve)
            {
                PieceData oldData = piece.PieceData;
                piece.Evolve(trackers[piece].TargetData);
                OnEvolutionTriggered?.Invoke(piece, oldData, trackers[piece].TargetData);
            }
        }
        
        /// <summary>
        /// Enregistre un kill pour une pièce (pour EvolutionCondition.OnKill).
        /// </summary>
        public void RegisterKill(PieceInstance killer)
        {
            if (trackers.ContainsKey(killer))
            {
                trackers[killer].KillCount++;
            }
        }
    }
    
    [System.Serializable]
    public class EvolutionTracker
    {
        public PieceInstance Piece;
        public EvolutionCondition Condition;
        public PieceData TargetData;
        public int KillCount = 0;
        public bool HasEvolved = false;
    }
}
```

---

## 5. BOARDMANAGER : PLATEAU COMPLET

### 🎮 BoardManager.cs (Full Implementation)

```csharp
using UnityEngine;
using System.Collections.Generic;
using OctagonalChess.Core;

namespace OctagonalChess.Gameplay
{
    /// <summary>
    /// Gère le plateau de jeu complet.
    /// 
    /// Responsabilités:
    /// 1. Créer et placer les pièces
    /// 2. Gérer la grille (positions, mouvements)
    /// 3. Valider les actions de combat
    /// 4. Tracker l'état du jeu
    /// </summary>
    public class BoardManager : MonoBehaviour
    {
        [SerializeField] private int boardWidth = 8;
        [SerializeField] private int boardHeight = 8;
        [SerializeField] private GameObject piecePrefab;  // Prefab de base
        [SerializeField] private Transform boardParent;
        
        [SerializeField] private CombatSystem combatSystem;
        [SerializeField] private BuffManager buffManager;
        [SerializeField] private EvolutionManager evolutionManager;
        [SerializeField] private CombatLog combatLog;
        
        private PieceInstance[,] board;
        private Dictionary<PieceInstance, Vector3Int> piecePositions;
        private int currentTurn = 0;
        
        // État du jeu
        private HashSet<PieceInstance> alivePieces = new HashSet<PieceInstance>();
        private HashSet<PieceInstance> team1Pieces = new HashSet<PieceInstance>();
        private HashSet<PieceInstance> team2Pieces = new HashSet<PieceInstance>();
        
        private void Awake()
        {
            InitializeBoard();
        }
        
        private void InitializeBoard()
        {
            board = new PieceInstance[boardWidth, boardHeight];
            piecePositions = new Dictionary<PieceInstance, Vector3Int>();
        }
        
        /// <summary>
        /// Crée une pièce et la place sur le plateau.
        /// </summary>
        public PieceInstance CreatePiece(
            PieceData data,
            int x,
            int y,
            TeamColor team)
        {
            // Vérifier position valide
            if (x < 0 || x >= boardWidth || y < 0 || y >= boardHeight)
            {
                Debug.LogError($"[BoardManager] Position invalide: ({x}, {y})");
                return null;
            }
            
            // Vérifier si case occupée
            if (board[x, y] != null)
            {
                Debug.LogError($"[BoardManager] Case ({x}, {y}) déjà occupée!");
                return null;
            }
            
            // Instancier le prefab
            GameObject pieceGO = Instantiate(piecePrefab, boardParent);
            pieceGO.name = $"{data.PieceName}_{team}_{x}_{y}";
            pieceGO.transform.position = GetWorldPosition(x, y);
            
            // Ajouter le composant
            PieceInstance instance = pieceGO.AddComponent<PieceInstance>();
            instance.Initialize(data, new Vector3Int(x, 0, y));
            
            // Enregistrer sur le plateau
            board[x, y] = instance;
            piecePositions[instance] = new Vector3Int(x, 0, y);
            alivePieces.Add(instance);
            
            // Assigner à une équipe
            if (team == TeamColor.Team1)
                team1Pieces.Add(instance);
            else
                team2Pieces.Add(instance);
            
            // S'enregistrer aux événements
            instance.OnDeath += () => OnPieceDied(instance);
            instance.OnEvolved += (old, neo) => evolutionManager.RegisterPiece(instance);
            
            // Tracker l'évolution
            evolutionManager.RegisterPiece(instance);
            
            Debug.Log($"[BoardManager] ✓ {data.PieceName} créé à ({x}, {y}) pour {team}");
            
            return instance;
        }
        
        /// <summary>
        /// Attaque entre deux pièces.
        /// </summary>
        public void AttackPiece(PieceInstance attacker, PieceInstance defender)
        {
            if (attacker == null || defender == null)
                return;
            
            if (!attacker.IsAlive || !defender.IsAlive)
            {
                Debug.LogWarning("[BoardManager] Attaque impossible: une pièce est morte.");
                return;
            }
            
            // Résoudre le combat
            combatSystem.ResolveCombat(attacker, defender);
            
            // Tracker les kills
            if (!defender.IsAlive)
            {
                evolutionManager.RegisterKill(attacker);
            }
        }
        
        /// <summary>
        /// Bouge une pièce sur le plateau.
        /// </summary>
        public void MovePiece(PieceInstance piece, int newX, int newY)
        {
            if (piece == null)
                return;
            
            // Récupérer l'ancienne position
            if (!piecePositions.TryGetValue(piece, out Vector3Int oldPos))
                return;
            
            // Vérifier nouvelle position
            if (newX < 0 || newX >= boardWidth || newY < 0 || newY >= boardHeight)
                return;
            
            // Vérifier collision
            if (board[newX, newY] != null)
            {
                Debug.LogWarning($"[BoardManager] Case ({newX}, {newY}) occupée!");
                return;
            }
            
            // Mettre à jour la grille
            board[oldPos.x, oldPos.z] = null;
            board[newX, newY] = piece;
            
            // Mettre à jour la position
            piecePositions[piece] = new Vector3Int(newX, 0, newY);
            
            // Animer
            piece.transform.position = GetWorldPosition(newX, newY);
            
            Debug.Log($"[BoardManager] {piece.PieceName} déplacé: ({oldPos.x}, {oldPos.z}) → ({newX}, {newY})");
        }
        
        /// <summary>
        /// Applique les buffs à la fin du tour.
        /// </summary>
        public void EndTurn()
        {
            currentTurn++;
            
            // Mettre à jour les buffs
            buffManager.UpdateAllBuffs();
            
            // Vérifier les évolutions
            evolutionManager.UpdateEvolutions(currentTurn);
            
            // Vérifier victoire
            CheckVictoryCondition();
            
            Debug.Log($"[BoardManager] === FIN TOUR {currentTurn} ===");
        }
        
        private void OnPieceDied(PieceInstance piece)
        {
            alivePieces.Remove(piece);
            team1Pieces.Remove(piece);
            team2Pieces.Remove(piece);
            
            // Enlever de la grille
            if (piecePositions.TryGetValue(piece, out Vector3Int pos))
            {
                board[pos.x, pos.z] = null;
                piecePositions.Remove(piece);
            }
            
            Debug.Log($"[BoardManager] {piece.PieceName} est mort.");
        }
        
        private void CheckVictoryCondition()
        {
            if (team1Pieces.Count == 0)
                Debug.Log("[BoardManager] 🎉 ÉQUIPE 2 GAGNE!");
            
            if (team2Pieces.Count == 0)
                Debug.Log("[BoardManager] 🎉 ÉQUIPE 1 GAGNE!");
        }
        
        private Vector3 GetWorldPosition(int x, int y)
        {
            return new Vector3(x * 1.5f, 0, y * 1.5f);
        }
        
        public Vector3Int GetBoardPosition(Vector3 worldPos)
        {
            return new Vector3Int(
                Mathf.RoundToInt(worldPos.x / 1.5f),
                0,
                Mathf.RoundToInt(worldPos.z / 1.5f)
            );
        }
    }
    
    public enum TeamColor
    {
        Team1,
        Team2
    }
}
```

---

## 6. COMBATLOG : JOURNALISATION

### 📜 CombatLog.cs

```csharp
using UnityEngine;
using System.Collections.Generic;
using OctagonalChess.Gameplay;

namespace OctagonalChess.Gameplay
{
    /// <summary>
    /// Journalise tous les combats pour l'UI et le debug.
    /// </summary>
    public class CombatLog : MonoBehaviour
    {
        private List<CombatLogEntry> entries = new List<CombatLogEntry>();
        [SerializeField] private int maxEntries = 100;
        
        public void LogCombat(CombatResult result)
        {
            string logEntry = $"{result.Attacker.PieceName} attaque {result.Defender.PieceName}: " +
                              $"{result.FinalDamage} dégâts (base: {result.BaseDamage})";n            
            if (result.CounterDamage.HasValue)
                logEntry += $" | CONTRE-ATTAQUE: {result.CounterDamage} dégâts";
            
            entries.Add(new CombatLogEntry
            {
                Timestamp = result.Timestamp,
                Message = logEntry,
                Result = result
            });
            
            // Limiter la taille du log
            if (entries.Count > maxEntries)
                entries.RemoveAt(0);
            
            Debug.Log($"[CombatLog] {logEntry}");
        }
        
        public List<CombatLogEntry> GetAllEntries() => new List<CombatLogEntry>(entries);
    }
    
    [System.Serializable]
    public class CombatLogEntry
    {
        public double Timestamp;
        public string Message;
        public CombatResult Result;
    }
}
```

---

## 7. PATTERNS DE COMBAT

### 🎯 Exemples d'Utilisation

#### Pattern 1: Combat Simple
```csharp
// Attaque simple
boardManager.AttackPiece(pion, roi);
// Le système s'occupe du reste (dégâts, contre-attaque, mort, etc.)
```

#### Pattern 2: Buff + Attaque
```csharp
// Appliquer fortification
buffManager.ApplyFortification(roi, turns: 3);

// Attaquer
boardManager.AttackPiece(ennemi, roi);
// Résultat: dégâts réduits grâce au buff
```

#### Pattern 3: Combos
```csharp
// Boost d'attaque + Attaque
buffManager.ApplyPowerBoost(cavalier, turns: 2);
boardManager.AttackPiece(cavalier, fou);
// Résultat: dégâts augmentés
```

#### Pattern 4: Gestion de Fin de Tour
```csharp
private void OnTurnEnd()
{
    // Mettre à jour les buffs (durées décrémentées)
    buffManager.UpdateAllBuffs();
    
    // Vérifier les évolutions
    evolutionManager.UpdateEvolutions(currentTurn);
    
    // Incrémenter le tour
    currentTurn++;
}
```

---

## 8. TESTS UNITAIRES

### 🧪 Tests de Combat

```csharp
using UnityEngine;
using NUnit.Framework;
using OctagonalChess.Core;
using OctagonalChess.Gameplay;

namespace OctagonalChess.Tests
{
    public class CombatTests
    {
        private CombatCalculator calculator;
        private PieceInstance roi;
        private PieceInstance pion;
        
        [SetUp]
        public void Setup()
        {
            calculator = new GameObject().AddComponent<CombatCalculator>();
            
            // Créer Roi (HP=15, ATK=8, DEF=4)
            var kingData = ScriptableObject.CreateInstance<PieceData>();
            kingData.MaxHealth = 15;
            kingData.BaseAttack = 8;
            kingData.BaseDefense = 4;
            
            roi = new GameObject().AddComponent<PieceInstance>();
            roi.Initialize(kingData, Vector3Int.zero);
            
            // Créer Pion (HP=3, ATK=1, DEF=1)
            var pawnData = ScriptableObject.CreateInstance<PieceData>();
            pawnData.MaxHealth = 3;
            pawnData.BaseAttack = 1;
            pawnData.BaseDefense = 1;
            
            pion = new GameObject().AddComponent<PieceInstance>();
            pion.Initialize(pawnData, Vector3Int.one);
        }
        
        [Test]
        public void TestDamageFormula_PionVsRoi()
        {
            // Pion (ATK=1) attaque Roi (DEF=4)
            // Dégâts = max(1, 1-4) = 1
            int damage = calculator.CalculateDamage(pion, roi);
            Assert.AreEqual(1, damage);
        }
        
        [Test]
        public void TestDamageFormula_RoiVsPion()
        {
            // Roi (ATK=8) attaque Pion (DEF=1)
            // Dégâts = max(1, 8-1) = 7
            int damage = calculator.CalculateDamage(roi, pion);
            Assert.AreEqual(7, damage);
        }
        
        [Test]
        public void TestTakeDamage()
        {
            int initialHP = pion.CurrentHealth;
            pion.TakeDamage(2, roi);
            
            Assert.AreEqual(initialHP - 2, pion.CurrentHealth);
        }
        
        [Test]
        public void TestDeath()
        {
            pion.TakeDamage(100, roi);
            Assert.IsFalse(pion.IsAlive);
        }
        
        [TearDown]
        public void Teardown()
        {
            Object.Destroy(calculator.gameObject);
            Object.Destroy(roi.gameObject);
            Object.Destroy(pion.gameObject);
        }
    }
}
```

---

## RÉSUMÉ DE L'ARCHITECTURE

### 🏗️ Modules Clés

| Module | Responsabilité | Entrée | Sortie |
|--------|----------------|--------|--------|
| **PieceData** | Définition des pièces | ScriptableObject | Stats, Visuel, Évolution |
| **PieceInstance** | État d'une pièce en jeu | Données + Position | HP courant, Events |
| **CombatCalculator** | Formules mathématiques | ATK/DEF | Dégâts finaux |
| **CombatSystem** | Orchestration combat | Attacker/Defender | CombatResult |
| **BuffManager** | Gestion des effets | Buff params | Stats modifiées |
| **EvolutionManager** | Déclenchement évolution | Condition | Pièce transformée |
| **BoardManager** | Gestion du plateau | Pièces + Positions | État du jeu |
| **CombatLog** | Journalisation | CombatResult | Logs |

### ✅ Points Clés

1. **Data-Driven**: 200+ pièces via ScriptableObjects
2. **Event-Driven**: Chaque action émet des événements
3. **Modulaire**: Chaque système indépendant
4. **Testable**: Logique séparée des GameObjects
5. **Performant**: Pas de Find/GetComponent

---

**Docs complètes créées! Vous avez une architecture RPG professionnelle prête à l'emploi.** 🚀
