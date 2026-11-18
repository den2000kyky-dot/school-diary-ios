import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var editedName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        ZStack {
                            Circle().fill(Color.appPrimaryContainer).frame(width: 64, height: 64)
                            Text(String(state.name.prefix(1)).uppercased())
                                .font(.title).foregroundColor(.white).fontWeight(.bold)
                        }
                        Spacer()
                    }

                    VStack(alignment: .leading) {
                        Text(tr("name", state.lang)).font(.subheadline).foregroundColor(.appMuted)
                        TextField(tr("name", state.lang), text: $editedName)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color.appCard)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .textInputAutocapitalization(.words)
                        Button {
                            Task {
                                await state.saveName(editedName)
                                dismiss()
                            }
                        } label: {
                            Text(tr("save", state.lang)).fontWeight(.semibold)
                                .frame(maxWidth: .infinity).padding(14)
                                .background(Color.appPrimary)
                                .foregroundColor(Color(red: 0x17 / 255, green: 0x14 / 255, blue: 0x2A / 255))
                                .cornerRadius(16)
                        }
                    }

                    LanguagePicker()

                    Button(role: .destructive) {
                        state.logout()
                        dismiss()
                    } label: {
                        Text(tr("logout", state.lang))
                            .frame(maxWidth: .infinity).padding(14)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.red.opacity(0.6)))
                    }
                }
                .padding()
            }
            .background(Color.appBg.ignoresSafeArea())
            .navigationTitle(tr("profile", state.lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(tr("close", state.lang)) { dismiss() }.foregroundColor(.appPrimary)
                }
            }
            .onAppear { editedName = state.name }
        }
    }
}
