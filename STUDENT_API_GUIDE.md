# Guide d'intégration API Student - ISCAE

Ce guide explique comment configurer et utiliser l'API Laravel avec Flutter pour la partie student.

## 📋 Structure du projet

```
lib/
├── core/
│   ├── config/
│   │   └── api_config.dart          # Configuration centralisée de l'API
│   └── constants/
│       └── api_endpoints.dart       # Tous les endpoints API
├── data/
│   ├── models/                      # Modèles de données
│   │   ├── dashboard_model.dart
│   │   ├── semestre_model.dart
│   │   ├── note_model.dart
│   │   ├── notification_model.dart
│   │   ├── profile_model.dart
│   │   ├── module_model.dart
│   │   ├── document_model.dart
│   │   └── reclamation_model.dart
│   └── services/                    # Services API
│       ├── api_client.dart          # Client HTTP générique
│       ├── auth_service.dart        # Service d'authentification
│       ├── student_service.dart     # Service student (nouveau)
│       └── reclamation_service.dart # Service réclamations
└── presentation/                    # UI et contrôleurs
```

## 🚀 Configuration initiale

### 1. Mettre à jour l'URL du backend

Dans `lib/core/constants/api_endpoints.dart`, remplacez l'URL par celle de votre serveur :

```dart
static const String baseUrl = 'http://192.168.100.59/iscae_backend_folder/public/api/v1';
```

### 2. Initialiser l'API dans main.dart

```dart
import 'package:flutter/material.dart';
import 'package:iscae_reclamation/core/config/api_config.dart';

void main() {
  // Initialiser l'API avec le token si disponible
  ApiConfig().initialize(authToken: 'votre_token_ici');
  
  runApp(MyApp());
}
```

### 3. Après connexion

```dart
// Après une connexion réussie
final response = await login(...);
if (response['success']) {
  final token = response['data']['token'];
  ApiConfig().setAuthToken(token);
  // Naviguer vers le dashboard
}
```

## 📦 Utilisation des services

### Dashboard

```dart
import 'package:iscae_reclamation/core/config/api_config.dart';

// Récupérer les données du dashboard
try {
  final dashboard = await ApiConfig().studentService.getDashboard();
  print('Total réclamations: ${dashboard.totalReclamations}');
  print('Notifications non lues: ${dashboard.unreadNotifications}');
} catch (e) {
  print('Erreur: $e');
}
```

### Semestres

```dart
// Récupérer les semestres disponibles pour l'étudiant
try {
  final semestres = await ApiConfig().studentService.getSemestres();
  for (var semestre in semestres) {
    print('${semestre.code} - ${semestre.label}');
    print('Types disponibles: ${semestre.availableTypes}');
  }
} catch (e) {
  print('Erreur: $e');
}
```

### Notes

```dart
// Récupérer toutes les notes
final notes = await ApiConfig().studentService.getNotes();

// Récupérer les notes d'un semestre spécifique
final notesS1 = await ApiConfig().studentService.getNotes(semestreId: 1);

// Récupérer une note spécifique
final note = await ApiConfig().studentService.getNoteById(5);
```

### Notifications

```dart
// Récupérer les notifications
final notifications = await ApiConfig().studentService.getNotifications();

// Récupérer les compteurs
final counts = await ApiConfig().studentService.getNotificationCounts();
print('Non lues: ${counts['unread']}');

// Marquer une notification comme lue
await ApiConfig().studentService.markNotificationAsRead(1);

// Marquer toutes comme lues
await ApiConfig().studentService.markAllNotificationsAsRead();

// Supprimer une notification
await ApiConfig().studentService.deleteNotification(1);
```

### Profil

```dart
// Récupérer le profil
final profile = await ApiConfig().studentService.getProfile();

// Mettre à jour le profil
final updatedProfile = await ApiConfig().studentService.updateProfile({
  'name': 'Nouveau nom',
  'phone': '0612345678',
});

// Mettre à jour la photo
await ApiConfig().studentService.updateProfilePhoto('/path/to/photo.jpg');

// Changer le mot de passe
await ApiConfig().studentService.updatePassword(
  currentPassword: 'ancien_mdp',
  newPassword: 'nouveau_mdp',
  newPasswordConfirmation: 'nouveau_mdp',
);
```

### Modules

