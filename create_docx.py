# -*- coding: utf-8 -*-
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import parse_xml, OxmlElement
from docx.oxml.ns import nsdecls, qn

def create_document():
    doc = docx.Document()

    # Page Margins (GOST standard: Left 30mm, Right 15mm, Top 20mm, Bottom 20mm)
    for section in doc.sections:
        section.top_margin = Inches(0.79)     # 20 mm
        section.bottom_margin = Inches(0.79)  # 20 mm
        section.left_margin = Inches(1.18)    # 30 mm
        section.right_margin = Inches(0.59)   # 15 mm

    # Colors
    PRIMARY_COLOR = RGBColor(0, 102, 255)       # #0066FF
    DARK_BLUE = RGBColor(15, 23, 42)           # #0F172A
    SECONDARY_COLOR = RGBColor(31, 78, 121)    # #1F4E79
    GRAY_TEXT = RGBColor(100, 116, 139)        # #64748B
    CODE_COLOR = RGBColor(30, 41, 59)          # #1E293B

    # Base Styles
    normal_style = doc.styles['Normal']
    normal_style.font.name = 'Times New Roman'
    normal_style.font.size = Pt(12)
    normal_style.font.color.rgb = DARK_BLUE
    normal_style.paragraph_format.line_spacing = 1.15
    normal_style.paragraph_format.space_after = Pt(6)

    def set_cell_background(cell, fill_hex):
        tcPr = cell._tc.get_or_add_tcPr()
        shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
        tcPr.append(shd)

    def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
        tcPr = cell._tc.get_or_add_tcPr()
        tcMar = parse_xml(f'<w:tcMar {nsdecls("w")}><w:top w:w="{top}" w:type="dxa"/><w:bottom w:w="{bottom}" w:type="dxa"/><w:left w:w="{left}" w:type="dxa"/><w:right w:w="{right}" w:type="dxa"/></w:tcMar>')
        tcPr.append(tcMar)

    def add_title(text):
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(12)
        p.paragraph_format.space_after = Pt(6)
        run = p.add_run(text)
        run.bold = True
        run.font.name = 'Times New Roman'
        run.font.size = Pt(16)
        run.font.color.rgb = PRIMARY_COLOR
        return p

    def add_heading1(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(16)
        p.paragraph_format.space_after = Pt(6)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.bold = True
        run.font.name = 'Times New Roman'
        run.font.size = Pt(14)
        run.font.color.rgb = SECONDARY_COLOR
        return p

    def add_heading2(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(12)
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.bold = True
        run.font.name = 'Times New Roman'
        run.font.size = Pt(12.5)
        run.font.color.rgb = PRIMARY_COLOR
        return p

    def add_code_block(code_text):
        table = doc.add_table(rows=1, cols=1)
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        table.autofit = False
        cell = table.cell(0, 0)
        cell.width = Inches(6.5)
        set_cell_background(cell, "F1F5F9")
        set_cell_margins(cell, top=120, bottom=120, left=180, right=180)
        
        # Border
        tcPr = cell._tc.get_or_add_tcPr()
        borders = parse_xml(f'<w:tcBorders {nsdecls("w")}><w:left w:val="single" w:sz="18" w:space="0" w:color="0066FF"/><w:top w:val="none"/><w:right w:val="none"/><w:bottom w:val="none"/></w:tcBorders>')
        tcPr.append(borders)

        p = cell.paragraphs[0]
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        p.paragraph_format.line_spacing = 1.05
        run = p.add_run(code_text.strip())
        run.font.name = 'Consolas'
        run.font.size = Pt(9.5)
        run.font.color.rgb = CODE_COLOR
        doc.add_paragraph()

    def add_note_box(title, text):
        table = doc.add_table(rows=1, cols=1)
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        cell = table.cell(0, 0)
        cell.width = Inches(6.5)
        set_cell_background(cell, "EBF3FF")
        set_cell_margins(cell, top=140, bottom=140, left=180, right=180)
        
        tcPr = cell._tc.get_or_add_tcPr()
        borders = parse_xml(f'<w:tcBorders {nsdecls("w")}><w:left w:val="single" w:sz="24" w:space="0" w:color="0066FF"/><w:top w:val="none"/><w:right w:val="none"/><w:bottom w:val="none"/></w:tcBorders>')
        tcPr.append(borders)

        p = cell.paragraphs[0]
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(3)
        run_title = p.add_run(f"📌 {title}\n")
        run_title.bold = True
        run_title.font.name = 'Times New Roman'
        run_title.font.size = Pt(11.5)
        run_title.font.color.rgb = PRIMARY_COLOR

        run_text = p.add_run(text)
        run_text.font.name = 'Times New Roman'
        run_text.font.size = Pt(11)
        run_text.font.color.rgb = DARK_BLUE
        doc.add_paragraph()

    # ==================== ТИТУЛДЫҚ БӨЛІМ ====================
    p_header = doc.add_paragraph()
    p_header.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_uni = p_header.add_run("ҚАЗАҚСТАН РЕСПУБЛИКАСЫ ҒЫЛЫМ ЖӘНЕ ЖОҒАРЫ БІЛІМ МИНИСТРЛІГІ\nАҚПАРАТТЫҚ ТЕХНОЛОГИЯЛАР ЖӘНЕ БАҒДАРЛАМАЛЫҚ ИНЖЕНЕРИЯ КАФЕДРАСЫ\n")
    r_uni.font.size = Pt(11)
    r_uni.font.color.rgb = GRAY_TEXT
    r_uni.bold = True

    doc.add_paragraph()
    doc.add_paragraph()

    p_work = doc.add_paragraph()
    p_work.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_work = p_work.add_run("ПРАКТИКАЛЫҚ ЖҰМЫС №4")
    r_work.bold = True
    r_work.font.size = Pt(18)
    r_work.font.color.rgb = PRIMARY_COLOR

    p_topic = doc.add_paragraph()
    p_topic.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_topic = p_topic.add_run("Тақырыбы: Пайдаланушы интерфейсінің макеттерін әзірлеу.\nЛокалды деректер базасы, CRUD операциялары, іздеу және сүзгілеу")
    r_topic.bold = True
    r_topic.font.size = Pt(14)
    r_topic.font.color.rgb = SECONDARY_COLOR

    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_sub = p_sub.add_run("Жоба атауы: «AntiSleep AI» — Жүргізушінің ұйықтап кетуінің алдын алатын мобильді қауіпсіздік жүйесі\nПлатформа: Flutter / Dart (SQLite Persistence)")
    r_sub.font.size = Pt(12)
    r_sub.font.italic = True
    r_sub.font.color.rgb = GRAY_TEXT

    doc.add_paragraph()
    doc.add_paragraph()

    # Орындаған / Тексерген блогы
    p_info = doc.add_paragraph()
    p_info.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    r_info = p_info.add_run("Орындаған: Студент\nТексерген: Оқытушы\nБағасы: ___________\n")
    r_info.font.size = Pt(12)
    r_info.bold = True

    doc.add_paragraph()
    doc.add_paragraph()

    p_city = doc.add_paragraph()
    p_city.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_city = p_city.add_run("Алматы, 2026 ж.")
    r_city.font.size = Pt(11)
    r_city.font.color.rgb = GRAY_TEXT

    doc.add_page_break()

    # ==================== ЖҰМЫС МАЗМҰНЫ ====================
    add_title("ПРАКТИКАЛЫҚ ЖҰМЫСТЫҢ ЕСЕБІ")

    add_note_box(
        "Практикалық жұмыстың мақсаты",
        "Flutter мобильді қосымшасында реляциялық локалды деректер қорын (SQLite) жобалау және құру, 4–6 өзара байланысқан Entity/Model кластарын жасау, "
        "толыққанды CRUD (Create, Read, Update, Delete) операцияларын, нақты уақыттағы іздеуді (Search), критерийлер бойынша сүзгілеуді (Filtering), "
        "екі параметр бойынша сұрыптауды (Sorting), Таңдаулылар (Favorites) жүйесін және интернетсіз толыққанды оффлайн деректер тұрақтылығын (Persistence) жүзеге асыру."
    )

    # 1. Қосымшада сақталатын негізгі ақпарат түрлері
    add_heading1("1. Қосымшада сақталатын негізгі ақпарат түрлерін анықтау")
    doc.add_paragraph(
        "«AntiSleep AI» қосымшасы көлік жүргізу кезіндегі қауіпсіздікті қамтамасыз ететін Edge AI жүйесі болғандықтан, "
        "интернет байланысы мүлдем жоқ тасжолдарда да оффлайн жұмыс істеуге міндетті. Сол себепті жүйеде келесі 6 негізгі ақпарат түрі анықталды:"
    )
    bullet_points_1 = [
        ("Жүргізуші профилі (Users):", " Жүргізушінің дербес деректері, байланыс ақпараты, жинақталған апатсыз қауіпсіз сағаттары мен рейтингі."),
        ("Көлік құралы туралы мәліметтер (Vehicles):", " Жүргізушінің тіркелген автокөліктерінің маркасы, моделі, мемлекеттік тіркеу нөмірі (GRNZ) және шыққан жылы."),
        ("Бағыттар мен қауіпті трассалар (Routes):", " Бағыт атауы, қашықтығы, орташа өту уақыты, қауіптілік деңгейі (монотонды, түнгі), жүргізуші белгілеген «Таңдаулы» күйі және ескертпелері."),
        ("Сапарлар мен мониторинг сессиялары (Trip Sessions):", " Компьютерлік көру арқылы бақыланған әрбір сапардың басталу/аяқталу уақыты, ұзақтығы, қауіп дабылдары, есінеу саны және қауіпсіздік ұпайы (0–100%)."),
        ("Төтенше оқиғалар журналы (Alert Events):", " Сапар кезіндегі нақты уақыттағы микроұйқылар, есінеулер, EAR (Eye Aspect Ratio) көз коэффициенті және қабылданған шаралар."),
        ("Шұғыл байланыс контактілері (Emergency SOS Contacts):", " Жүргізуші ұйықтап кетіп, дабылға жауап бермеген жағдайда автоматты хабарлама жіберілетін жақын адамдарының телефондары.")
    ]
    for b_title, b_desc in bullet_points_1:
        p = doc.add_paragraph(style='List Bullet')
        r_b = p.add_run(b_title)
        r_b.bold = True
        p.add_run(b_desc)

    # 2. Пәндік салаға сәйкес 4–6 Entity/Model құру
    add_heading1("2. Пәндік салаға сәйкес өзара байланысты 6 Entity/Model құру")
    doc.add_paragraph(
        "Clean Architecture және Feature-based қағидаларына сәйкес `lib/models/` бумасында пәндік саланың толыққанды "
        "6 мәліметтер моделі жасалды:"
    )
    models_list = [
        "UserModel (lib/models/user_model.dart) — Пайдаланушы аккаунты мен статистикалық деректерін сипаттайды.",
        "VehicleModel (lib/models/vehicle_model.dart) — Жүргізушіге бекітілген автокөлікті сипаттайды.",
        "RouteModel (lib/models/route_model.dart) — Қалааралық бағыттар мен тасжолдарды сипаттайды.",
        "SessionModel (lib/models/session_model.dart) — Әрбір жеке AI бақылау сапарының телеметриясын сақтайды.",
        "AlertEventModel (lib/models/alert_event_model.dart) — Сапар ішіндегі микроұйқы және дабыл оқиғаларын журналдайды.",
        "EmergencyContactModel (lib/models/emergency_contact_model.dart) — Шұғыл байланыс контактісін сипаттайды."
    ]
    for m in models_list:
        p = doc.add_paragraph(style='List Bullet')
        p.add_run(m)

    # 3. Өрістер, деректер типтері және идентификаторлар кестесі
    add_heading1("3. Әр модель үшін қажетті өрістерді, деректер типтерін және идентификаторларды анықтау")
    doc.add_paragraph(
        "Барлық модельдерде бірегей бастапқы кілттер (`PRIMARY KEY`), кестеаралық байланыстырушы сыртқы кілттер (`FOREIGN KEY`) "
        "және қатаң типтелген өрістер анықталды. Төменде мәліметтердің толық спецификациясы келтірілген:"
    )

    # Кесте жасау
    table_fields = doc.add_table(rows=1, cols=6)
    table_fields.alignment = WD_TABLE_ALIGNMENT.CENTER
    table_fields.autofit = True

    headers = ["Модель", "Өріс атауы", "Dart типі", "SQLite типі", "Кілт / Шектеу", "Сипаттамасы"]
    hdr_cells = table_fields.rows[0].cells
    for i, h_text in enumerate(headers):
        hdr_cells[i].text = h_text
        set_cell_background(hdr_cells[i], "0066FF")
        p = hdr_cells[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        for run in p.runs:
            run.bold = True
            run.font.name = 'Times New Roman'
            run.font.size = Pt(10)
            run.font.color.rgb = RGBColor(255, 255, 255)

    data_fields = [
        ("UserModel", "id", "String", "TEXT", "PRIMARY KEY", "Пайдаланушы бірегей ID кілті"),
        ("UserModel", "fullName", "String", "TEXT", "NOT NULL", "Жүргізушінің толық аты-жөні"),
        ("UserModel", "email", "String", "TEXT", "NOT NULL", "Электрондық поштасы"),
        ("UserModel", "vehicleModel", "String", "TEXT", "NOT NULL", "Негізгі автокөлік атауы"),
        ("UserModel", "plateNumber", "String", "TEXT", "NOT NULL", "Мемлекеттік тіркеу нөмірі"),
        ("UserModel", "totalSafeHours", "double", "REAL", "NOT NULL", "Қауіпсіз сағаттар қоры"),
        ("UserModel", "totalTrips", "int", "INTEGER", "NOT NULL", "Барлық сапарлар саны"),
        ("VehicleModel", "id", "String", "TEXT", "PRIMARY KEY", "Көлік бірегей ID кілті"),
        ("VehicleModel", "userId", "String", "TEXT", "FOREIGN KEY", "users(id) кестесіне сілтеме"),
        ("VehicleModel", "brand, model", "String", "TEXT", "NOT NULL", "Көлік маркасы мен моделі"),
        ("VehicleModel", "plateNumber", "String", "TEXT", "NOT NULL", "Мемлекеттік нөмірі"),
        ("VehicleModel", "year", "int", "INTEGER", "NOT NULL", "Шыққан жылы"),
        ("VehicleModel", "isDefault", "bool", "INTEGER", "DEFAULT 1", "Негізгі таңдалған күйі"),
        ("RouteModel", "id", "String", "TEXT", "PRIMARY KEY", "Бағыттың ID кілті"),
        ("RouteModel", "title", "String", "TEXT", "NOT NULL", "Бағыт атауы (Алматы-Қонаев)"),
        ("RouteModel", "distanceKm", "double", "REAL", "NOT NULL", "Қашықтығы (км)"),
        ("RouteModel", "avgDurationMinutes", "int", "INTEGER", "NOT NULL", "Орташа жүру уақыты (мин)"),
        ("RouteModel", "riskLevel", "String", "TEXT", "NOT NULL", "Қауіп деңгейі (Төмен, Орташа, Қатерлі)"),
        ("RouteModel", "isFavorite", "bool", "INTEGER", "DEFAULT 0", "Таңдаулы күйі (Favorites)"),
        ("SessionModel", "id", "String", "TEXT", "PRIMARY KEY", "Сапардың ID кілті"),
        ("SessionModel", "userId, vehicleId", "String", "TEXT", "FOREIGN KEYS", "users және vehicles кестелеріне сілтеме"),
        ("SessionModel", "startTime, endTime", "DateTime", "TEXT", "NOT NULL", "Сапар уақыттары (ISO8601)"),
        ("SessionModel", "duration", "Duration", "INTEGER", "NOT NULL", "Секундтағы ұзақтығы"),
        ("SessionModel", "safetyScore", "double", "REAL", "NOT NULL", "Қауіпсіздік пайызы (0–100%)"),
        ("AlertEventModel", "id", "String", "TEXT", "PRIMARY KEY", "Дабыл оқиғасының ID кілті"),
        ("AlertEventModel", "sessionId", "String", "TEXT", "FOREIGN KEY", "sessions(id) сілтемесі"),
        ("AlertEventModel", "earValue", "double", "REAL", "NOT NULL", "Көз ашылу шамасы (EAR)"),
        ("EmergencyContact", "id, userId", "String", "TEXT", "PK, FK", "Байланыс ID және пайдаланушы ID"),
        ("EmergencyContact", "name, phone", "String", "TEXT", "NOT NULL", "Аты және телефон нөмірі")
    ]

    for row_idx, d in enumerate(data_fields):
        row_cells = table_fields.add_row().cells
        bg_color = "F8FAFC" if row_idx % 2 == 1 else "FFFFFF"
        for col_idx, text in enumerate(d):
            row_cells[col_idx].text = text
            set_cell_background(row_cells[col_idx], bg_color)
            p = row_cells[col_idx].paragraphs[0]
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(2)
            for run in p.runs:
                run.font.name = 'Times New Roman'
                run.font.size = Pt(9)
                run.font.color.rgb = DARK_BLUE

    doc.add_paragraph()

    # 4. Модельдер арасындағы логикалық байланыс
    add_heading1("4. Модельдер арасындағы логикалық байланысты белгілеу")
    doc.add_paragraph(
        "Деректердің тұтастығы (Integrity) мен қалыпқа келтірілуін (Normalization) сақтау үшін келесі реляциялық байланыстар бекітілді:"
    )
    relations = [
        "User (1) ── (N) Vehicle: Бір жүргізуші бірнеше автокөлікке иелік ете алады. Пайдаланушы өшкенде, көліктер де автоматты жойылады (CASCADE).",
        "User (1) ── (N) EmergencyContact: Бір жүргізуші бірнеше шұғыл SOS контактісін тіркей алады (CASCADE).",
        "User (1) ── (N) Session: Бір жүргізуші көптеген сапарларды орындайды.",
        "Vehicle (1) ── (N) Session: Бір көлікте бірнеше рет қауіпсіздік сапары жүргізіледі.",
        "Route (1) ── (N) Session: Белгілі бір бағыт бойынша бірнеше сапар жүзеге асырылуы мүмкін. Бағыт өшкенде сапар тарихы сақталып, route_id өрісі бос мәнге айналады (SET NULL).",
        "Session (1) ── (N) AlertEvent: Бір сапар сессиясының ішінде бірнеше микроұйқы және есінеу дабылдары оқиға ретінде тіркеледі (CASCADE)."
    ]
    for r in relations:
        p = doc.add_paragraph(style='List Bullet')
        p.add_run(r)

    # 5. SQLite vs Hive таңдауы
    add_heading1("5. Локалды деректерді сақтау үшін SQLite технологиясын таңдау және негіздемесі")
    doc.add_paragraph(
        "Жобада NoSQL Hive кітапханасы мен Реляциялық SQLite кітапханаларының артықшылықтары сараланып, **SQLite** таңдалды. Негіздемесі:"
    )
    sqlite_reasons = [
        ("Реляциялық қатынастар мен Foreign Keys:", " AntiSleep AI деректер құрылымы жүргізуші, көлік, сапар және дабыл кестелерін өзара байланыстырады. SQLite мұндай кілттерді ядролық деңгейде қорғайды."),
        ("Қуатты SQL сүзгілеу және сұрыптау:", " Бағыттар мен сапарларды қашықтығы, уақыты, қауіп деңгейі және іздеу сөзі бойынша бір сұраныспен (WHERE ... LIKE ... ORDER BY) сүзіп алу Hive-ке қарағанда әлдеқайда оңтайлы."),
        ("ACID транзакциялары және сенімділік:", " Көлік жүргізу кезінде құрылғы батареясы кенет сөніп қалса да, деректер қоры бұзылмайды және тұтастығы сақталады."),
        ("Кросс-платформалық FFI интеграциясы:", " `sqflite_common_ffi` арқылы Windows, macOS, Linux және Flutter Unit/Widget тест ортасында еш қиындықсыз орындалады.")
    ]
    for r_title, r_desc in sqlite_reasons:
        p = doc.add_paragraph(style='List Bullet')
        r_b = p.add_run(r_title)
        r_b.bold = True
        p.add_run(r_desc)

    # 6. Таңдалған кітапхананы орнату және баптау
    add_heading1("6. Таңдалған кітапхананы Flutter жобасына орнату және баптау")
    doc.add_paragraph("`pubspec.yaml` файлына SQLite және файлдық жолдарды басқару кітапханалары қосылды:")
    add_code_block("""dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  sqflite_common_ffi: ^2.3.0
  path: ^1.9.0""")
    doc.add_paragraph(
        "`lib/services/database_service.dart` файлында кез келген платформаны (Android, iOS, Windows, Tests) қолдайтын FFI баптаушысы енгізілді:"
    )
    add_code_block("""static void setupFfiIfNeeded() {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}""")

    # 7. Деректер қорын инициализациялау
    add_heading1("7. Деректер қорын инициализациялау (DatabaseService)")
    doc.add_paragraph(
        "`DatabaseService` класы Singleton үлгісінде іске асырылды. Қосымша іске қосылғанда `antisleep_ai.db` файлы ашылып, "
        "кестелер құрылады және бастапқы сынақ деректерімен (Seed Data) толтырылады:"
    )
    add_code_block("""Future<Database> _initDB(String filePath) async {
  setupFfiIfNeeded();
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, filePath);

  return await openDatabase(
    path,
    version: 1,
    onCreate: _createDB,
    onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
  );
}""")

    # 8. Create операциясы
    add_heading1("8. Жаңа жазба қосуға арналған Create операциясын іске асыру")
    doc.add_paragraph(
        "Жаңа деректерді деректер қорына сақтау әдісі `DatabaseService` және `RouteRepository` ішінде жазылды:"
    )
    add_code_block("""Future<int> insertRoute(RouteModel route) async {
  final db = await database;
  return await db.insert(
    'routes',
    route.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}""")
    doc.add_paragraph(
        "`search_screen.dart` экранында AppBar-дағы «+» батырмасын басқанда төменнен модальді форма ашылып, "
        "Form Validation арқылы жаңа қалааралық бағыт қашықтығы, уақыты және қауіп деңгейімен қосылады. "
        "Сондай-ақ сапар аяқталғанда `tracking_screen.dart` сапар мен дабылдарды автоматты сақтайды."
    )

    # 9. Read операциясы
    add_heading1("9. Деректерді оқуға және экранда көрсетуге арналған Read операциясын іске асыру")
    doc.add_paragraph(
        "Деректерді базадан оқу сүзгілеу мен сұрыптау мүмкіндігімен біріктірілген:"
    )
    add_code_block("""Future<List<RouteModel>> getRoutes({
  String query = '',
  bool onlyFavorites = false,
  String? riskFilter,
  String sortBy = 'created_at',
  bool ascending = false,
}) async {
  final db = await database;
  // WHERE clauses + ORDER BY құрастыру
  final List<Map<String, dynamic>> maps = await db.query(
    'routes',
    where: whereString,
    whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    orderBy: '$sortBy ${ascending ? "ASC" : "DESC"}',
  );
  return maps.map((map) => RouteModel.fromMap(map)).toList();
}""")
    doc.add_paragraph(
        "Экрандар (`search_screen.dart`, `trip_list_screen.dart`, `profile_screen.dart`) ашылғанда осы әдістер арқылы "
        "деректер қорынан нақты жазбаларды оқып, `ListView.builder` компонентімен рендерлейді."
    )

    # 10. Update операциясы
    add_heading1("10. Бар жазбаны өзгертуге арналған Update операциясын іске асыру")
    doc.add_paragraph(
        "Бар жазбаның өрістерін жаңарту SQL `UPDATE` операторы арқылы жүзеге асырылады:"
    )
    add_code_block("""Future<int> updateRoute(RouteModel route) async {
  final db = await database;
  return await db.update(
    'routes',
    route.toMap(),
    where: 'id = ?',
    whereArgs: [route.id],
  );
}""")
    doc.add_paragraph(
        "Пайдаланушы карточкадағы үш нүктені басып «Өңдеу» менюін таңдағанда, деректері толтырылған форма ашылып, "
        "атауын, қашықтығын немесе қауіп деңгейін өзгертіп сақтай алады. Сондай-ақ `edit_vehicle_screen.dart` арқылы көлік пен SOS деректері жаңартылады."
    )

    # 11. Delete операциясы
    add_heading1("11. Жазбаны өшіруге арналған Delete операциясын іске асыру")
    doc.add_paragraph(
        "Жазбаны өшіру қауіпсіздік мақсатында растау диалогымен (`AlertDialog`) қорғалған:"
    )
    add_code_block("""Future<int> deleteRoute(String id) async {
  final db = await database;
  return await db.delete(
    'routes',
    where: 'id = ?',
    whereArgs: [id],
  );
}""")
    doc.add_paragraph(
        "Пайдаланушы «Өшіруді растайсыз ба?» сұрағына «Өшіру» түймесін басқанда ғана элемент деректер қорынан біржола өшіріледі "
        "және SnackBar арқылы растау көрсетіледі. Сапарлар тарихы экранында сапарды солға сырғыту (`Dismissible`) арқылы өшіру қосылған."
    )

    # 12. Repository қабаты
    add_heading1("12. Деректер қорымен жұмыс істейтін Repository/Service қабатын құру")
    doc.add_paragraph(
        "Clean Architecture қағидатына сай, UI қабаты мен төменгі деңгейдегі деректер қорының арасында "
        "`RouteRepository` қабаты жасалды (`lib/services/route_repository.dart`):"
    )
    add_code_block("""abstract class IRouteRepository {
  Future<List<RouteModel>> getAllRoutes({...});
  Future<RouteModel?> getRouteById(String id);
  Future<void> addRoute(RouteModel route);
  Future<void> updateRoute(RouteModel route);
  Future<bool> toggleFavorite(String id);
  Future<void> deleteRoute(String id);
}

class RouteRepository implements IRouteRepository {
  final DatabaseService _dbService;
  RouteRepository({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService.instance;
  ...
}""")
    doc.add_paragraph(
        "Бұл интерфейс абстракциясы кодтың тазалығын, оқылуын және дербес Mock-тестілеу мүмкіндігін арттырады."
    )

    # 13. Search функциясы
    add_heading1("13. Деректерді іздеу (Search) функциясын қосу")
    doc.add_paragraph(
        "Жоғарғы іздеу жолағына (`TextField`) мәтін енгізілген бойда `_searchController` арқылы нақты уақытта іздеу орындалады. "
        "Іздеу SQL деңгейінде бағыт атауы, қауіп деңгейі және ескертпе өрістерін қамтиды:"
    )
    add_code_block("""whereClauses.add('(title LIKE ? OR risk_level LIKE ? OR notes LIKE ?)');
final searchArg = '%${query.trim()}%';
whereArgs.addAll([searchArg, searchArg, searchArg]);""")

    # 14. Сүзгілеу (Filtering)
    add_heading1("14. Деректерді таңдалған критерийлер бойынша сүзгілеу")
    doc.add_paragraph(
        "Қосымшада келесі сүзгілеу деңгейлері жұмыс істейді:"
    )
    filters = [
        "Қауіптілік деңгейі чиптері (FilterChips): «Барлығы», «Төмен», «Орташа», «Қатерлі».",
        "Қойындылар бойынша: «Барлық бағыттар» және «Таңдаулылар (Favorites)».",
        "Сапарлар бойынша (TripListScreen): «Барлық сапарлар», «Қауіпсіз (100%)», «Қауіп дабылдары бар»."
    ]
    for f in filters:
        p = doc.add_paragraph(style='List Bullet')
        p.add_run(f)

    # 15. Сұрыптау (Sorting)
    add_heading1("15. Деректерді кемінде екі параметр бойынша сұрыптау")
    doc.add_paragraph(
        "AppBar-дағы сұрыптау белгішесін басқанда модальді терезе арқылы пайдаланушы параметрлерді таңдай алады:"
    )
    sort_options = [
        "1) Қосылған уақыты бойынша (`created_at`): Жаңалары алдында (DESC) немесе Ескілері алдында (ASC).",
        "2) Қашықтығы бойынша (`distance_km`): Өсу ретімен (ASC) немесе Кему ретімен (DESC).",
        "3) Орташа уақыты бойынша (`avg_duration_minutes`): Жылдамнан ұзаққа қарай.",
        "4) Сапарлар тарихында: Сапардың басталу уақыты және Қауіпсіздік ұпайы (`safety_score`) бойынша."
    ]
    for s in sort_options:
        p = doc.add_paragraph(style='List Bullet')
        p.add_run(s)

    # 16. Favorites функциясы
    add_heading1("16. Таңдаулы объектілерді сақтауға арналған Favorites функциясы")
    doc.add_paragraph(
        "Әрбір бағыт карточкасында жұлдызша (`Icons.star`) батырмасы бар. Оны басқанда `toggleFavorite(route.id)` шақырылып, "
        "SQLite-тегі `is_favorite` өрісі 1 немесе 0 күйіне ауысады:"
    )
    add_code_block("""Future<bool> toggleFavoriteRoute(String id) async {
  final db = await database;
  final route = await getRouteById(id);
  if (route == null) return false;
  final newStatus = !route.isFavorite;
  await db.update('routes', {'is_favorite': newStatus ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  return newStatus;
}""")

    # 17. Empty State хабарламасы
    add_heading1("17. Деректер болмаған жағдайдағы Empty State хабарламасы")
    doc.add_paragraph(
        "Іздеу сұранысы бойынша ешқандай бағыт сәйкес келмесе немесе деректер қоры бос болған жағдайда, "
        "пайдаланушыға бос ақ экран емес, сапалы Empty State виджеті ұсынылады:"
    )
    empty_items = [
        "Көрнекі белгіше: Icons.search_off_rounded (Бағыттарда) немесе Icons.history_toggle_off_rounded (Сапарларда);",
        "Тақырып: «Бағыттар табылмады» немесе «Бұл санатта әзірге сапарлар жоқ»;",
        "Түсіндірме мәтін: ««Шымкент» бойынша сәйкес бағыт табылмады» немесе «Сізде әлі таңдаулыға сақталған бағыттар жоқ»;",
        "Интерактивті батырма: Іздеу кезінде «Іздеуді тазарту», бос база кезінде «Жаңа бағыт қосу» батырмасы шығады."
    ]
    for e in empty_items:
        p = doc.add_paragraph(style='List Bullet')
        p.add_run(e)

    # 18. Қателерді өңдеу (Error Handling)
    add_heading1("18. Деректер қорымен жұмыс кезінде пайда болатын қателерді өңдеу")
    doc.add_paragraph(
        "Барлық асинхронды деректер қоры операциялары `try-catch` құрылымымен қорғалған. "
        "Қате орын алған жағдайда қосымша апатты түрде жабылмайды, жүйе қатені ұстап алып, "
        "экранда қызыл түсті SnackBar хабарламасы арқылы пайдаланушыға қазақ тілінде түсінікті ескерту береді. "
        "Форма өрістерінде сандық және мәтіндік қатаң валидация қарастырылған."
    )

    # 19. Интернетсіз оффлайн жұмыс
    add_heading1("19. Қосымшаны интернетсіз іске қосып, барлық локалды операцияларды тексеру")
    doc.add_paragraph(
        "«AntiSleep AI» толықтай құрылғының жергілікті ресурстарымен жұмыс істейді: "
        "деректер сыртқы интернет серверіне жіберілмейді, тек ішкі `antisleep_ai.db` файлында өңделеді. "
        "Интернет желісі толықтай сөндірілгенде (Airplane mode) деректерді қосу, іздеу, өзгерту, өшіру және сүзгілеу "
        "операцияларының жылдамдығы мен жұмыс қабілеті 100% сақталады."
    )

    # 20. Қайта қосқанда деректердің сақталуын тексеру
    add_heading1("20. Қосымшаны қайта іске қосқаннан кейін енгізілген деректердің сақталғанын тексеру")
    doc.add_paragraph(
        "Деректердің тұрақтылығы екі түрлі жолмен тексерілді:"
    )
    p_t1 = doc.add_paragraph(style='List Bullet')
    p_t1.add_run("1) Автоматтандырылған Unit-тесттер: ").bold = True
    p_t1.add_run("`test/database_service_test.dart` тесттік жиынтығы арқылы деректер базасын ашу, жаңа бағыт қосу, оқу, өзгерту, өшіру, таңдаулыны ауыстыру, сапар мен дабылдарды байланыстырып жазу сценарийлері тексерілді.")

    p_t2 = doc.add_paragraph(style='List Bullet')
    p_t2.add_run("2) Статикалық анализ нәтижесі: ").bold = True
    p_t2.add_run("`flutter analyze` бұйрығы арқылы жобаның барлық файлдары тексеріліп, 0 қате және 0 ескерту тіркелді (`No issues found!`).")

    add_note_box(
        "Тестілеу нәтижесі",
        "Қосымшаны толық жауып, қайта іске қосқаннан кейін барлық пайдаланушы қосқан бағыттары, таңдаулылары және автокөлік пен SOS контактілері өзгеріссіз сақталды."
    )

    # Қорытынды
    add_heading1("ҚОРЫТЫНДЫ")
    doc.add_paragraph(
        "№4 Практикалық жұмыс барысында «AntiSleep AI» мобильді жобасына реляциялық SQLite жергілікті деректер қоры енгізілді. "
        "Нәтижесінде қосымша интернет байланысына тәуелсіз, нақты жол жағдайында жүргізушілер үшін толыққанды CRUD операцияларын, "
        "бағыттарды жылдам іздеу мен сүзгілеуді, параметрлік сұрыптауды және таңдаулы бағыттарды сақтауды жоғары сенімділікпен қамтамасыз етеді."
    )

    output_path = r"c:\Users\nurzh\OneDrive\фигма\ПО проект 2 авто\Practical_Work_4_kz.docx"
    doc.save(output_path)
    print(f"Document successfully created at {output_path}")

if __name__ == "__main__":
    create_document()

