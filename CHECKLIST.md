# 📝 Checklist de Développement

---

## 🚀 Super-App Étudiante — EduMarket

### Phase 1 : Architecture & Base de données
- [x] Créer `TECH_SPEC.md` avec les choix techniques (Flutter + Supabase + Stripe Connect)
- [x] Définir le schéma DB PostgreSQL (`users`, `vendors`, `catalog`, `orders`, `sub_orders`, `order_items`)
- [x] Implémenter Row Level Security (RLS) pour chaque table
- [x] Concevoir la stratégie d'authentification (regex email + OTP Supabase)
- [x] Créer la structure Clean Architecture (`core/`, `domain/`, `data/`, `presentation/`)

### Phase 2 : Core Features (Frontend)
- [x] Écran `RegisterScreen` avec validation email étudiant bloquante
- [x] Écran `OtpVerificationScreen` (code OTP 6 chiffres avec countdown renvoi)
- [x] Dashboard `HubDashboardScreen` (codes promo statiques + raccourcis catégories)
- [x] `VendorListScreen` avec filtres par catégorie (Food, Tech, Papeterie)
- [x] `CartScreen` panier multi-vendeurs (items de sources différentes)
- [x] `CartBloc` — State Management BLoC pour le panier

### Phase 3 : Logique Métier & Edge Functions
- [x] Edge Function `validate-order` (vérif. stock + promo + Stripe PaymentIntent)
- [x] Edge Function `delivery-fee` (calcul dynamique distance Haversine)
- [x] Edge Function `dispatch-order` (Stripe Connect transfer + Stuart API)

### Phase 4 : Tests
- [x] Tests unitaires `email_validator_test.dart` (validation email + CartEntity)
- [ ] Tests BLoC (`CartBloc` avec `bloc_test`)
- [ ] Tests d'intégration Edge Functions (Deno test)

### Phase 5 : À valider avant génération du code principal
- [ ] ✅ Confirmer stack technique dans `TECH_SPEC.md`
- [ ] Implémenter `data/` layer (Supabase datasources + repository implémentations)
- [ ] Connecter les BLoCs aux écrans (injection via `get_it`)
- [ ] Ajouter navigation (`go_router`)
- [ ] Intégrer Stripe Flutter SDK pour le paiement

---

## Chess RPG Architecture Guide

## Phase 1 : Setup du Projet

### Création de la Structure de Dossiers
- [ ] Créer `Assets/Scripts/Core/`
- [ ] Créer `Assets/Scripts/Abilities/`
- [ ] Créer `Assets/Scripts/Systems/`
- [ ] Créer `Assets/Scripts/AI/`
- [ ] Créer `Assets/ScriptableObjects/Pieces/`
- [ ] Créer `Assets/ScriptableObjects/Abilities/`
- [ ] Créer `Assets/ScriptableObjects/Modifiers/`
- [ ] Créer `Assets/Prefabs/Visuals/`
- [ ] Créer `Assets/Materials/`
- [ ] Créer `Documentation/`

### Imports de Scripts
- [ ] Copier `PieceData.cs` dans Core
- [ ] Copier `PieceController.cs` dans Core
- [ ] Copier `AbilityManager.cs` dans Core
- [ ] Copier `AbilityData.cs` dans Core
- [ ] Copier `ModifierData.cs` dans Core
- [ ] Copier `IAbility.cs` dans Abilities
- [ ] Copier `DefenseAuraAbility.cs` dans Abilities
- [ ] Copier `BerserkRageAbility.cs` dans Abilities

---

## Phase 2 : Création des Assets de Base

### Création des Materials
- [ ] Créer Material pour Soldier (blanc/crème)
- [ ] Créer Material pour Mage (bleu/violet)
- [ ] Créer Material pour Knight (gris/métal)
- [ ] Créer Material pour Boss (or/rouille)

### Création des Prefabs Visuels
- [ ] Créer Soldier_Base.prefab (Cube + Material)
- [ ] Créer Mage_Base.prefab (Pyramide + Material)
- [ ] Créer Knight_Base.prefab (Cube haute + Material)
- [ ] Créer Boss_Base.prefab (Sphere grande + Material)
- [ ] Vérifier que tous ont Collider
- [ ] Vérifier que tous ont Renderer
- [ ] Vérifier que tous ont scale standard (1,1,1)

### Création des Abilities Globales
- [ ] Right-click → Create → Ability → Defense Aura
- [ ] Configurer : Name, Stats, Description
- [ ] Right-click → Create → Ability → Berserk Rage
- [ ] Configurer : Energy cost, Cooldown, Bonus ATK
- [ ] Right-click → Create → Ability → Holy Shield
- [ ] Configurer : Energy cost, Damage reduction
- [ ] (Créer 10-20 abilities de base pour démarrer)

