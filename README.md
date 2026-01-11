# 🎲 Architecture Modulaire Data-Driven pour Pièces d'Echecs RPG

**Guide complet pour gérer 200+ variétés de pièces d'echecs RPG sans modifier le code source**

## 🎉 Vue d'ensemble

Ce projet démontre comment créer un système de pièces d'echecs scalable et modulaire en Unity utilisant :

- **ScriptableObjects** pour les données (PieceData, AbilityData, ModifierData)
- **Strategy Pattern** pour les compétences interchangeables (IAbility)
- **Component Architecture** pour séparer données/logique/présentation
- **Observer Pattern** pour les événements découplés

## ✅ Objectifs Architecturaux

✅ **Ajouter 200 variétés** = créer 200 assets ScriptableObject, **zéro code compilé**
✅ **Changer stats** = modifier l'asset, pas le code
✅ **Une seule classe** PieceController pour TOUTES les piéces
✅ **Designers itèrent** indépendamment des programmeurs
✅ **Performance**: cache agressif, pas de GetComponent dans Update

## 📄 Structure du Projet

```
chess-rpg-architecture-guide/
├─ Scripts/
│  ├─ Core/
│  │  ├─ PieceData.cs         ❯ ScriptableObject principal
│  │  ├─ PieceController.cs   ❯ MonoBehaviour pour chaque pièce
│  │  ├─ AbilityManager.cs    ❯ Gére les compétences
│  │  ├─ AbilityData.cs       ❯ Conteneur de compétence
│  │  └─ ModifierData.cs      ❯ Buffs/Debuffs
│  ├─ Abilities/
│  │  ├─ IAbility.cs          ❯ Interface Strategy
│  │  ├─ DefenseAuraAbility.cs
│  │  ├─ BerserkRageAbility.cs
│  │  └─ HolyShieldAbility.cs
│  ├─ Systems/
│  │  ├─ HealthSystem.cs
│  │  ├─ PieceStateManager.cs
│  │  ├─ BoardEventManager.cs
│  │  └─ GameManager.cs
│  └─ AI/
│     ├─ IAIStrategy.cs
│     ├─ AggressiveAI.cs
│     └─ DefensiveAI.cs
├─ Documentation/
│  └─ ARCHITECTURE.md
└─ README.md
```

## 📚 Concepts Clés

### 1. **PieceData : Le Conteneur de Données**

```csharp
// Tout ce qui définit une pièce est stocké ici
var pieceDat = ScriptableObject.CreateInstance<PieceData>();
pieceData.MaxHealth = 100;
pieceData.AttackPower = 10;
pieceData.Defense = 5;
pieceData.Abilities = [defenseAura, berserkRage];
```

**Avantages :**
- ✅ Réutilisable (plusieurs GameObject référencent le même PieceData)
- ✅ Aucune recompilation pour créer de nouvelles variantes
- ✅ Designers peuvent itérer dans l'inspecteur
- ✅ Memory-efficient : partage des données

### 2. **PieceController : La Logique d'Exécution**

```csharp
// Instance locale d'une pièce = bindé à PieceData
var piece = gameObject.AddComponent<PieceController>();
piece.Initialize(pieceDatas[0], gridX: 3, gridY: 4);

// Prendre des dégâts
piece.TakeDamage(25);

// Exécuter une compétence
piece.ExecuteAbility(0);  // Index 0 = première ability
```

**Architecture :**
- 1 PieceController par pièce (instance)
- Référence 1 PieceData (template)
- Gére l'état local (santé, énergie, buffs)
- Émet des événements pour communication découplée

### 3. **IAbility : Strategy Pattern pour Compétences**

```csharp
public interface IAbility
{
    string AbilityName { get; }
    void Execute(PieceController owner, PieceController target = null);
    bool CanExecute(PieceController owner);
}

// Chaque compétence = sa propre classe
public class DefenseAuraAbility : ScriptableObject, IAbility { ... }
public class BerserkRageAbility : ScriptableObject, IAbility { ... }
public class HolyShieldAbility : ScriptableObject, IAbility { ... }
```

