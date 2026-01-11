# 🚶 Système de Mouvement - Partie 2: Sliders, Leapers, Terrain
## Reine, Tour, Fou, Cavalier, Soldats & Contraintes

**Namespace:** `OctagonalChess.Movement`

**Continuer de:** [MOVEMENT_SYSTEM.md - Partie 1](./MOVEMENT_SYSTEM.md)

---

## TABLE DES MATIÈRES

1. [Sliders: Reine, Tour, Fou](#1-sliders-reine-tour-fou)
2. [Leapers: Cavalier](#2-leapers-cavalier)
3. [Soldats avec Orientation](#3-soldats-avec-orientation)
4. [Roi 1 Case](#4-roi-1-case)
5. [Zone de Contrôle (ZOC)](#5-zone-de-contrôle-zoc)
6. [Pièges & Terrain](#6-pièges--terrain)
7. [Pathfinding & Prévisualisation](#7-pathfinding--prévisualisation)
8. [Intégration TurnManager](#8-intégration-turnmanager)

---

## 1. SLIDERS: REINE, TOUR, FOU

### 👑 Reine (Toutes les 6 directions)

```csharp
/// <summary>
/// GetSliderMoves = Calcule les mouvements en ligne (Sliders).
/// 
/// Sliders: Se déplacent en ligne droite jusqu'à un obstacle.
/// - Reine: 6 directions (toutes)
/// - Tour: 4 directions (cardinales: E, W, NW, SE)
/// - Fou: 4 directions (diagonales: NE, SW, SE, NW)
/// 
/// Algo:
/// 1. Pour chaque direction autorisée
/// 2. Avancé case par case
/// 3. Arrêter si obstacle ou limite
/// 4. Inclure captures d'ennemis
/// </summary>
private List<HexCoordinate> GetSliderMoves(
    PieceInstance piece,
    int actionPointsAvailable)
{
    var moves = new List<HexCoordinate>();
    var current = gridManager.GetPiecePosition(piece);
    
    // Déterminer directions autorisées selon pièce
    var directions = GetSliderDirections(piece);
    
    // Pour chaque direction
    foreach (int dirIndex in directions)
    {
        var current_check = current.GetNeighbor(dirIndex);
        int range = GetMovementRange(piece);
        
        // Avancé jusqu'à limite ou obstacle
        for (int dist = 1; dist <= range; dist++)
        {
            // Vérifier les limites du plateau
            if (!gridManager.IsInBounds(current_check))
                break;
            
            // VÉRIFIER OCCUPATION
            if (boardManager.IsOccupied(current_check))
            {
                // Ennemi = capture possible, puis arrêt
                if (IsEnemyAt(piece, current_check))
                {
                    moves.Add(current_check);
                }
                // Allié = arrêt complet
                break;
            }
            
            // Case libre = ajouter
            moves.Add(current_check);
            
            // Avancé pour prochain itération
            current_check = current_check.GetNeighbor(dirIndex);
        }
    }
    
    return moves;
}

/// <summary>
/// Détermine les 6 directions valides selon la pièce.
/// </summary>
private List<int> GetSliderDirections(PieceInstance piece)
{
    return piece.Category switch
    {
        // Reine: toutes les 6 directions
        PieceCategorie.Reine => new List<int> { 0, 1, 2, 3, 4, 5 },
        
        // Tour: 4 directions (E, SE, W, NW) - pairs
        PieceCategorie.Tour => new List<int> { 0, 1, 3, 4 },
        
        // Fou: 4 directions diagonales (NE, SE, SW, NW) - impairs
        // En hex: (0,0) → (1,-1) → (-1,0) → (-1,1)
        PieceCategorie.Fou => new List<int> { 0, 2, 3, 5 },
        
        _ => new List<int>()
    };
}

/// <summary>
/// Retourne la portée de mouvement selon pièce et terrain.
/// </summary>
private int GetMovementRange(PieceInstance piece)
{
    // Portée de base
    int range = piece.Category switch
    {
        PieceCategorie.Reine => 8,     // Illimité en pratique
        PieceCategorie.Tour => 8,
        PieceCategorie.Fou => 8,
        _ => 1
    };
    
    // Modificateur terrain (voir TerrainManager)
    if (terrainManager != null)
    {
        var terrain = terrainManager.GetTerrainAt(gridManager.GetPiecePosition(piece));
        if (terrain != null)
            range = Mathf.Max(0, range - terrain.MovementCost);
    }
    
    return range;
}
```

### 🗿 Tour (4 axes cardinaux)

```
Portée Tour (8 cases max):
         
           NW    NE
             \  /
              \/
    W ------- T ------- E
              /\
             /  \
           SW    SE

En hex axial: (0,1), (1,0), (1,-1), (0,-1), (-1,0), (-1,1)
Mais Tour seulement: (1,0), (1,-1), (-1,0), (-1,1)
```

### 🗺 Fou (4 diagonales)

```
Portée Fou (8 cases max):

    /\  /\
   /  \/  \
  | F      |
   \  /\  /
    \/  \/

En hex: Mêmes 6 voisins, mais seulement les diagonales
```

---

## 2. LEAPERS: CAVALIER

### 🐴 Cavalier (Saute par-dessus)

```csharp
/// <summary>
/// GetLeaperMoves = Cavalier saute par-dessus pièces et obstacles.
/// 
/// Saut Cavalier (hex/octagon):
/// - De la forme "L" adaptée au hex
/// - 8 sauts possibles
/// - Ignore obstacles
/// - Ignore ZOC
/// 
/// Offsets de saut (q, r):
///   (+2, 0)  (+1, -2)  (-1, -2)
///   (+2, -1) Cavalier  (-2, -1)
///   (+1, +1)  (-1, +1) (-2, +1)
/// </summary>
private List<HexCoordinate> GetLeaperMoves(
    PieceInstance piece,
    int actionPointsAvailable)
{
    var moves = new List<HexCoordinate>();
    var current = gridManager.GetPiecePosition(piece);
    
    // Définir les 8 offsets de saut du Cavalier hex
    var knightOffsets = new HexCoordinate[]
    {
        // Sauts longs (distance 2)
        new HexCoordinate(2, 0),
        new HexCoordinate(0, 2),
        new HexCoordinate(-2, 2),
        new HexCoordinate(-2, 0),
        new HexCoordinate(0, -2),
        new HexCoordinate(2, -2),
        
        // Sauts courts (distance 1.5 environ)
        new HexCoordinate(1, 1),
        new HexCoordinate(-1, 2),
        new HexCoordinate(-2, 1),
        new HexCoordinate(-1, -1),
        new HexCoordinate(1, -2),
        new HexCoordinate(2, -1)
    };
    
    foreach (var offset in knightOffsets)
    {
        var target = new HexCoordinate(current.q + offset.q, current.r + offset.r);
        
        // Vérifier limites
        if (!gridManager.IsInBounds(target))
            continue;
        
        // Ennemi ou vide = valide
        if (!boardManager.IsOccupied(target) || IsEnemyAt(piece, target))
        {
            moves.Add(target);
        }
    }
    
    return moves;
}

/// <summary>
/// BONUS DOUBLE MOUVEMENT: Cavalier +1 case de portée.
/// </summary>
public void ApplyCavalierDoubleMoveBonu()
{
    // Ajouter offset supplémentaire au calcul
    // Géré via TurnState.OnDoubleMoveBonus
}
```

### Tableau Offsets Cavalier (8 sauts)

```
Hex Grid - Saut Cavalier

     A   B   C
   D   E   F   G
     H   K   L
   M   N   O   P
     Q   R   S

De K:
- Saut type 1: K → A (distance ~2)
- Saut type 2: K → C (distance ~1.5)
- Etc...

En coordonnées axiales (q, r):
(+2, 0), (0, +2), (-2, +2), (-2, 0), (0, -2), (+2, -2)  = 6 sauts
(+1, +1), (-1, +2), (-2, +1), (-1, -1), (+1, -2), (+2, -1)  = 6 sauts

Total: 12 sauts possibles par case
```

---

## 3. SOLDATS AVEC ORIENTATION

### 🐙 Pion/Soldat (Avancée only)

```csharp
/// <summary>
/// GetPawnMoves = Soldat avec orientation "forward".
/// 
/// Règles Pion/Soldat:
/// - Avancée simple: 1 case forward (toujours)
/// - Saut initial: 2 cases forward (premier mouvement)
/// - Capture diagonale: 1 case diagonal-forward (ennemi seulement)
/// - Pas de mouvement arrière
/// 
/// Définition "forward" sur hex:
/// - Joueur 1 (bas): direction ↑ (NW, NE, W...)
/// - Joueur 2 (haut): direction ↓ (SE, SW, E...)
/// </summary>
private List<HexCoordinate> GetPawnMoves(
    PieceInstance piece,
    int actionPointsAvailable)
{
    var moves = new List<HexCoordinate>();
    var current = gridManager.GetPiecePosition(piece);
    
    // Déterminer direction "forward"
    int forwardDirection = GetPawnForwardDirection(piece);
    var forward = current.GetNeighbor(forwardDirection);
    
    // --- AVANCÉE SIMPLE ---
    if (gridManager.IsInBounds(forward) && !boardManager.IsOccupied(forward))
    {
        moves.Add(forward);
        
        // --- SAUT INITIAL (2 cases) ---
        if (!piece.HasMovedThisTurn)
        {
            var double_forward = forward.GetNeighbor(forwardDirection);
            if (gridManager.IsInBounds(double_forward) && !boardManager.IsOccupied(double_forward))
            {
                moves.Add(double_forward);
            }
        }
    }
    
    // --- CAPTURES DIAGONALES ---
    // Les deux diagonales qui "pointent" forward
    var diagonalDirections = GetPawnDiagonalDirections(forwardDirection);
    
    foreach (int diagDir in diagonalDirections)
    {
        var diagonal = current.GetNeighbor(diagDir);
        
        if (gridManager.IsInBounds(diagonal) && IsEnemyAt(piece, diagonal))
        {
            moves.Add(diagonal);
        }
    }
    
    return moves;
}

/// <summary>
/// Détermine la direction "forward" selon le joueur.
/// </summary>
private int GetPawnForwardDirection(PieceInstance piece)
{
    // Exemple: Joueur 1 = bas du plateau
    if (piece.OwnerPlayer == 1)
        return 4;  // Direction NW en hex
    else
        return 1;  // Direction SE en hex
}

/// <summary>
/// Retourne les 2 directions diagonales avant.
/// </summary>
private List<int> GetPawnDiagonalDirections(int forwardDir)
{
    return forwardDir switch
    {
        0 => new List<int> { 5, 1 },  // E: NE, SE
        1 => new List<int> { 0, 2 },  // SE: E, SW
        2 => new List<int> { 1, 3 },  // SW: SE, W
        3 => new List<int> { 2, 4 },  // W: SW, NW
        4 => new List<int> { 3, 5 },  // NW: W, NE
        5 => new List<int> { 4, 0 },  // NE: NW, E
        _ => new List<int>()
    };
}
```

### Diagramme Pion (Orientation)

```
Joueur 1 (en bas):
          
       /\
      /  \
     < P >  Forward = NW, NE (diagonales avant)
      \  /
       \/

Avancée simple: 1 case forward (NW ou NE)
Capture: 1 case diagonale forward
Saut initial: 2 cases forward
```

---

## 4. ROI 1 CASE

### 👑 Roi (1 hexagone dans toute direction)

```csharp
/// <summary>
/// GetKingMoves = Roi peut se déplacer 1 case dans toute direction.
/// </summary>
private List<HexCoordinate> GetKingMoves(
    PieceInstance piece,
    int actionPointsAvailable)
{
    var moves = new List<HexCoordinate>();
    var current = gridManager.GetPiecePosition(piece);
    
    // Tous les 6 voisins
    var neighbors = current.GetAllNeighbors();
    
    foreach (var neighbor in neighbors)
    {
        // Vérifier limites
        if (!gridManager.IsInBounds(neighbor))
            continue;
        
        // Case vide ou ennemi
        if (!boardManager.IsOccupied(neighbor) || IsEnemyAt(piece, neighbor))
        {
            moves.Add(neighbor);
        }
    }
    
    return moves;
}
```

---

## 5. ZONE DE CONTRÔLE (ZOC)

### 🔴 ZOCManager.cs

```csharp
using UnityEngine;
using System.Collections.Generic;
using System.Linq;
using OctagonalChess.Core;

namespace OctagonalChess.Movement
{
    /// <summary>
    /// ZOCManager = Gestion des Zones de Contrôle.
    /// 
    /// Règle:
    /// Si une pièce quitte une case adjacente à un ennemi,
    /// le coût de mouvement AUGMENTE ou le mouvement est BLOQUÉ.
    /// 
    /// Exception: Cavalier ignore la ZOC.
    /// 
    /// Implementation:
    /// - ZOC = 1 hexagone autour de chaque piéce ennemie
    /// - Pour quitter la ZOC: coût additionnel ou impossible
    /// </summary>
    public class ZOCManager : MonoBehaviour
    {
        [SerializeField] private BoardManager boardManager;
        [SerializeField] private GridManager gridManager;
        
        [Header("⚡ Paramétrages")]
        [SerializeField] private bool zocBlocksMovement = false;  // true = impossible, false = coût +1
        [SerializeField] private int zocCost = 1;  // Coût additionnel
        
        /// <summary>
        /// Vérifie si une pièce peut quitter la zone de contrôle d'un ennemi.
        /// </summary>
        public bool CanLeaveZOC(PieceInstance piece, HexCoordinate targetPosition)
        {
            // Cavalier ignore ZOC
            if (piece.Category == PieceCategorie.Cavalier)
                return true;
            
            var currentPos = gridManager.GetPiecePosition(piece);
            var enemies = boardManager.GetAllEnemiesOf(piece.OwnerPlayer);
            
            // Pour chaque ennemi
            foreach (var enemy in enemies)
            {
                if (!enemy.IsAlive)
                    continue;
                
                var enemyPos = gridManager.GetPiecePosition(enemy);
                
                // Vérifier si pièce est dans ZOC de l'ennemi
                if (IsInZOC(currentPos, enemyPos))
                {
                    // Vérifier si destination quitte la ZOC
                    if (!IsInZOC(targetPosition, enemyPos))
                    {
                        if (zocBlocksMovement)
                        {
                            Debug.Log($"[ZOC] \u274c {piece.PieceName} ne peut quitter ZOC de {enemy.PieceName}");
                            return false;
                        }
                        else
                        {
                            Debug.Log($"[ZOC] \u26a0 {piece.PieceName} quitte ZOC (coût +{zocCost})");
                            // Appliquer coût additionnel ailleurs
                        }
                    }
                }
            }
            
            return true;
        }
        
        /// <summary>
        /// Vérifie si une position est dans la ZOC de controleuse.
        /// </summary>
        private bool IsInZOC(HexCoordinate position, HexCoordinate controllerPos)
        {
            return position.DistanceTo(controllerPos) <= 1;  // Distance 0 ou 1
        }
        
        /// <summary>
        /// Retourne la ZOC (disque de rayon 1) pour un adversaire.
        /// </summary>
        public List<HexCoordinate> GetZOCCells(HexCoordinate controllerPos)
        {
            return controllerPos.GetDisk(1);
        }
        
        /// <summary>
        /// Visualiser ZOC pour débuggage.
        /// </summary>
        public void DebugDrawZOC(HexCoordinate center, Color color)
        {
            var zoc = GetZOCCells(center);
            foreach (var cell in zoc)
            {
                Debug.DrawLine(
                    gridManager.HexToWorldPosition(center),
                    gridManager.HexToWorldPosition(cell),
                    color,
                    0.5f
                );
            }
        }
    }
}
```

---

## 6. PIÈGES & TERRAIN

### ⚠ TerrainManager.cs

```csharp
using UnityEngine;
using System.Collections.Generic;

namespace OctagonalChess.Gameplay
{
    /// <summary>
    /// TerrainManager = Gestion du terrain, pièges, obstacles.
    /// 
    /// Types de terrain:
    /// - Herbe (gratuit)
    /// - Pierre (coût +1 mouvement)
    /// - Glace (coût -1 mais rebond aléatoire)
    /// - Lave (coûts +2, dégâts en entrée)
    /// 
    /// Piéges:
    /// - Piégé : Déjà activé (aucun effet)
    /// - Armé: Va s'activer à prochaine entrée
    /// - Désarmé: Neutre
    /// </summary>
    public class TerrainManager : MonoBehaviour
    {
        private Dictionary<HexCoordinate, TerrainTile> terrainTiles;
        private Dictionary<HexCoordinate, Trap> traps;
        
        [SerializeField] private GridManager gridManager;
        [SerializeField] private CombatSystem combatSystem;
        
        private void Awake()
        {
            terrainTiles = new Dictionary<HexCoordinate, TerrainTile>();
            traps = new Dictionary<HexCoordinate, Trap>();
        }
        
        /// <summary>
        /// Retourne le terrain à une position.
        /// </summary>
        public TerrainTile GetTerrainAt(HexCoordinate pos)
        {
            return terrainTiles.ContainsKey(pos) ? terrainTiles[pos] : null;
        }
        
        /// <summary>
        /// Vérifie s'il y a un piége à une position.
        /// </summary>
        public bool HasTrap(HexCoordinate pos)
        {
            return traps.ContainsKey(pos) && traps[pos].IsArmed;
        }
        
        /// <summary>
        /// Déclenche le piége quand pièce entrée.
        /// </summary>
        public void TriggerTrap(HexCoordinate pos, PieceInstance piece)
        {
            if (!HasTrap(pos))
                return;
            
            var trap = traps[pos];
            
            Debug.Log($"[Trap] 💣 {piece.PieceName} déclenche piége: {trap.TrapType}");
            
            switch (trap.TrapType)
            {
                case TrapType.Spike:
                    // Dégâts à la piéce
                    combatSystem.DealDamage(piece, trap.Damage);
                    break;
                    
                case TrapType.Immobilize:
                    // Piéce immobilisée 1 tour
                    piece.ApplyStun(1);
                    break;
                    
                case TrapType.Slow:
                    // Réduire mouvement prochain tour
                    piece.ApplyBuff(StatType.Movement, -1, 1);
                    break;
            }
            
            // Désarmer le piége
            trap.IsArmed = false;
        }
    }
    
    [System.Serializable]
    public class TerrainTile
    {
        public TerrainType Type;
        public int MovementCost;  // Coûts additionnel
        public int DefenseBonus;
        
        public TerrainTile(TerrainType type, int cost = 0, int defBonus = 0)
        {
            Type = type;
            MovementCost = cost;
            DefenseBonus = defBonus;
        }
    }
    
    [System.Serializable]
    public class Trap
    {
        public TrapType TrapType;
        public bool IsArmed = true;
        public int Damage = 5;
    }
    
    public enum TerrainType
    {
        Grass,      // Gratuit
        Stone,      // Coûts +1
        Ice,        // Coûts -1
        Lava,       // Coûts +2 + dégâts
        Forest,     // Coûts +1 + défense
        Water       // Bloque (sauf unités volantes)
    }
    
    public enum TrapType
    {
        Spike,      // Dégâts
        Immobilize, // Stun 1 tour
        Slow        // Réduit portée
    }
}
```

---

## 7. PATHFINDING & PRÉVISUALISATION

### 🗙 PathfindingEngine.cs

```csharp
using UnityEngine;
using System.Collections.Generic;
using System.Linq;

namespace OctagonalChess.Movement
{
    /// <summary>
    /// PathfindingEngine = A* pour trouver le chemin optimal.
    /// 
    /// Utilisé pour:
    /// - Prévisualisation des chemins de mouvement
    /// - Calcul du coûts réels (ZOC, terrain)
    /// - Déplacements IA
    /// </summary>
    public class PathfindingEngine : MonoBehaviour
    {
        [SerializeField] private MovementEngine movementEngine;
        [SerializeField] private BoardManager boardManager;
        [SerializeField] private GridManager gridManager;
        
        /// <summary>
        /// Trouve le chemin optimal entre deux positions (A* algorithm).
        /// </summary>
        public List<HexCoordinate> FindPath(
            HexCoordinate start,
            HexCoordinate goal,
            PieceInstance piece)
        {
            var openSet = new HashSet<HexCoordinate> { start };
            var cameFrom = new Dictionary<HexCoordinate, HexCoordinate>();
            var gScore = new Dictionary<HexCoordinate, float> { { start, 0 } };
            var fScore = new Dictionary<HexCoordinate, float> { { start, Heuristic(start, goal) } };
            
            while (openSet.Count > 0)
            {
                // Trouver noeud avec plus faible fScore
                var current = openSet.OrderBy(x => fScore.ContainsKey(x) ? fScore[x] : float.MaxValue).First();
                
                if (current == goal)
                    return ReconstructPath(cameFrom, current);
                
                openSet.Remove(current);
                
                // Vérifier voisins
                var neighbors = current.GetAllNeighbors();
                foreach (var neighbor in neighbors)
                {
                    if (!gridManager.IsInBounds(neighbor))
                        continue;
                    
                    // Coûts du mouvement
                    float tentativeGScore = gScore[current] + 1;
                    
                    if (!gScore.ContainsKey(neighbor) || tentativeGScore < gScore[neighbor])
                    {
                        cameFrom[neighbor] = current;
                        gScore[neighbor] = tentativeGScore;
                        fScore[neighbor] = gScore[neighbor] + Heuristic(neighbor, goal);
                        
                        if (!openSet.Contains(neighbor))
                            openSet.Add(neighbor);
                    }
                }
            }
            
            return new List<HexCoordinate>();  // Pas de chemin
        }
        
        private float Heuristic(HexCoordinate a, HexCoordinate b)
        {
            return a.DistanceTo(b);
        }
        
        private List<HexCoordinate> ReconstructPath(
            Dictionary<HexCoordinate, HexCoordinate> cameFrom,
            HexCoordinate current)
        {
            var path = new List<HexCoordinate> { current };
            
            while (cameFrom.ContainsKey(current))
            {
                current = cameFrom[current];
                path.Add(current);
            }
            
            path.Reverse();
            return path;
        }
    }
}
```

---

## 8. INTÉGRATION TURNMANAGER

### ⛃ TurnManager.cs - Orchestration

```csharp
using UnityEngine;
using OctagonalChess.Movement;
using OctagonalChess.Core;
using OctagonalChess.Gameplay;

namespace OctagonalChess.GameFlow
{
    /// <summary>
    /// TurnManager = Orchéstration complète du tour.
    /// 
    /// Flux:
    /// 1. StartTurn() - allocate 2 AP
    /// 2. Joueur sélectionne pièce
    /// 3. ShowValidMoves() - affiche mouvements
    /// 4. PlayerMove() - exécute le mouvement
    /// 5. Joueur peut attaquer ou bouger à nouveau
    /// 6. EndTurn() - cleanup
    /// </summary>
    public class TurnManager : MonoBehaviour
    {
        [Header("🎮 Références")]
        [SerializeField] private MovementEngine movementEngine;
        [SerializeField] private BoardManager boardManager;
        [SerializeField] private GridManager gridManager;
        [SerializeField] private UIManager uiManager;
        
        private TurnState currentTurnState;
        private PieceInstance selectedPiece;
        
        // ========== ÉVÉNEMENTS ==========
        
        public event System.Action<PieceInstance> OnPieceSelected;
        public event System.Action<PieceInstance> OnPieceMoved;
        public event System.Action<PieceInstance> OnTurnEnded;
        
        // ========== FLUX DE TOUR ==========
        
        public void StartTurn(PieceInstance piece)
        {
            currentTurnState = new TurnState();
            currentTurnState.StartTurn(piece);
            
            Debug.Log($"\ud83c\udf86 Tour de {piece.PieceName} (2 AP disponible)");
            
            uiManager.DisplayTurnInfo(piece, currentTurnState.CurrentAP);
        }
        
        public void SelectPiece(PieceInstance piece)
        {
            selectedPiece = piece;
            OnPieceSelected?.Invoke(piece);
            
            // Afficher mouvements valides
            ShowValidMoves(piece);
        }
        
        public void ShowValidMoves(PieceInstance piece)
        {
            var validMoves = movementEngine.GetValidMoves(
                piece,
                currentTurnState.CurrentAP
            );
            
            // Afficher sur UI
            uiManager.HighlightValidMoves(validMoves);
            
            Debug.Log($"[TurnManager] {validMoves.Count} mouvements valides pour {piece.PieceName}");
        }
        
        public void PlayerMove(PieceInstance piece, HexCoordinate target)
        {
            // Vérifier si mouvement valide
            var validMoves = movementEngine.GetValidMoves(piece, currentTurnState.CurrentAP);
            if (!validMoves.Contains(target))
            {
                Debug.LogWarning("[TurnManager] ❌ Mouvement invalide!");
                return;
            }
            
            // Dépenser 1 AP
            if (!currentTurnState.TryConsumeAP(1, ActionType.Move))
                return;
            
            // Exécuter mouvement
            var currentPos = gridManager.GetPiecePosition(piece);
            boardManager.MovePiece(piece, target);
            
            // Vérifier piéges
            if (TryTriggerTrap(piece, target))
            {
                // Piége déclenché = peut être fatal
            }
            
            OnPieceMoved?.Invoke(piece);
            
            // Vérifier si tour terminé
            if (currentTurnState.IsTurnFinished())
            {
                EndTurn();
            }
            else
            {
                // Afficher nouvelles options
                ShowValidMoves(piece);
            }
        }
        
        private bool TryTriggerTrap(PieceInstance piece, HexCoordinate pos)
        {
            var terrainManager = FindObjectOfType<TerrainManager>();
            if (terrainManager && terrainManager.HasTrap(pos))
            {
                terrainManager.TriggerTrap(pos, piece);
                return true;
            }
            return false;
        }
        
        public void EndTurn()
        {
            Debug.Log($"\u26c3 Tour de {currentTurnState.CurrentPiece.PieceName} terminé");
            
            OnTurnEnded?.Invoke(currentTurnState.CurrentPiece);
            
            // Nettoyer cache mouvement
            movementEngine.ClearCache();
            
            // Passer au tour suivant
            // (géré par GameFlow)
        }
    }
}
```

---

## 📄 Résumé d'Implémentation

| Composant | Rôle | Coûts |
|-----------|------|-------|
| **TurnState** | Allocation & suivi des 2 AP | ✓ Impact direct |
| **MovementEngine** | Calcul des mouvements valides | Simulation |
| **HexCoordinate** | Géométrie hexagone | ✅ Complet |
| **ZOCManager** | Zone de contrôle | Optionnel |
| **TerrainManager** | Piéges & terrain | Optionnel |
| **PathfindingEngine** | Chemin optimal (A*) | Utile pour IA |
| **TurnManager** | Orchéstration | ✅ Le tout coordonné |

---

**Suite:** [MOVEMENT_INTEGRATION.md](./MOVEMENT_INTEGRATION.md) - Schémas d'intégration et exemples de code complet.