import 'dart:convert';

import 'package:sankofasave/models/group_draft_model.dart';
import 'package:sankofasave/models/group_invite_model.dart';
import 'package:sankofasave/models/susu_group_model.dart';
import 'package:sankofasave/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'api_exception.dart';

class GroupService {
  GroupService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _localGroupsKey = 'susu_groups';
  static const String _draftKey = 'susu_group_draft';

  List<SusuGroupModel>? _cachedGroups;

  Future<List<SusuGroupModel>> getGroups({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedGroups != null) {
      return _cachedGroups!;
    }

    final localGroups = await _loadLocalGroups();
    List<SusuGroupModel> remoteGroups = [];

    try {
      final response = await _apiClient.get('/api/groups/');
      if (response is List) {
        remoteGroups = response
            .whereType<Map>()
            .map((item) => SusuGroupModel.fromApi(item.cast<String, dynamic>()))
            .toList();
      }
    } catch (_) {
      remoteGroups = [];
    }

    final remoteIds = remoteGroups.map((group) => group.id).toSet();
    final merged = <SusuGroupModel>[...remoteGroups];

    for (final group in localGroups) {
      if (!remoteIds.contains(group.id)) {
        merged.add(group);
      }
    }

    _cacheGroups(merged);
    return merged;
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

    final local = await _loadLocalGroups();
    try {
      final localGroup = local.firstWhere((group) => group.id == id);
      _upsertCachedGroup(localGroup);
      return localGroup;
    } catch (_) {
      // continue to fetch from API
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
    if (!_isLocalGroupId(updatedGroup.id)) {
      _upsertCachedGroup(updatedGroup);
      return;
    }

    final localGroups = await _loadLocalGroups();
    final index = localGroups.indexWhere((group) => group.id == updatedGroup.id);
    if (index == -1) {
      return;
    }

    localGroups[index] = updatedGroup;
    await _saveLocalGroups(localGroups);
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

  Future<SusuGroupModel> createGroupFromDraft(
    GroupDraftModel draft, {
    required UserModel owner,
  }) async {
    if (draft.name == null || draft.name!.trim().isEmpty) {
      throw StateError('Group name missing');
    }
    if (draft.contributionAmount == null || draft.contributionAmount! <= 0) {
      throw StateError('Contribution amount missing');
    }
    if (draft.startDate == null) {
      throw StateError('Start date missing');
    }
    if (draft.memberNames.isEmpty) {
      throw StateError('Invite at least one member');
    }

    final localGroups = await _loadLocalGroups();
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final generatedId = 'group_$timestamp';

    final memberIds = <String>[owner.id];
    final memberNames = <String>[owner.name];
    final pendingInvites = <GroupInviteModel>[];

    for (var i = 0; i < draft.memberNames.length; i++) {
      final inviteName = draft.memberNames[i];
      final inviteId = 'invite_${timestamp}_$i';
      pendingInvites.add(
        GroupInviteModel(
          id: inviteId,
          name: inviteName,
          phoneNumber: _generateMockPhone(timestamp + i),
          status: GroupInviteStatus.pending,
          kycCompleted: false,
          sentAt: now,
        ),
      );
    }

    final targetMemberCount = memberNames.length + pendingInvites.length;

    final newGroup = SusuGroupModel(
      id: generatedId,
      name: draft.name!.trim(),
      memberIds: memberIds,
      memberNames: memberNames,
      invites: pendingInvites,
      targetMemberCount: targetMemberCount,
      contributionAmount: draft.contributionAmount!,
      cycleNumber: 0,
      totalCycles: targetMemberCount,
      nextPayoutDate: draft.startDate!,
      payoutOrder: 'Rotating${draft.frequency != null ? ' (${draft.frequency})' : ''}',
      isPublic: false,
      description: draft.purpose,
      frequency: draft.frequency,
      location: null,
      requiresApproval: true,
      createdAt: now,
      updatedAt: now,
    );

    localGroups.insert(0, newGroup);
    await _saveLocalGroups(localGroups);
    await clearDraftGroup();
    _upsertCachedGroup(newGroup, prepend: true);
    return newGroup;
  }

  Future<SusuGroupModel?> logInviteReminder(
    String groupId,
    String inviteId,
  ) async {
    return _updateLocalGroup(
      groupId,
      (group) {
        final now = DateTime.now();
        final updatedInvites = group.invites.map((invite) {
          if (invite.id != inviteId) return invite;
          return invite.copyWith(
            lastRemindedAt: now,
            reminderCount: invite.reminderCount + 1,
          );
        }).toList();

        return group.copyWith(invites: updatedInvites, updatedAt: now);
      },
    );
  }

  Future<SusuGroupModel?> updateInviteStatus({
    required String groupId,
    required String inviteId,
    required GroupInviteStatus status,
    bool? kycCompleted,
  }) async {
    return _updateLocalGroup(
      groupId,
      (group) {
        final now = DateTime.now();
        final updatedInvites = group.invites.map((invite) {
          if (invite.id != inviteId) return invite;
          return invite.copyWith(
            status: status,
            kycCompleted: kycCompleted ?? invite.kycCompleted,
            respondedAt: status == GroupInviteStatus.pending ? invite.respondedAt : now,
          );
        }).toList();

        return group.copyWith(invites: updatedInvites, updatedAt: now);
      },
    );
  }

  Future<SusuGroupModel?> convertInviteToMember({
    required String groupId,
    required String inviteId,
  }) async {
    return _updateLocalGroup(
      groupId,
      (group) {
        final inviteIndex = group.invites.indexWhere((invite) => invite.id == inviteId);
        if (inviteIndex == -1) {
          return group;
        }

        final invite = group.invites[inviteIndex];
        final now = DateTime.now();

        final updatedMemberIds = List<String>.from(group.memberIds)
          ..add('member_${now.millisecondsSinceEpoch}');
        final updatedMemberNames = List<String>.from(group.memberNames)
          ..add(invite.name);
        final updatedInvites = List<GroupInviteModel>.from(group.invites)
          ..removeAt(inviteIndex);

        return group.copyWith(
          memberIds: updatedMemberIds,
          memberNames: updatedMemberNames,
          invites: updatedInvites,
          updatedAt: now,
        );
      },
    );
  }

  Future<List<SusuGroupModel>> _loadLocalGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = prefs.getStringList(_localGroupsKey);
    if (groupsJson == null || groupsJson.isEmpty) {
      return [];
    }

    return groupsJson
        .map((json) => SusuGroupModel.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveLocalGroups(List<SusuGroupModel> groups) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = groups.map((group) => jsonEncode(group.toJson())).toList();
    await prefs.setStringList(_localGroupsKey, groupsJson);
  }

  Future<SusuGroupModel?> _updateLocalGroup(
    String groupId,
    SusuGroupModel Function(SusuGroupModel group) updater,
  ) async {
    if (!_isLocalGroupId(groupId)) {
      throw ApiException('Invite management is not yet supported for live groups.');
    }

    final localGroups = await _loadLocalGroups();
    final index = localGroups.indexWhere((group) => group.id == groupId);
    if (index == -1) {
      return null;
    }

    final updatedGroup = updater(localGroups[index]);
    localGroups[index] = updatedGroup;
    await _saveLocalGroups(localGroups);
    _upsertCachedGroup(updatedGroup);
    return updatedGroup;
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

  bool _isLocalGroupId(String id) => id.startsWith('group_');

  String _generateMockPhone(int seed) {
    final normalized = (seed.abs() % 1000000).toString().padLeft(6, '0');
    final prefix = '20';
    final middle = normalized.substring(0, 3);
    final suffix = normalized.substring(3);
    return '+233 $prefix $middle $suffix';
  }
}
