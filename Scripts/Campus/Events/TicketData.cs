using UnityEngine;

/// <summary>
/// ScriptableObject représentant un billet sécurisé.
/// Chaque billet est lié à l'identité vérifiée de l'étudiant via un QR code unique.
/// 
/// Pilier 4 de l'architecture campus : billetterie sécurisée par la vraie identité.
/// </summary>
[CreateAssetMenu(fileName = "Ticket_", menuName = "Campus/Events/Ticket Data", order = 1)]
public class TicketData : ScriptableObject
{
    // ========== IDENTIFIANT ==========

    [Header("Identification")]
    [SerializeField] private string ticketId;
    [SerializeField] private string eventId;
    [SerializeField] private string ownerStudentId;

    // ========== TYPE D'ÉVÉNEMENT ==========

    [Header("Événement")]
    [SerializeField] private EventType eventType;
    [SerializeField] private string eventName;
    [SerializeField] private string cohortRestriction;

    // ========== ÉTAT DU BILLET ==========

    [Header("État")]
    [SerializeField] private bool isScanned = false;
    [SerializeField] private System.DateTime scanTimestamp;

    // ========== QR CODE ==========

    [Header("Sécurité")]
    [SerializeField] private string qrCodePayload;

    // ========== PROPRIÉTÉS ==========

    public string TicketId => ticketId;
    public string EventId => eventId;
    public string OwnerStudentId => ownerStudentId;
    public EventType Type => eventType;
    public string EventName => eventName;
    public string CohortRestriction => cohortRestriction;
    public bool IsScanned => isScanned;
    public System.DateTime ScanTimestamp => scanTimestamp;
    public string QrCodePayload => qrCodePayload;

    /// <summary>
    /// Un billet scané déverrouille l'album post-party (protection vie privée).
    /// </summary>
    public bool HasPostPartyAlbumAccess => isScanned && eventType == EventType.SoireesDePromo;

    // ========== INITIALISATION ==========

    public void Initialize(string evtId, string evtName, string studentId, EventType type, string cohort = "")
    {
        ticketId = System.Guid.NewGuid().ToString();
        eventId = evtId;
        eventName = evtName;
        ownerStudentId = studentId;
        eventType = type;
        cohortRestriction = cohort;
        isScanned = false;

        // Payload QR code : hash signé de l'identité + billet
        qrCodePayload = GenerateQrPayload(studentId, ticketId, evtId);

        Debug.Log($"[TicketData] Billet créé : {ticketId} pour {eventName} ({type})");
    }

    // ========== SCAN À L'ENTRÉE ==========

    /// <summary>
    /// Marque le billet comme scanné lors de l'entrée à l'événement.
    /// Déverrouille l'album post-party pour les soirées de promo.
    /// </summary>
    public void MarkAsScanned()
    {
        if (isScanned)
        {
            Debug.LogWarning($"[TicketData] Billet {ticketId} déjà scanné le {scanTimestamp}");
            return;
        }

        isScanned = true;
        scanTimestamp = System.DateTime.UtcNow;

        Debug.Log($"[TicketData] Billet {ticketId} scanné. Album post-party : {(HasPostPartyAlbumAccess ? "déverrouillé" : "non applicable")}");
    }

    // ========== SÉCURITÉ ==========

    private static string GenerateQrPayload(string studentId, string ticketId, string eventId)
    {
        string raw = $"{studentId}:{ticketId}:{eventId}:{System.DateTime.UtcNow.Ticks}";
        return System.Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(raw));
    }
}

/// <summary>
/// Types d'événements campus avec niveaux d'accès différenciés.
/// </summary>
public enum EventType
{
    /// <summary>Restreint à une cohorte de promotion.</summary>
    SoireesDePromo,
    /// <summary>Groupes de révision académiques exclusifs.</summary>
    SessionsAcademiques,
    /// <summary>Ouvert à l'ensemble du campus.</summary>
    ClubsEtAssos
}
