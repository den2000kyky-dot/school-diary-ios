import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var state: AppState
    @State private var odd = isOddWeek(Date())

    private var todayWeekday: Int { Calendar.current.component(.weekday, from: Date()) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("\(tr("todayIs", state.lang)) \(tr(odd ? "odd" : "even", state.lang).lowercased()) \(weekdayName(Date(), state.lang).lowercased())")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.appPrimaryContainer)
                .cornerRadius(0)

                HStack {
                    Button { odd = true } label: {
                        Text(tr("odd", state.lang))
                            .padding(.horizontal, 16).padding(.vertical, 9)
                            .background(odd ? Color(red: 0.17, green: 0.30, blue: 0.31) : Color.appCard)
                            .foregroundColor(odd ? Color(red: 0.92, green: 0.98, blue: 0.97) : .appMuted)
                            .cornerRadius(22)
                    }
                    Button { odd = false } label: {
                        Text(tr("even", state.lang))
                            .padding(.horizontal, 16).padding(.vertical, 9)
                            .background(!odd ? Color(red: 0.17, green: 0.30, blue: 0.31) : Color.appCard)
                            .foregroundColor(!odd ? Color(red: 0.92, green: 0.98, blue: 0.97) : .appMuted)
                            .cornerRadius(22)
                    }
                }

                ForEach(1...5, id: \.self) { weekday in
                    let lessons = scheduleData[weekday]?[odd ? "odd" : "even"] ?? []
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(weekdayNamesFor(state.lang)[weekday])
                                .font(.headline).foregroundColor(.white)
                            if weekday == todayWeekday {
                                Text(tr("today", state.lang))
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 9).padding(.vertical, 3)
                                    .background(Color.appPrimary)
                                    .foregroundColor(Color(red: 0x17 / 255, green: 0x14 / 255, blue: 0x2A / 255))
                                    .cornerRadius(20)
                            }
                        }
                        ForEach(Array(lessons.enumerated()), id: \.offset) { index, subjectId in
                            HStack(alignment: .top) {
                                Text("\(index + 1).").foregroundColor(.appPrimary)
                                Text(subjectName(subjectId, state.lang)).foregroundColor(.white)
                                Spacer()
                            }
                        }
                    }
                    .padding(14)
                    .background(weekday == todayWeekday ? Color.appPrimaryContainer : Color.appCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(weekday == todayWeekday ? Color.appPrimary : Color.clear, lineWidth: 1.5)
                    )
                    .cornerRadius(18)
                }
            }
            .padding()
        }
        .background(Color.appBg.ignoresSafeArea())
    }
}

private func weekdayNamesFor(_ lang: Lang) -> [String] {
    let monday: [String]
    switch lang {
    case .uk: monday = ["Понеділок", "Вівторок", "Середа", "Четвер", "П'ятниця"]
    case .ru: monday = ["Понедельник", "Вторник", "Среда", "Четверг", "Пятница"]
    case .en: monday = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    }
    return [""] + monday
}
