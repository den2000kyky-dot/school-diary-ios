import Foundation
import CommonCrypto
import SwiftUI

// MARK: - Models

struct DBUser: Identifiable {
    let id: String
    let name: String
    let avatar: String?
    let online: Bool
    let lastSeen: Int64
}

struct ChatMessage: Identifiable {
    let id: String
    let senderId: String
    let senderName: String
    let text: String?
    let image: String?
    let timestamp: Int64
}

// MARK: - Helpers

extension Array where Element == UInt8 {
    init(hex: String) {
        var result: [UInt8] = []
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2, limitedBy: hex.endIndex) ?? hex.endIndex
            result.append(UInt8(hex[index..<next], radix: 16) ?? 0)
            index = next
        }
        self = result
    }
    var hexString: String { map { String(format: "%02x", $0) }.joined() }
}

private func pbkdf2SHA1Hex(_ password: String, _ saltHex: String) -> String? {
    var key = [UInt8](repeating: 0, count: 32)
    let salt = [UInt8](hex: saltHex)
    guard !salt.isEmpty else { return nil }
    let status = salt.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> Int32 in
        CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            password,
            password.utf8.count,
            ptr.baseAddress?.assumingMemoryBound(to: UInt8.self),
            salt.count,
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1),
            120_000,
            &key,
            key.count,
        )
    }
    guard status == kCCSuccess else { return nil }
    return key.hexString
}

func dateKey(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}

func isOddWeek(_ date: Date) -> Bool {
    var utc = Calendar(identifier: .gregorian)
    utc.timeZone = TimeZone(secondsFromGMT: 0)!
    let anchor = utc.date(from: DateComponents(year: 2026, month: 11, day: 16, hour: 12))!
    let target = utc.date(from: DateComponents(
        year: utc.component(.year, from: date),
        month: utc.component(.month, from: date),
        day: utc.component(.day, from: date),
        hour: 12,
    ))!
    let days = Int(target.timeIntervalSince(anchor) / 86_400)
    return ((days / 7) % 2 + 2) % 2 == 0
}

func nextSchoolDay(_ date: Date, forward: Bool) -> Date {
    var result = Calendar.current.date(byAdding: .day, value: forward ? 1 : -1, to: date)!
    let weekday = Calendar.current.component(.weekday, from: result)
    while weekday == 1 || weekday == 7 {
        result = Calendar.current.date(byAdding: .day, value: forward ? 1 : -1, to: result)!
    }
    return result
}

// MARK: - REST API (same Firebase Realtime Database as Android)

enum API {
    static let base = "https://my-chat-d0393-default-rtdb.europe-west1.firebasedatabase.app"

    static func request(_ path: String, method: String = "GET", body: [String: Any]? = nil) async throws -> Data {
        guard let url = URL(string: "\(base)/\(path).json") else {
            throw NSError(domain: "API", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bad URL"])
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.cachePolicy = .reloadIgnoringLocalCacheData
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "API", code: -2, userInfo: [NSLocalizedDescriptionKey: "HTTP error"])
        }
        return data
    }

    static func object(_ path: String) async throws -> [String: Any]? {
        let data = try await request(path)
        let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if text.isEmpty || text == "null" { return nil }
        return try JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    static func users() async throws -> [DBUser] {
        let raw = try await object("users") ?? [:]
        return raw.compactMap { key, value in
            guard let user = value as? [String: Any],
                  let name = user["name"] as? String, !name.isEmpty,
                  user["blocked"] as? Bool != true else { return nil }
            return DBUser(
                id: key,
                name: name,
                avatar: user["avatar"] as? String,
                online: user["online"] as? Bool == true,
                lastSeen: (user["lastSeen"] as? NSNumber)?.int64Value ?? 0,
            )
        }
    }

    static func messages(_ chatId: String) async throws -> [ChatMessage] {
        let raw = try await object("chats/\(chatId)/messages") ?? [:]
        return raw.compactMap { key, value in
            guard let item = value as? [String: Any] else { return nil }
            return ChatMessage(
                id: key,
                senderId: item["senderId"] as? String ?? "",
                senderName: item["senderName"] as? String ?? "",
                text: item["text"] as? String,
                image: item["image"] as? String,
                timestamp: (item["timestamp"] as? NSNumber)?.int64Value ?? 0,
            )
        }.sorted { $0.timestamp < $1.timestamp }
    }

    static func findAccount(_ name: String) async throws -> (key: String, uid: String, accountName: String, salt: String, hash: String)? {
        let all = try await object("deviceAccounts") ?? [:]
        let wanted = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        for (key, value) in all {
            guard let account = value as? [String: Any],
                  let accountName = account["name"] as? String,
                  accountName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == wanted,
                  let uid = account["uid"] as? String else { continue }
            return (key, uid, accountName,
                    account["salt"] as? String ?? "",
                    account["passwordHash"] as? String ?? "")
        }
        return nil
    }

    static func sendMessage(chatId: String, uid: String, name: String, text: String?, image: String?) async throws {
        var body: [String: Any] = [
            "senderId": uid,
            "senderName": name,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
        ]
        if let text = text, !text.isEmpty { body["text"] = text }
        if let image = image { body["image"] = image }
        _ = try await request("chats/\(chatId)/messages", method: "POST", body: body)
    }
}

// MARK: - App state

@MainActor
final class AppState: ObservableObject {
    @Published var lang: Lang {
        didSet { UserDefaults.standard.set(lang.rawValue, forKey: "lang") }
    }
    @Published var uid: String?
    @Published var name: String = ""
    @Published var users: [DBUser] = []
    @Published var busy = false
    @Published var errorMessage: String?
    @Published var blocked = false

