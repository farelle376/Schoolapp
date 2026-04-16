// lib/services/admin_notification_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../model/notification_admin_model.dart';
import '../model/conversation_admin_model.dart';
import '../model/message_admin_model.dart';

class AdminNotificationService {
  final String baseUrl = Constants.baseUrl;
  String? _token;

  AdminNotificationService() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('admin_token');
  }

  Future<Map<String, dynamic>> _request(String method, String endpoint, {Map<String, dynamic>? data}) async {
    await _loadToken();
    
    final url = Uri.parse('$baseUrl/admin/$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };

    http.Response response;
    if (method == 'GET') {
      response = await http.get(url, headers: headers);
    } else if (method == 'POST') {
      response = await http.post(url, headers: headers, body: json.encode(data));
    } else if (method == 'PUT') {
      response = await http.put(url, headers: headers, body: json.encode(data));
    } else {
      response = await http.delete(url, headers: headers);
    }

    return json.decode(response.body);
  }

  // Notifications
  Future<List<NotificationAdminModel>> getNotifications() async {
    try {
      final response = await _request('GET', 'notifications');
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => NotificationAdminModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Erreur getNotifications: $e');
      return [];
    }
  }

  Future<bool> createNotification(Map<String, dynamic> data) async {
    try {
      final response = await _request('POST', 'notifications', data: data);
      return response['success'] == true;
    } catch (e) {
      print('Erreur createNotification: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(int id) async {
    try {
      final response = await _request('DELETE', 'notifications/$id');
      return response['success'] == true;
    } catch (e) {
      print('Erreur deleteNotification: $e');
      return false;
    }
  }

  // Parents
  Future<List<Map<String, dynamic>>> getParents() async {
    try {
      final response = await _request('GET', 'parents');
      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      return [];
    } catch (e) {
      print('Erreur getParents: $e');
      return [];
    }
  }

  // Élèves
  Future<List<Map<String, dynamic>>> getEleves() async {
    try {
      final response = await _request('GET', 'eleves');
      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      return [];
    } catch (e) {
      print('Erreur getEleves: $e');
      return [];
    }
  }

  // Conversations
  Future<List<ConversationAdminModel>> getConversations() async {
    try {
      final response = await _request('GET', 'conversations');
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => ConversationAdminModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Erreur getConversations: $e');
      return [];
    }
  }

  Future<List<MessageAdminModel>> getMessages(int conversationId) async {
    try {
      final response = await _request('GET', 'conversations/$conversationId/messages');
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => MessageAdminModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Erreur getMessages: $e');
      return [];
    }
  }

  Future<bool> sendMessage(int conversationId, String message) async {
    try {
      final response = await _request('POST', 'conversations/$conversationId/messages', data: {
        'message': message,
      });
      return response['success'] == true;
    } catch (e) {
      print('Erreur sendMessage: $e');
      return false;
    }
  }
}