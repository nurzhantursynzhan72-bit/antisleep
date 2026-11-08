# ПРАКТИКАЛЫҚ ЖҰМЫС №3
## Тақырыбы: Мобильді қосымшаның құрылымы мен навигациясын әзірлеу
### Жоба атауы: «AntiSleep AI» — Жүргізушінің ұйықтап кетуінің алдын алатын AI қауіпсіздік жүйесі

---

## 1. КІРІСПЕ ЖӘНЕ ЖОБАНЫҢ МАҚСАТЫ

**Практикалық жұмыстың мақсаты:** 
№2 Практикалық жұмыста Figma ортасында жобаланған 15 экранды және интерактивті пайдаланушы сценарийін негізге ала отырып, **Flutter фреймворкінде** қосымшаның толыққанды архитектурасын, модульдік құрылымын, бірыңғай дизайн жүйесін (Theme System), қайта қолданылатын компоненттерді (Reusable Widgets), экрандар арасындағы маршруттық навигацияны (Named Routes & onGenerateRoute), төменгі басқару тақтасын (BottomNavigationBar) және мәліметтерді тексеру формаларын (Form Validation) жүзеге асыру.

---

## 2. ЖОБАНЫҢ АРХИТЕКТУРАЛЫҚ ҚҰРЫЛЫМЫ (CLEAN / FEATURE-BASED ARCHITECTURE)

Жоба индустриялық стандарттарға сай **Layered & Feature-based Clean Architecture** қағидасына сәйкес папкаларға бөлініп ұйымдастырылды:

```
antisleep_ai/
├── android/                        # Android платформалық баптаулары
├── ios/                            # iOS платформалық баптаулары
├── windows/                        # Windows десктоп баптаулары
├── web/                            # Web қолдау файлдары
├── figma_screens/                  # Figma-да жасалған 14-15 экранның рендерлері
│   ├── 01_splash.png
│   ├── 02_onboarding.png
│   ├── 03_auth_login.png
│   ├── 04_forgot_password.png
│   ├── 05_home_dashboard.png
│   ├── 06_tracking_hud.png
│   ├── 07_emergency_alarm.png
│   ├── 08_trip_list.png
│   ├── 09_search_routes.png
│   ├── 10_edit_vehicle.png
│   ├── 11_rest_suggestion.png
│   ├── 12_profile.png
│   ├── 13_settings.png
│   └── 14_help_faq.png
├── lib/                            # Басты бастапқы код (Dart/Flutter)
│   ├── main.dart                   # Қосымшаның кіру нүктесі, MaterialApp, Route регистрациясы
│   ├── models/                     # Деректер модельдері (Data Entities)
│   │   ├── session_model.dart      # Сапар телеметриясы мен қауіпсіздік көрсеткіштері
│   │   └── user_model.dart         # Жүргізуші профилі мен көлік деректері
│   ├── screens/                    # Қосымшаның барлық 15 экраны (UI Layer)
│   │   ├── splash_screen.dart          # 1. Ашылу экраны (Анимациялы логотип + авто-өту)
│   │   ├── onboarding_screen.dart      # 2-3. Таныстыру экрандары (Ұстағыш орнату, AI түсіндірме)
│   │   ├── auth_screen.dart            # 4-5. Кіру және Тіркелу формалары (Validation)
│   │   ├── forgot_password_screen.dart # 5b. Құпиясөзді қалпына келтіру экраны
│   │   ├── home_screen.dart            # 6. Басты Dashboard экраны (BottomNav + Pulsing Start батырмасы)
│   │   ├── tracking_screen.dart        # 7. Белсенді AI бақылау экраны (Cockpit HUD, Face Mesh)
│   │   ├── alarm_screen.dart           # 8. Төтенше жағдайдағы дабыл экраны (Жыпылықтау, Сирена)
│   │   ├── rest_suggestion_screen.dart # 9. 15 минуттық демалыс ұсыну экраны (Кері санақ таймері)
│   │   ├── trip_list_screen.dart       # 10. Сапарлар тарихы экраны (Filter chips)
│   │   ├── trip_detail_screen.dart     # 11. Сапар бойынша толық телеметриялық есеп экраны
│   │   ├── edit_vehicle_screen.dart    # 12. Көлік және SOS байланысты баптау/өңдеу формасы
│   │   ├── search_screen.dart          # 13. Іздеу және Таңдаулы бағыттар экраны (Favorites + Жаңа бағыт)
│   │   ├── settings_screen.dart        # 14. Баптаулар экраны (EAR шегі, дабыл, діріл)
│   │   ├── profile_screen.dart         # 15. Пайдаланушы профилі және жетістік белгілері (Badges)
│   │   └── help_screen.dart            # FAQ және анықтамалық кеңестер экраны
│   ├── services/                   # Бизнес-логика және аппараттық сервистер (Domain/Service Layer)
│   │   ├── ai_detection_service.dart   # EAR көз жұмылуын талдайтын Edge AI қозғалтқышы
│   │   └── audio_service.dart          # Төтенше дабыл сиренасын басқару сервисі
│   ├── utils/                      # Тұрақтылар, дизайн токендері және навигация
│   │   ├── app_colors.dart         # Бірыңғай түстер палитрасы (Figma сәйкестігі)
│   │   ├── app_theme.dart          # ThemeData, Google Fonts Inter, батырма және input стильдері
│   │   └── app_routes.dart         # Орталықтандырылған маршруттар мен onGenerateRoute
│   └── widgets/                    # Қайта қолданылатын компоненттер (Reusable UI Elements)
│       ├── custom_button.dart      # Бірыңғай биіктіктегі басты және қосымша батырмалар
│       ├── custom_text_field.dart  # Тексеруі (Validation) бар әмбебап Input өрісі
│       ├── session_history_item.dart# Сапар тарихының интерактивті карточкасы
│       └── status_card.dart        # Көрсеткіштер мен телеметрия карточкасы
├── test/                           # Автоматтандырылған тестілер
│   ├── widget_test.dart            # Smoke test (Splash render тексеру)
│   └── navigation_test.dart        # Интеграциялық навигация және сценарий тесті
├── pubspec.yaml                    # Тәуелділіктер мен пакеттер тізімі
└── Practical_Work_3_kz.md          # №3 Практикалық жұмыстың ресми есебі
```

