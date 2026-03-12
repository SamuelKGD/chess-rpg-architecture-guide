using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// Feed social chronologique du campus.
/// Reçoit et diffuse en temps réel les résultats des sondages Hub Démocratique,
/// les publications étudiantes et les mises à jour d'événements.
/// 
/// Pilier 1 de l'architecture campus : réseau social chronologique (Webtoon).
/// Patterns : Observer (OnFeedItemAdded), Component
/// </summary>
public class FeedSystem : MonoBehaviour
{
    // ========== ITEMS DU FEED ==========

    private List<FeedItem> feedItems = new List<FeedItem>();

    // ========== ÉVÉNEMENTS (Observer Pattern) ==========

    /// <summary>Déclenché à chaque nouvel item publié dans le Feed.</summary>
    public event System.Action<FeedItem> OnFeedItemAdded;

    // ========== PUBLICATION ==========

    /// <summary>
    /// Publie une mise à jour de résultats de sondage en temps réel dans le Feed.
    /// Appelé automatiquement par RapidPollingSystem via l'Observer Pattern.
    /// </summary>
    public void PublishPollResult(IPoll poll)
    {
        var results = poll.GetLiveResults();
        var item = new FeedItem(
            FeedItemType.PollResult,
            title: $"Résultats en direct : {poll.Question}",
            payload: BuildPollResultPayload(poll, results)
        );

        AddItem(item);
        Debug.Log($"[Feed] Résultats de sondage publiés : \"{poll.Question}\"");
    }

    /// <summary>
    /// Publie une publication étudiante dans le Feed.
    /// </summary>
    public void PublishStudentPost(StudentProfile author, string content, string mediaUrl = "")
    {
        var item = new FeedItem(
            FeedItemType.StudentPost,
            title: author.DisplayName,
            payload: content,
            authorId: author.StudentId,
            mediaUrl: mediaUrl
        );

        AddItem(item);
    }

    /// <summary>
    /// Publie une annonce d'événement campus dans le Feed.
    /// </summary>
    public void PublishEventAnnouncement(string eventName, EventType eventType, string description)
    {
        var item = new FeedItem(
            FeedItemType.EventAnnouncement,
            title: eventName,
            payload: description,
            tag: eventType.ToString()
        );

        AddItem(item);
        Debug.Log($"[Feed] Événement annoncé : \"{eventName}\" ({eventType})");
    }

    // ========== LECTURE ==========

    /// <summary>
    /// Retourne les derniers items du Feed dans l'ordre chronologique inverse.
    /// </summary>
    public IReadOnlyList<FeedItem> GetLatestItems(int count = 20)
    {
        int start = Mathf.Max(0, feedItems.Count - count);
        return feedItems.GetRange(start, feedItems.Count - start).AsReadOnly();
    }

    // ========== PRIVÉ ==========

    private void AddItem(FeedItem item)
    {
        feedItems.Add(item);
        OnFeedItemAdded?.Invoke(item);
    }

    private string BuildPollResultPayload(IPoll poll, IReadOnlyDictionary<int, float> results)
    {
        var sb = new System.Text.StringBuilder();
        foreach (var option in poll.Options)
        {
            results.TryGetValue(option.OptionIndex, out float pct);
            sb.AppendLine($"{option.Label} : {pct}%");
        }
        return sb.ToString();
    }

    public int ItemCount => feedItems.Count;
}

// ========== MODÈLE DE DONNÉES FEED ==========

/// <summary>
/// Item publié dans le Feed.
/// </summary>
[System.Serializable]
public class FeedItem
{
    public string ItemId;
    public FeedItemType Type;
    public string Title;
    public string Payload;
    public string AuthorId;
    public string MediaUrl;
    public string Tag;
    public System.DateTime Timestamp;

    public FeedItem(FeedItemType type, string title, string payload, string authorId = "", string mediaUrl = "", string tag = "")
    {
        ItemId = System.Guid.NewGuid().ToString();
        Type = type;
        Title = title;
        Payload = payload;
        AuthorId = authorId;
        MediaUrl = mediaUrl;
        Tag = tag;
        Timestamp = System.DateTime.UtcNow;
    }
}

/// <summary>
/// Types d'items publiables dans le Feed.
/// </summary>
public enum FeedItemType
{
    StudentPost,
    PollResult,
    EventAnnouncement,
    TicketingUpdate
}
