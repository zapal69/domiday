#!/usr/bin/env python3
"""Демонстрационный дневник для показа и тестов: дом Кипр, поездки
2023–2026 без России, транзиты со стыковкой, пробелы, планы.
Пишет demo/domiday-demo-backup.json в формате резервной копии приложения
(схема 5). Правила: пересечения только стыковым днём, транзит поверх
пребывания допустим, дома между поездками — записи «Cyprus».

  python3 tool/make_demo.py
"""
import json, datetime as dt, pathlib

D = dt.date
HOME = ('Cyprus', 'CY')

# (id, country, code, city, note, arrival, departure, kind)
AWAY = [
    ('th23', 'Thailand', 'TH', 'Phuket', 'Winter escape', D(2023,2,10), D(2023,2,24), 'stay'),
    ('gr23', 'Greece', 'GR', 'Athens', 'Easter with friends', D(2023,4,14), D(2023,4,21), 'stay'),
    ('de23', 'Germany', 'DE', 'Berlin', 'Conference', D(2023,6,5), D(2023,6,9), 'stay'),
    ('it23', 'Italy', 'IT', 'Sardinia', 'Family holiday', D(2023,7,20), D(2023,8,12), 'stay'),
    ('mt23', 'Malta', 'MT', 'Valletta', 'Long weekend', D(2023,9,18), D(2023,9,21), 'stay'),
    ('gb23', 'United Kingdom', 'GB', 'London', 'Work trip', D(2023,10,2), D(2023,10,6), 'stay'),
    ('at23', 'Austria', 'AT', 'Innsbruck', 'Skiing', D(2023,12,22), D(2024,1,4), 'stay'),
    ('pt24', 'Portugal', 'PT', 'Lisbon', 'Spring break', D(2024,3,8), D(2024,3,15), 'stay'),
    ('ge24', 'Georgia', 'GE', 'Tbilisi', 'Wine tour', D(2024,5,1), D(2024,5,12), 'stay'),
    ('il24', 'Israel', 'IL', 'Tel Aviv', 'Weekend', D(2024,6,14), D(2024,6,16), 'stay'),
    ('es24', 'Spain', 'ES', 'Barcelona', 'Summer with the kids', D(2024,8,3), D(2024,8,24), 'stay'),
    ('it24', 'Italy', 'IT', 'Amalfi', 'September sun', D(2024,9,12), D(2024,9,19), 'stay'),
    ('nl24', 'Netherlands', 'NL', 'Amsterdam', 'Conference', D(2024,9,30), D(2024,10,4), 'stay'),
    ('jp24', 'Japan', 'JP', 'Tokyo', 'Autumn leaves', D(2024,11,15), D(2024,11,29), 'stay'),
    ('eg25', 'Egypt', 'EG', 'Sharm El Sheikh', 'Diving', D(2025,1,18), D(2025,1,25), 'stay'),
    ('cz25', 'Czechia', 'CZ', 'Prague', 'City break', D(2025,3,21), D(2025,3,28), 'stay'),
    ('am25', 'Armenia', 'AM', 'Yerevan', 'Road trip', D(2025,5,9), D(2025,5,20), 'stay'),
    ('gr25', 'Greece', 'GR', 'Crete', 'Long summer', D(2025,7,1), D(2025,8,15), 'stay'),
    ('hr25', 'Croatia', 'HR', 'Dubrovnik', 'Sailing week', D(2025,9,13), D(2025,9,21), 'stay'),
    ('fr25', 'France', 'FR', 'Paris', 'Anniversary', D(2025,10,10), D(2025,10,13), 'stay'),
    ('at25', 'Austria', 'AT', 'Vienna', 'Christmas market', D(2025,12,24), D(2026,1,2), 'stay'),
    ('th26', 'Thailand', 'TH', 'Chiang Mai', 'Escape the winter', D(2026,2,14), D(2026,2,28), 'stay'),
    ('it26', 'Italy', 'IT', 'Rome', 'Easter in Rome', D(2026,4,3), D(2026,4,10), 'stay'),
    ('pt26', 'Portugal', 'PT', 'Porto', 'Conference', D(2026,5,15), D(2026,5,22), 'stay'),
    ('es26', 'Spain', 'ES', 'Mallorca', 'Family holiday', D(2026,6,20), D(2026,7,5), 'stay'),
    ('gb26', 'United Kingdom', 'GB', 'Edinburgh', 'Festival', D(2026,7,24), D(2026,8,9), 'stay'),
]
# Транзиты со стыковкой: один день поверх дня приезда или отъезда.
TRANSIT = [
    ('tr-ae-2302a', 'United Arab Emirates', 'AE', 'Dubai', 'Layover', D(2023,2,10)),
    ('tr-ae-2302b', 'United Arab Emirates', 'AE', 'Dubai', 'Layover', D(2023,2,24)),
    ('tr-fr-2403', 'France', 'FR', 'Paris CDG', 'Layover', D(2024,3,8)),
    ('tr-tr-2405a', 'Turkey', 'TR', 'Istanbul', 'Layover', D(2024,5,1)),
    ('tr-tr-2405b', 'Turkey', 'TR', 'Istanbul', 'Layover', D(2024,5,12)),
    ('tr-ae-2411a', 'United Arab Emirates', 'AE', 'Dubai', 'Layover', D(2024,11,15)),
    ('tr-ae-2411b', 'United Arab Emirates', 'AE', 'Dubai', 'Layover', D(2024,11,29)),
    ('tr-tr-2505', 'Turkey', 'TR', 'Istanbul', 'Layover', D(2025,5,9)),
    ('tr-de-2512', 'Germany', 'DE', 'Frankfurt', 'Layover', D(2025,12,24)),
    ('tr-ae-2602a', 'United Arab Emirates', 'AE', 'Dubai', 'Layover', D(2026,2,14)),
    ('tr-ae-2602b', 'United Arab Emirates', 'AE', 'Dubai', 'Layover', D(2026,2,28)),
    ('tr-nl-2607', 'Netherlands', 'NL', 'Amsterdam', 'Layover', D(2026,7,24)),
]
# Пробелы без записей (неизвестные дни): между этими поездками дом не записан.
GAPS_AFTER = {'de23', 'gb26'}   # после Берлина 2023 и после Эдинбурга 2026
CURRENT_FROM = D(2026, 8, 25)
PLANS = [
    ('plan-gr', 'Greece', 'GR', 'Santorini', 'Weekend by the sea', D(2026,9,16), D(2026,9,20)),
    ('plan-de', 'Germany', 'DE', 'Munich', 'Oktoberfest', D(2026,9,4), D(2026,9,6)),
    ('plan-jp', 'Japan', 'JP', 'Kyoto', 'Autumn trip', D(2026,11,7), D(2026,11,21)),
    ('plan-pt', 'Portugal', 'PT', 'Madeira', 'Christmas', D(2026,12,20), D(2027,1,3)),
    ('plan-ge', 'Georgia', 'GE', 'Kazbegi', 'Hiking', D(2027,5,1), D(2027,5,10)),
]

