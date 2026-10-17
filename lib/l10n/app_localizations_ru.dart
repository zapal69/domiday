// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get back => 'Назад';

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get choose => 'Выбрать';

  @override
  String get save => 'Сохранить';

  @override
  String get saving => 'Сохраняем…';

  @override
  String get done => 'Готово';

  @override
  String get stay => 'Остаться';

  @override
  String get leave => 'Выйти';

  @override
  String get leaveWithoutSaving => 'Выйти без сохранения?';

  @override
  String get unsavedChanges => 'Изменения этой формы не будут сохранены.';

  @override
  String get localOnlyNoBackup =>
      'Только на этом устройстве. Резервная копия — в настройках.';

  @override
  String get aboutTooltip => 'О дневнике';

  @override
  String get settingsTooltip => 'Настройки';

  @override
  String get journalTooltip => 'Журнал';

  @override
  String daysCompact(int count) {
    return '$count дн.';
  }

  @override
  String daysFull(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дней',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String recordsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count записей',
      many: '$count записей',
      few: '$count записи',
      one: '$count запись',
    );
    return '$_temp0';
  }

  @override
  String tripsCount(int count) {
    return 'Поездок: $count';
  }

  @override
  String countriesCount(int count) {
    return 'Стран: $count';
  }

  @override
  String get loadFailedTitle => 'Не удалось открыть дневник';

  @override
  String get loadFailedBody =>
      'Файл недоступен, повреждён или создан другой версией приложения. Мы не заменяли его пустым дневником. Изменения отключены. Не удаляйте приложение и не очищайте данные.';

  @override
  String get retryOpen => 'Повторить открытие';

  @override
  String todayLine(String date) {
    return 'Сегодня · $date';
  }

  @override
  String yearSummaryButton(int year) {
    return 'Итоги за $year';
  }

  @override
  String periodLine(String from, String to, String days) {
    return '$from — $to · $days';
  }

  @override
  String get methodologyLine =>
      'Неизвестно — не значит дома. День переезда учитывается в обеих странах, а в известных днях — один раз.';

  @override
  String get byCountry => 'По странам';

  @override
  String get shareOfKnownDays => 'доля известных дней';

  @override
  String get noCountryData =>
      'Пока нет дат для расчёта. Неизвестные дни не относятся ни к одной стране.';

  @override
  String get recentTrips => 'Последние поездки';

  @override
  String get noCompletedTrips =>
      'Завершённых поездок с датами пока нет. Их можно добавить в журнале.';

  @override
  String get allJournalAndArchive => 'Весь журнал и архив';

  @override
  String get homeCountry => 'Домашняя страна';

  @override
  String countryShareSemantics(String country, int days, int percent) {
    return '$country: $days дней, $percent % известных';
  }

  @override
  String get nowStayEyebrow => 'СЕЙЧАС';

  @override
  String get arrivalUnknown => 'Дата приезда неизвестна';

  @override
  String get noDateNoDays =>
      'Без даты это пребывание не добавляет дней в итоги.';

  @override
  String sinceArrivalLine(String date) {
    return 'С $date, включая день приезда и сегодня.';
  }

  @override
  String get changeCountry => 'Сменить страну';

  @override
  String get arrivalDate => 'Дата приезда';

  @override
  String get dateShort => 'Дата';

  @override
  String get tileKnown => 'Известно';

  @override
  String tileKnownSub(int total) {
    return 'из $total в периоде';
  }

  @override
  String get tileHome => 'Дома';

  @override
  String get tileAway => 'Вне дома';

  @override
  String tileAwaySub(int count) {
    return 'пересечений с домом: $count';
  }

  @override
  String get tileUnknown => 'Неизвестно';

  @override
  String get checkGaps => 'Проверить пробелы';

  @override
  String get daysUnit => 'дн.';

  @override
  String get monthsShort => 'янв,фев,мар,апр,май,июн,июл,авг,сен,окт,ноя,дек';

  @override
  String calendarSemantics(int year, int home, int away, int unknown) {
    return 'Календарь $year: дома $home дн., вне дома $away дн., неизвестно $unknown дн.';
  }

  @override
  String get legendHome => 'дома';

  @override
  String get legendAway => 'вне дома';

  @override
  String get legendUnknown => 'неизвестно';

  @override
  String get legendBoth => 'день в двух странах';

  @override
  String get legendTransit => 'транзит';

  @override
  String get legendOther => 'другие страны';

  @override
  String get legendFuture => 'ещё не наступил';

  @override
  String get calendarMonthHint =>
      'Нажмите на месяц, чтобы раскрыть; на день — карточка дня.';

  @override
  String get calendarCollapse => 'Свернуть';

  @override
  String get monthsFull =>
      'Январь,Февраль,Март,Апрель,Май,Июнь,Июль,Август,Сентябрь,Октябрь,Ноябрь,Декабрь';

  @override
  String get weekdaysShort => 'пн,вт,ср,чт,пт,сб,вс';

  @override
  String get kindStay => 'Пребывание';

  @override
  String get kindTransit => 'Транзит';

  @override
  String get kindTransitHint =>
      'Пересадка или проезд: дни считаются известными и днями этой страны, но помечаются отдельно.';

  @override
  String transitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count транзитов',
      many: '$count транзитов',
      few: '$count транзита',
      one: '$count транзит',
    );
    return '$_temp0';
  }

  @override
  String transitCalendarSemantics(int count) {
    return 'транзит в $count дн.';
  }

  @override
  String get dayCardEmpty => 'Нет данных за этот день';

  @override
  String get dayCardCurrent => 'Текущее пребывание';

  @override
  String get dayCardHint =>
      'Нажмите на запись, чтобы открыть её. Просмотр ничего не меняет.';

  @override
  String dayCardSemantics(String date, int count) {
    return 'День $date: записей $count';
  }

  @override
  String transitToday(String country) {
    return 'Транзит сегодня: $country';
  }

  @override
  String wholeTransit(String days) {
    return '$days · Транзит';
  }

  @override
  String get newTransit => 'Новый транзит';

  @override
  String get yourTransit => 'Ваш транзит';

  @override
  String get transitFormIntro =>
      'Запишите пересадку или проезд. Одна дата или диапазон, если через полночь. Город или аэропорт необязательны; время не записывается.';

  @override
  String get detectNow => 'Определить страну сейчас';

  @override
  String get detectBusy => 'Определяем…';

  @override
  String detectSame(String country) {
    return 'Вы там же: $country. Ничего не изменилось.';
  }

  @override
  String get detectNone =>
      'Не удалось определить страну по координатам (море или место вне карты). Журнал не изменён.';

  @override
  String get detectDenied =>
      'Нет разрешения на приблизительное местоположение. Разрешите его в настройках Android или продолжайте вести журнал вручную.';

  @override
  String get detectServiceOff =>
      'Геолокация на телефоне выключена. Включите её или продолжайте вести журнал вручную.';

  @override
  String get detectFailed =>
      'Не удалось получить координаты (нет сигнала или истекло время). Попробуйте позже; журнал не изменён.';

  @override
  String detectSilenced(int days) {
    return 'Это определение вы уже отклонили. Оно будет предложено снова через $days дней или при смене страны.';
  }

  @override
  String candidateTitle(String country) {
    return 'Похоже, вы сейчас здесь: $country';
  }

  @override
  String candidateUncertain(String alternatives) {
    return 'Рядом граница или побережье: возможны также $alternatives. Проверьте сами.';
  }

  @override
  String get candidateUncertainNoAlt =>
      'Точка вне границ карты (побережье или море); показана ближайшая страна. Проверьте сами.';

  @override
  String candidateDetected(String date, String km) {
    return 'Обнаружено $date, точность около $km км. Это не дата въезда.';
  }

  @override
  String get candidateNoRecord =>
      'Пока вы не подтвердите, текущая страна, календарь и итоги не меняются. Дату въезда вы выберете на следующем экране; по умолчанию это день обнаружения.';

  @override
  String get candidateConfirm => 'Подтвердить переезд';

  @override
  String get candidateCorrect => 'Исправить страну';

  @override
  String get candidateTransit => 'Это был транзит';

  @override
  String get candidateDismiss => 'Это ошибка';

  @override
  String candidateDismissed(int days) {
    return 'Определение отклонено. Журнал не изменён; та же страна не будет предлагаться $days дней.';
  }

  @override
  String candidateBanner(String country) {
    return 'Похоже, вы здесь: $country';
  }

  @override
  String get candidateHint =>
      'По приблизительному положению. Пока это только предположение.';

  @override
  String get candidateYes => 'Да';

  @override
  String get candidateNo => 'Нет';

  @override
  String get detectHint =>
      'Приложение может подсказать, где вы, по приблизительному положению.';

  @override
  String get detectShort => 'Проверить';

  @override
  String get journalNow => 'сейчас';

  @override
  String get candidateReview => 'Проверить';

  @override
  String get detectTitle => 'Определение страны';

  @override
  String autoStatus(String time, String result) {
    return 'Автопроверка $time · $result';
  }

  @override
  String get autoStatusSame => 'страна совпадает';

  @override
  String get autoStatusPending => 'есть предложение';

  @override
  String get autoStatusDenied => 'нет разрешения на геолокацию';

  @override
  String get autoStatusOff => 'геолокация выключена';

  @override
  String get autoStatusFailed => 'координаты не получены';

  @override
  String get autoStatusNone => 'страна не определена';

  @override
  String get autoStatusSilenced => 'отклонено ранее';

  @override
  String seriesLine(String date) {
    return 'С $date — непрерывно по вашим записям.';
  }

  @override
  String get aboutDetectTitle => 'Определение страны';

  @override
  String get aboutDetectBody =>
      'По кнопке, при открытии приложения и, только если вы сами включили «Проверять в фоне», фоновой задачей приложение один раз запрашивает у Android приблизительное местоположение и сопоставляет его с границами стран, хранящимися в приложении (Natural Earth, общественное достояние). Спорные территории не приписываются ни одной стране: и на карте, и при определении предлагаются обе стороны на ваш выбор; это не позиция автора. Координаты остаются только в памяти, не сохраняются и никуда не отправляются; у приложения нет доступа к сети. Определение — лишь предположение: ничего не меняется, пока вы не подтвердите, не исправите или не отметите транзит.';

  @override
  String get titleOnboarding => 'Начнём с вас';

  @override
  String get titleSettings => 'Настройки';

  @override
  String get titleArrivalDate => 'Дата приезда';

  @override
  String get titleChangeCountry => 'Смена страны';

  @override
  String get titleIncompleteRecord => 'Неполная запись';

  @override
  String get pickerMoveDate => 'Дата переезда';

  @override
  String get archiveArrivalNote =>
      'Дата приезда уточнена вручную для неполной записи.';

  @override
  String get confirmMoveTitle => 'Подтвердить переезд?';

  @override
  String endsLine(String country) {
    return 'Завершится: $country';
  }

  @override
  String get arrivalUnknownShort => 'Приезд неизвестен';

  @override
  String startsLine(String country) {
    return 'Начнётся: $country';
  }

  @override
  String fromDate(String date) {
    return 'С $date';
  }

  @override
  String get archiveStaysNote =>
      'Предыдущее пребывание останется в архиве без расчёта дней.';

  @override
  String get moveDayBothNote =>
      'День переезда включён в оба пребывания. Другие записи не изменятся.';

  @override
  String get confirmMove => 'Подтвердить переезд';

  @override
  String get saveFailedFormKept =>
      'Не удалось сохранить. Данные формы не потеряны, дневник не изменён. Проверьте свободное место и повторите сохранение.';

  @override
  String get deleteIncompleteTitle => 'Удалить неполную запись?';

  @override
  String deleteIncompleteBody(String country) {
    return '$country. Восстановить запись не получится.';
  }

  @override
  String get anyCountryNameHelper => 'Любое название страны';

  @override
  String get countryRequired => 'Укажите страну';

  @override
  String countryResolved(String name, String code) {
    return '$name · $code';
  }

  @override
  String get countryNoCode =>
      'Нет в списке стран: сохранится как введённый текст';

  @override
  String get onboardingHeadline => 'Ваш дневник. Только ваш.';

  @override
  String get onboardingIntro =>
      'Без аккаунта, почты и отслеживания. Укажите домашнюю и текущую страны. Если не помните дату приезда, оставьте её пустой.';

  @override
  String previousTripsKept(int count) {
    return 'Ваши прежние поездки сохранены: $count.';
  }

  @override
  String get homeCountryHelper =>
      'Личная точка отсчёта, не налоговое резидентство. Изменение этой настройки не переписывает историю.';

  @override
  String get newCountry => 'Новая страна';

  @override
  String get recordCountry => 'Страна записи';

  @override
  String get currentCountry => 'Текущая страна';

  @override
  String notBeforeNote(String date) {
    return 'После подтверждённого переезда дата не может быть раньше $date.';
  }

  @override
  String archiveDepartureNote(String date) {
    return 'Выезд: $date. Пока приезд неизвестен, запись не участвует в подсчёте дней. Фильтр года не может определить её начало.';
  }

  @override
  String get moveLabel => 'Переезд';

  @override
  String get arrivalLabel => 'Приезд';

  @override
  String get dateUnknown => 'дата неизвестна';

  @override
  String get dontRememberDate => 'Не помню дату';

  @override
  String get changeHint =>
      'Предыдущее пребывание завершится в день переезда. Перед сохранением покажем обе записи для подтверждения.';

  @override
  String get unknownDateHint =>
      'Неизвестная дата не заменяется сегодняшней или 1 января. Без неё длительность и дни этого пребывания не считаются.';

  @override
  String get checkMove => 'Проверить переезд';

  @override
  String get openDashboard => 'Открыть мой дашборд';

  @override
  String get deleteIncomplete => 'Удалить неполную запись';

  @override
  String get noBackupWarning =>
      'Удаление приложения или очистка его данных приведут к потере записей — сохраняйте резервную копию.';

  @override
  String get openOldJournal => 'Открыть прежний журнал';

  @override
  String archiveCardLine(String date) {
    return 'Приезд неизвестен · выезд $date';
  }

  @override
  String get archiveCardNote =>
      'Архив без расчёта дней. Начало неизвестно, поэтому запись показана независимо от фильтра года.';

  @override
  String get clarifyOrDelete => 'Уточнить или удалить';

  @override
  String get language => 'Язык';

  @override
  String get languageSystem => 'Системный';

  @override
  String get languageHelper =>
      'Применяется сразу. Записи и даты в журнале не меняются.';

  @override
  String get themeTitle => 'Тема';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get autoDetectTitle => 'Проверять страну при открытии';

  @override
  String get autoDetectHelper =>
      'При открытии приложение делает то же одно приблизительное определение, что и кнопка, — не чаще раза в час, только если разрешение уже дано, и без диалогов. Другая страна появится предложением; ничего не записывается.';

  @override
  String get importSectionTitle => 'История Google Maps';

  @override
  String get importHelper =>
      'Настройки телефона → Местоположение → Хронология → «Экспортировать данные Хронологии» (или то же из Хронологии в Google Maps). Откройте полученный JSON-файл здесь: страны определяются офлайн по границам, координаты не сохраняются, файл не копируется. Ничего не записывается без просмотра и подтверждения.';

  @override
  String get importPick => 'Импортировать файл Хронологии…';

  @override
  String get importTitle => 'Импорт из Google Maps';

  @override
  String get importAnalyzing => 'Разбираем файл…';

  @override
  String get importFailed =>
      'Это не файл Хронологии Google Maps. Нужен JSON-файл, экспортированный из Хронологии, — шаги на предыдущем экране.';

  @override
  String get importNothing =>
      'В файле не нашлось точек с датами и координатами внутри стран. Это точно экспорт Хронологии Google Maps?';

  @override
  String importSummary(int points, int days, String first, String last) {
    return 'Точек: $points, дней с данными: $days, период $first — $last. Дни без данных остаются неизвестными.';
  }

  @override
  String get importHomeHelper =>
      'Предзаполнено самой частой страной в истории — проверьте.';

  @override
  String get importCurrentHelper =>
      'Страна, где вы сейчас; предзаполнено по последнему периоду.';

  @override
  String get importTransit => 'транзит';

  @override
  String importGap(String days) {
    return 'внутри без данных: $days';
  }

  @override
  String get importStatusExists => 'уже есть в дневнике';

  @override
  String importStatusConflict(String country) {
    return 'пересекается с записью: $country — при добавлении та будет обрезана';
  }

  @override
  String get importStatusCurrent => 'станет текущим пребыванием';

  @override
  String importApply(String records) {
    return 'Добавить: $records';
  }

  @override
  String get importConfirmTitle => 'Добавить в дневник?';

  @override
  String importConfirmText(String records) {
    return 'Будет добавлено: $records. Существующие записи не меняются.';
  }

  @override
  String get importConfirmAction => 'Добавить';

  @override
  String importDone(String records) {
    return 'Добавлено: $records';
  }

  @override
  String get importInvalid =>
      'Записи не прошли проверку. Проверьте домашнюю и текущую страну.';

  @override
  String get importFootnote =>
      'Границы приблизительные (масштаб 1:50 млн): у самой границы страна может быть определена неверно. Записи можно поправить в журнале.';

  @override
  String get onboardingHaveHistory => 'Уже есть история?';

  @override
  String get onboardingRestore => 'Восстановить из копии Domiday';

  @override
  String get onboardingImport => 'Импортировать из Google Maps';

  @override
  String get onboardingFresh => 'Или начните с чистого листа:';

  @override
  String get backupTitle => 'Резервная копия';

  @override
  String get backupHelper =>
      'Файл со всей историей в формате приложения. Сохраняйте его в Google Drive, «Файлы» или отправляйте себе — на телефоне копия не хранится. Восстановление заменяет всю текущую историю целиком.';

  @override
  String get backupSave => 'Сохранить копию…';

  @override
  String countryDaysLine(String yearDays, int year, String allDays) {
    return '$yearDays в $year · $allDays за всё время';
  }

  @override
  String get countryCalendarHint =>
      'В календаре закрашены только дни этой страны. Нажмите на день, чтобы увидеть все записи за него.';

  @override
  String get countryRecords => 'Записи';

  @override
  String get countryOpenJournal => 'Открыть в журнале';

  @override
  String get yearPrev => 'Предыдущий год';

  @override
  String get yearNext => 'Следующий год';

  @override
  String get moreDetails => 'Подробнее';

  @override
  String get lessDetails => 'Скрыть';

  @override
  String get autoDetectShort =>
      'Одно приблизительное определение при открытии, не чаще раза в час, без диалогов и записей.';

  @override
  String get backgroundShort =>
      'Раз в 2–3 часа — та же проверка с уведомлением, если страна другая. Нужны «Разрешить всегда» и уведомления.';

  @override
  String get backupShort =>
      'Файл со всей историей. Храните его вне телефона: здесь копия не остаётся.';

  @override
  String get importShort =>
      'Экспорт Хронологии Google Maps (JSON): страны определяются офлайн, ничего не записывается без подтверждения.';

  @override
  String get clearAllShort =>
      'Возврат к первому запуску. Восстановить можно только из резервной копии.';

  @override
  String get datesFieldLabel => 'Даты *';

  @override
  String get pickerDates => 'Даты поездки';

  @override
  String get quickToday => 'Сегодня';

  @override
  String get quickYesterday => 'Вчера';

  @override
  String get quickOneDay => 'Один день';

  @override
  String get shareYear => 'Поделиться итогами';

  @override
  String shareTitle(int year) {
    return 'Итоги $year';
  }

  @override
  String get shareSend => 'Поделиться';

  @override
  String get shareHint =>
      'Картинка собирается на телефоне и уходит только туда, куда вы выберете: в ней итоги года и страны, без записей и координат.';

  @override
  String get shareFooter =>
      'Личный дневник поездок · день переезда считается в обеих странах';

  @override
  String shareFailed(String error) {
    return 'Не удалось поделиться: $error';
  }

  @override
  String get navToday => 'Сегодня';

  @override
  String get navCalendar => 'Календарь';

  @override
  String get navMap => 'Карта';

  @override
  String get navJournal => 'Журнал';

  @override
  String get openCalendar => 'Открыть календарь';

  @override
  String get onThisDayTitle => 'В этот день';

  @override
  String onThisDayDay(int n, int total) {
    return 'День $n из $total';
  }

  @override
  String get onThisDayAround => 'В эти дни';

  @override
  String get onThisDayTransit => 'Транзит';

  @override
  String get calendarFilter => 'Только дни этой страны';

  @override
  String get reviewOpen => 'Итоги года';

  @override
  String reviewTitle(int year) {
    return 'Ваш $year';
  }

  @override
  String reviewNudge(int year) {
    return 'Итоги $year года готовы';
  }

  @override
  String reviewCountries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count стран',
      many: '$count стран',
      few: '$count страны',
      one: '$count страна',
    );
    return '$_temp0';
  }

  @override
  String get reviewCountriesSub => 'с хотя бы одним пребыванием в этом году';

  @override
  String reviewNewCountries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count новых стран',
      many: '$count новых стран',
      few: '$count новые страны',
      one: '$count новая страна',
      zero: 'Новых стран нет',
    );
    return '$_temp0';
  }

  @override
  String get reviewDaysTitle => 'Дни';

  @override
  String get reviewLongest => 'Самая долгая поездка';

  @override
  String get reviewNoTrips => 'Поездок в этом году нет.';

  @override
  String get reviewMapTitle => 'Ваша карта';

  @override
  String reviewCities(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count городов',
      many: '$count городов',
      few: '$count города',
      one: '$count город',
    );
    return '$_temp0';
  }

  @override
  String get reviewCitiesSub => 'из ваших записей';

  @override
  String get reviewShareTitle => 'Поделиться итогами';

  @override
  String get reviewShareBody =>
      'Картинка с годом, днями и странами, собранная на телефоне. Она уходит только туда, куда вы выберете.';

  @override
  String reviewThrough(String date) {
    return 'По $date';
  }

  @override
  String get planToggle => 'План';

  @override
  String get planTripToggle => 'Поездка';

  @override
  String get planNew => 'Новый план';

  @override
  String get planYour => 'План поездки';

  @override
  String get savePlan => 'Сохранить план';

  @override
  String get deletePlan => 'Удалить план';

  @override
  String get plansSection => 'Планы';

  @override
  String get planHint =>
      'План не считается в днях и итогах, пока вы его не подтвердите.';

  @override
  String planInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'через $count дней',
      many: 'через $count дней',
      few: 'через $count дня',
      one: 'через $count день',
      zero: 'сегодня',
    );
    return '$_temp0';
  }

  @override
  String get planOngoing => 'по плану в эти дни';

  @override
  String get planOverdue => 'даты прошли, не подтверждён';

  @override
  String get nextTrip => 'Следующая поездка';

  @override
  String planArrivedTitle(String place) {
    return 'По плану сегодня: $place. Вы там?';
  }

  @override
  String get planYes => 'Да, я там';

  @override
  String get planNo => 'Ещё нет';

  @override
  String get planAddAsTrip => 'Добавить как поездку';

  @override
  String planOverdueTitle(String place) {
    return '$place: даты прошли';
  }

  @override
  String get planOverdueBody =>
      'Запись не сделана. Добавьте как поездку или поправьте план.';

  @override
  String get mapTitle => 'Карта стран';

  @override
  String mapCount(int visited, int total) {
    return '$visited из $total';
  }

  @override
  String get mapAllTime => 'За всё время';

  @override
  String get mapCountries => 'Страны';

  @override
  String get mapPick => 'Какая страна?';

  @override
  String get mapNotVisited => 'записей нет';

  @override
  String get mapLegendVisited => 'были';

  @override
  String get mapLegendTransit => 'только транзит';

  @override
  String get mapLegendDisputed => 'спорная территория';

  @override
  String get mapNote => 'Границы по Natural Earth.';

  @override
  String get mapShare => 'Поделиться картой';

  @override
  String get mapFullscreen => 'На весь экран';

  @override
  String get mapSearch => 'Найти страну';

  @override
  String get mapSearchHint => 'Название страны';

  @override
  String get mapViewFlat => 'Плоская карта';

  @override
  String get mapViewGlobe => 'Шар';

  @override
  String get mapShareTitleAll => 'Мои страны';

  @override
  String mapShareTitleYear(int year) {
    return 'Мои страны · $year';
  }

  @override
  String backupLast(String date) {
    return 'Последняя копия: $date';
  }

  @override
  String get backupNever => 'Копия ещё не сохранялась.';

  @override
  String get backupNudgeTitle => 'Пора сохранить копию';

  @override
  String backupNudgeBody(String date) {
    return 'Записи хранятся только на этом телефоне. Последняя копия: $date.';
  }

  @override
  String get backupNudgeBodyNever =>
      'Записи хранятся только на этом телефоне, а копии ещё не было.';

  @override
  String get backupNudgeLater => 'Позже';

  @override
  String get clearAllTitle => 'Очистить всё';

  @override
  String get clearAllHelper =>
      'Удаляет все записи, архив, домашнюю страну, текущее пребывание и настройки — приложение вернётся к первому запуску. Восстановить можно только из резервной копии.';

  @override
  String get clearAllButton => 'Очистить всё…';

  @override
  String get clearAllConfirmTitle => 'Очистить всё?';

  @override
  String clearAllConfirmBody(String records) {
    return '$records, архив, домашняя страна, текущее пребывание и все настройки будут удалены. Восстановить можно только из резервной копии.';
  }

  @override
  String get clearAllBackupFirst => 'Сначала сохранить копию…';

  @override
  String get clearAllAction => 'Удалить всё';

  @override
  String get clearAllDone => 'Всё очищено';

  @override
  String clearAllFailed(String error) {
    return 'Не удалось очистить: $error';
  }

  @override
  String get backupRestore => 'Восстановить из копии…';

  @override
  String backupSaved(String name) {
    return 'Копия сохранена: $name';
  }

  @override
  String get backupSaveFailed =>
      'Не удалось записать файл. Попробуйте другую папку.';

  @override
  String backupTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count поездок',
      few: '$count поездки',
      one: '$count поездка',
    );
    return '$_temp0';
  }

  @override
  String get backupRestoreTitle => 'Восстановить из копии?';

  @override
  String backupRestoreConfirm(
    String name,
    String trips,
    String date,
    String version,
    String current,
  ) {
    return '$name: $trips, создана $date, Domiday $version. Текущая история ($current) будет заменена целиком.';
  }

  @override
  String get backupRestoreAction => 'Заменить историю';

  @override
  String backupRestored(String trips) {
    return 'История восстановлена: $trips';
  }

  @override
  String get backupUnknownDate => 'дата неизвестна';

  @override
  String get backupErrorTitle => 'Восстановление невозможно';

  @override
  String get backupErrorNotBackup => 'Это не файл резервной копии Domiday.';

  @override
  String get backupErrorNewer =>
      'Копия сделана более новой версией Domiday. Обновите приложение; текущая история не тронута.';

  @override
  String get backupErrorCorrupt =>
      'Файл повреждён или содержит недопустимые записи. Текущая история не тронута.';

  @override
  String get backgroundTitle => 'Проверять в фоне';

  @override
  String get backgroundHelper =>
      'Раз в 2–3 часа и при появлении связи приложение проверяет страну так же, как по кнопке, — и присылает уведомление только если страна, похоже, другая. Без вашего подтверждения ничего не записывается. Нужны разрешение «Геолокация — всегда» и уведомления; Samsung может усыплять фоновые задачи «спящих» приложений.';

  @override
  String get backgroundNeedsAlways =>
      'Разрешение «всегда» Android выдаёт только в своих настройках: откройте настройки приложения → Разрешения → Местоположение → «Разрешить всегда» и вернитесь в Domiday — режим включится сам.';

  @override
  String get backgroundNeedsNotifications =>
      'Уведомления для Domiday выключены. Разрешите их в настройках приложения, иначе фоновой проверке нечем вас позвать.';

  @override
  String get openAppSettings => 'Открыть настройки приложения';

  @override
  String get backgroundStatusOn => 'Фоновая проверка включена';

  @override
  String get backgroundStatusOff => 'Фоновая проверка выключена';

  @override
  String get backgroundStatusWaiting =>
      'Ждёт разрешений — включится сама, как только даны «Разрешить всегда» и уведомления';

  @override
  String get backgroundNeverRan => 'Фоновых проверок ещё не было';

  @override
  String backgroundLastRun(String when, String result) {
    return 'Последняя проверка: $when — $result';
  }

  @override
  String get backgroundOutcomeNotified => 'отправлено уведомление';

  @override
  String get backgroundOutcomeSame =>
      'та же страна или предложение уже отклонено';

  @override
  String get backgroundOutcomeAlreadyNotified => 'уведомление уже было';

  @override
  String get backgroundOutcomeNoLocation => 'координаты не получены';

  @override
  String get backgroundOutcomeNoCountry => 'страна не определена';

  @override
  String get backgroundOutcomeNoProfile => 'текущая страна не задана';

  @override
  String get backgroundOutcomeError => 'ошибка';

  @override
  String backgroundErrorDetail(String text) {
    return 'Ошибка: $text';
  }

  @override
  String get backgroundLogTitle => 'Последние запуски:';

  @override
  String get backgroundRunNow => 'Запустить проверку сейчас';

  @override
  String get backgroundRunNowStarted =>
      'Проверка запущена в фоне. Сверните приложение на минуту и вернитесь — результат появится в строке «Последняя проверка».';

  @override
  String get backgroundTestNotification => 'Тестовое уведомление';

  @override
  String get backgroundTestTitle => 'Уведомления Domiday работают';

  @override
  String get backgroundTestBody =>
      'Если вы это видите, канал, иконка и разрешение в порядке.';

  @override
  String get backgroundBatteryOk => 'Батарея: фон без ограничений.';

  @override
  String get backgroundHowToAlways =>
      'Как выдать: Настройки Android → Приложения → Domiday → Разрешения → Местоположение → «Разрешить всегда». Если уведомления запрещены, включите их там же. Затем вернитесь в Domiday — режим включится сам.';

  @override
  String backgroundEnableFailed(String error) {
    return 'Не удалось включить: $error';
  }

  @override
  String get backgroundNotificationsOffLine =>
      'Уведомления Domiday выключены: проверка идёт, но позвать вас нечем. Разрешите их в настройках приложения.';

  @override
  String get backgroundBatteryRestricted =>
      'Батарея: система ограничивает фон Domiday — проверки могут не запускаться. Откройте настройки приложения → Батарея → «Без ограничений».';

  @override
  String notificationTitle(String country) {
    return 'Похоже, вы здесь: $country';
  }

  @override
  String get notificationBody =>
      'Откройте Domiday, чтобы подтвердить, исправить или отклонить. До этого ничего не записывается.';

  @override
  String get notificationChannel => 'Определение страны';

  @override
  String get notificationChannelDescription =>
      'Предложения после фоновой проверки страны';

  @override
  String get gapsTitle => 'Пробелы в истории';

  @override
  String get gapsDone => 'Дни добавлены в журнал';

  @override
  String get gapsCheckFirst => 'Сначала проверьте даты';

  @override
  String gapsYearHome(int year, String home) {
    return 'Год: $year. Домашняя страна: $home.';
  }

  @override
  String get gapsExplain =>
      'Это неизвестные дни между известными пребываниями, а не доказательство, что вы были дома. Начальный и конечный незаписанные периоды не предлагаются. Записанные дни не затрагиваются.';

  @override
  String get gapsNone =>
      'Пробелов между известными пребываниями в этом году нет. При этом другие дни года могут оставаться неизвестными.';

  @override
  String gapsTotal(String days, int count) {
    return 'Всего: $days · записей: $count';
  }

  @override
  String get gapsDoneNote =>
      'Каждую запись можно изменить или удалить в журнале. В заметке указано, что пробел подтверждён вами вручную.';

  @override
  String gapsConfirmNote(String home) {
    return 'Подтверждая, вы указываете, что во ВСЕ эти даты были в стране «$home». Если это не так, вернитесь и добавьте отдельные поездки вручную.';
  }

  @override
  String get gapsConfirmButton => 'Подтверждаю: в эти дни я был(а) дома';

  @override
  String get gapsCancel => 'Отмена — ничего не добавлять';

  @override
  String get gapsSaveFailed =>
      'Не удалось сохранить. Дневник не изменён. Если дата или записи изменились, вернитесь и откройте предпросмотр заново.';

  @override
  String gapFillNote(int year, String home) {
    return 'Добавлено вручную после подтверждения пробела за $year год. Домашняя страна: $home. Это ваше подтверждение, не автоматическое определение.';
  }

  @override
  String get chooseCountry => 'Выберите страну';

  @override
  String get chooseYear => 'Выберите год';

  @override
  String get allCountries => 'Все страны';

  @override
  String get allYears => 'Все годы';

  @override
  String get journalTitle => 'Когда и где вы были';

  @override
  String get journalSubtitle => 'Ваши путешествия, собранные в одном месте.';

  @override
  String get addTrip => 'Добавить поездку';

  @override
  String get searchLabel => 'Найти поездку';

  @override
  String get searchHint => 'Страна, город, заметка или год';

  @override
  String get clearSearch => 'Очистить поиск';

  @override
  String get reset => 'Сбросить';

  @override
  String foundTrips(int count) {
    return 'Найдено поездок: $count';
  }

  @override
  String get tripHistory => 'История поездок';

  @override
  String get noSuchRecords => 'Таких записей пока нет.';

  @override
  String get tryAnotherWord => 'Попробуйте другое слово или сбросьте фильтры.';

  @override
  String get resetFilters => 'Сбросить фильтры';

  @override
  String get bySelectedTrips => 'По выбранным поездкам';

  @override
  String get byYourRecordsOnly => 'Только по вашим записям';

  @override
  String countryStatLine(String country, String days, int trips) {
    return '$country  ·  $days  ·  поездок: $trips';
  }

  @override
  String get moveDayNotVisa =>
      'День переезда может учитываться в двух странах. Это не визовый или налоговый расчёт.';

  @override
  String journalFooter(String version) {
    return 'Личный дневник · $version';
  }

  @override
  String get emptyTitle => 'С какой поездки начнём?';

  @override
  String get emptyBody =>
      'Вспомните одно путешествие и сохраните страну и даты. Город и маленькая заметка помогут вернуться к воспоминаниям.';

  @override
  String get emptyNote =>
      'Пока нет записей. Всё вводится вручную и хранится только на этом устройстве.';

  @override
  String get yourJournalInNumbers => 'Ваш дневник в цифрах';

  @override
  String get daysInRecordedTrips => 'Дни в записанных поездках';

  @override
  String get bothDatesIncluded =>
      'Обе даты включены. Совпадающие дни считаются один раз.';

  @override
  String daysOnlyInYear(int year) {
    return 'Дни — только в $year году.';
  }

  @override
  String wholeTrip(String days) {
    return '$days · Вся поездка';
  }

  @override
  String get openAndEdit => 'Открыть и изменить';

  @override
  String get currentStayOngoing => 'Текущее пребывание · продолжается';

  @override
  String get pickerArrival => 'Дата приезда';

  @override
  String get pickerDeparture => 'Дата выезда';

  @override
  String get errorPickBothDates => 'Выберите дату приезда и дату выезда';

  @override
  String get tripSaved => 'Поездка сохранена';

  @override
  String get overlapTitle => 'Дни уже заняты';

  @override
  String overlapIntro(String range) {
    return '$range: эти дни уже есть в дневнике. Один общий день на стыке — день переезда, он допустим; здесь пересечение больше.';
  }

  @override
  String overlapTrim(String country, String range, String next) {
    return '$country, $range: станет $next';
  }

  @override
  String overlapSplit(
    String country,
    String range,
    String first,
    String second,
  ) {
    return '$country, $range: разделится на $first и $second';
  }

  @override
  String overlapRemove(String country, String range) {
    return '$country, $range: будет удалена';
  }

  @override
  String overlapCurrent(String country, String date) {
    return 'Текущее пребывание, $country: начало станет $date';
  }

  @override
  String overlapCurrentFixed(String country) {
    return 'Текущее пребывание, $country: пересекается, изменить его здесь нельзя — сначала уточните дату приезда на карточке «Сейчас»';
  }

  @override
  String overlapSameCountry(String country) {
    return '$country (та же страна)';
  }

  @override
  String get overlapHint =>
      '«Заменить» обрежет или удалит перечисленные записи, как описано. «Оставить обе» запишет как есть: дни будут считаться в обеих.';

  @override
  String get overlapHintKeepOnly =>
      '«Оставить обе» запишет как есть: дни будут считаться в обеих.';

  @override
  String get overlapReplace => 'Заменить';

  @override
  String get overlapKeep => 'Оставить обе';

  @override
  String get tripSaveFailed =>
      'Не удалось сохранить. Данные формы остались на экране. Проверьте свободное место и нажмите «Сохранить поездку» ещё раз.';

  @override
  String get deleteTripTitle => 'Удалить поездку?';

  @override
  String get deleteTripBody =>
      'Восстановить запись в этом прототипе не получится.';

  @override
  String get tripDeleted => 'Поездка удалена';

  @override
  String get tripDeleteFailed =>
      'Не удалось удалить запись. Она осталась в дневнике. Попробуйте удалить её ещё раз.';

  @override
  String get newTrip => 'Новая поездка';

  @override
  String get yourTrip => 'Ваша поездка';

  @override
  String get tripFormIntro =>
      'Запишите завершённую поездку. Обе даты обязательны, не позднее сегодня. День приезда и день выезда включены.';

  @override
  String get countryFieldLabel => 'Страна *';

  @override
  String get countryFieldHelper => 'Можно ввести любую страну';

  @override
  String get cityLabel => 'Город';

  @override
  String get arrivalFieldLabel => 'Приезд *';

  @override
  String get departureFieldLabel => 'Выезд *';

  @override
  String get noteLabel => 'Заметка';

  @override
  String get noteHint => 'Что хочется запомнить?';

  @override
  String get saveTrip => 'Сохранить поездку';

  @override
  String get deleteTrip => 'Удалить поездку';

  @override
  String get chooseDate => 'Выбрать дату';

  @override
  String get aboutTagline =>
      'Личный дневник поездок. Считает дни по странам, показывает год в календаре и на карте, помнит, где вы были. Всё хранится только на вашем телефоне.';

  @override
  String get aboutFeaturesTitle => 'Что умеет';

  @override
  String get aboutFeatCalendar =>
      'Календарь года: каждый день закрашен цветом страны, транзит и день в двух странах помечены отдельно.';

  @override
  String get aboutFeatMap =>
      'Карта стран и вращающийся шар: посещённые страны в цветах политической карты, поиск с подлётом к стране.';

  @override
  String get aboutFeatJournal =>
      'Журнал с поиском по стране, городу, заметке и году; страница каждой страны.';

  @override
  String get aboutFeatPlans =>
      'Планы поездок: будущие даты видны в календаре, но не считаются, пока вы не подтвердите поездку.';

  @override
  String get aboutFeatReview =>
      'Итоги года: страны и новые страны, дни, самая долгая поездка, карта, города, картинка «Поделиться».';

  @override
  String get aboutFeatOnThisDay =>
      '«В этот день»: где вы были в эту дату в прошлые годы.';

  @override
  String get aboutFeatImport =>
      'Импорт Хронологии Google Maps: страны определяются офлайн, вы добавляете только нужные периоды.';

  @override
  String get aboutFeatDetect =>
      'Определение страны по кнопке и при открытии: подсказка, которую вы подтверждаете.';

  @override
  String get aboutFeatBackup =>
      'Резервная копия одним файлом, восстановление, «Очистить всё» с подтверждением.';

  @override
  String get aboutContactTitle => 'Связь';

  @override
  String get aboutContactEmail => 'Вопросы по почте';

  @override
  String get aboutContactSite =>
      'Предложения по доработке и сообщения об ошибках — на сайте';

  @override
  String get aboutContactNote =>
      'Письмо и сайт открываются в других приложениях. Само приложение в интернет не выходит.';

  @override
  String aboutOpenFailed(String url) {
    return 'Не удалось открыть $url: нет подходящего приложения.';
  }

  @override
  String get aboutCreditsTitle => 'Благодарности и лицензии';

  @override
  String get aboutCreditsBody =>
      'Границы стран — Natural Earth, общественное достояние. Флаги — набор flag-icons, лицензия MIT. Шрифты — Manrope (SIL Open Font License) и Roboto (Apache 2.0). Сделано на Flutter (BSD).';

  @override
  String get aboutCopyright => '© 2026 Domiday. Все права защищены.';

  @override
  String get aboutNoWarranty =>
      'Приложение предоставляется «как есть», без гарантий. Оно не определяет резидентство, право на въезд и визовые сроки.';

  @override
  String get aboutTitle => 'О дневнике';

  @override
  String aboutVersion(String version) {
    return 'Личный дневник · $version';
  }

  @override
  String get aboutPlaceTitle => 'Текущее место и история';

  @override
  String get aboutPlaceBody =>
      'Ручной дневник поездок и текущего пребывания. Он отвечает на вопрос «когда и где мы были» и ничего не меняет сам: каждая запись, дата и страна поставлены вами или подтверждены вами.';

  @override
  String get aboutUnknownTitle => 'Неизвестно — не значит дома';

  @override
  String get aboutUnknownBody =>
      'Домашняя страна — ваша личная настройка, не налоговое резидентство. Её изменение пересчитывает категории, но не меняет записи. Без даты приезда текущее пребывание не добавляет дней в итоги. Неизвестные дни считаются с 1 января по сегодня, а для прошлых лет — за весь год. Пробелы между известными пребываниями можно записать как дни дома только после просмотра дат и вашего подтверждения. Эти записи можно исправить или удалить в журнале.';

  @override
  String get aboutDeviceTitle => 'Ваши записи — на вашем устройстве';

  @override
  String get aboutDeviceBody =>
      'Данные хранятся в закрытой папке приложения. Нет аккаунта, облака, сетевых запросов, рекламы и аналитики. Резервную копию — файл в формате приложения — можно сохранить и восстановить в настройках. Удаление приложения или очистка его данных приведут к потере записей. Не храните здесь единственную копию важной информации.';

  @override
  String get aboutCountingTitle => 'Как считаются дни';

  @override
  String get aboutCountingBody =>
      'День приезда и день выезда включаются: поездка в один день — это один день. Пересекающиеся записи не увеличивают общий итог. Внутри одной страны совпадающие дни также считаются один раз. День переезда может относиться сразу к двум странам, поэтому сумма по странам может быть больше общего числа дней. При выборе года считаются только дни в этом году; карточки сохраняют полные даты поездки. Поиск по году находит поездки, которые его затрагивают, но сам по себе не обрезает даты.';

  @override
  String get aboutNotVisaTitle => 'Не визовый и не налоговый калькулятор';

  @override
  String get aboutNotVisaBody =>
      'Итоги описывают только введённые записи, а не всю историю пребывания. Пропущенная поездка — неизвестная история, а не доказательство отсутствия в стране. Дневник не определяет резидентство, право на въезд или соблюдение визовых сроков.';

  @override
  String get errMissingId => 'Отсутствует идентификатор записи';

  @override
  String get errCountryRequired => 'Укажите страну';

  @override
  String get errTextTooLong => 'Слишком длинный текст';

  @override
  String get errDepartureBeforeArrival =>
      'Дата выезда не может быть раньше даты приезда';

  @override
  String get errFutureTrip =>
      'Можно записать только прошедшие поездки, не будущие даты';

  @override
  String get errInvalidTrip => 'Некорректная запись поездки';

  @override
  String get errSameCountry => 'Выберите другую страну';

  @override
  String errMoveDateRange(String from, String to) {
    return 'Дата переезда — с $from по $to. Для более ранней истории используйте журнал.';
  }

  @override
  String get errCountryLength => 'Укажите страну: от 1 до 120 символов';

  @override
  String get errYearRange => 'Выберите прошедший или текущий год';

  @override
  String get errPreviewStale =>
      'Данные изменились. Откройте предпросмотр снова.';

  @override
  String get errHomeCountryFirst => 'Сначала укажите домашнюю страну';

  @override
  String get errMoveDateRequired => 'Укажите дату переезда';

  @override
  String get detectOffTitle => 'Определение страны выключено';

  @override
  String get detectOffDenied =>
      'У Domiday нет доступа к местоположению, поэтому он не заметит, что вы пересекли границу. Дни всё равно считаются — страну тогда меняете вы сами.';

  @override
  String get detectOffService =>
      'Геолокация на телефоне выключена, поэтому Domiday не заметит, что вы пересекли границу. Дни всё равно считаются — страну тогда меняете вы сами.';

  @override
  String get detectOffEnable => 'Включить';

  @override
  String get detectOffDismiss => 'Не нужно';

  @override
  String get countsItself =>
      'Дни считаются сами — отмечайте только смену страны.';

  @override
  String get importIntroLead =>
      'Domiday может заполнить дневник по Хронологии Google Maps. Это три шага:';

  @override
  String get importStep1 =>
      'Экспортируйте Хронологию на телефоне: Настройки → Местоположение → Службы геолокации → Хронология → «Экспортировать данные Хронологии». Или в Google Maps: ваш аватар → «Хронология» → ⋮ → «Настройки местоположения и конфиденциальности» → «Экспортировать данные Хронологии». На разных телефонах названия пунктов немного отличаются.';

  @override
  String get importStep2 =>
      'Сохраните файл, например в «Загрузки». Обычно он называется Timeline.json.';

  @override
  String get importStep3 =>
      'Вернитесь сюда и нажмите «Выбрать файл». Страны определятся офлайн, координаты не сохраняются, и ничего не запишется без просмотра и подтверждения.';

  @override
  String get importNoTimeline =>
      'Если Хронология на телефоне не включалась, выгружать нечего — тогда поездки добавляются вручную в журнале.';

  @override
  String get importChoose => 'Выбрать файл';

  @override
  String get importAnyFile => 'Файла нет в списке? Показать все файлы';

  @override
  String get importOtherFile => 'Выбрать другой файл';

  @override
  String get mapHintAll =>
      'Закрашены страны, где вы были. Нажмите на страну — увидите её дни.';

  @override
  String mapHintYear(int year) {
    return 'Закрашены страны, где вы были в $year году. Нажмите на страну — увидите её дни.';
  }

  @override
  String get mapEmpty =>
      'Здесь закрасятся страны, где вы были. Добавьте поездки в журнале или импортируйте историю из Google Maps.';

  @override
  String get feedbackTitle => 'Замечания и предложения';

  @override
  String get feedbackBody =>
      'Нашли ошибку или чего-то не хватает? Напишите мне: я читаю каждое сообщение и дорабатываю приложение. Сайт или почта откроются в отдельном приложении; сам Domiday в интернет не ходит.';

  @override
  String get feedbackSite => 'Написать на сайте';

  @override
  String get feedbackSiteHint => 'Форма на сайте, без входа';

  @override
  String get feedbackEmail => 'Написать по почте';

  @override
  String feedbackMailSubject(String version) {
    return 'Domiday $version: замечание';
  }
}
