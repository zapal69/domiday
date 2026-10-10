import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @leaveWithoutSaving.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving?'**
  String get leaveWithoutSaving;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Changes in this form will not be saved.'**
  String get unsavedChanges;

  /// No description provided for @localOnlyNoBackup.
  ///
  /// In en, this message translates to:
  /// **'On this device only. Backup is in Settings.'**
  String get localOnlyNoBackup;

  /// No description provided for @aboutTooltip.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTooltip;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @journalTooltip.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journalTooltip;

  /// No description provided for @daysCompact.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} day} other{{count} days}}'**
  String daysCompact(int count);

  /// No description provided for @daysFull.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} day} other{{count} days}}'**
  String daysFull(int count);

  /// No description provided for @recordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} record} other{{count} records}}'**
  String recordsCount(int count);

  /// No description provided for @tripsCount.
  ///
  /// In en, this message translates to:
  /// **'Trips: {count}'**
  String tripsCount(int count);

  /// No description provided for @countriesCount.
  ///
  /// In en, this message translates to:
  /// **'Countries: {count}'**
  String countriesCount(int count);

  /// No description provided for @loadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not open the journal'**
  String get loadFailedTitle;

  /// No description provided for @loadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'The file is unavailable, damaged or was created by another version of the app. We did not replace it with an empty journal. Changes are disabled. Do not uninstall the app or clear its data.'**
  String get loadFailedBody;

  /// No description provided for @retryOpen.
  ///
  /// In en, this message translates to:
  /// **'Try opening again'**
  String get retryOpen;

  /// No description provided for @todayLine.
  ///
  /// In en, this message translates to:
  /// **'Today · {date}'**
  String todayLine(String date);

  /// No description provided for @yearSummaryButton.
  ///
  /// In en, this message translates to:
  /// **'{year} summary'**
  String yearSummaryButton(int year);

  /// No description provided for @periodLine.
  ///
  /// In en, this message translates to:
  /// **'{from} — {to} · {days}'**
  String periodLine(String from, String to, String days);

  /// No description provided for @methodologyLine.
  ///
  /// In en, this message translates to:
  /// **'Unknown does not mean home. A moving day counts in both countries, and once among known days.'**
  String get methodologyLine;

  /// No description provided for @byCountry.
  ///
  /// In en, this message translates to:
  /// **'By country'**
  String get byCountry;

  /// No description provided for @shareOfKnownDays.
  ///
  /// In en, this message translates to:
  /// **'share of known days'**
  String get shareOfKnownDays;

  /// No description provided for @noCountryData.
  ///
  /// In en, this message translates to:
  /// **'No dates to count yet. Unknown days belong to no country.'**
  String get noCountryData;

  /// No description provided for @recentTrips.
  ///
  /// In en, this message translates to:
  /// **'Recent trips'**
  String get recentTrips;

  /// No description provided for @noCompletedTrips.
  ///
  /// In en, this message translates to:
  /// **'No completed trips with dates yet. Add them in the journal.'**
  String get noCompletedTrips;

  /// No description provided for @allJournalAndArchive.
  ///
  /// In en, this message translates to:
  /// **'Full journal and archive'**
  String get allJournalAndArchive;

  /// No description provided for @homeCountry.
  ///
  /// In en, this message translates to:
  /// **'Home country'**
  String get homeCountry;

  /// No description provided for @countryShareSemantics.
  ///
  /// In en, this message translates to:
  /// **'{country}: {days} days, {percent} % of known'**
  String countryShareSemantics(String country, int days, int percent);

  /// No description provided for @nowStayEyebrow.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get nowStayEyebrow;

  /// No description provided for @arrivalUnknown.
  ///
  /// In en, this message translates to:
  /// **'Arrival date unknown'**
  String get arrivalUnknown;

  /// No description provided for @noDateNoDays.
  ///
  /// In en, this message translates to:
  /// **'Without a date this stay adds no days to the totals.'**
  String get noDateNoDays;

  /// No description provided for @sinceArrivalLine.
  ///
  /// In en, this message translates to:
  /// **'Since {date}, including the arrival day and today.'**
  String sinceArrivalLine(String date);

  /// No description provided for @changeCountry.
  ///
  /// In en, this message translates to:
  /// **'Change country'**
  String get changeCountry;

  /// No description provided for @arrivalDate.
  ///
  /// In en, this message translates to:
  /// **'Arrival date'**
  String get arrivalDate;

  /// No description provided for @dateShort.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateShort;

  /// No description provided for @tileKnown.
  ///
  /// In en, this message translates to:
  /// **'Known'**
  String get tileKnown;

  /// No description provided for @tileKnownSub.
  ///
  /// In en, this message translates to:
  /// **'of {total} in the period'**
  String tileKnownSub(int total);

  /// No description provided for @tileHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tileHome;

  /// No description provided for @tileAway.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get tileAway;

  /// No description provided for @tileAwaySub.
  ///
  /// In en, this message translates to:
  /// **'overlapping with home: {count}'**
  String tileAwaySub(int count);

  /// No description provided for @tileUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get tileUnknown;

  /// No description provided for @checkGaps.
  ///
  /// In en, this message translates to:
  /// **'Check gaps'**
  String get checkGaps;

  /// No description provided for @daysUnit.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysUnit;

  /// No description provided for @monthsShort.
  ///
  /// In en, this message translates to:
  /// **'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec'**
  String get monthsShort;

  /// No description provided for @calendarSemantics.
  ///
  /// In en, this message translates to:
  /// **'{year} calendar: home {home} days, away {away} days, unknown {unknown} days'**
  String calendarSemantics(int year, int home, int away, int unknown);

  /// No description provided for @legendHome.
  ///
  /// In en, this message translates to:
  /// **'home'**
  String get legendHome;

  /// No description provided for @legendAway.
  ///
  /// In en, this message translates to:
  /// **'away'**
  String get legendAway;

  /// No description provided for @legendUnknown.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get legendUnknown;

  /// No description provided for @legendBoth.
  ///
  /// In en, this message translates to:
  /// **'day in two countries'**
  String get legendBoth;

  /// No description provided for @legendTransit.
  ///
  /// In en, this message translates to:
  /// **'transit'**
  String get legendTransit;

  /// No description provided for @legendOther.
  ///
  /// In en, this message translates to:
  /// **'other countries'**
  String get legendOther;

  /// No description provided for @legendFuture.
  ///
  /// In en, this message translates to:
  /// **'not yet'**
  String get legendFuture;

  /// No description provided for @calendarMonthHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a month to expand it; tap a day for its card.'**
  String get calendarMonthHint;

  /// No description provided for @calendarCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get calendarCollapse;

  /// No description provided for @monthsFull.
  ///
  /// In en, this message translates to:
  /// **'January,February,March,April,May,June,July,August,September,October,November,December'**
  String get monthsFull;

  /// No description provided for @weekdaysShort.
  ///
  /// In en, this message translates to:
  /// **'Mo,Tu,We,Th,Fr,Sa,Su'**
  String get weekdaysShort;

  /// No description provided for @kindStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get kindStay;

  /// No description provided for @kindTransit.
  ///
  /// In en, this message translates to:
  /// **'Transit'**
  String get kindTransit;

  /// No description provided for @kindTransitHint.
  ///
  /// In en, this message translates to:
  /// **'A layover or a pass-through: the days count as known and for that country, and are marked separately.'**
  String get kindTransitHint;

  /// No description provided for @transitsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} transit} other{{count} transits}}'**
  String transitsCount(int count);

  /// No description provided for @transitCalendarSemantics.
  ///
  /// In en, this message translates to:
  /// **'transit on {count} days'**
  String transitCalendarSemantics(int count);

  /// No description provided for @dayCardEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data for this day'**
  String get dayCardEmpty;

  /// No description provided for @dayCardCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current stay'**
  String get dayCardCurrent;

  /// No description provided for @dayCardHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a record to open it. Viewing changes nothing.'**
  String get dayCardHint;

  /// No description provided for @dayCardSemantics.
  ///
  /// In en, this message translates to:
  /// **'Day {date}: {count} records'**
  String dayCardSemantics(String date, int count);

  /// No description provided for @transitToday.
  ///
  /// In en, this message translates to:
  /// **'Transit today: {country}'**
  String transitToday(String country);

  /// No description provided for @wholeTransit.
  ///
  /// In en, this message translates to:
  /// **'{days} · Transit'**
  String wholeTransit(String days);

  /// No description provided for @newTransit.
  ///
  /// In en, this message translates to:
  /// **'New transit'**
  String get newTransit;

  /// No description provided for @yourTransit.
  ///
  /// In en, this message translates to:
  /// **'Your transit'**
  String get yourTransit;

  /// No description provided for @transitFormIntro.
  ///
  /// In en, this message translates to:
  /// **'Record a layover or a pass-through. One date or a range if it crossed midnight. City or airport is optional; time is not recorded.'**
  String get transitFormIntro;

  /// No description provided for @detectNow.
  ///
  /// In en, this message translates to:
  /// **'Detect my country now'**
  String get detectNow;

  /// No description provided for @detectBusy.
  ///
  /// In en, this message translates to:
  /// **'Detecting…'**
  String get detectBusy;

  /// No description provided for @detectSame.
  ///
  /// In en, this message translates to:
  /// **'You are still in {country}. Nothing changed.'**
  String detectSame(String country);

  /// No description provided for @detectNone.
  ///
  /// In en, this message translates to:
  /// **'Could not determine the country from the coordinates (sea or an area outside the map). The journal is unchanged.'**
  String get detectNone;

  /// No description provided for @detectDenied.
  ///
  /// In en, this message translates to:
  /// **'No permission for approximate location. Allow it in Android settings or keep the journal by hand.'**
  String get detectDenied;

  /// No description provided for @detectServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off on the phone. Turn it on or keep the journal by hand.'**
  String get detectServiceOff;

  /// No description provided for @detectFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not get coordinates (no signal or timed out). Try later; the journal is unchanged.'**
  String get detectFailed;

  /// No description provided for @detectSilenced.
  ///
  /// In en, this message translates to:
  /// **'This detection was dismissed earlier. It will be offered again after {days} days or when the country changes.'**
  String detectSilenced(int days);

  /// No description provided for @candidateTitle.
  ///
  /// In en, this message translates to:
  /// **'It looks like you are in {country}'**
  String candidateTitle(String country);

  /// No description provided for @candidateUncertain.
  ///
  /// In en, this message translates to:
  /// **'A border or coast is nearby: it could also be {alternatives}. Check by yourself.'**
  String candidateUncertain(String alternatives);

  /// No description provided for @candidateUncertainNoAlt.
  ///
  /// In en, this message translates to:
  /// **'The point is outside the map borders (coast or sea); the nearest country is shown. Check by yourself.'**
  String get candidateUncertainNoAlt;

  /// No description provided for @candidateDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected {date}, accuracy about {km} km. This is not the arrival date.'**
  String candidateDetected(String date, String km);

  /// No description provided for @candidateNoRecord.
  ///
  /// In en, this message translates to:
  /// **'Until you confirm, the current country, the calendar and the totals stay as they are. The arrival date is chosen on the next screen; by default it is the detection day.'**
  String get candidateNoRecord;

  /// No description provided for @candidateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm move'**
  String get candidateConfirm;

  /// No description provided for @candidateCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct the country'**
  String get candidateCorrect;

  /// No description provided for @candidateTransit.
  ///
  /// In en, this message translates to:
  /// **'It was transit'**
  String get candidateTransit;

  /// No description provided for @candidateDismiss.
  ///
  /// In en, this message translates to:
  /// **'This is wrong'**
  String get candidateDismiss;

  /// No description provided for @candidateDismissed.
  ///
  /// In en, this message translates to:
  /// **'Detection dismissed. The journal is unchanged; the same country will not be offered again for {days} days.'**
  String candidateDismissed(int days);

  /// No description provided for @candidateBanner.
  ///
  /// In en, this message translates to:
  /// **'It looks like you are in {country}'**
  String candidateBanner(String country);

  /// No description provided for @candidateHint.
  ///
  /// In en, this message translates to:
  /// **'From an approximate position. Only a suggestion for now.'**
  String get candidateHint;

  /// No description provided for @candidateYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get candidateYes;

  /// No description provided for @candidateNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get candidateNo;

  /// No description provided for @detectHint.
  ///
  /// In en, this message translates to:
  /// **'The app can suggest where you are from an approximate position.'**
  String get detectHint;

  /// No description provided for @detectShort.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get detectShort;

  /// No description provided for @journalNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get journalNow;

  /// No description provided for @candidateReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get candidateReview;

  /// No description provided for @detectTitle.
  ///
  /// In en, this message translates to:
  /// **'Country detection'**
  String get detectTitle;

  /// No description provided for @autoStatus.
  ///
  /// In en, this message translates to:
  /// **'Auto-check {time} · {result}'**
  String autoStatus(String time, String result);

  /// No description provided for @autoStatusSame.
  ///
  /// In en, this message translates to:
  /// **'country matches'**
  String get autoStatusSame;

  /// No description provided for @autoStatusPending.
  ///
  /// In en, this message translates to:
  /// **'there is a suggestion'**
  String get autoStatusPending;

  /// No description provided for @autoStatusDenied.
  ///
  /// In en, this message translates to:
  /// **'no location permission'**
  String get autoStatusDenied;

  /// No description provided for @autoStatusOff.
  ///
  /// In en, this message translates to:
  /// **'location is off'**
  String get autoStatusOff;

  /// No description provided for @autoStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'no coordinates'**
  String get autoStatusFailed;

  /// No description provided for @autoStatusNone.
  ///
  /// In en, this message translates to:
  /// **'country not determined'**
  String get autoStatusNone;

  /// No description provided for @autoStatusSilenced.
  ///
  /// In en, this message translates to:
  /// **'dismissed earlier'**
  String get autoStatusSilenced;

  /// No description provided for @seriesLine.
  ///
  /// In en, this message translates to:
  /// **'Since {date}, counting back through your records without a break.'**
  String seriesLine(String date);

  /// No description provided for @aboutDetectTitle.
  ///
  /// In en, this message translates to:
  /// **'Country detection'**
  String get aboutDetectTitle;

  /// No description provided for @aboutDetectBody.
  ///
  /// In en, this message translates to:
  /// **'On your tap, when the app opens and, only if you switched on “Check in the background”, in a background task, the app asks Android once for an approximate location and matches it against country borders stored inside the app (Natural Earth, public domain). Disputed territories are assigned to no country: on the map and in detection both sides are offered for you to choose; this is not the author’s position. Coordinates stay in memory only, are never saved and never sent anywhere; the app has no network access. Detection is only a suggestion: nothing changes until you confirm, correct or mark transit.'**
  String get aboutDetectBody;

  /// No description provided for @titleOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Let’s start with you'**
  String get titleOnboarding;

  /// No description provided for @titleSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get titleSettings;

  /// No description provided for @titleArrivalDate.
  ///
  /// In en, this message translates to:
  /// **'Arrival date'**
  String get titleArrivalDate;

  /// No description provided for @titleChangeCountry.
  ///
  /// In en, this message translates to:
  /// **'Change of country'**
  String get titleChangeCountry;

  /// No description provided for @titleIncompleteRecord.
  ///
  /// In en, this message translates to:
  /// **'Incomplete record'**
  String get titleIncompleteRecord;

  /// No description provided for @pickerMoveDate.
  ///
  /// In en, this message translates to:
  /// **'Moving date'**
  String get pickerMoveDate;

  /// No description provided for @archiveArrivalNote.
  ///
  /// In en, this message translates to:
  /// **'Arrival date set manually for an incomplete record.'**
  String get archiveArrivalNote;

  /// No description provided for @confirmMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm the move?'**
  String get confirmMoveTitle;

  /// No description provided for @endsLine.
  ///
  /// In en, this message translates to:
  /// **'Ends: {country}'**
  String endsLine(String country);

  /// No description provided for @arrivalUnknownShort.
  ///
  /// In en, this message translates to:
  /// **'Arrival unknown'**
  String get arrivalUnknownShort;

  /// No description provided for @startsLine.
  ///
  /// In en, this message translates to:
  /// **'Starts: {country}'**
  String startsLine(String country);

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From {date}'**
  String fromDate(String date);

  /// No description provided for @archiveStaysNote.
  ///
  /// In en, this message translates to:
  /// **'The previous stay will remain in the archive without counted days.'**
  String get archiveStaysNote;

  /// No description provided for @moveDayBothNote.
  ///
  /// In en, this message translates to:
  /// **'The moving day is included in both stays. Other records do not change.'**
  String get moveDayBothNote;

  /// No description provided for @confirmMove.
  ///
  /// In en, this message translates to:
  /// **'Confirm move'**
  String get confirmMove;

  /// No description provided for @saveFailedFormKept.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Your form data is kept and the journal is unchanged. Check free space and try saving again.'**
  String get saveFailedFormKept;

  /// No description provided for @deleteIncompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete the incomplete record?'**
  String get deleteIncompleteTitle;

  /// No description provided for @deleteIncompleteBody.
  ///
  /// In en, this message translates to:
  /// **'{country}. This record cannot be restored.'**
  String deleteIncompleteBody(String country);

  /// No description provided for @anyCountryNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Any country name'**
  String get anyCountryNameHelper;

  /// No description provided for @countryRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a country'**
  String get countryRequired;

  /// No description provided for @countryResolved.
  ///
  /// In en, this message translates to:
  /// **'{name} · {code}'**
  String countryResolved(String name, String code);

  /// No description provided for @countryNoCode.
  ///
  /// In en, this message translates to:
  /// **'Not in the country list: saved as entered text'**
  String get countryNoCode;

  /// No description provided for @onboardingHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your journal. Yours only.'**
  String get onboardingHeadline;

  /// No description provided for @onboardingIntro.
  ///
  /// In en, this message translates to:
  /// **'No account, e-mail or tracking. Enter your home and current countries. If you don’t remember the arrival date, leave it empty.'**
  String get onboardingIntro;

  /// No description provided for @previousTripsKept.
  ///
  /// In en, this message translates to:
  /// **'Your previous trips are kept: {count}.'**
  String previousTripsKept(int count);

  /// No description provided for @homeCountryHelper.
  ///
  /// In en, this message translates to:
  /// **'A personal reference point, not tax residency. Changing this setting does not rewrite history.'**
  String get homeCountryHelper;

  /// No description provided for @newCountry.
  ///
  /// In en, this message translates to:
  /// **'New country'**
  String get newCountry;

  /// No description provided for @recordCountry.
  ///
  /// In en, this message translates to:
  /// **'Record country'**
  String get recordCountry;

  /// No description provided for @currentCountry.
  ///
  /// In en, this message translates to:
  /// **'Current country'**
  String get currentCountry;

  /// No description provided for @notBeforeNote.
  ///
  /// In en, this message translates to:
  /// **'After a confirmed move the date cannot be earlier than {date}.'**
  String notBeforeNote(String date);

  /// No description provided for @archiveDepartureNote.
  ///
  /// In en, this message translates to:
  /// **'Departure: {date}. While the arrival is unknown, this record is not counted. The year filter cannot determine its start.'**
  String archiveDepartureNote(String date);

  /// No description provided for @moveLabel.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get moveLabel;

  /// No description provided for @arrivalLabel.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get arrivalLabel;

  /// No description provided for @dateUnknown.
  ///
  /// In en, this message translates to:
  /// **'date unknown'**
  String get dateUnknown;

  /// No description provided for @dontRememberDate.
  ///
  /// In en, this message translates to:
  /// **'I don’t remember'**
  String get dontRememberDate;

  /// No description provided for @changeHint.
  ///
  /// In en, this message translates to:
  /// **'The previous stay ends on the moving day. Before saving we will show both records for confirmation.'**
  String get changeHint;

  /// No description provided for @unknownDateHint.
  ///
  /// In en, this message translates to:
  /// **'An unknown date is not replaced with today or 1 January. Without it, the duration and days of this stay are not counted.'**
  String get unknownDateHint;

  /// No description provided for @checkMove.
  ///
  /// In en, this message translates to:
  /// **'Review move'**
  String get checkMove;

  /// No description provided for @openDashboard.
  ///
  /// In en, this message translates to:
  /// **'Open my dashboard'**
  String get openDashboard;

  /// No description provided for @deleteIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Delete incomplete record'**
  String get deleteIncomplete;

  /// No description provided for @noBackupWarning.
  ///
  /// In en, this message translates to:
  /// **'Uninstalling the app or clearing its data will lose your records — keep a backup.'**
  String get noBackupWarning;

  /// No description provided for @openOldJournal.
  ///
  /// In en, this message translates to:
  /// **'Open previous journal'**
  String get openOldJournal;

  /// No description provided for @archiveCardLine.
  ///
  /// In en, this message translates to:
  /// **'Arrival unknown · departure {date}'**
  String archiveCardLine(String date);

  /// No description provided for @archiveCardNote.
  ///
  /// In en, this message translates to:
  /// **'Archive without counted days. The start is unknown, so the record is shown regardless of the year filter.'**
  String get archiveCardNote;

  /// No description provided for @clarifyOrDelete.
  ///
  /// In en, this message translates to:
  /// **'Clarify or delete'**
  String get clarifyOrDelete;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageHelper.
  ///
  /// In en, this message translates to:
  /// **'Applies immediately. Records and dates in the journal do not change.'**
  String get languageHelper;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @autoDetectTitle.
  ///
  /// In en, this message translates to:
  /// **'Check the country on opening'**
  String get autoDetectTitle;

  /// No description provided for @autoDetectHelper.
  ///
  /// In en, this message translates to:
  /// **'When the app opens, it makes the same single approximate detection as the button — at most once an hour, only if permission is already granted, and without dialogs. A different country appears as a suggestion; nothing is recorded.'**
  String get autoDetectHelper;

  /// No description provided for @importSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Maps history'**
  String get importSectionTitle;

  /// No description provided for @importHelper.
  ///
  /// In en, this message translates to:
  /// **'Phone Settings → Location → Timeline → Export Timeline data (or the same from Timeline in Google Maps). Open the resulting JSON file here: countries are matched offline against borders, coordinates are not stored and the file is not copied. Nothing is recorded without review and confirmation.'**
  String get importHelper;

  /// No description provided for @importPick.
  ///
  /// In en, this message translates to:
  /// **'Import a Timeline file…'**
  String get importPick;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from Google Maps'**
  String get importTitle;

  /// No description provided for @importAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Reading the file…'**
  String get importAnalyzing;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'This is not a Google Maps Timeline file. You need the JSON file exported from Timeline — see the steps on the previous screen.'**
  String get importFailed;

  /// No description provided for @importNothing.
  ///
  /// In en, this message translates to:
  /// **'No dated points inside countries were found in the file. Is it really a Google Maps Timeline export?'**
  String get importNothing;

  /// No description provided for @importSummary.
  ///
  /// In en, this message translates to:
  /// **'{points} points, {days} days with data, {first} — {last}. Days without data stay unknown.'**
  String importSummary(int points, int days, String first, String last);

  /// No description provided for @importHomeHelper.
  ///
  /// In en, this message translates to:
  /// **'Prefilled with the most frequent country in the history — please check.'**
  String get importHomeHelper;

  /// No description provided for @importCurrentHelper.
  ///
  /// In en, this message translates to:
  /// **'The country you are in now; prefilled from the last period.'**
  String get importCurrentHelper;

  /// No description provided for @importTransit.
  ///
  /// In en, this message translates to:
  /// **'transit'**
  String get importTransit;

  /// No description provided for @importGap.
  ///
  /// In en, this message translates to:
  /// **'no data inside: {days}'**
  String importGap(String days);

  /// No description provided for @importStatusExists.
  ///
  /// In en, this message translates to:
  /// **'already in the journal'**
  String get importStatusExists;

  /// No description provided for @importStatusConflict.
  ///
  /// In en, this message translates to:
  /// **'overlaps a record: {country} — adding will trim it'**
  String importStatusConflict(String country);

  /// No description provided for @importStatusCurrent.
  ///
  /// In en, this message translates to:
  /// **'becomes the current stay'**
  String get importStatusCurrent;

  /// No description provided for @importApply.
  ///
  /// In en, this message translates to:
  /// **'Add: {records}'**
  String importApply(String records);

  /// No description provided for @importConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to the journal?'**
  String get importConfirmTitle;

  /// No description provided for @importConfirmText.
  ///
  /// In en, this message translates to:
  /// **'To be added: {records}. Existing records are not changed.'**
  String importConfirmText(String records);

  /// No description provided for @importConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get importConfirmAction;

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'Added: {records}'**
  String importDone(String records);

  /// No description provided for @importInvalid.
  ///
  /// In en, this message translates to:
  /// **'The records did not pass validation. Check the home and current country.'**
  String get importInvalid;

  /// No description provided for @importFootnote.
  ///
  /// In en, this message translates to:
  /// **'Borders are approximate (1:50 m scale): right at a border the country may be wrong. Records can be edited in the journal.'**
  String get importFootnote;

  /// No description provided for @onboardingHaveHistory.
  ///
  /// In en, this message translates to:
  /// **'Already have a history?'**
  String get onboardingHaveHistory;

  /// No description provided for @onboardingRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore a Domiday backup'**
  String get onboardingRestore;

  /// No description provided for @onboardingImport.
  ///
  /// In en, this message translates to:
  /// **'Import from Google Maps'**
  String get onboardingImport;

  /// No description provided for @onboardingFresh.
  ///
  /// In en, this message translates to:
  /// **'Or start from scratch:'**
  String get onboardingFresh;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupTitle;

  /// No description provided for @backupHelper.
  ///
  /// In en, this message translates to:
  /// **'A file with your whole history in the app’s format. Save it to Google Drive or Files, or send it to yourself — no copy is kept on the phone. Restoring replaces the whole current history.'**
  String get backupHelper;

  /// No description provided for @backupSave.
  ///
  /// In en, this message translates to:
  /// **'Save a backup…'**
  String get backupSave;

  /// No description provided for @countryDaysLine.
  ///
  /// In en, this message translates to:
  /// **'{yearDays} in {year} · {allDays} all time'**
  String countryDaysLine(String yearDays, int year, String allDays);

  /// No description provided for @countryCalendarHint.
  ///
  /// In en, this message translates to:
  /// **'Only this country\'s days are painted in the calendar. Tap a day to see every record for it.'**
  String get countryCalendarHint;

  /// No description provided for @countryRecords.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get countryRecords;

  /// No description provided for @countryOpenJournal.
  ///
  /// In en, this message translates to:
  /// **'Open in the journal'**
  String get countryOpenJournal;

  /// No description provided for @yearPrev.
  ///
  /// In en, this message translates to:
  /// **'Previous year'**
  String get yearPrev;

  /// No description provided for @yearNext.
  ///
  /// In en, this message translates to:
  /// **'Next year'**
  String get yearNext;

  /// No description provided for @moreDetails.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreDetails;

  /// No description provided for @lessDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get lessDetails;

  /// No description provided for @autoDetectShort.
  ///
  /// In en, this message translates to:
  /// **'One approximate detection when the app opens, at most once an hour, no dialogs, nothing recorded.'**
  String get autoDetectShort;

  /// No description provided for @backgroundShort.
  ///
  /// In en, this message translates to:
  /// **'Every 2–3 hours, the same check with a notification if the country looks different. Needs “Allow all the time” and notifications.'**
  String get backgroundShort;

  /// No description provided for @backupShort.
  ///
  /// In en, this message translates to:
  /// **'A file with your whole history. Keep it off the phone: no copy stays here.'**
  String get backupShort;

  /// No description provided for @importShort.
  ///
  /// In en, this message translates to:
  /// **'Google Maps Timeline export (JSON): countries are matched offline, nothing is recorded without confirmation.'**
  String get importShort;

  /// No description provided for @clearAllShort.
  ///
  /// In en, this message translates to:
  /// **'Back to the first launch. Only a backup copy can bring things back.'**
  String get clearAllShort;

  /// No description provided for @datesFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Dates *'**
  String get datesFieldLabel;

  /// No description provided for @pickerDates.
  ///
  /// In en, this message translates to:
  /// **'Trip dates'**
  String get pickerDates;

  /// No description provided for @quickToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get quickToday;

  /// No description provided for @quickYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get quickYesterday;

  /// No description provided for @quickOneDay.
  ///
  /// In en, this message translates to:
  /// **'One day'**
  String get quickOneDay;

  /// No description provided for @shareYear.
  ///
  /// In en, this message translates to:
  /// **'Share the summary'**
  String get shareYear;

  /// No description provided for @shareTitle.
  ///
  /// In en, this message translates to:
  /// **'{year} summary'**
  String shareTitle(int year);

  /// No description provided for @shareSend.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareSend;

  /// No description provided for @shareHint.
  ///
  /// In en, this message translates to:
  /// **'The picture is made on the phone and goes only where you choose: the year’s totals and countries, no records or coordinates.'**
  String get shareHint;

  /// No description provided for @shareFooter.
  ///
  /// In en, this message translates to:
  /// **'Personal travel journal · a moving day counts in both countries'**
  String get shareFooter;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share: {error}'**
  String shareFailed(String error);

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get navJournal;

  /// No description provided for @openCalendar.
  ///
  /// In en, this message translates to:
  /// **'Open the calendar'**
  String get openCalendar;

  /// No description provided for @onThisDayTitle.
  ///
  /// In en, this message translates to:
  /// **'On this day'**
  String get onThisDayTitle;

  /// No description provided for @onThisDayDay.
  ///
  /// In en, this message translates to:
  /// **'Day {n} of {total}'**
  String onThisDayDay(int n, int total);

  /// No description provided for @onThisDayAround.
  ///
  /// In en, this message translates to:
  /// **'Around these days'**
  String get onThisDayAround;

  /// No description provided for @onThisDayTransit.
  ///
  /// In en, this message translates to:
  /// **'Transit'**
  String get onThisDayTransit;

  /// No description provided for @calendarFilter.
  ///
  /// In en, this message translates to:
  /// **'Only this country’s days'**
  String get calendarFilter;

  /// No description provided for @reviewOpen.
  ///
  /// In en, this message translates to:
  /// **'Year in review'**
  String get reviewOpen;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Your {year}'**
  String reviewTitle(int year);

  /// No description provided for @reviewNudge.
  ///
  /// In en, this message translates to:
  /// **'Your {year} in review is ready'**
  String reviewNudge(int year);

  /// No description provided for @reviewCountries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} country} other{{count} countries}}'**
  String reviewCountries(int count);

  /// No description provided for @reviewCountriesSub.
  ///
  /// In en, this message translates to:
  /// **'with at least one stay this year'**
  String get reviewCountriesSub;

  /// No description provided for @reviewNewCountries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No new countries} one{{count} new country} other{{count} new countries}}'**
  String reviewNewCountries(int count);

  /// No description provided for @reviewDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get reviewDaysTitle;

  /// No description provided for @reviewLongest.
  ///
  /// In en, this message translates to:
  /// **'Longest trip'**
  String get reviewLongest;

  /// No description provided for @reviewNoTrips.
  ///
  /// In en, this message translates to:
  /// **'No trips this year.'**
  String get reviewNoTrips;

  /// No description provided for @reviewMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Your map'**
  String get reviewMapTitle;

  /// No description provided for @reviewCities.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} city} other{{count} cities}}'**
  String reviewCities(int count);

  /// No description provided for @reviewCitiesSub.
  ///
  /// In en, this message translates to:
  /// **'from your records'**
  String get reviewCitiesSub;

  /// No description provided for @reviewShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share the year'**
  String get reviewShareTitle;

  /// No description provided for @reviewShareBody.
  ///
  /// In en, this message translates to:
  /// **'A picture with the year, the days and the countries, made on the phone. It goes only where you choose.'**
  String get reviewShareBody;

  /// No description provided for @reviewThrough.
  ///
  /// In en, this message translates to:
  /// **'Through {date}'**
  String reviewThrough(String date);

  /// No description provided for @planToggle.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planToggle;

  /// No description provided for @planTripToggle.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get planTripToggle;

  /// No description provided for @planNew.
  ///
  /// In en, this message translates to:
  /// **'New plan'**
  String get planNew;

  /// No description provided for @planYour.
  ///
  /// In en, this message translates to:
  /// **'Trip plan'**
  String get planYour;

  /// No description provided for @savePlan.
  ///
  /// In en, this message translates to:
  /// **'Save plan'**
  String get savePlan;

  /// No description provided for @deletePlan.
  ///
  /// In en, this message translates to:
  /// **'Delete plan'**
  String get deletePlan;

  /// No description provided for @plansSection.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get plansSection;

  /// No description provided for @planHint.
  ///
  /// In en, this message translates to:
  /// **'A plan does not count in days or totals until you confirm it.'**
  String get planHint;

  /// No description provided for @planInDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{today} one{in {count} day} other{in {count} days}}'**
  String planInDays(int count);

  /// No description provided for @planOngoing.
  ///
  /// In en, this message translates to:
  /// **'planned for these days'**
  String get planOngoing;

  /// No description provided for @planOverdue.
  ///
  /// In en, this message translates to:
  /// **'dates passed, not confirmed'**
  String get planOverdue;

  /// No description provided for @nextTrip.
  ///
  /// In en, this message translates to:
  /// **'Next trip'**
  String get nextTrip;

  /// No description provided for @planArrivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Planned for today: {place}. Are you there?'**
  String planArrivedTitle(String place);

  /// No description provided for @planYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, I am there'**
  String get planYes;

  /// No description provided for @planNo.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get planNo;

  /// No description provided for @planAddAsTrip.
  ///
  /// In en, this message translates to:
  /// **'Add as a trip'**
  String get planAddAsTrip;

  /// No description provided for @planOverdueTitle.
  ///
  /// In en, this message translates to:
  /// **'{place}: the dates have passed'**
  String planOverdueTitle(String place);

  /// No description provided for @planOverdueBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing was recorded. Add it as a trip, or edit the plan.'**
  String get planOverdueBody;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Country map'**
  String get mapTitle;

  /// No description provided for @mapCount.
  ///
  /// In en, this message translates to:
  /// **'{visited} of {total}'**
  String mapCount(int visited, int total);

  /// No description provided for @mapAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get mapAllTime;

  /// No description provided for @mapCountries.
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get mapCountries;

  /// No description provided for @mapPick.
  ///
  /// In en, this message translates to:
  /// **'Which country?'**
  String get mapPick;

  /// No description provided for @mapNotVisited.
  ///
  /// In en, this message translates to:
  /// **'no records'**
  String get mapNotVisited;

  /// No description provided for @mapLegendVisited.
  ///
  /// In en, this message translates to:
  /// **'visited'**
  String get mapLegendVisited;

  /// No description provided for @mapLegendTransit.
  ///
  /// In en, this message translates to:
  /// **'transit only'**
  String get mapLegendTransit;

  /// No description provided for @mapLegendDisputed.
  ///
  /// In en, this message translates to:
  /// **'disputed territory'**
  String get mapLegendDisputed;

  /// No description provided for @mapNote.
  ///
  /// In en, this message translates to:
  /// **'Borders by Natural Earth.'**
  String get mapNote;

  /// No description provided for @mapShare.
  ///
  /// In en, this message translates to:
  /// **'Share the map'**
  String get mapShare;

  /// No description provided for @mapFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get mapFullscreen;

  /// No description provided for @mapSearch.
  ///
  /// In en, this message translates to:
  /// **'Find a country'**
  String get mapSearch;

  /// No description provided for @mapSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Country name'**
  String get mapSearchHint;

  /// No description provided for @mapViewFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat map'**
  String get mapViewFlat;

  /// No description provided for @mapViewGlobe.
  ///
  /// In en, this message translates to:
  /// **'Globe'**
  String get mapViewGlobe;

  /// No description provided for @mapShareTitleAll.
  ///
  /// In en, this message translates to:
  /// **'My countries'**
  String get mapShareTitleAll;

  /// No description provided for @mapShareTitleYear.
  ///
  /// In en, this message translates to:
  /// **'My countries · {year}'**
  String mapShareTitleYear(int year);

  /// No description provided for @backupLast.
  ///
  /// In en, this message translates to:
  /// **'Last copy: {date}'**
  String backupLast(String date);

  /// No description provided for @backupNever.
  ///
  /// In en, this message translates to:
  /// **'No copy saved yet.'**
  String get backupNever;

  /// No description provided for @backupNudgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to save a copy'**
  String get backupNudgeTitle;

  /// No description provided for @backupNudgeBody.
  ///
  /// In en, this message translates to:
  /// **'Your records live only on this phone. Last copy: {date}.'**
  String backupNudgeBody(String date);

  /// No description provided for @backupNudgeBodyNever.
  ///
  /// In en, this message translates to:
  /// **'Your records live only on this phone, and there is no copy yet.'**
  String get backupNudgeBodyNever;

  /// No description provided for @backupNudgeLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get backupNudgeLater;

  /// No description provided for @clearAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear everything'**
  String get clearAllTitle;

  /// No description provided for @clearAllHelper.
  ///
  /// In en, this message translates to:
  /// **'Deletes all records, the archive, home country, current stay and settings — the app returns to its first launch. Only a backup copy can bring them back.'**
  String get clearAllHelper;

  /// No description provided for @clearAllButton.
  ///
  /// In en, this message translates to:
  /// **'Clear everything…'**
  String get clearAllButton;

  /// No description provided for @clearAllConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear everything?'**
  String get clearAllConfirmTitle;

  /// No description provided for @clearAllConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{records}, the archive, home country, current stay and all settings will be deleted. Only a backup copy can bring them back.'**
  String clearAllConfirmBody(String records);

  /// No description provided for @clearAllBackupFirst.
  ///
  /// In en, this message translates to:
  /// **'Save a copy first…'**
  String get clearAllBackupFirst;

  /// No description provided for @clearAllAction.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get clearAllAction;

  /// No description provided for @clearAllDone.
  ///
  /// In en, this message translates to:
  /// **'Everything cleared'**
  String get clearAllDone;

  /// No description provided for @clearAllFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not clear: {error}'**
  String clearAllFailed(String error);

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore from a backup…'**
  String get backupRestore;

  /// No description provided for @backupSaved.
  ///
  /// In en, this message translates to:
  /// **'Backup saved: {name}'**
  String backupSaved(String name);

  /// No description provided for @backupSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not write the file. Try another folder.'**
  String get backupSaveFailed;

  /// No description provided for @backupTrips.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} trip} other{{count} trips}}'**
  String backupTrips(int count);

  /// No description provided for @backupRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup?'**
  String get backupRestoreTitle;

  /// No description provided for @backupRestoreConfirm.
  ///
  /// In en, this message translates to:
  /// **'{name}: {trips}, created {date}, Domiday {version}. The current history ({current}) will be replaced entirely.'**
  String backupRestoreConfirm(
    String name,
    String trips,
    String date,
    String version,
    String current,
  );

  /// No description provided for @backupRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Replace history'**
  String get backupRestoreAction;

  /// No description provided for @backupRestored.
  ///
  /// In en, this message translates to:
  /// **'History restored: {trips}'**
  String backupRestored(String trips);

  /// No description provided for @backupUnknownDate.
  ///
  /// In en, this message translates to:
  /// **'unknown date'**
  String get backupUnknownDate;

  /// No description provided for @backupErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot restore'**
  String get backupErrorTitle;

  /// No description provided for @backupErrorNotBackup.
  ///
  /// In en, this message translates to:
  /// **'This is not a Domiday backup file.'**
  String get backupErrorNotBackup;

  /// No description provided for @backupErrorNewer.
  ///
  /// In en, this message translates to:
  /// **'This backup was made by a newer Domiday. Update the app; the current history is untouched.'**
  String get backupErrorNewer;

  /// No description provided for @backupErrorCorrupt.
  ///
  /// In en, this message translates to:
  /// **'The file is damaged or contains invalid records. The current history is untouched.'**
  String get backupErrorCorrupt;

  /// No description provided for @backgroundTitle.
  ///
  /// In en, this message translates to:
  /// **'Check in the background'**
  String get backgroundTitle;

  /// No description provided for @backgroundHelper.
  ///
  /// In en, this message translates to:
  /// **'Every 2–3 hours and when the phone comes back online, the app checks the country the same way — and only sends a notification if it looks like a different country. Nothing is recorded without your confirmation. Needs the “Allow all the time” location permission and notifications; Samsung may pause background work for “sleeping” apps.'**
  String get backgroundHelper;

  /// No description provided for @backgroundNeedsAlways.
  ///
  /// In en, this message translates to:
  /// **'Android grants “all the time” location only in its settings. Open the app settings, choose Permissions → Location → Allow all the time, then return to Domiday — it will turn on by itself.'**
  String get backgroundNeedsAlways;

  /// No description provided for @backgroundNeedsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for Domiday. Allow them in the app settings, otherwise the background check has no way to reach you.'**
  String get backgroundNeedsNotifications;

  /// No description provided for @openAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get openAppSettings;

  /// No description provided for @backgroundStatusOn.
  ///
  /// In en, this message translates to:
  /// **'Background check is on'**
  String get backgroundStatusOn;

  /// No description provided for @backgroundStatusOff.
  ///
  /// In en, this message translates to:
  /// **'Background check is off'**
  String get backgroundStatusOff;

  /// No description provided for @backgroundStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for permissions — it will turn on by itself once “Allow all the time” and notifications are granted'**
  String get backgroundStatusWaiting;

  /// No description provided for @backgroundNeverRan.
  ///
  /// In en, this message translates to:
  /// **'No background check has run yet'**
  String get backgroundNeverRan;

  /// No description provided for @backgroundLastRun.
  ///
  /// In en, this message translates to:
  /// **'Last check: {when} — {result}'**
  String backgroundLastRun(String when, String result);

  /// No description provided for @backgroundOutcomeNotified.
  ///
  /// In en, this message translates to:
  /// **'notification sent'**
  String get backgroundOutcomeNotified;

  /// No description provided for @backgroundOutcomeSame.
  ///
  /// In en, this message translates to:
  /// **'same country, or the suggestion was already dismissed'**
  String get backgroundOutcomeSame;

  /// No description provided for @backgroundOutcomeAlreadyNotified.
  ///
  /// In en, this message translates to:
  /// **'already notified'**
  String get backgroundOutcomeAlreadyNotified;

  /// No description provided for @backgroundOutcomeNoLocation.
  ///
  /// In en, this message translates to:
  /// **'no location obtained'**
  String get backgroundOutcomeNoLocation;

  /// No description provided for @backgroundOutcomeNoCountry.
  ///
  /// In en, this message translates to:
  /// **'country not determined'**
  String get backgroundOutcomeNoCountry;

  /// No description provided for @backgroundOutcomeNoProfile.
  ///
  /// In en, this message translates to:
  /// **'current country not set'**
  String get backgroundOutcomeNoProfile;

  /// No description provided for @backgroundOutcomeError.
  ///
  /// In en, this message translates to:
  /// **'error'**
  String get backgroundOutcomeError;

  /// No description provided for @backgroundErrorDetail.
  ///
  /// In en, this message translates to:
  /// **'Error: {text}'**
  String backgroundErrorDetail(String text);

  /// No description provided for @backgroundLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent runs:'**
  String get backgroundLogTitle;

  /// No description provided for @backgroundRunNow.
  ///
  /// In en, this message translates to:
  /// **'Run a check now'**
  String get backgroundRunNow;

  /// No description provided for @backgroundRunNowStarted.
  ///
  /// In en, this message translates to:
  /// **'Check started in the background. Leave the app for a minute and come back — the result appears in the “Last check” line.'**
  String get backgroundRunNowStarted;

  /// No description provided for @backgroundTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Test notification'**
  String get backgroundTestNotification;

  /// No description provided for @backgroundTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Domiday notifications work'**
  String get backgroundTestTitle;

  /// No description provided for @backgroundTestBody.
  ///
  /// In en, this message translates to:
  /// **'If you can see this, the channel, icon and permission are fine.'**
  String get backgroundTestBody;

  /// No description provided for @backgroundBatteryOk.
  ///
  /// In en, this message translates to:
  /// **'Battery: background is unrestricted.'**
  String get backgroundBatteryOk;

  /// No description provided for @backgroundHowToAlways.
  ///
  /// In en, this message translates to:
  /// **'How to grant it: Android Settings → Apps → Domiday → Permissions → Location → “Allow all the time”. If notifications are off, enable them there too. Then return to Domiday — it will turn on by itself.'**
  String get backgroundHowToAlways;

  /// No description provided for @backgroundEnableFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not enable: {error}'**
  String backgroundEnableFailed(String error);

  /// No description provided for @backgroundNotificationsOffLine.
  ///
  /// In en, this message translates to:
  /// **'Domiday notifications are off: the check runs, but there is no way to reach you. Allow them in the app settings.'**
  String get backgroundNotificationsOffLine;

  /// No description provided for @backgroundBatteryRestricted.
  ///
  /// In en, this message translates to:
  /// **'Battery: the system restricts Domiday in the background — checks may not run. Open the app settings → Battery → “Unrestricted”.'**
  String get backgroundBatteryRestricted;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'It looks like you are in {country}'**
  String notificationTitle(String country);

  /// No description provided for @notificationBody.
  ///
  /// In en, this message translates to:
  /// **'Open Domiday to confirm, correct or dismiss. Nothing is recorded until you do.'**
  String get notificationBody;

  /// No description provided for @notificationChannel.
  ///
  /// In en, this message translates to:
  /// **'Country detection'**
  String get notificationChannel;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Suggestions after a background country check'**
  String get notificationChannelDescription;

  /// No description provided for @gapsTitle.
  ///
  /// In en, this message translates to:
  /// **'Gaps in history'**
  String get gapsTitle;

  /// No description provided for @gapsDone.
  ///
  /// In en, this message translates to:
  /// **'Days added to the journal'**
  String get gapsDone;

  /// No description provided for @gapsCheckFirst.
  ///
  /// In en, this message translates to:
  /// **'Check the dates first'**
  String get gapsCheckFirst;

  /// No description provided for @gapsYearHome.
  ///
  /// In en, this message translates to:
  /// **'Year: {year}. Home country: {home}.'**
  String gapsYearHome(int year, String home);

  /// No description provided for @gapsExplain.
  ///
  /// In en, this message translates to:
  /// **'These are unknown days between known stays, not proof that you were home. Unrecorded periods at the start and end are not offered. Recorded days are not affected.'**
  String get gapsExplain;

  /// No description provided for @gapsNone.
  ///
  /// In en, this message translates to:
  /// **'There are no gaps between known stays this year. Other days of the year may still be unknown.'**
  String get gapsNone;

  /// No description provided for @gapsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {days} · records: {count}'**
  String gapsTotal(String days, int count);

  /// No description provided for @gapsDoneNote.
  ///
  /// In en, this message translates to:
  /// **'Each record can be edited or deleted in the journal. The note says the gap was confirmed by you manually.'**
  String get gapsDoneNote;

  /// No description provided for @gapsConfirmNote.
  ///
  /// In en, this message translates to:
  /// **'By confirming you state that on ALL these dates you were in “{home}”. If not, go back and add separate trips manually.'**
  String gapsConfirmNote(String home);

  /// No description provided for @gapsConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'I confirm: I was home on these days'**
  String get gapsConfirmButton;

  /// No description provided for @gapsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel — add nothing'**
  String get gapsCancel;

  /// No description provided for @gapsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save. The journal is unchanged. If the date or records changed, go back and open the preview again.'**
  String get gapsSaveFailed;

  /// No description provided for @gapFillNote.
  ///
  /// In en, this message translates to:
  /// **'Added manually after confirming a gap in {year}. Home country: {home}. This is your confirmation, not automatic detection.'**
  String gapFillNote(int year, String home);

  /// No description provided for @chooseCountry.
  ///
  /// In en, this message translates to:
  /// **'Choose a country'**
  String get chooseCountry;

  /// No description provided for @chooseYear.
  ///
  /// In en, this message translates to:
  /// **'Choose a year'**
  String get chooseYear;

  /// No description provided for @allCountries.
  ///
  /// In en, this message translates to:
  /// **'All countries'**
  String get allCountries;

  /// No description provided for @allYears.
  ///
  /// In en, this message translates to:
  /// **'All years'**
  String get allYears;

  /// No description provided for @journalTitle.
  ///
  /// In en, this message translates to:
  /// **'When and where you were'**
  String get journalTitle;

  /// No description provided for @journalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your travels, gathered in one place.'**
  String get journalSubtitle;

  /// No description provided for @addTrip.
  ///
  /// In en, this message translates to:
  /// **'Add trip'**
  String get addTrip;

  /// No description provided for @searchLabel.
  ///
  /// In en, this message translates to:
  /// **'Find a trip'**
  String get searchLabel;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Country, city, note or year'**
  String get searchHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @foundTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips found: {count}'**
  String foundTrips(int count);

  /// No description provided for @tripHistory.
  ///
  /// In en, this message translates to:
  /// **'Trip history'**
  String get tripHistory;

  /// No description provided for @noSuchRecords.
  ///
  /// In en, this message translates to:
  /// **'No such records yet.'**
  String get noSuchRecords;

  /// No description provided for @tryAnotherWord.
  ///
  /// In en, this message translates to:
  /// **'Try another word or reset the filters.'**
  String get tryAnotherWord;

  /// No description provided for @resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get resetFilters;

  /// No description provided for @bySelectedTrips.
  ///
  /// In en, this message translates to:
  /// **'By selected trips'**
  String get bySelectedTrips;

  /// No description provided for @byYourRecordsOnly.
  ///
  /// In en, this message translates to:
  /// **'Only by your records'**
  String get byYourRecordsOnly;

  /// No description provided for @countryStatLine.
  ///
  /// In en, this message translates to:
  /// **'{country}  ·  {days}  ·  trips: {trips}'**
  String countryStatLine(String country, String days, int trips);

  /// No description provided for @moveDayNotVisa.
  ///
  /// In en, this message translates to:
  /// **'A moving day may count in two countries. This is not a visa or tax calculation.'**
  String get moveDayNotVisa;

  /// No description provided for @journalFooter.
  ///
  /// In en, this message translates to:
  /// **'Personal journal · {version}'**
  String journalFooter(String version);

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Which trip shall we start with?'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Recall one journey and save the country and dates. A city and a short note will help you return to the memories.'**
  String get emptyBody;

  /// No description provided for @emptyNote.
  ///
  /// In en, this message translates to:
  /// **'No records yet. Everything is entered by hand and stored only on this device.'**
  String get emptyNote;

  /// No description provided for @yourJournalInNumbers.
  ///
  /// In en, this message translates to:
  /// **'Your journal in numbers'**
  String get yourJournalInNumbers;

  /// No description provided for @daysInRecordedTrips.
  ///
  /// In en, this message translates to:
  /// **'Days in recorded trips'**
  String get daysInRecordedTrips;

  /// No description provided for @bothDatesIncluded.
  ///
  /// In en, this message translates to:
  /// **'Both dates are included. Overlapping days count once.'**
  String get bothDatesIncluded;

  /// No description provided for @daysOnlyInYear.
  ///
  /// In en, this message translates to:
  /// **'Days — only in {year}.'**
  String daysOnlyInYear(int year);

  /// No description provided for @wholeTrip.
  ///
  /// In en, this message translates to:
  /// **'{days} · Whole trip'**
  String wholeTrip(String days);

  /// No description provided for @openAndEdit.
  ///
  /// In en, this message translates to:
  /// **'Open and edit'**
  String get openAndEdit;

  /// No description provided for @currentStayOngoing.
  ///
  /// In en, this message translates to:
  /// **'Current stay · ongoing'**
  String get currentStayOngoing;

  /// No description provided for @pickerArrival.
  ///
  /// In en, this message translates to:
  /// **'Arrival date'**
  String get pickerArrival;

  /// No description provided for @pickerDeparture.
  ///
  /// In en, this message translates to:
  /// **'Departure date'**
  String get pickerDeparture;

  /// No description provided for @errorPickBothDates.
  ///
  /// In en, this message translates to:
  /// **'Choose the arrival and departure dates'**
  String get errorPickBothDates;

  /// No description provided for @tripSaved.
  ///
  /// In en, this message translates to:
  /// **'Trip saved'**
  String get tripSaved;

  /// No description provided for @overlapTitle.
  ///
  /// In en, this message translates to:
  /// **'Days already taken'**
  String get overlapTitle;

  /// No description provided for @overlapIntro.
  ///
  /// In en, this message translates to:
  /// **'{range}: these days are already in the journal. One shared day at the junction is a moving day and is fine; here the overlap is longer.'**
  String overlapIntro(String range);

  /// No description provided for @overlapTrim.
  ///
  /// In en, this message translates to:
  /// **'{country}, {range}: becomes {next}'**
  String overlapTrim(String country, String range, String next);

  /// No description provided for @overlapSplit.
  ///
  /// In en, this message translates to:
  /// **'{country}, {range}: splits into {first} and {second}'**
  String overlapSplit(
    String country,
    String range,
    String first,
    String second,
  );

  /// No description provided for @overlapRemove.
  ///
  /// In en, this message translates to:
  /// **'{country}, {range}: will be deleted'**
  String overlapRemove(String country, String range);

  /// No description provided for @overlapCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current stay, {country}: will start on {date}'**
  String overlapCurrent(String country, String date);

  /// No description provided for @overlapCurrentFixed.
  ///
  /// In en, this message translates to:
  /// **'Current stay, {country}: overlaps and cannot be changed here — set its arrival date on the “Now” card first'**
  String overlapCurrentFixed(String country);

  /// No description provided for @overlapSameCountry.
  ///
  /// In en, this message translates to:
  /// **'{country} (same country)'**
  String overlapSameCountry(String country);

  /// No description provided for @overlapHint.
  ///
  /// In en, this message translates to:
  /// **'“Replace” trims or deletes the listed records as described. “Keep both” saves as is: the days count in both.'**
  String get overlapHint;

  /// No description provided for @overlapHintKeepOnly.
  ///
  /// In en, this message translates to:
  /// **'“Keep both” saves as is: the days count in both.'**
  String get overlapHintKeepOnly;

  /// No description provided for @overlapReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get overlapReplace;

  /// No description provided for @overlapKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep both'**
  String get overlapKeep;

  /// No description provided for @tripSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save. The form data stayed on screen. Check free space and press “Save trip” again.'**
  String get tripSaveFailed;

  /// No description provided for @deleteTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete the trip?'**
  String get deleteTripTitle;

  /// No description provided for @deleteTripBody.
  ///
  /// In en, this message translates to:
  /// **'The record cannot be restored in this prototype.'**
  String get deleteTripBody;

  /// No description provided for @tripDeleted.
  ///
  /// In en, this message translates to:
  /// **'Trip deleted'**
  String get tripDeleted;

  /// No description provided for @tripDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the record. It remains in the journal. Try deleting it again.'**
  String get tripDeleteFailed;

  /// No description provided for @newTrip.
  ///
  /// In en, this message translates to:
  /// **'New trip'**
  String get newTrip;

  /// No description provided for @yourTrip.
  ///
  /// In en, this message translates to:
  /// **'Your trip'**
  String get yourTrip;

  /// No description provided for @tripFormIntro.
  ///
  /// In en, this message translates to:
  /// **'Record a completed trip. Both dates are required and not later than today. The arrival and departure days are included.'**
  String get tripFormIntro;

  /// No description provided for @countryFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Country *'**
  String get countryFieldLabel;

  /// No description provided for @countryFieldHelper.
  ///
  /// In en, this message translates to:
  /// **'Any country can be entered'**
  String get countryFieldHelper;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @arrivalFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Arrival *'**
  String get arrivalFieldLabel;

  /// No description provided for @departureFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Departure *'**
  String get departureFieldLabel;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteLabel;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'What do you want to remember?'**
  String get noteHint;

  /// No description provided for @saveTrip.
  ///
  /// In en, this message translates to:
  /// **'Save trip'**
  String get saveTrip;

  /// No description provided for @deleteTrip.
  ///
  /// In en, this message translates to:
  /// **'Delete trip'**
  String get deleteTrip;

  /// No description provided for @chooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get chooseDate;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'A private travel journal. It counts your days by country, shows the year in a calendar and on a map, and remembers where you were. Everything stays on your phone.'**
  String get aboutTagline;

  /// No description provided for @aboutFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'What it does'**
  String get aboutFeaturesTitle;

  /// No description provided for @aboutFeatCalendar.
  ///
  /// In en, this message translates to:
  /// **'Year calendar: every day painted with its country colour; transit and a day in two countries are marked separately.'**
  String get aboutFeatCalendar;

  /// No description provided for @aboutFeatMap.
  ///
  /// In en, this message translates to:
  /// **'Country map and a rotating globe: visited countries in political-map colours, search that flies to a country.'**
  String get aboutFeatMap;

  /// No description provided for @aboutFeatJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal with search by country, city, note and year; a page for every country.'**
  String get aboutFeatJournal;

  /// No description provided for @aboutFeatPlans.
  ///
  /// In en, this message translates to:
  /// **'Trip plans: future dates show in the calendar but do not count until you confirm the trip.'**
  String get aboutFeatPlans;

  /// No description provided for @aboutFeatReview.
  ///
  /// In en, this message translates to:
  /// **'Year in review: countries and new countries, days, the longest trip, the map, cities, a picture to share.'**
  String get aboutFeatReview;

  /// No description provided for @aboutFeatOnThisDay.
  ///
  /// In en, this message translates to:
  /// **'“On this day”: where you were on this date in past years.'**
  String get aboutFeatOnThisDay;

  /// No description provided for @aboutFeatImport.
  ///
  /// In en, this message translates to:
  /// **'Google Maps Timeline import: countries are matched offline, you add only the periods you want.'**
  String get aboutFeatImport;

  /// No description provided for @aboutFeatDetect.
  ///
  /// In en, this message translates to:
  /// **'Country detection on your tap and when the app opens: a suggestion that you confirm.'**
  String get aboutFeatDetect;

  /// No description provided for @aboutFeatBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup as a single file, restore, “Clear everything” with confirmation.'**
  String get aboutFeatBackup;

  /// No description provided for @aboutContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get aboutContactTitle;

  /// No description provided for @aboutContactEmail.
  ///
  /// In en, this message translates to:
  /// **'Questions by email'**
  String get aboutContactEmail;

  /// No description provided for @aboutContactSite.
  ///
  /// In en, this message translates to:
  /// **'Feature requests and bug reports on the website'**
  String get aboutContactSite;

  /// No description provided for @aboutContactNote.
  ///
  /// In en, this message translates to:
  /// **'The email and the website open in other apps. The app itself never goes online.'**
  String get aboutContactNote;

  /// No description provided for @aboutOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open {url}: no app can handle it.'**
  String aboutOpenFailed(String url);

  /// No description provided for @aboutCreditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Credits and licences'**
  String get aboutCreditsTitle;

  /// No description provided for @aboutCreditsBody.
  ///
  /// In en, this message translates to:
  /// **'Country borders: Natural Earth, public domain. Flags: the flag-icons set, MIT licence. Fonts: Manrope (SIL Open Font License) and Roboto (Apache 2.0). Built with Flutter (BSD).'**
  String get aboutCreditsBody;

  /// No description provided for @aboutCopyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 Domiday. All rights reserved.'**
  String get aboutCopyright;

  /// No description provided for @aboutNoWarranty.
  ///
  /// In en, this message translates to:
  /// **'The app is provided as is, without warranty. It does not determine residency, entry eligibility or visa limits.'**
  String get aboutNoWarranty;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Domiday'**
  String get aboutTitle;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Personal journal · {version}'**
  String aboutVersion(String version);

  /// No description provided for @aboutPlaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Current place and history'**
  String get aboutPlaceTitle;

  /// No description provided for @aboutPlaceBody.
  ///
  /// In en, this message translates to:
  /// **'A manual journal of trips and of where you are now. It answers “when and where were we” and never changes anything by itself: every record, date and country is entered or confirmed by you.'**
  String get aboutPlaceBody;

  /// No description provided for @aboutUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Unknown does not mean home'**
  String get aboutUnknownTitle;

  /// No description provided for @aboutUnknownBody.
  ///
  /// In en, this message translates to:
  /// **'The home country is your personal setting, not tax residency. Changing it recalculates the categories but does not change the records. Without an arrival date the current stay adds no days to the totals. Unknown days are counted from 1 January to today, and for past years — for the whole year. Gaps between known stays can be recorded as days at home only after reviewing the dates and your confirmation. Those records can be edited or deleted in the journal.'**
  String get aboutUnknownBody;

  /// No description provided for @aboutDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Your records stay on your device'**
  String get aboutDeviceTitle;

  /// No description provided for @aboutDeviceBody.
  ///
  /// In en, this message translates to:
  /// **'Data is stored in the app’s private folder. There is no account, cloud, network requests, ads or analytics. A backup — a file in the app’s format — can be saved and restored from Settings. Uninstalling the app or clearing its data will lose the records. Do not keep the only copy of important information here.'**
  String get aboutDeviceBody;

  /// No description provided for @aboutCountingTitle.
  ///
  /// In en, this message translates to:
  /// **'How days are counted'**
  String get aboutCountingTitle;

  /// No description provided for @aboutCountingBody.
  ///
  /// In en, this message translates to:
  /// **'The arrival and departure days are included: a one-day trip is one day. Overlapping records do not increase the total. Within one country overlapping days also count once. A moving day may belong to two countries, so the sum by country may exceed the total number of days. With a year selected, only days in that year are counted; cards keep the full trip dates. Searching by year finds trips that touch it but does not trim dates by itself.'**
  String get aboutCountingBody;

  /// No description provided for @aboutNotVisaTitle.
  ///
  /// In en, this message translates to:
  /// **'Not a visa or tax calculator'**
  String get aboutNotVisaTitle;

  /// No description provided for @aboutNotVisaBody.
  ///
  /// In en, this message translates to:
  /// **'The totals describe only the entered records, not your whole history of stays. A missed trip is unknown history, not proof of absence from a country. The journal does not determine residency, the right to enter or compliance with visa limits.'**
  String get aboutNotVisaBody;

  /// No description provided for @errMissingId.
  ///
  /// In en, this message translates to:
  /// **'The record has no identifier'**
  String get errMissingId;

  /// No description provided for @errCountryRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a country'**
  String get errCountryRequired;

  /// No description provided for @errTextTooLong.
  ///
  /// In en, this message translates to:
  /// **'The text is too long'**
  String get errTextTooLong;

  /// No description provided for @errDepartureBeforeArrival.
  ///
  /// In en, this message translates to:
  /// **'The departure date cannot be earlier than the arrival date'**
  String get errDepartureBeforeArrival;

  /// No description provided for @errFutureTrip.
  ///
  /// In en, this message translates to:
  /// **'Only past trips can be recorded, not future dates'**
  String get errFutureTrip;

  /// No description provided for @errInvalidTrip.
  ///
  /// In en, this message translates to:
  /// **'Invalid trip record'**
  String get errInvalidTrip;

  /// No description provided for @errSameCountry.
  ///
  /// In en, this message translates to:
  /// **'Choose a different country'**
  String get errSameCountry;

  /// No description provided for @errMoveDateRange.
  ///
  /// In en, this message translates to:
  /// **'The moving date must be between {from} and {to}. For earlier history use the journal.'**
  String errMoveDateRange(String from, String to);

  /// No description provided for @errCountryLength.
  ///
  /// In en, this message translates to:
  /// **'Enter a country: 1 to 120 characters'**
  String get errCountryLength;

  /// No description provided for @errYearRange.
  ///
  /// In en, this message translates to:
  /// **'Choose a past or the current year'**
  String get errYearRange;

  /// No description provided for @errPreviewStale.
  ///
  /// In en, this message translates to:
  /// **'The data changed. Open the preview again.'**
  String get errPreviewStale;

  /// No description provided for @errHomeCountryFirst.
  ///
  /// In en, this message translates to:
  /// **'Set the home country first'**
  String get errHomeCountryFirst;

  /// No description provided for @errMoveDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the moving date'**
  String get errMoveDateRequired;

  /// No description provided for @detectOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Country detection is off'**
  String get detectOffTitle;

  /// No description provided for @detectOffDenied.
  ///
  /// In en, this message translates to:
  /// **'Domiday has no location permission, so it can’t notice when you cross a border. Days are counted anyway — you just change the country yourself.'**
  String get detectOffDenied;

  /// No description provided for @detectOffService.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off on this phone, so Domiday can’t notice when you cross a border. Days are counted anyway — you just change the country yourself.'**
  String get detectOffService;

  /// No description provided for @detectOffEnable.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get detectOffEnable;

  /// No description provided for @detectOffDismiss.
  ///
  /// In en, this message translates to:
  /// **'Not needed'**
  String get detectOffDismiss;

  /// No description provided for @countsItself.
  ///
  /// In en, this message translates to:
  /// **'Days count on their own — just tell Domiday when you change country.'**
  String get countsItself;

  /// No description provided for @importIntroLead.
  ///
  /// In en, this message translates to:
  /// **'Domiday can fill your journal from Google Maps Timeline. It takes three steps:'**
  String get importIntroLead;

  /// No description provided for @importStep1.
  ///
  /// In en, this message translates to:
  /// **'Export Timeline on your phone: Settings → Location → Location services → Timeline → Export Timeline data. Or in Google Maps: your avatar → Your Timeline → ⋮ → Location & privacy settings → Export Timeline data. Menu names differ slightly between phones.'**
  String get importStep1;

  /// No description provided for @importStep2.
  ///
  /// In en, this message translates to:
  /// **'Save the file, for example to Downloads. It is usually called Timeline.json.'**
  String get importStep2;

  /// No description provided for @importStep3.
  ///
  /// In en, this message translates to:
  /// **'Come back here and tap “Choose file”. Countries are matched offline, coordinates are not stored, and nothing is recorded until you review and confirm.'**
  String get importStep3;

  /// No description provided for @importNoTimeline.
  ///
  /// In en, this message translates to:
  /// **'If Timeline was never turned on, there is nothing to export — then add trips by hand in the journal.'**
  String get importNoTimeline;

  /// No description provided for @importChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get importChoose;

  /// No description provided for @importAnyFile.
  ///
  /// In en, this message translates to:
  /// **'File not in the list? Show all files'**
  String get importAnyFile;

  /// No description provided for @importOtherFile.
  ///
  /// In en, this message translates to:
  /// **'Choose another file'**
  String get importOtherFile;

  /// No description provided for @mapHintAll.
  ///
  /// In en, this message translates to:
  /// **'Countries you have been to are coloured. Tap a country to see its days.'**
  String get mapHintAll;

  /// No description provided for @mapHintYear.
  ///
  /// In en, this message translates to:
  /// **'Countries you visited in {year} are coloured. Tap a country to see its days.'**
  String mapHintYear(int year);

  /// No description provided for @mapEmpty.
  ///
  /// In en, this message translates to:
  /// **'Countries you have been to will be coloured here. Add trips in the journal or import your history from Google Maps.'**
  String get mapEmpty;
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
