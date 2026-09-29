import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'theme/app_theme.dart';

class ProjectDataScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const ProjectDataScreen({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDataScreen> createState() => _ProjectDataScreenState();
}

class _ProjectDataScreenState extends State<ProjectDataScreen> {
  static const Color primaryColor = AppColors.primary;
  static const Color backgroundColor = AppColors.background;

  bool _loading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _entries = [];
  List<Map<String, dynamic>> _responsibilities = [];

  String _selectedPeriod = 'all';
  String _selectedResponsibility = 'all';
  bool _showArchives = false;

  String _searchQuery = '';

  final TextEditingController _searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // CHARGEMENT DES DONNÉES
  // ============================================================

  Future<void> _loadProjectData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final projectId = widget.project['id'];

      final entriesUri = Uri.parse(
        'https://myajf-backend.onrender.com/api/projects/$projectId/entries/',
      ).replace(
        queryParameters: {
          if (_showArchives) 'archived': 'true',
          if (_selectedPeriod != 'all')
            'period': _selectedPeriod,
          if (_selectedResponsibility != 'all')
            'responsibility_id': _selectedResponsibility,
        },
      );

      final responsibilitiesUri = Uri.parse(
        'https://myajf-backend.onrender.com/api/projects/$projectId/responsibilities/',
      );

      final responses = await Future.wait([
        http.get(entriesUri),
        http.get(responsibilitiesUri),
      ]);

      if (!mounted) return;

      final entriesResponse = responses[0];
      final responsibilitiesResponse = responses[1];

      if (entriesResponse.statusCode != 200) {
        setState(() {
          _loading = false;
          _errorMessage =
              'Le serveur a retourné une erreur '
              '(${entriesResponse.statusCode}).';
        });
        return;
      }

      final entriesDecoded = jsonDecode(entriesResponse.body);

      final loadedEntries = <Map<String, dynamic>>[];

      if (entriesDecoded is List) {
        for (final item in entriesDecoded) {
          if (item is Map) {
            loadedEntries.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      } else if (entriesDecoded is Map &&
          entriesDecoded['results'] is List) {
        for (final item in entriesDecoded['results']) {
          if (item is Map) {
            loadedEntries.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      }

      final loadedResponsibilities = <Map<String, dynamic>>[];

      if (responsibilitiesResponse.statusCode == 200) {
        final responsibilitiesDecoded =
            jsonDecode(responsibilitiesResponse.body);

        if (responsibilitiesDecoded is List) {
          for (final item in responsibilitiesDecoded) {
            if (item is Map) {
              loadedResponsibilities.add(
                Map<String, dynamic>.from(item),
              );
            }
          }
        } else if (responsibilitiesDecoded is Map &&
            responsibilitiesDecoded['results'] is List) {
          for (final item
              in responsibilitiesDecoded['results']) {
            if (item is Map) {
              loadedResponsibilities.add(
                Map<String, dynamic>.from(item),
              );
            }
          }
        }
      }

      setState(() {
        _entries = loadedEntries;
        _responsibilities = loadedResponsibilities;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage =
            'Impossible de contacter le serveur.';
      });
    }
  }

  // ============================================================
  // RECHERCHE
  // ============================================================

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim().toLowerCase();
    });
  }

  List<Map<String, dynamic>> get _filteredEntries {
    if (_searchQuery.isEmpty) {
      return _entries;
    }

    return _entries.where((entry) {
      final responsibility =
          (entry['responsibility_name'] ?? '')
              .toString()
              .toLowerCase();

      final createdBy =
          (entry['created_by_name'] ?? '')
              .toString()
              .toLowerCase();

      final notes =
          (entry['notes'] ?? '')
              .toString()
              .toLowerCase();

      final data = entry['data'];

      String dataText = '';

      if (data is Map) {
        dataText = data.entries
            .map(
              (item) =>
                  '${item.key} ${item.value}',
            )
            .join(' ')
            .toLowerCase();
      }

      return responsibility.contains(_searchQuery) ||
          createdBy.contains(_searchQuery) ||
          notes.contains(_searchQuery) ||
          dataText.contains(_searchQuery);
    }).toList();
  }

  // ============================================================
  // FORMATAGE
  // ============================================================

  String _formatLabel(String value) {
    if (value.isEmpty) return value;

    final formatted = value
        .replaceAll('_', ' ')
        .trim();

    if (formatted.isEmpty) return value;

    return formatted[0].toUpperCase() +
        formatted.substring(1);
  }

  String _formatDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Non renseignée';
    }

    try {
      final date = DateTime.parse(value);

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return value;
    }
  }

  String _formatDateTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Non renseignée';
    }

    try {
      final date = DateTime.parse(value).toLocal();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} à '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value;
    }
  }

  // ============================================================
  // DATE DE L'ACTIVITÉ
  // ============================================================

  String? _getActivityDate(
    Map<String, dynamic> entry,
  ) {
    final data = entry['data'];

    if (data is Map) {
      final value = data['date_activite'];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString();
      }

      const possibleNames = [
        'date_action',
        'date_realisation',
        'date_visite',
        'date_operation',
        'action_date',
      ];

      for (final name in possibleNames) {
        final possibleValue = data[name];

        if (possibleValue != null &&
            possibleValue
                .toString()
                .trim()
                .isNotEmpty) {
          return possibleValue.toString();
        }
      }
    }

    return null;
  }

  // ============================================================
  // RÉSUMÉ D'UNE DONNÉE
  // ============================================================

  String _entrySummary(
    Map<String, dynamic> entry,
  ) {
    final data = entry['data'];

    if (data is! Map || data.isEmpty) {
      return 'Aucune donnée détaillée';
    }

    final values = <String>[];

    for (final item in data.entries) {
      final key = item.key.toString();

      // On évite de répéter la date dans le résumé.
      if (key == 'date_activite') {
        continue;
      }

      final value = item.value;

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        values.add(value.toString());
      }
    }

    if (values.isEmpty) {
      return 'Aucune donnée détaillée';
    }

    return values.take(2).join(' • ');
  }

  // ============================================================
  // VALEUR LISIBILE
  // ============================================================

  String _formatValue(dynamic value) {
    if (value == null) {
      return '—';
    }

    if (value is List) {
      return value.join(', ');
    }

    if (value is Map) {
      return jsonEncode(value);
    }

    return value.toString();
  }

  // ============================================================
  // ICÔNE PAR RESPONSABILITÉ
  // ============================================================

  IconData _getResponsibilityIcon(
    String responsibilityName,
  ) {
    final name =
        responsibilityName.toLowerCase();

    if (name.contains('sant')) {
      return Icons.health_and_safety_outlined;
    }

    if (name.contains('aliment')) {
      return Icons.restaurant_outlined;
    }

    if (name.contains('vente') ||
        name.contains('client')) {
      return Icons.shopping_cart_outlined;
    }

    if (name.contains('stock') ||
        name.contains('oeuf') ||
        name.contains("œuf")) {
      return Icons.inventory_2_outlined;
    }

    if (name.contains('financ') ||
        name.contains('comptab')) {
      return Icons.account_balance_wallet_outlined;
    }

    if (name.contains('communication') ||
        name.contains('informatique')) {
      return Icons.campaign_outlined;
    }

    if (name.contains('conseil')) {
      return Icons.lightbulb_outline;
    }

    if (name.contains('veille')) {
      return Icons.visibility_outlined;
    }

    if (name.contains('terrain')) {
      return Icons.location_on_outlined;
    }

    return Icons.assignment_outlined;
  }

  // ============================================================
  // OUVRIR LES DÉTAILS
  // ============================================================

  void _openDetails(
    Map<String, dynamic> entry,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectEntryDetailScreen(
          entry: entry,
          project: widget.project,
        ),
      ),
    );
  }

  // ============================================================
  // CARTE D'UNE DONNÉE
  // ============================================================

  Widget _buildEntryCard(
    Map<String, dynamic> entry,
  ) {
    final responsibilityName =
        entry['responsibility_name'] ??
            'Responsabilité';

    final createdBy =
        entry['created_by_name'] ??
            'Membre';

    final createdAt =
        entry['created_at']?.toString();

    final activityDate =
        _getActivityDate(entry);

    final summary =
        _entrySummary(entry);

    final archived =
        entry['archived'] == true;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 13,
      ),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(12),
        side: const BorderSide(
          color: AppColors.border,
        ),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),
        onTap: () {
          _openDetails(entry);
        },
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------
              // RESPONSABILITÉ
              // ------------------------------------------------

              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color:
                          AppColors.primarySoft,
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getResponsibilityIcon(
                        responsibilityName.toString(),
                      ),
                      color: primaryColor,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          responsibilityName
                              .toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Saisi par : '
                          '$createdBy',
                          style: const TextStyle(
                            fontSize: 12,
                            color:
                                AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (archived)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            AppColors.border,
                        borderRadius:
                            BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Archivé',
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              AppColors.textSecondary,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                ],
              ),

              const SizedBox(height: 14),

              const Divider(height: 1),

              const SizedBox(height: 13),

              // ------------------------------------------------
              // DATE D'ACTIVITÉ
              // ------------------------------------------------

              if (activityDate != null)
                Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 17,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      'Activité : ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _formatDate(activityDate),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),

              if (activityDate != null)
                const SizedBox(height: 10),

              // ------------------------------------------------
              // DATE DE SAISIE
              // ------------------------------------------------

              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 17,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'Saisie : ',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _formatDateTime(createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ------------------------------------------------
              // RÉSUMÉ
              // ------------------------------------------------

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color:
                      AppColors.background,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Text(
                  summary,
                  maxLines: 3,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: [
                  Text(
                    'Voir les détails',
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryColor,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ÉTAT VIDE
  // ============================================================

  Widget _buildEmptyState() {
    final message = _showArchives
        ? 'Aucune donnée archivée'
        : _searchQuery.isNotEmpty
            ? 'Aucun résultat trouvé'
            : 'Aucune donnée disponible';

    final description = _showArchives
        ? 'Les données archivées du projet apparaîtront ici.'
        : _searchQuery.isNotEmpty
            ? 'Essayez avec un autre mot-clé ou modifiez vos filtres.'
            : 'Les données enregistrées dans les différentes responsabilités du projet apparaîtront ici.';

    return Container(
      margin:
          const EdgeInsets.only(top: 10),
      padding:
          const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color:
                  AppColors.primarySoft,
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: Icon(
              _showArchives
                  ? Icons.archive_outlined
                  : Icons.data_exploration_outlined,
              size: 38,
              color: primaryColor,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTRE PÉRIODE
  // ============================================================

  Widget _buildPeriodFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedPeriod,
      decoration: InputDecoration(
        labelText: 'Période',
        prefixIcon: const Icon(
          Icons.date_range_outlined,
          color: primaryColor,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      items: const [
        DropdownMenuItem(
          value: 'all',
          child: Text('Toutes les périodes'),
        ),
        DropdownMenuItem(
          value: 'today',
          child: Text("Aujourd'hui"),
        ),
        DropdownMenuItem(
          value: 'week',
          child: Text('Cette semaine'),
        ),
        DropdownMenuItem(
          value: 'month',
          child: Text('Ce mois'),
        ),
        DropdownMenuItem(
          value: '3months',
          child: Text('3 derniers mois'),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _selectedPeriod = value;
        });

        _loadProjectData();
      },
    );
  }

  // ============================================================
  // FILTRE RESPONSABILITÉ
  // ============================================================

  Widget _buildResponsibilityFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedResponsibility,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Responsabilité',
        prefixIcon: const Icon(
          Icons.category_outlined,
          color: primaryColor,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: 'all',
          child: Text(
            'Toutes les responsabilités',
          ),
        ),
        ..._responsibilities.map(
          (responsibility) {
            return DropdownMenuItem<String>(
              value:
                  responsibility['id']
                      .toString(),
              child: Text(
                responsibility['name']
                        ?.toString() ??
                    'Responsabilité',
                overflow:
                    TextOverflow.ellipsis,
              ),
            );
          },
        ),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _selectedResponsibility =
              value;
        });

        _loadProjectData();
      },
    );
  }

  // ============================================================
  // BOUTON ARCHIVES
  // ============================================================

  Widget _buildArchiveButton() {
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _showArchives = !_showArchives;
        });

        _loadProjectData();
      },
      icon: Icon(
        _showArchives
            ? Icons.folder_open_outlined
            : Icons.archive_outlined,
      ),
      label: Text(
        _showArchives
            ? 'Données actives'
            : 'Voir les archives',
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(
          color: primaryColor,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // FILTRES
  // ============================================================

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText:
                'Rechercher dans les données...',
            prefixIcon: const Icon(
              Icons.search,
              color: primaryColor,
            ),
            suffixIcon:
                _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController
                              .clear();
                          _onSearchChanged('');
                        },
                        icon: const Icon(
                          Icons.clear,
                        ),
                      )
                    : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(12),
              borderSide:
                  const BorderSide(
                color: AppColors.border,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        _buildPeriodFilter(),

        const SizedBox(height: 12),

        _buildResponsibilityFilter(),

        const SizedBox(height: 12),

        _buildArchiveButton(),
      ],
    );
  }

  // ============================================================
  // CORPS
  // ============================================================

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color:
                      AppColors.errorSoft,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.cloud_off_outlined,
                  size: 34,
                  color: AppColors.error,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Impossible de charger les données',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 22),

              FilledButton.icon(
                onPressed:
                    _loadProjectData,
                icon:
                    const Icon(Icons.refresh),
                label:
                    const Text('Réessayer'),
                style:
                    FilledButton.styleFrom(
                  backgroundColor:
                      primaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final visibleEntries =
        _filteredEntries;

    return RefreshIndicator(
      color: primaryColor,
      onRefresh:
          _loadProjectData,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          35,
        ),
        children: [
          // ----------------------------------------------------
          // TITRE
          // ----------------------------------------------------

          Text(
            _showArchives
                ? 'Archives du projet'
                : 'Espace commun',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            widget.project['name'] ??
                'Projet',
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 20),

          // ----------------------------------------------------
          // EXPLICATION
          // ----------------------------------------------------

          Container(
            padding:
                const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  AppColors.primarySoft,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.people_alt_outlined,
                  color: primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _showArchives
                        ? 'Consultez les anciennes données du projet.'
                        : 'Consultez ici les données enregistrées par les différentes responsabilités du projet.',
                    style:
                        const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ----------------------------------------------------
          // FILTRES
          // ----------------------------------------------------

          _buildFilters(),

          const SizedBox(height: 20),

          // ----------------------------------------------------
          // RÉSULTAT
          // ----------------------------------------------------

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(12),
              border: Border.all(
                color:
                    AppColors.border,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  color: primaryColor,
                  size: 21,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    visibleEntries.length == 1
                        ? '1 donnée trouvée'
                        : '${visibleEntries.length} données trouvées',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ----------------------------------------------------
          // LISTE
          // ----------------------------------------------------

          if (visibleEntries.isEmpty)
            _buildEmptyState()
          else
            ...visibleEntries.map(
              _buildEntryCard,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Données du projet',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }
}

// ================================================================
// ÉCRAN DÉTAIL D'UNE DONNÉE DU PROJET
// ================================================================

class ProjectEntryDetailScreen
    extends StatelessWidget {
  final Map<String, dynamic> entry;
  final Map<String, dynamic> project;

  const ProjectEntryDetailScreen({
    super.key,
    required this.entry,
    required this.project,
  });

  static const Color primaryColor =
      AppColors.primary;

  static const Color backgroundColor =
      AppColors.background;

  // ============================================================
  // FORMATAGE
  // ============================================================

  String _formatDate(String? value) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Non renseignée';
    }

    try {
      final date = DateTime.parse(value);

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return value;
    }
  }

  String _formatDateTime(String? value) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Non renseignée';
    }

    try {
      final date =
          DateTime.parse(value).toLocal();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} à '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value;
    }
  }

  String _formatLabel(String key) {
    final label = key
        .replaceAll('_', ' ')
        .trim();

    if (label.isEmpty) return key;

    return label[0].toUpperCase() +
        label.substring(1);
  }

  String _formatValue(dynamic value) {
    if (value == null) {
      return '—';
    }

    if (value is List) {
      return value.join(', ');
    }

    if (value is Map) {
      return jsonEncode(value);
    }

    return value.toString();
  }

  // ============================================================
  // DATE ACTIVITÉ
  // ============================================================

  String? _getActivityDate() {
    final data = entry['data'];

    if (data is! Map) {
      return null;
    }

    final value =
        data['date_activite'];

    if (value != null &&
        value.toString().trim().isNotEmpty) {
      return value.toString();
    }

    const possibleNames = [
      'date_action',
      'date_realisation',
      'date_visite',
      'date_operation',
      'action_date',
    ];

    for (final name in possibleNames) {
      final possibleValue = data[name];

      if (possibleValue != null &&
          possibleValue
              .toString()
              .trim()
              .isNotEmpty) {
        return possibleValue.toString();
      }
    }

    return null;
  }

  // ============================================================
  // CARTE INFORMATION
  // ============================================================

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
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
  // CARTE DONNÉE
  // ============================================================

  Widget _buildDataCard(
    String key,
    dynamic value,
  ) {
    final displayValue =
        _formatValue(value);

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 12),
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            _formatLabel(key),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            displayValue.isEmpty
                ? '—'
                : displayValue,
            style: const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final responsibilityName =
        entry['responsibility_name']
                ?.toString() ??
            'Responsabilité';

    final createdBy =
        entry['created_by_name']
                ?.toString() ??
            'Membre';

    final createdAt =
        entry['created_at']?.toString();

    final activityDate =
        _getActivityDate();

    final notes =
        entry['notes']?.toString() ?? '';

    final data = entry['data'];

    final archived =
        entry['archived'] == true;

    return Scaffold(
      backgroundColor:
          backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Détails',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(20),
        children: [
          // ----------------------------------------------------
          // RESPONSABILITÉ
          // ----------------------------------------------------

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  responsibilityName,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              if (archived)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        AppColors.border,
                    borderRadius:
                        BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Archivé',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          AppColors.textSecondary,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            project['name'] ??
                'Projet',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 22),

          // ----------------------------------------------------
          // INFORMATIONS GÉNÉRALES
          // ----------------------------------------------------

          if (activityDate != null)
            _buildInfoCard(
              icon:
                  Icons.event_outlined,
              label:
                  'Date de l’activité',
              value:
                  _formatDate(activityDate),
            ),

          _buildInfoCard(
            icon: Icons.access_time,
            label: 'Date de saisie',
            value:
                _formatDateTime(createdAt),
          ),

          _buildInfoCard(
            icon: Icons.person_outline,
            label: 'Saisi par',
            value: createdBy,
          ),

          const SizedBox(height: 10),

          // ----------------------------------------------------
          // DONNÉES
          // ----------------------------------------------------

          const Text(
            'Données enregistrées',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(height: 14),

          if (data is Map &&
              data.isNotEmpty)
            ...data.entries.map(
              (item) => _buildDataCard(
                item.key.toString(),
                item.value,
              ),
            )
          else
            Container(
              padding:
                  const EdgeInsets.all(18),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: const Text(
                'Aucune donnée détaillée.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ),

          // ----------------------------------------------------
          // NOTES
          // ----------------------------------------------------

          if (notes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),

            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color:
                    AppColors.primarySoft,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Text(
                notes,
                style: const TextStyle(
                  height: 1.5,
                ),
              ),
            ),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}