    private var deviceKey: String?

    init() {
        let savedLang = UserDefaults.standard.string(forKey: "lang") ?? "uk"
        lang = Lang(rawValue: savedLang) ?? .uk
        uid = UserDefaults.standard.string(forKey: "uid")
        name = UserDefaults.standard.string(forKey: "name") ?? ""
        deviceKey = UserDefaults.standard.string(forKey: "deviceKey")
    }

    var isSignedIn: Bool { uid != nil && !name.isEmpty }

    func restore() async {
        guard isSignedIn else { return }
        await refreshUsers()
        setPresence(online: true)
    }

    func login(name: String, password: String, create: Bool) async {
        errorMessage = nil
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { errorMessage = tr("needName", lang); return }
        guard password.count >= 8 else { errorMessage = tr("shortPass", lang); return }
        busy = true
        do {
            if create {
                if try await API.findAccount(cleanName) != nil {
                    errorMessage = tr("wrongPass", lang)
                    busy = false
                    return
                }
                var saltBytes = [UInt8](repeating: 0, count: 16)
                let status = saltBytes.withUnsafeMutableBytes { CCRandomGenerateBytes($0.baseAddress, 16) }
                guard status == kCCSuccess, let hash = pbkdf2SHA1Hex(password, saltBytes.hexString) else {
                    errorMessage = tr("syncError", lang)
                    busy = false
                    return
                }
                let newUid = UUID().uuidString
                let key = "web-\(UUID().uuidString)"
                try await API.request("deviceAccounts/\(key)", method: "PUT", body: [
                    "uid": newUid, "name": cleanName,
                    "salt": saltBytes.hexString, "passwordHash": hash,
                ])
                try await API.request("users/\(newUid)", method: "PATCH", body: [
                    "name": cleanName, "online": true, "updatedAt": Int(Date().timeIntervalSince1970 * 1000),
                ])
                uid = newUid
                self.name = cleanName
                deviceKey = key
            } else {
                guard let account = try await API.findAccount(cleanName),
                      let hash = pbkdf2SHA1Hex(password, account.salt),
                      hash == account.hash else {
                    errorMessage = tr("wrongPass", lang)
                    busy = false
                    return
                }
                uid = account.uid
                self.name = account.accountName
                deviceKey = account.key
            }
            UserDefaults.standard.set(uid, forKey: "uid")
            UserDefaults.standard.set(name, forKey: "name")
            UserDefaults.standard.set(deviceKey, forKey: "deviceKey")
            await refreshUsers()
            setPresence(online: true)
        } catch {
            errorMessage = tr("syncError", lang)
        }
        busy = false
    }

    func refreshUsers() async {
        do {
            let all = try await API.users()
            users = all
            if let uid = uid, let raw = try? await API.object("users/\(uid)") {
                blocked = raw["blocked"] as? Bool == true
            } else {
                blocked = false
            }
        } catch {}
    }

    func loadHomework(_ key: String) async -> [String: Any] {
        (try? await API.object("homework/\(key)")) ?? [:]
    }

    func saveName(_ newName: String) async {
        let clean = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, let uid = uid else { return }
        name = clean
        UserDefaults.standard.set(clean, forKey: "name")
        try? await API.request("users/\(uid)", method: "PATCH", body: [
            "name": clean, "updatedAt": Int(Date().timeIntervalSince1970 * 1000),
        ])
        if let deviceKey = deviceKey {
            try? await API.request("deviceAccounts/\(deviceKey)", method: "PATCH", body: ["name": clean])
        }
        await refreshUsers()
    }

    func setPresence(online: Bool) {
        guard let uid = uid else { return }
        let payload: [String: Any] = online
            ? ["online": true, "lastSeen": Int(Date().timeIntervalSince1970 * 1000)]
            : ["online": false, "lastSeen": Int(Date().timeIntervalSince1970 * 1000)]
        Task.detached { try? await API.request("users/\(uid)", method: "PATCH", body: payload) }
    }

    func logout() {
        setPresence(online: false)
        uid = nil
        name = ""
        deviceKey = nil
        users = []
        for key in ["uid", "name", "deviceKey"] { UserDefaults.standard.removeObject(forKey: key) }
    }
}
