import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'theme/app_theme.dart';

class DataEntryScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic> project;
  final Map<String, dynamic> responsibility;

  const DataEntryScreen({
    super.key,
    required this.user,
    required this.project,
    required this.responsibility,
  });

  @override
  State<DataEntryScreen> createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends State<DataEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  final Map<String, TextEditingController> _controllers = {};

  bool _loading = false;

  // ============================================================
  // FORM SCHEMA
  // ============================================================

  List<dynamic> get _formSchema {
    final schema = widget.responsibility['form_schema'];

    // Cas 1 : le schema est directement une liste
    if (schema is List) {
      return schema;
    }

    // Cas 2 : le schema contient {"fields": [...]}

    if (schema is Map && schema['fields'] is List) {
      return schema['fields'];
    }

    return [];
  }

  @override
  void initState() {
    super.initState();

    for (final field in _formSchema) {
      if (field is Map<String, dynamic>) {
        final name = field['name'];

        if (name != null) {
          _controllers[name.toString()] =
              TextEditingController();
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // ENREGISTREMENT
  // ============================================================

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final Map<String, dynamic> formData = {};

      for (final field in _formSchema) {
        if (field is! Map<String, dynamic>) {
          continue;
        }

        final name = field['name'];

        if (name == null) {
          continue;
        }

        final fieldName = name.toString();

        formData[fieldName] =
            _controllers[fieldName]?.text.trim() ?? '';
      }

      final responsibilityId =
          widget.responsibility['id'];

      final userId = widget.user['id'];

      final response = await http.post(
        Uri.parse(
          'https://myajf-backend.onrender.com/api/responsibilities/'
          '$responsibilityId/entries/create/',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'responsibility': responsibilityId,
          'data': formData,
          'notes': '',
        }),
      );

      if (!mounted) return;

      final responseData = jsonDecode(response.body);

      print('STATUS: ${response.statusCode}');
      print('RESPONSE: ${response.body}');

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Données enregistrées avec succès.',
            ),
          ),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseData['detail'] ??
                  responseData['message'] ??
                  'Impossible d’enregistrer les données.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de contacter le serveur : $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // SÉLECTEUR DE DATE
  // ============================================================

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    DateTime initialDate = DateTime.now();

    if (controller.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(controller.text);
      } catch (_) {
        initialDate = DateTime.now();
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('fr'),
    );

    if (picked != null) {
      final year = picked.year.toString().padLeft(4, '0');
      final month = picked.month.toString().padLeft(2, '0');
      final day = picked.day.toString().padLeft(2, '0');

      controller.text = '$year-$month-$day';
    }
  }

  // ============================================================
  // CHAMP DYNAMIQUE
  // ============================================================

  Widget _buildField(
    Map<String, dynamic> field,
  ) {
    final name =
        field['name']?.toString() ?? '';

    final label =
        field['label']?.toString() ?? name;

    final type =
        field['type']?.toString() ?? 'text';

    final required =
        field['required'] == true;

    final controller =
        _controllers[name];

    if (controller == null) {
      return const SizedBox.shrink();
    }

    // ----------------------------------------------------------
    // TYPE DATE
    // ----------------------------------------------------------

    if (type == 'date') {
      return Padding(
        padding: const EdgeInsets.only(
          bottom: 18,
        ),
        child: TextFormField(
          controller: controller,
          readOnly: true,
          onTap: () {
            _selectDate(
              context,
              controller,
            );
          },
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Sélectionner une date',
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.primary,
            ),
            suffixIcon: const Icon(
              Icons.arrow_drop_down,
              color: AppColors.textMuted,
            ),
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
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (required &&
                (value == null ||
                    value.trim().isEmpty)) {
              return '$label est obligatoire';
            }

            return null;
          },
        ),
      );
    }

    // ----------------------------------------------------------
// TYPE CHOICE
// ----------------------------------------------------------

