import SwiftUI

struct HomeworkView: View {
    @EnvironmentObject var state: AppState
    @State private var date = Date()
    @State private var homework: [String: Any] = [:]

    private var odd: Bool { isOddWeek(date) }
    private var weekday: Int { Calendar.current.component(.weekday, from: date) }
    private var lessons: [String] {
        let entry = scheduleData[weekday]
        return odd ? (entry?.odd ?? []) : (entry?.even ?? [])
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(tr(odd ? "oddWeek" : "evenWeek", state.lang))
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(odd ? Color(red: 0.17, green: 0.30, blue: 0.31) : Color(red: 0.35, green: 0.21, blue: 0.31))
                        .cornerRadius(20)
                    Spacer()
                    if !Calendar.current.isDateInToday(date) {
                        Button(tr("today", state.lang)) { date = Date() }
                            .foregroundColor(.appPrimary)
                    }
                }

                HStack {
                    Button { date = nextSchoolDay(date, forward: false) } label: {
                        Image(systemName: "chevron.left").font(.title2)
                    }.frame(width: 44)
                    Spacer()
                    VStack {
                        Text(weekdayName(date, state.lang)).font(.title2.bold())
                        Text(formatDate(date, state.lang)).font(.subheadline).foregroundColor(.appMuted)
                    }
                    Spacer()
                    Button { date = nextSchoolDay(date, forward: true) } label: {
                        Image(systemName: "chevron.right").font(.title2)
                    }.frame(width: 44)
                }
                .foregroundColor(.appPrimary)

                if lessons.isEmpty {
                    VStack(spacing: 8) {
                        Text("🌿").font(.system(size: 40))
                        Text(tr("dayOff", state.lang)).foregroundColor(.appMuted)
                    }
                    .frame(maxWidth: .infinity).padding(.top, 60)
                } else {
                    ForEach(Array(lessons.enumerated()), id: \.offset) { index, subjectId in
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle().fill(Color.appPrimaryContainer).frame(width: 32, height: 32)
                                Text("\(index + 1)").font(.subheadline.bold()).foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(subjectName(subjectId, state.lang))
                                    .font(.headline)
                                    .foregroundColor(.white)
                                let task = (homework[subjectId] as? [String: Any])?["text"] as? String ?? ""
                                Text(task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                     ? tr("noHomework", state.lang)
                                     : task)
                                    .font(.body)
                                    .foregroundColor(task.isEmpty ? .appMuted : .white)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.appCard)
                        .cornerRadius(18)
                    }
                }
            }
            .padding()
        }
        .background(Color.appBg.ignoresSafeArea())
        .task(id: dateKey(date)) {
            homework = await state.loadHomework(dateKey(date))
        }
    }
}
