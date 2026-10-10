# assets/borders.json

Границы стран для офлайн-определения страны по координатам.
Источник: Natural Earth, Admin 0 – Countries, 1:50m (public domain,
https://www.naturalearthdata.com/), GeoJSON из репозитория
nvkelso/natural-earth-vector, снято 14.09.2026. Код страны — поле
`ISO_A2_EH` (у Франции, Норвегии, Косово `ISO_A2` = -99). Объекты без кода
(Сомалиленд, Северный Кипр, Сиачен) и коды вне `assets/countries.json`
пропущены. Границы «де-факто» по умолчанию Natural Earth. Координаты
округлены до 0,001° (~100 м), кольца (внешние и дырки) хранятся плоскими
массивами `[lon, lat, lon, lat, …]`; принадлежность точки — по правилу
чётности (even-odd), поэтому дырки (Лесото, Сан-Марино) учитываются сами.
Формат: `{source, countries: [{code, bbox: [minLon, minLat, maxLon, maxLat], rings}]}`.
