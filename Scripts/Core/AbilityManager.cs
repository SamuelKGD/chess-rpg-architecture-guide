using UnityEngine;
using System.Collections.Generic;

public class AbilityManager
{
    private PieceController owner;
    private List<IAbility> abilities = new List<IAbility>();

    public AbilityManager(PieceController owner)
    {
        this.owner = owner;
    }

    public void AddAbility(IAbility ability)
    {
        abilities.Add(ability);
        Debug.Log($"[AbilityMgr] Compétence {ability.AbilityName} ajoutée");
    }

    public void ExecuteAbility(int index, PieceController target = null)
    {
        if (index < 0 || index >= abilities.Count)
        {
            Debug.LogWarning($"Index invalide: {index}");
            return;
        }

        IAbility ability = abilities[index];
        ability.Execute(owner, target);
    }

    public IAbility GetAbility(int index) => abilities[index];
    public int AbilityCount => abilities.Count;
}