---

## Phase 3 : Création des Pièces Template

### Famille Soldier (10 variantes pour tester)
- [ ] Soldier_Basic (100 HP, 10 ATK, 5 DEF, DefenseAura)
- [ ] Soldier_Elite (150 HP, 15 ATK, 8 DEF, DefenseAura + BerserkRage)
- [ ] Soldier_Berserker (180 HP, 22 ATK, 6 DEF, BerserkRage + Rampage)
- [ ] Soldier_Paladin (120 HP, 12 ATK, 12 DEF, HolyShield + Protect)
- [ ] Soldier_ArmedSword (130 HP, 16 ATK, 6 DEF, SwordSlash)
- [ ] Soldier_ArmedShield (110 HP, 10 ATK, 14 DEF, BlockingStance)
- [ ] Soldier_ArmedHeavy (140 HP, 14 ATK, 12 DEF, HeavyBlast)
- [ ] Soldier_Light (80 HP, 12 ATK, 4 DEF, Dash + Sprint)
- [ ] Soldier_Ranger (90 HP, 14 ATK, 6 DEF, ArrowShot)
- [ ] Soldier_Tank (160 HP, 8 ATK, 18 DEF, Taunt)

### Famille Mage (5 variantes pour tester)
- [ ] Mage_Fire (70 HP, 20 ATK, 3 DEF, Fireball)
- [ ] Mage_Ice (65 HP, 18 ATK, 5 DEF, IceSpear)
- [ ] Mage_Light (75 HP, 15 ATK, 4 DEF, Healing)
- [ ] Mage_Dark (70 HP, 22 ATK, 2 DEF, Drain)
- [ ] Mage_Balanced (70 HP, 18 ATK, 4 DEF, MultiCast)

### Famille Knight (5 variantes pour tester)
- [ ] Knight_Standard (120 HP, 16 ATK, 10 DEF, SwordSlash)
- [ ] Knight_Templar (140 HP, 18 ATK, 12 DEF, HolyBless)
- [ ] Knight_Dark (130 HP, 20 ATK, 9 DEF, DeathStrike)
- [ ] Knight_Holy (120 HP, 14 ATK, 14 DEF, DivineBless)
- [ ] Knight_Aggressive (100 HP, 24 ATK, 8 DEF, Charge)

### Boss (1 pour test)
- [ ] Boss_MinorChief (500 HP, 40 ATK, 20 DEF, PowerStrike + Regeneration)

**Total créé : ~20 pieces variantes pour tester l'architecture**

---

## Phase 4 : Tests Unitaires

### Tests Sanité
- [ ] Vérifier que TakeDamage() réduit currentHealth
- [ ] Vérifier que défense applique réduction
- [ ] Vérifier que muerte déclenche OnDied event
- [ ] Vérifier que Heal() augmente currentHealth (max = maxHealth)
- [ ] Vérifier que currentHealth ne va pas négatif

### Tests Abilities
- [ ] Vérifier que Execute() appelle la logique de l'ability
- [ ] Vérifier que CanExecute() valide conditions
- [ ] Vérifier que ConsumeEnergy() fonctionne
- [ ] Vérifier que Cooldown se décrémente

### Tests Modificateurs
- [ ] Vérifier que ApplyModifier() applique stats
- [ ] Vérifier que UpdateModifiers() décrémente durations
- [ ] Vérifier que modificateurs expirés sont retirés
- [ ] Vérifier que stacking fonctionne (si enabled)

### Tests Events
- [ ] Vérifier que OnDamageTaken est émis
- [ ] Vérifier que OnDied est émis
- [ ] Vérifier que OnModifierApplied est émis
- [ ] Vérifier que listeners reçoivent les events

---

## Phase 5 : Integration Plateau

### BoardGenerator Integration
- [ ] Charger les 20 pieces variantes en Resources
- [ ] Générer plateau avec 8x8 tiles
- [ ] Instancier PieceController pour chaque tile
- [ ] Appeler Initialize() avec PieceData aléatoire
- [ ] Vérifier que pieces se positionent correctement
- [ ] Vérifier que visuals s'instancient
- [ ] Vérifier que abilities chargent

### Combat System Integration
- [ ] Créer CombatSystem.cs
- [ ] Implémenter ResolveAttack(attacker, defender)
- [ ] Tester interaction attaque <-> défense
- [ ] Tester critiques
- [ ] Tester mort et nettoyage

### UI Integration
- [ ] Afficher HealthBar pour chaque piece
- [ ] Afficher nom de la piece
- [ ] Afficher liste des abilities
- [ ] Afficher buffs actifs
- [ ] Afficher niveau/tier

