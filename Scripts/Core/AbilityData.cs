using UnityEngine;

[System.Serializable]
public class AbilityData
{
    [SerializeField]
    private ScriptableObject abilityImplementation;

    [SerializeField]
    private int energyCost = 10;

    [SerializeField]
    private int cooldownTurns = 1;

    [TextArea(2, 4)]
    [SerializeField]
    private string abilityDescription = "";

    public ScriptableObject AbilityImplementation => abilityImplementation;
    public int EnergyCost => energyCost;
    public int CooldownTurns => cooldownTurns;
    public string AbilityDescription => abilityDescription;
}
