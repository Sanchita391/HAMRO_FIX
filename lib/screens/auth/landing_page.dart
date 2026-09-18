// ============================================================================
// HamroFix - Material 3 Refactored Landing Page
//
// 1. ZERO-PURPLE GUARANTEE:
//    This screen is wrapped in an explicit [kHamroFixLightGreenTheme] (Civic Light Green
//    palette) so even if your main.dart defaults to Flutter's purple seed color
//    (0xFF6750A4), this screen will ALWAYS render in light green on your phone.
//
// 2. LOGO ASSET HANDLING (logo.png):
//    The [HamroFixLogo] widget checks multiple common paths automatically:
//      a) 'assets/image/logo.png'   (your pasted path)
//      b) 'assets/images/logo.png'  (plural folder)
//      c) 'assets/logo.png'         (root assets)
//    with a bulletproof errorBuilder fallback so it NEVER crashes.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hamro_fix/screens/auth/admin/admin_signup.dart';
import 'package:hamro_fix/screens/auth/official/official_login.dart';
import 'package:hamro_fix/screens/auth/public/public_login.dart';
import 'package:hamro_fix/screens/auth/public/public_signup.dart';
import 'package:hamro_fix/screens/auth/worker/worker_signup.dart';

/// Dedicated Light Green Civic Theme to eliminate Flutter's default purple
final ThemeData kHamroFixLightGreenTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF2E7D32), // Forest / Civic Emerald Green
    primary: const Color(0xFF2E7D32),
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFC8E6C9), // Light Mint Green
    onPrimaryContainer: const Color(0xFF1B5E20),
    secondary: const Color(0xFF388E3C),
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFE8F5E9), // Soft pastel green
    onSecondaryContainer: const Color(0xFF1B5E20),
    surface: const Color(0xFFF6FBF4), // Light green-tinted canvas
    onSurface: const Color(0xFF191C1A),
    surfaceContainerLow: const Color(0xFFEDF5EC),
    surfaceContainer: const Color(0xFFE3EDE1),
    surfaceContainerHigh: const Color(0xFFD9E5D7),
    outline: const Color(0xFF727971),
    outlineVariant: const Color(0xFFC2C9BF),
  ),
  scaffoldBackgroundColor: const Color(0xFFF6FBF4),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF6FBF4),
    surfaceTintColor: Colors.transparent,
  ),
);

