import SwiftUI
import Combine

@MainActor
class NotificationStore: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false
    
    private let baseURL = APIConfig.baseURL
    private var pollingTask: Task<Void, Never>?
    private var currentUserEmail: String = "guest"
    
    init() {
        Task {
            await fetchNotifications()
        }
    }
    
    // MARK: - Live Polling (every 30 seconds)
    func startPolling(userEmail: String) {
        currentUserEmail = userEmail
        pollingTask?.cancel()
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                if !Task.isCancelled {
                    await fetchNotifications(userEmail: currentUserEmail)
                }
            }
        }
    }
    
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
    
    // MARK: - Fetch
    func fetchNotifications(userEmail: String = "guest") async {
        currentUserEmail = userEmail
        guard let encodedEmail = userEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: baseURL + "get_notifications.php?userEmail=\(encodedEmail)") else { return }
        isLoading = true
        
        do {
            var request = URLRequest(url: url)
            request.addValue("close", forHTTPHeaderField: "Connection")
            request.timeoutInterval = 30
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            decoder.dateDecodingStrategy = .custom({ decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                if let date = formatter.date(from: dateString) {
                    return date
                }
                let isoFormatter = ISO8601DateFormatter()
                if let date = isoFormatter.date(from: dateString) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
            })
            
            let response = try decoder.decode(APIResponse<[AppNotification]>.self, from: data)
            if response.status == "success" {
                self.notifications = response.data
            }
        } catch {
            print("Fetch notifications failed: \(error)")
        }
        isLoading = false
    }
    
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    // MARK: - Send (Admin Broadcast)
    func sendNotification(title: String, message: String, type: NotificationType, userEmail: String = "all") async {
        guard let url = URL(string: baseURL + "send_notification.php") else { return }
        
        let newNotification = AppNotification(title: title, message: message, date: Date(), type: type, userEmail: userEmail)
        
        // ✅ Immediately add to the shared store so the user tab shows it without polling delay
        notifications.insert(newNotification, at: 0)
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("close", forHTTPHeaderField: "Connection")
            request.timeoutInterval = 30
            
            let encoder = JSONEncoder()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            encoder.dateEncodingStrategy = .formatted(formatter)
            request.httpBody = try encoder.encode(newNotification)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(SimpleResponse.self, from: data)
            
            if response.status != "success" {
                // Roll back the optimistic insert if backend failed
                notifications.removeAll { $0.id == newNotification.id }
                print("Send notification failed on server: \(response.message ?? "unknown")")
            }
        } catch {
            // Roll back the optimistic insert on network error
            notifications.removeAll { $0.id == newNotification.id }
            print("Send notification failed: \(error)")
        }
    }
    
    // MARK: - Delete
    func deleteNotification(at offsets: IndexSet) {
        let toDelete = offsets.map { notifications[$0] }
        notifications.remove(atOffsets: offsets)
        
        Task {
            for notif in toDelete {
                guard let url = URL(string: baseURL + "delete_notification.php") else { continue }
                do {
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.addValue("close", forHTTPHeaderField: "Connection")
                    request.timeoutInterval = 30
                    let body = ["id": notif.id]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                    let _ = try await URLSession.shared.data(for: request)
                } catch {
                    print("Delete notification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Mark All Read
    func markAllAsRead(for email: String) {
        guard let url = URL(string: baseURL + "mark_notifications_read.php") else { return }
        
        Task {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("close", forHTTPHeaderField: "Connection")
                request.timeoutInterval = 30
                let body = ["userEmail": email]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (data, _) = try await URLSession.shared.data(for: request)
                let _ = try JSONDecoder().decode(SimpleResponse.self, from: data)
                
                for i in 0..<notifications.count {
                    notifications[i].isRead = true
                }
            } catch {
                print("Mark read failed: \(error)")
            }
        }
    }
    
    func clearAll() {
        notifications.removeAll()
    }
}
