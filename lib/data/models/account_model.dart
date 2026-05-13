class AccountModel {
  final int? id;
  final String serviceName;
  final String username;
  final String encryptedPassword;
  final String? decryptedPassword;

  AccountModel(
    {
      this.id,
      required this.serviceName,
      required this.username,
      required this.encryptedPassword,
      this.decryptedPassword,
    }
  );

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'],
      serviceName: map['service_name'],
      username: map['username'],
      encryptedPassword: map['encrypted_password'],
    );
  }

  AccountModel copyWith({String? decryptedPassword}) {
    return AccountModel(
      id: id,
      serviceName: serviceName,
      username: username,
      encryptedPassword: encryptedPassword,
      decryptedPassword: decryptedPassword ?? this.decryptedPassword,
    );
  }
}