import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'data_entry_screen.dart';
import 'history_screen.dart';
import 'project_data_screen.dart';
import 'coordinator_dashboard_screen.dart';
import 'theme/app_theme.dart';


// ============================================================
// ACCÈS AUX RESPONSABILITÉS
// ============================================================

// ============================================================
// ACCÈS MEMBRE
// ============================================================

class ResponsibleAccessScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const ResponsibleAccessScreen({
    super.key,
    required this.project,
  });

  @override
  State<ResponsibleAccessScreen> createState() =>
      _ResponsibleAccessScreenState();
}

class _ResponsibleAccessScreenState
    extends State<ResponsibleAccessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'https://myajf-backend.onrender.com/api/responsibilities/access/',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'project_id': widget.project['id'],
          'access_code': _codeController.text.trim(),
        }),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data['success'] == true) {
        final user =
            Map<String, dynamic>.from(data['user'] ?? {});

        final project =
            Map<String, dynamic>.from(data['project'] ?? {});

        final access =
            Map<String, dynamic>.from(data['access'] ?? {});

        final responsibilities =
            List<Map<String, dynamic>>.from(
          (data['responsibilities'] ?? []).map(
            (item) => Map<String, dynamic>.from(item),
          ),
        );

        final isCoordinator =
            access['is_coordinator'] == true;

        // Le coordinateur peut aussi avoir ses propres responsabilités.
        if (isCoordinator) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CoordinatorDashboardScreen(
                user: user,
                project: project,
                responsibilities: responsibilities,
              ),
            ),
          );
        } else if (responsibilities.length == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ResponsibleDashboardScreen(
                user: user,
                project: project,
                responsibility: responsibilities.first,
              ),
            ),
          );
        } else if (responsibilities.length > 1) {
          await _showResponsibilitySelector(
            user: user,
            project: project,
            responsibilities: responsibilities,
          );
        } else {
          _showMessage(
            'Aucune responsabilité ne vous est attribuée dans ce projet.',
          );
        }
      } else {
        _showMessage(
          data['message'] ??
              'Code personnel incorrect ou accès refusé.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Impossible de contacter le serveur : $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _showCoordinatorMessage({
    required Map<String, dynamic> user,
    required Map<String, dynamic> project,
    required List<Map<String, dynamic>> responsibilities,
  }) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Accès coordinateur'),
          content: Text(
            responsibilities.isEmpty
                ? 'Votre accès coordinateur a été reconnu. '
                    'L’espace de pilotage sera disponible dans la prochaine étape.'
                : 'Votre accès coordinateur a été reconnu. '
                    'Vous avez également ${responsibilities.length} '
                    'responsabilité(s) opérationnelle(s).',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Fermer'),
            ),
            if (responsibilities.isNotEmpty)
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);

                  _showResponsibilitySelector(
                    user: user,
                    project: project,
                    responsibilities: responsibilities,
                  );
                },
                child: const Text('Mes responsabilités'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showResponsibilitySelector({
    required Map<String, dynamic> user,
    required Map<String, dynamic> project,
    required List<Map<String, dynamic>> responsibilities,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Choisissez une responsabilité',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vous pouvez accéder à chaque espace qui vous est attribué.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ...responsibilities.map((responsibility) {
                  final accessType =
                      responsibility['access_type']?.toString();

                  final isSupport = accessType == 'support';

                  return Card(
                    color: AppColors.primarySoft,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Icon(
                        isSupport
                            ? Icons.people_alt_outlined
                            : Icons.assignment_ind_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        responsibility['name']?.toString() ??
                            'Responsabilité',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        isSupport
                            ? 'Appui'
                            : 'Responsable principal',
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ResponsibleDashboardScreen(
                              user: user,
                              project: project,
                              responsibility: responsibility,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Accès membre',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),

                Center(
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      size: 42,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Accéder à mes responsabilités',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  widget.project['name'] ?? 'Projet',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Entrez votre code personnel pour identifier '
                  'votre profil et vos responsabilités dans ce projet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 40),

                TextFormField(
                  controller: _codeController,
                  obscureText: _obscure,
                  keyboardType: TextInputType.text,
                  maxLength: 30,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Code personnel',
                    hintText: 'Votre code',
                    counterText: '',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.primary,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscure = !_obscure;
                        });
                      },
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Veuillez entrer votre code personnel';
                    }

                    if (value.trim().length < 4) {
                      return 'Le code doit contenir au moins 4 caractères';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 28),

                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _loading ? null : _continue,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Continuer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Votre code personnel est confidentiel. '
                          'Il permet d’identifier vos accès dans ce projet.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
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
// DASHBOARD RESPONSABLE
// ============================================================

class ResponsibleDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic> project;
  final Map<String, dynamic> responsibility;

  const ResponsibleDashboardScreen({
    super.key,
    required this.user,
    required this.project,
    required this.responsibility,
  });

  @override
  State<ResponsibleDashboardScreen> createState() =>
      _ResponsibleDashboardScreenState();
}

class _ResponsibleDashboardScreenState
    extends State<ResponsibleDashboardScreen> {
  static const Color primaryColor = AppColors.primary;
  static const Color backgroundColor = AppColors.background;

  bool _loadingInitialState = false;
  bool _initialStateConfigured = false;

  Map<String, dynamic> _initialState = {};

  String get _responsibilityName {
    return (widget.responsibility['name'] ?? '')
        .toString()
        .toLowerCase();
  }

  bool get _isEggStorage {
    return _responsibilityName.contains('stock') &&
        (_responsibilityName.contains('oeuf') ||
            _responsibilityName.contains('œuf'));
  }

  bool get _isHealth {
    return _responsibilityName.contains('sant');
  }

  bool get _isFood {
    return _responsibilityName.contains('aliment');
  }

  bool get _isFinance {
    return _responsibilityName.contains('finance') ||
        _responsibilityName.contains('compt');
  }

  bool get _isSales {
    return _responsibilityName.contains('client') ||
        _responsibilityName.contains('vente');
  }

  bool get _needsInitialState {
    return _isEggStorage ||
        _isHealth ||
        _isFood ||
        _isFinance ||
        _isSales;
  }

  @override
  void initState() {
    super.initState();

    if (_needsInitialState) {
      _loadInitialState();
    }
  }

  // ==========================================================
  // CHARGEMENT ÉTAT INITIAL
  // ==========================================================

  Future<void> _loadInitialState() async {
    setState(() {
      _loadingInitialState = true;
    });

    try {
      final responsibilityId =
          widget.responsibility['id'];

      final response = await http.get(
        Uri.parse(
          'https://myajf-backend.onrender.com/api/responsibilities/'
          '$responsibilityId/initial-state/',
        ),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        Map<String, dynamic> stateData = {};

        if (result['state'] is Map) {
          final state =
              Map<String, dynamic>.from(result['state']);

          if (state['data'] is Map) {
            stateData =
                Map<String, dynamic>.from(state['data']);
          }
        }

        setState(() {
          _initialStateConfigured =
              result['configured'] == true;

          _initialState = stateData;
        });
      }
    } catch (_) {
      // L'écran reste utilisable même si le serveur
      // n'est momentanément pas disponible.
    } finally {
      if (mounted) {
        setState(() {
          _loadingInitialState = false;
        });
      }
    }
  }

  // ==========================================================
  // ENREGISTREMENT ÉTAT INITIAL
  // ==========================================================

  Future<void> _saveInitialState(
    Map<String, dynamic> data,
  ) async {
    setState(() {
      _loadingInitialState = true;
    });

    try {
      final responsibilityId =
          widget.responsibility['id'];

      final userId = widget.user['id'];

      final response = await http.post(
        Uri.parse(
          'https://myajf-backend.onrender.com/api/responsibilities/'
          '$responsibilityId/initial-state/',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'data': data,
        }),
      );

      if (!mounted) return;

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        setState(() {
          _initialStateConfigured = true;
          _initialState = data;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'État initial enregistré avec succès.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              decoded['message'] ??
                  'Impossible d’enregistrer l’état initial.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de contacter le serveur.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingInitialState = false;
        });
      }
    }
  }

  // ==========================================================
  // OUVRIR LE FORMULAIRE
  // ==========================================================

  Future<void> _openInitialStateForm() async {
    Widget dialog;

    if (_isEggStorage) {
      dialog = EggInitialStateDialog(
        initialData: _initialState,
      );
    } else if (_isHealth) {
      dialog = HealthInitialStateDialog(
        initialData: _initialState,
      );
    } else if (_isFood) {
      dialog = FoodInitialStateDialog(
        initialData: _initialState,
      );
    } else if (_isFinance) {
      dialog = FinanceInitialStateDialog(
        initialData: _initialState,
      );
    } else if (_isSales) {
      dialog = SalesInitialStateDialog(
        initialData: _initialState,
      );
    } else {
      return;
    }

    final result =
        await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => dialog,
    );

    if (result == null) {
      return;
    }

    await _saveInitialState(result);
  }

  // ==========================================================
  // STOCK ŒUFS
  // ==========================================================

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is double) {
      return value.round();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  int get _initialEggStock {
    return _toInt(
      _initialState['stock_initial'],
    );
  }

  int get _layingHens {
    return _toInt(
      _initialState['poules_pondeuses'],
    );
  }

  Future<int> _calculateCurrentEggStock() async {
  try {
    final responsibilityId = widget.responsibility['id'];

    final response = await http.get(
      Uri.parse(
        'https://myajf-backend.onrender.com/api/responsibilities/'
        '$responsibilityId/entries/',
      ),
    );

    if (response.statusCode != 200) {
      return _initialEggStock;
    }

    final decoded = jsonDecode(response.body);

    List<dynamic> entries = [];

    if (decoded is List) {
      entries = decoded;
    } else if (decoded is Map && decoded['results'] is List) {
      entries = decoded['results'];
    }

    int stock = _initialEggStock;

    for (final entry in entries) {
      if (entry is! Map) continue;

      final data = entry['data'];

      if (data is! Map) continue;

      // Entrée réelle dans le stock
      final added = _toInt(
        data['oeufs_ajoutes_stock'],
      );

      // Œufs cassés
      final broken = _toInt(
        data['oeufs_casses'],
      );

      // Œufs sortis du stock
      final out = _toInt(
        data['oeufs_sortis'],
      );

      stock += added;
      stock -= broken;
      stock -= out;
    }

    // Évite d'afficher un stock négatif
    return stock < 0 ? 0 : stock;
  } catch (_) {
    return _initialEggStock;
  }
}

  // ==========================================================
  // CARTES ÉTAT INITIAL
  // ==========================================================

  Widget _buildInitialStateSection() {
    if (!_needsInitialState) {
      return const SizedBox.shrink();
    }

    if (_loadingInitialState) {
      return Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        ),
      );
    }

    if (!_initialStateConfigured) {
      return _buildConfigurationCard();
    }

    if (_isEggStorage) {
      return _buildEggState();
    }

    if (_isHealth) {
      return _buildHealthState();
    }

    if (_isFood) {
      return _buildFoodState();
    }

    if (_isFinance) {
      return _buildFinanceState();
    }

    if (_isSales) {
      return _buildSalesState();
    }

    return const SizedBox.shrink();
  }

  Widget _buildConfigurationCard() {
    String title = 'Configurez votre état initial';
    String description =
        'Indiquez la situation actuelle avant de commencer le suivi.';

    IconData icon = Icons.settings_outlined;

    if (_isHealth) {
      title = 'Configurez l’état initial de la santé';
      description =
          'Enregistrez le nombre de poules et les médicaments actuellement disponibles.';
      icon = Icons.health_and_safety_outlined;
    } else if (_isFood) {
      title = 'Configurez l’état initial de l’alimentation';
      description =
          'Enregistrez le nombre de poules et les aliments actuellement disponibles.';
      icon = Icons.grass_outlined;
    } else if (_isFinance) {
      title = 'Configurez la situation financière';
      description =
          'Indiquez le solde actuel et le montant réellement disponible.';
      icon = Icons.account_balance_wallet_outlined;
    } else if (_isSales) {
      title = 'Configurez les clients et ventes existants';
      description =
          'Enregistrez les clients déjà connus et les ventes réalisées avant l’utilisation de l’application.';
      icon = Icons.people_outline;
    } else if (_isEggStorage) {
      title = 'Configurez votre état initial';
      description =
          'Indiquez le stock actuel d’œufs et le nombre de poules pondeuses.';
      icon = Icons.inventory_2_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: const TextStyle(
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openInitialStateForm,
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Configurer maintenant'),
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ÉTAT ŒUFS
  // ==========================================================

  Widget _buildEggState() {
    return FutureBuilder<int>(
      future: _calculateCurrentEggStock(),
      builder: (context, snapshot) {
        final current =
            snapshot.data ?? _initialEggStock;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StateCard(
                    title: 'Stock initial',
                    value: '$_initialEggStock',
                    unit: 'œufs',
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StateCard(
                    title: 'Stock actuel',
                    value: '$current',
                    unit: 'œufs',
                    icon: Icons.egg_alt_outlined,
                    emphasized: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SmallInfoCard(
              icon: Icons.egg_alt_outlined,
              text:
                  'Poules pondeuses : $_layingHens',
            ),
            _EditInitialStateButton(
              onPressed: _openInitialStateForm,
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // ÉTAT SANTÉ
  // ==========================================================

  Widget _buildHealthState() {
    final hens =
        _toInt(_initialState['nombre_poules']);

    final medicines =
        _listFrom(_initialState['medicaments']);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StateCard(
                title: 'Nombre de poules',
                value: '$hens',
                unit: 'poules',
                icon: Icons.egg_alt_outlined,
              ),
            ),
            Expanded(
              child: _StateCard(
                title: 'Médicaments',
                value: '${medicines.length}',
                unit: 'types disponibles',
                icon: Icons.medication_outlined,
                emphasized: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _InventoryPreviewCard(
          title: 'Médicaments disponibles',
          icon: Icons.medication_outlined,
          items: medicines,
        ),
        _EditInitialStateButton(
          onPressed: _openInitialStateForm,
        ),
      ],
    );
  }

  // ==========================================================
  // ÉTAT ALIMENTATION
  // ==========================================================

  Widget _buildFoodState() {
    final hens =
        _toInt(_initialState['nombre_poules']);

    final foods =
        _listFrom(_initialState['aliments']);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StateCard(
                title: 'Nombre de poules',
                value: '$hens',
                unit: 'poules',
                icon: Icons.egg_alt_outlined,
              ),
            ),
            Expanded(
              child: _StateCard(
                title: 'Aliments',
                value: '${foods.length}',
                unit: 'types disponibles',
                icon: Icons.grass_outlined,
                emphasized: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _InventoryPreviewCard(
          title: 'Aliments disponibles',
          icon: Icons.grass_outlined,
          items: foods,
        ),
        _EditInitialStateButton(
          onPressed: _openInitialStateForm,
        ),
      ],
    );
  }

  // ==========================================================
  // ÉTAT FINANCES
  // ==========================================================

  Widget _buildFinanceState() {
    final balance =
        _toDouble(_initialState['solde_actuel']);

    final available =
        _toDouble(_initialState['solde_disponible']);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StateCard(
                title: 'Solde actuel',
                value: _formatMoney(balance),
                unit: 'FCFA',
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StateCard(
                title: 'Disponible',
                value: _formatMoney(available),
                unit: 'FCFA',
                icon: Icons.payments_outlined,
                emphasized: true,
              ),
            ),
          ],
        ),
        _EditInitialStateButton(
          onPressed: _openInitialStateForm,
        ),
      ],
    );
  }

  // ==========================================================
  // ÉTAT CLIENTS / VENTES
  // ==========================================================

  Widget _buildSalesState() {
    final clients =
        _listFrom(_initialState['clients']);

    final sales =
        _listFrom(_initialState['ventes_initiales']);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StateCard(
                title: 'Clients existants',
                value: '${clients.length}',
                unit: 'clients',
                icon: Icons.people_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StateCard(
                title: 'Ventes historiques',
                value: '${sales.length}',
                unit: 'ventes',
                icon: Icons.point_of_sale_outlined,
                emphasized: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ClientPreviewCard(
          clients: clients,
        ),
        _EditInitialStateButton(
          onPressed: _openInitialStateForm,
        ),
      ],
    );
  }

  // ==========================================================
  // OUTILS
  // ==========================================================

  List<Map<String, dynamic>> _listFrom(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString().replaceAll(',', '.'),
        ) ??
        0;
  }

  String _formatMoney(double value) {
    return value
        .round()
        .toString()
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ' ',
        );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final fullName =
        widget.user['full_name'] ??
            widget.user['username'] ??
            'Responsable';

    final projectName =
        widget.project['name'] ?? 'Projet';

    final responsibilityName =
        widget.responsibility['name'] ??
            'Responsabilité';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Mon espace',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Bonjour, $fullName',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Voici votre espace de travail.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 25),

            _ProjectCard(
              projectName: projectName,
              domain: widget.project['domain'] ?? '',
            ),

            const SizedBox(height: 15),

            _ResponsibilityCard(
              name: responsibilityName,
            ),

            const SizedBox(height: 20),

            _buildInitialStateSection(),

            if (_needsInitialState)
              const SizedBox(height: 10),

            const SizedBox(height: 10),

            const Text(
              'Mes actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 14),

            _DashboardAction(
              icon: Icons.add_circle_outline,
              title: 'Saisir des données',
              subtitle:
                  'Ajouter une nouvelle donnée à ma responsabilité',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DataEntryScreen(
                      user: widget.user,
                      project: widget.project,
                      responsibility:
                          widget.responsibility,
                    ),
                  ),
                ).then((_) {
                  if (mounted && _isEggStorage) {
                    setState(() {});
                  }
                });
              },
            ),

            const SizedBox(height: 12),

            _DashboardAction(
              icon: Icons.history,
              title: 'Mon historique',
              subtitle:
                  'Consulter les données déjà enregistrées',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistoryScreen(
                      user: widget.user,
                      project: widget.project,
                      responsibility:
                          widget.responsibility,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            _DashboardAction(
              icon: Icons.table_chart_outlined,
              title: 'Données du projet',
              subtitle:
                  'Voir les données validées par les responsables',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProjectDataScreen(
                      project: widget.project,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// DIALOGUE — ŒUFS
// ============================================================

class EggInitialStateDialog extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const EggInitialStateDialog({
    super.key,
    required this.initialData,
  });

  @override
  State<EggInitialStateDialog> createState() =>
      _EggInitialStateDialogState();
}

class _EggInitialStateDialogState
    extends State<EggInitialStateDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _stockController;
  late final TextEditingController _hensController;

  @override
  void initState() {
    super.initState();

    _stockController = TextEditingController(
      text: widget.initialData['stock_initial']
              ?.toString() ??
          '',
    );

    _hensController = TextEditingController(
      text: widget.initialData['poules_pondeuses']
              ?.toString() ??
          '',
    );
  }

  @override
  void dispose() {
    _stockController.dispose();
    _hensController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      {
        'stock_initial':
            int.parse(_stockController.text.trim()),
        'poules_pondeuses':
            int.parse(_hensController.text.trim()),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _InitialStateDialogShell(
      title: 'État initial — Œufs',
      icon: Icons.inventory_2_outlined,
      formKey: _formKey,
      onSubmit: _submit,
      alreadyConfigured:
          widget.initialData.isNotEmpty,
      children: [
        _NumberField(
          controller: _stockController,
          label: 'Stock initial d’œufs',
          suffix: 'œufs',
        ),
        const SizedBox(height: 14),
        _NumberField(
          controller: _hensController,
          label: 'Nombre de poules pondeuses',
          suffix: 'poules',
        ),
      ],
    );
  }
}


// ============================================================
// DIALOGUE — SANTÉ
// ============================================================

class HealthInitialStateDialog extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const HealthInitialStateDialog({
    super.key,
    required this.initialData,
  });

  @override
  State<HealthInitialStateDialog> createState() =>
      _HealthInitialStateDialogState();
}

class _HealthInitialStateDialogState
    extends State<HealthInitialStateDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _hensController;

  final List<Map<String, dynamic>> _medicines = [];

  @override
  void initState() {
    super.initState();

    _hensController = TextEditingController(
      text: widget.initialData['nombre_poules']
              ?.toString() ??
          '',
    );

    final existing =
        widget.initialData['medicaments'];

    if (existing is List) {
      for (final item in existing) {
        if (item is Map) {
          _medicines.add(
            Map<String, dynamic>.from(item),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _hensController.dispose();
    super.dispose();
  }

  Future<void> _addMedicine() async {
    final result =
        await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const InventoryItemDialog(
        title: 'Ajouter un médicament',
        nameLabel: 'Nom du médicament',
        unitLabel: 'Unité',
      ),
    );

    if (result != null) {
      setState(() {
        _medicines.add(result);
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      {
        'nombre_poules':
            int.parse(_hensController.text.trim()),
        'medicaments': _medicines,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _InitialStateDialogShell(
      title: 'État initial — Santé',
      icon: Icons.health_and_safety_outlined,
      formKey: _formKey,
      onSubmit: _submit,
      alreadyConfigured:
          widget.initialData.isNotEmpty,
      children: [
        _NumberField(
          controller: _hensController,
          label: 'Nombre de poules',
          suffix: 'poules',
        ),
        const SizedBox(height: 20),
        _SectionTitle(
          title: 'Médicaments disponibles',
        ),
        const SizedBox(height: 10),
        if (_medicines.isEmpty)
          const _EmptyInventoryMessage(
            text: 'Aucun médicament ajouté.',
          )
        else
          ..._medicines.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final item = entry.value;

              return _InventoryEditTile(
                item: item,
                onDelete: () {
                  setState(() {
                    _medicines.removeAt(index);
                  });
                },
              );
            },
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _addMedicine,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un médicament'),
        ),
      ],
    );
  }
}


// ============================================================
// DIALOGUE — ALIMENTATION
// ============================================================

class FoodInitialStateDialog extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const FoodInitialStateDialog({
    super.key,
    required this.initialData,
  });

  @override
  State<FoodInitialStateDialog> createState() =>
      _FoodInitialStateDialogState();
}

class _FoodInitialStateDialogState
    extends State<FoodInitialStateDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _hensController;

  final List<Map<String, dynamic>> _foods = [];

  @override
  void initState() {
    super.initState();

    _hensController = TextEditingController(
      text: widget.initialData['nombre_poules']
              ?.toString() ??
          '',
    );

    final existing =
        widget.initialData['aliments'];

    if (existing is List) {
      for (final item in existing) {
        if (item is Map) {
          _foods.add(
            Map<String, dynamic>.from(item),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _hensController.dispose();
    super.dispose();
  }

  Future<void> _addFood() async {
    final result =
        await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const InventoryItemDialog(
        title: 'Ajouter un aliment',
        nameLabel: 'Nom de l’aliment',
        unitLabel: 'Unité',
      ),
    );

    if (result != null) {
      setState(() {
        _foods.add(result);
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      {
        'nombre_poules':
            int.parse(_hensController.text.trim()),
        'aliments': _foods,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _InitialStateDialogShell(
      title: 'État initial — Alimentation',
      icon: Icons.grass_outlined,
      formKey: _formKey,
      onSubmit: _submit,
      alreadyConfigured:
          widget.initialData.isNotEmpty,
      children: [
        _NumberField(
          controller: _hensController,
          label: 'Nombre de poules',
          suffix: 'poules',
        ),
        const SizedBox(height: 20),
        _SectionTitle(
          title: 'Aliments disponibles',
        ),
        const SizedBox(height: 10),
        if (_foods.isEmpty)
          const _EmptyInventoryMessage(
            text: 'Aucun aliment ajouté.',
          )
        else
          ..._foods.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final item = entry.value;

              return _InventoryEditTile(
                item: item,
                onDelete: () {
                  setState(() {
                    _foods.removeAt(index);
                  });
                },
              );
            },
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _addFood,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un aliment'),
        ),
      ],
    );
  }
}


// ============================================================
// DIALOGUE — FINANCES
// ============================================================

class FinanceInitialStateDialog extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const FinanceInitialStateDialog({
    super.key,
    required this.initialData,
  });

  @override
  State<FinanceInitialStateDialog> createState() =>
      _FinanceInitialStateDialogState();
}

class _FinanceInitialStateDialogState
    extends State<FinanceInitialStateDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _balanceController;
  late final TextEditingController _availableController;

  @override
  void initState() {
    super.initState();

    _balanceController = TextEditingController(
      text: widget.initialData['solde_actuel']
              ?.toString() ??
          '',
    );

    _availableController = TextEditingController(
      text: widget.initialData['solde_disponible']
              ?.toString() ??
          '',
    );
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _availableController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      {
        'solde_actuel':
            double.parse(
          _balanceController.text.trim(),
        ),
        'solde_disponible':
            double.parse(
          _availableController.text.trim(),
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _InitialStateDialogShell(
      title: 'État initial — Finances',
      icon: Icons.account_balance_wallet_outlined,
      formKey: _formKey,
      onSubmit: _submit,
      alreadyConfigured:
          widget.initialData.isNotEmpty,
      children: [
        _MoneyField(
          controller: _balanceController,
          label: 'Solde actuel',
        ),
        const SizedBox(height: 14),
        _MoneyField(
          controller: _availableController,
          label: 'Solde disponible',
        ),
      ],
    );
  }
}


// ============================================================
// DIALOGUE — CLIENTS / VENTES
// ============================================================

class SalesInitialStateDialog extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const SalesInitialStateDialog({
    super.key,
    required this.initialData,
  });

  @override
  State<SalesInitialStateDialog> createState() =>
      _SalesInitialStateDialogState();
}

class _SalesInitialStateDialogState
    extends State<SalesInitialStateDialog> {
  final _formKey = GlobalKey<FormState>();

  final List<Map<String, dynamic>> _clients = [];
  final List<Map<String, dynamic>> _sales = [];

  @override
  void initState() {
    super.initState();

    final clients =
        widget.initialData['clients'];

    if (clients is List) {
      for (final item in clients) {
        if (item is Map) {
          _clients.add(
            Map<String, dynamic>.from(item),
          );
        }
      }
    }

    final sales =
        widget.initialData['ventes_initiales'];

    if (sales is List) {
      for (final item in sales) {
        if (item is Map) {
          _sales.add(
            Map<String, dynamic>.from(item),
          );
        }
      }
    }
  }

  Future<void> _addClient() async {
    final result =
        await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const ClientDialog(),
    );

    if (result != null) {
      setState(() {
        _clients.add(result);
      });
    }
  }

  Future<void> _addSale() async {
    final result =
        await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const InitialSaleDialog(),
    );

    if (result != null) {
      setState(() {
        _sales.add(result);
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      {
        'clients': _clients,
        'ventes_initiales': _sales,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _InitialStateDialogShell(
      title: 'État initial — Clients & ventes',
      icon: Icons.people_outline,
      formKey: _formKey,
      onSubmit: _submit,
      alreadyConfigured:
          widget.initialData.isNotEmpty,
      children: [
        _SectionTitle(
          title: 'Clients existants',
        ),
        const SizedBox(height: 10),
        if (_clients.isEmpty)
          const _EmptyInventoryMessage(
            text: 'Aucun client ajouté.',
          )
        else
          ..._clients.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final client = entry.value;

              return _ClientEditTile(
                client: client,
                onDelete: () {
                  setState(() {
                    _clients.removeAt(index);
                  });
                },
              );
            },
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _addClient,
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Ajouter un client'),
        ),
        const SizedBox(height: 25),
        _SectionTitle(
          title: 'Ventes antérieures',
        ),
        const SizedBox(height: 10),
        if (_sales.isEmpty)
          const _EmptyInventoryMessage(
            text: 'Aucune vente ajoutée.',
          )
        else
          ..._sales.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final sale = entry.value;

              return _SaleEditTile(
                sale: sale,
                onDelete: () {
                  setState(() {
                    _sales.removeAt(index);
                  });
                },
              );
            },
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _addSale,
          icon: const Icon(Icons.add_shopping_cart_outlined),
          label: const Text('Ajouter une vente'),
        ),
      ],
    );
  }
}


// ============================================================
// DIALOGUE GÉNÉRIQUE INVENTAIRE
// ============================================================

class InventoryItemDialog extends StatefulWidget {
  final String title;
  final String nameLabel;
  final String unitLabel;

  const InventoryItemDialog({
    super.key,
    required this.title,
    required this.nameLabel,
    required this.unitLabel,
  });

  @override
  State<InventoryItemDialog> createState() =>
      _InventoryItemDialogState();
}

class _InventoryItemDialogState
    extends State<InventoryItemDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      {
        'nom': _nameController.text.trim(),
        'quantite':
            double.parse(
          _quantityController.text.trim(),
        ),
        'unite': _unitController.text.trim(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TextField(
              controller: _nameController,
              label: widget.nameLabel,
            ),
            const SizedBox(height: 12),
            _NumberField(
              controller: _quantityController,
              label: 'Quantité',
            ),
            const SizedBox(height: 12),
            _TextField(
              controller: _unitController,
              label: widget.unitLabel,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor:
                AppColors.primary,
          ),
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}


// ============================================================
// DIALOGUE CLIENT
// ============================================================

class ClientDialog extends StatefulWidget {
  const ClientDialog({super.key});

  @override
  State<ClientDialog> createState() =>
      _ClientDialogState();
}

class _ClientDialogState extends State<ClientDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _placeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      {
        'nom': _nameController.text.trim(),
        'telephone': _phoneController.text.trim(),
        'lieu': _placeController.text.trim(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un client'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TextField(
              controller: _nameController,
              label: 'Nom du client',
            ),
            const SizedBox(height: 12),
            _TextField(
              controller: _phoneController,
              label: 'Téléphone',
              required: false,
            ),
            const SizedBox(height: 12),
            _TextField(
              controller: _placeController,
              label: 'Lieu',
              required: false,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor:
                AppColors.primary,
          ),
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}


// ============================================================
// DIALOGUE VENTE HISTORIQUE
// ============================================================

class InitialSaleDialog extends StatefulWidget {
  const InitialSaleDialog({super.key});

  @override
  State<InitialSaleDialog> createState() =>
      _InitialSaleDialogState();
}

class _InitialSaleDialogState
    extends State<InitialSaleDialog> {
  final _formKey = GlobalKey<FormState>();

  final _dateController = TextEditingController();
  final _clientController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  String _paymentMode = 'Espèces';

  @override
  void dispose() {
    _dateController.dispose();
    _clientController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDate: now,
    );

    if (picked != null) {
      _dateController.text =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final quantity =
        double.parse(_quantityController.text.trim());

    final price =
        double.parse(_priceController.text.trim());

    Navigator.pop(
      context,
      {
        'date': _dateController.text.trim(),
        'client': _clientController.text.trim(),
        'quantite_oeufs': quantity,
        'prix_unitaire': price,
        'total': quantity * price,
        'mode_paiement': _paymentMode,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une vente'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _selectDate,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon:
                      Icon(Icons.calendar_today_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Sélectionnez une date.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              _TextField(
                controller: _clientController,
                label: 'Client',
              ),
              const SizedBox(height: 12),
              _NumberField(
                controller: _quantityController,
                label: 'Quantité d’œufs',
              ),
              const SizedBox(height: 12),
              _MoneyField(
                controller: _priceController,
                label: 'Prix unitaire',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _paymentMode,
                decoration: const InputDecoration(
                  labelText: 'Mode de paiement',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Espèces',
                    child: Text('Espèces'),
                  ),
                  DropdownMenuItem(
                    value: 'Mobile Money',
                    child: Text('Mobile Money'),
                  ),
                  DropdownMenuItem(
                    value: 'Autre',
                    child: Text('Autre'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _paymentMode = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor:
                AppColors.primary,
          ),
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}


// ============================================================
// SHELL DIALOGUE
// ============================================================

class _InitialStateDialogShell extends StatelessWidget {
  final String title;
  final IconData icon;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;
  final bool alreadyConfigured;
  final List<Widget> children;

  const _InitialStateDialogShell({
    required this.title,
    required this.icon,
    required this.formKey,
    required this.onSubmit,
    required this.alreadyConfigured,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alreadyConfigured
                    ? 'Modifiez les informations de départ si nécessaire.'
                    : 'Indiquez la situation existante avant de commencer le suivi.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        18,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: onSubmit,
          style: FilledButton.styleFrom(
            backgroundColor:
                AppColors.primary,
          ),
          child: Text(
            alreadyConfigured
                ? 'Enregistrer'
                : 'Configurer',
          ),
        ),
      ],
    );
  }
}


// ============================================================
// CHAMPS
// ============================================================

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;

  const _TextField({
    required this.controller,
    required this.label,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
      ),
      validator: (value) {
        if (required &&
            (value == null || value.trim().isEmpty)) {
          return 'Ce champ est requis.';
        }

        return null;
      },
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? suffix;

  const _NumberField({
    required this.controller,
    required this.label,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
      ),
      validator: (value) {
        final number = double.tryParse(
          value?.trim() ?? '',
        );

        if (number == null) {
          return 'Entrez un nombre valide.';
        }

        if (number < 0) {
          return 'La valeur ne peut pas être négative.';
        }

        return null;
      },
    );
  }
}

class _MoneyField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _MoneyField({
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return _NumberField(
      controller: controller,
      label: label,
      suffix: 'FCFA',
    );
  }
}


// ============================================================
// PETITS COMPOSANTS
// ============================================================

class _StateCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final bool emphasized;

  const _StateCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: emphasized
            ? AppColors.primary
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: emphasized
            ? null
            : Border.all(
                color: AppColors.border,
              ),
        boxShadow: emphasized
            ? [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.08,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: emphasized
                ? Colors.white
                : AppColors.primary,
            size: 25,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: emphasized
                  ? Colors.white70
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: emphasized
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 11,
              color: emphasized
                  ? Colors.white70
                  : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallInfoCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SmallInfoCard({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditInitialStateButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _EditInitialStateButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          Icons.edit_outlined,
          size: 18,
        ),
        label: const Text('Modifier l’état initial'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _EmptyInventoryMessage extends StatelessWidget {
  final String text;

  const _EmptyInventoryMessage({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}


// ============================================================
// APERÇU INVENTAIRE
// ============================================================

class _InventoryPreviewCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> items;

  const _InventoryPreviewCard({
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Text(
              'Aucun élément enregistré.',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            )
          else
            ...items.take(4).map(
              (item) {
                final name =
                    item['nom']?.toString() ?? '';

                final quantity =
                    item['quantite']?.toString() ?? '';

                final unit =
                    item['unite']?.toString() ?? '';

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 5,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(name),
                      ),
                      Text(
                        '$quantity $unit',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
// APERÇU CLIENTS
// ============================================================

class _ClientPreviewCard extends StatelessWidget {
  final List<Map<String, dynamic>> clients;

  const _ClientPreviewCard({
    required this.clients,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          const Row(
            children: [
              Icon(
                Icons.people_outline,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Text(
                'Clients',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (clients.isEmpty)
            const Text(
              'Aucun client enregistré.',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            )
          else
            ...clients.take(4).map(
              (client) {
                final name =
                    client['nom']?.toString() ?? '';

                final phone =
                    client['telephone']
                            ?.toString() ??
                        '';

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 5,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(name),
                      ),
                      if (phone.isNotEmpty)
                        Text(
                          phone,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
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
// TUILES D'ÉDITION
// ============================================================

class _InventoryEditTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;

  const _InventoryEditTile({
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.inventory_2_outlined,
        color: AppColors.primary,
      ),
      title: Text(
        item['nom']?.toString() ?? '',
      ),
      subtitle: Text(
        '${item['quantite'] ?? 0} '
        '${item['unite'] ?? ''}',
      ),
      trailing: IconButton(
        onPressed: onDelete,
        icon: const Icon(
          Icons.delete_outline,
        ),
      ),
    );
  }
}

class _ClientEditTile extends StatelessWidget {
  final Map<String, dynamic> client;
  final VoidCallback onDelete;

  const _ClientEditTile({
    required this.client,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.person_outline,
        color: AppColors.primary,
      ),
      title: Text(
        client['nom']?.toString() ?? '',
      ),
      subtitle: Text(
        client['telephone']?.toString() ?? '',
      ),
      trailing: IconButton(
        onPressed: onDelete,
        icon: const Icon(
          Icons.delete_outline,
        ),
      ),
    );
  }
}

class _SaleEditTile extends StatelessWidget {
  final Map<String, dynamic> sale;
  final VoidCallback onDelete;

  const _SaleEditTile({
    required this.sale,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final quantity =
        sale['quantite_oeufs'] ?? 0;

    final total =
        sale['total'] ?? 0;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.point_of_sale_outlined,
        color: AppColors.primary,
      ),
      title: Text(
        sale['client']?.toString() ?? '',
      ),
      subtitle: Text(
        '$quantity œufs • $total FCFA',
      ),
      trailing: IconButton(
        onPressed: onDelete,
        icon: const Icon(
          Icons.delete_outline,
        ),
      ),
    );
  }
}


// ============================================================
// PROJET
// ============================================================

class _ProjectCard extends StatelessWidget {
  final String projectName;
  final String domain;

  const _ProjectCard({
    required this.projectName,
    required this.domain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary
              .withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROJET',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            projectName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            domain,
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsibilityCard extends StatelessWidget {
  final String name;

  const _ResponsibilityCard({
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.assignment_ind_outlined,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ma responsabilité',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// ACTION DASHBOARD
// ============================================================

class _DashboardAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(subtitle),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
        ),
        onTap: onTap,
      ),
    );
  }
}