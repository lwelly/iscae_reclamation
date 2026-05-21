import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/url_resolver.dart';
import '../auth/login_screen.dart';
import 'create_reclamation_screen.dart';
import 'dashboard_screen.dart';
import 'notification_controller.dart';
import 'notification_screen.dart';
import 'profile_controller.dart';
import 'profile_screen.dart';
import 'reclamation_detail_screen.dart';
import 'reclamation_screen.dart';
import '../auth/widgets/auth_shared.dart';
import 'widgets/profile_avatar.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  static const _drawerWidth = 260.0;
  static const _railWidth = 68.0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  bool _rail = false;
  Timer? _notifTimer;

  static const _pageTitles = {
    0: 'Tableau de bord',
    1: 'Mes Réclamations',
    2: 'Nouvelle Réclamation',
    3: 'Notifications',
    4: 'Mon Profil',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  bool get _isDark => context.watch<ThemeController>().isDark;

  SystemUiOverlayStyle get _overlayStyle => _isDark
      ? SystemUiOverlayStyle.light.copyWith(
          statusBarColor: _appBarBg,
          statusBarIconBrightness: Brightness.light,
        )
      : SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: _appBarBg,
          statusBarIconBrightness: Brightness.dark,
        );

  @override
  void dispose() {
    _notifTimer?.cancel();
    super.dispose();
  }

  Future<void> _initData() async {
    if (!mounted) return;
    final notifCtrl = context.read<NotificationController>();
    final profileCtrl = context.read<ProfileController>();
    await Future.wait([
      notifCtrl.loadCounts(),
      profileCtrl.loadProfile(),
    ]);
    _notifTimer?.cancel();
    _notifTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) context.read<NotificationController>().loadCounts();
    });
  }

  bool get _isMobile => MediaQuery.sizeOf(context).width < 768;

  Color get _drawerBg => _isDark ? const Color(0xFF16213E) : const Color(0xFF0F2D5E);
  Color get _mainBg => Theme.of(context).scaffoldBackgroundColor;
  Color get _appBarBg => context.appNavBar;
  Color get _appBarBorder => context.appBorder;

  void _toggleSidebar() {
    if (_isMobile) {
      final scaffold = _scaffoldKey.currentState;
      if (scaffold?.isDrawerOpen == true) {
        scaffold?.closeDrawer();
      } else {
        scaffold?.openDrawer();
      }
    } else {
      setState(() => _rail = !_rail);
    }
  }

  void _selectIndex(int index) {
    setState(() => _selectedIndex = index);
    if (_isMobile) _scaffoldKey.currentState?.closeDrawer();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    ApiConfig().clearAuthToken();
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  String _initials(String? name, String? email) {
    final source = (name?.trim().isNotEmpty == true ? name! : email) ?? 'ET';
    final parts = source.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return source.length >= 2 ? source.substring(0, 2).toUpperCase() : source.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final showLabels = !_rail || _isMobile;
    final sidebarWidth = (_rail && !_isMobile) ? _railWidth : _drawerWidth;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle,
      child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: _mainBg,
          drawer: _isMobile ? Drawer(child: _buildDrawerContent(showLabels: true, expanded: true)) : null,
          body: Row(
          children: [
            if (!_isMobile)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: sidebarWidth,
                child: _buildDrawerContent(showLabels: showLabels, expanded: showLabels),
              ),
            Expanded(
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1300),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: _isMobile ? 8 : 20,
                            vertical: _isMobile ? 8 : 24,
                          ),
                          child: IndexedStack(
                            index: _selectedIndex,
                            children: [
                              StudentDashboard(
                                embedded: true,
                                onNewReclamation: () => _selectIndex(2),
                                onViewAllReclamations: () => _selectIndex(1),
                              ),
                              const ReclamationScreen(),
                              CreateReclamationScreen(onBackToDashboard: () => _selectIndex(0)),
                              NotificationScreen(
                                onOpenReclamations: ({int? reclamationId}) {
                                  _selectIndex(1);
                                  if (reclamationId != null) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (!mounted) return;
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ReclamationDetailScreen(id: reclamationId),
                                        ),
                                      );
                                    });
                                  }
                                },
                              ),
                              const ProfileScreen(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
    );
  }

  Widget _buildDrawerContent({required bool showLabels, required bool expanded}) {
    return Material(
      color: _drawerBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLogo(showLabels),
          if (showLabels)
            _sectionLabel('NAVIGATION')
          else
            const SizedBox(height: 4),
          _navItem(index: 0, icon: Icons.dashboard_outlined, label: 'Tableau de bord', showLabels: showLabels),
          _navItem(index: 1, icon: Icons.description_outlined, label: 'Mes Réclamations', showLabels: showLabels),
          _navItem(index: 2, icon: Icons.add_circle_outline, label: 'Nouvelle Réclamation', showLabels: showLabels),
          _navItem(index: 3, icon: Icons.notifications_outlined, label: 'Notifications', showLabels: showLabels, showBadge: true),
          const SizedBox(height: 8),
          if (showLabels) _sectionLabel('COMPTE') else const SizedBox(height: 4),
          _navItem(index: 4, icon: Icons.person_outline, label: 'Mon Profil', showLabels: showLabels),
          const Spacer(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildLogo(bool showLabels) {
    return Padding(
      padding: EdgeInsets.fromLTRB(showLabels ? 16 : 8, 22, 16, 18),
      child: Row(
        mainAxisAlignment: showLabels ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(3),
            child: const IscaeLogoImage(size: 40),
          ),
          if (showLabels) ...[
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ISCAE', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                  Text('Espace Étudiant', style: TextStyle(color: Color(0x8FFFFFFF), fontSize: 11, letterSpacing: 0.5)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 6),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
    required bool showLabels,
    bool showBadge = false,
  }) {
    final active = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectIndex(index),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: active ? Colors.white.withOpacity(0.16) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                if (active)
                  Container(
                    width: 3,
                    height: 20,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: active ? Colors.white.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: active ? Colors.white : Colors.white.withOpacity(0.7)),
                ),
                if (showLabels) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.white.withOpacity(0.7),
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showBadge)
                    Consumer<NotificationController>(
                      builder: (_, ctrl, __) {
                        final unread = ctrl.unreadCount;
                        if (unread <= 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Consumer2<ProfileController, NotificationController>(
      builder: (context, profileCtrl, notifCtrl, _) {
        final profile = profileCtrl.profile;
        final fullName = profile?.fullName.isNotEmpty == true ? profile!.fullName : 'Étudiant';
        final firstName = profile?.prenom?.trim().isNotEmpty == true
            ? profile!.prenom!
            : fullName.split(' ').first;
        final email = profile?.studentEmail ?? profile?.email ?? '';
        final photoUrl = profile != null
            ? resolveProfilePhoto(photoUrl: profile.photoUrl, photoPath: profile.photoPath)
            : '';
        final resolvedPhoto = photoUrl.isNotEmpty ? photoUrl : null;
        final initials = _initials(fullName, email);
        final unread = notifCtrl.unreadCount;

        return Material(
          color: _appBarBg,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _appBarBorder)),
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: kToolbarHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          _rail && !_isMobile ? Icons.menu_open : Icons.menu,
                          color: _isDark ? const Color(0xFFA9B1D6) : const Color(0xFF0F2D5E),
                        ),
                        onPressed: _toggleSidebar,
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            if (!_isMobile) ...[
                              Text(
                                'Étudiant',
                                style: TextStyle(fontSize: 13, color: _isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                              ),
                              Icon(Icons.chevron_right, size: 14, color: _isDark ? const Color(0xFF565F89) : const Color(0xFFCBD5E1)),
                              const SizedBox(width: 4),
                            ],
                            Flexible(
                              child: Text(
                                _pageTitles[_selectedIndex] ?? 'Espace Étudiant',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: _isDark ? 'Mode clair' : 'Mode sombre',
                        onPressed: () => context.read<ThemeController>().toggle(),
                        icon: Icon(
                          _isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                          color: _isDark ? const Color(0xFFFCD34D) : const Color(0xFF475569),
                          size: 22,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _selectIndex(3),
                        icon: Badge(
                          isLabelVisible: unread > 0,
                          label: Text(unread > 99 ? '99+' : '$unread'),
                          child: Icon(
                            Icons.notifications_outlined,
                            size: 20,
                            color: _isDark ? const Color(0xFFD1D5DB) : const Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _UserMenuButton(
                        firstName: firstName,
                        fullName: fullName,
                        email: email,
                        photoUrl: resolvedPhoto,
                        initials: initials,
                        isMobile: _isMobile,
                        onProfile: () => _selectIndex(4),
                        onLogout: _logout,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UserMenuButton extends StatelessWidget {
  final String firstName;
  final String fullName;
  final String email;
  final String? photoUrl;
  final String initials;
  final bool isMobile;
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  const _UserMenuButton({
    required this.firstName,
    required this.fullName,
    required this.email,
    required this.photoUrl,
    required this.initials,
    required this.isMobile,
    required this.onProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: context.appCard,
      onSelected: (value) {
        if (value == 'profile') onProfile();
        if (value == 'logout') onLogout();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfileAvatar(
              radius: 16,
              initials: initials,
              backgroundColor: Colors.blue.shade700,
              photoUrl: photoUrl,
            ),
            if (!isMobile) ...[
              const SizedBox(width: 8),
              Text(
                firstName,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
              ),
              Icon(Icons.keyboard_arrow_down, size: 16, color: isDark ? const Color(0xFF565F89) : const Color(0xFFCBD5E1)),
            ],
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Row(
            children: [
              ProfileAvatar(
                radius: 21,
                initials: initials,
                backgroundColor: Colors.blue.shade700,
                photoUrl: photoUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fullName, style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B))),
                    Text(email, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'profile',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.account_circle_outlined),
            title: Text('Mon profil'),
            dense: true,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Se déconnecter', style: TextStyle(color: Colors.red)),
            dense: true,
          ),
        ),
      ],
    );
  }
}
