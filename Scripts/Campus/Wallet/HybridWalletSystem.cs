using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// Wallet hybride intégrant la carte bancaire (CB) et le solde Izly.
/// Un simple glissement de doigt suffit pour basculer entre les deux modes de paiement.
/// Le statut étudiant vérifié applique automatiquement les réductions partenaires (0 code promo).
/// 
/// Pilier 3 de l'architecture campus : paiement sans friction.
/// Patterns : Strategy (IPaymentMethod), Observer (OnPaymentProcessed, OnMethodSwitched)
/// </summary>
public class HybridWalletSystem : MonoBehaviour
{
    // ========== MÉTHODES DE PAIEMENT ==========

    private IPaymentMethod bankCard;
    private IPaymentMethod izlyBalance;
    private IPaymentMethod activeMethod;

    // ========== HISTORIQUE ==========

    private List<PaymentTransaction> transactionHistory = new List<PaymentTransaction>();

    // ========== ÉVÉNEMENTS (Observer Pattern) ==========

    /// <summary>Déclenché après chaque paiement : (transaction réussie/échouée)</summary>
    public event System.Action<PaymentTransaction> OnPaymentProcessed;

    /// <summary>Déclenché lors du switch CB ↔ Izly par swipe.</summary>
    public event System.Action<PaymentMethodType> OnMethodSwitched;

    // ========== INITIALISATION ==========

    public void Initialize(StudentProfile owner)
    {
        bankCard = new BankCardPayment(owner);
        izlyBalance = new IzlyPayment(owner);
        activeMethod = bankCard;

        Debug.Log($"[HybridWallet] Wallet initialisé pour {owner.DisplayName}. Mode actif : {activeMethod.MethodName}");
    }

    // ========== SWITCH PAR SWIPE ==========

    /// <summary>
    /// Bascule entre CB et Izly d'un simple glissement de doigt.
    /// </summary>
    public void SwitchPaymentMethod()
    {
        if (activeMethod == bankCard)
        {
            activeMethod = izlyBalance;
            OnMethodSwitched?.Invoke(PaymentMethodType.Izly);
            Debug.Log("[HybridWallet] Basculement → Izly");
        }
        else
        {
            activeMethod = bankCard;
            OnMethodSwitched?.Invoke(PaymentMethodType.BankCard);
            Debug.Log("[HybridWallet] Basculement → Carte Bancaire");
        }
    }

    /// <summary>
    /// Active directement une méthode de paiement spécifique.
    /// </summary>
    public void SetActiveMethod(PaymentMethodType type)
    {
        IPaymentMethod target = type == PaymentMethodType.BankCard ? bankCard : izlyBalance;

        if (activeMethod == target)
            return;

        activeMethod = target;
        OnMethodSwitched?.Invoke(type);
        Debug.Log($"[HybridWallet] Méthode active : {activeMethod.MethodName}");
    }

    // ========== PAIEMENT ==========

    /// <summary>
    /// Effectue un paiement avec la méthode active.
    /// Les réductions partenaires sont appliquées automatiquement grâce au statut étudiant vérifié.
    /// </summary>
    public PaymentTransaction Pay(float amount, string merchantId, StudentProfile payer)
    {
        float finalAmount = activeMethod.ApplyPartnerDiscount(amount, merchantId, payer);

        bool success = activeMethod.ProcessPayment(finalAmount, merchantId, payer);

        var transaction = new PaymentTransaction(
            merchantId: merchantId,
            amount: finalAmount,
            originalAmount: amount,
            method: activeMethod is BankCardPayment ? PaymentMethodType.BankCard : PaymentMethodType.Izly,
            success: success
        );

        transactionHistory.Add(transaction);
        OnPaymentProcessed?.Invoke(transaction);

        if (success)
            Debug.Log($"[HybridWallet] Paiement OK : {finalAmount:F2}€ chez {merchantId} via {activeMethod.MethodName}");
        else
            Debug.LogWarning($"[HybridWallet] Paiement refusé : solde insuffisant ({activeMethod.AvailableBalance:F2}€ disponible)");

        return transaction;
    }

    // ========== GETTERS ==========

