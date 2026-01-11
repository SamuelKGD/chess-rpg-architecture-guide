using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// ScriptableObject qui contient TOUTES les données d'une pièce d'échecs RPG.
/// 
/// Responsabilités:
/// 1. Stocker les données de base (ID, nom, description)
/// 2. Stocker les stats (PV, ATK, DEF, etc.)
/// 3. Référencer le Prefab visuel
/// 4. Stocker les compétences (abilities)
/// 5. Stocker les modificateurs (buffs/debuffs)
/// 
/// ❌ PAS DE LOGIQUE - Juste des données brutes
/// 
/// Exemple de création:
/// Right-click dans Assets → Create → Piece Data → Soldier Basic
/// 
/// Pattern: Repository Pattern - Une instance = une "recette" réutilisable
/// Plusieurs GameObject peuvent référencer la même PieceData
/// </summary>
[CreateAssetMenu(fileName = "Piece_", menuName = "Chess RPG/Piece Data", order = 1)]
public class PieceData : ScriptableObject
{
    // ========== DONNÉES DE BASE ==========

    [Header("Identité")]

    [SerializeField]
    private string pieceID = "piece_" + System.Guid.NewGuid().ToString().Substring(0, 8);

    [SerializeField]
    private string pieceName = "Unknown Piece";

    [TextArea(3, 6)]
    [SerializeField]
    private string description = "No description";

    [SerializeField]
    private PieceType pieceType = PieceType.Soldier;

    [Header("Visuel")]

    [SerializeField]
    private GameObject visualPrefab;

    [SerializeField]
    private Vector3 visualScale = Vector3.one;

    [SerializeField]
    private Vector3 visualOffset = Vector3.zero;

    // ========== STATISTIQUES ==========

    [Header("Stats de Base")]

    [SerializeField]
    [Range(1, 500)]
    private int maxHealth = 100;

    [SerializeField]
    [Range(1, 100)]
    private int attackPower = 10;

    [SerializeField]
    [Range(0, 100)]
    private int defense = 5;

    [SerializeField]
    [Range(0.5f, 10f)]
    private float movementSpeed = 1f;

    [SerializeField]
    [Range(1, 8)]
    private int attackRange = 1;

    [Header("Stats Avancées")]

    [SerializeField]
    [Range(0, 100)]
    private int criticalChance = 10;

    [SerializeField]
    [Range(1f, 3f)]
    private float criticalMultiplier = 1.5f;

    [SerializeField]
    [Range(0, 50)]
    private int healthRegenPerTurn = 0;

    // ========== COMPÉTENCES & COMPORTEMENTS ==========

    [Header("Compétences")]

    [SerializeField]
    private List<AbilityData> abilities = new List<AbilityData>();

    [SerializeField]
    private List<ModifierData> modifiers = new List<ModifierData>();

    // ========== MOUVEMENT & TACTIQUE ==========

    [Header("Mouvement")]

    [SerializeField]
    private MovementType movementType = MovementType.Grid;

    [SerializeField]
    [Range(1, 8)]
    private int movementRange = 3;

    [SerializeField]
    private bool canJump = false;

    [SerializeField]
    private float jumpHeight = 0.5f;

    // ========== PROPRIÉTÉS PUBLIQUES (RO après init) ==========

    public string PieceID => pieceID;
    public string PieceName => pieceName;
    public string Description => description;
    public PieceType PieceType => pieceType;

    public GameObject VisualPrefab => visualPrefab;
    public Vector3 VisualScale => visualScale;
    public Vector3 VisualOffset => visualOffset;

    public int MaxHealth => maxHealth;
    public int AttackPower => attackPower;
    public int Defense => defense;
    public float MovementSpeed => movementSpeed;
    public int AttackRange => attackRange;

    public int CriticalChance => criticalChance;
    public float CriticalMultiplier => criticalMultiplier;
    public int HealthRegenPerTurn => healthRegenPerTurn;

    public List<AbilityData> Abilities => new List<AbilityData>(abilities);
    public List<ModifierData> Modifiers => new List<ModifierData>(modifiers);

    public MovementType MovementType => movementType;
    public int MovementRange => movementRange;
    public bool CanJump => canJump;
    public float JumpHeight => jumpHeight;

    // ========== MÉTHODES UTILITAIRES ==========

    public PieceStats GetStats()
    {
        return new PieceStats
        {
            maxHealth = this.maxHealth,
            attackPower = this.attackPower,
            defense = this.defense,
            movementSpeed = this.movementSpeed,
            attackRange = this.attackRange,
            criticalChance = this.criticalChance,
            criticalMultiplier = this.criticalMultiplier,
            healthRegenPerTurn = this.healthRegenPerTurn,
            movementRange = this.movementRange
        };
    }

    public PieceStats GetModifiedStats(params ModifierData[] mods)
    {
        PieceStats stats = GetStats();

        foreach (var mod in mods)
        {
            stats.attackPower += mod.AttackBonus;
            stats.defense += mod.DefenseBonus;
            stats.maxHealth += mod.HealthBonus;
        }

        return stats;
    }

    private void OnValidate()
    {
        if (maxHealth < 1) maxHealth = 1;
        if (attackPower < 1) attackPower = 1;
        if (defense < 0) defense = 0;
    }
}

// ========== TYPES & ENUMS ==========

public enum PieceType
{
    Soldier,
    Knight,
    Bishop,
    Rook,
    Queen,
    King,
    Mage,
    Archer,
    Tank,
    Support,
    Boss
}

public enum MovementType
{
    Grid,
    NavMesh,
    Hybrid
}

public struct PieceStats
{
    public int maxHealth;
    public int attackPower;
    public int defense;
    public float movementSpeed;
    public int attackRange;
    public int criticalChance;
    public float criticalMultiplier;
    public int healthRegenPerTurn;
    public int movementRange;
}