---

## 3. ДИЗАЙН СИСТЕМАСЫ: ТҮСТЕР, ТИПОГРАФИКА ЖӘНЕ БІРЫҢҒАЙ ТЕМАНЫ (THEME) БАПТАУ

Қосымшаның интерфейсі Figma прототипіндегі Color Styles пен Typography кестесіне 100% сәйкес бапталды:

### 3.1. Түстер палитрасы (`AppColors` класы):
* **Primary (Негізгі көк):** `#0066FF` (`AppColors.primary`) — басты акцент, батырмалар, белсенді белгішелер.
* **Primary Light (Жұмсақ фон):** `#EBF3FF` (`AppColors.primaryLight`) — статус бейдждерінің фоны, иконкалар астары.
* **Dark Cockpit (Кабина фоны):** `#0F172A` (`AppColors.textPrimary`) — түнгі бақылау HUD режимі және негізгі мәтін.
* **Scaffold Slate (Фон):** `#F8FAFC` (`AppColors.scaffoldBackground`) — жеңіл заманауи сұр фон.
* **Card Surface (Карточкалар):** `#FFFFFF` (`AppColors.surface`) — ақ түсті таза карточкалар.
* **Success Green:** `#10B981` (`AppColors.success`) — «Көз ашық», «Оффлайн AI Дайын», қауіпсіздік статусы.
* **Warning Amber:** `#F59E0B` (`AppColors.warning`) — сақтық ескертулері мен таңдаулы жұлдызшалар.
* **Danger Red:** `#EF4444` (`AppColors.danger`) — ұйқы кезіндегі төтенше дабыл, сирена және сапарды тоқтату.
* **Border:** `#E2E8F0` (`AppColors.border`) — нәзік жиектер мен бөлу сызықтары.

