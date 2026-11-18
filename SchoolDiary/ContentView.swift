import SwiftUI

struct ChatTarget: Identifiable {
    let id = UUID()
    let chatId: String
    let title: String
    let isGroup: Bool
}

struct ContentView: View {
    @StateObject private var state = AppState()

    var body: some View {
        Group {
            if state.isSignedIn {
                MainView()
            } else {
                LoginView()
            }
        }
        .environmentObject(state)
        .preferredColorScheme(.dark)
        .task { await state.restore() }
    }
}

struct LanguagePicker: View {
    @EnvironmentObject var state: AppState
    var body: some View {
        Picker(tr("language", state.lang), selection: $state.lang) {
            ForEach(Lang.allCases) { Text($0.title).tag($0) }
        }
        .pickerStyle(.segmented)
    }
}

// MARK: - Login

struct LoginView: View {
    @EnvironmentObject var state: AppState
    @State private var name = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Spacer()
                Image(systemName: "book.fill")
                    .font(.system(size: 54))
                    .foregroundColor(.appPrimary)
                    .padding(.bottom, 8)

                Text(tr("loginTitle", state.lang))
                    .font(.title.bold())
                    .foregroundColor(.white)

                Text(tr("loginSub", state.lang))
                    .font(.subheadline)
                    .foregroundColor(.appMuted)
                    .multilineTextAlignment(.center)

                TextField(tr("name", state.lang), text: $name)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                SecureField(tr("password", state.lang), text: $password)
                    .textFieldStyle(.roundedBorder)

                if let error = state.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await state.login(name: name, password: password, create: false) }
                } label: {
                    if state.busy { ProgressView().tint(.appPrimary) }
                    else { Text(tr("signIn", state.lang)).fontWeight(.semibold) }
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color.appPrimary)
                .foregroundColor(Color(red: 0x17 / 255, green: 0x14 / 255, blue: 0x2A / 255))
                .cornerRadius(16)
                .disabled(state.busy)

                Button {
                    Task { await state.login(name: name, password: password, create: true) }
                } label: {
                    Text(tr("create", state.lang)).fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appPrimary, lineWidth: 1))
                .foregroundColor(.appPrimary)
                .disabled(state.busy)

                LanguagePicker().padding(.top, 12)
                Spacer()
            }
            .padding(24)
            .background(Color.appBg.ignoresSafeArea())
        }
    }
}

// MARK: - Main tabs

struct MainView: View {
    @EnvironmentObject var state: AppState
    @State private var selection = 0
    @State private var showProfile = false
    @State private var chatTarget: ChatTarget?
    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                HomeworkView()
                    .tabItem { Label(tr("homework", state.lang), systemImage: "book.fill") }
                    .tag(0)
                ScheduleView()
                    .tabItem { Label(tr("lessons", state.lang), systemImage: "calendar") }
                    .tag(1)
                ChatListView { target in chatTarget = target }
                    .tabItem { Label(tr("chat", state.lang), systemImage: "bubble.left.and.bubble.right.fill") }
                    .tag(2)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showProfile = true } label: {
                        ZStack {
                            Circle().fill(Color.appPrimaryContainer).frame(width: 34, height: 34)
                            Text(String(state.name.prefix(1)).uppercased())
                                .foregroundColor(.white).fontWeight(.bold)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showProfile) { ProfileView() }
        .fullScreenCover(item: $chatTarget) { target in
            ConversationView(target: target)
        }
        .onReceive(timer) { _ in
            Task { await state.refreshUsers() }
        }
        .onAppear { state.setPresence(online: true) }
    }
}
