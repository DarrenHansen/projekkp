/// Model Business Profile - Informasi usaha untuk nota/invoice
class BusinessProfile {
  int? id;
  String businessName;
  String businessAddress;
  String businessPhone;
  String businessEmail;
  String logoPath;
  String bankName;
  String bankAccount;
  String bankHolder;
  String notes;

  BusinessProfile({
    this.id,
    this.businessName = '',
    this.businessAddress = '',
    this.businessPhone = '',
    this.businessEmail = '',
    this.logoPath = '',
    this.bankName = '',
    this.bankAccount = '',
    this.bankHolder = '',
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
      'bank_name': bankName,
      'bank_account': bankAccount,
      'bank_holder': bankHolder,
      'notes': notes,
    };
  }

  factory BusinessProfile.fromMap(Map<String, dynamic> map) {
    return BusinessProfile(
      id: map['id'],
      businessName: map['business_name'] ?? '',
      businessAddress: map['business_address'] ?? '',
      businessPhone: map['business_phone'] ?? '',
      businessEmail: map['business_email'] ?? '',
      logoPath: map['logo_path'] ?? '',
      bankName: map['bank_name'] ?? '',
      bankAccount: map['bank_account'] ?? '',
      bankHolder: map['bank_holder'] ?? '',
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
    String? bankName,
    String? bankAccount,
    String? bankHolder,
    String? notes,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
      businessEmail: businessEmail ?? this.businessEmail,
      logoPath: logoPath ?? this.logoPath,
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
      bankHolder: bankHolder ?? this.bankHolder,
      notes: notes ?? this.notes,
    );
  }

  bool get isEmpty => businessName.isEmpty && businessAddress.isEmpty;
}