### 3.2. Типографика жүйесі:
Google Fonts кітапханасының халықаралық **Inter** қарібі қосымшаның бүкіл TextTheme құрылымына енгізілді:
* `displayLarge`: 32px, W800 (Splash, басты сандар)
* `headlineMedium`: 24px, W700 (Экран тақырыптары)
* `titleLarge` / `titleMedium`: 16-20px, W600 (Карточка тақырыптары)
* `bodyLarge` / `bodyMedium`: 14-16px, W400-W500 (Мәліметтер, түсіндірмелер)
* `labelLarge`: 14px, W700 (Батырмалар мен чиптер мәтіні)

### 3.3. Жаһандық Theme баптауы (`AppTheme.lightTheme`):
* `CardThemeData`: 16px дөңгеленген бұрыштар (BorderRadius), `AppColors.border` жиегі және жұмсақ көлеңке.
* `ElevatedButtonThemeData`: 54px биіктік, 14px дөңгелену, `#0066FF` түсі, 0dp elevation.
* `InputDecorationTheme`: `#F1F5F9` жұмсақ толтыру фоны, 14px радиус, фокус кезінде 2px көк жиек.

---

## 4. ҚАЙТА ҚОЛДАНЫЛАТЫН КОМПОНЕНТТЕР (REUSABLE WIDGETS)

Кодтың қайталануын болдырмау және жобаның тазалығын арттыру мақсатында `lib/widgets/` папкасында 4 негізгі Master виджет жүзеге асырылды:

1. **`CustomButton` (`custom_button.dart`):**
   * Қолданылуы: Splash, Onboarding, Auth, Tracking, Alarm, Edit Vehicle экрандарындағы барлық негізгі батырмалар.
   * Қасиеттері: `text`, `onPressed`, `isOutlined`, `isLoading`, `icon`, `backgroundColor`, `textColor`, `height`.
   * Жүктелу күйінде `CircularProgressIndicator` көрсетеді, басу кезінде интерактивті көлеңкемен жауап береді.

2. **`CustomTextField` (`custom_text_field.dart`):**
   * Қолданылуы: Кіру, Тіркелу, Құпиясөзді ауыстыру, Көлік параметрлері, Жаңа бағыт қосу формаларында.
   * Қасиеттері: `label`, `hintText`, `prefixIcon`, `isPassword` (құпиясөзді көрсету/жасыру көз иконкасы автоматты жұмыс істейді), `validator`, `keyboardType`.
   * Қате енгізілгенде жиегі қызылға айналып, түсінікті қазақша қате хабарламасын шығарады.

3. **`StatusCard` (`status_card.dart`):**
   * Қолданылуы: Dashboard және Tracking телеметрия блоктарында.
   * Қасиеттері: `title`, `value`, `icon`, `iconColor`, `backgroundColor`.
   * Статус бейджі және орындалу индикаторы бар.

4. **`SessionHistoryItem` (`session_history_item.dart`):**
   * Қолданылуы: Басты беттегі соңғы сапарлар және «Сапарлар тарихы» экранында.
   * Қасиеттері: Сапар уақыты, қауіпсіздік пайыздық көрсеткішіне байланысты түстік градиент (`>=90%` жасыл, `<75%` қызыл), дабыл белгілері.

---

## 5. ЭКРАНДАРДЫҢ ТОЛЫҚ СИПАТТАМАСЫ МЕН FIGMA ДИЗАЙНЫНА СӘЙКЕСТІГІ

Figma прототипіндегі 15 экранның әрқайсысы Flutter виджеттері ретінде толыққанды бағдарламаланды:

