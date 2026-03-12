import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
  <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('uz'),
  ];

  /// EduAnalytics
  String get appName;

  /// Kirish
  String get login;

  /// Chiqish
  String get logout;

  /// Email
  String get email;

  /// Parol
  String get password;

  /// Tizimga kirish
  String get loginButton;

  /// Xush kelibsiz!
  String get loginWelcome;

  /// Tizimga kirish uchun ma'lumotlaringizni kiriting
  String get loginSubtitle;

  /// Bosh sahifa
  String get dashboard;

  /// Kurslar
  String get courses;

  /// Guruhlar
  String get groups;

  /// O'quvchilar
  String get students;

  /// Statistika
  String get statistics;

  /// Sozlamalar
  String get settings;

  /// Prognoz
  String get prediction;

  /// Jami Kurslar
  String get totalCourses;

  /// Jami Guruhlar
  String get totalGroups;

  /// Jami O'quvchilar
  String get totalStudents;

  /// Xavf ostida
  String get atRiskStudents;

  /// O'rtacha Ball
  String get averageScore;

  /// Kurs qo'shish
  String get addCourse;

  /// Guruh qo'shish
  String get addGroup;

  /// O'quvchi qo'shish
  String get addStudent;

  /// O'chirish
  String get delete;

  /// Tahrirlash
  String get edit;

  /// Saqlash
  String get save;

  /// Bekor
  String get cancel;

  /// Tasdiqlash
  String get confirm;

  /// Kurs nomi
  String get courseName;

  /// Guruh nomi
  String get groupName;

  /// Ism familiya
  String get studentName;

  /// Davomat
  String get attendance;

  /// Uy vazifasi
  String get homework;

  /// Quiz
  String get quiz;

  /// Imtihon
  String get exam;

  /// Umumiy ball
  String get overallScore;

  /// Prognoz qilish
  String get predictButton;

  /// Prognoz qilinmoqda...
  String get predicting;

  /// Prognoz natijasi
  String get predictionResult;

  /// Yuqori daraja
  String get highPerformance;

  /// O'rta daraja
  String get mediumPerformance;

  /// Past daraja
  String get lowPerformance;

  /// Xavf foizi
  String get riskPercentage;

  /// Prognoz ball
  String get predictedScore;

  /// Tavsiya
  String get recommendation;

  /// Yorug' rejim
  String get lightMode;

  /// Qorong'u rejim
  String get darkMode;

  /// Til
  String get language;

  /// O'zbek
  String get uzbek;

  /// Ingliz
  String get english;

  /// Mavzu
  String get theme;

  /// Ko'rinish
  String get appearance;

  /// Profil
  String get profile;

  /// Ma'lumot topilmadi
  String get noData;

  /// Yuklanmoqda...
  String get loading;

  /// Xatolik yuz berdi
  String get error;

  /// Qayta urinish
  String get retry;

  /// Qidirish...
  String get search;

  /// Filtrlash
  String get filter;

  /// Ko'rsatkich
  String get performance;

  /// O'quvchilar ko'rsatkichi
  String get studentPerformance;

  /// Kurs ko'rsatkichi
  String get coursePerformance;

  /// Guruh statistikasi
  String get groupStatistics;

  /// Xavf taqsimoti
  String get riskDistribution;

  /// Haqiqatan ham o'chirmoqchimisiz?
  String get deleteConfirm;

  /// Tavsif
  String get description;

  /// Fan
  String get subject;

  /// %s ball
  String get score;

  /// Barchasi
  String get all;

  /// O'qituvchi
  String get teacher;

  /// Ilova haqida
  String get aboutApp;

  /// Versiya
  String get version;

  /// Hisob
  String get account;

  /// Ilova mavzusini o'zgartiring
  String get themeSubtitle;

  /// Xush kelibsiz,
  String get greetingPrefix;

  /// O'quvchilaringiz natijalarini kuzating
  String get greetingSubtitle;

  /// Xavf ostidagi o'quvchilar
  String get atRiskTitle;

  /// Kurslar ko'rsatkichi
  String get coursePerformanceTitle;

  /// Barchasini ko'rish
  String get viewAll;

  /// Xavf ostida
  String get riskLabel;

  /// o'rtacha
  String get avgLabel;

  /// o'quvchi
  String get studentsCount;

  /// Yangi kurs qo'shish
  String get newCourse;

  /// Yangi guruh qo'shish
  String get newGroup;

  /// Yangi o'quvchi qo'shish
  String get newStudent;

  /// Kursni tahrirlash
  String get editCourse;

  /// Guruhni tahrirlash
  String get editGroup;

  /// O'quvchini tahrirlash
  String get editStudent;

  /// Kurs tanlang
  String get selectCourse;

  /// Guruh tanlang
  String get selectGroup;

  /// Avval kurs tanlang
  String get selectCourseFirst;

  /// Email (ixtiyoriy)
  String get emailOptional;

  /// guruhini o'chirasizmi? Ichidagi o'quvchilar ham o'chadi.
  String get deleteGroupConfirm;

  /// ni o'chirasizmi?
  String get deleteStudentConfirm;

  /// O'chirishni tasdiqlang
  String get deleteConfirmTitle;

  /// Tizimdan chiqishni xohlaysizmi?
  String get logoutConfirm;

  /// Chiqish
  String get logoutTitle;

  /// Xavf
  String get atRiskBadge;

  /// umumiy ball
  String get overallBrief;

  /// O'quvchi qidirish...
  String get searchStudent;

  /// Kurs qidirish...
  String get searchCourse;

  /// topilmadi
  String get notFound;

  /// Ommaviy prognoz
  String get batchPrediction;

  /// Barcha o'quvchilarni tekshirish
  String get runBatch;

  /// Prognoz tarixi
  String get predictionHistory;

  /// Hali prognoz yo'q
  String get noHistory;

  /// xavf
  String get riskLabel2;

  /// O'quvchi ma'lumotlari
  String get detailTitle;

  /// Ballar
  String get scores;

  /// ML Prognoz
  String get predict;

  /// Ro'yxatga olingan
  String get enrolledAt;

  /// Guruh
  String get group;

  /// Kurs
  String get course;

  /// Mavzuni o'zgartirish
  String get changeTheme;

  /// Tilni o'zgartirish
  String get changeLanguage;

  /// Masalan: A-guruh
  String get groupNameHint;

  /// Guruhlar topilmadi
  String get groupNotFound;

  /// O'quvchilar topilmadi
  String get studentNotFound;

  /// Qo'shish
  String get add;

  /// Avval guruh tanlang
  String get selectGroupFirst;

  /// Ism, kurs va guruhni tanlang!
  String get requiredFields;

}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'uz':
      return AppLocalizationsUz();
  }
  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale".');
}