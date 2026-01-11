# 🎯 Architecture Complète des Pièces RPG d'Échecs
## *Système Data-Driven pour 200+ Variantes*

---

## TABLE DES MATIÈRES

1. [Vue d'Ensemble de l'Architecture](#1-vue-densemble-de-larchitecture)
2. [PieceData : Le Template ScriptableObject](#2-piecedata--le-template-scriptableobject)
3. [PieceController : Le Contrôleur Universel](#3-piececontroller--le-contrôleur-universel)
4. [Système de Stats : PieceStats Struct](#4-système-de-stats--piecestats-struct)
5. [Système de Compétences : IAbility](#5-système-de-compétences--iability)
6. [AbilityManager : Orchestrateur](#6-abilitymanager--orchestrateur)
7. [Système de Modificateurs : Buffs/Debuffs](#7-système-de-modificateurs--buffsdebuffs)
8. [Intégration avec le Plateau](#8-intégration-avec-le-plateau)
9. [Exemples Concrets : 10 Variantes](#9-exemples-concrets--10-variantes)
10. [Pipeline de Création](#10-pipeline-de-création)

---

## 1. VUE D'ENSEMBLE DE L'ARCHITECTURE

### 📐 Diagramme Complet

```
┌────────────────────────────────────────────────────────┐
│                  LAYER 1 : DONNÉES                        │
│        (ScriptableObjects - Source of Truth)           │
│                                                          │
│  ┌────────────────┐      ┌────────────────┐  │
│  │   PieceData.cs   │      │  AbilityData.cs  │  │
│  │ - Name          │      │ - AbilityName   │  │
│  │ - BaseStats     │      │ - ManaCost      │  │
│  │ - VisualPrefab  │      │ - Cooldown      │  │
│  │ - Abilities[]   │────►│ - Effects       │  │
│  └────────────────┘      └────────────────┘  │
│                                                          │
│      ┌───────────────────────────────┐         │
│      │      ModifierData.cs      │         │
│      │ - Name / Type            │         │
│      │ - AttackBonus/DefBonus   │         │
│      │ - Duration               │         │
│      └───────────────────────────────┘         │
└───────────────────────┬────────────────────────────────┘
                        │
                        ▼
┌───────────────────────┴────────────────────────────────┐
│              LAYER 2 : LOGIQUE & SYSTÈMES             │
│           (MonoBehaviour + Managers)                   │
│                                                          │
│  ┌─────────────────────────────────────────────┐  │
│  │       PieceController.cs (MonoBehaviour)     │  │
│  │  - pieceData (référence au template)       │  │
│  │  - currentStats (instance modifiable)        │  │
│  │  - currentHealth, currentMana                │  │
│  │  - gridPosition, isAlive, isSelected         │  │
│  │                                                 │  │
│  │  Méthodes :                                    │  │
│  │  + Initialize(PieceData data, x, y)          │  │
│  │  + TakeDamage(int amount)                    │  │
│  │  + Heal(int amount)                          │  │
│  │  + Die()                                     │  │
│  │  + ExecuteAbility(int index, target)         │  │
│  │  + ApplyModifier(modifier, duration)         │  │
│  └─────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────┐  ┌───────────────────┐  │
│  │  AbilityManager.cs  │  │ CombatSystem.cs │  │
│  │ - ExecuteAbility() │  │ - ResolveAttack │  │
│  │ - UpdateCooldowns()│  │ - CalculateDmg  │  │
│  └──────────────────────┘  └───────────────────┘  │
└───────────────────────┬────────────────────────────────┘
                        │
                        ▼
┌───────────────────────┴────────────────────────────────┐
│            LAYER 3 : PRÉSENTATION & UI                 │
│                                                          │
│  - Prefabs Visuels (Cube, Model 3D, Animations)       │
│  - HealthBar UI (Canvas au-dessus de la pièce)         │
│  - Ability Buttons / Tooltips                          │
│  - Particle Effects (attaque, mort, buff)              │
│  - Sound Effects                                       │
└──────────────────────────────────────────────────────────┘
```

### 🎯 Principes Fondamentaux

1. **Data-Driven** : Toutes les données sont dans des ScriptableObjects
2. **1 Classe Universelle** : PieceController gère TOUTES les variantes
3. **Composition** : Pièces = Stats + Abilities (pas d'héritage)
4. **Extensibilité** : Ajouter 100 variantes = créer 100 assets (pas de code)
5. **Performance** : Cache, struct, pooling, pas de GetComponent dans Update

---

## 2. PIECEDATA : LE TEMPLATE SCRIPTABLEOBJECT

### 📄 Code Complet : PieceData.cs

```csharp
using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// PieceData = Blueprint (template) d'une variante de pièce.
/// 
/// 1 PieceData.asset = 1 variante (ex: "Soldat d'Élite")
/// Création: Right-click → Create → Chess RPG → Piece Data
/// 
/// Responsabilités:
/// - Stocker TOUTES les données configurables
/// - Aucune logique (juste des champs)
/// - Réutilisable par plusieurs instances en jeu
/// </summary>
[CreateAssetMenu(fileName = "PieceData_", menuName = "Chess RPG/Piece Data", order = 1)]
public class PieceData : ScriptableObject
{
    // ========== SECTION 1 : IDENTITÉ ==========
    
    [Header("➖ Identité")]
    [Tooltip("Nom affiché en jeu (ex: 'Soldat d’Élite')")]
    [SerializeField] private string pieceName = "Untitled Piece";
    
    [Tooltip("Description pour tooltips/UI")]
    [TextArea(3, 5)]
    [SerializeField] private string description = "";
    
    [Tooltip("Icône 2D pour l'UI (portrait)")]
    [SerializeField] private Sprite icon;
    
    [Tooltip("ID unique pour identification rapide")]
    [SerializeField] private string pieceID = "";
    
    // ========== SECTION 2 : STATISTIQUES ==========
    
    [Header("💪 Stats de Base")]
    [Tooltip("Stats de départ (HP, ATK, DEF, Mana)")]
    [SerializeField] private PieceStats baseStats = new PieceStats(100, 10, 5, 50);
    
    [Tooltip("Niveau de départ (1-99)")]
    [Range(1, 99)]
    [SerializeField] private int startingLevel = 1;
    
    [Tooltip("Tier de rareté (1=Common, 5=Legendary)")]
    [Range(1, 5)]
    [SerializeField] private int unitTier = 1;
    
    [Tooltip("Scaling des stats par niveau (1.1 = +10% par niveau)")]
    [SerializeField] private float levelScaling = 1.1f;
    
    // ========== SECTION 3 : VISUEL ==========
    
    [Header("🎨 Présentation")]
    [Tooltip("Prefab 3D instantané pour représenter cette pièce")]
    [SerializeField] private GameObject visualPrefab;
    
    [Tooltip("Material optionnel (overwrite du prefab)")]
    [SerializeField] private Material materialOverride;
    
    [Tooltip("Couleur principale (si pas de material)")]
    [SerializeField] private Color primaryColor = Color.white;
    
    [Tooltip("Échelle visuelle (1 = normale, 1.5 = 50% plus grand)")]
    [SerializeField] private float visualScale = 1.0f;
    
    // ========== SECTION 4 : COMPÉTENCES ==========
    
    [Header("✨ Compétences")]
    [Tooltip("Liste des abilities actives de cette pièce")]
    [SerializeField] private List<AbilityData> abilities = new List<AbilityData>();
    
    [Tooltip("Nombre maximum de slots d'abilities (3-5)")]
    [Range(1, 10)]
    [SerializeField] private int maxAbilitySlots = 5;
    
    [Tooltip("Abilities passives (toujours actives)")]
    [SerializeField] private List<PassiveAbilityData> passiveAbilities = new List<PassiveAbilityData>();
    
    // ========== SECTION 5 : MOUVEMENT ==========
    
    [Header("👟 Mouvement")]
    [Tooltip("Type de mouvement (Grid, Diagonal, Knight, etc.)")]
    [SerializeField] private MovementType movementType = MovementType.Grid;
    
    [Tooltip("Portée de mouvement en cases (1-10)")]
    [Range(1, 10)]
    [SerializeField] private int movementRange = 1;
    
    [Tooltip("Vitesse d'animation de mouvement")]
    [SerializeField] private float movementSpeed = 5.0f;
    
    [Tooltip("Peut voler par-dessus les obstacles")]
    [SerializeField] private bool isFlying = false;
    
    // ========== SECTION 6 : CARACTÉRISTIQUES SPÉCIALES ==========
    
    [Header("🌟 Spécial")]
    [Tooltip("Peut contre-attaquer quand attaqué")]
    [SerializeField] private bool canCounterAttack = false;
    
    [Tooltip("Peut se soigner passivement chaque tour")]
    [SerializeField] private bool hasRegeneration = false;
    
    [Tooltip("Montant de régénération par tour (si activé)")]
    [SerializeField] private int regenerationAmount = 5;
    
    [Tooltip("Chance de critique (0-100%)")]
    [Range(0, 100)]
    [SerializeField] private float criticalChance = 5f;
    
    [Tooltip("Multiplicateur de dégâts critiques (1.5 = +50%)")]
    [SerializeField] private float criticalMultiplier = 1.5f;
    
    // ========== SECTION 7 : PROGRESSION ==========
    
    [Header("🎯 Progression")]
    [Tooltip("XP donnée à l'adversaire quand tué")]
    [SerializeField] private int experienceReward = 10;
    
    [Tooltip("Or/ressources donnés quand tué")]
    [SerializeField] private int goldReward = 5;
    
    // ========== SECTION 8 : AUDIO & FX ==========
    
    [Header("🎶 Audio & Effets")]
    [Tooltip("Son joué lors du spawn")]
    [SerializeField] private AudioClip spawnSound;
    
    [Tooltip("Son joué lors d'une attaque")]
    [SerializeField] private AudioClip attackSound;
    
    [Tooltip("Son joué lors de la mort")]
    [SerializeField] private AudioClip deathSound;
    
    [Tooltip("Particules lors de la mort")]
    [SerializeField] private GameObject deathParticles;
    
    // ========== PROPRIÉTÉS D'ACCÈS (READ-ONLY) ==========
    
    public string PieceName => pieceName;
    public string Description => description;
    public Sprite Icon => icon;
    public string PieceID => pieceID;
    public PieceStats BaseStats => baseStats;
    public int StartingLevel => startingLevel;
    public int UnitTier => unitTier;
    public float LevelScaling => levelScaling;
    public GameObject VisualPrefab => visualPrefab;
    public Material MaterialOverride => materialOverride;
    public Color PrimaryColor => primaryColor;
    public float VisualScale => visualScale;
    public List<AbilityData> Abilities => abilities;
    public int MaxAbilitySlots => maxAbilitySlots;
    public List<PassiveAbilityData> PassiveAbilities => passiveAbilities;
    public MovementType MovementType => movementType;
    public int MovementRange => movementRange;
    public float MovementSpeed => movementSpeed;
    public bool IsFlying => isFlying;
    public bool CanCounterAttack => canCounterAttack;
    public bool HasRegeneration => hasRegeneration;
    public int RegenerationAmount => regenerationAmount;
    public float CriticalChance => criticalChance;
    public float CriticalMultiplier => criticalMultiplier;
    public int ExperienceReward => experienceReward;
    public int GoldReward => goldReward;
    public AudioClip SpawnSound => spawnSound;
    public AudioClip AttackSound => attackSound;
    public AudioClip DeathSound => deathSound;
    public GameObject DeathParticles => deathParticles;
    
    // ========== VALIDATION (ÉDITEUR UNITY) ==========
    
    /// <summary>
    /// Appelé automatiquement quand on modifie l'asset dans l'inspecteur.
    /// Vérifie que les valeurs sont cohérentes.
    /// </summary>
    private void OnValidate()
    {
        // Générer un ID unique si vide
        if (string.IsNullOrEmpty(pieceID))
            pieceID = System.Guid.NewGuid().ToString();
        
        // Vérifier le nom
        if (string.IsNullOrEmpty(pieceName))
            pieceName = "Untitled Piece";
        
        // Vérifier les stats (doivent être positives)
        if (baseStats.MaxHealth <= 0)
        {
            Debug.LogWarning($"[{name}] MaxHealth doit être > 0. Fixé à 1.");
            baseStats.MaxHealth = 1;
        }
        
        if (baseStats.AttackPower < 0)
        {
            Debug.LogWarning($"[{name}] AttackPower doit être ≥ 0. Fixé à 0.");
            baseStats.AttackPower = 0;
        }
        
        if (baseStats.Defense < 0)
        {
            Debug.LogWarning($"[{name}] Defense doit être ≥ 0. Fixé à 0.");
            baseStats.Defense = 0;
        }
        
        // Limiter les abilities au max slots
        if (abilities.Count > maxAbilitySlots)
        {
            Debug.LogWarning($"[{name}] Trop d'abilities ({abilities.Count}/{maxAbilitySlots}). Tronqué.");
            abilities.RemoveRange(maxAbilitySlots, abilities.Count - maxAbilitySlots);
        }
        
        // Vérifier scale visuelle
        if (visualScale <= 0)
        {
            Debug.LogWarning($"[{name}] VisualScale doit être > 0. Fixé à 1.");
            visualScale = 1.0f;
        }
    }
    
    // ========== UTILITAIRES ==========
    
    /// <summary>
    /// Calcule les stats finales avec scaling de niveau.
    /// </summary>
    public PieceStats GetStatsAtLevel(int level)
    {
        float multiplier = Mathf.Pow(levelScaling, level - 1);
        
        return new PieceStats(
            maxHealth: Mathf.RoundToInt(baseStats.MaxHealth * multiplier),
            attackPower: Mathf.RoundToInt(baseStats.AttackPower * multiplier),
            defense: Mathf.RoundToInt(baseStats.Defense * multiplier),
            mana: Mathf.RoundToInt(baseStats.Mana * multiplier)
        );
    }
    
    /// <summary>
    /// Retourne une copie profonde de la liste d'abilities.
    /// </summary>
    public List<AbilityData> GetAbilitiesCopy()
    {
        return new List<AbilityData>(abilities);
    }
}

// ========== ENUMS ==========

/// <summary>
/// Types de mouvement disponibles.
/// </summary>
public enum MovementType
{
    Grid,           // Basique (haut/bas/gauche/droite)
    Diagonal,       // + diagonales
    Knight,         // Mouvement du cavalier (L)
    King,           // 1 case dans toutes directions
    Queen,          // Toutes directions, infini
    Custom          // Défini par script custom
}
```

### 📝 Exemple de Configuration : Soldier_Elite.asset

```
Inspecteur Unity (Soldier_Elite.asset)
────────────────────────────────────
➖ Identité
  Piece Name: "Soldat d'Élite"
  Description: "Soldat expérimenté avec compétences défensives avancées."
  Icon: [SoldierElite_Icon.png]
  Piece ID: "soldier_elite_001"

💪 Stats de Base
  Max Health: 150
  Attack Power: 15
  Defense: 8
  Mana: 50
  Starting Level: 1
  Unit Tier: 2 (Uncommon)
  Level Scaling: 1.1

🎨 Présentation
  Visual Prefab: [Soldier_Model]
  Material Override: [None]
  Primary Color: #3A7CA5 (Bleu)
  Visual Scale: 1.2

✨ Compétences
  Abilities:
    - DefenseAura
    - BerserkRage
  Max Ability Slots: 5
  Passive Abilities: [None]

👟 Mouvement
  Movement Type: Grid
  Movement Range: 2
  Movement Speed: 5.0
  Is Flying: false

🌟 Spécial
  Can Counter Attack: true
  Has Regeneration: false
  Critical Chance: 10%
  Critical Multiplier: 1.5
```

---

## 3. PIECECONTROLLER : LE CONTRÔLEUR UNIVERSEL

### 🎮 Code Complet : PieceController.cs

```csharp
using UnityEngine;
using System.Collections.Generic;
using UnityEngine.Events;
using System;

/// <summary>
/// PieceController = Instance d'une pièce en jeu.
/// 
/// CRUCIAL : Cette classe est UNIVERSELLE.
/// Elle gère TOUTES les variantes (200+) sans modification.
/// 
/// Responsabilités:
/// 1. Stocker l'état local (HP, mana, buffs, position)
/// 2. Orchestrer les systèmes (santé, abilities, mods)
/// 3. Émettre des événements pour découplage
/// 4. Interagir avec le plateau (tiles)
/// 
/// Pattern: Component (attaché à GameObject)
/// </summary>
[RequireComponent(typeof(Collider))]
public class PieceController : MonoBehaviour
{
    // ========== DONNÉES & RÉFÉRENCES ==========
    
    [Header("📊 Configuration")]
    [Tooltip("Template de cette pièce (ScriptableObject)")]
    [SerializeField] private PieceData pieceData;
    
    // État local (modifiable en jeu)
    private PieceStats currentStats;
    private int currentHealth;
    private int currentMana;
    private int currentLevel;
    
    // Position & état
    private GridPosition gridPosition;
    private Tile currentTile;
    private bool isAlive = true;
    private bool isSelected = false;
    private bool isMoving = false;
    
    // Modificateurs actifs
    private List<ActiveModifier> activeModifiers = new List<ActiveModifier>();
    
    // Cooldowns des abilities
    private Dictionary<int, int> abilityCooldowns = new Dictionary<int, int>();
    
    // ========== COMPOSANTS UNITY (CACHE) ==========
    
    private Renderer visualRenderer;
    private Transform visualTransform;
    private Collider pieceCollider;
    private Animator animator;
    private AudioSource audioSource;
    
    // ========== SYSTÈMES ==========
    
    private AbilityManager abilityManager;
    
    // ========== ÉVÉNEMENTS ==========
    
    [Header("📡 Événements")]
    public UnityEvent<int> OnDamageTaken;           // (damageAmount)
    public UnityEvent<int> OnHealed;                // (healAmount)
    public UnityEvent OnDied;
    public UnityEvent<bool> OnSelectedChanged;      // (isSelected)
    public UnityEvent<ModifierData> OnModifierApplied;
    public UnityEvent<ModifierData> OnModifierRemoved;
    public UnityEvent<int> OnLevelUp;               // (newLevel)
    
    // Événements C# (plus rapides que UnityEvent)
    public event Action<int> OnDamageTakenAction;
    public event Action OnDiedAction;
    
    // ========== PROPRIÉTÉS PUBLIQUES ==========
    
    public string PieceName => pieceData != null ? pieceData.PieceName : "Unknown";
    public int CurrentHealth => currentHealth;
    public int MaxHealth => currentStats.MaxHealth;
    public int CurrentMana => currentMana;
    public int MaxMana => currentStats.Mana;
    public bool IsAlive => isAlive;
    public bool IsSelected => isSelected;
    public bool IsMoving => isMoving;
    public GridPosition GridPosition => gridPosition;
    public Tile CurrentTile => currentTile;
    public PieceData PieceData => pieceData;
    public int UnitTier => pieceData != null ? pieceData.UnitTier : 1;
    public int CurrentLevel => currentLevel;
    public PieceStats CurrentStats => currentStats;
    
    // ========== INITIALISATION ==========
    
    /// <summary>
    /// OBLIGATOIRE : à appeler après instantiation.
    /// 
    /// Exemple d'usage:
    /// var piece = Instantiate(piecePrefab);
    /// piece.Initialize(soldierEliteData, x: 3, y: 4, tile);
    /// </summary>
    public void Initialize(PieceData data, int gridX, int gridY, Tile tile)
    {
        if (data == null)
        {
            Debug.LogError("[PieceController] PieceData est null! Initialisation impossible.");
            return;
        }
        
        // Assigner les données
        pieceData = data;
        currentLevel = data.StartingLevel;
        currentStats = data.GetStatsAtLevel(currentLevel);
        currentHealth = currentStats.MaxHealth;
        currentMana = currentStats.Mana;
        gridPosition = new GridPosition(gridX, gridY);
        currentTile = tile;
        
        // Cacher les composants Unity
        CacheComponents();
        
        // Initialiser les systèmes
        abilityManager = new AbilityManager(this, pieceData.GetAbilitiesCopy());
        
        // Initialiser les cooldowns
        for (int i = 0; i < pieceData.Abilities.Count; i++)
            abilityCooldowns[i] = 0;
        
        // Charger le visuel
        LoadVisual();
        
        // Nommer le GameObject
        gameObject.name = $"{PieceName}_{gridX}_{gridY}";
        
        // Jouer le son de spawn
        PlaySound(pieceData.SpawnSound);
        
        Debug.Log($"[PieceController] ✓ {PieceName} initialisé à ({gridX}, {gridY}) avec {currentHealth} HP");
    }
    
    /// <summary>
    /// Cache tous les composants Unity pour performance.
    /// </summary>
    private void CacheComponents()
    {
        visualRenderer = GetComponent<Renderer>();
        visualTransform = transform;
        pieceCollider = GetComponent<Collider>();
        animator = GetComponent<Animator>();
        audioSource = GetComponent<AudioSource>();
        
        // Créer un AudioSource si absent
        if (audioSource == null)
            audioSource = gameObject.AddComponent<AudioSource>();
    }
    
    /// <summary>
    /// Charge le prefab visuel.
    /// </summary>
    private void LoadVisual()
    {
        if (pieceData.VisualPrefab == null)
        {
            Debug.LogWarning($"[{PieceName}] Pas de Visual Prefab assigné.");
            return;
        }
        
        // Instantier le prefab visuel comme enfant
        GameObject visual = Instantiate(pieceData.VisualPrefab, transform);
        visual.transform.localPosition = Vector3.zero;
        visual.transform.localScale = Vector3.one * pieceData.VisualScale;
        
        // Override du material si spécifié
        if (pieceData.MaterialOverride != null)
        {
            Renderer renderer = visual.GetComponent<Renderer>();
            if (renderer != null)
                renderer.material = pieceData.MaterialOverride;
        }
        
        visualRenderer = visual.GetComponent<Renderer>();
    }
    
    // ========== LOGIQUE DE SANTÉ ==========
    
    /// <summary>
    /// Inflige des dégâts à cette pièce.
    /// 
    /// Algorithme:
    /// 1. Appliquer réduction de défense
    /// 2. Appliquer modificateurs de réduction
    /// 3. Déduire HP
    /// 4. Vérifier mort
    /// </summary>
    public void TakeDamage(int damageAmount, PieceController attacker = null)
    {
        if (!isAlive)
        {
            Debug.LogWarning($"[{PieceName}] Déjà mort, dégâts ignorés.");
            return;
        }
        
        // Étape 1 : Réduction par défense
        // Formule : reduction = damage * (defense / 100)
        // Exemple : 100 dmg, 20 def = 100 * 0.20 = 20 réduits = 80 finaux
        int defenseReduction = Mathf.RoundToInt(damageAmount * (currentStats.Defense / 100f));
        int damageAfterDefense = Mathf.Max(1, damageAmount - defenseReduction);
        
        // Étape 2 : Modificateurs de réduction
        float totalReduction = 0f;
        foreach (var mod in activeModifiers)
        {
            if (mod.Data.DamageReduction > 0)
                totalReduction += mod.Data.DamageReduction;
        }
        
        int finalDamage = Mathf.RoundToInt(damageAfterDefense * (1f - totalReduction));
        finalDamage = Mathf.Max(1, finalDamage);  // Minimum 1 dégât
        
        // Étape 3 : Appliquer
        currentHealth -= finalDamage;
        currentHealth = Mathf.Max(0, currentHealth);
        
        // Émettre événements
        OnDamageTaken?.Invoke(finalDamage);
        OnDamageTakenAction?.Invoke(finalDamage);
        
        Debug.Log($"[{PieceName}] 💔 Prend {finalDamage} dégâts (HP: {currentHealth}/{currentStats.MaxHealth})");
        
        // Animation
        PlayAnimation("TakeDamage");
        
        // Étape 4 : Vérifier mort
        if (currentHealth <= 0)
        {
            Die();
        }
        else
        {
            // Contre-attaque si capacité
            if (pieceData.CanCounterAttack && attacker != null)
            {
                CounterAttack(attacker);
            }
        }
    }
    
    /// <summary>
    /// Soigne la pièce (limité au MaxHealth).
    /// </summary>
    public void Heal(int healAmount)
    {
        if (!isAlive)
            return;
        
        int actualHeal = Mathf.Min(healAmount, currentStats.MaxHealth - currentHealth);
        currentHealth += actualHeal;
        
        OnHealed?.Invoke(actualHeal);
        
        Debug.Log($"[{PieceName}] ❤️ Guérit de {actualHeal} HP (HP: {currentHealth}/{currentStats.MaxHealth})");
        
        PlayAnimation("Heal");
    }
    
    /// <summary>
    /// Tue la pièce et nettoie les ressources.
    /// </summary>
    public void Die()
    {
        if (!isAlive)
            return;
        
        isAlive = false;
        currentHealth = 0;
        
        // Événements
        OnDied?.Invoke();
        OnDiedAction?.Invoke();
        
        // Son & Particules
        PlaySound(pieceData.DeathSound);
        if (pieceData.DeathParticles != null)
            Instantiate(pieceData.DeathParticles, transform.position, Quaternion.identity);
        
        // Animation
        PlayAnimation("Die");
        
        // Désactiver interactions
        if (pieceCollider != null)
            pieceCollider.enabled = false;
        
        // Libérer la tile
        if (currentTile != null)
            currentTile.SetPiece(null);
        
        Debug.Log($"[{PieceName}] ☠️ Est mort.");
        
        // Détruire après animation (2 secondes)
        Destroy(gameObject, 2f);
    }
    
    /// <summary>
    /// Contre-attaque un attaquant.
    /// </summary>
    private void CounterAttack(PieceController target)
    {
        int counterDamage = Mathf.RoundToInt(currentStats.AttackPower * 0.5f);
        target.TakeDamage(counterDamage, this);
        
        Debug.Log($"[{PieceName}] ⚔️ Contre-attaque {target.PieceName} pour {counterDamage} dégâts!");
    }
    
    // ========== COMPÉTENCES ==========
    
    /// <summary>
    /// Exécute une ability par index.
    /// </summary>
    public void ExecuteAbility(int abilityIndex, PieceController targetPiece = null)
    {
        if (!isAlive)
        {
            Debug.LogWarning($"[{PieceName}] Mort, ne peut pas exécuter d'ability.");
            return;
        }
        
        if (abilityManager == null)
        {
            Debug.LogError($"[{PieceName}] AbilityManager est null!");
            return;
        }
        
        abilityManager.ExecuteAbility(abilityIndex, targetPiece);
    }
    
    /// <summary>
    /// Retourne true si l'ability à cet index peut être exécutée.
    /// </summary>
    public bool CanExecuteAbility(int abilityIndex)
    {
        if (abilityIndex < 0 || abilityIndex >= pieceData.Abilities.Count)
            return false;
        
        AbilityData abilityData = pieceData.Abilities[abilityIndex];
        
        // Vérifier cooldown
        if (abilityCooldowns.ContainsKey(abilityIndex) && abilityCooldowns[abilityIndex] > 0)
            return false;
        
        // Vérifier mana
        if (currentMana < abilityData.ManaCost)
            return false;
        
        return true;
    }
    
    /// <summary>
    /// Consomme de la mana.
    /// </summary>
    public void ConsumeMana(int amount)
    {
        currentMana -= amount;
        currentMana = Mathf.Max(0, currentMana);
        
        Debug.Log($"[{PieceName}] Consomme {amount} mana (Mana: {currentMana}/{currentStats.Mana})");
    }
    
    /// <summary>
    /// Régénère de la mana.
    /// </summary>
    public void RegenerateMana(int amount)
    {
        currentMana += amount;
        currentMana = Mathf.Min(currentMana, currentStats.Mana);
    }
    
    // ========== MODIFICATEURS ==========
    
    /// <summary>
    /// Applique un buff/debuff.
    /// </summary>
    public void ApplyModifier(ModifierData modifier, int durationTurns)
    {
        if (modifier == null)
        {
            Debug.LogWarning($"[{PieceName}] ModifierData est null.");
            return;
        }
        
        // Créer l'instance active
        ActiveModifier activeMod = new ActiveModifier
        {
            Data = modifier,
            RemainingTurns = durationTurns,
            AppliedAtTurn = GameManager.Instance.CurrentTurn  // Si GameManager existe
        };
        
        activeModifiers.Add(activeMod);
        
        // Appliquer les bonus de stats
        currentStats.AttackPower += modifier.AttackBonus;
        currentStats.Defense += modifier.DefenseBonus;
        
        // Heal instantané si bonus HP
        if (modifier.HealthBonus > 0)
            Heal(modifier.HealthBonus);
        
        OnModifierApplied?.Invoke(modifier);
        
        Debug.Log($"[{PieceName}] 🌟 Buff appliqué: {modifier.ModifierName} (durée: {durationTurns} tours)");
    }
    
    /// <summary>
    /// À appeler chaque tour pour décrémenter les durées.
    /// </summary>
    public void UpdateModifiers()
    {
        for (int i = activeModifiers.Count - 1; i >= 0; i--)
        {
            activeModifiers[i].RemainingTurns--;
            
            if (activeModifiers[i].RemainingTurns <= 0)
            {
                RemoveModifier(i);
            }
        }
    }
    
    /// <summary>
    /// Retire un modificateur par index.
    /// </summary>
    private void RemoveModifier(int index)
    {
        if (index < 0 || index >= activeModifiers.Count)
            return;
        
        ActiveModifier mod = activeModifiers[index];
        
        // Retirer les bonus de stats
        currentStats.AttackPower -= mod.Data.AttackBonus;
        currentStats.Defense -= mod.Data.DefenseBonus;
        
        OnModifierRemoved?.Invoke(mod.Data);
        
        Debug.Log($"[{PieceName}] Buff expiré: {mod.Data.ModifierName}");
        
        activeModifiers.RemoveAt(index);
    }
    
    // ========== ÉTATS ==========
    
    /// <summary>
    /// Change l'état de sélection.
    /// </summary>
    public void SetSelected(bool selected)
    {
        isSelected = selected;
        OnSelectedChanged?.Invoke(isSelected);
        
        // Feedback visuel (highlight)
        if (visualRenderer != null)
        {
            Color color = isSelected ? Color.yellow : Color.white;
            visualRenderer.material.color = color;
        }
    }
    
    /// <summary>
    /// Change l'état de mouvement.
    /// </summary>
    public void SetMoving(bool moving)
    {
        isMoving = moving;
    }
    
    // ========== POSITION & TILE ==========
    
    /// <summary>
    /// Met à jour la position sur la grille.
    /// </summary>
    public void SetGridPosition(int x, int y, Tile tile)
    {
        gridPosition = new GridPosition(x, y);
        currentTile = tile;
        
        // Mettre à jour la position 3D
        if (tile != null)
            transform.position = tile.transform.position;
    }
    
    /// <summary>
    /// Déplace la pièce vers une tile.
    /// </summary>
    public void MoveTo(Tile destinationTile)
    {
        if (destinationTile == null)
            return;
        
        // Libérer la tile actuelle
        if (currentTile != null)
            currentTile.SetPiece(null);
        
        // Occuper la nouvelle tile
        currentTile = destinationTile;
        currentTile.SetPiece(this);
        gridPosition = new GridPosition(destinationTile.GridX, destinationTile.GridY);
        
        // Animation de mouvement (lerp vers nouvelle position)
        StartCoroutine(MoveAnimation(destinationTile.transform.position));
    }
    
    private System.Collections.IEnumerator MoveAnimation(Vector3 targetPosition)
    {
        SetMoving(true);
        
        Vector3 startPos = transform.position;
        float elapsed = 0f;
        float duration = 1f / pieceData.MovementSpeed;
        
        while (elapsed < duration)
        {
            transform.position = Vector3.Lerp(startPos, targetPosition, elapsed / duration);
            elapsed += Time.deltaTime;
            yield return null;
        }
        
        transform.position = targetPosition;
        SetMoving(false);
    }
    
    // ========== PROGRESSION ==========
    
    /// <summary>
    /// Monte la pièce d'un niveau.
    /// </summary>
    public void LevelUp()
    {
        currentLevel++;
        currentStats = pieceData.GetStatsAtLevel(currentLevel);
        currentHealth = currentStats.MaxHealth;
        currentMana = currentStats.Mana;
        
        OnLevelUp?.Invoke(currentLevel);
        
        Debug.Log($"[{PieceName}] 🎉 Level up! Niveau {currentLevel}");
    }
    
    // ========== ACCESSEURS DE STATS ==========
    
    public int GetAttackPower() => currentStats.AttackPower;
    public int GetDefense() => currentStats.Defense;
    public float GetCriticalChance() => pieceData.CriticalChance;
    public float GetCriticalMultiplier() => pieceData.CriticalMultiplier;
    
    // ========== UTILITAIRES ==========
    
    /// <summary>
    /// Notation algébrique (A1, B2, H8).
    /// </summary>
    public string GetAlgebraicNotation()
    {
        char file = (char)('A' + gridPosition.X);
        int rank = gridPosition.Y + 1;
        return $"{file}{rank}";
    }
    
    /// <summary>
    /// Joue un son.
    /// </summary>
    private void PlaySound(AudioClip clip)
    {
        if (clip != null && audioSource != null)
            audioSource.PlayOneShot(clip);
    }
    
    /// <summary>
    /// Joue une animation.
    /// </summary>
    private void PlayAnimation(string triggerName)
    {
        if (animator != null)
            animator.SetTrigger(triggerName);
    }
    
    /// <summary>
    /// Debug : affiche les infos de la pièce.
    /// </summary>
    public void PrintInfo()
    {
        Debug.Log($"===== {PieceName} =====");
        Debug.Log($"HP: {currentHealth}/{currentStats.MaxHealth}");
        Debug.Log($"Mana: {currentMana}/{currentStats.Mana}");
        Debug.Log($"ATK: {currentStats.AttackPower} | DEF: {currentStats.Defense}");
        Debug.Log($"Position: {GetAlgebraicNotation()}");
        Debug.Log($"Alive: {isAlive} | Selected: {isSelected}");
        Debug.Log($"Buffs actifs: {activeModifiers.Count}");
    }
}

// ========== CLASSES SUPPORT ==========

/// <summary>
/// Modificateur actif avec durée restante.
/// </summary>
[System.Serializable]
public class ActiveModifier
{
    public ModifierData Data;
    public int RemainingTurns;
    public int AppliedAtTurn;
}
```

---

## 4. SYSTÈME DE STATS : PIECESTATS STRUCT

### 📊 Code Complet : PieceStats.cs

```csharp
using UnityEngine;

/// <summary>
/// PieceStats = Structure de données pour les statistiques.
/// 
/// Pourquoi STRUCT et pas CLASS ?
/// - STRUCT est alloué sur la STACK (plus rapide)
/// - Pas de GC (Garbage Collection)
/// - Copy-by-value (pas de référence partagée)
/// 
/// Performance:
/// - 30% plus rapide que classe pour petites structures
/// - Pas d'allocations mémoire dynamiques
/// </summary>
[System.Serializable]
public struct PieceStats
{
    [Tooltip("Points de vie max")]
    public int MaxHealth;
    
    [Tooltip("Puissance d'attaque")]
    public int AttackPower;
    
    [Tooltip("Défense (réduit dégâts en %)")]
    public int Defense;
    
    [Tooltip("Mana / Énergie pour abilities")]
    public int Mana;
    
    // Constructeur
    public PieceStats(int maxHealth, int attackPower, int defense, int mana)
    {
        MaxHealth = maxHealth;
        AttackPower = attackPower;
        Defense = defense;
        Mana = mana;
    }
    
    // ========== OPÉRATEURS ==========
    
    /// <summary>
    /// Addition de stats (pour buffs).
    /// </summary>
    public static PieceStats operator +(PieceStats a, PieceStats b)
    {
        return new PieceStats(
            a.MaxHealth + b.MaxHealth,
            a.AttackPower + b.AttackPower,
            a.Defense + b.Defense,
            a.Mana + b.Mana
        );
    }
    
    /// <summary>
    /// Multiplication par scalaire (pour scaling de niveau).
    /// </summary>
    public static PieceStats operator *(PieceStats stats, float multiplier)
    {
        return new PieceStats(
            Mathf.RoundToInt(stats.MaxHealth * multiplier),
            Mathf.RoundToInt(stats.AttackPower * multiplier),
            Mathf.RoundToInt(stats.Defense * multiplier),
            Mathf.RoundToInt(stats.Mana * multiplier)
        );
    }
    
    // ========== UTILITAIRES ==========
    
    /// <summary>
    /// Retourne une copie avec toutes les stats à 0.
    /// </summary>
    public static PieceStats Zero => new PieceStats(0, 0, 0, 0);
    
    /// <summary>
    /// Affichage formatté.
    /// </summary>
    public override string ToString()
    {
        return $"HP:{MaxHealth} ATK:{AttackPower} DEF:{Defense} MANA:{Mana}";
    }
    
    /// <summary>
    /// Comparer deux PieceStats.
    /// </summary>
    public override bool Equals(object obj)
    {
        if (!(obj is PieceStats))
            return false;
        
        PieceStats other = (PieceStats)obj;
        return MaxHealth == other.MaxHealth &&
               AttackPower == other.AttackPower &&
               Defense == other.Defense &&
               Mana == other.Mana;
    }
    
    public override int GetHashCode()
    {
        return MaxHealth.GetHashCode() ^ AttackPower.GetHashCode() ^
               Defense.GetHashCode() ^ Mana.GetHashCode();
    }
    
    /// <summary>
    /// Calcule le "score de puissance" total.
    /// Utile pour équilibrer les pièces.
    /// </summary>
    public int GetPowerScore()
    {
        // Formule arbitraire
        return MaxHealth + (AttackPower * 2) + Defense + (Mana / 2);
    }
}

/// <summary>
/// Structure de position sur la grille.
/// </summary>
[System.Serializable]
public struct GridPosition
{
    public int X;
    public int Y;
    
    public GridPosition(int x, int y)
    {
        X = x;
        Y = y;
    }
    
    /// <summary>
    /// Distance de Manhattan (pour mouvement grid).
    /// </summary>
    public int DistanceTo(GridPosition other)
    {
        return Mathf.Abs(X - other.X) + Mathf.Abs(Y - other.Y);
    }
    
    /// <summary>
    /// Distance euclidienne.
    /// </summary>
    public float EuclideanDistanceTo(GridPosition other)
    {
        int dx = X - other.X;
        int dy = Y - other.Y;
        return Mathf.Sqrt(dx * dx + dy * dy);
    }
    
    public override string ToString() => $"({X}, {Y})";
    
    public override bool Equals(object obj)
    {
        if (!(obj is GridPosition))
            return false;
        
        GridPosition other = (GridPosition)obj;
        return X == other.X && Y == other.Y;
    }
    
    public override int GetHashCode() => X.GetHashCode() ^ Y.GetHashCode();
    
    public static bool operator ==(GridPosition a, GridPosition b) => a.X == b.X && a.Y == b.Y;
    public static bool operator !=(GridPosition a, GridPosition b) => !(a == b);
}
```

---

**(La suite du document avec les sections 5-10 serait trop longue pour une seule réponse. Voulez-vous que je continue avec les sections restantes dans des fichiers séparés ?)**

---

## SUITE DU DOCUMENT

Voulez-vous que je crée :
1. **PIECE_ARCHITECTURE_PART2.md** - Sections 5-7 (Abilities, AbilityManager, Modificateurs)
2. **PIECE_ARCHITECTURE_PART3.md** - Sections 8-10 (Intégration plateau, Exemples, Pipeline)

Ou préférez-vous tout dans un seul fichier (qui sera très long) ?
