import 'dart:async';

import 'package:sankofasave/models/dispute_model.dart';

import 'api_client.dart';
import 'api_exception.dart';

class DisputeService {
  DisputeService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  List<DisputeModel>? _cachedDisputes;
  DateTime? _lastFetchedAt;

  static const _listPath = '/api/disputes/disputes/';

  Future<List<DisputeModel>> listDisputes({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh && _cachedDisputes != null) {
      final lastFetched = _lastFetchedAt;
      if (lastFetched != null && now.difference(lastFetched) < const Duration(minutes: 3)) {
        return _cachedDisputes!;
      }
    }

    final response = await _apiClient.get(_listPath);
    final List<dynamic>? rawList;
    if (response is List) {
      rawList = response;
    } else if (response is Map<String, dynamic>) {
      final results = response['results'];
      if (results is List) {
        rawList = results;
      } else {
        rawList = null;
      }
    } else {
      rawList = null;
    }

    if (rawList == null) {
      throw ApiException('Unexpected response when loading disputes.');
    }

    final disputes = rawList
        .whereType<Map>()
        .map((entry) => DisputeModel.fromApi(entry.cast<String, dynamic>()))
        .toList();

    _cachedDisputes = disputes;
    _lastFetchedAt = now;
    return disputes;
  }

  Future<DisputeModel?> fetchDispute(String id, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedDisputes != null) {
      try {
        return _cachedDisputes!.firstWhere((dispute) => dispute.id == id);
      } catch (_) {
        // not cached, fall through to fetch
      }
    }

    final response = await _apiClient.get('$_listPath$id/');
    if (response is Map<String, dynamic>) {
      final dispute = DisputeModel.fromApi(response);
      _upsertDispute(dispute);
      return dispute;
    }
    return null;
  }

  Future<DisputeModel> createDispute({
    required String title,
    required String description,
    required String category,
    required String severity,
    required String priority,
    required String channel,
    String? groupId,
    required String initialMessage,
  }) async {
    final payload = {
      'title': title,
      'description': description,
      'category': category,
      'severity': severity,
      'priority': priority,
      'channel': channel,
      'initial_message': initialMessage,
      if (groupId != null && groupId.isNotEmpty) 'group': groupId,
    };

    final response = await _apiClient.post(_listPath, body: payload);
    if (response is Map<String, dynamic>) {
      final disputeId = response['id']?.toString();
      if (disputeId != null && disputeId.isNotEmpty) {
        final detailed = await fetchDispute(disputeId, forceRefresh: true);
        if (detailed != null) {
          return detailed;
        }
      }
      final dispute = DisputeModel.fromApi(response);
      _upsertDispute(dispute);
      return dispute;
    }
    throw ApiException('Unable to create dispute right now. Please try again.');
  }

  Future<DisputeModel> postMessage({
    required String disputeId,
    required String message,
    String? channel,
  }) async {
    final payload = {
      'message': message,
      if (channel != null && channel.isNotEmpty) 'channel': channel,
    };
    final response = await _apiClient.post('$_listPath$disputeId/messages/', body: payload);
    if (response is Map<String, dynamic>) {
      final dispute = DisputeModel.fromApi(response);
      _upsertDispute(dispute);
      return dispute;
    }
    throw ApiException('Unable to send your update. Please try again.');
  }

  void _upsertDispute(DisputeModel dispute) {
    final existing = _cachedDisputes;
    if (existing == null) {
      _cachedDisputes = [dispute];
      _lastFetchedAt = DateTime.now();
      return;
    }
    final index = existing.indexWhere((item) => item.id == dispute.id);
    if (index >= 0) {
      existing[index] = dispute;
    } else {
      existing.insert(0, dispute);
    }
    _lastFetchedAt = DateTime.now();
  }
}