/// Safe Logo Widget: checks 'assets/image/logo.png', 'assets/images/logo.png',
/// and 'assets/logo.png' before falling back to a civic icon container.
class HamroFixLogo extends StatelessWidget {
  final double size;
  const HamroFixLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        'assets/image/logo.png', // Priority 1: user pasted path
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, _, __) => Image.asset(
          'assets/images/logo.png', // Priority 2: plural folder
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, _, __) => Image.asset(
            'assets/logo.png', // Priority 3: root assets folder
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, _, __) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Icon(
                Icons.shield_outlined,
                size: size * 0.6,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum AppRole {
  public(
    title: 'Public Citizen',
    titleNp: 'सार्वजनिक नागरिक',
    subtitle: 'Report and track local issues in your neighborhood',
    subtitleNp: 'आफ्नो टोल-छिमेकका समस्या रिपोर्ट र ट्र्याक गर्नुहोस्',
    icon: Icons.campaign_rounded,
    allowRegister: true,
    allowLogin: true,
  ),
  worker(
    title: 'Field Worker',
    titleNp: 'फिल्ड कर्मचारी',
    subtitle: 'Resolve assigned tasks and upload live progress',
    subtitleNp: 'तोकिएका कार्यहरू समाधान गरी प्रगति पेश गर्नुहोस्',
    icon: Icons.engineering_rounded,
    allowRegister: true,
    allowLogin: false,
    restrictionNote:
        'Account requires administrative clearance before initial login',
    restrictionNoteNp: 'पहिलो लगइन अघि प्रशासनिक स्वीकृतिको आवश्यकता पर्दछ',
  ),
  official(
    title: 'Ward Official',
    titleNp: 'वडा अधिकारी',
    subtitle: 'Dispatch teams, review tickets, and monitor ward metrics',
    subtitleNp: 'टिम परिचालन, उजुरी पुनरावलोकन र वडा प्रगति अनुगमन',
    icon: Icons.assured_workload_rounded,
    allowRegister: false,
    allowLogin: true,
    restrictionNote:
        'Official credentials are provisioned by municipality administrators',
    restrictionNoteNp:
        'अधिकारी खाता नगरपालिका प्रशासकद्वारा मात्र उपलब्ध गराइन्छ',
  ),
  admin(
    title: 'System Admin',
    titleNp: 'प्रणाली प्रशासक',
    subtitle: 'Full municipal system configuration and audit logs',
    subtitleNp: 'समग्र नगरपालिका प्रणाली व्यवस्थापन र अडिट लग',
    icon: Icons.admin_panel_settings_rounded,
    allowRegister: false,
    allowLogin: true,
    restrictionNote:
        'Superuser access restricted to authorized network terminals',
    restrictionNoteNp: 'प्रशासक पहुँच आधिकारिक नेटवर्क टर्मिनलमा मात्र सीमित छ',
  );

  final String title;
  final String titleNp;
  final String subtitle;
  final String subtitleNp;
  final IconData icon;
  final bool allowRegister;
  final bool allowLogin;
  final String? restrictionNote;
  final String? restrictionNoteNp;

  const AppRole({
    required this.title,
    required this.titleNp,
    required this.subtitle,
    required this.subtitleNp,
    required this.icon,
    required this.allowRegister,
    required this.allowLogin,
    this.restrictionNote,
    this.restrictionNoteNp,
  });
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  // Locale filter: 0 = Bilingual, 1 = English, 2 = Nepali
  int _localeIndex = 0;

  void _onRoleAction(BuildContext context, AppRole role, bool isRegister) {
    HapticFeedback.lightImpact();

    final isPermitted = isRegister ? role.allowRegister : role.allowLogin;
    if (!isPermitted) {
      _showRestrictionSheet(context, role, isRegister);
      return;
    }

    final Widget targetPage = switch (role) {
      AppRole.public =>
        isRegister ? const PublicSignupPage() : const PublicLoginPage(),
      AppRole.worker => const WorkerSignupPage(),
      AppRole.official => const OfficialLoginPage(),
      AppRole.admin => const AdminSignupPage(),
    };

    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => targetPage));
  }

  void _showRestrictionSheet(
    BuildContext context,
    AppRole role,
    bool isRegister,
  ) {
    final theme = Theme.of(context);
    final isNepali = _localeIndex == 2;
    final isDual = _localeIndex == 0;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.lock_clock_outlined,
                      color: theme.colorScheme.onErrorContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRegister
                              ? 'Registration Policy'
                              : 'Access Restricted',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          isRegister ? 'दर्ता नीति' : 'पहुँच सीमित',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (!isNepali && role.restrictionNote != null)
                Text(
                  role.restrictionNote!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    height: 1.45,
                  ),
                ),
              if (isDual &&
                  role.restrictionNote != null &&
                  role.restrictionNoteNp != null)
                const SizedBox(height: 8),
              if ((isNepali || isDual) && role.restrictionNoteNp != null)
                Text(
                  role.restrictionNoteNp!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Understood / बुझें'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Theme wrapper forces Light Green theme even if main.dart uses Flutter's default purple
    return Theme(
      data: kHamroFixLightGreenTheme,
      child: Builder(
        builder: (themedContext) {
          final theme = Theme.of(themedContext);
          final colorScheme = theme.colorScheme;

          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  expandedHeight: 180,
                  floating: false,
                  pinned: true,
                  backgroundColor: colorScheme.surface,
                  scrolledUnderElevation: 3,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 0, label: Text('Dual')),
                          ButtonSegment(value: 1, label: Text('EN')),
                          ButtonSegment(value: 2, label: Text('नेपाली')),
                        ],
                        selected: {_localeIndex},
                        onSelectionChanged: (set) {
                          HapticFeedback.selectionClick();
                          setState(() => _localeIndex = set.first);
                        },
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsetsDirectional.only(
                      start: 20,
                      bottom: 16,
                    ),
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Safe logo loader checks 'assets/image/logo.png', 'assets/images/logo.png', etc.
                        const HamroFixLogo(size: 32),
                        const SizedBox(width: 10),
                        Text(
                          'HamroFix',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_localeIndex != 2)
                          Text(
                            'Choose Your Access Portal',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                        if (_localeIndex != 1)
                          Text(
                            'तपाईंको भूमिका छनोट गर्नुहोस्',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          _localeIndex == 2
                              ? ' समुदायको विकास र सुधारका लागि हातेमालो गरौं।'
                              : 'Lets join hands for the development and improvement of our community.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: AppRole.values.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final role = AppRole.values[index];
                      return _RoleCard(
                        role: role,
                        localeIndex: _localeIndex,
                        onAction: (isRegister) =>
                            _onRoleAction(context, role, isRegister),
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.localeIndex,
    required this.onAction,
  });

  final AppRole role;
  final int localeIndex;
  final ValueChanged<bool> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDual = localeIndex == 0;
    final isNp = localeIndex == 2;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    role.icon,
                    size: 22,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isNp ? role.titleNp : role.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (isDual)
                        Text(
                          role.titleNp,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isNp ? role.subtitleNp : role.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (isDual) ...[
              const SizedBox(height: 4),
              Text(
                role.subtitleNp,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Smart Material 3 Action Row
            Row(
              children: [
                if (role.allowRegister)
                  Expanded(
                    child: FilledButton(
                      onPressed: () => onAction(true),
                      child: Text(isNp ? 'दर्ता गर्नुहोस्' : 'Register'),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onAction(true),
                      icon: const Icon(Icons.lock_outline, size: 16),
                      label: Text(isNp ? 'दर्ता नीति' : 'Invite Only'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.outline,
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
                if (role.allowLogin)
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => onAction(false),
                      child: Text(isNp ? 'लगइन' : 'Sign In'),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onAction(false),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: Text(isNp ? 'स्वीकृति' : 'Approval Req.'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.outline,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
