import 'package:flutter/material.dart';
import 'responsible_access_screen.dart';
import 'services/api_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'member_access_screen.dart';
import 'theme/app_theme.dart';


void main() {
  runApp(const AJFApp());
}

class AJFApp extends StatelessWidget {
  const AJFApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      localizationsDelegates:
        GlobalMaterialLocalizations.delegates,

      supportedLocales: const[
        Locale('fr'),
        Locale('en'),
      ],
      
      title: 'AJF',
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}

// ============================================================
// ÉCRAN 1 — ACCUEIL
// ============================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showComingSoon(BuildContext context, String section) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$section sera disponible dans la prochaine étape.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 40,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 30,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.groups_rounded,
                            size: 44,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          'AJF',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          'Système de gestion centralisé',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    'De quoi allons-nous gérer aujourd’hui ?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 35),

                  _ManagementButton(
                    icon: Icons.account_balance_outlined,
                    title: 'Association',
                    subtitle: 'Gérer les activités de l’AJF',
                    color: AppColors.info,
                    onPressed: () {
                      _showComingSoon(context, 'Association');
                    },
                  ),

                  const SizedBox(height: 18),

                  _ManagementButton(
                    icon: Icons.agriculture_outlined,
                    title: 'Coopérative',
                    subtitle: 'Gérer les projets et activités de production',
                    color: AppColors.primary,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MemberAccessScreen(
                            section: 'Coopérative',
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 55),

                  const Text(
                    'Association des Jeunes Futurs',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Construire aujourd’hui, transformer demain.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ÉCRAN 2 — PROJETS DE LA COOPÉRATIVE
// ============================================================

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final ApiService api = ApiService();

  List<dynamic> projects = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadProjects();
  }

  Future<void> loadProjects() async {
    try {
      final result = await api.getProjects();

      if (!mounted) return;

      setState(() {
        projects = result;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Coopérative',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : error != null
                ? _ErrorView(
                    message: error!,
                    onRetry: loadProjects,
                  )
                : RefreshIndicator(
                    onRefresh: loadProjects,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        10,
                        20,
                        30,
                      ),
                      children: [
                        const Text(
                          'Projets',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          'Sélectionnez le projet que vous souhaitez consulter.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 28),

                        const _SectionTitle(
                          icon: Icons.play_circle_outline,
                          title: 'Projets en cours',
                        ),

                        const SizedBox(height: 12),

                        if (projects.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Center(
                              child: Text(
                                'Aucun projet disponible.',
                              ),
                            ),
                          ),

                        ...projects.map((project) {
                          return _ProjectCard(
                            project: {
                              'name': project['name'] ?? 'Projet',
                              'domain':
                                  project['domain'] ?? 'Coopérative',
                              'coordinator':
                                  project['coordinator_name'] ??
                                      'Non défini',
                              'start':
                                  project['start_date'] ?? 'Non définie',
                              'status':
                                  project['status'] ?? 'ACTIVE',
                              'icon': Icons.egg_alt_outlined,
                            },
                            active: project['status'] == 'ACTIVE',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProjectDetailsScreen(
                                    project: {
                                      'id': project['id'],
                                      'name': project['name'],
                                      'domain':
                                          project['domain'],
                                      'coordinator':
                                          project['coordinator_name'],
                                      'start':
                                          project['start_date'],
                                      'status':
                                          project['status'],
                                      'description':
                                          project['description'],
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      ],
                    ),
                  ),
      ),
    );
  }
}

// ============================================================
// TITRE DE SECTION
// ============================================================

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 21,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CARTE PROJET
// ============================================================

class _ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final bool active;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppColors.primary
        : AppColors.textSecondary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  project['icon'],
                  color: color,
                  size: 29,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project['name'],
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      project['domain'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      'Coordinateur : ${project['coordinator']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.chevron_right_rounded,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ÉCRAN 3 PROVISOIRE — INFORMATIONS DU PROJET
// ============================================================

class ProjectDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> project;

  const ProjectDetailsScreen({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    final status = project['status'] ?? 'ACTIVE';

    final statusLabel = status == 'ACTIVE'
        ? 'Actif'
        : status == 'PAUSED'
            ? 'En pause'
            : 'Clôturé';

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Projet',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --------------------------------------------------
          // INFORMATIONS DU PROJET
          // --------------------------------------------------

          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.10),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.egg_alt_outlined,
                    size: 30,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  project['name'] ?? 'Projet',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  project['domain'] ?? 'Coopérative',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),

                const Divider(height: 30),

                _InfoRow(
                  label: 'Coordinateur',
                  value: project['coordinator'] ?? 'Non défini',
                ),

                _InfoRow(
                  label: 'Début',
                  value: project['start'] ?? 'Non définie',
                ),

                _InfoRow(
                  label: 'Statut',
                  value: statusLabel,
                ),

                if ((project['description'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  const Divider(height: 25),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    project['description'].toString(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'Comment souhaitez-vous entrer ?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Choisissez votre niveau d’accès à ce projet.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 16),

          // --------------------------------------------------
          // INVITÉ
          // --------------------------------------------------

          _AccessCard(
            icon: Icons.visibility_outlined,
            title: 'Invité',
            subtitle:
                'Consulter le projet et ses informations en lecture seule.',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Le mode invité sera connecté aux données du projet.',
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // --------------------------------------------------
          // RESPONSABLE
          // --------------------------------------------------

          _AccessCard(
            icon: Icons.badge_outlined,
            title: 'Responsable',
            subtitle:
                'Accéder à mes responsabilités et gérer mes données.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResponsibleAccessScreen(
                    project: project,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LIGNE D'INFORMATION
// ============================================================

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CARTE INVITÉ / RESPONSABLE
// ============================================================

class _AccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.person_outline,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textMuted,
        ),
        onTap: onTap,
      ),
    );
  }
}

// ============================================================
// BOUTON ACCUEIL
// ============================================================

class _ManagementButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onPressed;

  const _ManagementButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border,
              ),
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: color,
                  ),
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 50,
              color: Colors.grey,
            ),
            const SizedBox(height: 15),
            const Text(
              'Impossible de charger les projets.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}