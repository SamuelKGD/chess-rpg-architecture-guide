using UnityEngine;

[CreateAssetMenu(fileName = "Ability_", menuName = "Chess RPG/Ability/Berserk Rage", order = 10)]
public class BerserkRageAbility : ScriptableObject, IAbility
{
    [SerializeField]
    private int energyCost = 30;

    [SerializeField]
    private int attackBonus = 50;

    [SerializeField]
    private int durationTurns = 3;

    [SerializeField]
    private int cooldownTurns = 2;

    private int currentCooldown = 0;

    public string AbilityName => "Rage Berserk";
    public string AbilityDescription => $"Attaque +{attackBonus}% pendant {durationTurns} tours";

    public void Execute(PieceController owner, PieceController target = null)
    {
        if (!CanExecute(owner))
        {
            Debug.LogWarning($"Ne peut pas utiliser {AbilityName}!");
            return;
        }

        owner.ConsumeEnergy(energyCost);
        owner.ModifyStats(attackBonus: attackBonus);
        currentCooldown = cooldownTurns;

        Debug.Log($"[Ability] {owner.name} entre en Rage Berserk!");
    }

    public bool CanExecute(PieceController owner)
    {
        return owner.CurrentEnergy >= energyCost && currentCooldown <= 0;
    }

    public void DecrementCooldown()
    {
        if (currentCooldown > 0)
            currentCooldown--;
    }
}
