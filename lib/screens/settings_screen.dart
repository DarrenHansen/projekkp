import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Settings Screen - Pengaturan aplikasi
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance section
            Text(
              'Tampilan',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? const Color(0xFFE94560) : const Color(0xFF1A1A2E),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            _buildSettingsCard(
              context,
              isDark: isDark,
              children: [
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return _SettingsTile(
                      icon: isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      iconColor: isDark
                          ? const Color(0xFFE94560)
                          : const Color(0xFF1A1A2E),
                      title: 'Dark Mode',
                      subtitle: isDark
                          ? 'Mode gelap sedang aktif'
                          : 'Mode terang sedang aktif',
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (_) => themeProvider.toggleTheme(),
                        activeColor: isDark
                            ? const Color(0xFFE94560)
                            : const Color(0xFF1A1A2E),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // About section
            Text(
              'Tentang',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? const Color(0xFFE94560) : const Color(0xFF1A1A2E),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            _buildSettingsCard(
              context,
              isDark: isDark,
              children: [
                _SettingsTile(
                  icon: Icons.info_outline,
                  iconColor: isDark
                      ? const Color(0xFF6666AA)
                      : const Color(0xFF9999AA),
                  title: 'Versi Aplikasi',
                  subtitle: '1.0.0',
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.code_outlined,
                  iconColor: isDark
                      ? const Color(0xFF6666AA)
                      : const Color(0xFF9999AA),
                  title: 'Dibuat dengan',
                  subtitle: 'Flutter + Provider + SQLite',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Features section
            Text(
              'Fitur',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? const Color(0xFFE94560) : const Color(0xFF1A1A2E),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            _buildSettingsCard(
              context,
              isDark: isDark,
              children: const [
                _SettingsTile(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'Export PDF',
                  subtitle: 'Invoice otomatis dalam format PDF profesional',
                ),
                Divider(height: 1),
                _SettingsTile(
                  icon: Icons.share_outlined,
                  title: 'Share Invoice',
                  subtitle: 'Bagikan via WhatsApp, Email, atau file PDF',
                ),
                Divider(height: 1),
                _SettingsTile(
                  icon: Icons.search_outlined,
                  title: 'Pencarian & Filter',
                  subtitle: 'Cari invoice berdasarkan nama atau nomor',
                ),
                Divider(height: 1),
                _SettingsTile(
                  icon: Icons.label_outline,
                  title: 'Status Invoice',
                  subtitle: 'Paid, Unpaid, dan Overdue tracking',
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A4A) : const Color(0xFFF0F0F5),
        ),
      ),
      child: Column(children: children),
    );
  }
}

/// Settings tile widget
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? const Color(0xFF1A1A2E)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? const Color(0xFF8888AA) : const Color(0xFF9999AA),
        ),
      ),
      trailing: trailing,
    );
  }
}
