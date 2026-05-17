class DashboardModel {
  final int totalReclamations;
  final int pendingReclamations;
  final int inProgressReclamations;
  final int resolvedReclamations;
  final int rejectedReclamations;
  final int unreadNotifications;
  final int activeSemestres;
  final double? moyenneGenerale;
  final Map<String, dynamic>? stats;

  DashboardModel({
    required this.totalReclamations,
    required this.pendingReclamations,
    required this.inProgressReclamations,
    required this.resolvedReclamations,
    required this.rejectedReclamations,
    required this.unreadNotifications,
    required this.activeSemestres,
    this.moyenneGenerale,
    this.stats,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      totalReclamations: json['total_reclamations'] ?? 0,
      pendingReclamations: json['pending_reclamations'] ?? 0,
      inProgressReclamations: json['in_progress_reclamations'] ?? 0,
      resolvedReclamations: json['resolved_reclamations'] ?? 0,
      rejectedReclamations: json['rejected_reclamations'] ?? 0,
      unreadNotifications: json['unread_notifications'] ?? 0,
      activeSemestres: json['active_semestres'] ?? 0,
      moyenneGenerale: json['moyenne_generale'] != null 
          ? (json['moyenne_generale'] as num).toDouble() 
          : null,
      stats: json['stats'] != null 
          ? Map<String, dynamic>.from(json['stats']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_reclamations': totalReclamations,
      'pending_reclamations': pendingReclamations,
      'in_progress_reclamations': inProgressReclamations,
      'resolved_reclamations': resolvedReclamations,
      'rejected_reclamations': rejectedReclamations,
      'unread_notifications': unreadNotifications,
      'active_semestres': activeSemestres,
      'moyenne_generale': moyenneGenerale,
      'stats': stats,
    };
  }
}
