import 'package:flutter/material.dart';

import 'services/api_service.dart';
import 'coordinator_dashboard_screen.dart';
import 'responsible_access_screen.dart';
import 'theme/app_theme.dart';

class MemberAccessScreen extends StatefulWidget {
  final String section;

  const MemberAccessScreen({
    super.key,
    required this.section,
  });

  @override
  State<MemberAccessScreen> createState() => _MemberAccessScreenState();
}

class _MemberAccessScreenState extends State<MemberAccessScreen> {
  final TextEditingController _codeController = TextEditingController();
  final ApiService api = ApiService();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _error = 'Veuillez entrer votre code personnel.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final memberData = await api.verifyMember(code);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MemberVerifiedScreen(
            section: widget.section,
            user: Map<String, dynamic>.from(
              memberData['user'] ?? {},
            ),
            accessCode: code,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accès membre'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Identifiez-vous pour accéder à '
                  '${widget.section.toLowerCase()}.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Code personnel',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _codeController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _continue(),
                  decoration: InputDecoration(
                    hintText: 'Votre code personnel',
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: _error,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Votre code personnel permet de vérifier '
                  'que vous êtes membre de l’AJF.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _continue,
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Continuer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ============================================================
// ÉCRAN APRÈS IDENTIFICATION
// ============================================================

class MemberVerifiedScreen extends StatefulWidget {
  final String section;
  final Map<String, dynamic> user;
  final String accessCode;

  const MemberVerifiedScreen({
    super.key,
    required this.section,
    required this.user,
    required this.accessCode,
  });

  @override
  State<MemberVerifiedScreen> createState() =>
      _MemberVerifiedScreenState();
}

class _MemberVerifiedScreenState
    extends State<MemberVerifiedScreen> {
  final ApiService api = ApiService();

  bool _loading = true;
  String? _error;

  List<dynamic> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await api.getProjects();

      if (!mounted) return;

      setState(() {
        _projects = projects;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName =
        widget.user['full_name']?.toString() ?? 'Membre';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.section),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 700,
                    ),
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.check_circle_outline,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Identification réussie',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bienvenue $fullName',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge,
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Sélectionnez un projet pour continuer.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_projects.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'Aucun projet disponible.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),

                        ..._projects.map(
                          (project) {
                            final projectMap =
                                Map<String, dynamic>.from(
                              project,
                            );

                            return Card(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.folder_outlined,
                                ),
                                title: Text(
                                  projectMap['name']
                                          ?.toString() ??
                                      'Projet',
                                ),
                                subtitle: Text(
                                  projectMap['domain']
                                          ?.toString() ??
                                      '',
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textMuted,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          MemberProjectAccessScreen(
                                        user: widget.user,
                                        project: projectMap,
                                        accessCode:
                                            widget.accessCode,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}


// ============================================================
// ACCÈS DU MEMBRE AU PROJET
// ============================================================

class MemberProjectAccessScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic> project;
  final String accessCode;

  const MemberProjectAccessScreen({
    super.key,
    required this.user,
    required this.project,
    required this.accessCode,
  });

  @override
  State<MemberProjectAccessScreen> createState() =>
      _MemberProjectAccessScreenState();
}

class _MemberProjectAccessScreenState
    extends State<MemberProjectAccessScreen> {
  final ApiService api = ApiService();

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _responsibilities = [];

  bool _isCoordinator = false;

  @override
  void initState() {
    super.initState();
    _loadAccess();
  }

  Future<void> _loadAccess() async {
    try {
      final projectId = widget.project['id'];

      if (projectId == null) {
        throw Exception(
          'Informations du projet manquantes.',
        );
      }

      final data = await api.getResponsibilityAccess(
        projectId: int.parse(
          projectId.toString(),
        ),
        accessCode: widget.accessCode,
      );

      if (!mounted) return;

      final rawResponsibilities =
          data['responsibilities'] ?? [];

      final responsibilities =
          <Map<String, dynamic>>[];

      if (rawResponsibilities is List) {
        for (final item in rawResponsibilities) {
          if (item is Map) {
            responsibilities.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      }

      final access = data['access'];

      setState(() {
        _responsibilities = responsibilities;

        _isCoordinator =
            access is Map &&
            access['is_coordinator'] == true;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error =
            e.toString().replaceFirst(
              'Exception: ',
              '',
            );
        _loading = false;
      });
    }
  }

  // ============================================================
  // OUVERTURE D'UNE RESPONSABILITÉ
  // ============================================================

  void _openResponsibility(
    Map<String, dynamic> responsibility,
  ) {
    final accessType =
        responsibility['access_type']?.toString() ??
            'member';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResponsibleDashboardScreen(
          user: widget.user,
          project: widget.project,
          responsibility: responsibility,
        ),
      ),
    );
  }

  // ============================================================
  // ESPACE COORDINATEUR
  // ============================================================

  void _openCoordinatorDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoordinatorDashboardScreen(
          user: widget.user,
          project: widget.project,
          responsibilities: _responsibilities,
        ),
      ),
    );
  }

  // ============================================================
  // ICÔNE
  // ============================================================

  IconData _getResponsibilityIcon(
    String name,
  ) {
    final value = name.toLowerCase();

    if (value.contains('sant')) {
      return Icons.health_and_safety_outlined;
    }

    if (value.contains('aliment')) {
      return Icons.restaurant_outlined;
    }

    if (value.contains('vente') ||
        value.contains('client')) {
      return Icons.shopping_cart_outlined;
    }

    if (value.contains('stock') ||
        value.contains('oeuf') ||
        value.contains('œuf')) {
      return Icons.inventory_2_outlined;
    }

    if (value.contains('financ') ||
        value.contains('compt')) {
      return Icons.account_balance_wallet_outlined;
    }

    if (value.contains('communication') ||
        value.contains('informatique')) {
      return Icons.campaign_outlined;
    }

    if (value.contains('conseil')) {
      return Icons.lightbulb_outline;
    }

    if (value.contains('veille')) {
      return Icons.visibility_outlined;
    }

    if (value.contains('terrain')) {
      return Icons.location_on_outlined;
    }

    return Icons.assignment_outlined;
  }

  // ============================================================
  // CARTE RESPONSABILITÉ
  // ============================================================

  Widget _buildResponsibilityCard(
    Map<String, dynamic> item,
  ) {
    final accessType =
        item['access_type']?.toString() ?? 'member';

    final isSupport =
        accessType == 'support';

    final name =
        item['name']?.toString() ??
            'Responsabilité';

    final description =
        item['description']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: AppColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _openResponsibility(item);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  _getResponsibilityIcon(name),
                  color:
                      AppColors.primary,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      isSupport
                          ? 'Appui'
                          : 'Responsable principal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                        color: isSupport
                            ? AppColors.textSecondary
                            : AppColors.primary,
                      ),
                    ),

                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        description,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ÉCRAN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final fullName =
        widget.user['full_name']?.toString() ??
            'Membre';

    final projectName =
        widget.project['name']?.toString() ??
            'Projet';

    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        title: Text(
          projectName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : SafeArea(
                  child: ListView(
                    padding:
                        const EdgeInsets.all(24),
                    children: [
                      // ------------------------------------------------
                      // BIENVENUE
                      // ------------------------------------------------

                      Text(
                        'Bonjour $fullName',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.w700,
                            ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        projectName,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ------------------------------------------------
                      // COORDINATEUR
                      // ------------------------------------------------

                      if (_isCoordinator)
                        Container(
                          margin:
                              const EdgeInsets.only(
                            bottom: 28,
                          ),
                          padding:
                              const EdgeInsets.all(18),
                          decoration:
                              BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons
                                        .dashboard_outlined,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Espace coordinateur',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              const Text(
                                'Accédez à l’espace de pilotage du projet.',
                                style: TextStyle(
                                  color:
                                      AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),

                              const SizedBox(height: 14),

                              FilledButton.icon(
                                onPressed:
                                    _openCoordinatorDashboard,
                                icon: const Icon(
                                  Icons
                                      .dashboard_outlined,
                                ),
                                label: const Text(
                                  'Ouvrir le pilotage',
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ------------------------------------------------
                      // RESPONSABILITÉS
                      // ------------------------------------------------

                      const Text(
                        'Vos responsabilités',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Sélectionnez l’espace auquel vous souhaitez accéder.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (_responsibilities.isEmpty)
                        Container(
                          padding:
                              const EdgeInsets.all(24),
                          decoration:
                              BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons
                                    .assignment_outlined,
                                size: 45,
                                color:
                                    AppColors.textMuted,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Aucune responsabilité active.',
                                textAlign:
                                    TextAlign.center,
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Vous n’avez aucune responsabilité opérationnelle attribuée dans ce projet.',
                                textAlign:
                                    TextAlign.center,
                                style: TextStyle(
                                  color:
                                      AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._responsibilities.map(
                          _buildResponsibilityCard,
                        ),
                    ],
                  ),
                ),
    );
  }
}