# 🎯 Guide Ultime : Architecture Modulaire Data-Driven d'un Système RPG d'Échecs 200+ Variantes

**Créer un système d'échecs RPG évolutif, maintenable, et performant avec Unity en C#**

---

## TABLE DES MATIÈRES

1. [Introduction & Philosophie](#1-introduction--philosophie)
2. [Architecture Globale & Stack Technique](#2-architecture-globale--stack-technique)
3. [Foundation : Système de Données (ScriptableObjects)](#3-foundation--système-de-données-scriptableobjects)
4. [Système de Contrôle : PieceController Universel](#4-système-de-contrôle--piececontroller-universel)
5. [Système de Compétences : Strategy Pattern IAbility](#5-système-de-compétences--strategy-pattern-iability)
6. [Système de Modificateurs : Buffs/Debuffs](#6-système-de-modificateurs--buffsdebuffs)
7. [Scaling à 200+ Variantes : Pipeline de Création](#7-scaling-à-200-variantes--pipeline-de-création)
8. [Optimisations & Déploiement Production](#8-optimisations--déploiement-production)

---

## 1. INTRODUCTION & PHILOSOPHIE

### 🎲 Le Défi

Vous développez un jeu d'échecs RPG avec ambition :
- **200+ variantes de pièces** (Soldat Basique, Soldat d'Élite, Guerrier Berserker, Mage de Feu, etc.)
- **Chaque variante a des stats uniques** (PV, Attaque, Défense, Mana)
- **Chaque variante a 1-5 compétences distinctes**
- **L'équipe design doit pouvoir itérer** sans recompiler le code
- **Performance critique** : le plateau doit gérer 1000+ pièces simultanées

### ❌ Approche Naïve (À ÉVITER)

```csharp
// ❌ MAUVAIS : hiérarchie de classes profonde
public class Piece { ... }
public class Soldier : Piece { ... }
public class EliteSoldier : Soldier { ... }
public class BerserkSoldier : EliteSoldier { ... }  // Problème du diamant!
public class PaladinSoldier : Soldier { ... }

// Résultat : 200+ classes interconnectées, impossible à maintenir
```

**Problèmes :**
- Hiérarchie complexe (problème du diamant)
- Chaque variante = recompilation
- Designers ne peuvent pas créer de variantes
- Modificatio d'une classe mère = risque de casser 50+ enfants

### ✅ Notre Approche : Data-Driven + Composition

```
PieceData (Asset ScriptableObject) + PieceController (MonoBehaviour)
         ↓
      [Données]     +    [Logique Unifiée]
     - HP
     - ATK          PieceController.cs (1 SEULE classe)
     - DEF          - TakeDamage()
     - Abilities    - ExecuteAbility()
                    - ApplyModifier()
```

**Avantages :**
- ✅ 1 seule classe PieceController pour TOUTES les 200+ variantes
- ✅ Créer nouvelle variante = créer 1 asset (pas de code)
- ✅ Designers itèrent indépendamment
- ✅ 0 recompilation nécessaire
- ✅ Maximum de réutilisabilité de code

---

## 2. ARCHITECTURE GLOBALE & STACK TECHNIQUE

### 📐 Diagramme d'Architecture

```
┌─────────────────────────────────────────────────┐
│          PRÉSENTATION (Layer 3)                 │
│  - Prefab visuel (Cube, Model 3D)               │
│  - UI (HealthBar, AbilityButtons)               │
│  - Particules/Animations                        │
└──────────────────┬──────────────────────────────┘
                   │
        ┌──────────▼──────────┐
        │ PieceController.cs  │
        │ (Orchestration)     │
        │ - Initialize()      │
        │ - TakeDamage()      │
        │ - ExecuteAbility()  │
        └──────────┬──────────┘
                   │
        ┌──────────▼──────────────────────┐
        │    SYSTÈMES MÉTIER (Layer 2)    │
        │ - HealthSystem                  │
        │ - AbilityManager                │
        │ - ModifierManager               │
        │ - CombatSystem                  │
        └──────────┬───────────────────────┘
                   │
┌──────────────────▼────────────────────────────┐
│        DONNÉES (Layer 1 - Source of Truth)   │
│  - PieceData (ScriptableObject)              │
│  - AbilityData (ScriptableObject)            │
│  - ModifierData (ScriptableObject)           │
└───────────────────────────────────────────────┘
```

### 🛠️ Stack Technologique

| Component | Technology | Raison |
|-----------|-----------|--------|
| **Données** | ScriptableObjects | Créées dans l'inspecteur, réutilisables, aucune recompilation |
| **Logique** | MonoBehaviour | Gestion du cycle de vie, cache agressif |
| **Compétences** | Strategy Pattern (IAbility) | Extensible, découplé, testable |
| **Communication** | UnityEvent + C# Action | Découplage des systèmes |
| **Performance** | Object Pooling | Recycler les pièces, moins d'allocations |
| **Stats Système** | Struct (PieceStats) | Plus rapide que classe, pas de GC |

### 📦 Structure des Dossiers Recommandée

```
Assets/
├── Scripts/
│   ├── Core/
│   │   ├── PieceData.cs               (Data class)
│   │   ├── PieceController.cs         (Main orchestrator)
│   │   ├── AbilityManager.cs          (Ability executor)
│   │   ├── AbilityData.cs             (Ability container)
│   │   ├── ModifierData.cs            (Buff/debuff container)
│   │   └── PieceStats.cs              (Struct for stats)
│   ├── Abilities/
│   │   ├── IAbility.cs                (Strategy interface)
│   │   ├── DefenseAuraAbility.cs
│   │   ├── BerserkRageAbility.cs
│   │   ├── HolyShieldAbility.cs
│   │   └── [...10+ abilities]
│   ├── Systems/
│   │   ├── HealthSystem.cs
│   │   ├── PieceStateManager.cs
│   │   ├── CombatSystem.cs
│   │   ├── BoardEventManager.cs
│   │   └── GameManager.cs
│   ├── AI/
│   │   ├── IAIStrategy.cs
│   │   ├── AggressiveAI.cs
│   │   └── DefensiveAI.cs
│   ├── Utils/
│   │   ├── PiecePool.cs
│   │   └── EnumDefinitions.cs
│   └── Editor/
│       └── PieceDataEditor.cs         (Custom inspector)
├── ScriptableObjects/
│   ├── Pieces/                        (200+ PieceData assets)
│   │   ├── Soldier_Basic.asset
│   │   ├── Soldier_Elite.asset
│   │   ├── Mage_Fire.asset
│   │   └── [...198 more variants]
│   ├── Abilities/                     (50+ AbilityData assets)
│   │   ├── DefenseAura.asset
│   │   ├── BerserkRage.asset
│   │   └── [...48 more abilities]
│   └── Modifiers/
│       ├── AttackBoost.asset
│       └── [...other buffs]
├── Prefabs/
│   ├── Visuals/
│   │   ├── Soldier_Base.prefab
│   │   ├── Mage_Base.prefab
│   │   └── [...visual variants]
│   ├── UI/
│   │   ├── HealthBarCanvas.prefab
│   │   └── AbilityButtons.prefab
│   └── Systems/
│       └── GameManager.prefab
├── Materials/
│   ├── Soldier.mat
│   ├── Mage.mat
│   └── [...]
└── Resources/
    └── PieceDatabase.asset           (Master list)
```

---

## 3. FOUNDATION : SYSTÈME DE DONNÉES (SCRIPTABLEOBJECTS)

### 🏛️ PieceData.cs : Le Conteneur Central

```csharp
using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// PieceData = Template (ou "Blueprint") d'une variante de pièce.
/// 
/// C'est un ScriptableObject qui stocke TOUTES les données
/// nécessaires pour créer une pièce en jeu.
/// 
/// Exemple : "Soldat d'Élite" = 1 PieceData.asset
/// </summary>
[CreateAssetMenu(fileName = "PieceData_", menuName = "Chess RPG/Piece Data", order = 1)]
public class PieceData : ScriptableObject
{
    [Header("Identity")]
    [SerializeField] private string pieceName = "Untitled Piece";
    [SerializeField] private string description = "";
    [SerializeField] private Sprite icon;
    
    [Header("Stats de Base")]
    [SerializeField] private PieceStats baseStats = new PieceStats(100, 10, 5, 0);
    
    [Header("Visuel & Présentation")]
    [SerializeField] private GameObject visualPrefab;  // Cube, Pyramid, Model 3D
    [SerializeField] private Material materialOverride;
    [SerializeField] private int unitTier = 1;  // 1=Basic, 2=Uncommon, 3=Rare, 4=Epic, 5=Legendary
    
    [Header("Compétences")]
    [SerializeField] private List<AbilityData> abilities = new List<AbilityData>();
    [SerializeField] private int maxAbilitiesSlots = 5;
    
    [Header("Caractéristiques Spéciales")]
    [SerializeField] private bool canCounter = false;      // Peut contre-attaquer
    [SerializeField] private bool isFlying = false;        // Ignore terrain
    [SerializeField] private float movementSpeed = 1.0f;
    [SerializeField] private int movementRange = 1;        // Cases par mouvement
    
    [Header("Progression")]
    [SerializeField] private int experienceReward = 10;
    [SerializeField] private float levelScaling = 1.1f;     // Multiplier par niveau
    
    // ========== PROPRIÉTÉS D'ACCÈS ==========
    
    public string PieceName => pieceName;
    public string Description => description;
    public Sprite Icon => icon;
    public PieceStats BaseStats => baseStats;
    public GameObject VisualPrefab => visualPrefab;
    public Material MaterialOverride => materialOverride;
    public int UnitTier => unitTier;
    public List<AbilityData> Abilities => abilities;
    public bool CanCounter => canCounter;
    public bool IsFlying => isFlying;
    public float MovementSpeed => movementSpeed;
    public int MovementRange => movementRange;
    public int ExperienceReward => experienceReward;
    public float LevelScaling => levelScaling;
    
    // ========== VALIDATION (ÉDITEUR) ==========
    
    private void OnValidate()
    {
        // Vérifier que le nom n'est pas vide
        if (string.IsNullOrEmpty(pieceName))
            pieceName = "Untitled Piece";
        
        // Vérifier que les stats sont positives
        if (baseStats.MaxHealth <= 0)
            baseStats.MaxHealth = 1;
        if (baseStats.AttackPower < 0)
            baseStats.AttackPower = 0;
        if (baseStats.Defense < 0)
            baseStats.Defense = 0;
        
        // Vérifier qu'on n'a pas plus d'abilities que de slots
        if (abilities.Count > maxAbilitiesSlots)
            abilities.RemoveRange(maxAbilitiesSlots, abilities.Count - maxAbilitiesSlots);
    }
}

/// <summary>
/// Struct pour les statistiques (plus rapide que classe, pas de GC).
/// </summary>
public struct PieceStats
{
    public int MaxHealth;
    public int AttackPower;
    public int Defense;
    public int Mana;
    
    public PieceStats(int maxHealth, int attackPower, int defense, int mana)
    {
        MaxHealth = maxHealth;
        AttackPower = attackPower;
        Defense = defense;
        Mana = mana;
    }
    
    public override string ToString() => $"HP:{MaxHealth} ATK:{AttackPower} DEF:{Defense} MANA:{Mana}";
}
```

### 📋 AbilityData.cs : Template d'une Compétence

```csharp
using UnityEngine;

/// <summary>
/// AbilityData = Conteneur de configuration pour une compétence.
/// 
/// Utilisé par PieceController -> AbilityManager -> IAbility (implémentation)
/// </summary>
[System.Serializable]
public class AbilityData : ScriptableObject
{
    [Header("Identité")]
    [SerializeField] private string abilityName = "Ability";
    [SerializeField] private string description = "";
    [SerializeField] private Sprite icon;
    
    [Header("Coûts")]
    [SerializeField] private int manaCost = 10;
    [SerializeField] private int energyCost = 0;
    
    [Header("Cooldown")]
    [SerializeField] private int cooldownTurns = 0;
    
    [Header("Ciblage")]
    [SerializeField] private TargetType targetType = TargetType.Ally;  // Ally, Enemy, Self
    [SerializeField] private int rangeInTiles = 1;
    [SerializeField] private bool requiresLineOfSight = false;
    
    [Header("Effets")]
    [SerializeField] private int damageAmount = 0;
    [SerializeField] private int healAmount = 0;
    [SerializeField] private int defenseModifier = 0;  // Buffs défense
    [SerializeField] private int attackModifier = 0;   // Buffs attaque
    
    [Header("Modificateur (Buff/Debuff)")]
    [SerializeField] private ModifierData appliedModifier;  // À appliquer sur cible
    [SerializeField] private int modifierDuration = 3;      // Durée en tours
    
    // Properties
    public string AbilityName => abilityName;
    public int ManaCost => manaCost;
    public int EnergyCost => energyCost;
    public int CooldownTurns => cooldownTurns;
    public TargetType TargetType => targetType;
    public int RangeInTiles => rangeInTiles;
    public int DamageAmount => damageAmount;
    public int HealAmount => healAmount;
    public ModifierData AppliedModifier => appliedModifier;
    public int ModifierDuration => modifierDuration;
}

public enum TargetType { Self, Ally, Enemy, AnyUnit, Ground }
```

### 🛡️ ModifierData.cs : Buffs et Debuffs

```csharp
using UnityEngine;

/// <summary>
/// ModifierData = Configuration d'un buff/debuff.
/// 
/// Exemple : "+20 Attaque pendant 3 tours" = 1 ModifierData.asset
/// </summary>
[CreateAssetMenu(fileName = "Modifier_", menuName = "Chess RPG/Modifier", order = 3)]
public class ModifierData : ScriptableObject
{
    [SerializeField] private string modifierName = "Buff";
    [SerializeField] private string description = "";
    [SerializeField] private ModifierType type = ModifierType.Positive;
    
    [SerializeField] private int healthBonus = 0;
    [SerializeField] private int attackBonus = 0;
    [SerializeField] private int defenseBonus = 0;
    
    [SerializeField] private float damageReduction = 0f;  // En % (0-1)
    [SerializeField] private bool isCrowdControl = false;  // Stun, Freeze, etc.
    
    public string ModifierName => modifierName;
    public ModifierType Type => type;
    public int HealthBonus => healthBonus;
    public int AttackBonus => attackBonus;
    public int DefenseBonus => defenseBonus;
    public float DamageReduction => damageReduction;
    public bool IsCrowdControl => isCrowdControl;
}

public enum ModifierType { Positive, Negative, Neutral }
```

---

## 4. SYSTÈME DE CONTRÔLE : PIECECONTROLLER UNIVERSEL

### 🎮 PieceController.cs : Une Classe pour Toutes les 200+ Variantes

```csharp
using UnityEngine;
using System.Collections.Generic;
using UnityEngine.Events;

/// <summary>
/// PieceController = Instance d'une pièce en jeu.
/// 
/// Responsabilités :
/// 1. Stocker l'état local (HP, buffs, position)
/// 2. Orchéstrer les systèmes (santé, compétences, modificateurs)
/// 3. Émettre des événements pour découplage
/// 
/// CRITIQUE : Cette classe ne change JAMAIS, peu importe les variantes!
/// </summary>
public class PieceController : MonoBehaviour
{
    // ========== RÉFÉRENCES AUX DONNÉES ==========
    
    [SerializeField] private PieceData pieceData;  // Template (asset)
    private PieceStats currentStats;               // Instance (modifiable)
    private int currentHealth;
    private int currentMana;
    
    // ========== ÉTAT LOCAL ==========
    
    private GridPosition gridPosition;
    private bool isAlive = true;
    private List<ModifierData> activeModifiers = new List<ModifierData>();
    private Dictionary<int, int> abilityCooldowns = new Dictionary<int, int>();  // [abilityIndex] = cooldownLeft
    
    // ========== COMPOSANTS UNITY ==========
    
    private Renderer visualRenderer;
    private Transform visualTransform;
    private Collider pieceCollider;
    
    // ========== SYSTÈMES ==========
    
    private AbilityManager abilityManager;
    
    // ========== ÉVÉNEMENTS ==========
    
    [SerializeField] private UnityEvent<int> OnDamageTaken;      // (damageAmount)
    [SerializeField] private UnityEvent OnDied;
    [SerializeField] private UnityEvent<int> OnHealed;           // (healAmount)
    [SerializeField] private UnityEvent<ModifierData> OnModifierApplied;
    
    // ========== PROPRIÉTÉS PUBLIQUES ==========
    
    public string PieceName => pieceData.PieceName;
    public int CurrentHealth => currentHealth;
    public int MaxHealth => currentStats.MaxHealth;
    public int CurrentMana => currentMana;
    public bool IsAlive => isAlive;
    public GridPosition GridPosition => gridPosition;
    public PieceData PieceData => pieceData;
    public int UnitTier => pieceData.UnitTier;
    
    // ========== INITIALISATION ==========
    
    /// <summary>
    /// À appeler IMMÉDIATEMENT après instantiation.
    /// 
    /// Exemple :
    /// var piece = Instantiate(piecePrefab);
    /// piece.Initialize(soldierData, x: 3, y: 4);
    /// </summary>
    public void Initialize(PieceData data, int gridX, int gridY)
    {
        if (data == null)
        {
            Debug.LogError("[PieceController] PieceData est null!");
            return;
        }
        
        pieceData = data;
        currentStats = data.BaseStats;
        currentHealth = currentStats.MaxHealth;
        currentMana = currentStats.Mana;
        gridPosition = new GridPosition(gridX, gridY);
        
        // Cacher les composants
        visualRenderer = GetComponent<Renderer>();
        visualTransform = transform;
        pieceCollider = GetComponent<Collider>();
        
        // Créer le gestionnaire d'abilities
        abilityManager = new AbilityManager(this, pieceData.Abilities);
        
        // Instancier le visuel
        if (pieceData.VisualPrefab != null)
        {
            GameObject visual = Instantiate(pieceData.VisualPrefab, transform);
            visualRenderer = visual.GetComponent<Renderer>();
        }
        
        gameObject.name = $"{PieceName}_{gridX}_{gridY}";
        
        Debug.Log($"[PieceController] Initialisé: {PieceName} à ({gridX}, {gridY})");
    }
    
    // ========== LOGIQUE DE SANTÉ ==========
    
    /// <summary>
    /// Inflige des dégâts et applique la réduction de défense.
    /// </summary>
    public void TakeDamage(int damageAmount, PieceController attacker = null)
    {
        if (!isAlive) return;
        
        // Appliquer la réduction de défense
        int defenseReduction = Mathf.RoundToInt(damageAmount * (currentStats.Defense / 100f));
        int finalDamage = Mathf.Max(1, damageAmount - defenseReduction);  // Min 1 dégât
        
        // Appliquer les modificateurs de réduction de dégâts
        foreach (var modifier in activeModifiers)
        {
            finalDamage = Mathf.RoundToInt(finalDamage * (1 - modifier.DamageReduction));
        }
        
        currentHealth -= finalDamage;
        OnDamageTaken?.Invoke(finalDamage);
        
        Debug.Log($"[{PieceName}] Prend {finalDamage} dégâts (HP: {currentHealth}/{currentStats.MaxHealth})");
        
        if (currentHealth <= 0)
        {
            Die();
        }
    }
    
    /// <summary>
    /// Soigne la pièce (limité à MaxHealth).
    /// </summary>
    public void Heal(int healAmount)
    {
        if (!isAlive) return;
        
        int actualHeal = Mathf.Min(healAmount, currentStats.MaxHealth - currentHealth);
        currentHealth += actualHeal;
        OnHealed?.Invoke(actualHeal);
        
        Debug.Log($"[{PieceName}] Guérit de {actualHeal} PV");
    }
    
    /// <summary>
    /// Meurt et nettoie les ressources.
    /// </summary>
    public void Die()
    {
        isAlive = false;
        currentHealth = 0;
        OnDied?.Invoke();
        
        // Désactiver visuellement
        if (pieceCollider != null)
            pieceCollider.enabled = false;
        
        Debug.Log($"[{PieceName}] Est mort.");
    }
    
    // ========== COMPÉTENCES ==========
    
    /// <summary>
    /// Exécute une compétence par index.
    /// </summary>
    public void ExecuteAbility(int abilityIndex, PieceController targetPiece = null)
    {
        if (!isAlive || abilityManager == null)
            return;
        
        abilityManager.ExecuteAbility(abilityIndex, targetPiece);
    }
    
    // ========== MODIFICATEURS ==========
    
    /// <summary>
    /// Applique un buff/debuff à cette pièce.
    /// </summary>
    public void ApplyModifier(ModifierData modifier, int durationTurns)
    {
        if (modifier == null) return;
        
        activeModifiers.Add(modifier);
        currentStats.AttackPower += modifier.AttackBonus;
        currentStats.Defense += modifier.DefenseBonus;
        currentHealth = Mathf.Min(currentHealth + modifier.HealthBonus, currentStats.MaxHealth);
        
        OnModifierApplied?.Invoke(modifier);
        
        Debug.Log($"[{PieceName}] Buff appliqué: {modifier.ModifierName}");
    }
    
    /// <summary>
    /// À appeler chaque tour pour décrémenter les durées des modificateurs.
    /// </summary>
    public void UpdateModifiers()
    {
        for (int i = activeModifiers.Count - 1; i >= 0; i--)
        {
            // TODO: Implémenter décrément de durée et suppression
            // activeModifierDurations[i]--;
            // if (activeModifierDurations[i] <= 0) activeModifiers.RemoveAt(i);
        }
    }
    
    // ========== ACCÉSSEURS DE STATS ==========
    
    public int GetAttackPower() => currentStats.AttackPower;
    public int GetDefense() => currentStats.Defense;
    public int GetCriticalChance() => 5;  // 5% base
    public float GetCriticalMultiplier() => 1.5f;
    
    // ========== UTILITAIRES ==========
    
    /// <summary>
    /// Obtient la notation algébrique (A1, B2, H8, etc.).
    /// </summary>
    public string GetAlgebraicNotation()
    {
        char file = (char)('A' + gridPosition.X);
        int rank = gridPosition.Y + 1;
        return $"{file}{rank}";
    }
}

/// <summary>
/// Position sur la grille.
/// </summary>
public struct GridPosition
{
    public int X, Y;
    
    public GridPosition(int x, int y)
    {
        X = x;
        Y = y;
    }
    
    public override string ToString() => $"({X}, {Y})";
}
```

---

## 5. SYSTÈME DE COMPÉTENCES : STRATEGY PATTERN IABILITY

### 🎲 IAbility.cs : L'Interface Stratégie

```csharp
using UnityEngine;

/// <summary>
/// IAbility = Interface pour toutes les compétences.
/// 
/// Design Pattern: Strategy
/// Avantage: Chaque ability = sa propre classe, zéro dépendance à PieceController
/// </summary>
public interface IAbility
{
    string AbilityName { get; }
    int ManaCost { get; }
    
    /// <summary>
    /// Exécute la compétence.
    /// </summary>
    void Execute(PieceController owner, PieceController targetPiece = null);
    
    /// <summary>
    /// Retourne true si la compétence peut être exécutée.
    /// </summary>
    bool CanExecute(PieceController owner);
}
```

### 🛡️ Exemple 1 : DefenseAuraAbility

```csharp
using UnityEngine;

/// <summary>
/// DefenseAuraAbility = Augmente la défense de toutes les pièces alliées.
/// </summary>
[CreateAssetMenu(fileName = "Ability_DefenseAura", menuName = "Chess RPG/Ability/Defense Aura")]
public class DefenseAuraAbility : ScriptableObject, IAbility
{
    [SerializeField] private string abilityName = "Aura de Défense";
    [SerializeField] private int manaCost = 20;
    [SerializeField] private int defenseBonus = 5;
    [SerializeField] private int radiusInTiles = 3;
    [SerializeField] private int durationTurns = 5;
    
    public string AbilityName => abilityName;
    public int ManaCost => manaCost;
    
    public void Execute(PieceController owner, PieceController targetPiece = null)
    {
        // Trouver toutes les pièces alliées à proximité
        Collider[] colliders = Physics.OverlapSphere(
            owner.transform.position,
            radiusInTiles
        );
        
        foreach (Collider col in colliders)
        {
            if (col.TryGetComponent<PieceController>(out var piece))
            {
                // Appliquer le buff
                ModifierData defenseBuff = ScriptableObject.CreateInstance<ModifierData>();
                defenseBuff.DefenseBonus = defenseBonus;
                
                piece.ApplyModifier(defenseBuff, durationTurns);
            }
        }
        
        Debug.Log($"[{owner.PieceName}] Active l'Aura de Défense!");
    }
    
    public bool CanExecute(PieceController owner)
    {
        return owner.CurrentMana >= manaCost && owner.IsAlive;
    }
}
```

### ⚔️ Exemple 2 : BerserkRageAbility

```csharp
using UnityEngine;

/// <summary>
/// BerserkRageAbility = Double les dégâts mais réduit la défense.
/// </summary>
[CreateAssetMenu(fileName = "Ability_BerserkRage", menuName = "Chess RPG/Ability/Berserk Rage")]
public class BerserkRageAbility : ScriptableObject, IAbility
{
    [SerializeField] private string abilityName = "Rage Berserker";
    [SerializeField] private int manaCost = 30;
    [SerializeField] private int attackMultiplier = 2;  // ×2 dégâts
    [SerializeField] private int defenseReduction = 3;  // -3 défense
    [SerializeField] private int durationTurns = 3;
    
    public string AbilityName => abilityName;
    public int ManaCost => manaCost;
    
    public void Execute(PieceController owner, PieceController targetPiece = null)
    {
        // Créer le buff de rage
        ModifierData rageBuff = ScriptableObject.CreateInstance<ModifierData>();
        // TODO: Implémenter multiplicateurs dans ModifierData
        
        owner.ApplyModifier(rageBuff, durationTurns);
        
        Debug.Log($"[{owner.PieceName}] Entre en rage berserker!");
    }
    
    public bool CanExecute(PieceController owner)
    {
        return owner.CurrentMana >= manaCost && owner.IsAlive;
    }
}
```

---

## 6. SYSTÈME DE MODIFICATEURS : BUFFS/DEBUFFS

### 📊 AbilityManager.cs : Orchestrateur de Compétences

```csharp
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// AbilityManager = Exécute les abilities et gère les cooldowns.
/// </summary>
public class AbilityManager
{
    private PieceController owner;
    private List<AbilityData> abilities;
    private Dictionary<int, int> cooldowns = new Dictionary<int, int>();  // [index] = turnsLeft
    private Dictionary<int, IAbility> implementations = new Dictionary<int, IAbility>();  // [index] = actual ability
    
    public AbilityManager(PieceController owner, List<AbilityData> abilities)
    {
        this.owner = owner;
        this.abilities = abilities;
        
        // Initialiser les implémentations (charger depuis Resources)
        for (int i = 0; i < abilities.Count; i++)
        {
            // TODO: Charger l'implémentation via nom ou référence directe
            cooldowns[i] = 0;
        }
    }
    
    public void ExecuteAbility(int abilityIndex, PieceController targetPiece = null)
    {
        if (abilityIndex < 0 || abilityIndex >= abilities.Count)
            return;
        
        AbilityData data = abilities[abilityIndex];
        
        // Vérifier cooldown
        if (cooldowns.ContainsKey(abilityIndex) && cooldowns[abilityIndex] > 0)
        {
            Debug.Log($"[{owner.PieceName}] {data.AbilityName} est en cooldown ({cooldowns[abilityIndex]} tours)");
            return;
        }
        
        // Vérifier mana
        if (owner.CurrentMana < data.ManaCost)
        {
            Debug.Log($"[{owner.PieceName}] Pas assez de mana! ({owner.CurrentMana}/{data.ManaCost})");
            return;
        }
        
        // Exécuter (via l'implémentation)
        if (implementations.TryGetValue(abilityIndex, out var ability))
        {
            ability.Execute(owner, targetPiece);
            cooldowns[abilityIndex] = data.CooldownTurns;
        }
    }
    
    public void UpdateCooldowns()
    {
        foreach (var key in cooldowns.Keys)
        {
            if (cooldowns[key] > 0)
                cooldowns[key]--;
        }
    }
}
```

---

## 7. SCALING À 200+ VARIANTES : PIPELINE DE CRÉATION

### 🚀 Workflow Optimisé (Zéro Recompilation)

#### **Étape 1 : Créer les Assets Réutilisables (1 fois)**

```
Assets/ScriptableObjects/Abilities/
├─ DefenseAura.asset        (1 asset, réutilisé 50 fois)
├─ BerserkRage.asset        (1 asset, réutilisé 40 fois)
├─ HolyShield.asset         (1 asset, réutilisé 30 fois)
├─ Fireball.asset           (1 asset, réutilisé 25 fois)
└─ [...50+ abilities au total]

Résultat : 50 abilities pour 200+ variantes!
```

#### **Étape 2 : Créer les 200+ PieceData Assets (Itérer 200x)**

Method A : **Manuellement via l'inspecteur** (2 min par variante)

```
1. Right-click → Create → Piece Data → Soldier_Basic
2. Dans l'inspecteur :
   - Name: "Soldat Basique"
   - Max Health: 100
   - Attack Power: 10
   - Defense: 5
   - Visual Prefab: Soldier_Base
   - Abilities: [DefenseAura]
3. Save

Répéter 199 fois...
```

Method B : **Script Editor pour Batch Creation** (1 min pour 200 variantes!)

```csharp
#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;
using System.Collections.Generic;

public class PieceDataBatchCreator
{
    [MenuItem("Tools/Create Batch Pieces (200 variants)")]
    public static void CreateBatchPieces()
    {
        // Template de base
        var baseStats = new PieceStats(100, 10, 5, 0);
        var visualPrefab = Resources.Load<GameObject>("Prefabs/Visuals/Soldier_Base");
        var defenseAura = Resources.Load<AbilityData>("Abilities/DefenseAura");
        
        // Boucle de création
        for (int i = 0; i < 200; i++)
        {
            var pieceData = ScriptableObject.CreateInstance<PieceData>();
            
            // Variation légère des stats
            int tier = i / 40;  // 5 tiers (0-4)
            int variant = i % 40;  // 40 variantes par tier
            
            pieceData.PieceName = $"Soldier_Tier{tier}_Variant{variant}";
            pieceData.BaseStats = new PieceStats(
                maxHealth: 100 + (tier * 50),
                attackPower: 10 + (tier * 5),
                defense: 5 + (tier * 3),
                mana: 20
            );
            
            // Sauvegarder l'asset
            string path = $"Assets/ScriptableObjects/Pieces/{pieceData.PieceName}.asset";
            AssetDatabase.CreateAsset(pieceData, path);
        }
        
        AssetDatabase.SaveAssets();
        Debug.Log("✓ 200 PieceData créés en batch!");
    }
}
#endif
```

### 📊 Composition : Combinaisons d'Abilities

Avec seulement **50 abilities**, on peut créer des milliers de combinaisons :

```
50 abilities × (50 choose 5) = 50 × 2,118,760 = 105,938,000 combinaisons!
```

**Exemple de composition :**

| Pièce | Abilities | Descripton |
|-------|-----------|-------------|
| Soldier_Basic | [DefenseAura] | Tank simple |
| Soldier_Elite | [DefenseAura, BerserkRage] | Tank agressif |
| Soldier_Berserker | [BerserkRage, Rampage, Charge] | Dégâts massifs |
| Mage_Fire | [Fireball, Heatwave] | DPS zone |
| Mage_Ice | [IceSpear, Freeze, Blizzard] | Control |
| Knight_Holy | [HolyShield, DivineBless, Smite] | Support tank |

---

## 8. OPTIMISATIONS & DÉPLOIEMENT PRODUCTION

### ⚡ Performance : Points Critiques

#### **1. Cache les GetComponent()**

```csharp
// ❌ LENT (50+ GetComponent par frame si 200 pièces)
private void Update()
{
    var renderer = GetComponent<Renderer>();  // AVOID!
    var animator = GetComponent<Animator>();
}

// ✅ RAPIDE (Cache au Start)
private Renderer renderer;
private Animator animator;

private void Start()
{
    renderer = GetComponent<Renderer>();
    animator = GetComponent<Animator>();
}

private void Update()
{
    // Utiliser les caches
}
```

#### **2. Utiliser Struct pour Stats (pas Classe)**

```csharp
// ❌ CLASSE = Allocation mémoire + GC
public class PieceStats
{
    public int Health;
    public int Attack;
}

// ✅ STRUCT = Stack allocation, pas de GC
public struct PieceStats
{
    public int Health;
    public int Attack;
}
```

#### **3. Object Pooling pour Recycler les Pièces**

```csharp
public class PiecePool : MonoBehaviour
{
    private Dictionary<string, Queue<PieceController>> pools = new();
    
    public PieceController GetPiece(PieceData data)
    {
        string key = data.PieceName;
        
        // Recycler si disponible
        if (pools.ContainsKey(key) && pools[key].Count > 0)
            return pools[key].Dequeue();
        
        // Créer nouveau sinon
        var go = new GameObject(key);
        return go.AddComponent<PieceController>();
    }
    
    public void ReturnPiece(string key, PieceController piece)
    {
        piece.gameObject.SetActive(false);
        
        if (!pools.ContainsKey(key))
            pools[key] = new Queue<PieceController>();
        
        pools[key].Enqueue(piece);
    }
}
```

#### **4. Profiling & Mesures**

```csharp
// Mesurer le temps d'Initialize
private void Start()
{
    var stopwatch = System.Diagnostics.Stopwatch.StartNew();
    
    for (int i = 0; i < 1000; i++)
    {
        var piece = Instantiate(piecePrefab);
        piece.Initialize(pieceData, 0, 0);
    }
    
    stopwatch.Stop();
    Debug.Log($"1000 pieces in {stopwatch.ElapsedMilliseconds}ms");
    // Target: < 100ms
}
```

### 📊 Benchmarks Attendus

| Métrique | Target | Acceptable |
|----------|--------|------------|
| **Initialize() 1 piece** | < 0.1 ms | < 0.5 ms |
| **TakeDamage() 1 piece** | < 0.05 ms | < 0.1 ms |
| **ExecuteAbility()** | < 1 ms | < 2 ms |
| **1000 pieces simultanées** | 60 FPS | 30 FPS |
| **Memory (500 pieces)** | < 300 MB | < 500 MB |

### 🚀 Déploiement Production

**Pre-Release Checklist :**
- [ ] Tous les scripts compilent sans erreur
- [ ] Aucune référence manquante (Missing Prefabs, Assets)
- [ ] Scene charge en < 5 secondes
- [ ] 100+ pièces sans frame drops
- [ ] GC spikes < 50ms
- [ ] Tests unitaires passent (80%+ coverage)
- [ ] Documentation mise à jour
- [ ] Assets packagés en AssetBundles

---

## CONCLUSION

### ✨ Résumé des Principes

1. **Data-Driven** : ScriptableObjects pour TOUTES les données
2. **Composition** : Utiliser List<Ability> au lieu d'héritage
3. **Découplage** : Events pour la communication entre systèmes
4. **Cache Agressif** : Jamais de GetComponent dans les loops
5. **Scaling** : 200+ variantes avec 1 seule classe et 50 abilities

### 🎯 Métriques de Succès

✅ **Scalabilité** : 200+ variantes, 0 recompilation
✅ **Performance** : 1000+ pièces à 60 FPS
✅ **Maintenance** : Ajouter une ability = 10 min (1 classe)
✅ **Équipes** : Designers itèrent indépendamment des programmeurs

---

**Bon développement! 🚀**
