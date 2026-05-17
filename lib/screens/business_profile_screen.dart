import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/bank_account.dart';

import '../providers/business_profile_provider.dart';
import '../models/business_profile.dart';
import '../utils/app_localizations.dart';

/// Business Profile Screen - Kustomisasi info usaha untuk nota/invoice
class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  List<Map<String, TextEditingController>> _bankControllers = [];
  final _notesController = TextEditingController();
  String _logoPath = '';
  bool _isSaving = false;
  void _addBankAccount() {
  setState(() {
    _bankControllers.add({
      'bankName': TextEditingController(),
      'bankAccount': TextEditingController(),
      'bankHolder': TextEditingController(),
    });
  });
}

void _removeBankAccount(int index) {
  setState(() {
    _bankControllers[index]['bankName']?.dispose();
    _bankControllers[index]['bankAccount']?.dispose();
    _bankControllers[index]['bankHolder']?.dispose();

    _bankControllers.removeAt(index);
  });
}

  @override
  void initState() {
    super.initState();
    final profile = context.read<BusinessProfileProvider>().profile;
    _nameController.text = profile.businessName;
    _addressController.text = profile.businessAddress;
    _phoneController.text = profile.businessPhone;
    _emailController.text = profile.businessEmail;
    if (profile.bankAccounts.isNotEmpty) {
  _bankControllers = profile.bankAccounts.map((bank) {
    return {
      'bankName': TextEditingController(text: bank.bankName),
      'bankAccount': TextEditingController(text: bank.bankAccount),
      'bankHolder': TextEditingController(text: bank.bankHolder),
    };
  }).toList();
} else {
  _addBankAccount();
}
    _notesController.text = profile.notes;
    _logoPath = profile.logoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    for (final bank in _bankControllers) {
  bank['bankName']?.dispose();
  bank['bankAccount']?.dispose();
  bank['bankHolder']?.dispose();
}
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final profile = BusinessProfile(
        id: context.read<BusinessProfileProvider>().profile.id,
        businessName: _nameController.text.trim(),
        businessAddress: _addressController.text.trim(),
        businessPhone: _phoneController.text.trim(),
        businessEmail: _emailController.text.trim(),
        logoPath: _logoPath,
        bankAccounts: _bankControllers.map((bank) {
  return BankAccount(
    bankName: bank['bankName']!.text.trim(),
    bankAccount: bank['bankAccount']!.text.trim(),
    bankHolder: bank['bankHolder']!.text.trim(),
  );
}).toList(),
        notes: _notesController.text.trim(),
      );

      await context.read<BusinessProfileProvider>().saveProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil disimpan')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('business_profile'), style: const TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo picker
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                    if (picked != null) {
                      setState(() => _logoPath = picked.path);
                    }
                  },
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF16162A) : const Color(0xFFF0F0F5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF2A2A4A) : const Color(0xFFE0E0F0)),
                    ),
                    child: _logoPath.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(File(_logoPath), fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.business_outlined, size: 30, color: isDark ? const Color(0xFF6666AA) : const Color(0xFF9999AA)),
                              const SizedBox(height: 4),
                              Text(loc.get('product_photo'), style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF6666AA) : const Color(0xFF9999AA))),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: loc.get('business_name'), prefixIcon: const Icon(Icons.business_outlined)),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: loc.get('business_address'), prefixIcon: const Icon(Icons.location_on_outlined)),
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(labelText: loc.get('business_phone'), prefixIcon: const Icon(Icons.phone_outlined)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: loc.get('business_email'), prefixIcon: const Icon(Icons.email_outlined)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bank Info
Text(
  'Informasi Bank',
  style: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: isDark
        ? const Color(0xFFE94560)
        : const Color(0xFF1A1A2E),
  ),
),

const SizedBox(height: 12),

ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: _bankControllers.length,
  itemBuilder: (context, index) {
    final bank = _bankControllers[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF16162A)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2A2A4A)
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bank ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),

              if (_bankControllers.length > 1)
                IconButton(
                  onPressed: () => _removeBankAccount(index),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: bank['bankName'],
            decoration: InputDecoration(
              labelText: loc.get('bank_name'),
              prefixIcon:
                  const Icon(Icons.account_balance_outlined),
            ),
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: bank['bankAccount'],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: loc.get('bank_account'),
              prefixIcon: const Icon(Icons.credit_card),
            ),
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: bank['bankHolder'],
            decoration: InputDecoration(
              labelText: loc.get('bank_holder'),
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
        ],
      ),
    );
  },
),

SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    onPressed: _addBankAccount,
    icon: const Icon(Icons.add),
    label: const Text('Tambah Bank'),
  ),
),

const SizedBox(height: 12),

TextFormField(
  controller: _notesController,
  decoration: InputDecoration(
    labelText: loc.get('profile_notes'),
    prefixIcon: const Icon(Icons.notes),
    alignLabelWithHint: true,
  ),
  maxLines: 3,
),

const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(loc.get('save'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
