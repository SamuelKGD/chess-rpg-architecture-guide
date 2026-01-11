using UnityEngine;

/// <summary>
/// Interface que TOUTE compétence doit implémenter.
/// Strategy Pattern: chaque compétence = stratégie interchangeable
/// </summary>
public interface IAbility
{
    string AbilityName { get; }
    string AbilityDescription { get; }

    void Execute(PieceController owner, PieceController target = null);
    bool CanExecute(PieceController owner);
}
