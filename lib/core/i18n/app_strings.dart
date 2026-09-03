/// Interim hand-written localisation for the profile / settings surface
/// (P8-07).
///
/// This is deliberately *small* — it covers only the account menu, the staff
/// and patient profile screens, and the preferences controls, so those screens
/// demonstrate working English/Arabic switching (including RTL).
///
/// TODO(i18n): replace with generated `AppLocalizations` (ARB + `flutter
/// gen-l10n`) and translate the whole app, then audit every screen for RTL.
library;

import 'package:flutter/widgets.dart';

class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  static AppStrings of(BuildContext context) =>
      AppStrings(Localizations.localeOf(context));

  bool get _ar => locale.languageCode == 'ar';

  String get profile => _ar ? 'الملف الشخصي' : 'Profile';
  String get signOut => _ar ? 'تسجيل الخروج' : 'Sign out';
  String get signOutConfirmTitle => _ar ? 'تسجيل الخروج؟' : 'Sign out?';
  String get signOutConfirmBody => _ar
      ? 'ستحتاج إلى تسجيل الدخول مرة أخرى للمتابعة.'
      : 'You will need to sign in again to continue.';

  String get account => _ar ? 'الحساب' : 'Account';
  String get roleStaff => _ar ? 'طاقم طبي' : 'Medical staff';
  String get rolePatient => _ar ? 'مري/ة' : 'Patient';
  String get roleAdmin => _ar ? 'مسؤول' : 'Administrator';

  String get specialty => _ar ? 'التخصص' : 'Specialty';
  String get jobTitle => _ar ? 'المسمى الوظيفي' : 'Job title';
  String get licenseNo => _ar ? 'رقم الترخيص' : 'License no.';
  String get department => _ar ? 'القسم' : 'Department';
  String get memberSince => _ar ? 'عضو منذ' : 'Member since';
  String get managedByAdmin => _ar
      ? 'تتم إدارة هذه التفاصيل بواسطة المسؤول.'
      : 'These details are managed by your administrator.';
  String get none => _ar ? 'لا يوجد' : '—';

  String get preferences => _ar ? 'التفضيلات' : 'Preferences';
  String get theme => _ar ? 'المظهر' : 'Theme';
  String get themeSystem => _ar ? 'النظام' : 'System';
  String get themeLight => _ar ? 'فاتح' : 'Light';
  String get themeDark => _ar ? 'داكن' : 'Dark';
  String get language => _ar ? 'اللغة' : 'Language';
  String get languageSystem => _ar ? 'لغة النظام' : 'System default';
  String get languageEnglish => 'English';
  String get languageArabic => 'العربية';
  String get translationNote => _ar
      ? 'ترجمة الواجهة بالكامل قيد التطوير؛ حالياً تدعم شاشة الملف الشخصي '
            'العربية والإنجليزية.'
      : 'Full UI translation is in progress — for now the profile screen '
            'supports English and Arabic.';
}
