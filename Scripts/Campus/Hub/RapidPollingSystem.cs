using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// Système de sondage rapide du Hub Démocratique.
/// Permet aux étudiants de voter en un swipe sur les décisions campus
/// (BDE, syndicats, CA) avec diffusion des résultats en temps réel dans le Feed.
/// 
/// Patterns : Strategy (IPoll), Observer (OnResultsUpdated, OnPollClosed)
/// </summary>
public class RapidPollingSystem : MonoBehaviour, IPoll
{
    // ========== DONNÉES DU SONDAGE ==========

    [SerializeField] private string pollId;
    [SerializeField] private string question;
    [SerializeField] private bool isAnonymous = true;
    [SerializeField] private float durationSeconds = 3600f;

    private List<PollOption> options = new List<PollOption>();
    private Dictionary<string, int> votesByStudent = new Dictionary<string, int>();
    private PollStatus status = PollStatus.Pending;
    private float remainingTime;

    // ========== ÉVÉNEMENTS (Observer Pattern) ==========

    /// <summary>Déclenché à chaque nouveau vote : (optionIndex, pourcentages actuels)</summary>
    public event System.Action<int, IReadOnlyDictionary<int, float>> OnResultsUpdated;

    /// <summary>Déclenché à la clôture : résultats finaux diffusés dans le Feed.</summary>
    public event System.Action<IPoll> OnPollClosed;

    // ========== IMPLÉMENTATION IPoll ==========

    public string PollId => pollId;
    public string Question => question;
    public IReadOnlyList<PollOption> Options => options.AsReadOnly();
    public PollStatus Status => status;
    public bool IsAnonymous => isAnonymous;

    // ========== CYCLE DE VIE ==========

    private void Update()
    {
        if (status != PollStatus.Active)
            return;

        remainingTime -= Time.deltaTime;
        if (remainingTime <= 0f)
            Close();
    }

    /// <summary>
    /// Initialise et active le sondage avec les options fournies.
    /// </summary>
    public void Open(string id, string pollQuestion, List<PollOption> pollOptions, bool anonymous = true, float duration = 3600f)
    {
        pollId = id;
        question = pollQuestion;
        options = pollOptions;
        isAnonymous = anonymous;
        durationSeconds = duration;
        remainingTime = durationSeconds;
        status = PollStatus.Active;

        Debug.Log($"[RapidPolling] Sondage ouvert : \"{question}\" ({options.Count} options)");
    }

    // ========== VOTE PAR SWIPE ==========

    /// <summary>
    /// Enregistre le vote d'un étudiant identifié.
    /// Un étudiant = un vote (garanti par son StudentId vérifié).
    /// </summary>
    public void CastVote(StudentProfile voter, int optionIndex)
    {
        if (!CanVote(voter))
        {
            Debug.LogWarning($"[RapidPolling] {voter.DisplayName} ne peut pas voter sur \"{question}\"");
            return;
        }

        if (optionIndex < 0 || optionIndex >= options.Count)
        {
            Debug.LogWarning($"[RapidPolling] Option invalide : {optionIndex}");
            return;
        }

        options[optionIndex].VoteCount++;
        votesByStudent[voter.StudentId] = optionIndex;

        var liveResults = GetLiveResults();
        OnResultsUpdated?.Invoke(optionIndex, liveResults);

        Debug.Log($"[RapidPolling] Vote de {(isAnonymous ? "anonyme" : voter.DisplayName)} → option {optionIndex} (\"{options[optionIndex].Label}\")");
    }

    /// <summary>
    /// Un étudiant peut voter s'il est vérifié, si le sondage est actif
    /// et s'il n'a pas encore voté.
    /// </summary>
    public bool CanVote(StudentProfile voter)
    {
        return status == PollStatus.Active
            && voter != null
            && voter.IsVerified
            && !votesByStudent.ContainsKey(voter.StudentId);
    }

    // ========== RÉSULTATS EN TEMPS RÉEL ==========

    /// <summary>
    /// Calcule les pourcentages actuels pour chaque option.
    /// </summary>
    public IReadOnlyDictionary<int, float> GetLiveResults()
    {
        int totalVotes = TotalVoteCount();
        var results = new Dictionary<int, float>();

        foreach (var option in options)
        {
            float percentage = totalVotes > 0
                ? (option.VoteCount / (float)totalVotes) * 100f
                : 0f;
            results[option.OptionIndex] = Mathf.Round(percentage);
        }

        return results;
    }

    /// <summary>
    /// Clôt le sondage et diffuse les résultats finaux via le Feed (Observer).
    /// </summary>
    public void Close()
    {
        if (status == PollStatus.Closed)
            return;

        status = PollStatus.Closed;
        OnPollClosed?.Invoke(this);

        Debug.Log($"[RapidPolling] Sondage \"{question}\" clôturé. {TotalVoteCount()} votes au total.");
        LogFinalResults();
    }

    // ========== UTILITAIRES ==========

    private int TotalVoteCount()
    {
        int total = 0;
        foreach (var option in options)
            total += option.VoteCount;
        return total;
    }

    private void LogFinalResults()
    {
        var results = GetLiveResults();
        foreach (var option in options)
        {
            results.TryGetValue(option.OptionIndex, out float pct);
            Debug.Log($"  [{option.Label}] → {option.VoteCount} votes ({pct}%)");
        }
    }

    public int TotalVotes => TotalVoteCount();
    public float RemainingTimeSeconds => remainingTime;
}
