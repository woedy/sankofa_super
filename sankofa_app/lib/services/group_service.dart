import 'dart:convert';

import 'package:sankofasave/models/group_draft_model.dart';
import 'package:sankofasave/models/group_invite_model.dart';
import 'package:sankofasave/models/susu_group_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'api_exception.dart';
import 'auth_service.dart';

class GroupService {
  GroupService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _draftKey = 'susu_group_draft';

  List<SusuGroupModel>? _cachedGroups;

  Future<List<SusuGroupModel>> getGroups({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedGroups != null) {
      return _cachedGroups!;
    }

    try {
      final response = await _apiClient.get('/api/groups/');
      if (response is List) {
        final groups = response
            .whereType<Map>()
            .map((item) => SusuGroupModel.fromApi(item.cast<String, dynamic>()))
            .toList();
        _cacheGroups(groups);
        return groups;
      }
    } catch (_) {
      // Swallow errors and fall back to cached data
    }

    _cachedGroups ??= const [];
    return _cachedGroups!;
  }

  Future<SusuGroupModel?> getGroupById(String id) async {
    final cachedList = _cachedGroups;
    if (cachedList != null) {
      try {
        return cachedList.firstWhere((group) => group.id == id);
      } catch (_) {
        // not found in cache
      }
    }

    try {
      final response = await _apiClient.get('/api/groups/$id/');
      if (response is Map<String, dynamic>) {
        final group = SusuGroupModel.fromApi(response);
        _upsertCachedGroup(group);
        return group;
      }
    } catch (_) {
      // swallow errors so the UI can continue showing local data
    }

    return null;
  }

  Future<void> updateGroup(SusuGroupModel updatedGroup) async {
    _upsertCachedGroup(updatedGroup);
  }

  Future<SusuGroupModel> joinPublicGroup({
    required String groupId,
    String? introduction,
    bool autoSave = false,
    bool remindersEnabled = true,
  }) async {
    final payload = <String, dynamic>{
      if (introduction != null && introduction.isNotEmpty) 'introduction': introduction,
      if (autoSave) 'auto_save': autoSave,
      if (!remindersEnabled) 'reminders_enabled': remindersEnabled,
    };

    final response = await _apiClient.post(
      '/api/groups/$groupId/join/',
      body: payload.isEmpty ? null : payload,
    );
    if (response is Map<String, dynamic>) {
      final group = SusuGroupModel.fromApi(response);
      _upsertCachedGroup(group);
      return group;
    }
    throw ApiException('Unexpected response from server.');
  }

  Future<GroupDraftModel?> getDraftGroup() async {
    final prefs = await SharedPreferences.getInstance();
    final draftJson = prefs.getString(_draftKey);
    if (draftJson == null) return null;
    try {
      final decoded = jsonDecode(draftJson) as Map<String, dynamic>;
      return GroupDraftModel.fromJson(decoded);
    } catch (_) {
      await prefs.remove(_draftKey);
      return null;
    }
  }

  Future<void> saveDraftGroup(GroupDraftModel draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, jsonEncode(draft.toJson()));
  }

  Future<void> clearDraftGroup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  Future<SusuGroupModel> createGroupFromDraft(GroupDraftModel draft) async {
    if (draft.name == null || draft.name!.trim().isEmpty) {
      throw StateError('Group name missing');
    }
    if (draft.contributionAmount == null || draft.contributionAmount! <= 0) {
      throw StateError('Contribution amount missing');
    }
    if (draft.startDate == null) {
      throw StateError('Start date missing');
    }
    if (draft.invites.isEmpty) {
      throw StateError('Invite at least one member');
    }

    final contribution = draft.contributionAmount!;
    final authService = AuthService();
    final invites = <Map<String, dynamic>>[];

    for (final invite in draft.invites) {
      final normalizedName = invite.name.trim();
      final phone = invite.phoneNumber.trim();
      if (normalizedName.isEmpty) {
        throw StateError('Each invite needs a name.');
      }
      if (phone.isEmpty) {
        throw StateError('Each invite needs a phone number.');
      }
      invites.add({
        'name': normalizedName,
        'phoneNumber': authService.normalizePhone(phone),
      });
    }

    final payload = {
      'name': draft.name!.trim(),
      if (draft.purpose != null && draft.purpose!.trim().isNotEmpty)
        'description': draft.purpose!.trim(),
      'contributionAmount': contribution.toStringAsFixed(2),
      if (draft.frequency != null) 'frequency': draft.frequency,
      'startDate': draft.startDate!.toIso8601String(),
      'targetMemberCount': invites.length + 1,
      'invites': invites,
      'requiresApproval': true,
      'isPublic': false,
      'payoutOrder': 'Rotating${draft.frequency != null ? ' (${draft.frequency})' : ''}',
    };

    final response = await _apiClient.post(
      '/api/groups/',
      body: payload,
    );

    if (response is Map<String, dynamic>) {
      final group = SusuGroupModel.fromApi(response);
      _upsertCachedGroup(group, prepend: true);
      await clearDraftGroup();
      return group;
    }

    throw ApiException('Unexpected response when creating group.');
  }

  Future<SusuGroupModel?> logInviteReminder(
    String groupId,
    String inviteId,
  ) async {
    final response = await _apiClient.post(
      '/api/groups/$groupId/invites/$inviteId/remind/',
    );

    if (response is Map<String, dynamic>) {
      final group = SusuGroupModel.fromApi(response);
      _upsertCachedGroup(group);
      return group;
    }

    throw ApiException('Unable to send invite reminder right now.');
  }

  Future<SusuGroupModel?> updateInviteStatus({
    required String groupId,
    required String inviteId,
    required GroupInviteStatus status,
    bool? kycCompleted,
  }) async {
    final payload = {
      'status': status.key,
      if (kycCompleted != null) 'kycCompleted': kycCompleted,
    };

    final response = await _apiClient.post(
      '/api/groups/$groupId/invites/$inviteId/status/',
      body: payload,
    );

    if (response is Map<String, dynamic>) {
      final group = SusuGroupModel.fromApi(response);
      _upsertCachedGroup(group);
      return group;
    }

    throw ApiException('Unable to update invite status.');
  }

  Future<SusuGroupModel?> convertInviteToMember({
    required String groupId,
    required String inviteId,
  }) async {
    final response = await _apiClient.post(
      '/api/groups/$groupId/invites/$inviteId/promote/',
    );

    if (response is Map<String, dynamic>) {
      final group = SusuGroupModel.fromApi(response);
      _upsertCachedGroup(group);
      return group;
    }

    throw ApiException('Unable to promote invite at this time.');
  }

  void _cacheGroups(List<SusuGroupModel> groups) {
    _cachedGroups = List<SusuGroupModel>.from(groups);
  }

  void _upsertCachedGroup(SusuGroupModel group, {bool prepend = false}) {
    final current = List<SusuGroupModel>.from(_cachedGroups ?? const []);
    final existingIndex = current.indexWhere((item) => item.id == group.id);
    if (existingIndex >= 0) {
      current[existingIndex] = group;
    } else {
      if (prepend) {
        current.insert(0, group);
      } else {
        current.add(group);
      }
    }
    _cacheGroups(current);
  }

}
