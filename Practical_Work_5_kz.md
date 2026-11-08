# ПРАКТИКАЛЫҚ ЖҰМЫС №5
## Тақырыбы: Мобильді қосымшаның интерактивті прототипін жасау (REST API, CRUD сұраулары және желілік қателерді өңдеу)
### Жоба атауы: «AntiSleep AI» — Жүргізушінің ұйықтап кетуінің алдын алатын AI жүйесі

---

## 1. REST API ҚҰЖАТТАМАСЫ ЖӘНЕ ENDPOINT-ТЕР ТІЗІМІ

«AntiSleep AI» қосымшасы үшін бұлтты маршруттар мен трассаларды қашықтан басқаруға арналған арнайы REST API жасалды.

* **Сервер адресі:** `http://localhost:8080/api` (Android эмуляторында: `http://10.0.2.2:8080/api`)
* **Деректер форматы:** `application/json; charset=utf-8`

### Endpoint-тер мен HTTP әдістері:

| № | HTTP әдісі | Endpoint | Орындалатын операция | Жауап коды |
|---|---|---|---|---|
| 1 | `GET` | `/api/health` | Сервердің жұмыс істеп тұрғанын тексеру | `200 OK` |
| 2 | `GET` | `/api/routes` | Барлық бағыттар тізімін алу (іздеу параметрлерімен `?q=...`) | `200 OK` |
| 3 | `GET` | `/api/routes/{id}` | Нақты бір бағыт туралы толық ақпарат алу | `200 OK` / `404 Not Found` |
| 4 | `POST` | `/api/routes` | Жаңа бағытты серверге тіркеу | `201 Created` |
| 5 | `PUT` | `/api/routes/{id}` | Бар бағытты толық өзгерту (жаңарту) | `200 OK` / `404 Not Found` |
| 6 | `PATCH` | `/api/routes/{id}` | Бағытты ішінара өзгерту (мысалы, `isFavorite`) | `200 OK` / `404 Not Found` |
| 7 | `DELETE` | `/api/routes/{id}` | Бағытты серверден біржола өшіру | `204 No Content` / `404` |

---

## 2. ҚОСЫЛҒАН КІТАПХАНАЛАР (`pubspec.yaml`)

HTTP сұрауларын орындау үшін ресми `http` пакеті қосылды:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.2
  sqflite: ^2.3.0
  sqflite_common_ffi: ^2.3.0
  path: ^1.9.0
```

---

## 3. DART MODEL ЖӘНЕ JSON СЕРИАЛИЗАЦИЯСЫ

[`RouteModel`](lib/models/route_model.dart) моделіне сервердің JSON деректерін оқу (`fromJson`) және серверге JSON күйінде жіберу (`toJson`) әдістері іске асырылды:

```dart
factory RouteModel.fromJson(Map<String, dynamic> json) {
  return RouteModel(
    id: json['id'].toString(),
    title: json['title'] as String,
    distanceKm: (json['distanceKm'] as num? ?? 0).toDouble(),
    avgDurationMinutes: (json['avgDurationMinutes'] as num? ?? 0).toInt(),
    riskLevel: (json['riskLevel'] as String?) ?? 'Төмен',
    isFavorite: (json['isFavorite'] as bool?) ?? false,
    notes: (json['notes'] as String?) ?? '',
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}

Map<String, dynamic> toJson({bool includeId = true}) {
  return {
    if (includeId) 'id': id,
    'title': title,
    'distanceKm': distanceKm,
    'avgDurationMinutes': avgDurationMinutes,
    'riskLevel': riskLevel,
    'isFavorite': isFavorite,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };
}
```

---

## 4. HTTP СҰРАУЛАРЫ МЕН АСИНХРОНДЫ ҚЫЗМЕТ (`RouteApiService`)

[`RouteApiService`](lib/services/route_api_service.dart) класында барлық операциялар `async/await` арқылы жазылған:
* **GET:** `fetchRoutes()`, `fetchRoute(id)`
* **POST:** `createRoute(route)`
* **PUT:** `updateRoute(route)`
* **PATCH:** `patchRoute(id, fields)`
* **DELETE:** `deleteRoute(id)`

Әр сұрау 8 секундтық timeout-пен қорғалған:
```dart
res = await request().timeout(const Duration(seconds: 8));
```

---

## 5. КҮЙЛЕРДІ БАСҚАРУ ЖӘНЕ ҚАТЕЛЕРДІ ӨҢДЕУ

1. **Loading күйі:** Тізім жүктеліп жатқанда `CircularProgressIndicator()`, ал қосу/өзгерту кезінде экранның үстінде `LinearProgressIndicator()` көрсетіледі.
2. **Success күйі:** Сервер жауабынан кейін тізім жаңарады және жасыл түсті хабарлама (`SnackBar`) шығады.
3. **Error күйлері ([`ApiException`](lib/services/api_exception.dart)):**
   * **Интернет жоқ болса:** `SocketException` / `ClientException` ауланып, «Интернет байланысы жоқ» қатесі және офлайн кэш деректері көрсетіледі.
   * **Timeout (күту уақыты асып кетсе):** `TimeoutException` ауланып, «Сервер жауап бермеді» хабарламасы беріледі.
   * **Сервер қатесі (500):** «Сервер қатесі (500). Кейінірек қайталап көріңіз» хабары шығады.
   * **404:** «Сұралған дерек серверде табылмады (404)».

---

## 6. СЕРВЕР МЕН ЛОКАЛДЫ ДЕРЕКТЕРДІ БАЙЛАНЫСТЫРУ (SYNC REPOSITORY)

[`RouteSyncRepository`](lib/services/route_sync_repository.dart) класы:
1. Серверден алынған жаңа бағыттарды автоматты түрде SQLite дерекқорына кэш ретінде жазады.
2. Егер интернет өшіп қалса немесе сервер сөнсе, қосымша SQLite-тағы кэшті пайдаланып («Офлайн режим: локалды SQLite деректері») жұмысын жалғастырады.

---

## 7. ЖҮЙЕНІ ІСКЕ ҚОСУ ЖӘНЕ ТЕКСЕРУ ТӘРТІБІ

### 1-қадам: Жергілікті REST API серверін іске қосу
Терминалда (жоба папкасында):
```powershell
dart run server/antisleep_api_server.dart
```
Сервер `http://localhost:8080/api/routes` адресінде іске қосылады.

### 2-қадам: Unit-тесттерді тексеру
Барлық 13 желілік тесттерді (GET, POST, PUT, PATCH, DELETE, 500, 404, Timeout, SocketException, Parsing) тексеру:
```powershell
flutter test test/route_api_service_test.dart
```
**Нәтижесі:** `00:00 +13: All tests passed!`

### 3-қадам: Қосымша интерфейсінен тексеру
Қосымшаның басты экранында жаңа карточка қосылды:
* **«Бұлттағы бағыттар» (REST API · сервермен синхрондау)**.
* Мұнда бағыттарды қосу (POST), таңдаулыға ауыстыру (PATCH), өзгерту (PUT) және өшіру (DELETE) толық интерактивті түрде жұмыс істейді.
* Жоғарғы оң жақтағы колба белгісі (🧪) арқылы **«Баяу сервер (Timeout)»** немесе **«Сервер қатесі (500)»** режимдерін таңдап, қателердің қалай өңделетінін тікелей экранда көрсетуге болады.

