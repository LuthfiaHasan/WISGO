class UserProfile {
  final String id;
  final String phoneNumber;
  final String fullName;
  final String role;
  final String? avatarUrl;
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    required this.phoneNumber,
    required this.fullName,
    this.role = 'tourist',
    this.avatarUrl,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'Wisatawan Ranah Minang',
      role: json['role']?.toString() ?? 'tourist',
      avatarUrl: json['avatar_url']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone_number': phoneNumber,
    'full_name': fullName,
    'role': role,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };

  /// Inisial kapital 1-2 huruf untuk avatar pengguna Minang
  String get initials {
    final clean = fullName.trim();
    if (clean.isEmpty) return 'W';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
