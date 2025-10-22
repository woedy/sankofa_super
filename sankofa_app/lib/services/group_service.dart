import 'dart:convert';

import 'package:sankofasave/models/group_draft_model.dart';
import 'package:sankofasave/models/susu_group_model.dart';
import 'package:sankofasave/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupService {
  static const String _groupsKey = 'susu_groups';
  static const String _draftKey = 'susu_group_draft';

  Future<List<SusuGroupModel>> getGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = prefs.getStringList(_groupsKey);
    if (groupsJson != null && groupsJson.isNotEmpty) {
      return groupsJson
          .map((json) => SusuGroupModel.fromJson(jsonDecode(json)))
          .toList();
    }
    final defaultGroups = _getDefaultGroups();
    await _saveGroups(defaultGroups);
    return defaultGroups;
  }

  Future<void> _saveGroups(List<SusuGroupModel> groups) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = groups.map((g) => jsonEncode(g.toJson())).toList();
    await prefs.setStringList(_groupsKey, groupsJson);
  }

  Future<void> updateGroup(SusuGroupModel updatedGroup) async {
    final groups = await getGroups();
    final index = groups.indexWhere((group) => group.id == updatedGroup.id);
    if (index == -1) return;
    groups[index] = updatedGroup;
    await _saveGroups(groups);
  }

  Future<SusuGroupModel?> getGroupById(String id) async {
    final groups = await getGroups();
    try {
      return groups.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
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

    final groups = await getGroups();
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final generatedId = 'group_$timestamp';

    final memberIds = <String>[owner.id];
    final memberNames = <String>[owner.name];

    for (var i = 0; i < draft.memberNames.length; i++) {
      memberIds.add('invite_${timestamp}_$i');
      memberNames.add(draft.memberNames[i]);
    }

    final newGroup = SusuGroupModel(
      id: generatedId,
      name: draft.name!.trim(),
      memberIds: memberIds,
      memberNames: memberNames,
      contributionAmount: draft.contributionAmount!,
      cycleNumber: 0,
      totalCycles: memberNames.length,
      nextPayoutDate: draft.startDate!,
      payoutOrder:
          'Rotating${draft.frequency != null ? ' (${draft.frequency})' : ''}',
      createdAt: now,
      updatedAt: now,
    );

    groups.insert(0, newGroup);
    await _saveGroups(groups);
    await clearDraftGroup();
    return newGroup;
  }

  List<SusuGroupModel> _getDefaultGroups() {
    final now = DateTime.now();
    return [
      SusuGroupModel(
        id: 'group_001',
        name: 'Unity Savers Group',
        memberIds: [
          'user_001',
          'user_002',
          'user_003',
          'user_004',
          'user_005',
        ],
        memberNames: [
          'Kwame Mensah',
          'Ama Darko',
          'Kofi Asante',
          'Abena Osei',
          'Yaw Boateng',
        ],
        contributionAmount: 200.00,
        cycleNumber: 3,
        totalCycles: 5,
        nextPayoutDate: now.add(const Duration(days: 7)),
        payoutOrder: 'Rotating',
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now,
      ),
      SusuGroupModel(
        id: 'group_002',
        name: 'Women Empowerment Circle',
        memberIds: ['user_001', 'user_006', 'user_007', 'user_008'],
        memberNames: [
          'Kwame Mensah',
          'Akua Frimpong',
          'Efua Adjei',
          'Adwoa Mensah',
        ],
        contributionAmount: 150.00,
        cycleNumber: 2,
        totalCycles: 4,
        nextPayoutDate: now.add(const Duration(days: 14)),
        payoutOrder: 'Rotating',
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now,
      ),
      SusuGroupModel(
        id: 'group_003',
        name: 'Traders Alliance',
        memberIds: [
          'user_001',
          'user_009',
          'user_010',
          'user_011',
          'user_012',
          'user_013',
        ],
        memberNames: [
          'Kwame Mensah',
          'Kwesi Owusu',
          'Nana Agyeman',
          'Kojo Addai',
          'Yaa Appiah',
          'Kwabena Ofori',
        ],
        contributionAmount: 300.00,
        cycleNumber: 4,
        totalCycles: 6,
        nextPayoutDate: now.add(const Duration(days: 21)),
        payoutOrder: 'Rotating',
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now,
      ),
    ];
  }
}
