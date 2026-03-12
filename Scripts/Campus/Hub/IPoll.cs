using System.Collections.Generic;

/// <summary>
/// Interface que tout sondage du Hub Démocratique doit implémenter.
/// Strategy Pattern : chaque type de vote = une stratégie interchangeable.
/// 
/// Utilisé pour les votes BDE, syndicats, CA et sondages rapides campus.
/// </summary>
public interface IPoll
{
    string PollId { get; }
    string Question { get; }
    IReadOnlyList<PollOption> Options { get; }
    PollStatus Status { get; }
    bool IsAnonymous { get; }

    /// <summary>
    /// Enregistre le vote d'un étudiant via swipe.
    /// </summary>
    void CastVote(StudentProfile voter, int optionIndex);

    /// <summary>
    /// Vérifie si l'étudiant peut voter (identité vérifiée, pas encore voté).
    /// </summary>
    bool CanVote(StudentProfile voter);

    /// <summary>
    /// Retourne les résultats en temps réel sous forme de pourcentages.
    /// </summary>
    IReadOnlyDictionary<int, float> GetLiveResults();

    /// <summary>
    /// Clôt le sondage et publie les résultats dans le Feed.
    /// </summary>
    void Close();
}

/// <summary>
/// Option d'un sondage (ex : "Artiste A", "Artiste B").
/// </summary>
[System.Serializable]
public class PollOption
{
    public int OptionIndex;
    public string Label;
    public string ImageUrl;
    public int VoteCount;

    public PollOption(int index, string label, string imageUrl = "")
    {
        OptionIndex = index;
        Label = label;
        ImageUrl = imageUrl;
        VoteCount = 0;
    }
}

/// <summary>
/// États possibles d'un sondage.
/// </summary>
public enum PollStatus
{
    Pending,
    Active,
    Closed
}