**Avançantages du Pattern:**
- ✅ Open/Closed Principle : ouvert à extension, fermé à modification
- ✅ 100 abilities = 100 classes, zéro changement à PieceController
- ✅ Téstés indépendamment
- ✅ Réutilisables entre plusieurs pièces

### 4. **Compositeurs vs Héritage**

| Approche | Code | Problèmes |
|----------|------|----------|
| **Inheritance** | class SoldatBerserker : Soldat | Problème du diamant, hiérarchies complexes |
| **Composition** (notre approche) | Soldat contient List<IAbility> | Flexible, scalable, facile à étendre |

## 🛠️ Workflow de Création (Zéro Code)

### Étape 1 : Créer le visuel (1 fois)
```
Assets → Create → 3D Object → Cube
Renommer : Soldier_Base.prefab
Ajouter : MeshRenderer, Material, Animator, Colliders
```

### Étape 2 : Créer les abilities (réutilisables)
```
Right-click → Create → Ability → Defense Aura
Right-click → Create → Ability → Berserk Rage
```

### Étape 3 : Créer 200 PieceData (itérer 200x)
```
Right-click → Create → Piece Data → Soldier_Basic
Inspector :
  - Name: "Soldat Basique"
  - Max Health: 100
  - Attack Power: 10
  - Defense: 5
  - Visual Prefab: Soldier_Base
  - Abilities: [DefenseAura]

(Dupliquer pour Soldier_Elite, Soldier_Berserker, etc.)
```

**Temps par variété : ~2 minutes. Code compilé : 0 fois.** ✨

## 📂 Exemple d'Utilisation

### Générer un plateau avec des pièces

```csharp
public class BoardGenerator : MonoBehaviour
{
    [SerializeField] private Tile[,] tiles = new Tile[8, 8];
    [SerializeField] private List<PieceData> pieceDatas;  // 200 variétés

    public void GenerateBoard()
    {
        for (int x = 0; x < 8; x++)
        {
            for (int y = 0; y < 8; y++)
            {
                Tile tile = tiles[x, y];
                PieceData pieceData = pieceDatas[Random.Range(0, pieceDatas.Count)];

                // Créer le GameObject
                GameObject pieceGO = new GameObject($"Piece_{x}_{y}");
                pieceGO.transform.position = tile.transform.position;

                // Ajouter le contrôleur
                PieceController controller = pieceGO.AddComponent<PieceController>();
                controller.Initialize(pieceData, x, y, tile);

                // Optionnel : s'enregistrer aux événements
                controller.OnDied.AddListener(() =>
                {
                    BoardEventManager.Instance.NotifyPieceDied(controller);
                });

                tile.SetPiece(controller);
            }
        }
    }
}
```

### Appliquer des buffs/débuffs

```csharp
PieceController piece = ...;
ModifierData buff = Resources.Load<ModifierData>("Modifiers/AttackBoost");

// Appliquer : +20 attaque pendant 3 tours
piece.ApplyModifier(buff, durationTurns: 3);

// Chaque fin de tour
piece.UpdateModifiers();  // Décrémente les durations
```

### Exécuter des compétences

```csharp
PieceController attacker = ...;
PieceController defender = ...;

// Exécuter l'ability 0 (DefenseAura)
attacker.ExecuteAbility(0);

// Exécuter l'ability 1 sur une cible (HolyShield)
attacker.ExecuteAbility(1, target: defender);
```

### Gérer le combat

```csharp
public class CombatSystem : MonoBehaviour
{
    public void ResolveAttack(PieceController attacker, PieceController defender)
    {
        int baseDamage = attacker.GetAttackPower();
        
        // Appliquer chance de critique
        if (Random.Range(0, 100) < attacker.GetCriticalChance())
        {
            baseDamage = (int)(baseDamage * attacker.GetCriticalMultiplier());
        }

        // Inflige les dégâts (defense calculée internalement)
        defender.TakeDamage(baseDamage, attacker);
    }
}
```