| № | Экран атауы | Файл атауы | Негізгі элементтері мен функционалы |
| :-: | :--- | :--- | :--- |
| **1** | **Splash Screen** | `splash_screen.dart` | Қауіпсіздік қалқаны мен көз анимациясы, 2.8 секундтан кейін Onboarding-ке автоматты өту таймері. |
| **2-3**| **Onboarding Screens** | `onboarding_screen.dart` | Смартфонды бекіту нұсқаулығы, PageView парақтау индикаторы, «Өткізіп жіберу» және «Бастау» түймелері. |
| **4** | **Login Screen** | `auth_screen.dart` (Tab 1) | Email мен құпиясөзді тексеру, қателер валидациясы, қонақ ретінде сынау мүмкіндігі. |
| **5** | **Registration Screen** | `auth_screen.dart` (Tab 2) | Жүргізушінің аты-жөні, көлік моделі, email, құпиясөз енгізу және тіркеу формасы. |
| **5b**| **Forgot Password** | `forgot_password_screen.dart` | Email-ге 4 таңбалы SMS/пошта растау кодын жіберу және құпиясөзді жаңарту диалогы. |
| **6** | **Home Dashboard** | `home_screen.dart` | Жүргізуші профилі, «Оффлайн AI Дайын» индикаторы, ірі пульсациялайтын START түймесі, сезімталдық таңдау чиптері. |
| **7** | **Active HUD Tracking**| `tracking_screen.dart` | Cockpit Dark Mode, Face Mesh центровка овали, EAR көрсеткіші, нақты уақыттағы секундомер, Stop батырмасы. |
| **8** | **Emergency Alarm** | `alarm_screen.dart` | Қызыл-қара түсті жыпылықтайтын қауіп фоны, сирена дыбысы, алып «МЕН ОЯУМЫН» батырмасы. |
| **9** | **Rest Suggestion** | `rest_suggestion_screen.dart` | 15 минуттық демалыс кері санақ таймері, жақын жердегі демалыс орындары мен ЖҚС тізімі. |
| **10**| **Trip List** | `trip_list_screen.dart` | Сапарлар тарихының толық тізімі, сүзгі чиптері («Барлығы», «Қауіпсіз», «Қауіпті»), жиынтық статистика. |
| **11**| **Trip Detail** | `trip_detail_screen.dart` | Таңдалған сапардың толық телеметриясы, назар аудару сызықтық графигі, PDF есеп экспорттау түймесі. |
| **12**| **Edit Vehicle** | `edit_vehicle_screen.dart` | Автокөлік маркасы, мемлекеттік нөмірі, жылы, шұғыл жағдайдағы SOS контакт нөмірін сақтау формасы. |
| **13**| **Search & Favorites** | `search_screen.dart` | Бағыттар мен тасжолдарды нақты уақытта іздеу, таңдаулыға қосу/алу, модальды терезе арқылы жаңа бағыт қосу. |
| **14**| **Settings Screen** | `settings_screen.dart` | EAR сезімталдық шегі (Slider), сирена қаттылығы, діріл қосқышы, FAQ бөліміне сілтеме. |
| **15**| **Profile Screen** | `profile_screen.dart` | Пайдаланушы аватары, апатсыз жүрілген сағаттар, «Қырағы жүргізуші» жетістік белгілері (Badges). |
| **+** | **Help & FAQ** | `help_screen.dart` | Қосымшаны пайдалану бойынша сұрақ-жауаптар мен қауіпсіздік кеңестері. |

---

## 6. НАВИГАЦИЯ ЖҮЙЕСІ МЕН МАРШРУТТАР МАТРИЦАСЫ (NAVIGATION & ROUTING)

Қосымшада барлық өтулер `AppRoutes` класы арқылы **Named Routes** және күрделі параметрлер (мысалы, нақты сапар моделі) үшін **`onGenerateRoute`** механизмі арқылы ұйымдастырылды.

### 6.1. Маршруттар реестрі (`AppRoutes`):
```dart
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot_password';
  static const String home = '/home';
  static const String tracking = '/tracking';
  static const String alarm = '/alarm';
  static const String trips = '/trips';
  static const String tripDetail = '/trip_detail';
  static const String search = '/search';
  static const String editVehicle = '/edit_vehicle';
  static const String restSuggestion = '/rest_suggestion';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String help = '/help';
}
```

### 6.2. Толық навигациялық байланыстар кестесі:

