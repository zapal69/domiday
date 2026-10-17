// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get choose => 'Choose';

  @override
  String get save => 'Save';

  @override
  String get saving => 'Saving…';

  @override
  String get done => 'Done';

  @override
  String get stay => 'Stay';

  @override
  String get leave => 'Leave';

  @override
  String get leaveWithoutSaving => 'Leave without saving?';

  @override
  String get unsavedChanges => 'Changes in this form will not be saved.';

  @override
  String get localOnlyNoBackup => 'On this device only. Backup is in Settings.';

  @override
  String get aboutTooltip => 'About';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get journalTooltip => 'Journal';

  @override
  String daysCompact(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String daysFull(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String recordsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '$count record',
    );
    return '$_temp0';
  }

  @override
  String tripsCount(int count) {
    return 'Trips: $count';
  }

  @override
  String countriesCount(int count) {
    return 'Countries: $count';
  }

  @override
  String get loadFailedTitle => 'Could not open the journal';

  @override
  String get loadFailedBody =>
      'The file is unavailable, damaged or was created by another version of the app. We did not replace it with an empty journal. Changes are disabled. Do not uninstall the app or clear its data.';

  @override
  String get retryOpen => 'Try opening again';

  @override
  String todayLine(String date) {
    return 'Today · $date';
  }

  @override
  String yearSummaryButton(int year) {
    return '$year summary';
  }

  @override
  String periodLine(String from, String to, String days) {
    return '$from — $to · $days';
  }

  @override
  String get methodologyLine =>
      'Unknown does not mean home. A moving day counts in both countries, and once among known days.';

  @override
  String get byCountry => 'By country';

  @override
  String get shareOfKnownDays => 'share of known days';

  @override
  String get noCountryData =>
      'No dates to count yet. Unknown days belong to no country.';

  @override
  String get recentTrips => 'Recent trips';

  @override
  String get noCompletedTrips =>
      'No completed trips with dates yet. Add them in the journal.';

  @override
  String get allJournalAndArchive => 'Full journal and archive';

  @override
  String get homeCountry => 'Home country';

  @override
  String countryShareSemantics(String country, int days, int percent) {
    return '$country: $days days, $percent % of known';
  }

  @override
  String get nowStayEyebrow => 'NOW';

  @override
  String get arrivalUnknown => 'Arrival date unknown';

  @override
  String get noDateNoDays =>
      'Without a date this stay adds no days to the totals.';

  @override
  String sinceArrivalLine(String date) {
    return 'Since $date, including the arrival day and today.';
  }

  @override
  String get changeCountry => 'Change country';

  @override
  String get arrivalDate => 'Arrival date';

  @override
  String get dateShort => 'Date';

  @override
  String get tileKnown => 'Known';

  @override
  String tileKnownSub(int total) {
    return 'of $total in the period';
  }

  @override
  String get tileHome => 'Home';

  @override
  String get tileAway => 'Away';

  @override
  String tileAwaySub(int count) {
    return 'overlapping with home: $count';
  }

  @override
  String get tileUnknown => 'Unknown';

  @override
  String get checkGaps => 'Check gaps';

  @override
  String get daysUnit => 'days';

  @override
  String get monthsShort => 'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec';

  @override
  String calendarSemantics(int year, int home, int away, int unknown) {
    return '$year calendar: home $home days, away $away days, unknown $unknown days';
  }

  @override
  String get legendHome => 'home';

  @override
  String get legendAway => 'away';

  @override
  String get legendUnknown => 'unknown';

  @override
  String get legendBoth => 'day in two countries';

  @override
  String get legendTransit => 'transit';

  @override
  String get legendOther => 'other countries';

  @override
  String get legendFuture => 'not yet';

  @override
  String get calendarMonthHint =>
      'Tap a month to expand it; tap a day for its card.';

  @override
  String get calendarCollapse => 'Collapse';

  @override
  String get monthsFull =>
      'January,February,March,April,May,June,July,August,September,October,November,December';

  @override
  String get weekdaysShort => 'Mo,Tu,We,Th,Fr,Sa,Su';

  @override
  String get kindStay => 'Stay';

  @override
  String get kindTransit => 'Transit';

  @override
  String get kindTransitHint =>
      'A layover or a pass-through: the days count as known and for that country, and are marked separately.';

  @override
  String transitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transits',
      one: '$count transit',
    );
    return '$_temp0';
  }

  @override
  String transitCalendarSemantics(int count) {
    return 'transit on $count days';
  }

  @override
  String get dayCardEmpty => 'No data for this day';

  @override
  String get dayCardCurrent => 'Current stay';

  @override
  String get dayCardHint => 'Tap a record to open it. Viewing changes nothing.';

  @override
  String dayCardSemantics(String date, int count) {
    return 'Day $date: $count records';
  }

  @override
  String transitToday(String country) {
    return 'Transit today: $country';
  }

  @override
  String wholeTransit(String days) {
    return '$days · Transit';
  }

  @override
  String get newTransit => 'New transit';

  @override
  String get yourTransit => 'Your transit';

  @override
  String get transitFormIntro =>
      'Record a layover or a pass-through. One date or a range if it crossed midnight. City or airport is optional; time is not recorded.';

  @override
  String get detectNow => 'Detect my country now';

  @override
  String get detectBusy => 'Detecting…';

  @override
  String detectSame(String country) {
    return 'You are still in $country. Nothing changed.';
  }

  @override
  String get detectNone =>
      'Could not determine the country from the coordinates (sea or an area outside the map). The journal is unchanged.';

  @override
  String get detectDenied =>
      'No permission for approximate location. Allow it in Android settings or keep the journal by hand.';

  @override
  String get detectServiceOff =>
      'Location is turned off on the phone. Turn it on or keep the journal by hand.';

  @override
  String get detectFailed =>
      'Could not get coordinates (no signal or timed out). Try later; the journal is unchanged.';

  @override
  String detectSilenced(int days) {
    return 'This detection was dismissed earlier. It will be offered again after $days days or when the country changes.';
  }

  @override
  String candidateTitle(String country) {
    return 'It looks like you are in $country';
  }

  @override
  String candidateUncertain(String alternatives) {
    return 'A border or coast is nearby: it could also be $alternatives. Check by yourself.';
  }

  @override
  String get candidateUncertainNoAlt =>
      'The point is outside the map borders (coast or sea); the nearest country is shown. Check by yourself.';

  @override
  String candidateDetected(String date, String km) {
    return 'Detected $date, accuracy about $km km. This is not the arrival date.';
  }

  @override
  String get candidateNoRecord =>
      'Until you confirm, the current country, the calendar and the totals stay as they are. The arrival date is chosen on the next screen; by default it is the detection day.';

  @override
  String get candidateConfirm => 'Confirm move';

  @override
  String get candidateCorrect => 'Correct the country';

  @override
  String get candidateTransit => 'It was transit';

  @override
  String get candidateDismiss => 'This is wrong';

  @override
  String candidateDismissed(int days) {
    return 'Detection dismissed. The journal is unchanged; the same country will not be offered again for $days days.';
  }

  @override
  String candidateBanner(String country) {
    return 'It looks like you are in $country';
  }

  @override
  String get candidateHint =>
      'From an approximate position. Only a suggestion for now.';

  @override
  String get candidateYes => 'Yes';

  @override
  String get candidateNo => 'No';

  @override
  String get detectHint =>
      'The app can suggest where you are from an approximate position.';

  @override
  String get detectShort => 'Check';

  @override
  String get journalNow => 'now';

  @override
  String get candidateReview => 'Review';

  @override
  String get detectTitle => 'Country detection';

  @override
  String autoStatus(String time, String result) {
    return 'Auto-check $time · $result';
  }

  @override
  String get autoStatusSame => 'country matches';

  @override
  String get autoStatusPending => 'there is a suggestion';

  @override
  String get autoStatusDenied => 'no location permission';

  @override
  String get autoStatusOff => 'location is off';

  @override
  String get autoStatusFailed => 'no coordinates';

  @override
  String get autoStatusNone => 'country not determined';

  @override
  String get autoStatusSilenced => 'dismissed earlier';

  @override
  String seriesLine(String date) {
    return 'Since $date, counting back through your records without a break.';
  }

  @override
  String get aboutDetectTitle => 'Country detection';

  @override
  String get aboutDetectBody =>
      'On your tap, when the app opens and, only if you switched on “Check in the background”, in a background task, the app asks Android once for an approximate location and matches it against country borders stored inside the app (Natural Earth, public domain). Disputed territories are assigned to no country: on the map and in detection both sides are offered for you to choose; this is not the author’s position. Coordinates stay in memory only, are never saved and never sent anywhere; the app has no network access. Detection is only a suggestion: nothing changes until you confirm, correct or mark transit.';

  @override
  String get titleOnboarding => 'Let’s start with you';

  @override
  String get titleSettings => 'Settings';

  @override
  String get titleArrivalDate => 'Arrival date';

  @override
  String get titleChangeCountry => 'Change of country';

  @override
  String get titleIncompleteRecord => 'Incomplete record';

  @override
  String get pickerMoveDate => 'Moving date';

  @override
  String get archiveArrivalNote =>
      'Arrival date set manually for an incomplete record.';

  @override
  String get confirmMoveTitle => 'Confirm the move?';

  @override
  String endsLine(String country) {
    return 'Ends: $country';
  }

  @override
  String get arrivalUnknownShort => 'Arrival unknown';

  @override
  String startsLine(String country) {
    return 'Starts: $country';
  }

  @override
  String fromDate(String date) {
    return 'From $date';
  }

  @override
  String get archiveStaysNote =>
      'The previous stay will remain in the archive without counted days.';

  @override
  String get moveDayBothNote =>
      'The moving day is included in both stays. Other records do not change.';

  @override
  String get confirmMove => 'Confirm move';

  @override
  String get saveFailedFormKept =>
      'Could not save. Your form data is kept and the journal is unchanged. Check free space and try saving again.';

  @override
  String get deleteIncompleteTitle => 'Delete the incomplete record?';

  @override
  String deleteIncompleteBody(String country) {
    return '$country. This record cannot be restored.';
  }

  @override
  String get anyCountryNameHelper => 'Any country name';

  @override
  String get countryRequired => 'Enter a country';

  @override
  String countryResolved(String name, String code) {
    return '$name · $code';
  }

  @override
  String get countryNoCode => 'Not in the country list: saved as entered text';

  @override
  String get onboardingHeadline => 'Your journal. Yours only.';

  @override
  String get onboardingIntro =>
      'No account, e-mail or tracking. Enter your home and current countries. If you don’t remember the arrival date, leave it empty.';

  @override
  String previousTripsKept(int count) {
    return 'Your previous trips are kept: $count.';
  }

  @override
  String get homeCountryHelper =>
      'A personal reference point, not tax residency. Changing this setting does not rewrite history.';

  @override
  String get newCountry => 'New country';

  @override
  String get recordCountry => 'Record country';

  @override
  String get currentCountry => 'Current country';

  @override
  String notBeforeNote(String date) {
    return 'After a confirmed move the date cannot be earlier than $date.';
  }

  @override
  String archiveDepartureNote(String date) {
    return 'Departure: $date. While the arrival is unknown, this record is not counted. The year filter cannot determine its start.';
  }

  @override
  String get moveLabel => 'Move';

  @override
  String get arrivalLabel => 'Arrival';

  @override
  String get dateUnknown => 'date unknown';

  @override
  String get dontRememberDate => 'I don’t remember';

  @override
  String get changeHint =>
      'The previous stay ends on the moving day. Before saving we will show both records for confirmation.';

  @override
  String get unknownDateHint =>
      'An unknown date is not replaced with today or 1 January. Without it, the duration and days of this stay are not counted.';

  @override
  String get checkMove => 'Review move';

  @override
  String get openDashboard => 'Open my dashboard';

  @override
  String get deleteIncomplete => 'Delete incomplete record';

  @override
  String get noBackupWarning =>
      'Uninstalling the app or clearing its data will lose your records — keep a backup.';

  @override
  String get openOldJournal => 'Open previous journal';

  @override
  String archiveCardLine(String date) {
    return 'Arrival unknown · departure $date';
  }

  @override
  String get archiveCardNote =>
      'Archive without counted days. The start is unknown, so the record is shown regardless of the year filter.';

  @override
  String get clarifyOrDelete => 'Clarify or delete';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageHelper =>
      'Applies immediately. Records and dates in the journal do not change.';

  @override
  String get themeTitle => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get autoDetectTitle => 'Check the country on opening';

  @override
  String get autoDetectHelper =>
      'When the app opens, it makes the same single approximate detection as the button — at most once an hour, only if permission is already granted, and without dialogs. A different country appears as a suggestion; nothing is recorded.';

  @override
  String get importSectionTitle => 'Google Maps history';

  @override
  String get importHelper =>
      'Phone Settings → Location → Timeline → Export Timeline data (or the same from Timeline in Google Maps). Open the resulting JSON file here: countries are matched offline against borders, coordinates are not stored and the file is not copied. Nothing is recorded without review and confirmation.';

  @override
  String get importPick => 'Import a Timeline file…';

  @override
  String get importTitle => 'Import from Google Maps';

  @override
  String get importAnalyzing => 'Reading the file…';

  @override
  String get importFailed =>
      'This is not a Google Maps Timeline file. You need the JSON file exported from Timeline — see the steps on the previous screen.';

  @override
  String get importNothing =>
      'No dated points inside countries were found in the file. Is it really a Google Maps Timeline export?';

  @override
  String importSummary(int points, int days, String first, String last) {
    return '$points points, $days days with data, $first — $last. Days without data stay unknown.';
  }

  @override
  String get importHomeHelper =>
      'Prefilled with the most frequent country in the history — please check.';

  @override
  String get importCurrentHelper =>
      'The country you are in now; prefilled from the last period.';

  @override
  String get importTransit => 'transit';

  @override
  String importGap(String days) {
    return 'no data inside: $days';
  }

  @override
  String get importStatusExists => 'already in the journal';

  @override
  String importStatusConflict(String country) {
    return 'overlaps a record: $country — adding will trim it';
  }

  @override
  String get importStatusCurrent => 'becomes the current stay';

  @override
  String importApply(String records) {
    return 'Add: $records';
  }

  @override
  String get importConfirmTitle => 'Add to the journal?';

  @override
  String importConfirmText(String records) {
    return 'To be added: $records. Existing records are not changed.';
  }

  @override
  String get importConfirmAction => 'Add';

  @override
  String importDone(String records) {
    return 'Added: $records';
  }

  @override
  String get importInvalid =>
      'The records did not pass validation. Check the home and current country.';

  @override
  String get importFootnote =>
      'Borders are approximate (1:50 m scale): right at a border the country may be wrong. Records can be edited in the journal.';

  @override
  String get onboardingHaveHistory => 'Already have a history?';

  @override
  String get onboardingRestore => 'Restore a Domiday backup';

  @override
  String get onboardingImport => 'Import from Google Maps';

  @override
  String get onboardingFresh => 'Or start from scratch:';

  @override
  String get backupTitle => 'Backup';

  @override
  String get backupHelper =>
      'A file with your whole history in the app’s format. Save it to Google Drive or Files, or send it to yourself — no copy is kept on the phone. Restoring replaces the whole current history.';

  @override
  String get backupSave => 'Save a backup…';

  @override
  String countryDaysLine(String yearDays, int year, String allDays) {
    return '$yearDays in $year · $allDays all time';
  }

  @override
  String get countryCalendarHint =>
      'Only this country\'s days are painted in the calendar. Tap a day to see every record for it.';

  @override
  String get countryRecords => 'Records';

  @override
  String get countryOpenJournal => 'Open in the journal';

  @override
  String get yearPrev => 'Previous year';

  @override
  String get yearNext => 'Next year';

  @override
  String get moreDetails => 'More';

  @override
  String get lessDetails => 'Hide';

  @override
  String get autoDetectShort =>
      'One approximate detection when the app opens, at most once an hour, no dialogs, nothing recorded.';

  @override
  String get backgroundShort =>
      'Every 2–3 hours, the same check with a notification if the country looks different. Needs “Allow all the time” and notifications.';

  @override
  String get backupShort =>
      'A file with your whole history. Keep it off the phone: no copy stays here.';

  @override
  String get importShort =>
      'Google Maps Timeline export (JSON): countries are matched offline, nothing is recorded without confirmation.';

  @override
  String get clearAllShort =>
      'Back to the first launch. Only a backup copy can bring things back.';

  @override
  String get datesFieldLabel => 'Dates *';

  @override
  String get pickerDates => 'Trip dates';

  @override
  String get quickToday => 'Today';

  @override
  String get quickYesterday => 'Yesterday';

  @override
  String get quickOneDay => 'One day';

  @override
  String get shareYear => 'Share the summary';

  @override
  String shareTitle(int year) {
    return '$year summary';
  }

  @override
  String get shareSend => 'Share';

  @override
  String get shareHint =>
      'The picture is made on the phone and goes only where you choose: the year’s totals and countries, no records or coordinates.';

  @override
  String get shareFooter =>
      'Personal travel journal · a moving day counts in both countries';

  @override
  String shareFailed(String error) {
    return 'Could not share: $error';
  }

  @override
  String get navToday => 'Today';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navMap => 'Map';

  @override
  String get navJournal => 'Journal';

  @override
  String get openCalendar => 'Open the calendar';

  @override
  String get onThisDayTitle => 'On this day';

  @override
  String onThisDayDay(int n, int total) {
    return 'Day $n of $total';
  }

  @override
  String get onThisDayAround => 'Around these days';

  @override
  String get onThisDayTransit => 'Transit';

  @override
  String get calendarFilter => 'Only this country’s days';

  @override
  String get reviewOpen => 'Year in review';

  @override
  String reviewTitle(int year) {
    return 'Your $year';
  }

  @override
  String reviewNudge(int year) {
    return 'Your $year in review is ready';
  }

  @override
  String reviewCountries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count countries',
      one: '$count country',
    );
    return '$_temp0';
  }

  @override
  String get reviewCountriesSub => 'with at least one stay this year';

  @override
  String reviewNewCountries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new countries',
      one: '$count new country',
      zero: 'No new countries',
    );
    return '$_temp0';
  }

  @override
  String get reviewDaysTitle => 'Days';

  @override
  String get reviewLongest => 'Longest trip';

  @override
  String get reviewNoTrips => 'No trips this year.';

  @override
  String get reviewMapTitle => 'Your map';

  @override
  String reviewCities(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cities',
      one: '$count city',
    );
    return '$_temp0';
  }

  @override
  String get reviewCitiesSub => 'from your records';

  @override
  String get reviewShareTitle => 'Share the year';

  @override
  String get reviewShareBody =>
      'A picture with the year, the days and the countries, made on the phone. It goes only where you choose.';

  @override
  String reviewThrough(String date) {
    return 'Through $date';
  }

  @override
  String get planToggle => 'Plan';

  @override
  String get planTripToggle => 'Trip';

  @override
  String get planNew => 'New plan';

  @override
  String get planYour => 'Trip plan';

  @override
  String get savePlan => 'Save plan';

  @override
  String get deletePlan => 'Delete plan';

  @override
  String get plansSection => 'Plans';

  @override
  String get planHint =>
      'A plan does not count in days or totals until you confirm it.';

  @override
  String planInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count days',
      one: 'in $count day',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String get planOngoing => 'planned for these days';

  @override
  String get planOverdue => 'dates passed, not confirmed';

  @override
  String get nextTrip => 'Next trip';

  @override
  String planArrivedTitle(String place) {
    return 'Planned for today: $place. Are you there?';
  }

  @override
  String get planYes => 'Yes, I am there';

  @override
  String get planNo => 'Not yet';

  @override
  String get planAddAsTrip => 'Add as a trip';

  @override
  String planOverdueTitle(String place) {
    return '$place: the dates have passed';
  }

  @override
  String get planOverdueBody =>
      'Nothing was recorded. Add it as a trip, or edit the plan.';

  @override
  String get mapTitle => 'Country map';

  @override
  String mapCount(int visited, int total) {
    return '$visited of $total';
  }

  @override
  String get mapAllTime => 'All time';

  @override
  String get mapCountries => 'Countries';

  @override
  String get mapPick => 'Which country?';

  @override
  String get mapNotVisited => 'no records';

  @override
  String get mapLegendVisited => 'visited';

  @override
  String get mapLegendTransit => 'transit only';

  @override
  String get mapLegendDisputed => 'disputed territory';

  @override
  String get mapNote => 'Borders by Natural Earth.';

  @override
  String get mapShare => 'Share the map';

  @override
  String get mapFullscreen => 'Full screen';

  @override
  String get mapSearch => 'Find a country';

  @override
  String get mapSearchHint => 'Country name';

  @override
  String get mapViewFlat => 'Flat map';

  @override
  String get mapViewGlobe => 'Globe';

  @override
  String get mapShareTitleAll => 'My countries';

  @override
  String mapShareTitleYear(int year) {
    return 'My countries · $year';
  }

  @override
  String backupLast(String date) {
    return 'Last copy: $date';
  }

  @override
  String get backupNever => 'No copy saved yet.';

  @override
  String get backupNudgeTitle => 'Time to save a copy';

  @override
  String backupNudgeBody(String date) {
    return 'Your records live only on this phone. Last copy: $date.';
  }

  @override
  String get backupNudgeBodyNever =>
      'Your records live only on this phone, and there is no copy yet.';

  @override
  String get backupNudgeLater => 'Later';

  @override
  String get clearAllTitle => 'Clear everything';

  @override
  String get clearAllHelper =>
      'Deletes all records, the archive, home country, current stay and settings — the app returns to its first launch. Only a backup copy can bring them back.';

  @override
  String get clearAllButton => 'Clear everything…';

  @override
  String get clearAllConfirmTitle => 'Clear everything?';

  @override
  String clearAllConfirmBody(String records) {
    return '$records, the archive, home country, current stay and all settings will be deleted. Only a backup copy can bring them back.';
  }

  @override
  String get clearAllBackupFirst => 'Save a copy first…';

  @override
  String get clearAllAction => 'Delete everything';

  @override
  String get clearAllDone => 'Everything cleared';

  @override
  String clearAllFailed(String error) {
    return 'Could not clear: $error';
  }

  @override
  String get backupRestore => 'Restore from a backup…';

  @override
  String backupSaved(String name) {
    return 'Backup saved: $name';
  }

  @override
  String get backupSaveFailed =>
      'Could not write the file. Try another folder.';

  @override
  String backupTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips',
      one: '$count trip',
    );
    return '$_temp0';
  }

  @override
  String get backupRestoreTitle => 'Restore from backup?';

  @override
  String backupRestoreConfirm(
    String name,
    String trips,
    String date,
    String version,
    String current,
  ) {
    return '$name: $trips, created $date, Domiday $version. The current history ($current) will be replaced entirely.';
  }

  @override
  String get backupRestoreAction => 'Replace history';

  @override
  String backupRestored(String trips) {
    return 'History restored: $trips';
  }

  @override
  String get backupUnknownDate => 'unknown date';

  @override
  String get backupErrorTitle => 'Cannot restore';

  @override
  String get backupErrorNotBackup => 'This is not a Domiday backup file.';

  @override
  String get backupErrorNewer =>
      'This backup was made by a newer Domiday. Update the app; the current history is untouched.';

  @override
  String get backupErrorCorrupt =>
      'The file is damaged or contains invalid records. The current history is untouched.';

  @override
  String get backgroundTitle => 'Check in the background';

  @override
  String get backgroundHelper =>
      'Every 2–3 hours and when the phone comes back online, the app checks the country the same way — and only sends a notification if it looks like a different country. Nothing is recorded without your confirmation. Needs the “Allow all the time” location permission and notifications; Samsung may pause background work for “sleeping” apps.';

  @override
  String get backgroundNeedsAlways =>
      'Android grants “all the time” location only in its settings. Open the app settings, choose Permissions → Location → Allow all the time, then return to Domiday — it will turn on by itself.';

  @override
  String get backgroundNeedsNotifications =>
      'Notifications are off for Domiday. Allow them in the app settings, otherwise the background check has no way to reach you.';

  @override
  String get openAppSettings => 'Open app settings';

  @override
  String get backgroundStatusOn => 'Background check is on';

  @override
  String get backgroundStatusOff => 'Background check is off';

  @override
  String get backgroundStatusWaiting =>
      'Waiting for permissions — it will turn on by itself once “Allow all the time” and notifications are granted';

  @override
  String get backgroundNeverRan => 'No background check has run yet';

  @override
  String backgroundLastRun(String when, String result) {
    return 'Last check: $when — $result';
  }

  @override
  String get backgroundOutcomeNotified => 'notification sent';

  @override
  String get backgroundOutcomeSame =>
      'same country, or the suggestion was already dismissed';

  @override
  String get backgroundOutcomeAlreadyNotified => 'already notified';

  @override
  String get backgroundOutcomeNoLocation => 'no location obtained';

  @override
  String get backgroundOutcomeNoCountry => 'country not determined';

  @override
  String get backgroundOutcomeNoProfile => 'current country not set';

  @override
  String get backgroundOutcomeError => 'error';

  @override
  String backgroundErrorDetail(String text) {
    return 'Error: $text';
  }

  @override
  String get backgroundLogTitle => 'Recent runs:';

  @override
  String get backgroundRunNow => 'Run a check now';

  @override
  String get backgroundRunNowStarted =>
      'Check started in the background. Leave the app for a minute and come back — the result appears in the “Last check” line.';

  @override
  String get backgroundTestNotification => 'Test notification';

  @override
  String get backgroundTestTitle => 'Domiday notifications work';

  @override
  String get backgroundTestBody =>
      'If you can see this, the channel, icon and permission are fine.';

  @override
  String get backgroundBatteryOk => 'Battery: background is unrestricted.';

  @override
  String get backgroundHowToAlways =>
      'How to grant it: Android Settings → Apps → Domiday → Permissions → Location → “Allow all the time”. If notifications are off, enable them there too. Then return to Domiday — it will turn on by itself.';

  @override
  String backgroundEnableFailed(String error) {
    return 'Could not enable: $error';
  }

  @override
  String get backgroundNotificationsOffLine =>
      'Domiday notifications are off: the check runs, but there is no way to reach you. Allow them in the app settings.';

  @override
  String get backgroundBatteryRestricted =>
      'Battery: the system restricts Domiday in the background — checks may not run. Open the app settings → Battery → “Unrestricted”.';

  @override
  String notificationTitle(String country) {
    return 'It looks like you are in $country';
  }

  @override
  String get notificationBody =>
      'Open Domiday to confirm, correct or dismiss. Nothing is recorded until you do.';

  @override
  String get notificationChannel => 'Country detection';

  @override
  String get notificationChannelDescription =>
      'Suggestions after a background country check';

  @override
  String get gapsTitle => 'Gaps in history';

  @override
  String get gapsDone => 'Days added to the journal';

  @override
  String get gapsCheckFirst => 'Check the dates first';

  @override
  String gapsYearHome(int year, String home) {
    return 'Year: $year. Home country: $home.';
  }

  @override
  String get gapsExplain =>
      'These are unknown days between known stays, not proof that you were home. Unrecorded periods at the start and end are not offered. Recorded days are not affected.';

  @override
  String get gapsNone =>
      'There are no gaps between known stays this year. Other days of the year may still be unknown.';

  @override
  String gapsTotal(String days, int count) {
    return 'Total: $days · records: $count';
  }

  @override
  String get gapsDoneNote =>
      'Each record can be edited or deleted in the journal. The note says the gap was confirmed by you manually.';

  @override
  String gapsConfirmNote(String home) {
    return 'By confirming you state that on ALL these dates you were in “$home”. If not, go back and add separate trips manually.';
  }

  @override
  String get gapsConfirmButton => 'I confirm: I was home on these days';

  @override
  String get gapsCancel => 'Cancel — add nothing';

  @override
  String get gapsSaveFailed =>
      'Could not save. The journal is unchanged. If the date or records changed, go back and open the preview again.';

  @override
  String gapFillNote(int year, String home) {
    return 'Added manually after confirming a gap in $year. Home country: $home. This is your confirmation, not automatic detection.';
  }

  @override
  String get chooseCountry => 'Choose a country';

  @override
  String get chooseYear => 'Choose a year';

  @override
  String get allCountries => 'All countries';

  @override
  String get allYears => 'All years';

  @override
  String get journalTitle => 'When and where you were';

  @override
  String get journalSubtitle => 'Your travels, gathered in one place.';

  @override
  String get addTrip => 'Add trip';

  @override
  String get searchLabel => 'Find a trip';

  @override
  String get searchHint => 'Country, city, note or year';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get reset => 'Reset';

  @override
  String foundTrips(int count) {
    return 'Trips found: $count';
  }

  @override
  String get tripHistory => 'Trip history';

  @override
  String get noSuchRecords => 'No such records yet.';

  @override
  String get tryAnotherWord => 'Try another word or reset the filters.';

  @override
  String get resetFilters => 'Reset filters';

  @override
  String get bySelectedTrips => 'By selected trips';

  @override
  String get byYourRecordsOnly => 'Only by your records';

  @override
  String countryStatLine(String country, String days, int trips) {
    return '$country  ·  $days  ·  trips: $trips';
  }

  @override
  String get moveDayNotVisa =>
      'A moving day may count in two countries. This is not a visa or tax calculation.';

  @override
  String journalFooter(String version) {
    return 'Personal journal · $version';
  }

  @override
  String get emptyTitle => 'Which trip shall we start with?';

  @override
  String get emptyBody =>
      'Recall one journey and save the country and dates. A city and a short note will help you return to the memories.';

  @override
  String get emptyNote =>
      'No records yet. Everything is entered by hand and stored only on this device.';

  @override
  String get yourJournalInNumbers => 'Your journal in numbers';

  @override
  String get daysInRecordedTrips => 'Days in recorded trips';

  @override
  String get bothDatesIncluded =>
      'Both dates are included. Overlapping days count once.';

  @override
  String daysOnlyInYear(int year) {
    return 'Days — only in $year.';
  }

  @override
  String wholeTrip(String days) {
    return '$days · Whole trip';
  }

  @override
  String get openAndEdit => 'Open and edit';

  @override
  String get currentStayOngoing => 'Current stay · ongoing';

  @override
  String get pickerArrival => 'Arrival date';

  @override
  String get pickerDeparture => 'Departure date';

  @override
  String get errorPickBothDates => 'Choose the arrival and departure dates';

  @override
  String get tripSaved => 'Trip saved';

  @override
  String get overlapTitle => 'Days already taken';

  @override
  String overlapIntro(String range) {
    return '$range: these days are already in the journal. One shared day at the junction is a moving day and is fine; here the overlap is longer.';
  }

  @override
  String overlapTrim(String country, String range, String next) {
    return '$country, $range: becomes $next';
  }

  @override
  String overlapSplit(
    String country,
    String range,
    String first,
    String second,
  ) {
    return '$country, $range: splits into $first and $second';
  }

  @override
  String overlapRemove(String country, String range) {
    return '$country, $range: will be deleted';
  }

  @override
  String overlapCurrent(String country, String date) {
    return 'Current stay, $country: will start on $date';
  }

  @override
  String overlapCurrentFixed(String country) {
    return 'Current stay, $country: overlaps and cannot be changed here — set its arrival date on the “Now” card first';
  }

  @override
  String overlapSameCountry(String country) {
    return '$country (same country)';
  }

  @override
  String get overlapHint =>
      '“Replace” trims or deletes the listed records as described. “Keep both” saves as is: the days count in both.';

  @override
  String get overlapHintKeepOnly =>
      '“Keep both” saves as is: the days count in both.';

  @override
  String get overlapReplace => 'Replace';

  @override
  String get overlapKeep => 'Keep both';

  @override
  String get tripSaveFailed =>
      'Could not save. The form data stayed on screen. Check free space and press “Save trip” again.';

  @override
  String get deleteTripTitle => 'Delete the trip?';

  @override
  String get deleteTripBody =>
      'The record cannot be restored in this prototype.';

  @override
  String get tripDeleted => 'Trip deleted';

  @override
  String get tripDeleteFailed =>
      'Could not delete the record. It remains in the journal. Try deleting it again.';

  @override
  String get newTrip => 'New trip';

  @override
  String get yourTrip => 'Your trip';

  @override
  String get tripFormIntro =>
      'Record a completed trip. Both dates are required and not later than today. The arrival and departure days are included.';

  @override
  String get countryFieldLabel => 'Country *';

  @override
  String get countryFieldHelper => 'Any country can be entered';

  @override
  String get cityLabel => 'City';

  @override
  String get arrivalFieldLabel => 'Arrival *';

  @override
  String get departureFieldLabel => 'Departure *';

  @override
  String get noteLabel => 'Note';

  @override
  String get noteHint => 'What do you want to remember?';

  @override
  String get saveTrip => 'Save trip';

  @override
  String get deleteTrip => 'Delete trip';

  @override
  String get chooseDate => 'Choose a date';

  @override
  String get aboutTagline =>
      'A private travel journal. It counts your days by country, shows the year in a calendar and on a map, and remembers where you were. Everything stays on your phone.';

  @override
  String get aboutFeaturesTitle => 'What it does';

  @override
  String get aboutFeatCalendar =>
      'Year calendar: every day painted with its country colour; transit and a day in two countries are marked separately.';

  @override
  String get aboutFeatMap =>
      'Country map and a rotating globe: visited countries in political-map colours, search that flies to a country.';

  @override
  String get aboutFeatJournal =>
      'Journal with search by country, city, note and year; a page for every country.';

  @override
  String get aboutFeatPlans =>
      'Trip plans: future dates show in the calendar but do not count until you confirm the trip.';

  @override
  String get aboutFeatReview =>
      'Year in review: countries and new countries, days, the longest trip, the map, cities, a picture to share.';

  @override
  String get aboutFeatOnThisDay =>
      '“On this day”: where you were on this date in past years.';

  @override
  String get aboutFeatImport =>
      'Google Maps Timeline import: countries are matched offline, you add only the periods you want.';

  @override
  String get aboutFeatDetect =>
      'Country detection on your tap and when the app opens: a suggestion that you confirm.';

  @override
  String get aboutFeatBackup =>
      'Backup as a single file, restore, “Clear everything” with confirmation.';

  @override
  String get aboutContactTitle => 'Contact';

  @override
  String get aboutContactEmail => 'Questions by email';

  @override
  String get aboutContactSite =>
      'Feature requests and bug reports on the website';

  @override
  String get aboutContactNote =>
      'The email and the website open in other apps. The app itself never goes online.';

  @override
  String aboutOpenFailed(String url) {
    return 'Could not open $url: no app can handle it.';
  }

  @override
  String get aboutCreditsTitle => 'Credits and licences';

  @override
  String get aboutCreditsBody =>
      'Country borders: Natural Earth, public domain. Flags: the flag-icons set, MIT licence. Fonts: Manrope (SIL Open Font License) and Roboto (Apache 2.0). Built with Flutter (BSD).';

  @override
  String get aboutCopyright => '© 2026 Domiday. All rights reserved.';

  @override
  String get aboutNoWarranty =>
      'The app is provided as is, without warranty. It does not determine residency, entry eligibility or visa limits.';

  @override
  String get aboutTitle => 'About Domiday';

  @override
  String aboutVersion(String version) {
    return 'Personal journal · $version';
  }

  @override
  String get aboutPlaceTitle => 'Current place and history';

  @override
  String get aboutPlaceBody =>
      'A manual journal of trips and of where you are now. It answers “when and where were we” and never changes anything by itself: every record, date and country is entered or confirmed by you.';

  @override
  String get aboutUnknownTitle => 'Unknown does not mean home';

  @override
  String get aboutUnknownBody =>
      'The home country is your personal setting, not tax residency. Changing it recalculates the categories but does not change the records. Without an arrival date the current stay adds no days to the totals. Unknown days are counted from 1 January to today, and for past years — for the whole year. Gaps between known stays can be recorded as days at home only after reviewing the dates and your confirmation. Those records can be edited or deleted in the journal.';

  @override
  String get aboutDeviceTitle => 'Your records stay on your device';

  @override
  String get aboutDeviceBody =>
      'Data is stored in the app’s private folder. There is no account, cloud, network requests, ads or analytics. A backup — a file in the app’s format — can be saved and restored from Settings. Uninstalling the app or clearing its data will lose the records. Do not keep the only copy of important information here.';

  @override
  String get aboutCountingTitle => 'How days are counted';

  @override
  String get aboutCountingBody =>
      'The arrival and departure days are included: a one-day trip is one day. Overlapping records do not increase the total. Within one country overlapping days also count once. A moving day may belong to two countries, so the sum by country may exceed the total number of days. With a year selected, only days in that year are counted; cards keep the full trip dates. Searching by year finds trips that touch it but does not trim dates by itself.';

  @override
  String get aboutNotVisaTitle => 'Not a visa or tax calculator';

  @override
  String get aboutNotVisaBody =>
      'The totals describe only the entered records, not your whole history of stays. A missed trip is unknown history, not proof of absence from a country. The journal does not determine residency, the right to enter or compliance with visa limits.';

  @override
  String get errMissingId => 'The record has no identifier';

  @override
  String get errCountryRequired => 'Enter a country';

  @override
  String get errTextTooLong => 'The text is too long';

  @override
  String get errDepartureBeforeArrival =>
      'The departure date cannot be earlier than the arrival date';

  @override
  String get errFutureTrip =>
      'Only past trips can be recorded, not future dates';

  @override
  String get errInvalidTrip => 'Invalid trip record';

  @override
  String get errSameCountry => 'Choose a different country';

  @override
  String errMoveDateRange(String from, String to) {
    return 'The moving date must be between $from and $to. For earlier history use the journal.';
  }

  @override
  String get errCountryLength => 'Enter a country: 1 to 120 characters';

  @override
  String get errYearRange => 'Choose a past or the current year';

  @override
  String get errPreviewStale => 'The data changed. Open the preview again.';

  @override
  String get errHomeCountryFirst => 'Set the home country first';

  @override
  String get errMoveDateRequired => 'Enter the moving date';

  @override
  String get detectOffTitle => 'Country detection is off';

  @override
  String get detectOffDenied =>
      'Domiday has no location permission, so it can’t notice when you cross a border. Days are counted anyway — you just change the country yourself.';

  @override
  String get detectOffService =>
      'Location is turned off on this phone, so Domiday can’t notice when you cross a border. Days are counted anyway — you just change the country yourself.';

  @override
  String get detectOffEnable => 'Turn on';

  @override
  String get detectOffDismiss => 'Not needed';

  @override
  String get countsItself =>
      'Days count on their own — just tell Domiday when you change country.';

  @override
  String get importIntroLead =>
      'Domiday can fill your journal from Google Maps Timeline. It takes three steps:';

  @override
  String get importStep1 =>
      'Export Timeline on your phone: Settings → Location → Location services → Timeline → Export Timeline data. Or in Google Maps: your avatar → Your Timeline → ⋮ → Location & privacy settings → Export Timeline data. Menu names differ slightly between phones.';

  @override
  String get importStep2 =>
      'Save the file, for example to Downloads. It is usually called Timeline.json.';

  @override
  String get importStep3 =>
      'Come back here and tap “Choose file”. Countries are matched offline, coordinates are not stored, and nothing is recorded until you review and confirm.';

  @override
  String get importNoTimeline =>
      'If Timeline was never turned on, there is nothing to export — then add trips by hand in the journal.';

  @override
  String get importChoose => 'Choose file';

  @override
  String get importAnyFile => 'File not in the list? Show all files';

  @override
  String get importOtherFile => 'Choose another file';

  @override
  String get mapHintAll =>
      'Countries you have been to are coloured. Tap a country to see its days.';

  @override
  String mapHintYear(int year) {
    return 'Countries you visited in $year are coloured. Tap a country to see its days.';
  }

  @override
  String get mapEmpty =>
      'Countries you have been to will be coloured here. Add trips in the journal or import your history from Google Maps.';

  @override
  String get feedbackTitle => 'Feedback and suggestions';

  @override
  String get feedbackBody =>
      'Found a bug, or something is missing? Write to me: I read every message and keep improving the app. The site or your mail app opens in a separate window; Domiday itself never goes online.';

  @override
  String get feedbackSite => 'Write on the website';

  @override
  String get feedbackSiteHint => 'Feedback form, no sign-up';

  @override
  String get feedbackEmail => 'Write by email';

  @override
  String feedbackMailSubject(String version) {
    return 'Domiday $version: feedback';
  }
}
