//
//  NotifyParentsView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 28/08/2025.
//

import SwiftUI

struct NotifyParentsView: View {
    @State private var students = ["John Doe", "Mary Jane", "Ali Hassan"] // Example list
    @State private var selectedStudent: String? = nil
    
    @State private var statusMessage = ""
    @State private var isSending = false
    
    var body: some View {
        ZStack {
            Color.blue
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("SafeRider Notifications")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                // 🔹 Student Picker
                Picker("Select Student", selection: $selectedStudent) {
                    Text("Choose a student").tag(nil as String?)
                    ForEach(students, id: \.self) { student in
                        Text(student).tag(student as String?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                
                // Drop-off button
                Button(action: {
                    if let student = selectedStudent {
                        sendNotification(event: "dropoff", student: student)
                    } else {
                        statusMessage = "⚠️ Please select a student first."
                    }
                }) {
                    Text("✅ Dropped at School")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                // Pickup button
                Button(action: {
                    if let student = selectedStudent {
                        sendNotification(event: "pickup", student: student)
                    } else {
                        statusMessage = "⚠️ Please select a student first."
                    }
                }) {
                    Text("🏡 Back Home Safe")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                if isSending {
                    ProgressView("Sending...")
                        .foregroundColor(.white)
                }
                
                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .foregroundColor(.yellow)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    // 🔹 Function to call backend API
    private func sendNotification(event: String, student: String) {
        guard let url = URL(string: "https://your-backend.com/notify") else { return }
        
        isSending = true
        statusMessage = ""
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "driver_id": "123",
            "child_name": student,
            "event": event
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSending = false
                if let error = error {
                    statusMessage = "❌ Failed: \(error.localizedDescription)"
                } else {
                    statusMessage = "✅ Notification sent to \(student)’s parent!"
                }
            }
        }.resume()
    }
}
