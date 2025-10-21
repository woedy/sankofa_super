class UserAvatarResolver {
  static const Map<String, String> _nameToAsset = {
    'Kwame Mensah': 'assets/images/African_man_business_null_1760947790305.jpg',
    'Ama Darko': 'assets/images/African_woman_professional_null_1760947773326.jpg',
    'Abena Osei': 'assets/images/African_woman_professional_null_1760947773326.jpg',
    'Akua Frimpong': 'assets/images/African_woman_professional_null_1760947773326.jpg',
    'Efua Adjei': 'assets/images/African_woman_professional_null_1760947773326.jpg',
    'Adwoa Mensah': 'assets/images/African_woman_professional_null_1760947773326.jpg',
    'Kofi Asante': 'assets/images/African_man_business_null_1760947790305.jpg',
    'Yaw Boateng': 'assets/images/African_community_savings_group_null_1760947730962.png',
    'Kwesi Owusu': 'assets/images/African_community_savings_group_null_1760947730962.png',
    'Nana Agyeman': 'assets/images/African_community_savings_group_null_1760947730962.png',
    'Kojo Addai': 'assets/images/African_community_savings_group_null_1760947730962.png',
    'Yaa Appiah': 'assets/images/African_community_savings_group_null_1760947730962.png',
    'Kwabena Ofori': 'assets/images/African_community_savings_group_null_1760947730962.png',
  };

  static String? resolve(String? name) {
    if (name == null) return null;
    return _nameToAsset[name];
  }
}