# 🔡 Templates pour Créer 200+ Variétés de Pièces

## Vue d'Ensemble

Ce document contient des templates pour créer rapidement de nouvelles variétés de pièces sans code.

Chaque template définit :
- **Stats de base** (HP, ATK, DEF, vitesse)
- **Compétences** (abilities associées)
- **Type** (Soldier, Mage, Knight, etc.)
- **Visuel** (prefab à utiliser)

---

## Famille SOLDAT (50 variétés)

### Template 1: Soldat Basique
```
ID:                Soldier_001
Nom:               Soldat Basique
Type:              Soldier
Visuel:            Soldier_Base.prefab

Stats:
  Max Health:      100 HP
  Attack Power:    10 ATK
  Defense:         5 DEF
  Movement Speed:  1.0
  Attack Range:    1
  Critical:        10% (1.5x)

Compétences:
  - DefenseAura (passive)

Mouvement:
  Type:            Grid
  Range:           3 cases
  Can Jump:        Non
```

### Template 2: Soldat d'Elite
```
ID:                Soldier_002
Nom:               Soldat d'Elite
Type:              Soldier
Visuel:            Soldier_Elite.prefab

Stats:
  Max Health:      150 HP        ↑ +50%
  Attack Power:    15 ATK         ↑ +50%
  Defense:         8 DEF          ↑ +60%
  Movement Speed:  1.2
  Attack Range:    1
  Critical:        15% (1.5x)

Compétences:
  - DefenseAura (passive)
  - BerserkRage (active, Énergie: 30, Cooldown: 2)

Mouvement:
  Type:            Grid
  Range:           4 cases        ↑ +1
  Can Jump:        Non
```

### Template 3: Soldat Berserker
```
ID:                Soldier_003
Nom:               Soldat Berserker
Type:              Soldier
Visuel:            Soldier_Berserker.prefab

Stats:
  Max Health:      180 HP         ↑ +80%
  Attack Power:    22 ATK         ↑ +120%  (très offensif)
  Defense:         6 DEF          ↓ -40%   (peu de défense)
  Movement Speed:  1.4
  Attack Range:    1
  Critical:        25% (2.0x)     ↑ Critique élevé

Compétences:
  - BerserkRage (active, toujours dispo)
  - Rampage (active, frappe toutes les cibles adjacentes)

Mouvement:
  Type:            Grid
  Range:           4 cases
  Can Jump:        Oui (height: 0.8)
```

### Template 4: Soldat Paladin
```
ID:                Soldier_004
Nom:               Soldat Paladin
Type:              Soldier
Visuel:            Soldier_Paladin.prefab

Stats:
  Max Health:      120 HP         ↑ +20%
  Attack Power:    12 ATK         ↑ +20%
  Defense:         12 DEF         ↑ +140%  (très défensif)
  Movement Speed:  0.8            ↓ Lent
  Attack Range:    1
  Critical:        8% (1.5x)      ↓ Faible

Compétences:
  - DefenseAura (passive, +8 DEF)
  - HolyShield (active, cible ou auto)
  - Protect (active, réduit les dégâts des alliés)

Mouvement:
  Type:            Grid
  Range:           2 cases        ↓ Limité
  Can Jump:        Non
```

### Template 5-10: Variantes Équipement (dépëlacement selon niveau)
```
Soldat_Armé_Epée        (+30% ATK, -10% DEF)
Soldat_Armé_Bouclier    (-20% ATK, +30% DEF)
Soldat_Armé_Armure      (+20% DEF, -15% Speed)
Soldat_Léger            (-20% DEF, +30% Speed)
Soldat_Lourd             (+25% DEF, -30% Speed, +50% HP)
Soldat_Balancé           (Stats équilibrées)
```

### Template 11-50: Variantes Spéciales par Level
```
# Niveau 1 (basique)
Soldat_Niveau1        HP: 100, ATK: 10, DEF: 5

# Niveau 2
Soldat_Niveau2        HP: 120, ATK: 12, DEF: 7

# Niveau 3
Soldat_Niveau3        HP: 150, ATK: 15, DEF: 9

# ... jusqu'au Niveau 50
Soldat_Niveau50       HP: 500, ATK: 50, DEF: 40
```

---

## Famille MAGE (30 variétés)