## ⚡️ Optimisations Performance

### Cache agressif
```csharp
private void Start()
{
    // ✅ FAIRE : cache une seule fois
    visualRenderer = GetComponent<Renderer>();
    animator = GetComponent<Animator>();
}

private void Update()
{
    // ❌ JAMAIS : GetComponent chaque frame
    // var renderer = GetComponent<Renderer>();
}
```

### Utiliser C# Action au lieu d'UnityEvent pour perf
```csharp
// ❌ Lent (UnityEvent)
public UnityEvent OnDamaged;

// ✅ Rapide (C# Action)
public event System.Action<int> OnDamaged;  // 20% plus rapide
```

### Object Pooling pour recycler les pièces
```csharp
public class PiecePool : MonoBehaviour
{
    public PieceController GetPiece(string pieceID)
    {
        if (pools[pieceID].Count > 0)
            return pools[pieceID].Dequeue();
        
        return CreateNewPiece(pieceID);
    }

    public void ReturnPiece(string pieceID, PieceController piece)
    {
        piece.gameObject.SetActive(false);
        pools[pieceID].Enqueue(piece);
    }
}
```

## 🧐 Système d'IA

### Stratégies interchangeables

```csharp
public interface IAIStrategy
{
    AIAction DecideAction(PieceController self, List<PieceController> enemies, BoardState board);
}

// Chaque type d'IA = sa propre classe
public class AggressiveAI : ScriptableObject, IAIStrategy { ... }
public class DefensiveAI : ScriptableObject, IAIStrategy { ... }
public class SmartAI : ScriptableObject, IAIStrategy { ... }
```

### Utilisation dans GameManager

```csharp
[SerializeField] private IAIStrategy aiStrategy;

public void ExecuteAITurn(PieceController aiPiece)
{
    AIAction action = aiStrategy.DecideAction(aiPiece, enemies, board);
    
    switch (action.type)
    {
        case AIAction.ActionType.Attack:
            CombatSystem.ResolveAttack(aiPiece, action.targetPiece);
            break;
        case AIAction.ActionType.Move:
            MovePiece(aiPiece, action.targetPosition);
            break;
    }
}
```

## 🔧 Bonnes Pratiques

### ✅ À FAIRE
- Utiliser ScriptableObjects pour TOUTES les données
- Cache les GetComponent au Start()
- Utiliser des interfaces pour abstractions (IAbility, IAIStrategy)
- Émettre des événements pour découplage
- Tester chaque système indépendamment

### ❌ À ÉVITER
- Logique complex dans le constructor/Initialize
- GetComponent dans Update/LateUpdate
- Find()/FindWithTag chaque frame
- Allocations mémoire inutiles (List<> créés chaque frame)
- HierArchie de classes profonde (Soldier > EliteSoldier > BerserkSoldier)

## 🚧 Troubleshooting

### PieceData null après Initialize
**Solution** : Vérifier que PieceData est assignée avant d'appeler Initialize()

### Abilities ne s'exécutent pas
**Solution** : Vérifier que AbilityImplementation implémente IAbility

### Performance baisse avec 200+ pièces
**Solution** : 
- Utiliser Object Pooling
- Cacher les GetComponent
- Utiliser C# Action au lieu d'UnityEvent

## 📄 Documentation Supplémentaire

Voir [ARCHITECTURE.md](Documentation/ARCHITECTURE.md) pour :
- Diagrammes détaillés
- Patterns de design utilisés
- Exemples complets de code
- Résolution avancée de problèmes

## 👋 Contribution

Contributions bienvenues! Pour contribuer :
1. Fork le repo
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📜 Licence

Ce projet est sous licence MIT. Voir [LICENSE](LICENSE) pour détails.

---

**Créé pour les développeurs Unity cherchant une architecture scalable et maintenable pour systèmes complexes de jeux.** ✨
