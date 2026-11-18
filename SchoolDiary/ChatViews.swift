import SwiftUI
import PhotosUI

struct ChatListView: View {
    @EnvironmentObject var state: AppState
    let onOpen: (ChatTarget) -> Void

    private var others: [DBUser] { state.users.filter { $0.id != state.uid } }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Button {
                    onOpen(ChatTarget(chatId: "general", title: tr("general", state.lang), isGroup: true))
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.appPrimaryContainer).frame(width: 48, height: 48)
                            Image(systemName: "bubble.left.and.bubble.right.fill").foregroundColor(.white)
                        }
                        VStack(alignment: .leading) {
                            Text(tr("general", state.lang)).font(.headline).foregroundColor(.white)
                            Text(tr("allStudents", state.lang)).font(.caption).foregroundColor(.appMuted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.appMuted)
                    }
                    .padding(16)
                    .background(Color.appCard)
                    .cornerRadius(18)
                }

                Text("\(tr("students", state.lang)) · \(others.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.appMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 6)

                if others.isEmpty {
                    Text(tr("noUsers", state.lang))
                        .foregroundColor(.appMuted)
                        .padding(.top, 30)
                } else {
                    ForEach(others) { user in
                        Button {
                            onOpen(ChatTarget(
                                chatId: dmChatId(state.uid ?? "", user.id),
                                title: user.name,
                                isGroup: false,
                            ))
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle().fill(Color.appPrimaryContainer).frame(width: 46, height: 46)
                                    Text(String(user.name.prefix(1)).uppercased())
                                        .foregroundColor(.white).fontWeight(.bold)
                                }
                                VStack(alignment: .leading) {
                                    Text(user.name).font(.headline).foregroundColor(.white)
                                    Text(user.online
                                         ? tr("online", state.lang)
                                         : tr("lastSeen", state.lang))
                                        .font(.caption)
                                        .foregroundColor(user.online ? .appPrimary : .appMuted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(.appMuted)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.appBg.ignoresSafeArea())
    }
}

private func dmChatId(_ a: String, _ b: String) -> String {
    "dm_" + [a, b].sorted().joined(separator: "_")
}

private func timeString(_ timestamp: Int64) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
}

struct ConversationView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    let target: ChatTarget

    @State private var messages: [ChatMessage] = []
    @State private var text = ""
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(messages) { message in
                            messageBubble(message)
                        }
                    }
                    .padding(12)
                }
                .defaultScrollAnchor(.bottom)

                HStack(spacing: 8) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Image(systemName: "paperclip").font(.title3).foregroundColor(.appPrimary)
                    }
                    TextField(tr("message", state.lang), text: $text)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color.appCard)
                        .cornerRadius(18)
                        .foregroundColor(.white)
                        .onSubmit { send() }
                    Button { send() } label: {
                        Image(systemName: "paperplane.fill").foregroundColor(.appPrimary)
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(10)
                .background(Color.appSurface)
            }
            .background(Color.appBg.ignoresSafeArea())
            .navigationTitle(target.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").foregroundColor(.appPrimary)
                    }
                }
            }
            .task {
                while !Task.isCancelled {
                    await load()
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                }
            }
            .onChange(of: photoItem) { _, newItem in
                guard let newItem = newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data),
                       let jpeg = image.jpegData(compressionQuality: 0.75),
                       let uid = state.uid {
                        try? await API.sendMessage(
                            chatId: target.chatId, uid: uid, name: state.name,
                            text: nil, image: jpeg.base64EncodedString(),
                        )
                        await load()
                    }
                    photoItem = nil
                }
            }
        }
    }

    private func load() async {
        messages = (try? await API.messages(target.chatId)) ?? []
    }

    private func send() {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, let uid = state.uid else { return }
        text = ""
        Task {
            do {
                try await API.sendMessage(
                    chatId: target.chatId, uid: uid, name: state.name,
                    text: value, image: nil,
                )
                await load()
            } catch {
                state.errorMessage = tr("sendError", state.lang)
            }
        }
    }

    @ViewBuilder
    private func messageBubble(_ message: ChatMessage) -> some View {
        let mine = message.senderId == state.uid
        VStack(alignment: mine ? .trailing : .leading, spacing: 2) {
            if target.isGroup && !mine {
                Text(message.senderName)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.appPrimary)
            }
            if let base64 = message.image,
               let data = Data(base64Encoded: base64),
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220)
                    .cornerRadius(12)
            }
            if let body = message.text, !body.isEmpty {
                Text(body)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(mine ? Color.appPrimaryContainer : Color.appCard)
                    .cornerRadius(16)
            }
            Text(timeString(message.timestamp))
                .font(.caption2)
                .foregroundColor(.appMuted)
        }
        .frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
    }
}
