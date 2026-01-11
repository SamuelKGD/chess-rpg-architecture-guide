# 🚶 Système de Mouvement - Guide de Démarrage Rapide
## 2 Actions, Grille Hexagone, Sliders/Leapers, ZOC & Piéges

**Namespace:** `OctagonalChess.Movement`

**Lire d'abord:** [MOVEMENT_SYSTEM.md](./Documentation/MOVEMENT_SYSTEM.md) (base) + [MOVEMENT_ADVANCED.md](./Documentation/MOVEMENT_ADVANCED.md) (avancé)

---

## 🌟 Vue d'Ensemble

### 📊 Flux Complet

```
┌─────────────────────────────────────────────┐
│    TOUR: 2 ACTIONS PAR PIÈCE                       │
├─────────────────────────────────────────────┤
│                                                     │
│  🎉 Allocation 2 AP                                 │
│     └─ TurnState.StartTurn(piece)                    │
│                                                     │
│  👂 Mouvement 1 (coûte 1 AP)                         │
│     └─ MovementEngine.GetValidMoves()           │
│     └─ └─ Slider? Leaper? Pawn?                  │
│     └─ Vérifier ZOC                              │
│     └─ Vérifier piéges                            │
│     └─ TryConsumeAP(1, ActionType.Move)         │
│     └─ BoardManager.MovePiece()                 │
│                                                     │
│  ⚡ Option 1: Attaquer (coûte 1 AP = TOUR FINI)    │
│     └─ CombatSystem.ResolveCombat()           │
│     └─ AP: 1 → 0 (END)                          │
│                                                     │
│  ⚡ Option 2: Mouvement 2 (coûte 1 AP = TOUR FINI)  │
│     └─ MovementEngine.GetValidMoves() again    │
│     └─ TryConsumeAP(1, ActionType.Move)         │
│     └─ BoardManager.MovePiece()                 │
│     └─ 🔥 DOUBLE MOUVEMENT BONUS!                 │
│        - Cavalier: +1 portée saut                 │
│        - Soldat: +1 DEF                           │
│        - Tour: +2 portée                          │
│     └─ AP: 1 → 0 (END)                          │
│                                                     │
│  ⚡ Option 3: Terminer tour                            │
│     └─ Gaspiller 1 AP (mauvaise stratégie!)     │
│                                                     │
└─────────────────────────────────────────────┘
```

### ✨ Caractéristiques Clés

✅ **Système 2 AP** - Chaque pièce a 2 points d'action par tour  
✅ **Grille Hexagone** - 6 voisins par case, coordonnées axiales  
✅ **Sliders** - Reine (6 dir), Tour (4 cardinales), Fou (4 diagonales)  
✅ **Leapers** - Cavalier saute par-dessus obstacles (ignore ZOC)  
✅ **Pawns** - Soldats avancée only, orientation forward  
✅ **Double Mouvement** - 2 AP pour bouger = bonus stratégique  
✅ **Zone de Contrôle** - Quitter ZOC coûte plus cher (sauf Cavalier)  
✅ **Piéges & Terrain** - Cases spéciales infligent effet  
✅ **Pathfinding A*** - Chemin optimal pour IA  
✅ **Simulation Pure** - Les calculs ne modifient pas l'état  
✅ **Cache Performance** - Optimisé pour mille+ mouvements  

---

## ⚡ Les 6 Types de Mouvements

### 1. 👑 Reine (Slider - 6 directions)

```
Portée: Jusqu'à bord plateau (6 directions hex)
Règle: Ligne droite jusqu'au blocage
Capture: Ennemi sur chemin
Ex: Reine en (0,0) peut atteindre (2,0) si chemin libre

      \ | /
    ---R---
      / | \
```

### 2. 🗿 Tour (Slider - 4 cardinales)

```
Portée: Jusqu'à bord plateau (4 directions)
Règle: Ligne cardinale jusqu'au blocage
Capture: Ennemi sur chemin
Ex: Tour en (0,0) peut atteindre (3,0) ou (0,3)

      | 
    --T--
      |
```

### 3. 🗺 Fou (Slider - 4 diagonales)

