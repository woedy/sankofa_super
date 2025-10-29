import 'dart:async';

import 'package:sankofasave/models/dispute_model.dart';

import 'api_client.dart';
import 'api_exception.dart';

class DisputeService {
  DisputeService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  List<DisputeModel>? _cachedDisputes;
  DateTime? _lastFetchedAt;

  static const _basePath = '/api/disputes/disputes';

  String get _listPath => '$_basePath/';

  String _detailPath(String id) => '$_basePath/$id/';

  String _messagePath(String id) => '$_basePath/$id/messages/';

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
        .whereType<Map<String, dynamic>>()
        .map((entry) {
          try {
            return DisputeModel.fromApi(entry);
          } on FormatException {
            return null;
          }
        })
        .whereType<DisputeModel>()
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

    if (id.isEmpty) {
      throw ApiException('Unable to load this dispute.');
    }
    final response = await _apiClient.get(_detailPath(id));
    if (response is Map<String, dynamic>) {
      try {
        final dispute = DisputeModel.fromApi(response);
        _upsertDispute(dispute);
        return dispute;
      } on FormatException {
        throw ApiException('Unable to understand the dispute details returned by the server.');
      }
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
      try {
        final dispute = DisputeModel.fromApi(response);
        _upsertDispute(dispute);
        return dispute;
      } on FormatException {
        throw ApiException('We created your dispute but could not read it back. Please refresh.');
      }
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
    if (disputeId.isEmpty) {
      throw ApiException('Unable to send your update right now.');
    }
    final response = await _apiClient.post(_messagePath(disputeId), body: payload);
    if (response is Map<String, dynamic>) {
      try {
        final dispute = DisputeModel.fromApi(response);
        _upsertDispute(dispute);
        return dispute;
      } on FormatException {
        throw ApiException('We sent your update but could not refresh the dispute. Please pull to refresh.');
      }
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
