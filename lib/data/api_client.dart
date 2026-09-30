import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thin wrapper around the FastAPI backend. Every method fails silently so a dead backend never breaks the UI — the
class ApiClient {
  // Chrome + desktop: FastAPI runs on your machine at this port.
  static const _baseUrl = 'http://127.0.0.1:8000';

  static Future<void> fundProject(String projectId) async {
    await _post('/projects/$projectId/fund');
  }

  static Future<void> submitMilestone(String projectId, String milestoneId) async {
    await _post('/milestones/$projectId/$milestoneId/submit');
  }

  static Future<void> approveMilestone(String projectId, String milestoneId) async {
    await _post('/milestones/$projectId/$milestoneId/approve');
  }

  static Future<void> offramp(String userId, double amountUsdc) async {
    await _post('/wallet/offramp', body: {
      'user_id': userId,
      'amount_usdc': amountUsdc,
    });
  }

  static Future<void> _post(String path, {Map<String, dynamic>? body}) async {
    try {
      await http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(const Duration(seconds: 3));
    } catch (e) {
// This is for debugging only. In production, we don't want to spam the console with errors if the backend is down.
      print('ApiClient error on $path: $e');
    }
  }
}