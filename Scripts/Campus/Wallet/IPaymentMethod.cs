/// <summary>
/// Interface que toute méthode de paiement du Wallet Hybride doit implémenter.
/// Strategy Pattern : la carte bancaire et Izly sont interchangeables via un simple swipe.
/// </summary>
public interface IPaymentMethod
{
    string MethodName { get; }
    string MethodDescription { get; }
    float AvailableBalance { get; }
    bool IsActive { get; }

    /// <summary>
    /// Tente de débiter le montant spécifié.
    /// Retourne true si le paiement a été accepté.
    /// </summary>
    bool ProcessPayment(float amount, string merchantId, StudentProfile payer);

    /// <summary>
    /// Vérifie si le solde est suffisant pour le montant demandé.
    /// </summary>
    bool CanPay(float amount);

    /// <summary>
    /// Retourne le montant réel après application des réductions partenaires.
    /// </summary>
    float ApplyPartnerDiscount(float originalAmount, string merchantId, StudentProfile payer);
}

/// <summary>
/// Méthodes de paiement disponibles dans le Wallet Hybride.
/// </summary>
public enum PaymentMethodType
{
    /// <summary>Carte bancaire classique (CB).</summary>
    BankCard,
    /// <summary>Solde Izly (carte CROUS étudiant).</summary>
    Izly
}
