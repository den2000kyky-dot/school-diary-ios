import Foundation

enum Lang: String, CaseIterable, Identifiable {
    case uk, ru, en
    var id: String { rawValue }
    var index: Int { self == .uk ? 0 : (self == .ru ? 1 : 2) }
    var title: String { self == .uk ? "Українська" : (self == .ru ? "Русский" : "English") }
    var code: String { rawValue.uppercased() }
}

private let dictionary: [String: [String]] = [
    "homework": ["ДЗ", "ДЗ", "Homework"],
    "lessons": ["Уроки", "Уроки", "Lessons"],
    "chat": ["Чат", "Чат", "Chat"],
    "loginTitle": ["Вхід в акаунт", "Вход в аккаунт", "Sign in"],
    "loginSub": ["Введіть ім'я та пароль від акаунта на Android або створіть новий.",
                 "Введите имя и пароль от аккаунта на Android или создайте новый.",
                 "Enter the name and password of your Android account or create a new one."],
    "name": ["Ім'я", "Имя", "Name"],
    "password": ["Пароль, мінімум 8 символів", "Пароль, минимум 8 символов", "Password, at least 8 characters"],
    "signIn": ["Увійти", "Войти", "Sign in"],
    "create": ["Створити акаунт", "Создать аккаунт", "Create account"],
    "language": ["Мова", "Язык", "Language"],
    "today": ["Сьогодні", "Сегодня", "Today"],
    "oddWeek": ["Непарний тиждень", "Нечётная неделя", "Odd week"],
    "evenWeek": ["Парний тиждень", "Чётная неделя", "Even week"],
    "odd": ["Непарний", "Нечётный", "Odd"],
    "even": ["Парний", "Чётный", "Even"],
    "noHomework": ["Д/з не задано", "Д/з не задано", "No homework yet"],
    "dayOff": ["Вихідний", "Выходной", "Day off"],
    "todayIs": ["Сьогодні", "Сегодня", "Today is"],
    "general": ["Загальний чат", "Общий чат", "General chat"],
    "allStudents": ["Усі учні", "Все ученики", "All students"],
    "students": ["Учні", "Ученики", "Students"],
    "online": ["У мережі", "В сети", "Online"],
    "lastSeen": ["Був(ла) у мережі", "Был(а) в сети", "Last seen"],
    "message": ["Повідомлення", "Сообщение", "Message"],
    "profile": ["Профіль", "Профиль", "Profile"],
    "save": ["Зберегти", "Сохранить", "Save"],
    "saved": ["Збережено", "Сохранено", "Saved"],
    "logout": ["Вийти з акаунта", "Выйти из аккаунта", "Sign out"],
    "close": ["Закрити", "Закрыть", "Close"],
    "wrongPass": ["Невірний пароль або акаунт не знайдено", "Неверный пароль или аккаунт не найден", "Wrong password or account not found"],
    "needName": ["Введіть ім'я", "Введите имя", "Enter a name"],
    "shortPass": ["Пароль має містити мінімум 8 символів", "Пароль должен быть не короче 8 символов", "Password must be at least 8 characters"],
    "checking": ["Перевірка пароля…", "Проверка пароля…", "Checking password…"],
    "sendError": ["Не вдалося надіслати", "Не удалось отправить", "Could not send"],
    "noUsers": ["Поки нікого немає", "Пока никого нет", "Nobody here yet"],
    "syncError": ["Немає зв'язку з базою", "Нет связи с базой", "No connection to the database"],
]

func tr(_ key: String, _ lang: Lang) -> String {
    guard let values = dictionary[key] else { return key }
    return values[lang.index]
}

private let subjectNames: [String: [String]] = [
    "english": ["Англійська мова", "Английский язык", "English"],
    "informatics": ["Інформатика", "Информатика", "Informatics"],
    "math": ["Математика", "Математика", "Math"],
    "pe": ["Фізкультура", "Физкультура", "PE"],
    "ukrainian": ["Українська мова", "Украинский язык", "Ukrainian"],
    "nature": ["Пізнаємо природу", "Познаём природу", "Exploring Nature"],
    "art": ["Мистецтво", "Искусство", "Art"],
    "history": ["Історія", "История", "History"],
    "ukrlit": ["Українська література", "Украинская литература", "Ukrainian Literature"],
    "geography": ["Географія", "География", "Geography"],
    "tech": ["Технології", "Технологии", "Technology"],
    "worldlit": ["Зарубіжна література", "Зарубежная литература", "World Literature"],
    "zbd": ["ЗБД", "ЗБД", "Health & Safety"],
]

func subjectName(_ id: String, _ lang: Lang) -> String {
    guard let values = subjectNames[id] else { return id }
    return values[lang.index]
}

private let weekdayNames: [[String]] = [
    ["Неділя", "Понеділок", "Вівторок", "Середа", "Четвер", "П'ятниця", "Субота"],
    ["Воскресенье", "Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота"],
    ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
]

private let monthNames: [[String]] = [
    ["січня", "лютого", "березня", "квітня", "травня", "червня", "липня", "серпня", "вересня", "жовтня", "листопада", "грудня"],
    ["января", "февраля", "марта", "апреля", "мая", "июня", "июля", "августа", "сентября", "октября", "ноября", "декабря"],
    ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
]

func weekdayName(_ date: Date, _ lang: Lang) -> String {
    let wd = Calendar.current.component(.weekday, from: date) - 1
    return weekdayNames[lang.index][wd]
}

func formatDate(_ date: Date, _ lang: Lang) -> String {
    let cal = Calendar.current
    let day = cal.component(.day, from: date)
    let month = monthNames[lang.index][cal.component(.month, from: date) - 1]
    return lang == .en ? "\(month) \(day)" : "\(day) \(month)"
}

let scheduleData: [Int: (odd: [String], even: [String])] = [
    1: (["english", "informatics", "math", "pe"], ["ukrainian", "nature", "art"]),
    2: (["math", "ukrainian", "history"], ["math", "ukrainian", "english"]),
    3: (["ukrlit", "english", "pe"], ["ukrlit", "math", "history", "pe"]),
    4: (["ukrainian", "geography", "tech"], ["geography", "ukrainian", "informatics"]),
    5: (["worldlit", "math", "nature", "art"], ["english", "math", "zbd", "tech"]),
]
