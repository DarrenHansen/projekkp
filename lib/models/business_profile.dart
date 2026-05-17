import 'bank_account.dart';
import 'dart:convert';
/// Model Business Profile - Informasi usaha untuk nota/invoice
class BusinessProfile {
  int? id;

  String businessName;
  String businessAddress;
  String businessPhone;
  String businessEmail;
  String logoPath;

  List<BankAccount> bankAccounts;

  String notes;

  BusinessProfile({
    this.id,
    this.businessName = '',
    this.businessAddress = '',
    this.businessPhone = '',
    this.businessEmail = '',
    this.logoPath = '',
    this.bankAccounts = const [],
    this.notes = '',
  });

 Map<String, dynamic> toMap() {
  return {
    'id': id,
    'business_name': businessName,
    'business_address': businessAddress,
    'business_phone': businessPhone,
    'business_email': businessEmail,
    'logo_path': logoPath,

    // UBAH INI
    'bank_accounts': jsonEncode(
      bankAccounts.map((e) => e.toMap()).toList(),
    ),

    'notes': notes,
  };
}

 factory BusinessProfile.fromMap(
  Map<String, dynamic> map,
) {
  return BusinessProfile(
    id: map['id'],

    businessName:
        map['business_name'] ?? '',

    businessAddress:
        map['business_address'] ?? '',

    businessPhone:
        map['business_phone'] ?? '',

    businessEmail:
        map['business_email'] ?? '',

    logoPath:
        map['logo_path'] ?? '',

    bankAccounts:
        map['bank_accounts'] != null &&
                map['bank_accounts']
                    .toString()
                    .isNotEmpty
            ? (jsonDecode(
                    map['bank_accounts'])
                as List)
                .map(
                  (e) =>
                      BankAccount.fromMap(e),
                )
                .toList()
            : [],

    notes: map['notes'] ?? '',
  );
}
  BusinessProfile copyWith({
    int? id,
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessEmail,
    String? logoPath,
    List<BankAccount>? bankAccounts,
    String? notes,
  }) {
    return BusinessProfile(
      id: id ?? this.id,

      businessName:
          businessName ?? this.businessName,

      businessAddress:
          businessAddress ??
              this.businessAddress,

      businessPhone:
          businessPhone ?? this.businessPhone,

      businessEmail:
          businessEmail ?? this.businessEmail,

      logoPath:
          logoPath ?? this.logoPath,

      bankAccounts:
          bankAccounts ?? this.bankAccounts,

      notes: notes ?? this.notes,
    );
  }

  bool get isEmpty =>
      businessName.isEmpty &&
      businessAddress.isEmpty;
}