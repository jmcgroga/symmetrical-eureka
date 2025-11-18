import SwiftUI
import VoiceJournalCore

public struct macOSSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var settings = AppSettings.load()
    @State private var dailyNotificationDate = Date()
    @State private var weeklyNotificationDate = Date()
    @State private var showingError = false
    @State private var errorMessage = ""

    private let weekdays = [
        (1, "Sunday"),
        (2, "Monday"),
        (3, "Tuesday"),
        (4, "Wednesday"),
        (5, "Thursday"),
        (6, "Friday"),
        (7, "Saturday")
    ]

    public init() {}

    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button("Save") {
                    saveSettings()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            // Content
            Form {
                Section("iCloud") {
                    Toggle("Enable iCloud Sync", isOn: $settings.iCloudSyncEnabled)
                    Text("Sync your journal entries across all your devices using iCloud")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("AI Title Generation") {
                    Picker("Apple Intelligence Mode", selection: $settings.aiSummarizationMode) {
                        ForEach(AppSettings.AISummarizationMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    Text(settings.aiSummarizationMode.description + ". Entry titles are automatically generated using Apple Intelligence.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $settings.notificationsEnabled)
                    Text("Receive daily reminders to journal and weekly summary notifications")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if settings.notificationsEnabled {
                    Section("Daily Journal Reminder") {
                        DatePicker(
                            "Time",
                            selection: $dailyNotificationDate,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: dailyNotificationDate) { _, newValue in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                            settings.dailyNotificationTime = components
                        }

                        Text("You'll receive a daily reminder to write in your journal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Section("Weekly Summary") {
                        Picker("Day of Week", selection: $settings.weeklyNotificationDay) {
                            ForEach(weekdays, id: \.0) { weekday in
                                Text(weekday.1).tag(weekday.0)
                            }
                        }

                        DatePicker(
                            "Time",
                            selection: $weeklyNotificationDate,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: weeklyNotificationDate) { _, newValue in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                            settings.weeklyNotificationTime = components
                        }

                        Text("Receive a weekly summary of your journal entries")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Section {
                        Button("Request Notification Permission") {
                            Task {
                                await requestNotificationPermission()
                            }
                        }

                        Text("If notifications aren't working, you may need to enable them in System Settings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .padding()
        }
        .frame(width: 500, height: 600)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            setupDatePickers()
        }
    }

    private func setupDatePickers() {
        var dailyComponents = settings.dailyNotificationTime
        dailyComponents.year = Calendar.current.component(.year, from: Date())
        dailyComponents.month = Calendar.current.component(.month, from: Date())
        dailyComponents.day = Calendar.current.component(.day, from: Date())
        if let date = Calendar.current.date(from: dailyComponents) {
            dailyNotificationDate = date
        }

        var weeklyComponents = settings.weeklyNotificationTime
        weeklyComponents.year = Calendar.current.component(.year, from: Date())
        weeklyComponents.month = Calendar.current.component(.month, from: Date())
        weeklyComponents.day = Calendar.current.component(.day, from: Date())
        if let date = Calendar.current.date(from: weeklyComponents) {
            weeklyNotificationDate = date
        }
    }

    private func saveSettings() {
        settings.save()

        Task {
            do {
                try await macOSNotificationService.shared.updateNotifications(settings: settings)
                dismiss()
            } catch {
                errorMessage = "Failed to update notifications: \(error.localizedDescription)"
                showingError = true
            }
        }
    }

    private func requestNotificationPermission() async {
        do {
            let granted = try await macOSNotificationService.shared.requestAuthorization()
            if !granted {
                errorMessage = "Notification permission was denied. Please enable it in System Settings."
                showingError = true
            }
        } catch {
            errorMessage = "Failed to request permission: \(error.localizedDescription)"
            showingError = true
        }
    }
}
