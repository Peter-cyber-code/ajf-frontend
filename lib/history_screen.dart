import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic> project;
  final Map<String, dynamic> responsibility;

  const HistoryScreen({
    super.key,
    required this.user,
    required this.project,
    required this.responsibility,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  String? _error;

  List<dynamic> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // ============================================================
  // CHARGEMENT DE L'HISTORIQUE
  // ============================================================

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final responsibilityId =
          widget.responsibility['id'];

      final response = await http.get(
        Uri.parse(
          'https://myajf-backend.onrender.com/api/responsibilities/'
          '$responsibilityId/entries/',
        ),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          if (data is List) {
            _entries = data;
          } else if (data is Map &&
              data['results'] is List) {
            _entries = data['results'];
          } else {
            _entries = [];
          }

          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _error =
              'Impossible de charger l’historique.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error =
            'Impossible de contacter le serveur.';
      });
    }
  }

  // ============================================================
  // FORMATAGE DATE
  // ============================================================

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) {
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
    if (value == null || value.isEmpty) {
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
  // RÉSUMÉ D'UNE DONNÉE
  // ============================================================

  String _entrySummary(Map<String, dynamic> entry) {
    final data = entry['data'];

    if (data is! Map || data.isEmpty) {
      return 'Aucune donnée détaillée';
    }

    final values = <String>[];

    for (final item in data.entries) {
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
  // OBTENIR LA DATE DE RÉALISATION
  // ============================================================

  String? _getActionDate(Map<String, dynamic> entry) {
    final data = entry['data'];

    if (data is! Map) {
      return null;
    }

    // On cherche quelques noms courants.
    const possibleNames = [
      'date_action',
      'date_realisation',
      'date_visite',
      'date_operation',
      'action_date',
    ];

    for (final name in possibleNames) {
      final value = data[name];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return null;
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
        builder: (_) => HistoryDetailScreen(
          entry: entry,
          user: widget.user,
          project: widget.project,
          responsibility: widget.responsibility,
        ),
      ),
    );
  }

  // ============================================================
  // CARTE HISTORIQUE
  // ============================================================

  Widget _buildEntryCard(
    Map<String, dynamic> entry,
  ) {
    final actionDate =
        _getActionDate(entry);

    final createdAt =
        entry['created_at']?.toString();

    final summary =
        _entrySummary(entry);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
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
          padding:
              const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.primarySoft,
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color:
                          AppColors.primary,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          widget.responsibility[
                                  'name'] ??
                              'Responsabilité',
                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          summary,
                          maxLines: 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color:
                                AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons
                        .chevron_right_rounded,
                    color:
                        AppColors.textMuted,
                  ),
                ],
              ),

              const SizedBox(
                height: 15,
              ),

              const Divider(
                height: 1,
              ),

              const SizedBox(
                height: 13,
              ),

              // DATE DE RÉALISATION
              if (actionDate != null)
                Row(
                  children: [
                    const Icon(
                      Icons
                          .event_outlined,
                      size: 18,
                      color:
                          AppColors.primary,
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    const Text(
                      'Réalisation : ',
                      style:
                          TextStyle(
                        fontSize: 13,
                        color:
                            AppColors.textSecondary,
                      ),
                    ),

                    Text(
                      _formatDate(
                        actionDate,
                      ),
                      style:
                          const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),

              if (actionDate != null)
                const SizedBox(
                  height: 8,
                ),

              // DATE DE SAISIE
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 18,
                    color:
                        AppColors.primary,
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  const Text(
                    'Saisie : ',
                    style:
                        TextStyle(
                      fontSize: 13,
                      color:
                          AppColors.textSecondary,
                    ),
                  ),

                  Text(
                    _formatDateTime(
                      createdAt,
                    ),
                    style:
                        const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                    ),
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
  // ÉCRAN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final projectName =
        widget.project['name'] ??
            'Projet';

    final responsibilityName =
        widget.responsibility['name'] ??
            'Responsabilité';

    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Mon historique',
          style: TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView(
          padding:
              const EdgeInsets.all(20),
          children: [
            // --------------------------------------------------
            // EN-TÊTE
            // --------------------------------------------------

            Text(
              responsibilityName,
              style:
                  const TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              projectName,
              style:
                  const TextStyle(
                color:
                    AppColors.textSecondary,
                fontSize: 14,
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            // --------------------------------------------------
            // CHARGEMENT
            // --------------------------------------------------

            if (_loading)
              const Padding(
                padding:
                    EdgeInsets.only(
                  top: 80,
                ),
                child: Center(
                  child:
                      CircularProgressIndicator(
                    color:
                        AppColors.primary,
                  ),
                ),
              )

            // --------------------------------------------------
            // ERREUR
            // --------------------------------------------------

            else if (_error != null)
              Container(
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFFFEBEE,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons
                          .error_outline,
                      color:
                          AppColors.error,
                      size: 40,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Text(
                      _error!,
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color:
                            AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    OutlinedButton.icon(
                      onPressed:
                          _loadHistory,
                      icon:
                          const Icon(
                        Icons.refresh,
                      ),
                      label:
                          const Text(
                        'Réessayer',
                      ),
                    ),
                  ],
                ),
              )

            // --------------------------------------------------
            // AUCUNE DONNÉE
            // --------------------------------------------------

            else if (_entries.isEmpty)
              Container(
                padding:
                    const EdgeInsets.all(
                  30,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration:
                          BoxDecoration(
                        color:
                            AppColors.primarySoft,
                        borderRadius:
                            BorderRadius
                                .circular(
                          22,
                        ),
                      ),
                      child:
                          const Icon(
                        Icons
                            .history,
                        size: 35,
                        color:
                            AppColors.primary,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    const Text(
                      'Aucune donnée enregistrée',
                      style:
                          TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    const Text(
                      'Les données que vous saisirez pour cette responsabilité apparaîtront ici.',
                      textAlign:
                          TextAlign.center,
                      style:
                          TextStyle(
                        color:
                            AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              )

            // --------------------------------------------------
            // LISTE
            // --------------------------------------------------

            else
              ..._entries
                  .whereType<
                      Map<String,
                          dynamic>>()
                  .map(
                    _buildEntryCard,
                  ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// DÉTAIL D'UNE SAISIE
// ============================================================

class HistoryDetailScreen
    extends StatelessWidget {
  final Map<String, dynamic> entry;
  final Map<String, dynamic> user;
  final Map<String, dynamic> project;
  final Map<String, dynamic> responsibility;

  const HistoryDetailScreen({
    super.key,
    required this.entry,
    required this.user,
    required this.project,
    required this.responsibility,
  });

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) {
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
    if (value == null || value.isEmpty) {
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

  String? _getActionDate() {
    final data = entry['data'];

    if (data is! Map) {
      return null;
    }

    const possibleNames = [
      'date_action',
      'date_realisation',
      'date_visite',
      'date_operation',
      'action_date',
    ];

    for (final name in possibleNames) {
      final value = data[name];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return null;
  }

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
            color:
                AppColors.primary,
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  label,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        AppColors.textMuted,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

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

  Widget _buildDataCard(
    String key,
    dynamic value,
  ) {
    String displayValue;

    if (value == null) {
      displayValue = '';
    } else if (value is List) {
      displayValue =
          value.join(', ');
    } else if (value is Map) {
      displayValue =
          jsonEncode(value);
    } else {
      displayValue =
          value.toString();
    }

    // Transformer certains noms techniques
    // en titres plus lisibles.
    final label = key
        .replaceAll('_', ' ')
        .trim();

    final formattedLabel =
        label.isEmpty
            ? key
            : '${label[0].toUpperCase()}'
              '${label.substring(1)}';

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
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
            CrossAxisAlignment
                .start,
        children: [
          Text(
            formattedLabel,
            style:
                const TextStyle(
              fontSize: 13,
              color:
                  AppColors.textSecondary,
              fontWeight:
                  FontWeight.w500,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          Text(
            displayValue.isEmpty
                ? '—'
                : displayValue,
            style:
                const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actionDate =
        _getActionDate();

    final data = entry['data'];

    final notes =
        entry['notes']?.toString() ??
            '';

    final createdAt =
        entry['created_at']
            ?.toString();

    final fullName =
        user['full_name'] ??
            user['username'] ??
            'Responsable';

    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Détails',
          style: TextStyle(
            fontWeight:
                FontWeight.w600,
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

          Text(
            responsibility['name'] ??
                'Responsabilité',
            style:
                const TextStyle(
              fontSize: 24,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            project['name'] ??
                'Projet',
            style:
                const TextStyle(
              color:
                  AppColors.textSecondary,
            ),
          ),

          const SizedBox(
            height: 22,
          ),

          // ----------------------------------------------------
          // INFORMATIONS GÉNÉRALES
          // ----------------------------------------------------

          if (actionDate != null)
            _buildInfoCard(
              icon:
                  Icons.event_outlined,
              label:
                  'Date de réalisation',
              value:
                  _formatDate(
                actionDate,
              ),
            ),

          _buildInfoCard(
            icon:
                Icons.access_time,
            label:
                'Date de saisie',
            value:
                _formatDateTime(
              createdAt,
            ),
          ),

          _buildInfoCard(
            icon:
                Icons.person_outline,
            label:
                'Saisi par',
            value:
                fullName.toString(),
          ),

          const SizedBox(
            height: 10,
          ),

          // ----------------------------------------------------
          // DONNÉES
          // ----------------------------------------------------

          const Text(
            'Données enregistrées',
            style:
                TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

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
                  const EdgeInsets.all(
                18,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child:
                  const Text(
                'Aucune donnée détaillée.',
                style:
                    TextStyle(
                  color:
                      AppColors.textSecondary,
                ),
              ),
            ),

          // ----------------------------------------------------
          // NOTES
          // ----------------------------------------------------

          if (notes.trim().isNotEmpty) ...[
            const SizedBox(
              height: 10,
            ),

            const Text(
              'Notes',
              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(
                18,
              ),
              decoration:
                  BoxDecoration(
                color:
                    AppColors.primarySoft,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child:
                  Text(
                notes,
                style:
                    const TextStyle(
                  height: 1.5,
                ),
              ),
            ),
          ],

          const SizedBox(
            height: 30,
          ),
        ],
      ),
    );
  }
}