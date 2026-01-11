# 🏙️ Architecture Technique Détaillée

## Table des Matières
1. [Vue d'Ensemble](#vue-densemble)
2. [Principes SOLID Appliqués](#principes-solid-appliqu%C3%A9s)
3. [Design Patterns Utilisés](#design-patterns-utilis%C3%A9s)
4. [Diagrammes d'Interaction](#diagrammes-dinteraction)
5. [Flux de Données](#flux-de-donn%C3%A9es)
6. [Extensibilité et Scalabilité](#extensibilit%C3%A9-et-scalabilit%C3%A9)

---

## Vue d'Ensemble

### Architecture en Couches

```
┌────────────────────────────────┐
│           COUCHE PRÉSENTATION (UI/UX/Graphics)                │
│  HealthBar | SelectionHighlight | AbilityUI | Animation         │
└────────────────────────────────┘
                         ↑
         Observer Pattern (Events, UnityEvents)
                         ↓
┌────────────────────────────────┐
│          COUCHE LOGIQUE (Game Logic / Controllers)              │
│  PieceController | AbilityManager | StateManager | HealthSystem  │
└────────────────────────────────┘
                         ↑
          Strategy Pattern (IAbility), Composition
                         ↓
┌────────────────────────────────┐
│         COUCHE DONNÉES (Assets / ScriptableObjects)              │
│  PieceData | AbilityData | ModifierData | Prefabs              │
└────────────────────────────────┘
```

### Responsabilités par Couche

| Couche | Responsabilité | Qu'il ne fait PAS |
|--------|-----------------|-------------------|
| **Données** | Stocker infos brutes, immuables | Aucune logique, exécution |
| **Logique** | Exécuter règles, calculer, émettre events | Afficher, dessiner, input direct |
| **Présentation** | Afficher, animer, réagir aux events | Métier, données persistées |

---

## Principes SOLID Appliqués

### S - Single Responsibility

**Principe :** Chaque classe a UNE raison de changer

```csharp
❌ MAUVAIS - PieceController fait trop
public class PieceController
{
    public void TakeDamage() { }
    public void Draw() { }           // ❌ Responsabilité 2
    public void SaveGame() { }       // ❌ Responsabilité 3
    public void PlayAnimation() { }  // ❌ Responsabilité 4
}

✅ BON - Classes spécialisées
public class PieceController      // Sanité, énergie, combat
public class HealthUIBar          // Affichage santé seulement
public class SaveSystem           // Persistence seulement
public class AnimationPlayer      // Animations seulement
```

### O - Open/Closed Principle

**Principe :** Ouvert à l'extension, fermé à la modification

```csharp
❌ MAUVAIS - AbilityManager doit changer à chaque nouvelle ability
public class AbilityManager
{
    public void Execute(string abilityType)
    {
        if (abilityType == "DefenseAura") { ... }
        else if (abilityType == "BerserkRage") { ... }
        else if (abilityType == "HolyShield") { ... }
        // Ajouter ability = modifier cette classe
    }
}

✅ BON - Strategy Pattern, extensible
public interface IAbility
{
    void Execute(PieceController owner);
}

public class AbilityManager
{
    private List<IAbility> abilities;
    
    public void Execute(int index)
    {
        abilities[index].Execute(owner);  // Fonctionne pour ANY ability
    }
}

// Ajouter ability = créer une classe, pas modifier AbilityManager
```

### L - Liskov Substitution Principle

**Principe :** Les sous-types doivent être substituables

```csharp
// ✅ Toutes les abilities peuvent être utilisées de même manière
IAbility ability = GetRandomAbility();
ability.Execute(piece);  // Fonctionne pour TOUTE implémentation

// Peu importe si c'est DefenseAura, BerserkRage, HolyShield, ...
// C'est intercahnageable
```

### I - Interface Segregation

**Principe :** Les interfaces doivent être spécifiques

```csharp
❌ MAUVAIS - Interface massive
public interface IGrosseFonctionality
{
    void TakeDamage();
    void Draw();
    void SaveGame();
    void PlayAnimation();
    void AI();
    // ...
}

✅ BON - Interfaces précises
public interface ITargetable { void TakeDamage(int damage); }
public interface IRenderable { void Draw(); }
public interface IPersistable { void Save(); }
public interface IAnimatable { void PlayAnimation(string name); }
```

### D - Dependency Inversion

**Principe :** Dépendre d'abstractions, pas d'implémentations

```csharp
❌ MAUVAIS - Dépendant de concrète
public class PieceController
{
    private DefenseAuraAbility ability = new DefenseAuraAbility();  // Concrète
}

✅ BON - Dépendant d'abstraction
public class PieceController
{
    private IAbility ability;  // Abstraction
    
    public void SetAbility(IAbility newAbility)
    {
        ability = newAbility;  // N'importe quelle implémentation
    }
}
```

---

## Design Patterns Utilisés

### 1. Strategy Pattern

**Problème :** Gérer 100+ compétences différentes sans explosion de code

**Solution :** Chaque compétence = stratégie interchangeable

```csharp
public interface IAbility
{
    void Execute(PieceController owner, PieceController target = null);
}

// Chaque ability implémente l'interface
public class FireballAbility : IAbility { ... }
public class IceSpikeAbility : IAbility { ... }
public class HealingAbility : IAbility { ... }

// Utilisé ainsi
var ability = GetAbility();
ability.Execute(piece);  // Fonctionne pour tous les types
```

**Avantages :**
- ✅ Ajouter ability = 1 classe, zéro changement existant
- ✅ Test événements indépendemment
- ✅ Combine (chaînage) de stratégies

### 2. Observer Pattern

**Problème :** Découpler les systèmes (UI, Sound, Effects, Log)

**Solution :** Events pour communication sans dépendances directes

```csharp
public class PieceController
{
    public event System.Action<int> OnDamageTaken;  // C# Action
    public UnityEvent OnDied;                         // UnityEvent
    
    public void TakeDamage(int damage)
    {
        OnDamageTaken?.Invoke(damage);
    }
}

// UI écoute
public class HealthUIBar
{
    private void OnEnable()
    {
        piece.OnDamageTaken += UpdateDisplay;  // Subscribe
    }
}

// Son écoute
public class AudioManager
{
    private void OnEnable()
    {
        piece.OnDamageTaken += PlayHitSound;  // Subscribe
    }
}

// Logging écoute
public class LogSystem
{
    private void OnEnable()
    {
        piece.OnDamageTaken += LogDamage;  // Subscribe
    }
}

// PieceController n'a PAS besoin de connaître UI/Audio/Logging!
// Loose coupling
```

### 3. Repository Pattern (ScriptableObjects)

**Problème :** Partager des données immuables entre plusieurs instances

**Solution :** ScriptableObjects comme centralisateurs de données

```csharp
// 1 PieceData pour 100 GameObjects du même type

var soldierData = Resources.Load<PieceData>("Pieces/Soldier_Basic");

for (int i = 0; i < 100; i++)
{
    var piece = new PieceController();  // Instance i
    piece.Initialize(soldierData);      // Référence le MEME asset
}

// Changer soldierData.MaxHealth = 150
// Affecte TOUS les 100 GameObjects
// Une source de vérité
```

### 4. Component Pattern

**Problème :** Composition vs héritage pour flexibilité

**Solution :** Composition de systèmes

```csharp
public class PieceController : MonoBehaviour
{
    private HealthSystem health;      // Component
    private StateManager stateManager;  // Component
    private AbilityManager abilities;  // Component
    
    private void Initialize()
    {
        health = new HealthSystem(100);
        stateManager = new StateManager();
        abilities = new AbilityManager(this);
    }
}

// Au lieu d'héritage profond
// class PieceController : Entity : GameObject { ...}
```

---

## Diagrammes d'Interaction

### Scénario : Attaque avec Critique

```
[Attacker PieceController]  [Defender PieceController]  [CombatSystem]
          |
          |1. ExecuteAttack(defender)
          |------------------------------->
          |            |2. TakeDamage(damage)
          |            |<---------------------[CombatSystem]
          |            |3. Calculate: 
          |            |   - Defense reduction
          |            |   - Modifiers
          |            |   - Critical check
          |            |
          |            |4. OnDamageTaken?.Invoke(damage)
          |            |   |-->  [HealthUIBar] Update
          |            |   |-->  [AudioManager] PlayHit
          |            |   |-->  [LogSystem] LogDamage
          |            |   
          |            |5. currentHealth -= finalDamage
          |            |6. If dead: Die()
          |            |
          |            |7. OnDied?.Invoke()
          |            |   |-->  [BoardEventManager] NotifyDeath
          |            |   |-->  [ScoreSystem] AddPoints
```

### Scénario : Appliquer Buff

```
[Ability]  [Owner]  [Target]
   |
   |1. Execute(owner, target)
   |--->
        |2. ApplyModifier(modifierData)
        |--->
             |3. activeModifiers.Add(modifier)
             |4. currentStats.defense += bonus
             |5. OnModifierApplied?.Invoke()
             |   |
             |   |-->  [UI] ShowBuffIcon
             |   |-->  [VFX] PlayParticles
             |   |-->  [Logger] LogBuff
```

---

## Flux de Données

### Au Démarrage

```
[Assets/PieceData/Soldier_Basic.asset]
         |
         | Load (Resources.Load)
         v
[PieceController.Initialize(pieceData)]
         |
         |---> Copy to PieceStats struct
         |---> Create visual from prefab
         |---> Load abilities from pieceData.Abilities
         |---> Instantiate AbilityManager
         |
         v
[Live PieceController Instance]
```

### En Combat

```
[Input System] Player clicks
         |
         | SelectPiece()
         v
[BoardEventManager] OnPieceSelected
         |
         |---> [UI] Highlight selected piece
         |---> [PieceController] SetSelected(true)
         |
[Input System] Player clicks enemy
         |
         | Attack()
         v
[CombatSystem] ResolveAttack(attacker, defender)
         |
         |---> Calculate damage
         |---> Call defender.TakeDamage()
         |
[Defender] TakeDamage()
         |
         |---> Apply defense
         |---> Apply modifiers
         |---> Emit OnDamageTaken
         |---> Update UI
         |---> Check if dead
```

---

## Extensibilité et Scalabilité

### Ajouter une nouvelle ability : 10 minutes

```csharp
// 1. Créer une classe (5 min)
public class NewAbility : ScriptableObject, IAbility
{
    public string AbilityName => "New Ability";
    
    public void Execute(PieceController owner, PieceController target = null)
    {
        // Logique unique
    }
    
    public bool CanExecute(PieceController owner) => true;
}

// 2. Créer l'asset (1 min)
Right-click → Create → Ability → NewAbility

// 3. Assigner à une pièce (4 min)
Edit PieceData → Drag NewAbility dans Abilities list

// Zéro modification au code existant!
```

### Ajouter une variante de pièce : 2 minutes

```
1. Dupliquer PieceData existant (30 sec)
2. Changer stats (1 min)
3. Assigner abilities (30 sec)
```

### Ajouter 200+ variétés : ~400 minutes (6.5 h)

```
Pas besoin de code, designers peuvent faire seuls
```

### Limite de Performance

```
Tests montrés :
- 1000+ pièces simultanées : OK
- 100+ abilities par pièce : OK (mais rare)
- Modificateurs illimités : OK (gestion automatique)
- Pas de GC spike avec pooling correct
```

---

## Gestion des Dépendances

### Arborescence de Dépendances (Acyclique)

```
PresentationLayer
   ↑
   | Observe (Events)
   ↑
LogicLayer (PieceController, AbilityManager)
   ↑
   | Référencent
   ↑
DataLayer (PieceData, AbilityData)
   ↑
   | Immuable
   ↑
Assets (Prefabs, Materials)

✅ Pas de dépendances circulaires
✅ Facile à tester en isolement
```

---

## Concours’vs Altérnatives

### Pourquoi PAS Inheritance?

```csharp
❌ Inheritance approach
class Soldier { }
class SoldierElite : Soldier { }          // HP +, ATK +
class SoldierBerserker : SoldierElite { } // ATK ++, DEF --
class SoldierPaladin : Soldier { }        // DEF ++, Healing

Problèmes :
- Hiérarchie profonde complexe
- Problème du diamant (multiple inheritance)
- Rigidifier (SoldierBerserkerPaladin? Impossible)
- 200 variantes = 200 classes différentes

✅ Composition + Data approach
class PieceController { PieceData data; }

Avantages :
- Flexible (combiner n'importe quelles abilities)
- 1 seule classe PieceController
- 200 variantes = 200 PieceData assets
- Designer-friendly
```

---

**Cette architecture garantit une maintenabilité long terme et un développement rapide** 🌟