| Бастапқы экран | Триггер / Әрекет | Навигация түрі | Мақсатты экран | Берілетін аргументтер |
| :--- | :--- | :--- | :--- | :--- |
| **Splash** | 2.8 секунд өткенде | `pushReplacementNamed` | `Onboarding` | — |
| **Onboarding** | «Өткізіп жіберу» / «Бастау» | `pushReplacementNamed` | `Auth` (Кіру/Тіркелу) | — |
| **Auth** | «Жүйеге кіру» / «Қонақ режимі» | `pushReplacementNamed` | `Home` (Dashboard) | — |
| **Auth** | «Құпиясөзді ұмыттыңыз ба?» | `pushNamed` | `ForgotPassword` | — |
| **Home (Dashboard)** | Ірі пульсациялы «START» батырмасы | `pushNamed` | `Tracking` (HUD) | Сезімталдық деңгейі |
| **Tracking (HUD)** | «Дабылды сынау» / Көз жұмылуы | `pushNamed` | `Alarm` | Дыбыс қаттылығы |
| **Alarm** | «МЕН ОЯУМЫН / ТОҚТАТУ» | `pop` | `Tracking` (HUD) | — |
| **Tracking (HUD)** | «Сапарды тоқтату» | `pushReplacement` | `TripDetail` | Нақты `SessionModel` деректері |
| **Home / BottomNav** | «Сапарлар» қосымшасы | Tab switch (IndexedStack) | `TripList` | — |
| **TripList** | Кез келген сапар карточкасын басу | `pushNamed` / MaterialPageRoute | `TripDetail` | Таңдалған `SessionModel` |
| **Home / BottomNav** | «Бағыттар» қосымшасы | Tab switch (IndexedStack) | `SearchScreen` | — |
| **Home / BottomNav** | «Профиль» қосымшасы | Tab switch (IndexedStack) | `ProfileScreen` | — |
| **Profile** | Көлікті өзгерту қарындаш белгішесі | `pushNamed` | `EditVehicleScreen` | — |
| **Profile** | Баптаулар белгішесі (Gear) | `pushNamed` | `SettingsScreen` | — |
| **Settings** | «Көмек және анықтама (FAQ)» | `pushNamed` | `HelpScreen` | — |

### 6.3. Bottom Navigation Bar ұйымдастырылуы:
Басты экранда (`HomeScreen`) 4 негізгі тармақ `IndexedStack` виджеті арқылы басқарылады:
1. 🏠 **Басты (Home Dashboard)** — Жүргізуші мәртебесі мен бақылауды бастау;
2. 📊 **Сапарлар (Trips)** — Барлық өткен сапарлар тарихы мен сүзгілері;
3. 🛣️ **Бағыттар (Search & Routes)** — Трассаларды іздеу және таңдаулы бағыттар;
4. 👤 **Профиль (Profile)** — Жүргізуші жетістіктері, көлік баптауы және баптаулар мәзірі.

`IndexedStack` қолданылуының арқасында қолданушы бөлімдер арасында ауысқанда экранның күйі мен деректері жоғалмай, бірден лезде ашылады.

---

## 7. ФОРМАЛАРДЫ БАҒДАРЛАМАЛАУ ЖӘНЕ ДЕРЕКТЕРДІ ТЕКСЕРУ (VALIDATION)

Қосымшаның мәлімет енгізу формаларына `GlobalKey<FormState>` және `TextFormField` тексерушілері (validators) толық енгізілді.

### 7.1. Тексеру ережелері мен қазақша хабарламалар:

1. **Email / Электрондық поштаны тексеру:**
   * *Ереже:* Өріс бос болмауы керек және `^[^@]+@[^@]+\.[^@]+` тұрақты өрнегіне (RegExp) сәйкес келуі тиіс.
   * *Қате хабарламасы:* «Электрондық поштаны енгізіңіз» немесе «Email пішімі қате (мысалы: driver@antisleep.kz)».
2. **Құпиясөзді (Password) тексеру:**
   * *Ереже:* Бос болмауы керек, ұзындығы кемінде 6 таңбадан тұруы тиіс.
   * *Қате хабарламасы:* «Құпиясөз өрісі бос болмауы керек» немесе «Құпиясөз кемінде 6 таңбадан тұруы тиіс».
3. **Жүргізуші аты-жөнін тексеру:**
   * *Ереже:* Бос болмауы тиіс, кемінде 2 әріп болуы керек.
   * *Қате хабарламасы:* «Жүргізушінің аты-жөнін жазыңыз».