---

## Phase 6 : Performance & Optimization

### Profiling
- [ ] Profile avec 100+ pieces simultanées
- [ ] Vérifier pas de GetComponent loops
- [ ] Vérifier pas de Find() loops
- [ ] Mesurer GC pressure
- [ ] Mesurer frame time

### Optimizations
- [ ] Cache tous les GetComponent au Start()
- [ ] Utiliser C# Action au lieu d'UnityEvent si besoin perf
- [ ] Implémenter Object Pooling pour pieces
- [ ] Utiliser Struct pour PieceStats (pas classe)
- [ ] Limiter List allocations

### Memory
- [ ] Profiler memory avec Profiler window
- [ ] Vérifier que PieceData assets partagés
- [ ] Vérifier pas de duplication de données
- [ ] Checker retained memory

---

## Phase 7 : Scaling à 200+ Variantes

### Batch Creation (Automatisation)
- [ ] Créer script Editor pour dupliquer PieceData
- [ ] Créer script Editor pour assigner stats par template
- [ ] Utiliser pour générer 180+ variantes automatiquement

### Quality Assurance
- [ ] Vérifier pas de duplicata (IDs uniques)
- [ ] Vérifier toutes ont au moins 1 ability
- [ ] Vérifier balance globale (HP/ATK/DEF sommes)
- [ ] Vérifier visual prefabs existent tous
- [ ] Vérifier pas d'assets manquants

### Documentation
- [ ] Documenter chaque famille de pieces
- [ ] Documenter répartition par roles
- [ ] Documenter balance numbers
- [ ] Créer spreadsheet avec toutes les 200+ variantes

---

## Phase 8 : Systèmes Avancés (Optionnel)

### AI System
- [ ] Implémenter IAIStrategy interface
- [ ] Créer AggressiveAI
- [ ] Créer DefensiveAI
- [ ] Créer SmartAI
- [ ] Tester décisions IA

### Progression System
- [ ] Implémenter Experience/Leveling
- [ ] Scaling de stats par niveau
- [ ] Ability unlock par niveau
- [ ] Save/Load progression

### Loot/Equipment
- [ ] Créer système d'items
- [ ] Implémenter stat modifiers
- [ ] Affichage d'equipment sur pieces

---

## Checklist de Code Quality

### Codestyle
- [ ] Tous les noms de classe PascalCase
- [ ] Tous les noms de variable camelCase
- [ ] Constantes UPPERCASE_WITH_UNDERSCORES
- [ ] Fonctions publiques documentées avec ///
- [ ] Pas de magic numbers (utiliser const)

### Performance
- [ ] Pas de GetComponent dans Update/LateUpdate
- [ ] Pas de Find dans Update
- [ ] Pas d'allocations dans Update (New List, etc.)
- [ ] Cache de Renderer, Animator, Collider
- [ ] Utiliser Struct pour petits data (PieceStats)

### Architecture
- [ ] PieceController ne fait que orchestration
- [ ] Logique métier dans systèmes spécialisés
- [ ] Communication par Events, pas appels directs
- [ ] Pas de dépendances circulaires
- [ ] Interfaces pour abstractions

### Testing
- [ ] Chaque système testé en isolation
- [ ] Unit tests pour math crêtique (dégâts, defense, crit)
- [ ] Integration tests pour board
- [ ] Load tests avec 100+ units

---

## Checklist de Déploiement

### Pre-Release
- [ ] Tous les scripts compilés sans erreur
- [ ] Tous les assets référencés correctement
- [ ] Pas de missing references dans hierarchy
- [ ] Pas d'assets inutilisables
- [ ] Scene se charge en < 2 secondes

### Post-Release
- [ ] Documenter toute déviation de l'architecture
- [ ] Mettre à jour README si changements
- [ ] Tag version stable
- [ ] Archiver pour reference future

---

## Metriques de Succès

### Développement
- ✅ **200 variantes créées en < 8 heures** (0 code compilé)
- ✅ **1 seule classe PieceController** pour TOUS les types
- ✅ **0 modifications au code** pour ajouter 100 new variantes
- ✅ **50+ abilities** sans bloat du code

### Performance
- ✅ **1000+ pièces** sans frame drops
- ✅ **0 GC spikes** avec pooling
- ✅ **< 100 ms** pour Initialize() d'une piece
- ✅ **Memory < 500MB** pour 500 pieces

### Maintenance
- ✅ **Ajouter ability = 1 classe, 10 min**
- ✅ **Changer stat = 1 click, 30 sec**
- ✅ **Equipes séparées** (programmeurs/designers)
- ✅ **0 recompilation** pour ajustements

---

**Bonne chance pour votre implémentation!** ✨
