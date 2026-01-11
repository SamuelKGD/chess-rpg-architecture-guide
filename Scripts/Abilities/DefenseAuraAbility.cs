using UnityEngine;

[CreateAssetMenu(fileName = "Ability_", menuName = "Chess RPG/Ability/Defense Aura", order = 10)]
public class DefenseAuraAbility : ScriptableObject, IAbility
{
    [SerializeField]
    private int defenseBonus = 5;

    public string AbilityName => "Aura de Défense";
    public string AbilityDescription => $"+{defenseBonus} Défense par tour";

    public void Execute(PieceController owner, PieceController target = null)
    {
        Debug.Log($"[Ability] {owner.name} active l'Aura de Défense!");
        owner.ModifyStats(defenseBonus: defenseBonus);
    }

    public bool CanExecute(PieceController owner) => true;
}