4. **Көлік моделі мен нөмірін тексеру:**
   * *Ереже:* Бос болмауы тиіс.
   * *Қате хабарламасы:* «Автокөлік маркасын көрсетіңіз» және «Мемлекеттік нөмірді енгізу міндетті».
5. **Шыққан жылын тексеру:**
   * *Ереже:* Сан болуы керек, 1980 мен 2026 жылдар аралығында болуы тиіс.
   * *Қате хабарламасы:* «Жыл 1980 мен 2026 аралығында болуы керек».
6. **SOS телефон нөмірін тексеру:**
   * *Ереже:* Бос болмауы керек, кемінде 8 таңбадан тұруы тиіс.
   * *Қате хабарламасы:* «SOS телефон нөмірін енгізіңіз».

---

## 8. АДАПТИВТІЛІК ЖӘНЕ ҚАТЕЛЕРДІ ТҮЗЕТУ (RESPONSIVE & BUG FIXES)

1. **Экран өлшемдеріне бейімдеу (Responsive Layout):**
   * Барлық енгізу экрандары мен статистикалық парақтар `SingleChildScrollView` виджетімен қорғалды.
   * Пернетақта ашылған кезде (Keyboard appearance) мәтін өрістері жабылып қалмайды және "RenderFlex overflowed by N pixels" қатесі толығымен жойылды.
   * `SafeArea` виджеті барлық экрандарда Notch, Dynamic Island және төменгі Home индикаторларының үстін басып кетуден қорғайды.

2. **Visual & Navigation қателерін түзету:**
   * Flutter 3.38 нұсқасында ескірген (deprecated) `withOpacity()` функциялары жаңа `withValues(alpha: ...)` стандартына көшірілді.
   * `SwitchListTile` ішіндегі ескірген `activeColor` параметрі `activeThumbColor`-ға алмастырылды.
   * `SplashScreen` ішіндегі фондық таймердің жадыдан ағып кету (Memory Leak) қаупі түзетіліп, `dispose()` кезінде `_navTimer?.cancel()` шақырылуы қамтамасыз етілді.
   * Барлық экрандарда `const` конструкторлары дұрыс қолданылып, кадр жиілігі (60-120 FPS) оңтайландырылды.

---

## 9. ТЕСТІЛЕУ НӘТИЖЕЛЕРІ (AUTOMATED & INTEGRATION TESTING)

Жобаның сапасы мен функционалдығы үш деңгейлі тестілеуден өткізілді:

### 9.1. Статикалық кодты тексеру (`flutter analyze`):
```bash
$ flutter analyze
Analyzing ПО проект 2 авто...
No issues found! (ran in 2.8s)
```
Нәтиже: **0 қате, 0 ескерту (Zero warnings/lints)**.

### 9.2. Бастапқы smoke тестілеу (`test/widget_test.dart`):
```bash
$ flutter test test/widget_test.dart
00:00 +0: loading test/widget_test.dart
00:00 +0: AntiSleep AI app starts and renders SplashScreen
00:01 +1: All tests passed!
```
Нәтиже: Ашылу экраны мен анимациялар табысты орындалды.

### 9.3. Интеграциялық навигациялық тестілеу (`test/navigation_test.dart`):
```bash
$ flutter test test/navigation_test.dart
00:00 +0: loading test/navigation_test.dart
00:00 +0: Full Navigation and Form Validation Test Flow
00:01 +2: All tests passed!
```
Тексерілген қадамдар:
1. Splash экранының ашылуы және таймер арқылы Onboarding-ке өтуі;
2. Onboarding экранындағы нұсқаулықты өткізіп, Авторизацияға бағытталуы;
3. Кіру формасын тексеру және қонақ режимі арқылы Басты Dashboard-қа кіруі;
4. Bottom Navigation Bar арқылы Сапарлар тарихы, Бағыттар, Профиль қосымшалары арасында ауысуы;
5. Профиль ішінен «Көлікті өңдеу» формасын ашып, артқа қайтуы;
6. «Баптаулар» экранына өтіп, кері Dashboard-қа оралуы.

---

## 10. ТАПСЫРМАНЫҢ 19 ҚАДАМЫ БОЙЫНША ЕСЕП КЕСТЕСІ

