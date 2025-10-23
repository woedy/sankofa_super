import 'dart:convert';

import 'package:sankofasave/models/group_draft_model.dart';
import 'package:sankofasave/models/group_invite_model.dart';
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
      payoutOrder:
          'Rotating${draft.frequency != null ? ' (${draft.frequency})' : ''}',
      isPublic: false,
      description: draft.purpose,
      frequency: draft.frequency,
      location: null,
      requiresApproval: true,
      createdAt: now,
      updatedAt: now,
    );

    groups.insert(0, newGroup);
    await _saveGroups(groups);
    await clearDraftGroup();
    return newGroup;
  }

  Future<SusuGroupModel> joinPublicGroup({
    required String groupId,
    required UserModel user,
    String? introduction,
    bool autoSave = false,
    bool remindersEnabled = true,
  }) async {
    final groups = await getGroups();
    final index = groups.indexWhere((group) => group.id == groupId);
    if (index == -1) {
      throw StateError('Group not found');
    }
    final group = groups[index];
    if (!group.isPublic) {
      throw StateError('This group is invite-only');
    }
    if (group.memberIds.contains(user.id)) {
      return group;
    }
    final seatsRemaining = group.targetMemberCount - group.memberIds.length;
    if (seatsRemaining <= 0) {
      throw StateError('This group is already at capacity');
    }

    final now = DateTime.now();
    final updatedGroup = group.copyWith(
      memberIds: [...group.memberIds, user.id],
      memberNames: [...group.memberNames, user.name],
      updatedAt: now,
    );

    groups[index] = updatedGroup;
    await _saveGroups(groups);
    return updatedGroup;
  }

  Future<SusuGroupModel?> logInviteReminder(
    String groupId,
    String inviteId,
  ) async {
    final groups = await getGroups();
    final index = groups.indexWhere((group) => group.id == groupId);
    if (index == -1) return null;
    final group = groups[index];
    final now = DateTime.now();

    final updatedInvites = group.invites.map((invite) {
      if (invite.id != inviteId) return invite;
      return invite.copyWith(
        lastRemindedAt: now,
        reminderCount: invite.reminderCount + 1,
      );
    }).toList();

    final updatedGroup = group.copyWith(
      invites: updatedInvites,
      updatedAt: now,
    );

    groups[index] = updatedGroup;
    await _saveGroups(groups);
    return updatedGroup;
  }

  Future<SusuGroupModel?> updateInviteStatus({
    required String groupId,
    required String inviteId,
    required GroupInviteStatus status,
    bool? kycCompleted,
  }) async {
    final groups = await getGroups();
    final index = groups.indexWhere((group) => group.id == groupId);
    if (index == -1) return null;
    final group = groups[index];
    final now = DateTime.now();

    final updatedInvites = group.invites.map((invite) {
      if (invite.id != inviteId) return invite;
      return invite.copyWith(
        status: status,
        kycCompleted: kycCompleted ?? invite.kycCompleted,
        respondedAt:
            status == GroupInviteStatus.pending ? invite.respondedAt : now,
      );
    }).toList();

    final updatedGroup = group.copyWith(
      invites: updatedInvites,
      updatedAt: now,
    );

    groups[index] = updatedGroup;
    await _saveGroups(groups);
    return updatedGroup;
  }

  Future<SusuGroupModel?> convertInviteToMember({
    required String groupId,
    required String inviteId,
  }) async {
    final groups = await getGroups();
    final index = groups.indexWhere((group) => group.id == groupId);
    if (index == -1) return null;
    final group = groups[index];
    final inviteIndex = group.invites.indexWhere((invite) => invite.id == inviteId);
    if (inviteIndex == -1) return group;
    final invite = group.invites[inviteIndex];
    final now = DateTime.now();

    final updatedMemberIds = List<String>.from(group.memberIds)
      ..add('member_${now.millisecondsSinceEpoch}');
    final updatedMemberNames = List<String>.from(group.memberNames)
      ..add(invite.name);
    final updatedInvites = List<GroupInviteModel>.from(group.invites)
      ..removeAt(inviteIndex);

    final updatedGroup = group.copyWith(
      memberIds: updatedMemberIds,
      memberNames: updatedMemberNames,
      invites: updatedInvites,
      updatedAt: now,
    );

    groups[index] = updatedGroup;
    await _saveGroups(groups);
    return updatedGroup;
  }

  String _generateMockPhone(int seed) {
    final normalized = (seed.abs() % 1000000).toString().padLeft(6, '0');
    final prefix = '20';
    final middle = normalized.substring(0, 3);
    final suffix = normalized.substring(3);
    return '+233 $prefix $middle $suffix';
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
        invites: const [],
        targetMemberCount: 5,
        contributionAmount: 200.00,
        cycleNumber: 3,
        totalCycles: 5,
        nextPayoutDate: now.add(const Duration(days: 7)),
        payoutOrder: 'Rotating (Weekly)',
        isPublic: false,
        description:
            'A trusted weekly circle for SMEs pooling ₵200 each to fund business reinvestment.',
        frequency: 'Weekly contributions',
        location: 'Madina Market • Accra',
        requiresApproval: true,
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
        invites: [
          GroupInviteModel(
            id: 'invite_2001',
            name: 'Selina Koranteng',
            phoneNumber: '+233 20 555 1122',
            status: GroupInviteStatus.pending,
            kycCompleted: false,
            sentAt: now.subtract(const Duration(days: 4)),
            lastRemindedAt: now.subtract(const Duration(days: 1)),
            reminderCount: 1,
          ),
          GroupInviteModel(
            id: 'invite_2002',
            name: 'Naana Sarpong',
            phoneNumber: '+233 24 880 4411',
            status: GroupInviteStatus.accepted,
            kycCompleted: true,
            sentAt: now.subtract(const Duration(days: 6)),
            respondedAt: now.subtract(const Duration(days: 2)),
            reminderCount: 2,
            lastRemindedAt: now.subtract(const Duration(days: 2)),
          ),
        ],
        targetMemberCount: 6,
        contributionAmount: 150.00,
        cycleNumber: 2,
        totalCycles: 6,
        nextPayoutDate: now.add(const Duration(days: 14)),
        payoutOrder: 'Rotating (Bi-weekly)',
        isPublic: false,
        description:
            'A women-led circle funding traders and artisans with flexible two-week rotations.',
        frequency: 'Every two weeks',
        location: 'Koforidua Central',
        requiresApproval: true,
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
        invites: [
          GroupInviteModel(
            id: 'invite_3001',
            name: 'Afia Ansah',
            phoneNumber: '+233 55 110 3399',
            status: GroupInviteStatus.pending,
            kycCompleted: true,
            sentAt: now.subtract(const Duration(days: 10)),
            reminderCount: 3,
            lastRemindedAt: now.subtract(const Duration(days: 2)),
          ),
          GroupInviteModel(
            id: 'invite_3002',
            name: 'Yaw Tetteh',
            phoneNumber: '+233 27 990 2288',
            status: GroupInviteStatus.declined,
            kycCompleted: false,
            sentAt: now.subtract(const Duration(days: 8)),
            respondedAt: now.subtract(const Duration(days: 1)),
          ),
        ],
        targetMemberCount: 8,
        contributionAmount: 300.00,
        cycleNumber: 4,
        totalCycles: 8,
        nextPayoutDate: now.add(const Duration(days: 21)),
        payoutOrder: 'Rotating (Monthly)',
        isPublic: false,
        description:
            'Import/export traders rotating a monthly ₵300 stake to bulk purchase stock.',
        frequency: 'Monthly contributions',
        location: 'Kantamanto • Accra',
        requiresApproval: true,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now,
      ),
      SusuGroupModel(
        id: 'group_public_001',
        name: 'Accra Market Vendors',
        memberIds: [
          'user_014',
          'user_015',
          'user_016',
          'user_017',
          'user_018',
        ],
        memberNames: [
          'Esi Boateng',
          'Rita Amankwah',
          'Kojo Nyarko',
          'Hannah Asare',
          'Yaw Nyamekye',
        ],
        invites: const [],
        targetMemberCount: 12,
        contributionAmount: 180.00,
        cycleNumber: 1,
        totalCycles: 12,
        nextPayoutDate: now.add(const Duration(days: 5)),
        payoutOrder: 'Rotating (Weekly)',
        isPublic: true,
        description:
            'Open weekly circle for Makola and Okaishie vendors building working capital.',
        frequency: 'Weekly contributions',
        location: 'Makola Market • Accra',
        requiresApproval: false,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      ),
      SusuGroupModel(
        id: 'group_public_002',
        name: 'Ashesi Alumni Builders',
        memberIds: [
          'user_021',
          'user_022',
          'user_023',
          'user_024',
        ],
        memberNames: [
          'Leslie Mensima',
          'Kwesi Addae',
          'Adjoa Sackey',
          'Samuel Koomson',
        ],
        invites: const [],
        targetMemberCount: 10,
        contributionAmount: 400.00,
        cycleNumber: 0,
        totalCycles: 10,
        nextPayoutDate: now.add(const Duration(days: 10)),
        payoutOrder: 'Rotating (Bi-weekly)',
        isPublic: true,
        description:
            'Tech and design alumni pooling ₵400 bi-weekly toward side-hustle launches.',
        frequency: 'Bi-weekly contributions',
        location: 'Virtual • Nationwide',
        requiresApproval: true,
        createdAt: now.subtract(const Duration(days: 14)),
        updatedAt: now,
      ),
      SusuGroupModel(
        id: 'group_public_003',
        name: 'Cape Coast Teachers Fund',
        memberIds: [
          'user_030',
          'user_031',
          'user_032',
          'user_033',
          'user_034',
          'user_035',
        ],
        memberNames: [
          'Agnes Quaye',
          'Naana Eshun',
          'Felix Aidoo',
          'Abigail Appiah',
          'Joseph Ankrah',
          'Matilda Gyan',
        ],
        invites: const [],
        targetMemberCount: 15,
        contributionAmount: 220.00,
        cycleNumber: 2,
        totalCycles: 15,
        nextPayoutDate: now.add(const Duration(days: 3)),
        payoutOrder: 'Rotating (Monthly)',
        isPublic: true,
        description:
            'Cape Coast teachers saving toward professional development and rent advances.',
        frequency: 'Monthly contributions',
        location: 'Cape Coast Metropolis',
        requiresApproval: false,
        createdAt: now.subtract(const Duration(days: 75)),
        updatedAt: now,
      ),
    ];
  }
}
