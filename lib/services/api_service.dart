import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
    'https://myajf-backend.onrender.com/api';

  // ============================================================
  // PROJETS
  // ============================================================

  Future<List<dynamic>> getProjects() async {
    final response = await http.get(
      Uri.parse('$baseUrl/projects/'),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur lors du chargement des projets : ${response.statusCode}',
      );
    }

    return jsonDecode(response.body) as List<dynamic>;
  }

  // ============================================================
  // IDENTIFICATION DU MEMBRE
  // ============================================================

  Future<Map<String, dynamic>> verifyMember(
    String accessCode,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/member-access/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'access_code': accessCode.trim(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    if (data is Map && data['message'] != null) {
      throw Exception(data['message'].toString());
    }

    throw Exception(
      'Erreur lors de la vérification du membre : '
      '${response.statusCode}',
    );
  }

  // ============================================================
  // ACCÈS AUX RESPONSABILITÉS DU MEMBRE
  // ============================================================

  Future<Map<String, dynamic>> getResponsibilityAccess({
    required int projectId,
    required String accessCode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/responsibility-access/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'project_id': projectId,
        'access_code': accessCode.trim(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    if (data is Map && data['message'] != null) {
      throw Exception(data['message'].toString());
    }

    throw Exception(
      'Erreur lors de la récupération des responsabilités : '
      '${response.statusCode}',
    );
  }
}