```
Portée: Jusqu'à bord plateau (4 diagonales)
Règle: Diagonale jusqu'au blocage
Capture: Ennemi sur chemin
Ex: Fou en (0,0) peut atteindre (2,2)

    \ | /
     \|/
      B
     /|\
    / | \
```

### 4. 🐴 Cavalier (Leaper - 8 sauts)

```
Portée: 8 sauts en L adapté hex
Règle: Saute par-dessus pieces
Ignore: ZOC
Ex: Cavalier (0,0) peut atteindre 8 positions
Double Mouvement Bonus: +1 portée saut
```

### 5. 🐙 Soldat/Pion (Pawn - Orientation)

```
Portée: 1 case forward (normal) ou 2 cases (premier mouvement)
Règle: Avancée droite uniquement
Capture: Diagonale forward (ennemi)
Double Mouvement Bonus: +1 DEF temporaire

      ^
      P (Mouvement forward)
     /|\
```

### 6. 👑 Roi (1 case)

```
Portée: 1 hexagone dans toute direction
Règle: Roi peut pas avoir ZOC? (régles variant)
Ex: Roi en (0,0) peut atteindre 6 voisins

      /\
     /  \
    < K >
     \  /
      \/
```

---

## 💳 Système AP (Action Points)

### Allocation & Consommation

```csharp
// Début de tour
TurnState ts = new TurnState();
ts.StartTurn(piece);
// état: CurrentAP = 2, APUsedThisTurn = 0

// Action 1: Mouvement
bool success = ts.TryConsumeAP(1, ActionType.Move);
// état: CurrentAP = 1, APUsedThisTurn = 1

// Action 2: Attaque OU Mouvement
if (joueur_attaque)
    ts.TryConsumeAP(1, ActionType.Attack);
    // état: CurrentAP = 0, TOUR FINI
else if (joueur_bouge)
    ts.TryConsumeAP(1, ActionType.Move);
    // état: CurrentAP = 0, TOUR FINI
    // Vérifier: IsDoubleMovePerformed() = true
    // DOUBLE MOUVEMENT BONUS appliqué!
```

### Double Mouvement Bonus

```csharp
// Quand IsDoubleMovePerformed() = true:
// (2 Move + 0 Attack)

switch (piece.Category)
{
    case Cavalier:
        // +1 case de portée saut
        leaperMovement.ExtendRange(+1);
        break;
    case Soldat:
        // +1 DEF temporaire
        piece.ApplyBuff(Defense, +1, duration: 1);
        break;
    case Tour:
        // +2 portée
        sliderMovement.ExtendRange(+2);
        break;
}
```

---

## 🗑 Setup en 5 Étapes

### Étape 1: Ajouter les Managers à la Scène

```
Hiérarchie:
└── GameManager (GameObject)
    ├── BoardManager (Script)
    ├── GridManager (Script)
    ├── MovementEngine (Script) ← AJOUTER
    ├── TurnManager (Script) ← AJOUTER
    ├── TerrainManager (Script) ← AJOUTER
    └── ZOCManager (Script) ← AJOUTER
```

```csharp
// Dans GameManager.Awake()
private void Awake()
{
    movementEngine = gameObject.AddComponent<MovementEngine>();
    turnManager = gameObject.AddComponent<TurnManager>();
    terrainManager = gameObject.AddComponent<TerrainManager>();
    zocManager = gameObject.AddComponent<ZOCManager>();
}
```

### Étape 2: Initialiser Grille Hexagone

```csharp
// HexCoordinate = structure légère (pas MonoBehaviour)

// Création simple
var hex = new HexCoordinate(q: 2, r: 3);

// Voisins
var neighbors = hex.GetAllNeighbors();  // 6 cases

// Distance
int dist = hex.DistanceTo(other);  // Nombre de sauts

// Rayon (toutes les cases à distance N)
var ring = hex.GetRing(radius: 2);

// Disque (toutes les cases jusqu'à distance N)
var disk = hex.GetDisk(radius: 2);
```

### Étape 3: Obtenir les Mouvements Valides