### Template 1: Mage Basique
```
ID:                Mage_001
Nom:               Mage Basique
Type:              Mage
Visuel:            Mage_Base.prefab

Stats:
  Max Health:      60 HP          ↓ Fragile
  Attack Power:    15 ATK         Attaque magique
  Defense:         3 DEF          ↓ Très faible
  Movement Speed:  0.9
  Attack Range:    4              ↑ Portée élevée
  Critical:        12% (1.8x)

Compétences:
  - Fireball (active, dégâts AoE)
  - ManaShield (passive, réduit dégâts à partir de mana)

Mouvement:
  Type:            NavMesh       (plus fluide pour casters)
  Range:           3 cases
  Can Jump:        Non
```

### Template 2: Mage du Feu
```
ID:                Mage_002
Nom:               Mage du Feu
Type:              Mage
Visuel:            Mage_Fire.prefab

Stats:
  Max Health:      70 HP          ↑ +17%
  Attack Power:    20 ATK         ↑ +33% (spécializé)
  Defense:         2 DEF          ↓ Fragile
  Movement Speed:  0.8            ↓ Lent
  Attack Range:    4
  Critical:        18% (2.0x)     ↑ Bon pour dégâts bursts

Compétences:
  - Fireball (active, dégâts ++)
  - InfernoRage (active, multi-cibles)
  - ManaShield (passive)

Mouvement:
  Type:            NavMesh
  Range:           2 cases
  Can Jump:        Non
```

### Template 3: Mage de Glace
```
ID:                Mage_003
Nom:               Mage de Glace
Type:              Mage
Visuel:            Mage_Ice.prefab

Stats:
  Max Health:      65 HP
  Attack Power:    18 ATK         Moins que feu, plus que basique
  Defense:         5 DEF          ↑ Un peu plus de défense
  Movement Speed:  0.7
  Attack Range:    4
  Critical:        10% (1.5x)

Compétences:
  - IceSpear (active, dégâts + slow)
  - FrostAura (passive, défense +, vitesse ennemi -)
  - Blizzard (active, AoE massive, cooldown long)

Mouvement:
  Type:            NavMesh
  Range:           3 cases
  Can Jump:        Non
```

### Template 4-30: Variantes Éléments
```
Mage_Lumiere        (Healing focus)
Mage_Ombre          (Debuff focus)
Mage_Electricite    (Chain damage)
Mage_Nature         (DoT + Healing)
Mage_Metal          (Buff/Debuff stats)
Mage_Necromancien   (Minions, drain)
Mage_Archimage      (Ultimate power, lent)
Mage_Illusionniste  (Confusion, dodge)
... (+ 22 de plus)
```

---

## Famille KNIGHT (40 variétés)

### Template 1: Knight Standard
```
ID:                Knight_001
Nom:               Knight Standard
Type:              Knight
Visuel:            Knight_Base.prefab

Stats:
  Max Health:      120 HP         Balancé
  Attack Power:    16 ATK
  Defense:         10 DEF
  Movement Speed:  1.0
  Attack Range:    1
  Critical:        12% (1.5x)

Compétences:
  - Riposte (passive, contre-attaque)
  - SwordSlash (active, dégâts linéaires)

Mouvement:
  Type:            Grid
  Range:           3 cases
  Can Jump:        Oui (height: 0.5)
```

### Template 2: Knight Templar
```
ID:                Knight_002
Nom:               Knight Templar
Type:              Knight
Visuel:            Knight_Templar.prefab

Stats:
  Max Health:      140 HP         ↑ +17%
  Attack Power:    18 ATK         ↑ +12%
  Defense:         12 DEF         ↑ +20%
  Movement Speed:  1.1
  Attack Range:    1
  Critical:        14% (1.6x)

Compétences:
  - Riposte (passive)
  - SwordSlash (active)
  - HolyBless (active, buff alliés)

Mouvement:
  Type:            Grid
  Range:           3 cases
  Can Jump:        Oui
```

### Template 3-40: Variantes Armures/Stratégies
```
Knight_Noir        (Sombre, ATK ++, DEF -)
Knight_Lumineux    (Sacré, DEF ++, support)
Knight_Berserker   (Agressif, ATK +++, HP -)
Knight_Moine       (Défense, DEF ++, mouvement -)
Knight_Seul        (Solo focus, resist debuffs)
... (+ 35 de plus)
```

---

## Famille BOSS (10 variétés)