```dart
// Récupérer tous les modules
final modules = await ApiConfig().studentService.getModules();

// Récupérer les modules d'un semestre
final modulesS1 = await ApiConfig().studentService.getModules(semestreId: 1);
```

### Documents

```dart
// Récupérer tous les documents
final documents = await ApiConfig().studentService.getDocuments();

// Récupérer les documents par catégorie
final pdfDocs = await ApiConfig().studentService.getDocuments(category: 'pdf');

// Récupérer un document spécifique
final document = await ApiConfig().studentService.getDocumentById(1);
```

## 🔐 Gestion de l'authentification

### Connexion

```dart
final result = await login(
  login: 'matricule_ou_email',
  password: 'mot_de_passe',
  deviceFingerprint: 'device_id_unique',
);

if (result['success']) {
  final token = result['data']['token'];
  ApiConfig().setAuthToken(token);
}
```

### Déconnexion

```dart
await ApiConfig().apiClient.post(ApiEndpoints.logout);
ApiConfig().clearAuthToken();
```

## 📝 Modèles de données

### DashboardModel
- `totalReclamations`: Nombre total de réclamations
- `pendingReclamations`: Réclamations en attente
- `inProgressReclamations`: Réclamations en cours
- `resolvedReclamations`: Réclamations résolues
- `rejectedReclamations`: Réclamations rejetées
- `unreadNotifications`: Notifications non lues
- `activeSemestres`: Semestres actifs
- `moyenneGenerale`: Moyenne générale

### SemestreModel
- `id`: ID du semestre
- `code`: Code (S1, S2, etc.)
- `label`: Nom du semestre
- `academicYear`: Année académique
- `isOpen`: Si les CC sont ouverts
- `isExamOpen`: Si les examens sont ouverts
- `isRattrapageOpen`: Si les rattrapages sont ouverts
- `availableTypes`: Types disponibles (cc, examen, rattrapage)

### NoteModel
- `id`: ID de la note
- `matricule`: Matricule de l'étudiant
- `moduleCode`: Code du module
- `moduleName`: Nom du module
- `type`: Type (cc, examen, rattrapage)
- `value`: Note
- `coefficient`: Coefficient

### NotificationModel
- `id`: ID de la notification
- `title`: Titre
- `message`: Message
- `type`: Type (info, warning, success, error)
- `isRead`: Si lue
- `data`: Données additionnelles

### ProfileModel
- `id`: ID du profil
- `name`: Nom complet
- `email`: Email
- `matricule`: Matricule
- `phone`: Téléphone
- `photo`: URL de la photo
- `niveauCode`: Code du niveau (L1, L2, L3)
- `filiereNom`: Nom de la filière

## ⚠️ Points importants

1. **URL du backend**: Assurez-vous de remplacer l'URL par celle de votre serveur Laravel
2. **Token d'authentification**: Le token doit être stocké de manière sécurisée (SharedPreferences ou secure_storage)
3. **Gestion des erreurs**: Toutes les méthodes lancent des exceptions en cas d'erreur
4. **Timeout**: Les requêtes ont un timeout de 10 secondes
5. **Filtrage par niveau**: Les semestres sont automatiquement filtrés selon le niveau de l'étudiant (L1, L2, L3)

## 🔄 Exemple complet d'écran Dashboard

```dart
import 'package:flutter/material.dart';
import 'package:iscae_reclamation/core/config/api_config.dart';
import 'package:iscae_reclamation/data/models/dashboard_model.dart';

class StudentDashboard extends StatefulWidget {
  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  DashboardModel? _dashboard;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final dashboard = await ApiConfig().studentService.getDashboard();
      setState(() {
        _dashboard = dashboard;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: _dashboard != null ? _buildDashboard() : Center(child: Text('Aucune donnée')),
    );
  }

  Widget _buildDashboard() {
    return ListView(
      children: [
        Card(
          child: ListTile(
            title: Text('Réclamations totales'),
            trailing: Text('${_dashboard!.totalReclamations}'),
          ),
        ),
        Card(
          child: ListTile(
            title: Text('Notifications non lues'),
            trailing: Text('${_dashboard!.unreadNotifications}'),
          ),
        ),
        // ... autres widgets
      ],
    );
  }
}
```

## 📞 Support

Pour toute question ou problème, contactez l'équipe de développement.
