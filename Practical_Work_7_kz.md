# ПРАКТИКАЛЫҚ ЖҰМЫС №7
## Тақырыбы: Flutter жобасын баптау және тәуелділіктерді басқару (WebSocket Realtime, Рефакторинг, Логирование, Тестілеу және Қателерді түзету)
### Жоба атауы: «AntiSleep AI» — Жүргізушінің ұйықтап кетуінің алдын алатын AI жүйесі

---

## 1. НАҚТЫ УАҚЫТТАҒЫ СЦЕНАРИЙ ЖӘНЕ WEBSOCKET (Tasks 1-4)

«AntiSleep AI» жүйесі үшін нақты уақыттағы екіжақты байланыс сценарийі ретінде **«Live Telemetry Stream & Dispatcher Emergency Center» (Жүргізуші телеметриясы мен диспетчерлік орталық байланысы)** таңдалды:

1. **Технология:** `web_socket_channel: ^3.0.1` және Dart `WebSocketTransformer`.
2. **WebSocket Endpoint:** `ws://localhost:8080/ws/telemetry` (Android эмуляторында: `ws://10.0.2.2:8080/ws/telemetry`).
3. **Серверлік іске асыру:** [`server/antisleep_api_server.dart`](server/antisleep_api_server.dart) ішінде WebSocket қосылымдары, клиенттерді бақылау және жол/ауа райы ескертулерін периодты трансляциялау (`_startBroadcastLoop`) енгізілді.

---

## 2. НАҚТЫ УАҚЫТТА ДЕРЕКТЕР АЛМАСУ (Tasks 5-6)

### Жіберілетін телеметрия пакеті (Client $\rightarrow$ Server):
[`DriverTelemetry`](lib/models/realtime_message_model.dart):
* `ear` (Eye Aspect Ratio): көздің ашылу коэффициенті (мысалы, 0.28);
* `eyeOpenness`: көздің ашылу пайызы (92%);
* `speed`: көліктің ағымдағы жылдамдығы (км/сағ);
* `drowsy`: ұйқы қаупінің белгісі (`true`/`false`);
* `safetyScore`: қауіпсіздік индексі.

### Қабылданатын хабарламалар (Server $\rightarrow$ Client):
[`RealtimeMessage`](lib/models/realtime_message_model.dart):
* `telemetry_ack`: сервер телеметрияны сәтті қабылдағанын растайды;
* `dispatcher_alert`: егер көз ұзақ жұмылса, диспетчерден автоматты шұғыл ескерту жіберіледі;
* `traffic_broadcast`: жолдағы ауа райы, тұман және демалыс орындары туралы live хабарламалар.

---

## 3. БАЙЛАНЫС ҮЗІЛУІН, ҚАЙТА ҚОСЫЛУДЫ ЖӘНЕ OFFLINE КҮЙІН ӨҢДЕУ (Tasks 7-9)

[`RealtimeTelemetryService`](lib/services/realtime_telemetry_service.dart) сервисінде 5 байланыс күйі қарастырылған:
* 🟢 **`connected`** — Нақты уақыттағы байланыс орнатылды;
* 🟡 **`connecting`** / **`reconnecting`** — Серверге қосылу немесе байланысты қалпына келтіру жүруде;
* 🔴 **`disconnected`** — Желі үзілді (Offline режим);
* ❌ **`error`** — Қосылу қатесі.

### Экспоненциалды қайта қосылу (Auto-Reconnect):
Байланыс үзілгенде автоматты түрде қайта қосылу таймері іске қосылады: $t = \min(\text{attempt} \times 2, 10)$ секунд. Лимит: 5 рет.

---

## 4. РЕФАКТОРИНГ ЖӘНЕ ЛОГТАРДЫ ЖҮРГІЗУ (Tasks 10-13)

