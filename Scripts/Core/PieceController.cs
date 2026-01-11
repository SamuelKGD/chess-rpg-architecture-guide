using UnityEngine;
using System.Collections.Generic;
using UnityEngine.Events;

/// <summary>
/// MonoBehaviour principal attaché à chaque pièce d'"e9checs RPG.
/// 
/// Responsabilités:
/// 1. Stocker une référence à PieceData (données immuables)
/// 2. Gérer l'état local (santé, énergie, buffs)
/// 3. Exécuter les compétences via AbilityManager
/// 4. Émettre des événements (OnDamaged, OnDied, etc.)
/// 5. Communiquer avec le plateau/board generator
/// 
/// Pattern: Component + Observer
/// </summary>
public class PieceController : MonoBehaviour
{
    // ========== DONNÉES ==========

    private PieceData pieceData;
    private PieceStats currentStats;

    // ========== SANTÉ & ÉNERGIE ==========

    private int currentHealth;
    public UnityEvent<int, int> OnDamageTaken;  // (damageReceived, healthRemaining)
    public UnityEvent OnDied;

    private int currentEnergy;
    private int maxEnergy = 100;

    // ========== ÉTATS ==========

    private bool isSelected = false;
    private bool isMoving = false;
    private bool isDead = false;
    private Vector2Int gridPosition = Vector2Int.zero;

    // ========== SYSTÈME DE COMPÉTENCES ==========

    private AbilityManager abilityManager;

    // ========== MODIFICATEURS ==========

    private List<ActiveModifier> activeModifiers = new List<ActiveModifier>();

    // ========== CACHE COMPOSANTS ==========

    private Transform visualTransform;
    private Renderer visualRenderer;
    private Animator animator;

    // ========== INITIALISATION ==========

    public void Initialize(PieceData data, int gridX, int gridY, Tile boardTile = null)
    {
        pieceData = data;
        gridPosition = new Vector2Int(gridX, gridY);

        currentStats = data.GetStats();
        currentHealth = currentStats.maxHealth;
        currentEnergy = maxEnergy;

        // Instantier le visuel
        if (data.VisualPrefab != null)
        {
            GameObject visualGO = Instantiate(
                data.VisualPrefab,
                transform.position + data.VisualOffset,
                Quaternion.identity,
                transform
            );

            visualGO.transform.localScale = data.VisualScale;
            visualTransform = visualGO.transform;
            visualRenderer = visualGO.GetComponent<Renderer>();
            animator = visualGO.GetComponent<Animator>();
        }

        // Initialiser AbilityManager
        abilityManager = new AbilityManager(this);
        foreach (var abilityData in data.Abilities)
        {
            if (abilityData.AbilityImplementation is IAbility ability)
            {
                abilityManager.AddAbility(ability);
            }
        }

        // Appliquer les modificateurs de base
        foreach (var mod in data.Modifiers)
        {
            ApplyModifier(mod, 0);
        }

        gameObject.name = $"{data.PieceName}_{gridX}_{gridY}";

        Debug.Log($"[PieceController] Initialisé: {gameObject.name} ({currentHealth} HP)");
    }

    private void Start()
    {
        if (visualRenderer == null)
            visualRenderer = GetComponent<Renderer>();

        if (animator == null)
            animator = GetComponent<Animator>();
    }

    // ========== SANTÉ & DÉGÂTS ==========

    public void TakeDamage(int baseDamage, PieceController attacker = null)
    {
        if (isDead)
            return;

        float damageMultiplier = 100f / (100f + currentStats.defense);
        int actualDamage = Mathf.Max(1, Mathf.RoundToInt(baseDamage * damageMultiplier));

        foreach (var mod in activeModifiers)
        {
            if (mod.damageReductionPercent > 0)
            {
                actualDamage = Mathf.RoundToInt(actualDamage * (1f - mod.damageReductionPercent / 100f));
            }
        }

        currentHealth = Mathf.Max(0, currentHealth - actualDamage);

        OnDamageTaken?.Invoke(actualDamage, currentHealth);

        TriggerDamageAnimation();

        Debug.Log($"[Combat] {gameObject.name} a reçu {actualDamage} dégâts. PV: {currentHealth}/{currentStats.maxHealth}");

        if (currentHealth <= 0)
        {
            Die(attacker);
        }
    }

    public void Heal(int amount)
    {
        if (isDead)
            return;

        int oldHealth = currentHealth;
        currentHealth = Mathf.Min(currentStats.maxHealth, currentHealth + amount);
        int actualHealing = currentHealth - oldHealth;

        Debug.Log($"[Healing] {gameObject.name} guéri de {actualHealing} PV. Santé: {currentHealth}/{currentStats.maxHealth}");
    }