```csharp
// Début de tour
TurnState ts = new TurnState();
ts.StartTurn(piece);

// Calculer mouvements
var validMoves = movementEngine.GetValidMoves(
    piece: piece,
    actionPointsAvailable: ts.CurrentAP  // 2 ou 1
);

// Afficher sur UI
uiManager.HighlightValidMoves(validMoves);

// Le calcul vérifie:
// ✓ Type de mouvement (Slider/Leaper/Pawn/King)
// ✓ Obstacles
// ✓ ZOC (si activé)
// ✓ Piéges détectés
// ✓ Limites plateau
```

### Étape 4: Exécuter le Mouvement

```csharp
// Joueur clique sur case valide
public void OnMovementClick(HexCoordinate target)
{
    // Vérifier validité
    var validMoves = movementEngine.GetValidMoves(selectedPiece);
    if (!validMoves.Contains(target))
        return;  // Invalide
    
    // Dépenser 1 AP
    if (!turnState.TryConsumeAP(1, ActionType.Move))
        return;  // Pas assez d'AP
    
    // Déplacer
    boardManager.MovePiece(selectedPiece, target);
    
    // Vérifier piéges
    terrainManager.TriggerTrap(target, selectedPiece);
    
    // Vérifier si double mouvement
    if (turnState.IsDoubleMovePerformed())
    {
        // BONUS appliqué automatiquement!
    }
    
    // Tour terminé?
    if (turnState.IsTurnFinished())
        EndCurrentTurn();
    else
        ShowValidMovesAgain(selectedPiece);
}
```

### Étape 5: Gérer Fin de Tour

```csharp
public void EndTurn()
{
    Debug.Log($"Tour de {currentPiece.PieceName} terminé");
    
    // Nettoyer cache
    movementEngine.ClearCache();
    
    // Passer au joueur suivant
    NextPlayerTurn();
}
```

---

## 📚 Architecture Fichiers

```
Documentation/
├── MOVEMENT_SYSTEM.md (Partie 1: Base)
│   ├─ Vue d'ensemble flux
│   ├─ TurnState.cs (AP allocation)
│   ├─ HexCoordinate.cs (Géométrie hex)
│   ├─ MovementEngine.cs (Base moteur)
│   └─ Détermination type mouvement
│
├── MOVEMENT_ADVANCED.md (Partie 2: Détails)
│   ├─ GetSliderMoves (Reine, Tour, Fou)
│   ├─ GetLeaperMoves (Cavalier)
│   ├─ GetPawnMoves (Soldat/Orientation)
│   ├─ GetKingMoves (Roi)
│   ├─ ZOCManager.cs (Zone contrôle)
│   ├─ TerrainManager.cs (Piéges/terrain)
│   ├─ PathfindingEngine.cs (A* pour IA)
│   └─ TurnManager.cs (Orchéstration)
│
└── README_MOVEMENT_SYSTEM.md (Ce fichier)
    └─ Guide d'implémentation rapide
```

---

## 📋 Checklist Implémentation

### Phase 1: Infrastructure Hex

- [ ] HexCoordinate.cs créé avec:
  - [ ] Constructeur (q, r)
  - [ ] GetNeighbor(direction) pour 6 voisins
  - [ ] DistanceTo(other) calcul distance
  - [ ] GetRing(radius) cercle
  - [ ] GetDisk(radius) disque
  - [ ] LineTo(target) ligne entre 2 hex
  - [ ] Override Equals/GetHashCode

- [ ] GridManager.cs updateé avec:
  - [ ] HexToWorldPosition(HexCoordinate)
  - [ ] WorldToHexPosition(Vector3)
  - [ ] IsInBounds(HexCoordinate)

### Phase 2: Système AP

- [ ] TurnState.cs créé avec:
  - [ ] StartTurn(piece) alloue 2 AP
  - [ ] TryConsumeAP(amount, type) retourne bool
  - [ ] IsDoubleMovePerformed() détecté
  - [ ] ApplyDoubleMoveBonus() appliqué
  - [ ] Events OnAPChanged, OnDoubleMoveBonus

- [ ] TurnManager.cs créé avec:
  - [ ] StartTurn() initialise TurnState
  - [ ] SelectPiece() affiche mouvements
  - [ ] PlayerMove() exécute et vérifie
  - [ ] EndTurn() nettoie

### Phase 3: Moteur Mouvement

