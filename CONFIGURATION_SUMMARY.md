# Configuration Backend Laravel avec Flutter - Partie Student

## ✅ Configuration terminée

L'intégration de l'API Laravel avec Flutter pour la partie student a été configurée avec succès.

## 📁 Fichiers créés/modifiés

### 1. Configuration et Endpoints
- ✅ `lib/core/constants/api_endpoints.dart` - Ajout des endpoints student manquants
- ✅ `lib/core/config/api_config.dart` - Configuration centralisée de l'API

### 2. Modèles de données (Models)
- ✅ `lib/data/models/dashboard_model.dart` - Modèle Dashboard
- ✅ `lib/data/models/semestre_model.dart` - Modèle Semestre
- ✅ `lib/data/models/note_model.dart` - Modèle Note
- ✅ `lib/data/models/notification_model.dart` - Modèle Notification
- ✅ `lib/data/models/profile_model.dart` - Modèle Profile
- ✅ `lib/data/models/module_model.dart` - Modèle Module
- ✅ `lib/data/models/document_model.dart` - Modèle Document

### 3. Services API
- ✅ `lib/data/services/student_service.dart` - Service complet pour toutes les fonctionnalités student
- ✅ `lib/data/services/api_client.dart` - Correction de l'import

### 4. Contrôleurs (Controllers)
- ✅ `lib/presentation/student/dashboard_controller.dart` - Contrôleur Dashboard
- ✅ `lib/presentation/student/profile_controller.dart` - Contrôleur Profile
- ✅ `lib/presentation/student/notes_controller.dart` - Contrôleur Notes

### 5. Documentation
- ✅ `STUDENT_API_GUIDE.md` - Guide complet d'utilisation de l'API
- ✅ `lib/main_example.dart` - Exemple d'implémentation main.dart

### 6. Dépendances
- ✅ `pubspec.yaml` - Ajout de shared_preferences

## 🚀 Étapes suivantes

### 1. Installer les dépendances
```bash
flutter pub get
```

### 2. Configurer l'URL du backend
Dans `lib/core/constants/api_endpoints.dart`, ligne 4 :
```dart
static const String baseUrl = 'http://VOTRE_IP/VOTRE_DOSSIER_LARAVEL/public/api/v1';
```

### 3. Intégrer dans main.dart
Utilisez le fichier `lib/main_example.dart` comme référence pour intégrer l'API dans votre application.

### 4. Créer les écrans UI
Créez les écrans Flutter en utilisant les contrôleurs créés :
- Dashboard (dashboard_controller.dart)
- Profile (profile_controller.dart)
- Notes (notes_controller.dart)
- Semestres
- Notifications
- Documents

## 📋 Fonctionnalités disponibles

### Dashboard
- Statistiques des réclamations
- Notifications non lues
- Semestres actifs
- Moyenne générale

### Semestres
- Liste des semestres selon le niveau (L1, L2, L3)
- Filtrage automatique par niveau étudiant
- Types disponibles (CC, Examen, Rattrapage)

### Notes
- Liste des notes
- Filtrage par semestre
- Calcul de moyenne
- Groupement par module/semestre

### Notifications
- Liste des notifications
- Marquer comme lu
- Marquer tout comme lu
- Supprimer
- Compteurs

### Profile
- Consultation du profil
- Mise à jour des informations
- Changement de photo
- Changement de mot de passe

### Modules
- Liste des modules
- Filtrage par semestre

### Documents
- Liste des documents
- Filtrage par catégorie

## 🔐 Gestion de l'authentification

### Stockage du token
```dart
// Après connexion réussie
final prefs = await SharedPreferences.getInstance();
await prefs.setString('auth_token', token);
ApiConfig().setAuthToken(token);
```

### Récupération du token au démarrage
```dart
final prefs = await SharedPreferences.getInstance();
final authToken = prefs.getString('auth_token');
ApiConfig().initialize(authToken: authToken);
```

### Déconnexion
```dart
final prefs = await SharedPreferences.getInstance();
await prefs.remove('auth_token');
ApiConfig().clearAuthToken();
```

## 📚 Documentation complète

Pour plus de détails sur l'utilisation de chaque service, consultez le fichier :
- `STUDENT_API_GUIDE.md`

## 🎯 Architecture

```
lib/
├── core/
│   ├── config/
│   │   └── api_config.dart          # Singleton API
│   └── constants/
│       └── api_endpoints.dart       # Endpoints
├── data/
│   ├── models/                      # Modèles de données
│   └── services/                    # Services API
└── presentation/
    ├── auth/                        # Authentification
    └── student/                     # Écrans student
        ├── dashboard_controller.dart
        ├── profile_controller.dart
        └── notes_controller.dart
```

## ⚠️ Points importants

1. **URL Backend**: Remplacez l'URL par celle de votre serveur Laravel
2. **Token**: Stockez-le de manière sécurisée (SharedPreferences ou secure_storage)
3. **Gestion des erreurs**: Toutes les méthodes lancent des exceptions
4. **Timeout**: 10 secondes par défaut
5. **Filtrage**: Les semestres sont filtrés automatiquement par niveau

## 🔄 Exemple d'utilisation rapide

```dart
// Initialisation
ApiConfig().initialize(authToken: 'votre_token');

// Utilisation
try {
  final dashboard = await ApiConfig().studentService.getDashboard();
  print('Réclamations: ${dashboard.totalReclamations}');
} catch (e) {
  print('Erreur: $e');
}
```

## 📞 Support

Pour toute question, référez-vous au guide `STUDENT_API_GUIDE.md`.
