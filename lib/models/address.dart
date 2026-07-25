// lib/models/address.dart

class Address {
  final String id;
  final String userId;
  final String label;
  final String addressLine;
  final String city;
  final bool isDefault;

  const Address({
    required this.id,
    required this.userId,
    required this.label,
    required this.addressLine,
    required this.city,
    required this.isDefault,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      label: json['label'] as String? ?? 'Home',
      addressLine: json['address_line'] as String,
      city: json['city'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'label': label,
        'address_line': addressLine,
        'city': city,
        'is_default': isDefault,
      };

  String get fullAddress => '$addressLine, $city';
}
