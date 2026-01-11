using UnityEngine;

[CreateAssetMenu(fileName = "Modifier_", menuName = "Chess RPG/Modifier Data", order = 3)]
public class ModifierData : ScriptableObject
{
    [SerializeField]
    private string modifierName = "Unnamed Modifier";

    [SerializeField]
    private int attackBonus = 0;

    [SerializeField]
    private int defenseBonus = 0;

    [SerializeField]
    private int healthBonus = 0;

    [SerializeField]
    private int durationTurns = 0;

    [SerializeField]
    private bool canStack = true;

    public string ModifierName => modifierName;
    public int AttackBonus => attackBonus;
    public int DefenseBonus => defenseBonus;
    public int HealthBonus => healthBonus;
    public int DurationTurns => durationTurns;
    public bool CanStack => canStack;
}
