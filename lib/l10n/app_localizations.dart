import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_cs.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('cs'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'BibleDay'**
  String get appTitle;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get navStudy;

  /// No description provided for @navBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get navBookmarks;

  /// No description provided for @navNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get navNotes;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @verseOfDay.
  ///
  /// In en, this message translates to:
  /// **'VERSE OF THE DAY'**
  String get verseOfDay;

  /// No description provided for @reflection.
  ///
  /// In en, this message translates to:
  /// **'REFLECTION'**
  String get reflection;

  /// No description provided for @prayer.
  ///
  /// In en, this message translates to:
  /// **'PRAYER'**
  String get prayer;

  /// No description provided for @loadingReflection.
  ///
  /// In en, this message translates to:
  /// **'Preparing reflection...'**
  String get loadingReflection;

  /// No description provided for @loadingPrayer.
  ///
  /// In en, this message translates to:
  /// **'Preparing prayer...'**
  String get loadingPrayer;

  /// No description provided for @errorLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load.'**
  String get errorLoad;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @apiKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Requires API key'**
  String get apiKeyRequired;

  /// No description provided for @apiKeyRequiredDesc.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings and enter your API key.'**
  String get apiKeyRequiredDesc;

  /// No description provided for @studyBible.
  ///
  /// In en, this message translates to:
  /// **'Bible Study'**
  String get studyBible;

  /// No description provided for @tabReading.
  ///
  /// In en, this message translates to:
  /// **'READING'**
  String get tabReading;

  /// No description provided for @tabMap.
  ///
  /// In en, this message translates to:
  /// **'MAP'**
  String get tabMap;

  /// No description provided for @tabPlan.
  ///
  /// In en, this message translates to:
  /// **'PLAN'**
  String get tabPlan;

  /// No description provided for @selectBook.
  ///
  /// In en, this message translates to:
  /// **'Select book'**
  String get selectBook;

  /// No description provided for @chapter.
  ///
  /// In en, this message translates to:
  /// **'Ch.'**
  String get chapter;

  /// No description provided for @chapterLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load chapter'**
  String get chapterLoadError;

  /// No description provided for @studyChapter.
  ///
  /// In en, this message translates to:
  /// **'CHAPTER STUDY'**
  String get studyChapter;

  /// No description provided for @studyLoading.
  ///
  /// In en, this message translates to:
  /// **'Studying chapter...'**
  String get studyLoading;

  /// No description provided for @studyLoad.
  ///
  /// In en, this message translates to:
  /// **'Load study'**
  String get studyLoad;

  /// No description provided for @studyApiRequired.
  ///
  /// In en, this message translates to:
  /// **'Study requires API key'**
  String get studyApiRequired;

  /// No description provided for @context.
  ///
  /// In en, this message translates to:
  /// **'CONTEXT'**
  String get context;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'SUMMARY'**
  String get summary;

  /// No description provided for @keyVerses.
  ///
  /// In en, this message translates to:
  /// **'KEY VERSES'**
  String get keyVerses;

  /// No description provided for @questions.
  ///
  /// In en, this message translates to:
  /// **'REFLECTION QUESTIONS'**
  String get questions;

  /// No description provided for @application.
  ///
  /// In en, this message translates to:
  /// **'PRACTICAL APPLICATION'**
  String get application;

  /// No description provided for @showAnswer.
  ///
  /// In en, this message translates to:
  /// **'Show answer'**
  String get showAnswer;

  /// No description provided for @bookmarkAdded.
  ///
  /// In en, this message translates to:
  /// **'Verse saved to bookmarks ✓'**
  String get bookmarkAdded;

  /// No description provided for @bookmarkRemoved.
  ///
  /// In en, this message translates to:
  /// **'Bookmark removed'**
  String get bookmarkRemoved;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @noBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get noBookmarks;

  /// No description provided for @noBookmarksDesc.
  ///
  /// In en, this message translates to:
  /// **'In Study, tap 🔖 next to a verse'**
  String get noBookmarksDesc;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get noNotes;

  /// No description provided for @noNotesDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first note'**
  String get noNotesDesc;

  /// No description provided for @newNote.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get newNote;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get editNote;

  /// No description provided for @noteTitle.
  ///
  /// In en, this message translates to:
  /// **'Title...'**
  String get noteTitle;

  /// No description provided for @noteText.
  ///
  /// In en, this message translates to:
  /// **'Write your note...'**
  String get noteText;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'CLAUDE API KEY'**
  String get apiKey;

  /// No description provided for @apiKeySet.
  ///
  /// In en, this message translates to:
  /// **'API key is set'**
  String get apiKeySet;

  /// No description provided for @apiKeyVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying key...'**
  String get apiKeyVerifying;

  /// No description provided for @apiKeyValid.
  ///
  /// In en, this message translates to:
  /// **'API key verified and saved ✓'**
  String get apiKeyValid;

  /// No description provided for @apiKeyInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid API key! Please check it.'**
  String get apiKeyInvalid;

  /// No description provided for @apiKeyRemoved.
  ///
  /// In en, this message translates to:
  /// **'API key removed'**
  String get apiKeyRemoved;

  /// No description provided for @getKey.
  ///
  /// In en, this message translates to:
  /// **'Get key'**
  String get getKey;

  /// No description provided for @apiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'sk-ant-...'**
  String get apiKeyHint;

  /// No description provided for @apiKeyPrice.
  ///
  /// In en, this message translates to:
  /// **'💰 \$5 credit = 4+ years of daily study\n~\$0.003 per day'**
  String get apiKeyPrice;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'FONT SIZE'**
  String get fontSize;

  /// No description provided for @fontSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get fontSmall;

  /// No description provided for @fontNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get fontNormal;

  /// No description provided for @fontLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get fontLarge;

  /// No description provided for @fontXLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get fontXLarge;

  /// No description provided for @translation.
  ///
  /// In en, this message translates to:
  /// **'BIBLE TRANSLATION'**
  String get translation;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get aboutApp;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @bibleApi.
  ///
  /// In en, this message translates to:
  /// **'Bible API'**
  String get bibleApi;

  /// No description provided for @madeBy.
  ///
  /// In en, this message translates to:
  /// **'Made by'**
  String get madeBy;

  /// No description provided for @readingPlan.
  ///
  /// In en, this message translates to:
  /// **'READING PLAN'**
  String get readingPlan;

  /// No description provided for @noPlan.
  ///
  /// In en, this message translates to:
  /// **'No reading plan'**
  String get noPlan;

  /// No description provided for @noPlanDesc.
  ///
  /// In en, this message translates to:
  /// **'Set up a reading plan and track your progress through Scripture.'**
  String get noPlanDesc;

  /// No description provided for @createPlan.
  ///
  /// In en, this message translates to:
  /// **'Create plan'**
  String get createPlan;

  /// No description provided for @wholeBible.
  ///
  /// In en, this message translates to:
  /// **'Whole Bible'**
  String get wholeBible;

  /// No description provided for @newTestament.
  ///
  /// In en, this message translates to:
  /// **'New Testament'**
  String get newTestament;

  /// No description provided for @customPlan.
  ///
  /// In en, this message translates to:
  /// **'Custom plan'**
  String get customPlan;

  /// No description provided for @chaptersPerDay.
  ///
  /// In en, this message translates to:
  /// **'Chapters per day:'**
  String get chaptersPerDay;

  /// No description provided for @startPlan.
  ///
  /// In en, this message translates to:
  /// **'Start plan'**
  String get startPlan;

  /// No description provided for @changePlan.
  ///
  /// In en, this message translates to:
  /// **'Change plan'**
  String get changePlan;

  /// No description provided for @resetPlan.
  ///
  /// In en, this message translates to:
  /// **'Reset plan'**
  String get resetPlan;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @chapters.
  ///
  /// In en, this message translates to:
  /// **'chapters total'**
  String get chapters;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'% completed'**
  String get completed;

  /// No description provided for @todayReading.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S READING'**
  String get todayReading;

  /// No description provided for @planDone.
  ///
  /// In en, this message translates to:
  /// **'Plan completed! 🎉'**
  String get planDone;

  /// No description provided for @planDoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Congratulations on finishing the entire plan!'**
  String get planDoneDesc;

  /// No description provided for @read.
  ///
  /// In en, this message translates to:
  /// **'READ'**
  String get read;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Welcome to BibleDay'**
  String get onboardingTitle1;

  /// No description provided for @onboardingSubtitle1.
  ///
  /// In en, this message translates to:
  /// **'Daily Scripture Study'**
  String get onboardingSubtitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'BibleDay brings you a verse, reflection, prayer and chapter study every day. Works without AI — but with it, it\'s a truly enriching experience.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'What awaits you'**
  String get onboardingTitle2;

  /// No description provided for @onboardingSubtitle2.
  ///
  /// In en, this message translates to:
  /// **'Four sections, one goal'**
  String get onboardingSubtitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'☀️ Today — verse of the day, reflection and prayer\n\n📚 Study — choose a chapter, AI will summarize it\n\n🔖 Bookmarks — saved verses\n\n📝 Notes — your personal notes'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Claude API Key'**
  String get onboardingTitle3;

  /// No description provided for @onboardingSubtitle3.
  ///
  /// In en, this message translates to:
  /// **'Recommended for full features'**
  String get onboardingSubtitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'BibleDay uses Claude by Anthropic — the best AI for Bible study. Get your key easily at console.anthropic.com.\n\nPrice: \$5 credit lasts over 4 years of daily study!'**
  String get onboardingBody3;

  /// No description provided for @onboardingPrice.
  ///
  /// In en, this message translates to:
  /// **'💰 Estimated cost'**
  String get onboardingPrice;

  /// No description provided for @onboardingPriceDesc.
  ///
  /// In en, this message translates to:
  /// **'\$5 credit = 4+ years of study\n~\$0.003 per day'**
  String get onboardingPriceDesc;

  /// No description provided for @getApiKey.
  ///
  /// In en, this message translates to:
  /// **'Get API key at console.anthropic.com'**
  String get getApiKey;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @startStudying.
  ///
  /// In en, this message translates to:
  /// **'Start studying'**
  String get startStudying;

  /// No description provided for @mapLocation.
  ///
  /// In en, this message translates to:
  /// **'Chapter location'**
  String get mapLocation;

  /// No description provided for @mapNoLocation.
  ///
  /// In en, this message translates to:
  /// **'Location not found'**
  String get mapNoLocation;

  /// No description provided for @mapApiRequired.
  ///
  /// In en, this message translates to:
  /// **'API key required for unknown books'**
  String get mapApiRequired;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'BACKUP'**
  String get backupTitle;

  /// No description provided for @backupExport.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get backupExport;

  /// No description provided for @backupImport.
  ///
  /// In en, this message translates to:
  /// **'How to restore a backup'**
  String get backupImport;

  /// No description provided for @backupExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup exported successfully ✓'**
  String get backupExportSuccess;

  /// No description provided for @backupExportError.
  ///
  /// In en, this message translates to:
  /// **'Error exporting backup'**
  String get backupExportError;

  /// No description provided for @backupImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup imported successfully ✓'**
  String get backupImportSuccess;

  /// No description provided for @backupImportError.
  ///
  /// In en, this message translates to:
  /// **'Error importing backup — file is not a valid BibleDay backup'**
  String get backupImportError;

  /// No description provided for @backupImportWarning.
  ///
  /// In en, this message translates to:
  /// **'Importing a backup will overwrite all existing data (notes, bookmarks, settings). Do you want to continue?'**
  String get backupImportWarning;

  /// No description provided for @supportDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Support developer'**
  String get supportDeveloper;

  /// No description provided for @planChapterDone.
  ///
  /// In en, this message translates to:
  /// **'Marked in plan ✓'**
  String get planChapterDone;

  /// No description provided for @planAutoTrackHint.
  ///
  /// In en, this message translates to:
  /// **'A chapter is automatically marked as read once you open it for study.'**
  String get planAutoTrackHint;

  /// No description provided for @currentlyReading.
  ///
  /// In en, this message translates to:
  /// **'currently reading'**
  String get currentlyReading;

  /// No description provided for @backupDesc.
  ///
  /// In en, this message translates to:
  /// **'Save your notes, bookmarks, reading plan and settings. The backup is a small JSON file you can save to Google Drive, email, or anywhere else.'**
  String get backupDesc;

  /// No description provided for @backupImportHowTo.
  ///
  /// In en, this message translates to:
  /// **'In your file manager (or wherever you saved the backup), find the file named bibleday_backup_....json and tap it.\n\nChoose \"Open with\" or \"Share\" and select BibleDay. The backup will load automatically.'**
  String get backupImportHowTo;

  /// No description provided for @autoBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic Backup'**
  String get autoBackupTitle;

  /// No description provided for @autoBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'An extra safety net — the app saves a backup in the background automatically, even if you forget to do it manually.'**
  String get autoBackupDesc;

  /// No description provided for @autoBackupFrequency.
  ///
  /// In en, this message translates to:
  /// **'FREQUENCY'**
  String get autoBackupFrequency;

  /// No description provided for @autoBackupDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get autoBackupDaily;

  /// No description provided for @autoBackupWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get autoBackupWeekly;

  /// No description provided for @autoBackupTime.
  ///
  /// In en, this message translates to:
  /// **'APPROXIMATE TIME'**
  String get autoBackupTime;

  /// No description provided for @autoBackupTimeApprox.
  ///
  /// In en, this message translates to:
  /// **'approximate'**
  String get autoBackupTimeApprox;

  /// No description provided for @autoBackupLast.
  ///
  /// In en, this message translates to:
  /// **'Last backup'**
  String get autoBackupLast;

  /// No description provided for @autoBackupNever.
  ///
  /// In en, this message translates to:
  /// **'none yet'**
  String get autoBackupNever;

  /// No description provided for @backupNever.
  ///
  /// In en, this message translates to:
  /// **'none yet'**
  String get backupNever;

  /// No description provided for @autoBackupLocation.
  ///
  /// In en, this message translates to:
  /// **'Saved to: Download/BibleDay_AutoBackup (last 3 backups)'**
  String get autoBackupLocation;

  /// No description provided for @planTodayDone.
  ///
  /// In en, this message translates to:
  /// **'Today\'s reading done! 🎉'**
  String get planTodayDone;

  /// No description provided for @planTodayDoneDesc.
  ///
  /// In en, this message translates to:
  /// **'New chapters will appear tomorrow. God bless you!'**
  String get planTodayDoneDesc;

  /// No description provided for @aiLanguage.
  ///
  /// In en, this message translates to:
  /// **'AI LANGUAGE'**
  String get aiLanguage;

  /// No description provided for @aiLanguageAuto.
  ///
  /// In en, this message translates to:
  /// **'Follow Bible translation'**
  String get aiLanguageAuto;

  /// No description provided for @aiLanguageCz.
  ///
  /// In en, this message translates to:
  /// **'Always Czech'**
  String get aiLanguageCz;

  /// No description provided for @aiLanguageEn.
  ///
  /// In en, this message translates to:
  /// **'Always English'**
  String get aiLanguageEn;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search the Bible...'**
  String get searchHint;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'results'**
  String get searchResults;

  /// No description provided for @searchEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a word or phrase\nand press Enter'**
  String get searchEmpty;

  /// No description provided for @searchScopeChapter.
  ///
  /// In en, this message translates to:
  /// **'This chapter'**
  String get searchScopeChapter;

  /// No description provided for @searchScopeBook.
  ///
  /// In en, this message translates to:
  /// **'This book'**
  String get searchScopeBook;

  /// No description provided for @searchScopeNT.
  ///
  /// In en, this message translates to:
  /// **'New Testament'**
  String get searchScopeNT;

  /// No description provided for @searchScopeAll.
  ///
  /// In en, this message translates to:
  /// **'Whole Bible'**
  String get searchScopeAll;

  /// No description provided for @searchSlowWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Searching multiple chapters may take a while'**
  String get searchSlowWarning;

  /// No description provided for @bookmarkAddedToGroup.
  ///
  /// In en, this message translates to:
  /// **'Verse added to bookmark group ✓'**
  String get bookmarkAddedToGroup;

  /// No description provided for @verseCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy verse'**
  String get verseCopy;

  /// No description provided for @verseCopied.
  ///
  /// In en, this message translates to:
  /// **'Verse copied ✓'**
  String get verseCopied;

  /// No description provided for @planLoadNext.
  ///
  /// In en, this message translates to:
  /// **'Load next chapters'**
  String get planLoadNext;

  /// No description provided for @planRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh today\'s chapters'**
  String get planRefresh;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notificationTitle;

  /// No description provided for @notificationVerseDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily verse'**
  String get notificationVerseDaily;

  /// No description provided for @notificationDesc.
  ///
  /// In en, this message translates to:
  /// **'⚠️ This feature is currently being tested and will be available in the next update.'**
  String get notificationDesc;

  /// No description provided for @notificationTime.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATION TIME'**
  String get notificationTime;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission was denied'**
  String get notificationPermissionDenied;

  /// No description provided for @cspAttribution.
  ///
  /// In en, this message translates to:
  /// **'BIBLE TRANSLATION'**
  String get cspAttribution;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @notificationPermissionExplain.
  ///
  /// In en, this message translates to:
  /// **'BibleDay will send you a daily Bible verse. Tap the notification to open the app.\n\nNotification permission is required to enable this.'**
  String get notificationPermissionExplain;

  /// No description provided for @notificationPermissionDeniedSettings.
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Enable notifications in Phone Settings → Apps → BibleDay.'**
  String get notificationPermissionDeniedSettings;

  /// No description provided for @planReadNext.
  ///
  /// In en, this message translates to:
  /// **'NEXT CHAPTER IN PLAN'**
  String get planReadNext;

  /// No description provided for @apiKeyGuide.
  ///
  /// In en, this message translates to:
  /// **'How to get an API key?'**
  String get apiKeyGuide;

  /// No description provided for @apiKeyGuideIntro.
  ///
  /// In en, this message translates to:
  /// **'The API key connects BibleDay to Claude AI. You can get it for free on the Anthropic website.'**
  String get apiKeyGuideIntro;

  /// No description provided for @apiKeyStep1.
  ///
  /// In en, this message translates to:
  /// **'Open console.anthropic.com (button below)'**
  String get apiKeyStep1;

  /// No description provided for @apiKeyStep2.
  ///
  /// In en, this message translates to:
  /// **'Sign up using your email or Google account.'**
  String get apiKeyStep2;

  /// No description provided for @apiKeyStep3.
  ///
  /// In en, this message translates to:
  /// **'Select a credit amount (\$5). Fill in your name and address, then your payment card details. Click \"Buy Credits\".'**
  String get apiKeyStep3;

  /// No description provided for @apiKeyStep4.
  ///
  /// In en, this message translates to:
  /// **'On the next page, skip automatic reloading by clicking \"Skip for now\".'**
  String get apiKeyStep4;

  /// No description provided for @apiKeyStep5.
  ///
  /// In en, this message translates to:
  /// **'In the top right corner, click \"Get API Key\".'**
  String get apiKeyStep5;

  /// No description provided for @apiKeyGuideTip.
  ///
  /// In en, this message translates to:
  /// **'💡 Tip: Add \$5 credit to start — it lasts over 4 years of daily study!'**
  String get apiKeyGuideTip;

  /// No description provided for @apiKeyOpenConsole.
  ///
  /// In en, this message translates to:
  /// **'Open Anthropic'**
  String get apiKeyOpenConsole;

  /// No description provided for @shareVerse.
  ///
  /// In en, this message translates to:
  /// **'Share verse'**
  String get shareVerse;

  /// No description provided for @shareWithReflection.
  ///
  /// In en, this message translates to:
  /// **'Share with reflection'**
  String get shareWithReflection;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'APP THEME'**
  String get themeTitle;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get themeLight;

  /// No description provided for @tabAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get tabAssistant;

  /// No description provided for @assistantWelcome.
  ///
  /// In en, this message translates to:
  /// **'How can I help you?'**
  String get assistantWelcome;

  /// No description provided for @assistantDesc.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything about the Bible, faith or Christian life.'**
  String get assistantDesc;

  /// No description provided for @assistantExample1.
  ///
  /// In en, this message translates to:
  /// **'What does John 3:16 mean?'**
  String get assistantExample1;

  /// No description provided for @assistantExample2.
  ///
  /// In en, this message translates to:
  /// **'Who was the apostle Paul?'**
  String get assistantExample2;

  /// No description provided for @assistantExample3.
  ///
  /// In en, this message translates to:
  /// **'How to pray?'**
  String get assistantExample3;

  /// No description provided for @assistantHint.
  ///
  /// In en, this message translates to:
  /// **'Type your question...'**
  String get assistantHint;

  /// No description provided for @ttsInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Bible Reading'**
  String get ttsInfoTitle;

  /// No description provided for @ttsInfoDesc.
  ///
  /// In en, this message translates to:
  /// **'Voice quality depends on the TTS engine on your phone.'**
  String get ttsInfoDesc;

  /// No description provided for @apiKeyStep6.
  ///
  /// In en, this message translates to:
  /// **'Click \"Create Key\", name it BibleDay and copy the key starting with \"sk-ant-...\".'**
  String get apiKeyStep6;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['cs', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'cs': return AppLocalizationsCs();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