    private void Die(PieceController killer = null)
    {
        isDead = true;
        OnDied?.Invoke();

        TriggerDeathAnimation();

        if (TryGetComponent<Collider>(out var collider))
            collider.enabled = false;

        animator?.SetTrigger("Death");

        Debug.Log($"[Death] {gameObject.name} a été vaincu!");

        Destroy(gameObject, 2f);
    }

    // ========== ÉNERGIE ==========

    public void ConsumeEnergy(int cost)
    {
        currentEnergy = Mathf.Max(0, currentEnergy - cost);
        Debug.Log($"[Energy] {gameObject.name} a consommé {cost} énergie. Restante: {currentEnergy}/{maxEnergy}");
    }

    public void RestoreEnergy(int amount)
    {
        currentEnergy = Mathf.Min(maxEnergy, currentEnergy + amount);
    }

    public int CurrentEnergy => currentEnergy;

    // ========== COMPÉTENCES ==========

    public void ExecuteAbility(int abilityIndex, PieceController target = null)
    {
        abilityManager.ExecuteAbility(abilityIndex, target);
    }

    public IAbility GetAbility(int index) => abilityManager.GetAbility(index);
    public int AbilityCount => abilityManager.AbilityCount;

    // ========== MODIFICATEURS (BUFFS/DEBUFFS) ==========

    public void ApplyModifier(ModifierData modifier, int durationTurns = 0)
    {
        var activeMod = new ActiveModifier(modifier, durationTurns);
        activeModifiers.Add(activeMod);

        currentStats.attackPower += modifier.AttackBonus;
        currentStats.defense += modifier.DefenseBonus;
        currentStats.maxHealth += modifier.HealthBonus;

        if (modifier.HealthBonus > 0)
        {
            currentHealth += modifier.HealthBonus;
        }

        Debug.Log($"[Modifier] {gameObject.name} a reçu le buff: {modifier.ModifierName}");
    }

    public void ApplyDamageReduction(int reductionPercent, int durationTurns)
    {
        var mod = new ActiveModifier(reductionPercent, durationTurns);
        activeModifiers.Add(mod);

        Debug.Log($"[Modifier] {gameObject.name} a une réduction de {reductionPercent}% des dégâts");
    }

    public void UpdateModifiers()
    {
        activeModifiers.RemoveAll(m => m.DecrementDuration() <= 0);
    }

    public void ModifyStats(int? healthBonus = null, int? attackBonus = null, int? defenseBonus = null)
    {
        if (healthBonus.HasValue)
            currentStats.maxHealth += healthBonus.Value;
        if (attackBonus.HasValue)
            currentStats.attackPower += attackBonus.Value;
        if (defenseBonus.HasValue)
            currentStats.defense += defenseBonus.Value;
    }

    // ========== ÉTATS ==========

    public void SetSelected(bool selected)
    {
        isSelected = selected;
        if (visualRenderer != null)
        {
            visualRenderer.material.color = isSelected ? Color.yellow : Color.white;
        }
    }

    public void SetMoving(bool moving)
    {
        isMoving = moving;
        if (animator != null)
        {
            animator.SetBool("IsMoving", isMoving);
        }
    }

    public bool IsSelected => isSelected;
    public bool IsMoving => isMoving;
    public bool IsDead => isDead;
    public Vector2Int GridPosition => gridPosition;

    // ========== ANIMATIONS ==========

    private void TriggerDamageAnimation()
    {
        if (animator != null)
            animator.SetTrigger("TakeDamage");

        StartCoroutine(FlashEffect(Color.red, 0.2f));
    }

    private void TriggerDeathAnimation()
    {
        if (animator != null)
            animator.SetTrigger("Death");
    }

    private System.Collections.IEnumerator FlashEffect(Color flashColor, float duration)
    {
        if (visualRenderer == null)
            yield break;

        Color originalColor = visualRenderer.material.color;
        visualRenderer.material.color = flashColor;

        yield return new WaitForSeconds(duration);

        visualRenderer.material.color = originalColor;
    }

    // ========== GETTERS ==========

    public int GetCurrentHealth() => currentHealth;
    public int GetMaxHealth() => currentStats.maxHealth;
    public int GetAttackPower() => currentStats.attackPower;
    public int GetDefense() => currentStats.defense;
    public PieceData GetPieceData() => pieceData;

    // ========== DEBUG ==========

    private void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(transform.position, currentStats.attackRange);
    }
}

public class ActiveModifier
{
    public ModifierData modifier;
    public int remainingTurns;
    public int damageReductionPercent = 0;

    public ActiveModifier(ModifierData mod, int duration)
    {
        modifier = mod;
        remainingTurns = duration;
    }

    public ActiveModifier(int damageReduction, int duration)
    {
        damageReductionPercent = damageReduction;
        remainingTurns = duration;
    }

    public int DecrementDuration()
    {
        if (remainingTurns > 0)
            remainingTurns--;
        return remainingTurns;
    }
}