if (type == 'choice') {
  final options = field['options'];

  if (options is! List || options.isEmpty) {
    return const SizedBox.shrink();
  }

  return Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: DropdownButtonFormField<String>(
      value: controller.text.isEmpty
          ? null
          : controller.text,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(
          Icons.arrow_drop_down_circle_outlined,
          color: AppColors.primary,
        ),
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
      items: options.map<DropdownMenuItem<String>>((option) {
        return DropdownMenuItem<String>(
          value: option.toString(),
          child: Text(option.toString()),
        );
      }).toList(),
      onChanged: (value) {
        controller.text = value ?? '';
      },
      validator: (value) {
        if (required &&
            (value == null || value.trim().isEmpty)) {
          return '$label est obligatoire';
        }

        return null;
      },
    ),
  );
}


    // ----------------------------------------------------------
    // TYPES NUMÉRIQUES
    // ----------------------------------------------------------

    final bool isNumber =
        type == 'number' ||
        type == 'decimal';

    // ----------------------------------------------------------
    // TEXTAREA
    // ----------------------------------------------------------

    final bool isMultiline =
        type == 'textarea';

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 18,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(
                decimal: true,
              )
            : TextInputType.text,
        maxLines:
            isMultiline ? 5 : 1,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint:
              isMultiline,
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(
            isNumber
                ? Icons.numbers
                : isMultiline
                    ? Icons.notes_outlined
                    : Icons.edit_outlined,
            color:
                AppColors.primary,
          ),
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
          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
            borderSide:
                const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
        ),
        validator: (value) {
          if (required &&
              (value == null ||
                  value.trim().isEmpty)) {
            return '$label est obligatoire';
          }

          return null;
        },
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

    final fullName =
        widget.user['full_name'] ??
            widget.user['username'] ??
            'Responsable';

    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Saisie des données',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding:
                const EdgeInsets.all(20),
            children: [

              // ------------------------------------------------
              // RESPONSABLE
              // ------------------------------------------------

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
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration:
                          BoxDecoration(
                        color:
                            AppColors.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                      child:
                          const Icon(
                        Icons
                            .person_outline,
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
                          const Text(
                            'RESPONSABLE',
                            style:
                                TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              color:
                                  AppColors.textMuted,
                              letterSpacing:
                                  1,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            fullName,
                            style:
                                const TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              // ------------------------------------------------
              // PROJET
              // ------------------------------------------------

              Container(
                padding:
                    const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                    const Text(
                      'PROJET',
                      style:
                          TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            AppColors.textMuted,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    Text(
                      projectName,
                      style:
                          const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      responsibilityName,
                      style:
                          const TextStyle(
                        fontSize: 14,
                        color:
                            AppColors.primary,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              const Text(
                'Informations',
                style:
                    TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              const Text(
                'Remplissez les informations demandées pour cette responsabilité.',
                style:
                    TextStyle(
                  color:
                      AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),

              const SizedBox(
                height: 22,
              ),

              // ------------------------------------------------
              // FORMULAIRE DYNAMIQUE
              // ------------------------------------------------

              if (_formSchema.isEmpty)
                Container(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.warningSoft,
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color:
                            AppColors.warning,
                      ),
                      SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Text(
                          'Aucun champ n’a encore été défini pour cette responsabilité.',
                          style:
                              TextStyle(
                            color:
                                AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._formSchema
                    .whereType<
                        Map<String,
                            dynamic>>()
                    .map(
                      _buildField,
                    ),

              const SizedBox(
                height: 10,
              ),

              // ------------------------------------------------
              // BOUTON
              // ------------------------------------------------

              SizedBox(
                height: 54,
                child:
                    FilledButton.icon(
                  onPressed:
                      _loading
                          ? null
                          : _saveData,
                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                  icon: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons
                              .save_outlined,
                        ),
                  label: Text(
                    _loading
                        ? 'Enregistrement...'
                        : 'Enregistrer les données',
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}