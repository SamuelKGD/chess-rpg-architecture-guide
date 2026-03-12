using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// Système de billetterie sécurisée par l'identité vérifiée de l'étudiant.
/// Chaque billet est lié au profil étudiant via QR code unique.
/// L'album post-party est déverrouillé uniquement pour les billets scannés à l'entrée.
/// 
/// Pilier 4 de l'architecture campus.
/// Patterns : Observer (OnTicketIssued, OnTicketScanned, OnAlbumUnlocked)
/// </summary>
public class SecureTicketingSystem : MonoBehaviour
{
    // ========== REGISTRE DES BILLETS ==========

    private Dictionary<string, TicketData> ticketRegistry = new Dictionary<string, TicketData>();
    private Dictionary<string, List<string>> ticketsByEvent = new Dictionary<string, List<string>>();
    private Dictionary<string, List<string>> ticketsByStudent = new Dictionary<string, List<string>>();

    // ========== ÉVÉNEMENTS (Observer Pattern) ==========

    /// <summary>Déclenché à l'émission d'un billet.</summary>
    public event System.Action<TicketData> OnTicketIssued;

    /// <summary>Déclenché au scan d'un billet à l'entrée.</summary>
    public event System.Action<TicketData> OnTicketScanned;

    /// <summary>Déclenché lorsque l'album post-party est déverrouillé.</summary>
    public event System.Action<string, string> OnPostPartyAlbumUnlocked;  // (studentId, eventId)

    // ========== ÉMISSION DE BILLETS ==========

    /// <summary>
    /// Émet un billet pour un étudiant vérifié.
    /// Applique les restrictions de cohorte pour les soirées de promo.
    /// </summary>
    public TicketData IssueTicket(StudentProfile student, string eventId, string eventName, EventType eventType, string cohortRestriction = "")
    {
        if (!CanAttend(student, eventType, cohortRestriction))
        {
            Debug.LogWarning($"[Ticketing] {student.DisplayName} ne peut pas accéder à l'événement \"{eventName}\" ({eventType})");
            return null;
        }

        var ticket = ScriptableObject.CreateInstance<TicketData>();
        ticket.Initialize(eventId, eventName, student.StudentId, eventType, cohortRestriction);

        ticketRegistry[ticket.TicketId] = ticket;

        if (!ticketsByEvent.ContainsKey(eventId))
            ticketsByEvent[eventId] = new List<string>();
        ticketsByEvent[eventId].Add(ticket.TicketId);

        if (!ticketsByStudent.ContainsKey(student.StudentId))
            ticketsByStudent[student.StudentId] = new List<string>();
        ticketsByStudent[student.StudentId].Add(ticket.TicketId);

        OnTicketIssued?.Invoke(ticket);

        Debug.Log($"[Ticketing] Billet émis pour {student.DisplayName} → \"{eventName}\"");
        return ticket;
    }

    // ========== VÉRIFICATION D'ACCÈS ==========

    /// <summary>
    /// Vérifie si un étudiant peut accéder à un événement selon son type et sa cohorte.
    /// </summary>
    public bool CanAttend(StudentProfile student, EventType eventType, string cohortRestriction = "")
    {
        if (!student.IsVerified)
            return false;

        switch (eventType)
        {
            case EventType.SoireesDePromo:
                // Restreint à la cohorte de promotion de l'étudiant
                return string.IsNullOrEmpty(cohortRestriction) || student.CohortId == cohortRestriction;

            case EventType.SessionsAcademiques:
                // Réservé aux étudiants inscrits au groupe de révision
                return student.IsEnrolledInGroup(cohortRestriction);

            case EventType.ClubsEtAssos:
                // Ouvert à tous les étudiants vérifiés du campus
                return true;

            default:
                return false;
        }
    }

    // ========== SCAN À L'ENTRÉE ==========

    /// <summary>
    /// Scanne un billet par son QR code à l'entrée de l'événement.
    /// Déverrouille l'album post-party pour les soirées de promo.
    /// </summary>
    public bool ScanTicket(string ticketId)
    {
        if (!ticketRegistry.TryGetValue(ticketId, out TicketData ticket))
        {
            Debug.LogWarning($"[Ticketing] Billet introuvable : {ticketId}");
            return false;
        }

        if (ticket.IsScanned)
        {
            Debug.LogWarning($"[Ticketing] Billet {ticketId} déjà utilisé !");
            return false;
        }

        ticket.MarkAsScanned();
        OnTicketScanned?.Invoke(ticket);

        if (ticket.HasPostPartyAlbumAccess)
        {
            OnPostPartyAlbumUnlocked?.Invoke(ticket.OwnerStudentId, ticket.EventId);
            Debug.Log($"[Ticketing] Album post-party déverrouillé pour {ticket.OwnerStudentId} → {ticket.EventName}");
        }

        return true;
    }

    // ========== ALBUM POST-PARTY ==========

    /// <summary>
    /// Vérifie si un étudiant a accès à l'album post-party d'un événement.
    /// Protège la vie privée : uniquement pour les billets scannés à l'entrée.
    /// </summary>
    public bool HasPostPartyAlbumAccess(string studentId, string eventId)
    {
        if (!ticketsByStudent.TryGetValue(studentId, out var studentTickets))
            return false;

        foreach (var ticketId in studentTickets)
        {
            if (ticketRegistry.TryGetValue(ticketId, out TicketData ticket))
            {
                if (ticket.EventId == eventId && ticket.HasPostPartyAlbumAccess)
                    return true;
            }
        }

        return false;
    }

    // ========== STATISTIQUES ==========

    public int GetEventAttendanceCount(string eventId)
    {
        if (!ticketsByEvent.TryGetValue(eventId, out var eventTickets))
            return 0;

        int scanned = 0;
        foreach (var ticketId in eventTickets)
        {
            if (ticketRegistry.TryGetValue(ticketId, out TicketData ticket) && ticket.IsScanned)
                scanned++;
        }
        return scanned;
    }

    public IReadOnlyList<string> GetStudentTickets(string studentId)
    {
        return ticketsByStudent.TryGetValue(studentId, out var tickets)
            ? tickets.AsReadOnly()
            : new List<string>().AsReadOnly();
    }
}