- [ ] MovementEngine.cs créé avec:
  - [ ] GetValidMoves(piece, AP) retourne liste
  - [ ] DetermineMoveType(piece) retourne type
  - [ ] ApplyConstraints(piece, moves) filtre
  - [ ] ClearCache() performance

- [ ] GetSliderMoves(piece, AP) implémenté:
  - [ ] Boucle pour chaque direction
  - [ ] Avancé case par case
  - [ ] Détection obstacles
  - [ ] Capture ennemis

- [ ] GetLeaperMoves(piece, AP) implémenté:
  - [ ] 8 offsets de saut
  - [ ] Vérification limites
  - [ ] Ignore obstacles

- [ ] GetPawnMoves(piece, AP) implémenté:
  - [ ] Direction forward déterminée
  - [ ] Avancée 1 case
  - [ ] Saut initial 2 cases
  - [ ] Captures diagonales

### Phase 4: Contraintes Terrain

- [ ] ZOCManager.cs créé avec:
  - [ ] CanLeaveZOC(piece, target) retourne bool
  - [ ] GetZOCCells(pos) retourne liste
  - [ ] Cavalier ignore ZOC

- [ ] TerrainManager.cs créé avec:
  - [ ] GetTerrainAt(pos) retourne type
  - [ ] HasTrap(pos) détecté
  - [ ] TriggerTrap(pos, piece) appliqué
  - [ ] Types: Grass, Stone, Ice, Lava, Forest
  - [ ] Piéges: Spike, Immobilize, Slow

### Phase 5: Pathfinding & Visuel

- [ ] PathfindingEngine.cs créé avec:
  - [ ] FindPath(start, goal, piece) utilise A*
  - [ ] Heuristic(a, b) retourne distance
  - [ ] ReconstructPath() rebuild chemin

- [ ] UIManager.cs mis à jour:
  - [ ] HighlightValidMoves(list) affiche
  - [ ] AnimateMovement(path) animation fluide
  - [ ] ShowAPCounter(current) affiche AP restants

### Phase 6: Intégration Complete

- [ ] GameManager.cs:
  - [ ] References tous les managers
  - [ ] Ordre d'initialisation correct
  - [ ] GameFlow géré proprement

- [ ] Tests unitaires:
  - [ ] HexCoordinate calculs
  - [ ] TurnState AP allocation
  - [ ] GetValidMoves pour chaque piéce
  - [ ] ZOC filtering
  - [ ] Terrain effects

---

## 🚣 Performance Optimisation

### Cache Mouvement

```csharp
private Dictionary<PieceInstance, List<HexCoordinate>> movementCache;

// Mémoriser calcul
if (movementCache.ContainsKey(piece))
    return movementCache[piece];

// Ré-calculer si plateau changé
movementEngine.ClearCache();
```

### Éviter O(n²) Loops

```csharp
// ❌ MAUVAIS: Vérifier TOUTES les piéces pour chaque mouvement
foreach (var move in validMoves)
{
    foreach (var piece in allPieces)
    {
        if (piece.Position == move) ...
    }
}

// ✅ BON: Dictionnaire rapide
private Dictionary<HexCoordinate, PieceInstance> boardState;
if (boardState.ContainsKey(move))
    var occupier = boardState[move];
```

### Limitation Calcul

```csharp
// Vérifier ZOC seulement pour piéces proches
var nearbyEnemies = boardManager.GetEnemiesInRadius(
    piece,
    radius: 2  // Seulement voisins!
);
```

---

## 📏 Exemples de Scénarios

### Scénario 1: Tour Mouvement Reine

```
T1 (Reine blanc):
1. StartTurn(): AP = 2
2. GetValidMoves(reine): 
   - 6 directions hex
   - Jus qu'au bord ou obstacle
   - Ennemi = capture possible
3. Joueur clique (2,0)
4. TryConsumeAP(1, Move): AP = 1
5. BoardManager.MovePiece(reine, (2,0))
6. ShowValidMovesAgain(reine)
7. Joueur clique attaque
8. TryConsumeAP(1, Attack): AP = 0
9. EndTurn()
```

### Scénario 2: Double Mouvement Cavalier

