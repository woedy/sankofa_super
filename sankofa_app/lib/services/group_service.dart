import 'package:sankofasave/models/susu_group_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GroupService {
  static const String _groupsKey = 'susu_groups';

  Future<List<SusuGroupModel>> getGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = prefs.getStringList(_groupsKey);
    if (groupsJson != null && groupsJson.isNotEmpty) {
      return groupsJson.map((json) => SusuGroupModel.fromJson(jsonDecode(json))).toList();
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

  List<SusuGroupModel> _getDefaultGroups() {
    final now = DateTime.now();
    return [
      SusuGroupModel(
        id: 'group_001',
        name: 'Unity Savers Group',
        memberIds: ['user_001', 'user_002', 'user_003', 'user_004', 'user_005'],
        memberNames: ['Kwame Mensah', 'Ama Darko', 'Kofi Asante', 'Abena Osei', 'Yaw Boateng'],
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
        memberNames: ['Kwame Mensah', 'Akua Frimpong', 'Efua Adjei', 'Adwoa Mensah'],
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
        memberIds: ['user_001', 'user_009', 'user_010', 'user_011', 'user_012', 'user_013'],
        memberNames: ['Kwame Mensah', 'Kwesi Owusu', 'Nana Agyeman', 'Kojo Addai', 'Yaa Appiah', 'Kwabena Ofori'],
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
