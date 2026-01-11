# 🕳️ Architecture RPG Data-Driven pour Pièces d'Échecs Octogonales
## *Octagonal Chess Tactics - Système Complet avec Règles*

**Namespace :** `OctagonalChess.Core`

---

## TABLE DES MATIÈRES

1. [Vue d'Ensemble](#1-vue-densemble)
2. [PieceData : Configuration des Pièces](#2-piecedata--configuration-des-pièces)
3. [RoleTactique & Catégories](#3-roletactique--catégories)
4. [PieceInstance : L'Instance en Jeu](#4-pieceinstance--linstance-en-jeu)
5. [Logique de Combat : Formule RPG](#5-logique-de-combat--formule-rpg)
6. [Système d'Evolution](#6-système-dévolution)
7. [Gestion UI & Buffs](#7-gestion-ui--buffs)
8. [Exemples de Création d'Assets](#8-exemples-de-création-déassets)
9. [Intégration avec le Plateau](#9-intégration-avec-le-plateau)
10. [Optimisations & Performance](#10-optimisations--performance)

---

## 1. VUE D'ENSEMBLE

### 🎯 Diagramme de l'Architecture

```
┌─────────────────────────────────────────────────────────┐
│              LAYER 1 : DONNÉES (ScriptableObjects)        │
│                                                             │
│  ┌─────────────────────────────────────────┐  │
│  │          PieceData.cs                           │  │
│  │  - PieceID / Name / Description               │  │
│  │  - MaxHealth, BaseAttack, BaseDefense          │  │
│  │  - RoleTactique (Tank, DPS, Support)           │  │
│  │  - Prefab 3D + Material                         │  │
│  │  - PieceCatégorie (King, Queen, Knight, ...)    │  │
│  │  - EvolutionTarget (optional)                  │  │
│  └─────────────────────────────────────────┘  │
│                                                             │
└───────────────────────┬───────────────────────────────┐
                        │
                        ▼
┌───────────────────────┬───────────────────────────────┐
│             LAYER 2 : LOGIQUE (MonoBehaviour)            │
│                                                             │
│  ┌─────────────────────────────────────────┐  │
│  │      PieceInstance.cs                          │  │
│  │  - CurrentHP / CurrentAttack / CurrentDefense  │  │
│  │  - TakeDamage(int damage, PieceInstance from)  │  │
│  │  - ApplyBuff(StatType, value, duration)        │  │
│  │  - Evolve(PieceData newData)                   │  │
│  │  - Events: OnTakeDamage, OnHealthThreshold     │  │
│  └─────────────────────────────────────────┘  │
│                                                             │
└───────────────────────┬───────────────────────────────┐
                        │
                        ▼
┌───────────────────────┬───────────────────────────────┐
│         LAYER 3 : PRÉSENTATION (UI/Visuel)             │
│                                                             │
│  - HealthBar Canvas (au-dessus de la pièce)                │
│  - Prefab Modèle 3D                                        │
│  - Effects visuels (attaque, mort, évolution)              │
│  - Animations                                             │
└───────────────────────────────────────────────────┐
```

### 📁 Workflow de Données

```
1. Designer crée PieceData.asset (stats → ScriptableObject)
                    │
                    ▼
2. BoardGenerator instancie GameObject + PieceInstance
                    │
                    ▼
3. PieceInstance lit PieceData.asset
                    │
                    ▼
4. Initialize() copie stats de base à l'état courant
                    │
                    ▼
5. Combat : TakeDamage() applique formule DMG = ATK - DEF
                    │
                    ▼
6. Buffs : ApplyBuff() modifie CurrentStats temporairement
                    │
                    ▼
7. Évolution : Evolve() remplace les stats tout en preservant %HP
```

---

## 2. PIECEDATA : CONFIGURATION DES PIÈCES

### 📄 Code Complet : PieceData.cs

```csharp
using UnityEngine;
using System;
using OctagonalChess.Core;

namespace OctagonalChess.Core
{
    /// <summary>
    /// PieceData = Configuration d'une pièce d'échecs octogonale.
    /// 
    /// C'est un ScriptableObject qui définit TOUTES les propriétés
    /// d'une variante de pièce (stats, rôle, visuel, évolution).
    /// 
    /// Création: Right-click → Create → Octagonal Chess → Piece Data
    /// 
    /// Exemples:
    /// - King.asset : MaxHealth=15, Attack=8, Defense=4
    /// - Queen.asset : MaxHealth=12, Attack=9, Defense=3
    /// - Soldier_Basic.asset : MaxHealth=3, Attack=1, Defense=1
    /// - Soldier_Elite.asset : MaxHealth=5, Attack=2, Defense=2
    /// </summary>
    [CreateAssetMenu(fileName = "PieceData_", menuName = "Octagonal Chess/Piece Data", order = 1)]
    public class PieceData : ScriptableObject
    {
        // ========== IDENTITÉ & CATÉGORISATION ==========
        
        [Header("📋 Identité")]
        [SerializeField] private string pieceID;           // Unique identifier (ex: "king_red_1")
        [SerializeField] private string pieceName;         // Nom affiché (ex: "Roi")
        [TextArea(2, 4)]
        [SerializeField] private string description;       // Description pour UI/tooltip
        
        [Header("👊 Catégorie")]
        [Tooltip("Type de pièce (Roi, Reine, Cavalier, etc.)")]
        [SerializeField] private PieceCategorie pieceCategorie = PieceCategorie.Pion;
        
        [Tooltip("Rôle tactique (Tank, DPS, Support)")]
        [SerializeField] private RoleTactique roleTactique = RoleTactique.DPS;
        
        [Range(1, 5)]
        [SerializeField] private int tier = 1;  // 1=Basic, 5=Legendary
        
        // ========== STATISTIQUES ==========
        
        [Header("💪 Statistiques de Base")]
        [Tooltip("Points de vie max (par défaut: Roi=15, Reine=12, etc.)")]
        [Range(1, 50)]
        [SerializeField] private int maxHealth = 10;
        
        [Tooltip("Attaque de base (formule: dmg = attaque_ennemi - defense_cible)")]
        [Range(0, 20)]
        [SerializeField] private int baseAttack = 5;
        
        [Tooltip("Défense de base (réduit dégâts entrants)")]
        [Range(0, 20)]
        [SerializeField] private int baseDefense = 2;
        
        // ========== VISUEL ==========
        
        [Header("🎨 Présentation")]
        [Tooltip("Prefab 3D de la pièce")]
        [SerializeField] private GameObject visualPrefab;
        
        [Tooltip("Material personnalisé (optionnel)")]
        [SerializeField] private Material materialOverride;
        
        [Tooltip("Couleur si pas de material")]
        [SerializeField] private Color primaryColor = Color.white;
        
        [Tooltip("Échelle visuelle (1 = normal)")]
        [SerializeField] private float visualScale = 1.0f;
        
        // ========== ÉVOLUTION ==========
        
        [Header("🌟 Évolution")]
        [Tooltip("Pièce vers laquelle évolue cette pièce (ex: Soldier_Basic → Soldier_Elite)")]
        [SerializeField] private PieceData evolutionTarget;
        
        [Tooltip("Condition d'évolution (ex: si HP > 50% au tour 5)")]
        [SerializeField] private EvolutionCondition evolutionCondition = EvolutionCondition.None;
        
        // ========== PROPRIÉTÉS D'ACCÈS ==========
        
        public string PieceID => pieceID;
        public string PieceName => pieceName;
        public string Description => description;
        public PieceCategorie PieceCategorie => pieceCategorie;
        public RoleTactique RoleTactique => roleTactique;
        public int Tier => tier;
        public int MaxHealth => maxHealth;
        public int BaseAttack => baseAttack;
        public int BaseDefense => baseDefense;
        public GameObject VisualPrefab => visualPrefab;
        public Material MaterialOverride => materialOverride;
        public Color PrimaryColor => primaryColor;
        public float VisualScale => visualScale;
        public PieceData EvolutionTarget => evolutionTarget;
        public EvolutionCondition EvolutionCondition => evolutionCondition;
        
        // ========== VALIDATION ==========
        
        private void OnValidate()
        {
            // Vérifier l'ID unique
            if (string.IsNullOrEmpty(pieceID))
                pieceID = System.Guid.NewGuid().ToString();
            
            // Vérifier le nom
            if (string.IsNullOrEmpty(pieceName))
                pieceName = "Untitled Piece";
            
            // Vérifier les stats positives
            if (maxHealth <= 0)
            {
                Debug.LogWarning($"[{name}] MaxHealth doit être > 0.");
                maxHealth = 1;
            }
            
            if (baseAttack < 0)
            {
                Debug.LogWarning($"[{name}] Attack doit être ≥ 0.");
                baseAttack = 0;
            }
            
            if (baseDefense < 0)
            {
                Debug.LogWarning($"[{name}] Defense doit être ≥ 0.");
                baseDefense = 0;
            }
            
            // Ne pas laisser une pièce pointer sur elle-même pour évolution
            if (evolutionTarget == this)
            {
                Debug.LogWarning($"[{name}] Evolution target ne peut pas pointer sur soi-même!");
                evolutionTarget = null;
            }
            
            // Vérifier scale visuelle
            if (visualScale <= 0)
            {
                Debug.LogWarning($"[{name}] VisualScale doit être > 0.");
                visualScale = 1.0f;
            }
        }
        
        // ========== UTILITAIRES ==========
        
        /// <summary>
        /// Retourne le "power score" global de la pièce.
        /// Utile pour le balancing.
        /// </summary>
        public int GetPowerScore()
        {
            return maxHealth + (baseAttack * 2) + baseDefense;
        }
        
        /// <summary>
        /// Retourne true si cette pièce peut évoluer.
        /// </summary>
        public bool CanEvolve()
        {
            return evolutionTarget != null && evolutionCondition != EvolutionCondition.None;
        }
        
        /// <summary>
        /// Retourne les valeurs par défaut pour chaque catégorie.
        /// Utile pour "reset" les stats après un débuff.
        /// </summary>
        public static PieceData GetDefaultTemplate(PieceCategorie categorie)
        {
            // Ces valeurs correspondent au fichier PDF fourni
            return categorie switch
            {
                PieceCategorie.Roi => CreateTemplate("Roi", 15, 8, 4, PieceCategorie.Roi, RoleTactique.Tank),
                PieceCategorie.Reine => CreateTemplate("Reine", 12, 9, 3, PieceCategorie.Reine, RoleTactique.DPS),
                PieceCategorie.Cavalier => CreateTemplate("Cavalier", 8, 7, 2, PieceCategorie.Cavalier, RoleTactique.DPS),
                PieceCategorie.Tour => CreateTemplate("Tour", 9, 6, 3, PieceCategorie.Tour, RoleTactique.Tank),
                PieceCategorie.Fou => CreateTemplate("Fou", 7, 6, 2, PieceCategorie.Fou, RoleTactique.Support),
                PieceCategorie.Pion => CreateTemplate("Pion", 3, 1, 1, PieceCategorie.Pion, RoleTactique.DPS),
                _ => CreateTemplate("Unknown", 5, 3, 1, PieceCategorie.Pion, RoleTactique.DPS)
            };
        }
        
        private static PieceData CreateTemplate(string name, int hp, int atk, int def, PieceCategorie cat, RoleTactique role)
        {
            var data = ScriptableObject.CreateInstance<PieceData>();
            data.pieceName = name;
            data.maxHealth = hp;
            data.baseAttack = atk;
            data.baseDefense = def;
            data.pieceCategorie = cat;
            data.roleTactique = role;
            return data;
        }
    }
    
    // ========== ENUMS & TYPES ==========
    
    /// <summary>
    /// Catégories de pièces au chess octogonal.
    /// </summary>
    public enum PieceCategorie
    {
        Roi,      // King
        Reine,    // Queen
        Cavalier, // Knight
        Tour,     // Rook
        Fou,      // Bishop
        Pion      // Pawn
    }
    
    /// <summary>
    /// Rôle tactique de la pièce dans la bataille.
    /// </summary>
    public enum RoleTactique
    {
        Tank,     // Haute défense, HP élevés
        DPS,      // Haute attaque, faible défense
        Support,  // Buff/Debuff d'autres piéces
        Control,  // Contrôle du terrain
        Healer    // Soins (optionnel)
    }
    
    /// <summary>
    /// Conditions d'évolution d'une pièce.
    /// </summary>
    public enum EvolutionCondition
    {
        None,
        OnHealthAboveThreshold,  // Si HP > 50%
        OnTurnNumber,            // Après N tours
        OnKill,                  // Après avoir tué X piéces
        OnBuffApplied            // Si un buff spécifique est appliqué
    }
}
```

---

## 3. ROLETACTIQUE & CATÉGORIES

### 📖 Tableau de Référence

| Catégorie | HP | ATK | DEF | Rôle | Exemples |
|----------|-----|-----|-----|-------|----------|
| **Roi** | 15 | 8 | 4 | Tank | Roi Blanc, Roi Noir |
| **Reine** | 12 | 9 | 3 | DPS | Reine Blanche, Reine Noire |
| **Cavalier** | 8 | 7 | 2 | DPS | 15 variantes |
| **Tour** | 9 | 6 | 3 | Tank | 25 variantes |
| **Fou** | 7 | 6 | 2 | Support | 25 variantes |
| **Pion** | 3 | 1 | 1 | DPS | 95 variantes |

**Total : 200+ pièces** (15 Rois + 15 Reines + 25 Cavaliers + 25 Tours + 25 Fous + 95 Soldats)

---

## 4. PIECEINSTANCE : L'INSTANCE EN JEU

### 🎮 Code Complet : PieceInstance.cs

```csharp
using UnityEngine;
using System;
using System.Collections.Generic;
using OctagonalChess.Core;

namespace OctagonalChess.Core
{
    /// <summary>
    /// PieceInstance = Instance d'une pièce dans la scéne.
    /// 
    /// C'est le MonoBehaviour attaché au GameObject qui représente
    /// une pièce spécifique sur le plateau.
    /// 
    /// Responsabilités:
    /// 1. Stocke l'état LOCAL (HP courant, buffs, niveau d'usure)
    /// 2. Applique la LOGIQUE DE COMBAT (formule dégâts)
    /// 3. Gére les BUFFS/DEBUFFS temporaires
    /// 4. Permet l'ÉVOLUTION (transformation en pièce plus puissante)
    /// 5. ÉMET DES ÉVÉNEMENTS pour l'UI
    /// 
    /// Usage:
    /// var piece = Instantiate(piecePrefab);
    /// var instance = piece.AddComponent<PieceInstance>();
    /// instance.Initialize(kingData, boardPosition);
    /// </summary>
    [RequireComponent(typeof(Collider))]
    public class PieceInstance : MonoBehaviour
    {
        // ========== RÉFÉRENCES ==========
        
        [Header("📊 Configuration")]
        [Tooltip("PieceData template (ScriptableObject)")]
        [SerializeField] private PieceData pieceData;
        
        // ========== ÉTAT LOCAL ==========
        
        // Stats courantes (modifiables en jeu par buffs)
        private int currentHealth;
        private int currentAttack;
        private int currentDefense;
        
        // Position
        private Vector3Int gridPosition;
        
        // État
        private bool isAlive = true;
        private bool isSelected = false;
        
        // Buffs/Debuffs actifs
        private List<ActiveBuff> activeBuffs = new List<ActiveBuff>();
        
        // ========== COMPOSANTS UNITY (CACHE) ==========
        
        private Renderer visualRenderer;
        private Collider pieceCollider;
        private Transform visualTransform;
        
        // ========== ÉVÉNEMENTS ==========
        
        /// <summary>
        /// Événement : la pièce a pris des dégâts.
        /// Param: (damageAmount, attacker)
        /// </summary>
        public event Action<int, PieceInstance> OnTakeDamage;
        
        /// <summary>
        /// Événement : la pièce a été guérie.
        /// Param: (healAmount)
        /// </summary>
        public event Action<int> OnHealed;
        
        /// <summary>
        /// Événement : la pièce est morte.
        /// </summary>
        public event Action OnDeath;
        
        /// <summary>
        /// Événement : la pièce a atteint un seuil de santé.
        /// Param: (healthPercentage, thresholdType)
        /// Ex: trigger si HP < 30% ou HP < 50%
        /// </summary>
        public event Action<float, HealthThreshold> OnHealthThresholdCrossed;
        
        /// <summary>
        /// Événement : un buff a été appliqué.
        /// Param: (buffName, duration)
        /// </summary>
        public event Action<string, int> OnBuffApplied;
        
        /// <summary>
        /// Événement : la pièce a évolué.
        /// Param: (ancienData, nouveauData)
        /// </summary>
        public event Action<PieceData, PieceData> OnEvolved;
        
        // ========== PROPRIÉTÉS PUBLIQUES ==========
        
        public PieceData PieceData => pieceData;
        public string PieceName => pieceData != null ? pieceData.PieceName : "Unknown";
        public int CurrentHealth => currentHealth;
        public int MaxHealth => pieceData.MaxHealth;
        public int CurrentAttack => currentAttack;
        public int BaseAttack => pieceData.BaseAttack;
        public int CurrentDefense => currentDefense;
        public int BaseDefense => pieceData.BaseDefense;
        public bool IsAlive => isAlive;
        public bool IsSelected => isSelected;
        public float HealthPercentage => (float)currentHealth / MaxHealth;
        public PieceCategorie Category => pieceData.PieceCategorie;
        public RoleTactique Role => pieceData.RoleTactique;
        
        // ========== INITIALISATION ==========
        
        /// <summary>
        /// Initialise la pièce avec ses données.
        /// 
        /// OBLIGATOIRE d'appeler cette méthode après instantiation.
        /// </summary>
        public void Initialize(PieceData data, Vector3Int position)
        {
            if (data == null)
            {
                Debug.LogError("[PieceInstance] PieceData est null!");
                return;
            }
            
            pieceData = data;
            gridPosition = position;
            
            // Initialiser les stats
            currentHealth = data.MaxHealth;
            currentAttack = data.BaseAttack;
            currentDefense = data.BaseDefense;
            
            // Cacher les composants Unity
            CacheComponents();
            
            // Charger le visuel
            LoadVisual();
            
            // Nommer le GameObject
            gameObject.name = $"{PieceName}_{position}";
            
            Debug.Log($"[PieceInstance] ✓ {PieceName} initialisé à {position} avec {currentHealth} HP");
        }
        
        /// <summary>
        /// Cache les composants Unity pour performance.
        /// </summary>
        private void CacheComponents()
        {
            visualRenderer = GetComponent<Renderer>();
            pieceCollider = GetComponent<Collider>();
            visualTransform = transform;
        }
        
        /// <summary>
        /// Charge le prefab visuel de la pièce.
        /// </summary>
        private void LoadVisual()
        {
            if (pieceData.VisualPrefab == null)
            {
                Debug.LogWarning($"[{PieceName}] Pas de Visual Prefab assigné.");
                return;
            }
            
            GameObject visual = Instantiate(pieceData.VisualPrefab, transform);
            visual.transform.localPosition = Vector3.zero;
            visual.transform.localScale = Vector3.one * pieceData.VisualScale;
            
            // Override du material
            if (pieceData.MaterialOverride != null)
            {
                Renderer renderer = visual.GetComponent<Renderer>();
                if (renderer != null)
                    renderer.material = pieceData.MaterialOverride;
            }
        }
        
        // ========== LOGIQUE DE COMBAT ==========
        
        /// <summary>
        /// Applique la formule de dégâts RPG.
        /// 
        /// Formule: Dommages Finaux = max(1, Attaque - Défense)
        /// 
        /// Exemple:
        /// - Attaquant: Attack=10
        /// - Défenseur: Defense=4
        /// - Dégâts = max(1, 10 - 4) = 6
        /// 
        /// Param:
        /// - incomingDamage: dégâts bruts de l'attaquant
        /// - attacker: la pièce qui attaque
        /// </summary>
        public void TakeDamage(int incomingDamage, PieceInstance attacker = null)
        {
            if (!isAlive)
            {
                Debug.LogWarning($"[{PieceName}] Déjà mort.");
                return;
            }
            
            // Appliquer la réduction de défense
            int reducedDamage = Mathf.Max(1, incomingDamage - currentDefense);
            
            // Appliquer les buffs de réduction de dégâts
            float damageMultiplier = 1.0f;
            foreach (var buff in activeBuffs)
            {
                if (buff.Type == StatType.Defense)
                {
                    // 1 point de défense supplémentaire = 5% réduction de dégâts
                    damageMultiplier *= (1.0f - (buff.Value * 0.05f));
                }
            }
            
            int finalDamage = Mathf.RoundToInt(reducedDamage * damageMultiplier);
            finalDamage = Mathf.Max(1, finalDamage);
            
            // Appliquer les dégâts
            currentHealth -= finalDamage;
            currentHealth = Mathf.Max(0, currentHealth);
            
            // Émettre l'événement
            OnTakeDamage?.Invoke(finalDamage, attacker);
            
            Debug.Log($"[{PieceName}] 💔 Prend {finalDamage} dégâts (HP: {currentHealth}/{MaxHealth})");
            
            // Vérifier les seuils de santé
            CheckHealthThresholds();
            
            // Vérifier mort
            if (currentHealth <= 0)
            {
                Die();
            }
        }
        
        /// <summary>
        /// Guérit la pièce (limité au MaxHealth).
        /// </summary>
        public void Heal(int healAmount)
        {
            if (!isAlive)
                return;
            
            int actualHeal = Mathf.Min(healAmount, MaxHealth - currentHealth);
            currentHealth += actualHeal;
            
            OnHealed?.Invoke(actualHeal);
            
            Debug.Log($"[{PieceName}] ❤️ Guérit de {actualHeal} HP (HP: {currentHealth}/{MaxHealth})");
            
            CheckHealthThresholds();
        }
        
        /// <summary>
        /// Vérifie si la pièce a crossé un seuil de santé (30%, 50%).
        /// </summary>
        private void CheckHealthThresholds()
        {
            float healthPercent = HealthPercentage;
            
            if (healthPercent < 0.3f)
            {
                OnHealthThresholdCrossed?.Invoke(healthPercent, HealthThreshold.CriticalLow);
                Debug.Log($"[{PieceName}] 🚨 Santé CRITIQUE (< 30%)");
            }
            else if (healthPercent < 0.5f)
            {
                OnHealthThresholdCrossed?.Invoke(healthPercent, HealthThreshold.Low);
                Debug.Log($"[{PieceName}] ⚠️ Santé FAIBLE (< 50%)");
            }
        }
        
        /// <summary>
        /// Tue la pièce.
        /// </summary>
        private void Die()
        {
            if (!isAlive)
                return;
            
            isAlive = false;
            
            OnDeath?.Invoke();
            
            Debug.Log($"[{PieceName}] ☠️ Est mort.");
            
            // Désactiver interactions
            if (pieceCollider != null)
                pieceCollider.enabled = false;
            
            // Garder le GameObject pour l'animation, le détruire après 2s
            Destroy(gameObject, 2f);
        }
        
        // ========== SYSTÈME DE BUFFS ==========
        
        /// <summary>
        /// Applique un buff temporaire.
        /// 
        /// Exemple:
        /// ApplyBuff(StatType.Defense, +4, duration: 3 tours) // Fortification
        /// ApplyBuff(StatType.Attack, +2, duration: 2 tours)  // Boost d'attaque
        /// 
        /// Param:
        /// - statType: quel stat buffer (Attack, Defense)
        /// - value: valeur du buff
        /// - durationTurns: durée en tours
        /// </summary>
        public void ApplyBuff(StatType statType, int value, int durationTurns)
        {
            if (!isAlive)
            {
                Debug.LogWarning($"[{PieceName}] Mort, buff ignoré.");
                return;
            }
            
            // Créer l'instance du buff
            ActiveBuff buff = new ActiveBuff
            {
                Type = statType,
                Value = value,
                RemainingTurns = durationTurns
            };
            
            activeBuffs.Add(buff);
            
            // Appliquer la modification
            switch (statType)
            {
                case StatType.Attack:
                    currentAttack += value;
                    break;
                case StatType.Defense:
                    currentDefense += value;
                    break;
            }
            
            OnBuffApplied?.Invoke(statType.ToString(), durationTurns);
            
            Debug.Log($"[{PieceName}] 🌟 Buff appliqué: +{value} {statType} pour {durationTurns} tours");
        }
        
        /// <summary>
        /// Retire un buff.
        /// </summary>
        public void RemoveBuff(int buffIndex)
        {
            if (buffIndex < 0 || buffIndex >= activeBuffs.Count)
                return;
            
            ActiveBuff buff = activeBuffs[buffIndex];
            
            // Retirer la modification
            switch (buff.Type)
            {
                case StatType.Attack:
                    currentAttack -= buff.Value;
                    break;
                case StatType.Defense:
                    currentDefense -= buff.Value;
                    break;
            }
            
            activeBuffs.RemoveAt(buffIndex);
            
            Debug.Log($"[{PieceName}] Buff expiré: {buff.Type}");
        }
        
        /// <summary>
        /// Met à jour les buffs chaque tour.
        /// Décrémente les durées et retire les buffs expirés.
        /// </summary>
        public void UpdateBuffs()
        {
            for (int i = activeBuffs.Count - 1; i >= 0; i--)
            {
                activeBuffs[i].RemainingTurns--;
                
                if (activeBuffs[i].RemainingTurns <= 0)
                {
                    RemoveBuff(i);
                }
            }
        }
        
        // ========== ÉVOLUTION ==========
        
        /// <summary>
        /// Évolue la pièce vers une version plus puissante.
        /// 
        /// Exemples:
        /// - Soldier_Basic (3 HP) → Soldier_Elite (5 HP)
        /// - Pion (3 HP) → Reine (12 HP)
        /// 
        /// Important: le %HP est préservé!
        /// Ex: Si Soldier_Basic a 2/3 HP (66%), après évolution
        ///     il aura 66% de 5 HP = 3.3 ≈ 3 HP
        /// </summary>
        public void Evolve(PieceData newData)
        {
            if (!isAlive || newData == null)
            {
                Debug.LogWarning($"[{PieceName}] Évolution impossible.");
                return;
            }
            
            // Préserver le %HP
            float healthPercentBeforeEvolution = HealthPercentage;
            
            // Sauvegarder l'ancienne donnée
            PieceData oldData = pieceData;
            
            // Appliquer la nouvelle donnée
            pieceData = newData;
            currentAttack = newData.BaseAttack;
            currentDefense = newData.BaseDefense;
            currentHealth = Mathf.RoundToInt(newData.MaxHealth * healthPercentBeforeEvolution);
            
            // Recharger le visuel
            LoadVisual();
            
            // Émettre l'événement
            OnEvolved?.Invoke(oldData, newData);
            
            Debug.Log($"[{PieceName}] 🌟 ÉVOLUTION: {oldData.PieceName} → {newData.PieceName}!");
        }
        
        // ========== UTILITAIRES ==========
        
        /// <summary>
        /// Change l'état de sélection (pour l'UI).
        /// </summary>
        public void SetSelected(bool selected)
        {
            isSelected = selected;
            
            if (visualRenderer != null)
            {
                Color color = isSelected ? Color.yellow : Color.white;
                visualRenderer.material.color = color;
            }
        }
        
        /// <summary>
        /// Debug: affiche les infos de la pièce.
        /// </summary>
        public void PrintDebugInfo()
        {
            Debug.Log($"===== {PieceName} =====");
            Debug.Log($"HP: {currentHealth}/{MaxHealth} ({HealthPercentage * 100:F1}%)");
            Debug.Log($"ATK: {currentAttack} (base: {BaseAttack})");
            Debug.Log($"DEF: {currentDefense} (base: {BaseDefense})");
            Debug.Log($"Catégorie: {Category}");
            Debug.Log($"Rôle: {Role}");
            Debug.Log($"Buffs actifs: {activeBuffs.Count}");
        }
    }
    
    // ========== CLASSES & ENUMS SUPPORT ==========
    
    /// <summary>
    /// Buff temporaire appliqué à une pièce.
    /// </summary>
    [System.Serializable]
    public class ActiveBuff
    {
        public StatType Type;              // Attack ou Defense
        public int Value;                  // Valeur du bonus
        public int RemainingTurns;         // Tours restants
    }
    
    /// <summary>
    /// Type de stat modifiable.
    /// </summary>
    public enum StatType
    {
        Attack,
        Defense
    }
    
    /// <summary>
    /// Seuils de santé pour des réactions (animation, son, etc.)
    /// </summary>
    public enum HealthThreshold
    {
        CriticalLow,  // < 30%
        Low           // < 50%
    }
}
```

---

## 5. LOGIQUE DE COMBAT : FORMULE RPG

### 💪 Formule Exacte

```
┌────────────────────────────────────────────────────┐
│  DÉGÂTS FINAUX = max(1, Attaque_Attaquant - Défense_Défenseur)  │
└────────────────────────────────────────────────────┘
```

### 📝 Implemémentation dans TakeDamage()

```csharp
// *** Dans PieceInstance.TakeDamage() ***

public void TakeDamage(int incomingDamage, PieceInstance attacker = null)
{
    // incomingDamage = Attaque de l'attaquant
    // currentDefense = Défense de cette pièce
    
    int reducedDamage = Mathf.Max(1, incomingDamage - currentDefense);
    // max(1, ...) → Dégâts minimum = 1
    
    currentHealth -= reducedDamage;
}
```

### 📊 Exemples de Calculs

#### Exemple 1 : Roi vs Pion
```
Attaquant (Pion): Attack = 1
Défenseur (Roi): Defense = 4

Dégâts = max(1, 1 - 4) = max(1, -3) = 1
Roi prend 1 dégât sur ses 15 HP
```

#### Exemple 2 : Reine vs Pion
```
Attaquant (Reine): Attack = 9
Défenseur (Pion): Defense = 1

Dégâts = max(1, 9 - 1) = 8
Pion prend 8 dégâts (mais n'a que 3 HP) → mort
```

#### Exemple 3 : Avec Buff
```
Attaquant (Cavalier): Attack = 7 + Buff(+2) = 9
Défenseur (Fou): Defense = 2 + Buff(+4) = 6

Dégâts = max(1, 9 - 6) = 3
```

---

## 6. SYSTÈME D'ÉVOLUTION

### 🌟 Méthode Evolve() Complète

```csharp
/// <summary>
/// Évolue la pièce vers une version plus puissante en gardant le % de HP.
/// 
/// Flux:
/// 1. Calculer le %HP avant évolution
/// 2. Charger les nouvelles stats
/// 3. Recharger le visuel (modèle 3D)
/// 4. Calculer les nouveaux HP = %HP * nouveauMaxHP
/// 5. Émettre un événement pour l'UI/animations
/// 
/// Exemple AVANT ÉVOLUTION:
/// - Soldier_Basic: 2/3 HP (66%)
/// - Stats: Attack=1, Defense=1
/// 
/// Après APPEL: Evolve(Soldier_Elite_Data)
/// 
/// APRES ÉVOLUTION:
/// - Soldier_Elite: 3/5 HP (66% préservé)
/// - Stats: Attack=2, Defense=2
/// - Visuel: prefab changé en "Elite"
/// </summary>
public void Evolve(PieceData newData)
{
    if (!isAlive || newData == null)
    {
        Debug.LogWarning($"[{PieceName}] Évolution impossible.");
        return;
    }
    
    // Étape 1: Préserver le %HP
    float healthPercentBeforeEvolution = (float)currentHealth / MaxHealth;
    
    // Étape 2: Sauvegarder l'ancienne donnée
    PieceData oldData = pieceData;
    
    // Étape 3: Appliquer la nouvelle donnée
    pieceData = newData;
    currentAttack = newData.BaseAttack;
    currentDefense = newData.BaseDefense;
    
    // Étape 4: Calculer les nouveaux HP
    currentHealth = Mathf.RoundToInt(newData.MaxHealth * healthPercentBeforeEvolution);
    
    // Étape 5: Recharger le visuel
    LoadVisual();
    
    // Étape 6: Émettre l'événement
    OnEvolved?.Invoke(oldData, newData);
    
    Debug.Log($"[{PieceName}] 🌟 ÉVOLUTION: {oldData.PieceName} → {newData.PieceName}!");
}
```

### 📐 Tableau d'Évolution Possible

| De | Vers | Perte de % | Gain HP |
|---|---|---|---|
| Pion (3 HP) | Soldat Elite (5 HP) | Aucune | +2 |
| Soldat Elite (5 HP) | Cavalier (8 HP) | Aucune | +3 |
| Cavalier (8 HP) | Reine (12 HP) | Aucune | +4 |
| Pion (3 HP) | Reine (12 HP) | Aucune | +9 |

**Exemple avec %HP:**
```
Pion à 2/3 HP (66%) → Évolution → Soldat Elite
Nouveau HP = 66% de 5 = 3.3 ≈ 3/5 HP (60%)
```

---

## 7. GESTION UI & BUFFS

### 📁 Mise à jour de la HealthBar

```csharp
using UnityEngine;
using UnityEngine.UI;
using OctagonalChess.Core;

namespace OctagonalChess.UI
{
    /// <summary>
    /// Gére l'affichage de la barre de vie au-dessus d'une pièce.
    /// </summary>
    public class HealthBarUI : MonoBehaviour
    {
        [SerializeField] private PieceInstance piece;
        [SerializeField] private Image healthBarImage;       // Image verte/rouge
        [SerializeField] private Text healthText;            // "5/10"
        [SerializeField] private Canvas canvas;              // Canvas flottant
        
        private void Start()
        {
            if (piece == null)
                piece = GetComponentInParent<PieceInstance>();
            
            // S'enregistrer aux événements
            piece.OnTakeDamage += UpdateHealthBar;
            piece.OnHealed += UpdateHealthBar;
            piece.OnDeath += HideHealthBar;
            piece.OnHealthThresholdCrossed += OnHealthThresholdChanged;
        }
        
        /// <summary>
        /// Met à jour la barre de vie et le texte.
        /// </summary>
        private void UpdateHealthBar(int dummy = 0)
        {
            if (healthBarImage != null)
            {
                // Remplir la barre proportionnellement
                healthBarImage.fillAmount = piece.HealthPercentage;
                
                // Changer la couleur selon le %HP
                if (piece.HealthPercentage > 0.5f)
                    healthBarImage.color = Color.green;
                else if (piece.HealthPercentage > 0.3f)
                    healthBarImage.color = Color.yellow;
                else
                    healthBarImage.color = Color.red;
            }
            
            if (healthText != null)
                healthText.text = $"{piece.CurrentHealth}/{piece.MaxHealth}";
        }
        
        /// <summary>
        /// Réagit aux seuils de santé (animations, sons).
        /// </summary>
        private void OnHealthThresholdChanged(float healthPercent, HealthThreshold threshold)
        {
            if (threshold == HealthThreshold.CriticalLow)
            {
                // Animation de "shake"
                StartCoroutine(ShakeHealthBar());
            }
        }
        
        private void HideHealthBar()
        {
            canvas.enabled = false;
        }
        
        private System.Collections.IEnumerator ShakeHealthBar()
        {
            Vector3 originalPos = canvas.transform.localPosition;
            
            for (int i = 0; i < 10; i++)
            {
                canvas.transform.localPosition = originalPos + Random.insideUnitSphere * 0.1f;
                yield return new WaitForSeconds(0.05f);
            }
            
            canvas.transform.localPosition = originalPos;
        }
    }
}
```

---

## 8. EXEMPLES DE CRÉATION D'ASSETS

### 📄 Création d'un Roi

```
Right-click dans Assets/ScriptableObjects/Pieces/
↳ Create → Octagonal Chess → Piece Data
↳ Nommer: King.asset

Inspecteur:
│ Piece ID: "king_001"
│ Piece Name: "Roi"
│ Piece Categorie: Roi
│ Role Tactique: Tank
│ Tier: 1
│
│ Max Health: 15 ✅
│ Base Attack: 8
│ Base Defense: 4
│
│ Visual Prefab: [King_Model.prefab]
│ Primary Color: White
│
│ Evolution Target: (none)
│ Evolution Condition: None
```

### 📄 Création d'un Soldat Élite (avec Évolution)

```
Asset 1: Soldier_Basic.asset
│ Max Health: 3
│ Attack: 1
│ Defense: 1
│ Evolution Target: Soldier_Elite.asset
│ Evolution Condition: OnHealthAboveThreshold

Asset 2: Soldier_Elite.asset
│ Max Health: 5
│ Attack: 2
│ Defense: 2
│ Evolution Target: (none)
```

---

## 9. INTÉGRATION AVEC LE PLATEAU

### 👛 BoardManager avec Création de Pièces

```csharp
using UnityEngine;
using OctagonalChess.Core;

namespace OctagonalChess.Gameplay
{
    public class BoardManager : MonoBehaviour
    {
        [SerializeField] private PieceData[] pieceDataArray;  // 200+ assets
        [SerializeField] private GameObject piecePrefab;      // Prefab base
        [SerializeField] private Transform boardParent;
        
        private PieceInstance[,] board = new PieceInstance[8, 8];
        
        /// <summary>
        /// Crée une pièce sur le plateau.
        /// </summary>
        public PieceInstance CreatePiece(PieceData data, int x, int y)
        {
            // Instantier le prefab
            GameObject pieceGO = Instantiate(piecePrefab, boardParent);
            pieceGO.transform.position = new Vector3(x, 0, y);
            
            // Ajouter le composant
            PieceInstance instance = pieceGO.AddComponent<PieceInstance>();
            instance.Initialize(data, new Vector3Int(x, 0, y));
            
            // Enregistrer sur le plateau
            board[x, y] = instance;
            
            // S'enregistrer aux événements
            instance.OnTakeDamage += OnPieceDamaged;
            instance.OnDeath += OnPieceDied;
            
            return instance;
        }
        
        /// <summary>
        /// Attaque entre deux pièces.
        /// </summary>
        public void Attack(PieceInstance attacker, PieceInstance defender)
        {
            if (attacker == null || defender == null || !defender.IsAlive)
                return;
            
            // Appliquer la formule de dégâts
            int damage = attacker.CurrentAttack;
            defender.TakeDamage(damage, attacker);
            
            Debug.Log($"[Combat] {attacker.PieceName} attaque {defender.PieceName} pour {damage} dégâts");
        }
        
        private void OnPieceDamaged(int damage, PieceInstance attacker)
        {
            Debug.Log($"[BoardManager] Pièce endommagée: {damage} HP perdus");
        }
        
        private void OnPieceDied()
        {
            Debug.Log($"[BoardManager] Une pièce est morte");
        }
    }
}
```

---

## 10. OPTIMISATIONS & PERFORMANCE

### ⚡ Bonnes Pratiques

1. **Cache les Composants** (fait dans Initialize)
2. **Utilisez des Structs** pour les stats légères
3. **Pool les Objets** (recyclez les GameObject des pièces tuées)
4. **Batch les Updates** (UpdateBuffs chaque tour, pas chaque frame)
5. **Utilisez Events** au lieu de Find/GetComponent

### 📊 Checklist de Performance

- [ ] 0 GetComponent dans Update()
- [ ] 0 Find() ou FindWithTag()
- [ ] Buffs mis à jour uniquement fin de tour
- [ ] GameObject réutilisés via pooling
- [ ] Renderer caché au Start()
- [ ] Stats recalculés une seule fois lors de buff applique

---

## CONCLUSION

Cette architecture permet de:

✅ **Gérer 200+ variantes** sans ajouter de code
✅ **Appliquer une formule RPG claire** (DMG = ATK - DEF)
✅ **Gérer les buffs/debuffs** facilement
✅ **Permettre l'évolution** tout en préservant les HP%
✅ **Event-driven** pour une UI réactive
✅ **Performance optimisée** pour 1000+ piéces

**Créez vos 200+ pièces en remplissant simplement des ScriptableObjects!** 🚀