| № | Тапсырма тармағы | Орындалу деңгейі | Түсініктеме / Қолданылған файлдар |
| :-: | :--- | :---: | :--- |
| **1** | Алдыңғы Flutter жобасын ашу және жұмысын тексеру | 100% | Жоба сәтті іске қосылды, Flutter 3.38.8 ортасы қолданылды. |
| **2** | Жоба құрылымын Clean Architecture бойынша ұйымдастыру | 100% | models, screens, services, utils, widgets қабаттары бөлінді. |
| **3** | Экрандар, модельдер, виджеттер, сервистер папкаларын құру | 100% | Барлық қажетті модульдік папкалар толық жасақталды. |
| **4** | Түстерді, шрифттерді және стильдерді Theme арқылы баптау | 100% | `app_colors.dart`, `app_theme.dart` (Google Fonts Inter). |
| **5** | Бірнеше экранда қайталанатын reusable widgets құру | 100% | `CustomButton`, `CustomTextField`, `StatusCard`, `SessionHistoryItem`. |
| **6** | Figma дизайнына сәйкес Splash Screen әзірлеу | 100% | `splash_screen.dart` (Анимация, қалқан логотипі, прогресс-бар). |
| **7** | Login және Registration экрандарын бағдарламалау | 100% | `auth_screen.dart` (Таб ауыстыру, өрістер, қауіпсіз кіру). |
| **8** | Home экранын әзірлеу | 100% | `home_screen.dart` (START AI батырмасы, сәлемдесу, сезімталдық). |
| **9** | List және Detail экрандарын әзірлеу | 100% | `trip_list_screen.dart` және `trip_detail_screen.dart` (Графиктер). |
| **10**| Create/Edit формаларын бағдарламалау | 100% | `edit_vehicle_screen.dart` және `search_screen.dart` (Жаңа бағыт қосу). |
| **11**| Search, Favorites, Profile, Settings экрандарын әзірлеу | 100% | `search_screen.dart`, `profile_screen.dart`, `settings_screen.dart`. |
| **12**| Экрандар арасында routes арқылы өтулерді іске асыру | 100% | `app_routes.dart` (17 named route, `onGenerateRoute`). |
| **13**| Bottom Navigation Bar жұмысын ұйымдастыру | 100% | `HomeScreen` ішінде 4 бөлімді `BottomNavigationBar` мен `IndexedStack`. |
| **14**| Мәлімет енгізу формаларына validation қосу | 100% | `GlobalKey<FormState>`, `TextFormField` қатаң тексеру алгоритмдері. |
| **15**| Қате email, бос пароль, бос өрістерге түсінікті хабарламалар | 100% | Қазақ тіліндегі нақты ескерту хабарламалары қойылды. |
| **16**| Интерфейсті әртүрлі экран өлшемдеріне бейімдеу | 100% | `SingleChildScrollView`, `SafeArea`, `Flexible` қолданылды. |
| **17**| Figma прототипі мен Flutter интерфейсін салыстыру | 100% | 15 экранның түстері, радиустары мен орналасуы сәйкестендірілді. |
| **18**| Визуалды және навигациялық қателерді түзету | 100% | Linter ескертулері жойылды, timer leak мәселесі шешілді. |
| **19**| Экрандардың ашылуын және өзара дұрыс байланысуын тексеру | 100% | `flutter test` интеграциялық тестілері сәтті өтті. |

---

## 11. ҚОРЫТЫНДЫ

№3 Практикалық жұмыс талаптары толық көлемде орындалды:
1. Figma ортасында жасалған 15 экранның мобильді интерфейсі Flutter фреймворкінде сапалы, эстетикалық жағынан мінсіз етіп бағдарламаланды.
2. Қосымшаның масштабталатын **Clean Architecture** құрылымы жасалып, орталықтандырылған **Named Routes** және **BottomNavigationBar** навигациясы орнатылды.
3. Енгізу өрістеріне толыққанды қазақша **Form Validation** тексерулері қосылып, пайдаланушының қате мәліметтер енгізуінен қорғалды.
4. Қосымша код сапасының ең жоғары талаптарына сәйкес келеді (`flutter analyze` — 0 warnings, `flutter test` — All tests passed).
