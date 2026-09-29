import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'theme/app_theme.dart';

class CoordinatorDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic> project;
  final List<Map<String, dynamic>> responsibilities;

  const CoordinatorDashboardScreen({
    super.key,
    required this.user,
    required this.project,
    required this.responsibilities,
  });

  @override
  State<CoordinatorDashboardScreen> createState() =>
      _CoordinatorDashboardScreenState();
}

class _CoordinatorDashboardScreenState
    extends State<CoordinatorDashboardScreen> {
  static const Color primaryColor = AppColors.primary;
  static const Color backgroundColor = AppColors.background;

  bool _loadingEntries = false;
  String? _entriesError;

  List<Map<String, dynamic>> _entries = [];

  String get userName {
    return widget.user["full_name"]?.toString() ??
        "${widget.user["first_name"] ?? ""} "
            "${widget.user["last_name"] ?? ""}".trim();
  }

  String get projectName {
    return widget.project["name"]?.toString() ?? "Projet";
  }

  String get projectDomain {
    return widget.project["domain"]?.toString() ?? "";
  }

  String get projectStatus {
    return widget.project["status"]?.toString() ?? "En cours";
  }

  @override
  void initState() {
    super.initState();

    // Charger automatiquement les données du projet
    _loadProjectEntries();
  }

  // ============================================================
  // CHARGEMENT DES DONNÉES DU PROJET
  // ============================================================

  Future<void> _loadProjectEntries() async {
    if (mounted) {
      setState(() {
        _loadingEntries = true;
        _entriesError = null;
      });
    }

    try {
      final projectId = widget.project["id"];

      final response = await http.get(
        Uri.parse(
          'https://myajf-backend.onrender.com/api/projects/'
          '$projectId/entries/',
        ),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<dynamic> rawEntries = [];

        if (decoded is List) {
          rawEntries = decoded;
        } else if (decoded is Map &&
            decoded["results"] is List) {
          rawEntries = decoded["results"];
        }

        final entries = rawEntries
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();

        setState(() {
          _entries = entries;
          _loadingEntries = false;
        });
      } else {
        setState(() {
          _entriesError =
              "Le serveur a retourné une erreur "
              "(${response.statusCode}).";
          _loadingEntries = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _entriesError =
            "Impossible de contacter le serveur Django.";
        _loadingEntries = false;
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Espace coordinateur",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadingEntries
                ? null
                : _loadProjectEntries,
            icon: const Icon(Icons.refresh),
            tooltip: "Actualiser",
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProjectEntries,
          color: primaryColor,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 20),

              _buildProjectCard(),
              const SizedBox(height: 20),

              _buildOverviewSection(),
              const SizedBox(height: 20),

              _buildManagementSection(),
              const SizedBox(height: 20),

              _buildActivitySection(),
              const SizedBox(height: 20),

              _buildResponsibilitiesSection(),
              const SizedBox(height: 20),

              _buildInformationSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BIENVENUE
  // ============================================================

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ESPACE COORDINATEUR",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Bonjour $userName",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Pilotez et suivez les activités du projet.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROJET
  // ============================================================

  Widget _buildProjectCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(Icons.business),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Projet actuel",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            projectName,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (projectDomain.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              projectDomain,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 9,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 7),
                Text(
                  projectStatus,
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VUE D'ENSEMBLE
  // ============================================================

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          "Vue d'ensemble",
          Icons.dashboard_outlined,
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: "Responsabilités",
                value:
                    widget.responsibilities.length.toString(),
                icon: Icons.assignment_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: "Données enregistrées",
                value: _entries.length.toString(),
                icon: Icons.data_usage_outlined,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _buildActivitySummaryCard(),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: primaryColor,
            size: 25,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySummaryCard() {
    final activeCount = _getResponsibilitiesWithDataCount();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          _iconBox(Icons.timeline),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Activité du projet",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "$activeCount responsabilité(s) "
                  "ont déjà enregistré des données.",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getResponsibilitiesWithDataCount() {
    final idsWithData = <dynamic>{};

    for (final entry in _entries) {
      if (entry["responsibility"] != null) {
        idsWithData.add(entry["responsibility"]);
      }
    }

    return idsWithData.length;
  }

  // ============================================================
  // GESTION
  // ============================================================

  Widget _buildManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          "Gestion du projet",
          Icons.settings_outlined,
        ),
        const SizedBox(height: 12),

        _buildActionCard(
          icon: Icons.analytics_outlined,
          title: "Vue d'ensemble",
          description:
              "Consulter la situation et l'activité générale du projet.",
          onTap: _openOverview,
        ),

        _buildActionCard(
          icon: Icons.folder_open_outlined,
          title: "Données du projet",
          description:
              "Consulter les données enregistrées par les responsables.",
          onTap: _openProjectData,
        ),

        _buildActionCard(
          icon: Icons.people_outline,
          title: "Responsabilités",
          description:
              "Voir les responsabilités et les personnes affectées.",
          onTap: _showAllResponsibilities,
        ),

        _buildActionCard(
          icon: Icons.search,
          title: "Recherche et filtres",
          description:
              "Rechercher et filtrer les données du projet.",
          onTap: () {
            _showMessage(
              "Recherche et filtres",
              "Cette fonctionnalité sera ajoutée après la consultation des données.",
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                _iconBox(icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VRAIE VUE D'ENSEMBLE
  // ============================================================

  void _openOverview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height:
              MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),

              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius:
                      BorderRadius.circular(8),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                "Vue d'ensemble",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                projectName,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 15),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    5,
                    20,
                    30,
                  ),
                  children: [
                    _buildOverviewModalStats(),
                    const SizedBox(height: 22),

                    _buildSectionTitle(
                      "Activité des responsabilités",
                      Icons.timeline,
                    ),

                    const SizedBox(height: 12),

                    _buildResponsibilitiesActivity(),

                    const SizedBox(height: 22),

                    _buildSectionTitle(
                      "Données récentes",
                      Icons.history,
                    ),

                    const SizedBox(height: 12),

                    _buildRecentEntries(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewModalStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: "Responsabilités",
            value:
                widget.responsibilities.length.toString(),
            icon: Icons.assignment_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: "Données",
            value: _entries.length.toString(),
            icon: Icons.data_usage_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildResponsibilitiesActivity() {
    if (widget.responsibilities.isEmpty) {
      return _emptyCard(
        icon: Icons.assignment_outlined,
        message:
            "Aucune responsabilité n'est configurée pour ce projet.",
      );
    }

    return Column(
      children: widget.responsibilities.map((responsibility) {
        final latestEntry =
            _getLatestEntryForResponsibility(
          responsibility,
        );

        return _buildResponsibilityActivityItem(
          responsibility,
          latestEntry,
        );
      }).toList(),
    );
  }

  Map<String, dynamic>? _getLatestEntryForResponsibility(
    Map<String, dynamic> responsibility,
  ) {
    final responsibilityId =
        responsibility["id"];

    final matchingEntries = _entries.where(
      (entry) =>
          entry["responsibility"] ==
          responsibilityId,
    );

    if (matchingEntries.isEmpty) {
      return null;
    }

    final list = matchingEntries.toList();

    list.sort(
      (a, b) {
        final dateA =
            DateTime.tryParse(
                  a["created_at"]?.toString() ?? "",
                ) ??
                DateTime(2000);

        final dateB =
            DateTime.tryParse(
                  b["created_at"]?.toString() ?? "",
                ) ??
                DateTime(2000);

        return dateB.compareTo(dateA);
      },
    );

    return list.first;
  }

  Widget _buildResponsibilityActivityItem(
    Map<String, dynamic> responsibility,
    Map<String, dynamic>? latestEntry,
  ) {
    final name =
        responsibility["name"]?.toString() ??
            "Responsabilité";

    final responsible =
        responsibility["responsible_name"]
                ?.toString() ??
            "Non défini";

    final support =
        responsibility["support_name"]
                ?.toString() ??
            "";

    final hasData = latestEntry != null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: hasData
                  ? AppColors.primarySoft
                  : Colors.grey.shade100,
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: Icon(
              hasData
                  ? Icons.check_circle_outline
                  : Icons.remove_circle_outline,
              color: hasData
                  ? AppColors.primary
                  : AppColors.textMuted,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  "Responsable : $responsible",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),

                if (support.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    "Appui : $support",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(height: 7),

                if (hasData)
                  Text(
                    "Dernière activité : "
                    "${_formatDate(
                      latestEntry!["created_at"],
                    )}",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    "Aucune donnée enregistrée",
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEntries() {
    if (_entriesError != null) {
      return _emptyCard(
        icon: Icons.cloud_off_outlined,
        message: _entriesError!,
      );
    }

    if (_loadingEntries) {
      return const Padding(
        padding: EdgeInsets.all(25),
        child: Center(
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return _emptyCard(
        icon: Icons.inbox_outlined,
        message:
            "Aucune donnée enregistrée pour le moment.",
      );
    }

    final recentEntries =
        List<Map<String, dynamic>>.from(_entries);

    recentEntries.sort(
      (a, b) {
        final dateA =
            DateTime.tryParse(
                  a["created_at"]?.toString() ?? "",
                ) ??
                DateTime(2000);

        final dateB =
            DateTime.tryParse(
                  b["created_at"]?.toString() ?? "",
                ) ??
                DateTime(2000);

        return dateB.compareTo(dateA);
      },
    );

    final limitedEntries =
        recentEntries.take(5).toList();

    return Column(
      children: limitedEntries.map(
        (entry) {
          final responsibility =
              entry["responsibility_name"]
                      ?.toString() ??
                  "Responsabilité";

          final createdBy =
              entry["created_by_name"]
                      ?.toString() ??
                  "Utilisateur";

          return Container(
            width: double.infinity,
            margin:
                const EdgeInsets.only(bottom: 10),
            padding:
                const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _iconBox(
                  Icons.assignment_outlined,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        responsibility,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Saisi par : $createdBy",
                        style: TextStyle(
                          color:
                              AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(
                          entry["created_at"],
                        ),
                        style: TextStyle(
                          color:
                              AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ).toList(),
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 38,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DONNÉES DU PROJET
  // ============================================================

  Future<void> _openProjectData() async {
    await _loadProjectEntries();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height:
              MediaQuery.of(context).size.height * 0.82,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),

              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius:
                      BorderRadius.circular(8),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                "Données du projet",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                projectName,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 15),

              Expanded(
                child: _buildEntriesContent(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEntriesContent() {
    if (_loadingEntries) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    if (_entriesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 45,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                _entriesError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 15),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openProjectData();
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Réessayer"),
              ),
            ],
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 50,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              const Text(
                "Aucune donnée enregistrée.",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Les données saisies par les responsables "
                "apparaîtront ici.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        20,
        5,
        20,
        25,
      ),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        return _buildEntryCard(
          _entries[index],
        );
      },
    );
  }

  Widget _buildEntryCard(
    Map<String, dynamic> entry,
  ) {
    final responsibility =
        entry["responsibility_name"]
                ?.toString() ??
            "Responsabilité";

    final createdBy =
        entry["created_by_name"]
                ?.toString() ??
            "Utilisateur";

    final createdAt =
        entry["created_at"]
                ?.toString() ??
            "";

    final notes =
        entry["notes"]
                ?.toString() ??
            "";

    final data = entry["data"];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _iconBox(
                Icons.assignment_outlined,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      responsibility,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Saisi par : $createdBy",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (createdAt.isNotEmpty)
            Text(
              "Date : ${_formatDate(createdAt)}",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),

          const SizedBox(height: 10),

          if (data is Map && data.isNotEmpty)
            _buildDataPreview(
              Map<String, dynamic>.from(data),
            ),

          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              "Note : $notes",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataPreview(
    Map<String, dynamic> data,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: data.entries
            .take(8)
            .map(
              (item) {
                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 6,
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatFieldName(
                            item.key,
                          ),
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Text(
                          _formatValue(
                            item.value,
                          ),
                          style: TextStyle(
                            color:
                                AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
            .toList(),
      ),
    );
  }

  String _formatFieldName(String value) {
    final withSpaces =
        value.replaceAll("_", " ");

    return withSpaces.replaceFirstMapped(
      RegExp(r"^[a-z]"),
      (match) =>
          match.group(0)!.toUpperCase(),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return "";

    if (value is List) {
      return value.join(", ");
    }

    if (value is Map) {
      return value.toString();
    }

    return value.toString();
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return "Date inconnue";
    }

    final text = value.toString();

    final date = DateTime.tryParse(text);

    if (date == null) {
      return text;
    }

    final local = date.toLocal();

    final day =
        local.day.toString().padLeft(2, "0");
    final month =
        local.month.toString().padLeft(2, "0");
    final year =
        local.year.toString();

    final hour =
        local.hour.toString().padLeft(2, "0");
    final minute =
        local.minute.toString().padLeft(2, "0");

    return "$day/$month/$year à $hour:$minute";
  }

  // ============================================================
  // ACTIVITÉ SUR LA PAGE PRINCIPALE
  // ============================================================

  Widget _buildActivitySection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            "Activité des responsabilités",
            Icons.timeline,
          ),
          const SizedBox(height: 15),
          _buildResponsibilitiesActivity(),
        ],
      ),
    );
  }

  // ============================================================
  // RESPONSABILITÉS
  // ============================================================

  Widget _buildResponsibilitiesSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            "Responsabilités du projet",
            Icons.assignment_ind_outlined,
          ),
          const SizedBox(height: 15),

          if (widget.responsibilities.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 15,
              ),
              child: Text(
                "Aucune responsabilité affectée.",
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...widget.responsibilities.map(
              (responsibility) {
                return _buildResponsibilityItem(
                  responsibility,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildResponsibilityItem(
    Map<String, dynamic> responsibility,
  ) {
    final name =
        responsibility["name"]
                ?.toString() ??
            "Responsabilité";

    final description =
        responsibility["description"]
                ?.toString() ??
            "";

    final responsibleName =
        responsibility["responsible_name"]
                ?.toString() ??
            "";

    final supportName =
        responsibility["support_name"]
                ?.toString() ??
            "";

    final frequency =
        responsibility["frequency"]
                ?.toString() ??
            "";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: () {
          _showResponsibilityDetails(
            responsibility,
          );
        },
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _iconBox(Icons.assignment),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (responsibleName.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      "Responsable : $responsibleName",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],

                  if (supportName.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      "Appui : $supportName",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],

                  if (frequency.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      "Fréquence : $frequency",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],

                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      description,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATIONS
  // ============================================================

  Widget _buildInformationSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            "À propos de cet espace",
            Icons.info_outline,
          ),
          const SizedBox(height: 12),
          Text(
            "L'espace coordinateur permet de piloter le "
            "projet et de consulter les informations "
            "enregistrées par les responsables.",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LISTE RESPONSABILITÉS
  // ============================================================

  void _showAllResponsibilities() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height:
              MediaQuery.of(context).size.height *
                  0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),

              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius:
                      BorderRadius.circular(8),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                "Responsabilités du projet",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.all(20),
                  itemCount:
                      widget.responsibilities.length,
                  itemBuilder: (context, index) {
                    return _buildBottomSheetResponsibility(
                      widget.responsibilities[index],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetResponsibility(
    Map<String, dynamic> responsibility,
  ) {
    final name =
        responsibility["name"]
                ?.toString() ??
            "Responsabilité";

    final responsible =
        responsibility["responsible_name"]
                ?.toString() ??
            "Non défini";

    final support =
        responsibility["support_name"]
                ?.toString() ??
            "";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Responsable principal : $responsible",
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
          if (support.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              "Appui : $support",
              style: const TextStyle(
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // DÉTAIL RESPONSABILITÉ
  // ============================================================

  void _showResponsibilityDetails(
    Map<String, dynamic> responsibility,
  ) {
    final name =
        responsibility["name"]
                ?.toString() ??
            "Responsabilité";

    final description =
        responsibility["description"]
                ?.toString() ??
            "";

    final responsible =
        responsibility["responsible_name"]
                ?.toString() ??
            "Non défini";

    final support =
        responsibility["support_name"]
                ?.toString() ??
            "Non défini";

    final frequency =
        responsibility["frequency"]
                ?.toString() ??
            "Non définie";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (description.isNotEmpty) ...[
                  const Text(
                    "Description",
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(description),
                  const SizedBox(height: 15),
                ],

                const Text(
                  "Responsable principal",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(responsible),

                const SizedBox(height: 12),

                const Text(
                  "Appui",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(support),

                const SizedBox(height: 12),

                const Text(
                  "Fréquence",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(frequency),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Fermer"),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Compris"),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // COMPOSANTS
  // ============================================================

  Widget _buildSectionTitle(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: primaryColor,
          size: 21,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: child,
    );
  }

  Widget _iconBox(
    IconData icon,
  ) {
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: primaryColor,
        size: 22,
      ),
    );
  }
}