def rec(id_, country, code, city, note, a, d, kind='stay'):
    return {'id': id_, 'country': country, 'countryCode': code, 'city': city,
            'note': note, 'arrival': a.isoformat(), 'departure': d.isoformat(), 'kind': kind}

trips = [rec(*t) for t in AWAY]
# Дом между поездками: со дня отъезда предыдущей по день приезда следующей
# (стыковые дни общие). Первая запись дома — с начала 2023 года.
prev_dep, prev_id = D(2023, 1, 1), None
for t in AWAY:
    if prev_id not in GAPS_AFTER:
        trips.append(rec(f'home-{t[5].isoformat()}', *HOME, 'Limassol', '', prev_dep, t[5]))
    prev_dep, prev_id = t[6], t[0]
trips += [rec(i, c, k, city, note, d, d, 'transit') for (i, c, k, city, note, d) in TRANSIT]
trips.sort(key=lambda r: r['arrival'])

# Проверка правила пересечений: пребывания могут делить только стыковой день.
stays = [r for r in trips if r['kind'] == 'stay']
for i, a in enumerate(stays):
    for b in stays[i+1:]:
        lo = max(a['arrival'], b['arrival']); hi = min(a['departure'], b['departure'])
        if lo <= hi:
            days = (D.fromisoformat(hi) - D.fromisoformat(lo)).days + 1
            assert days <= 1, (a['id'], b['id'], days)

journal = {
    'schemaVersion': 5,
    'trips': trips,
    'homeCountry': HOME[0],
    'homeCountryCode': HOME[1],
    'current': {'id': 'now', 'country': HOME[0], 'countryCode': HOME[1],
                'arrival': CURRENT_FROM.isoformat(), 'confirmedOn': D(2026, 9, 17).isoformat(),
                'notBefore': None},
    'undated': [],
    'plans': [rec(*p) for p in PLANS],
}
backup = {
    'format': 'domiday-backup', 'backupVersion': 1,
    'createdAt': '2026-09-17T12:00:00.000Z', 'appVersion': '0.18.0 (40)',
    'journal': journal,
}
out = pathlib.Path(__file__).resolve().parent.parent / 'demo' / 'domiday-demo-backup.json'
out.write_text(json.dumps(backup, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(out, len(trips), 'records,', len(PLANS), 'plans')
