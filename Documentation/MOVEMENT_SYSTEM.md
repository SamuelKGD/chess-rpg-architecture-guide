# 🚶 Système de Mouvement - Octagonal Chess Tactics
## 2 Actions par Tour, Grille Hexagone, ZOC & Pièges

**Namespace:** `OctagonalChess.Movement`

---

## TABLE DES MATIÈRES

1. [Vue d'Ensemble](#1-vue-densemble)
2. [Système de Points d'Action (AP)](#2-système-de-points-daction-ap)
3. [Géométrie Hexagone - Coordonnées Axiales](#3-géométrie-hexagone--coordonnées-axiales)
4. [Moteur de Mouvement - GetValidMoves()](#4-moteur-de-mouvement--getvalidmoves)
5. [Sliders (Reine, Tour, Fou)](#5-sliders-reine-tour-fou)
6. [Leapers (Cavalier)](#6-leapers-cavalier)
7. [Soldats avec Orientation](#7-soldats-avec-orientation)
8. [Zone de Contrôle (ZOC)](#8-zone-de-contrôle-zoc)
9. [Pièges & Terrain](#9-pièges--terrain)
10. [Pathfinding & Prévisualisation](#10-pathfinding--prévisualisation)

---

## 1. VUE D'ENSEMBLE

### 📊 Flux de Mouvement

```
T1 = Tour allié
╔════════════════════════════════════════════════════════════╗
║          SYSTÈME DE MOUVEMENT (Octagonal Chess Tactics)              ║
╚════════════════════════════════════════════════════════════╗

1. DÉBUT TOUR: TurnManager alloca 2 AP
   │
   ├─→ Joueur sélectionne une pièce
   │   └─→ MovementEngine.GetValidMoves(piece)
   │       ├─→ Calculer portee (Hex grid)
   │       ├─→ Vérifier ZOC (Zone de Contrôle)
   │       ├─→ Vérifier piéges
   │       └─→ Retourner liste des cases valides
   │
   ├─→ UI affiche déplacement prévisualisé
   │
   ├─→ Joueur clique sur case cible
   │   └─→ MovementEngine.Move(piece, target)
   │       ├─→ Décrémenter AP: 2 → 1
   │       ├─→ Déplacer pièce
   │       ├─→ Vérifier piéges
   │       └─→ Activer ZOC
   │
   ├─→ Joueur peut:
   │   ├─ Attaquer (coûte 1 AP)
   │   │  └─→ CombatSystem.ResolveCombat()
   │   │      └─→ AP: 1 → 0 (TOUR TERMINÉ)
   │   ├─ Bouger à nouveau (si pas d'attaque)
   │   │  └─→ GetValidMoves() (avec 1 AP restant)
   │   └─ Terminer le tour
   │       └─→ AP: 0 ou 1 (fin de tour)
   │
   └─→ FIN TOUR: Nettoyer état de mouvement
```

### ⚡ Caractéristiques Clés

- **2 Actions Par Tour** : Chaque pièce dispose de 2 AP (Action Points)
- **Hexagone** : Grille 6-adjacent (pas 4 ou 8)
- **Sliders** : Reine, Tour, Fou se déplacent en ligne jusqu'au blocage
- **Leapers** : Cavalier saute par-dessus les obstacles
- **Double Mouvement** : 2 AP pour mouvoir = bonus stratégique
- **Orientation** : Soldats ne bougent que "forward"
- **ZOC** : Quitter case adjacente à ennemi coûte plus cher
- **Piéges** : Cases spéciales infligent effet

---

## 2. SYSTÈME DE POINTS D'ACTION (AP)

### 🎉 TurnState.cs - État du Tour

```csharp
using UnityEngine;
using System.Collections.Generic;
using OctagonalChess.Core;

namespace OctagonalChess.Movement
{
    /// <summary>
    /// TurnState = Gère l'allocation des points d'action (AP) pour une pièce pendant son tour.
    /// 
    /// Règles:
    /// - Chaque pièce reçoit 2 AP au début de son tour
    /// - Move() coûte 1 AP
    /// - Attack() coûte 1 AP
    /// - Double Move: Si joueur utilise 2 AP pour bouger (pas d'attaque)
    ///   → Bonus spécial (Cavalier +1 case, Soldat +1 DEF)
    /// 
    /// Exemples:
    /// - Scénario 1: Move (2→1 AP) + Attack (1→0 AP) = Tour fini
    /// - Scénario 2: Move (2→1 AP) + Move (1→0 AP) = Double mouvement = BONUS
    /// - Scénario 3: Move (2→1 AP) + Rien = 1 AP gâché
    /// </summary>
    [System.Serializable]
    public class TurnState
    {
        public const int MAX_AP = 2;  // Points d'action max par tour
        
        // ========== ÉTAT ==========
        
        public PieceInstance CurrentPiece { get; private set; };
        public int CurrentAP { get; private set; };
        public int APUsedThisTurn { get; private set; };
        
        // Tracker les actions
        private List<ActionType> actionsPerformed = new List<ActionType>();
        
        // ========== ÉVÉNEMENTS ==========
        
        public event System.Action<int> OnAPChanged;  // (newAP)
        public event System.Action OnDoubleMoveBonus;  // Déclenché si 2 mouvements
        
        // ========== INITIALISATION ==========
        
        public void StartTurn(PieceInstance piece)
        {
            CurrentPiece = piece;
            CurrentAP = MAX_AP;
            APUsedThisTurn = 0;
            actionsPerformed.Clear();
            
            Debug.Log($"[TurnState] \ud83c\udf86 {piece.PieceName} commence avec {MAX_AP} AP");
        }
        
        // ========== CONSOMMATION D'AP ==========
        
        /// <summary>
        /// Essaie de dépenser X AP pour une action.
        /// Retourne true si succès.
        /// </summary>
        public bool TryConsumeAP(int amount, ActionType actionType)
        {
            if (CurrentAP < amount)
            {
                Debug.LogWarning($"[TurnState] \u274c Insuffisant AP: {CurrentAP}/{amount}");
                return false;
            }
            
            CurrentAP -= amount;
            APUsedThisTurn += amount;
            actionsPerformed.Add(actionType);
            
            OnAPChanged?.Invoke(CurrentAP);
            
            Debug.Log($"[TurnState] -{amount} AP (reste: {CurrentAP}). Action: {actionType}");
            
            // ========== VÉRIFIER DOUBLE MOUVEMENT ==========
            
            if (IsDoubleMovePerformed())
            {
                ApplyDoubleMoveBonus();
            }
            
            return true;
        }
        
        /// <summary>
        /// Vérifie si le joueur a effectué 2 mouvements (pas d'attaque).
        /// </summary>
        private bool IsDoubleMovePerformed()
        {
            int moveCount = 0;
            int attackCount = 0;
            
            foreach (var action in actionsPerformed)
            {
                if (action == ActionType.Move)
                    moveCount++;
                else if (action == ActionType.Attack)
                    attackCount++;
            }
            
            // Double move = 2 move et 0 attack
            return moveCount == 2 && attackCount == 0;
        }
        
        /// <summary>
        /// Applique les bonus du double mouvement.
        /// </summary>
        private void ApplyDoubleMoveBonus()
        {
            Debug.Log($"[TurnState] \ud83d\udd25 DOUBLE MOUVEMENT BONUS!");
            
            OnDoubleMoveBonus?.Invoke();
            
            // Bonus spécifiques par type de pièce
            switch (CurrentPiece.Category)
            {
                case PieceCategorie.Cavalier:
                    // Cavalier: +1 case de portée sur le prochain saut
                    Debug.Log("[TurnState] \ud83d\udca8 Cavalier: +1 case de portée bonus");
                    break;
                    
                case PieceCategorie.Pion:
                    // Soldat: +1 DEF temporaire
                    CurrentPiece.ApplyBuff(StatType.Defense, +1, 1);
                    Debug.Log("[TurnState] \ud83d\udca8 Soldat: +1 DEF temporaire");
                    break;
                    
                case PieceCategorie.Tour:
                    // Tour: Portée +2 cases
                    Debug.Log("[TurnState] \ud83d\udca8 Tour: +2 portée bonus");
                    break;
            }
        }
        
        // ========== UTILITAIRES ==========
        
        public bool HasAPRemaining() => CurrentAP > 0;
        public bool IsTurnFinished() => CurrentAP <= 0;
        public int GetAPSpent() => APUsedThisTurn;
        public List<ActionType> GetActionsPerformed() => new List<ActionType>(actionsPerformed);
    }
    
    /// <summary>
    /// Types d'actions possibles.
    /// </summary>
    public enum ActionType
    {
        Move,      // Coûte 1 AP
        Attack,    // Coûte 1 AP
        Special    // Coûte 1 AP (bonus action)
    }
}
```

---

## 3. GÉOMÉTRIE HEXAGONE - COORDONNÉES AXIALES

### 🧭 HexCoordinate.cs - Système de Coordonnées

```csharp
using UnityEngine;
using System.Collections.Generic;
using System;

namespace OctagonalChess.Movement
{
    /// <summary>
    /// HexCoordinate = Représente une case sur une grille hexagone (Coordonnées Axiales).
    /// 
    /// Système Axial (q, r):
    /// - q = axe horizontal
    /// - r = axe diagonale bas-gauche
    /// - s = axe diagonale haut-droite (calculé: s = -q - r)
    /// 
    /// Avantages:
    /// - Distances faciles à calculer
    /// - 6 directions cardinales simples
    /// - Ring/Spiral parcours naturels
    /// 
    /// Grille visuelle (q, r):
    ///         (0,0)  (1,0)  (2,0)
    ///       (0,1)  (1,1)  (2,1)
    ///    (0,2)  (1,2)  (2,2)
    /// </summary>
    [System.Serializable]
    public struct HexCoordinate : IEquatable<HexCoordinate>
    {
        public int q;  // Axe horizontal
        public int r;  // Axe diagonal
        
        // Calculé automatiquement
        public int s => -q - r;  // Axe diagonal opposé
        
        // ========== CONSTRUCTEURS ==========
        
        public HexCoordinate(int q, int r)
        {
            this.q = q;
            this.r = r;
        }
        
        // ========== DIRECTIONS CARDINALES ==========
        
        /// <summary>
        /// Les 6 directions du hexagone (axial).
        /// 
        /// Ordre: E, SE, SW, W, NW, NE
        /// </summary>
        private static readonly HexCoordinate[] Directions = new HexCoordinate[]
        {
            new HexCoordinate(1, 0),    // E (Est)
            new HexCoordinate(1, -1),   // SE (Sud-Est)
            new HexCoordinate(0, -1),   // SW (Sud-Ouest)
            new HexCoordinate(-1, 0),   // W (Ouest)
            new HexCoordinate(-1, 1),   // NW (Nord-Ouest)
            new HexCoordinate(0, 1)     // NE (Nord-Est)
        };
        
        /// <summary>
        /// Retourne la hex voisine dans une direction.
        /// </summary>
        public HexCoordinate GetNeighbor(int direction)
        {
            if (direction < 0 || direction >= 6)
                throw new ArgumentException($"Direction invalide: {direction}");
            
            var dir = Directions[direction];
            return new HexCoordinate(q + dir.q, r + dir.r);
        }
        
        /// <summary>
        /// Retourne les 6 voisins directs.
        /// </summary>
        public List<HexCoordinate> GetAllNeighbors()
        {
            var neighbors = new List<HexCoordinate>();
            for (int i = 0; i < 6; i++)
                neighbors.Add(GetNeighbor(i));
            return neighbors;
        }
        
        // ========== DIAGONALES (8 directions) ==========
        
        /// <summary>
        /// Retourne les 6 diagonales (distance 2).
        /// 
        /// Utile pour certaines pièces (Fou en chess classique).
        /// </summary>
        public List<HexCoordinate> GetDiagonalNeighbors()
        {
            var diagonals = new List<HexCoordinate>();
            
            // Les diagonales en hex = voisins du voisin
            for (int i = 0; i < 6; i++)
            {
                var neighbor = GetNeighbor(i);
                var nextDir = (i + 1) % 6;
                diagonals.Add(neighbor.GetNeighbor(nextDir));
            }
            
            return diagonals;
        }
        
        // ========== DISTANCES ==========
        
        /// <summary>
        /// Calcule la distance entre deux hex (nombre minimum de mouvements).
        /// </summary>
        public int DistanceTo(HexCoordinate other)
        {
            return (Math.Abs(q - other.q) + Math.Abs(r - other.r) + Math.Abs(s - other.s)) / 2;
        }
        
        /// <summary>
        /// Retourne tous les hex dans un rayon donné.
        /// </summary>
        public List<HexCoordinate> GetRing(int radius)
        {
            var results = new List<HexCoordinate>();
            
            for (int dq = -radius; dq <= radius; dq++)
            {
                for (int dr = Math.Max(-radius, -dq - radius); dr <= Math.Min(radius, -dq + radius); dr++)
                {
                    if (DistanceTo(new HexCoordinate(q + dq, r + dr)) == radius)
                        results.Add(new HexCoordinate(q + dq, r + dr));
                }
            }
            
            return results;
        }
        
        /// <summary>
        /// Retourne tous les hex jusqu'à un rayon (incluant le centre).
        /// </summary>
        public List<HexCoordinate> GetDisk(int radius)
        {
            var results = new List<HexCoordinate>();
            
            for (int dq = -radius; dq <= radius; dq++)
            {
                for (int dr = Math.Max(-radius, -dq - radius); dr <= Math.Min(radius, -dq + radius); dr++)
                {
                    results.Add(new HexCoordinate(q + dq, r + dr));
                }
            }
            
            return results;
        }
        
        /// <summary>
        /// Retourne la ligne entre deux hex.
        /// </summary>
        public List<HexCoordinate> LineTo(HexCoordinate target)
        {
            int distance = DistanceTo(target);
            if (distance == 0)
                return new List<HexCoordinate> { this };
            
            var results = new List<HexCoordinate>();
            
            for (int i = 0; i <= distance; i++)
            {
                float t = (float)i / distance;
                results.Add(LerpHex(this, target, t));
            }
            
            return results;
        }
        
        private static HexCoordinate LerpHex(HexCoordinate a, HexCoordinate b, float t)
        {
            int q = Mathf.RoundToInt(Mathf.Lerp(a.q, b.q, t));
            int r = Mathf.RoundToInt(Mathf.Lerp(a.r, b.r, t));
            return new HexCoordinate(q, r);
        }
        
        // ========== OVERRIDE ==========
        
        public override bool Equals(object obj)
        {
            return obj is HexCoordinate coord && Equals(coord);
        }
        
        public bool Equals(HexCoordinate other)
        {
            return q == other.q && r == other.r;
        }
        
        public override int GetHashCode()
        {
            return HashCode.Combine(q, r);
        }
        
        public static bool operator ==(HexCoordinate left, HexCoordinate right) => left.Equals(right);
        public static bool operator !=(HexCoordinate left, HexCoordinate right) => !left.Equals(right);
        
        public override string ToString() => $"({q}, {r})";
    }
}
```

---

## 4. MOTEUR DE MOUVEMENT - GETVALIDMOVES()

### 🏗 MovementEngine.cs - Coeur du Système

```csharp
using UnityEngine;
using System.Collections.Generic;
using System.Linq;
using OctagonalChess.Core;
using OctagonalChess.Gameplay;

namespace OctagonalChess.Movement
{
    /// <summary>
    /// MovementEngine = Calcule les mouvements valides pour une pièce.
    /// 
    /// Responsabilités:
    /// 1. Déterminer le type de mouvement (Slider, Leaper, etc.)
    /// 2. Calculer les cases atteignables
    /// 3. Vérifier les contraintes (ZOC, pièges, terrain)
    /// 4. Appliquer les modificateurs
    /// 5. SIMULER (ne pas modifier l'état du jeu)
    /// </summary>
    public class MovementEngine : MonoBehaviour
    {
        [Header("🎮 Références")]
        [SerializeField] private BoardManager boardManager;
        [SerializeField] private GridManager gridManager;
        [SerializeField] private TerrainManager terrainManager;
        
        [Header("⚡ Configuration")]
        [SerializeField] private float movementCostMultiplier = 1.0f;  // Malus terrain
        [SerializeField] private bool enableZOC = true;  // Zone de Contrôle active?
        [SerializeField] private bool enableTraps = true;  // Pièges actifs?
        
        // Cache pour performance
        private Dictionary<PieceInstance, List<HexCoordinate>> movementCache;
        private System.Nullable<HexCoordinate> cachedPiecePosition;
        
        private void Awake()
        {
            movementCache = new Dictionary<PieceInstance, List<HexCoordinate>>();
        }
        
        // ========== MÉTHODE PRINCIPALE ==========
        
        /// <summary>
        /// Retourne tous les mouvements valides pour une pièce.
        /// 
        /// SIMULÉ: ne modifie pas l'état du jeu.
        /// </summary>
        public List<HexCoordinate> GetValidMoves(
            PieceInstance piece,
            int actionPointsAvailable = 1)
        {
            if (piece == null || !piece.IsAlive)
                return new List<HexCoordinate>();
            
            // Utiliser cache si disponible
            if (movementCache.ContainsKey(piece))
                return movementCache[piece];
            
            var validMoves = new List<HexCoordinate>();
            
            // Déterminer le type de mouvement
            var moveType = DetermineMoveType(piece);
            
            // Calculer les mouvements selon le type
            validMoves = moveType switch
            {
                MoveType.Slider => GetSliderMoves(piece, actionPointsAvailable),
                MoveType.Leaper => GetLeaperMoves(piece, actionPointsAvailable),
                MoveType.Pawn => GetPawnMoves(piece, actionPointsAvailable),
                MoveType.King => GetKingMoves(piece, actionPointsAvailable),
                _ => new List<HexCoordinate>()
            };
            
            // Appliquer les contraintes globales
            validMoves = ApplyConstraints(piece, validMoves);
            
            // Cache
            movementCache[piece] = validMoves;
            
            return validMoves;
        }
        
        /// <summary>
        /// Détermine le type de mouvement d'une pièce.
        /// </summary>
        private MoveType DetermineMoveType(PieceInstance piece)
        {
            return piece.Category switch
            {
                PieceCategorie.Reine => MoveType.Slider,    // Tous les axes
                PieceCategorie.Tour => MoveType.Slider,     // 4 axes (cardinaux)
                PieceCategorie.Fou => MoveType.Slider,      // 4 diagonales
                PieceCategorie.Cavalier => MoveType.Leaper, // Saut en L
                PieceCategorie.Pion => MoveType.Pawn,       // Orientation
                PieceCategorie.Roi => MoveType.King,        // 1 case dans toute direction
                _ => MoveType.Slider
            };
        }
        
        /// <summary>
        /// Applique les contraintes (ZOC, pièges, terrain).
        /// </summary>
        private List<HexCoordinate> ApplyConstraints(
            PieceInstance piece,
            List<HexCoordinate> moves)
        {
            if (moves == null || moves.Count == 0)
                return moves;
            
            var filtered = new List<HexCoordinate>();
            
            foreach (var move in moves)
            {
                bool isValid = true;
                
                // VÉRIFIER ZOC
                if (enableZOC && !CanLeaveZOC(piece, move))
                    isValid = false;
                
                // VÉRIFIER PIÉGES
                if (enableTraps && terrainManager && terrainManager.HasTrap(move))
                {
                    // Les pièges sont valides mais affichés différemment
                    Debug.Log($"[MovementEngine] ⚠ Case piégée détectée: {move}");
                }
                
                // VÉRIFIER COLLISION
                if (boardManager.IsOccupied(move) && !IsEnemyAt(piece, move))
                    isValid = false;
                
                if (isValid)
                    filtered.Add(move);
            }
            
            return filtered;
        }
        
        private bool IsEnemyAt(PieceInstance piece, HexCoordinate pos)
        {
            var occupier = boardManager.GetPieceAt(pos);
            return occupier != null && occupier.IsAlive && occupier != piece;
        }
        
        // ========== UTILITAIRES ==========
        
        private bool CanLeaveZOC(PieceInstance piece, HexCoordinate target)
        {
            // Les Cavaliers ignorent la ZOC
            if (piece.Category == PieceCategorie.Cavalier)
                return true;
            
            // Vérifier si case actuelle est contrôlée par ennemi
            // (implémentation dans ZOCManager)
            return true;  // Placeholder
        }
        
        public void ClearCache()
        {
            movementCache.Clear();
        }
    }
    
    public enum MoveType
    {
        Slider,   // Se déplace en ligne (Reine, Tour, Fou)
        Leaper,   // Saute par-dessus (Cavalier)
        Pawn,     // Mouvement contraint (Soldat, Roi)
        King      // 1 case dans toute direction
    }
}
```

--- **[Suite dans partie 2...]**