### Template 1: Boss Mineur
```
ID:                Boss_001
Nom:               Chef de Guilde
Type:              Boss
Visuel:            Boss_Minor.prefab

Stats:
  Max Health:      500 HP         ↑ ↑ ↑
  Attack Power:    40 ATK
  Defense:         20 DEF
  Movement Speed:  0.8
  Attack Range:    2
  Critical:        20% (2.0x)

Compétences:
  - PowerStrike (active, dégâts massifs)
  - Regeneration (passive, 10 HP par tour)
  - Intimidation (active, debuff alliés)

Mouvement:
  Type:            Grid
  Range:           5 cases
  Can Jump:        Oui (height: 1.0)
```

### Template 2: Boss Dragon
```
ID:                Boss_002
Nom:               Dragon Ancétral
Type:              Boss
Visuel:            Boss_Dragon.prefab

Stats:
  Max Health:      1000 HP        ↑ ↑ ↑ ↑
  Attack Power:    60 ATK
  Defense:         30 DEF
  Movement Speed:  0.6
  Attack Range:    3              Portée exceptionnelle
  Critical:        30% (2.5x)

Compétences:
  - DragonBreath (active, AoE massive)
  - FlightMode (active, invulnérabilité temporaire)
  - Regeneration (passive, 20 HP par tour)
  - Roar (active, stun zone)

Mouvement:
  Type:            Hybrid         (Vole + sol)
  Range:           6 cases
  Can Jump:        Oui (height: 3.0)
```

### Template 3-10: Boss Autres Archétypes
```
Boss_Liche         (Magic-heavy, many abilities)
Boss_Demon         (Aggressive, high ATK)
Boss_Angel         (Support, buffs minions)
Boss_Titan         (Massive, high HP/DEF)
Boss_Assassin      (Glass cannon, high crit)
Boss_Mage_Arch     (Ultimate caster)
Boss_Hydra         (Multiple heads, multi-attack)
Boss_Shadow_Lord   (Dark powers, debuffs)
```

---

## Création Rapide : Workflow 2 Minutes

### Étape 1: Dupliquer un asset existant (30 sec)
```
Assets/ScriptableObjects/Pieces/
Soldier_001 → Right-click → Duplicate → Soldier_002
```

### Étape 2: Modifier les stats (1 min)
```
Inspector ouvert sur Soldier_002:

Changer :
  - Name:          "Soldat d'Elite"
  - Max Health:    150        (100 → 150)
  - Attack Power:  15         (10 → 15)
  - Defense:       8          (5 → 8)
  - Visual Prefab: Soldier_Elite.prefab
```

### Étape 3: Assigner abilities (30 sec)
```
Drag & drop dans la liste Abilities :
  + DefenseAura
  + BerserkRage

Sauve auto-sauvegarder (Ctrl+S)
```

**Total : ~2 minutes par variété**

**200 variétés = ~400 minutes = ~6.5 heures sans interruption**

---

## Balance de Jeu : Principes Clés

### La formule de dégâts
```
damage_final = base_damage * (100 / (100 + defense)) * critical_multiplier
```

### Points de création
Chéquer que la somme des stats reste balancée :

```
HP + ATK + DEF + Speed = Points Totaux (ex: 150 pour unité niveau 1)

Exemples :
- Offensif:   HP 80, ATK 40, DEF 20, Speed 10 = 150 ✅
- Défensif:  HP 60, ATK 20, DEF 50, Speed 20 = 150 ✅
- Balancé:   HP 40, ATK 40, DEF 40, Speed 30 = 150 ✅
```

### Compétences et rayon
```
- Attack Range 1   = mélée
- Attack Range 2-3 = semi-distance
- Attack Range 4+  = distance (casters)

PlusAttack Range ⇔ Plus Mouvement limité
Moins Attack Range ⇔ Plus Mouvement rapide
```

---

## Checklist Avant de Fin

Pour chaque variété, vérifier :

- [ ] Nom unique (pas deux identiques)
- [ ] ID unique (system généré auto, mais vérifier)
- [ ] Visual Prefab assigné et existant
- [ ] Stats somme balancée
- [ ] Au moins 1 ability assignée
- [ ] Movement Range cohere avec Attack Range
- [ ] Type correspond à la famille

---

**Avec ce template, vous pouvez créer 200+ variétés rapidement et avec qualité constante** 🌟
