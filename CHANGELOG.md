# 📝 Changelog - Todo List Flutter

## [2.0.0] - 2024-01-27

### ✨ Nouvelles fonctionnalités majeures

#### 1. Navigation complète de l'application

- **AppDrawer** : Menu latéral avec profil utilisateur et navigation
- **Header complet** : Accès rapide aux différentes sections depuis l'AppBar
- Navigation fluide entre :
  - 📋 Mes tâches
  - 👥 Mes équipes
  - ⚙️ Paramètres
- Confirmation de déconnexion avec dialogue

#### 2. Assignation de tâches aux équipes

- **TeamMemberSelector** : Widget de sélection d'équipe et de membre
- Assignation de tâches à une équipe entière
- Assignation de tâches à un membre spécifique
- Affichage visuel avec chips colorés :
  - Badge équipe avec icône groupe
  - Badge membre avec avatar personnalisé
- Conservation de l'assignation lors des modifications

#### 3. Gestion des équipes améliorée

- Correction du système de requêtes Firestore
- Ajout du champ `memberIds` pour des requêtes optimisées
- Réactivité en temps réel via Streams
- Support complet des opérations CRUD sur les équipes

#### 4. Thèmes light/dark

- Mode clair et mode sombre Material 3
- Sauvegarde de la préférence utilisateur
- Changement dynamique depuis les paramètres
- Design moderne et cohérent

### 🔧 Corrections de bugs

#### LocalStorageService

- Fix du type de retour de `getDefaultPriority()` (TaskPriority au lieu de null)
- Ajout de l'import `TaskModel`
- Gestion robuste des erreurs avec valeurs par défaut

#### TeamService

- Fix de `getUserTeams()` : utilisation de `memberIds` au lieu d'objet complexe
- Synchronisation automatique du champ `memberIds` dans toutes les opérations
- Logs de débogage pour faciliter le diagnostic

#### TaskTile

- Utilisation de `task.copyWith()` au lieu de recréer un objet complet
- Conservation de tous les champs lors des modifications
- Fix de l'affichage des informations d'assignation

### 🎨 Améliorations UI/UX

#### AddTaskSheet

- Converti en StatefulWidget pour gérer l'état
- Ajout du sélecteur d'équipe/membre
- Validation du titre obligatoire
- Messages de confirmation personnalisés
- Scrollable pour s'adapter aux petits écrans

#### TasksPage & TeamsPage

- Drawer accessible depuis les deux pages
- Boutons d'accès rapide dans l'AppBar
- Navigation cohérente et intuitive

#### SettingsPage

- Correction des getters/setters de LocalStorageService
- Interface simplifiée et épurée
- Fonctionnement sans erreurs

### 📚 Documentation

#### Nouveaux fichiers

- `FIREBASE_DEBUG.md` : Guide de débogage Firebase et gestion des équipes
- `FEATURE_TASK_ASSIGNMENT.md` : Documentation complète de l'assignation de tâches
- `CHANGELOG.md` : Ce fichier !

### 🔒 Sécurité

#### Règles Firestore recommandées

```javascript
// Teams - lecture/écriture sécurisées
match /teams/{teamId} {
  allow read: if request.auth.uid in resource.data.memberIds;
  allow create: if request.auth.uid == request.resource.data.ownerId;
  allow update, delete: if request.auth.uid == resource.data.ownerId;
}

// Tasks - avec support des équipes
match /tasks/{taskId} {
  allow read: if request.auth.uid == resource.data.userId
              || request.auth.uid == resource.data.assignedToUserId
              || (resource.data.teamId != null &&
                  get(/databases/$(database)/documents/teams/$(resource.data.teamId))
                    .data.memberIds.hasAny([request.auth.uid]));
  allow write: if request.auth.uid == resource.data.userId;
}
```

### 🗂️ Structure du projet

```
lib/
├── models/
│   ├── task_model.dart (✓ champs assignation)
│   └── team_model.dart (✓ champ memberIds)
├── services/
│   ├── auth/
│   ├── task/
│   ├── team/ (✓ requêtes optimisées)
│   └── storage/ (✓ types corrigés)
├── ui/
│   ├── pages/
│   │   ├── tasks_page.dart (✓ drawer + navigation)
│   │   ├── teams_page.dart (✓ drawer + navigation)
│   │   └── settings_page.dart (✓ fonctionnel)
│   ├── widgets/
│   │   ├── app_drawer.dart (✨ nouveau)
│   │   ├── team_member_selector.dart (✨ nouveau)
│   │   ├── add_task_sheet.dart (✓ assignation)
│   │   └── task_tile.dart (✓ affichage assignation)
│   └── theme/
│       └── app_theme.dart (✓ light/dark)
└── main.dart (✓ providers + routing)
```

### 📊 Statistiques

- **Fichiers modifiés :** 12
- **Nouveaux fichiers :** 3 widgets + 3 docs
- **Lignes de code ajoutées :** ~800
- **Bugs corrigés :** 5 majeurs
- **Warnings résolus :** Tous les erreurs (0 errors restants)

### 🚀 Prochaines étapes suggérées

1. **Notifications push** lors de l'assignation de tâches
2. **Filtres avancés** dans TasksPage (par équipe, par priorité)
3. **Page dédiée** aux tâches d'équipe dans TeamDetailPage
4. **Statistiques** de performance par équipe
5. **Recherche** de tâches et d'équipes
6. **Tags** pour organiser les tâches
7. **Récurrence** pour les tâches répétitives
8. **Pièces jointes** (images, fichiers)

### 🐛 Problèmes connus

- **Warnings :** 28 warnings "info" restants (non-bloquants)
  - Principalement sur `withOpacity()` déprécié (remplacer par `.withValues()`)
  - `use_build_context_synchronously` (ajouter des checks `mounted`)
  - `value` dans DropdownButtonFormField (comportement voulu)

### 💡 Notes pour les développeurs

- Utiliser `flutter run -d chrome --hot` pour le développement web
- Les streams sont réactifs : pas besoin de rafraîchir manuellement
- Le champ `memberIds` doit TOUJOURS être synchronisé avec `members`
- Utiliser `task.copyWith()` pour conserver tous les champs d'une tâche

### 📱 Tests recommandés

#### Navigation

- [ ] Ouvrir le drawer depuis TasksPage
- [ ] Naviguer vers TeamsPage via le drawer
- [ ] Utiliser les boutons de l'AppBar
- [ ] Tester le bouton de déconnexion

#### Assignation de tâches

- [ ] Créer une tâche personnelle
- [ ] Créer une tâche d'équipe (toute l'équipe)
- [ ] Assigner une tâche à un membre spécifique
- [ ] Vérifier l'affichage des chips
- [ ] Modifier une tâche assignée

#### Équipes

- [ ] Créer une équipe
- [ ] Vérifier qu'elle apparaît immédiatement
- [ ] Vérifier dans la console Firebase
- [ ] Inviter un membre (si implémenté)

#### Thèmes

- [ ] Changer de thème dans les paramètres
- [ ] Vérifier la persistance après redémarrage
- [ ] Tester le mode système

---

## [1.0.0] - 2024-01-20

### ✨ Version initiale

- Authentification Firebase (email/password, Google)
- CRUD de tâches
- Firestore comme base de données
- Material Design basique
- Modèle de tâches simple

---

**Contributeurs :** Prince, Cursor AI  
**Framework :** Flutter 3.x  
**Base de données :** Firebase Firestore  
**Authentification :** Firebase Auth
