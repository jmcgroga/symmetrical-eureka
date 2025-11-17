import SwiftUI
import VoiceJournalCore

public struct SettingsView: View {
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
        NavigationStack {
            Form {
                Section {
                    Toggle("Enable iCloud Sync", isOn: $settings.iCloudSyncEnabled)
                } header: {
                    Text("iCloud")
                } footer: {
                    Text("Sync your journal entries across all your devices using iCloud")
                }

                Section {
                    Toggle("Enable Notifications", isOn: $settings.notificationsEnabled)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Receive daily reminders to journal and weekly summary notifications")
                }

                if settings.notificationsEnabled {
                    Section {
                        DatePicker(
                            "Daily Reminder",
                            selection: $dailyNotificationDate,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: dailyNotificationDate) { _, newValue in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                            settings.dailyNotificationTime = components
                        }
                    } header: {
                        Text("Daily Journal Reminder")
                    } footer: {
                        Text("You'll receive a daily reminder to write in your journal")
                    }

                    Section {
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
                    } header: {
                        Text("Weekly Summary")
                    } footer: {
                        Text("Receive a weekly summary of your journal entries")
                    }
                }

                Section {
                    Button("Request Notification Permission") {
                        Task {
                            await requestNotificationPermission()
                        }
                    }
                } footer: {
                    Text("If notifications aren't working, you may need to enable them in Settings")
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveSettings()
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                setupDatePickers()
            }
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
                try await NotificationService.shared.updateNotifications(settings: settings)
                dismiss()
            } catch {
                errorMessage = "Failed to update notifications: \(error.localizedDescription)"
                showingError = true
            }
        }
    }

    private func requestNotificationPermission() async {
        do {
            let granted = try await NotificationService.shared.requestAuthorization()
            if !granted {
                errorMessage = "Notification permission was denied. Please enable it in Settings."
                showingError = true
            }
        } catch {
            errorMessage = "Failed to request permission: \(error.localizedDescription)"
            showingError = true
        }
    }
}
