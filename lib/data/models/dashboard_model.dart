class DashboardModel {
  final int totalReclamations;
  final int pendingReclamations;
  final int resolvedReclamations;
  final int rejectedReclamations;
  final int unreadNotifications;
  final String studentName;
  final String studentMatricule;
  final List<dynamic> recentReclamations;

  DashboardModel({
    required this.totalReclamations,
    required this.pendingReclamations,
    required this.resolvedReclamations,
    required this.rejectedReclamations,
    required this.unreadNotifications,
    required this.studentName,
    required this.studentMatricule,
    required this.recentReclamations,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    // Puisque le service passe déjà response.data['data'], 'json' est directement l'objet contenant les clés
    final stats = json['reclamations_stats'] as Map<String, dynamic>? ?? {};
    final student = json['student'] as Map<String, dynamic>? ?? {};

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return DashboardModel(
      totalReclamations: parseInt(stats['total']),
      pendingReclamations: parseInt(stats['pending']),
      resolvedReclamations: parseInt(stats['resolved']),
      rejectedReclamations: parseInt(stats['rejected']),
      unreadNotifications: parseInt(json['unread_notifications']),
      studentName: student['full_name']?.toString() ?? 'Nom Inconnu',
      studentMatricule: student['matricule']?.toString() ?? 'XXXXXX',
      recentReclamations: json['recent_reclamations'] as List<dynamic>? ?? [],
    );
  }
}