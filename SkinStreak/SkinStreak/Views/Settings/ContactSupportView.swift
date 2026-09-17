import SwiftUI

struct ContactSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSubject: SupportSubject = .general
    @State private var customSubject = ""
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var isSending = false
    @State private var sendError: String?
    @State private var didSend = false

    private var effectiveSubject: String {
        selectedSubject == .other ? customSubject.trimmingCharacters(in: .whitespacesAndNewlines) : selectedSubject.title
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && isValidEmail
            && !effectiveSubject.isEmpty
            && !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && message.count <= 1000
    }

    private var isValidEmail: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        return trimmed.contains("@") && trimmed.contains(".") && !trimmed.hasPrefix("@") && !trimmed.hasSuffix(".")
    }

    var body: some View {
        Form {
            Section {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(SupportSubject.allCases) { subject in
                        subjectTile(subject)
                    }
                }
                .padding(.vertical, 4)
                if selectedSubject == .other {
                    TextField("Tell us the subject", text: $customSubject)
                }
            } header: {
                Text("What's this about?")
            }

            Section("Your details") {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            Section {
                ZStack(alignment: .topLeading) {
                    if message.isEmpty {
                        Text("How can we help?")
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $message)
                        .frame(minHeight: 120)
                }
                HStack {
                    Spacer()
                    Text("\(message.count)/1000")
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(message.count > 1000 ? Theme.coral : .secondary)
                }
            } header: {
                Text("Message")
            }

            Section {
                Button {
                    submit()
                } label: {
                    HStack {
                        if isSending {
                            ProgressView()
                        }
                        Text("Submit")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit || isSending)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            Section {
                Text("We only use your email to respond to this feedback.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .alert("Couldn't send", isPresented: Binding(get: { sendError != nil }, set: { if !$0 { sendError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(sendError ?? "")
        }
        .overlay {
            if didSend {
                successOverlay
            }
        }
    }

    private func subjectTile(_ subject: SupportSubject) -> some View {
        let isSelected = selectedSubject == subject
        return Button {
            selectedSubject = subject
        } label: {
            VStack(spacing: 6) {
                Image(systemName: subject.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? Color.white : Theme.sageDeep)
                Text(subject.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? Color.white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Theme.sage : Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Theme.sage : Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .gridCellColumns(subject.spansFullWidth ? 2 : 1)
    }

    private var successOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 46))
                .foregroundStyle(Theme.sage)
            Text("Message sent")
                .font(.headline)
            Text("Thanks for reaching out — we'll get back to you soon.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(radius: 20)
        .padding(40)
    }

    private func submit() {
        isSending = true
        sendError = nil
        let request = FeedbackRequest(
            name: name.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces),
            subject: effectiveSubject,
            message: message,
            app_name: "SkinStreak"
        )
        Task {
            do {
                try await FeedbackService.send(request)
                didSend = true
                Haptics.success()
            } catch {
                sendError = error.localizedDescription
            }
            isSending = false
        }
    }
}

enum SupportSubject: CaseIterable, Identifiable {
    case general, feature, bug, usage, performance, ui, other

    var id: String { title }

    var title: String {
        switch self {
        case .general: "General"
        case .feature: "Feature Suggestion"
        case .bug: "Bug Report"
        case .usage: "Usage Question"
        case .performance: "Performance"
        case .ui: "UI Improvement"
        case .other: "Other"
        }
    }

    var icon: String {
        switch self {
        case .general: "bubble.left.fill"
        case .feature: "lightbulb.fill"
        case .bug: "ant.fill"
        case .usage: "questionmark.circle.fill"
        case .performance: "gauge.with.dots.needle.67percent"
        case .ui: "paintpalette.fill"
        case .other: "ellipsis.circle.fill"
        }
    }

    var spansFullWidth: Bool { self == .other }
}