```
T1 (Cavalier noir):
1. StartTurn(): AP = 2
2. Move 1: Cavalier (0,0) → (2,0)
   - TryConsumeAP(1, Move): AP = 1
3. Move 2: Cavalier (2,0) → (4,1)
   - TryConsumeAP(1, Move): AP = 0
   - IsDoubleMovePerformed() = true
   - 🔥 BONUS: +1 portée saut prochain tour
4. EndTurn()
```

### Scénario 3: Soldat Orientation

```
T1 (Soldat blanc, joueur 1):
1. StartTurn(): AP = 2
2. Forward direction = NW (d'après joueur)
3. GetValidMoves(soldat):
   - Avancée simple: +1 NW
   - Saut initial: +2 NW (premier mouvement)
   - Captures: diagonales NE/NW si ennemi
4. Joueur clique NW (avancée 1 case)
5. TryConsumeAP(1, Move): AP = 1
6. EndTurn ou 2e mouvement
```

### Scénario 4: ZOC Bloquage

```
T1 (Fou blanc, mais dans ZOC Tour noire):
1. Fou à (1,0), Tour noire à (0,0)
2. GetValidMoves(fou):
   - Calcule 4 diagonales
   - Vérifier CanLeaveZOC(fou, (3,0))?
   - Est dans ZOC? Oui (distance 1)
   - Quitter ZOC? Oui
   - zocBlocksMovement = false?
   - Appliquer coûts +1
3. Si zocBlocksMovement = true:
   - Mouvement bloqué!
4. Cavaleir peut quitter (ignore)
```

### Scénario 5: Piége Spike

```
T1 (Cavalier):
1. GetValidMoves(cavalier): Retour 8 sauts
2. Joueur clique (2,1) [case piégée]
3. BoardManager.MovePiece(cavalier, (2,1))
4. TriggerTrap((2,1), cavalier):
   - Trap.Type = Spike
   - Damage = 5
   - CombatSystem.DealDamage(cavalier, 5)
   - Trap.IsArmed = false
5. Cavalier prend 5 dégâts
```

---

## 📄 Résumé Classes

| Classe | Rôle | Fichier |
|--------|------|----------|
| **TurnState** | Allocation 2 AP | MOVEMENT_SYSTEM.md |
| **HexCoordinate** | Géométrie hex | MOVEMENT_SYSTEM.md |
| **MovementEngine** | Calcul mouvements | MOVEMENT_SYSTEM.md |
| **ZOCManager** | Zone contrôle | MOVEMENT_ADVANCED.md |
| **TerrainManager** | Piéges & terrain | MOVEMENT_ADVANCED.md |
| **PathfindingEngine** | A* pour IA | MOVEMENT_ADVANCED.md |
| **TurnManager** | Orchéstration | MOVEMENT_ADVANCED.md |

---

## 🤞 FAQ

**Q: Comment changer direction forward du Soldat?**  
A: Modifier GetPawnForwardDirection(). 1 = SE, 4 = NW, etc.

**Q: Cavalier avec ZOC: oui ou non?**  
A: Non! Voir CanLeaveZOC() - Cavalier retourne true toujours.

**Q: Peut-on avoir 3 AP?**  
A: Oui! Modifier MAX_AP dans TurnState (mais retester bonus).

**Q: Performance pour grille 20x20?**  
A: Cache + limiter rayon ZOC = OK. Bench: <1ms /tour.

**Q: Terrains ralentissent mouvement?**  
A: Oui, via MovementCost. Impacte portée Sliders seulement.

**Q: Comment tester les mouvements?**  
A: Voir MOVEMENT_SYSTEM.md tests unitaires.

---

## 🚀 Prochaines Étapes

1. **Lire** MOVEMENT_SYSTEM.md (base)
2. **Implémenter** HexCoordinate + TurnState
3. **Créer** MovementEngine avec GetSliderMoves
4. **Tester** Reine/Tour/Fou seuls
5. **Ajouter** Cavalier + GetLeaperMoves
6. **Implémenter** Soldat + orientation
7. **Intégrer** ZOCManager + TerrainManager
8. **Tester** complet avec TurnManager
9. **Optimiser** cache + performance
10. **Polir** animations + feedback visuel

---

**Système de mouvement complet prêt pour votre jeu d'échecs RPG!** 🚶✨