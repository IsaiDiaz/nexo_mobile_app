enum UserRole { client, professional }

enum RegistrationStep {
  none,
  roleSelection,
  userRegistration,
  personDetails,
  professionalProfile,
  completed,
}

class RegistrationData {
  final UserRole? role;
  final String? email;
  final String? password;
  final String? username;
  final String? avatarPath;

  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? identificationNumber;

  final double? hourlyRate;
  final String? address;
  final String? description;
  final String? businessName;
  final double? coordinateLat;
  final double? coordinateLon;
  final String? category;

  RegistrationData({
    this.role,
    this.email,
    this.password,
    this.username,
    this.avatarPath,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.identificationNumber,
    this.hourlyRate,
    this.address,
    this.description,
    this.businessName,
    this.coordinateLat,
    this.coordinateLon,
    this.category,
  });

  RegistrationData copyWith({
    UserRole? role,
    String? email,
    String? password,
    String? username,
    String? avatarPath,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? identificationNumber,
    double? hourlyRate,
    String? address,
    String? description,
    String? businessName,
    double? coordinateLat,
    double? coordinateLon,
    String? category,
  }) {
    return RegistrationData(
      role: role ?? this.role,
      email: email ?? this.email,
      password: password ?? this.password,
      username: username ?? this.username,
      avatarPath: avatarPath ?? this.avatarPath,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      identificationNumber: identificationNumber ?? this.identificationNumber,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      address: address ?? this.address,
      description: description ?? this.description,
      businessName: businessName ?? this.businessName,
      coordinateLat: coordinateLat ?? this.coordinateLat,
      coordinateLon: coordinateLon ?? this.coordinateLon,
      category: category ?? this.category,
    );
  }

  static RegistrationData empty() {
    return RegistrationData();
  }
}