1. **Кодты рефакторингтеу:**
   * Басты беттегі қайталанатын карточкалар `_buildQuickActionCard` әмбебап компонентіне көшірілді.
   * `lib/services/database_service.dart` ішіндегі пайдаланылмаған `removed` айнымалысы жойылды.
   * Тест файлдарындағы артық импорттар тазартылды.
2. **Жүйелік логгер әзірлеу ([`AppLogger`](lib/utils/app_logger.dart)):**
   * Лог деңгейлері: `debug`, `info`, `warning`, `error`.
   * Соңғы 200 лог жазбасы жедел жадта сақталады және уақыт белгісімен (`hh:mm:ss.ms`) консольге әрі қосымшаның интерфейсіндегі төменгі панельге шығарылады.

---

## 5. ТЕСТІЛЕУ ЖӘНЕ АНЫҚТАЛҒАН ҚАТЕЛЕРДІ ТҮЗЕТУ (Tasks 14-19)

### Әзірленген тесттер тізімі ([`test/practical_7_test.dart`](test/practical_7_test.dart)):
1. **Тест 1:** `RealtimeMessage` JSON десериализациясы және `isAlert` қауіпті анықтау логикасы.
2. **Тест 2:** `DriverTelemetry` JSON форматы мен міндетті өрістердің дұрыстығы.
3. **Тест 3:** `AppLogger` жүйесінің ақпараттық және қате логтарын тіркеуі мен тазартуы.
4. **Тест 4:** `RealtimeProvider` күйлері, телеметрия пакеттерін есептеу және диспетчер дабылдарын басқару.
5. **Тест 5:** Байланыс үзілген және Offline күйін өңдеу, байланысты қолмен үзу симуляциясы.
6. **Тест 6 (Widget Test):** `RealtimeHubScreen` интерфейсінің дұрыс салынуы және басқару батырмаларының көрінуі.

---

### Тестілеу кезінде анықталған қателер тізімі және түзетулер (Tasks 16-18):

| № | Анықталған қате | Пайда болу себебі | Қалай түзетілді |
|---|---|---|---|
| **1** | `test/database_service_test.dart`: `The property 'isOpen' can't be unconditionally accessed` | SQLite базасы `null` қайтаруы мүмкін болғандықтан компилятор ескертті | `expect(db, isNotNull); expect(db!.isOpen, isTrue);` тексеруі қойылды |
| **2** | `lib/services/database_service.dart`: `The value of local variable 'removed' isn't used` | `removeWhere` нәтижесін айнымалыға телу артық болды | Артық `final removed =` алынып тасталды |
| **3** | `RealtimeProvider.sendTelemetry()`: Офлайн кезде соңғы телеметрия сақталмады | `if (sent)` шартының ішінде ғана жазылып тұрған | Телеметрия нысаны желі күйіне қарамастан `_latestSentTelemetry` кэшіне сақталатын етіп түзетілді |
| **4** | `RealtimeHubScreen`: `RenderFlex overflowed by 17 pixels` | Телефон өлшемінде мәтін ұзын болып, экраннан 17 пиксель шығып кетті | Мәтін `Expanded` виджетіне оралып, көлемі бейімделді |
| **5** | Widget Test: `A Timer is still pending even after the widget tree was disposed` | Экран автоматты түрде 5 секундтық WebSocket күту таймерін қосқан | Экранға `autoConnect: false` параметрі қосылып, тест аяқталғанда байланыс қауіпсіз жабылды |

---

## 6. ҚАЙТА ТЕСТІЛЕУ ЖӘНЕ ҚОРЫТЫНДЫ (Tasks 19-20)

Барлық түзетулерден кейін тестілеу қайта жүргізілді:

```powershell
flutter test test/practical_6_test.dart test/practical_7_test.dart test/route_api_service_test.dart test/database_service_test.dart
```

### Нәтиже:
```
00:01 +37: All tests passed!
```
Барлық **37 тест сәтті өтті**. `flutter analyze` нәтижесі: **No issues found!**
Қосымшаның жалпы тұрақтылығы мен негізгі функцияларының жұмысы толық тексерілді.

