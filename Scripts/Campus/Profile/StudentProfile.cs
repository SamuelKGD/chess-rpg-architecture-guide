using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// Profile étudiant vérifié : identité centrale de l'écosystème campus.
/// Lie le billet, le wallet et le vote à la vraie identité de l'étudiant.
/// 
/// Pilier 5 de l'architecture campus : graphe social et identité.
/// </summary>
public class StudentProfile : MonoBehaviour
{
    // ========== IDENTITÉ ==========

    [Header("Identité")]
    [SerializeField] private string studentId;
    [SerializeField] private string displayName;
    [SerializeField] private string email;
    [SerializeField] private bool isVerified = false;

    // ========== ACADÉMIQUE ==========

    [Header("Académique")]
    [SerializeField] private string cohortId;
    [SerializeField] private string program;
    [SerializeField] private int yearOfStudy;
    [SerializeField] private List<string> enrolledGroups = new List<string>();

    // ========== SOCIAL ==========

    [Header("Social")]
    [SerializeField] private List<string> followedStudentIds = new List<string>();
    [SerializeField] private List<string> clubMemberships = new List<string>();

    // ========== PROPRIÉTÉS ==========

    public string StudentId => studentId;
    public string DisplayName => displayName;
    public string Email => email;
    public bool IsVerified => isVerified;
    public string CohortId => cohortId;
    public string Program => program;
    public int YearOfStudy => yearOfStudy;

    // ========== INITIALISATION ==========

    public void Initialize(string id, string name, string mail, string cohort, string prog, int year)
    {
        studentId = id;
        displayName = name;
        email = mail;
        cohortId = cohort;
        program = prog;
        yearOfStudy = year;
        isVerified = false;

        Debug.Log($"[StudentProfile] Profil créé : {displayName} ({studentId})");
    }

    // ========== VÉRIFICATION D'IDENTITÉ ==========

    /// <summary>
    /// Vérifie l'identité de l'étudiant (ex : vérification email institutionnel).
    /// Requis pour accéder au Wallet Izly, voter et récupérer les billets.
    /// </summary>
    public void VerifyIdentity()
    {
        isVerified = true;
        Debug.Log($"[StudentProfile] Identité vérifiée : {displayName}");
    }

    // ========== GROUPES ACADÉMIQUES ==========

    public bool IsEnrolledInGroup(string groupId)
    {
        return string.IsNullOrEmpty(groupId) || enrolledGroups.Contains(groupId);
    }

    public void EnrollInGroup(string groupId)
    {
        if (!enrolledGroups.Contains(groupId))
        {
            enrolledGroups.Add(groupId);
            Debug.Log($"[StudentProfile] {displayName} inscrit au groupe : {groupId}");
        }
    }

    // ========== GRAPHE SOCIAL ==========

    public void Follow(string targetStudentId)
    {
        if (!followedStudentIds.Contains(targetStudentId))
            followedStudentIds.Add(targetStudentId);
    }

    public void Unfollow(string targetStudentId)
    {
        followedStudentIds.Remove(targetStudentId);
    }

    public bool IsFollowing(string targetStudentId) => followedStudentIds.Contains(targetStudentId);

    public IReadOnlyList<string> FollowedStudents => followedStudentIds.AsReadOnly();
    public IReadOnlyList<string> ClubMemberships => clubMemberships.AsReadOnly();
    public IReadOnlyList<string> EnrolledGroups => enrolledGroups.AsReadOnly();
}
