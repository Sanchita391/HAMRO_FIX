import 'package:flutter/material.dart';

class AppLocale extends ChangeNotifier {
  AppLocale._();
  static final AppLocale instance = AppLocale._();

  bool isEnglish = true;

  Locale get locale => Locale(isEnglish ? 'en' : 'ne');

  void setEnglish(bool value) {
    if (isEnglish == value) return;
    isEnglish = value;
    notifyListeners();
  }

  String t(String english, String nepali) => isEnglish ? english : nepali;
}

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        final english = AppLocale.instance.isEnglish;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LangChip(
                label: 'EN',
                selected: english,
                onTap: () => AppLocale.instance.setEnglish(true),
              ),
              const SizedBox(width: 4),
              _LangChip(
                label: 'ने',
                selected: !english,
                onTap: () => AppLocale.instance.setEnglish(false),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF2E7D32) : const Color(0xFFE8F5E9),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : const Color(0xFF1B5E20),
            ),
          ),
        ),
      ),
    );
  }
}
