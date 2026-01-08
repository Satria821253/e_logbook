class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? token;
  final String? vesselName;
  final String? vesselNumber;
  final String? captainName;
  final int? crewCount;
  final List<String>? crewNames;
  final String? role; // 'Nahkoda' or 'ABK'
  final String? profileImagePath;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.token,
    this.vesselName,
    this.vesselNumber,
    this.captainName,
    this.crewCount,
    this.crewNames,
    this.role = 'Nahkoda', // Default role
    this.profileImagePath,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      token: json['token'],
      vesselName: json['vessel_name'],
      vesselNumber: json['vessel_number'],
      captainName: json['captain_name'],
      crewCount: json['crew_count'],
      crewNames: json['crew_names'] != null
          ? List<String>.from(json['crew_names'])
          : null,
      role: json['role'] ?? 'Nahkoda',
      profileImagePath: json['profile_image_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'token': token,
      'vessel_name': vesselName,
      'vessel_number': vesselNumber,
      'captain_name': captainName,
      'crew_count': crewCount,
      'crew_names': crewNames,
      'role': role,
      'profile_image_path': profileImagePath,
    };
  }

  bool get isNahkoda => (role ?? 'Nahkoda') == 'Nahkoda';
  bool get isABK => (role ?? 'Nahkoda') == 'ABK';
}