    public IPaymentMethod ActiveMethod => activeMethod;
    public PaymentMethodType ActiveMethodType => activeMethod is BankCardPayment ? PaymentMethodType.BankCard : PaymentMethodType.Izly;
    public float BankCardBalance => bankCard.AvailableBalance;
    public float IzlyBalance => izlyBalance.AvailableBalance;
    public IReadOnlyList<PaymentTransaction> TransactionHistory => transactionHistory.AsReadOnly();
}

// ========== IMPLÉMENTATIONS IPaymentMethod ==========

/// <summary>
/// Paiement par carte bancaire classique (CB).
/// </summary>
public class BankCardPayment : IPaymentMethod
{
    private float balance;
    private StudentProfile owner;
    private static readonly Dictionary<string, float> partnerDiscounts = new Dictionary<string, float>
    {
        { "resto_u", 0.50f },
        { "librairie_campus", 0.10f },
        { "bde_shop", 0.15f }
    };

    public BankCardPayment(StudentProfile owner, float initialBalance = 500f)
    {
        this.owner = owner;
        balance = initialBalance;
    }

    public string MethodName => "Carte Bancaire";
    public string MethodDescription => "Paiement CB classique";
    public float AvailableBalance => balance;
    public bool IsActive => true;

    public bool ProcessPayment(float amount, string merchantId, StudentProfile payer)
    {
        if (!CanPay(amount))
            return false;

        balance -= amount;
        return true;
    }

    public bool CanPay(float amount) => balance >= amount;

    public float ApplyPartnerDiscount(float originalAmount, string merchantId, StudentProfile payer)
    {
        if (!payer.IsVerified)
            return originalAmount;

        if (partnerDiscounts.TryGetValue(merchantId, out float discount))
        {
            float discounted = originalAmount * (1f - discount);
            Debug.Log($"[BankCard] Réduction partenaire {discount * 100f}% appliquée chez {merchantId} → {discounted:F2}€");
            return discounted;
        }

        return originalAmount;
    }
}

/// <summary>
/// Paiement par solde Izly (carte CROUS étudiant).
/// </summary>
public class IzlyPayment : IPaymentMethod
{
    private float balance;
    private StudentProfile owner;
    private static readonly Dictionary<string, float> izlyPartnerDiscounts = new Dictionary<string, float>
    {
        { "resto_u", 0.68f },
        { "cafeteria", 0.20f }
    };

    public IzlyPayment(StudentProfile owner, float initialBalance = 50f)
    {
        this.owner = owner;
        balance = initialBalance;
    }

    public string MethodName => "Izly";
    public string MethodDescription => "Solde Izly CROUS";
    public float AvailableBalance => balance;
    public bool IsActive => owner.IsVerified;

    public bool ProcessPayment(float amount, string merchantId, StudentProfile payer)
    {
        if (!CanPay(amount) || !payer.IsVerified)
            return false;

        balance -= amount;
        return true;
    }

    public bool CanPay(float amount) => balance >= amount && owner.IsVerified;

    public float ApplyPartnerDiscount(float originalAmount, string merchantId, StudentProfile payer)
    {
        if (!payer.IsVerified)
            return originalAmount;

        if (izlyPartnerDiscounts.TryGetValue(merchantId, out float discount))
        {
            float discounted = originalAmount * (1f - discount);
            Debug.Log($"[Izly] Réduction partenaire {discount * 100f}% appliquée chez {merchantId} → {discounted:F2}€");
            return discounted;
        }

        return originalAmount;
    }
}

// ========== DONNÉES DE TRANSACTION ==========

/// <summary>
/// Enregistrement d'une transaction de paiement.
/// </summary>
[System.Serializable]
public class PaymentTransaction
{
    public string TransactionId;
    public string MerchantId;
    public float Amount;
    public float OriginalAmount;
    public PaymentMethodType Method;
    public bool Success;
    public System.DateTime Timestamp;

    public float DiscountApplied => OriginalAmount - Amount;
    public bool HadDiscount => DiscountApplied > 0.001f;

    public PaymentTransaction(string merchantId, float amount, float originalAmount, PaymentMethodType method, bool success)
    {
        TransactionId = System.Guid.NewGuid().ToString();
        MerchantId = merchantId;
        Amount = amount;
        OriginalAmount = originalAmount;
        Method = method;
        Success = success;
        Timestamp = System.DateTime.UtcNow;
    }
}
