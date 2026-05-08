import SwiftUI

// MARK: - Reusable Field Components
struct VertixInputField: View {
    let title: String
    let placeholder: String
    let leftIcon: String
    @Binding var text: String
    var isSecure: Bool = false
    
    @State private var isPasswordVisible: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
                .tracking(1.0) // Uppercase letter spacing
            
            HStack(spacing: 12) {
                Image(systemName: leftIcon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                if isSecure && !isPasswordVisible {
                    SecureField(placeholder, text: $text)
                        .foregroundColor(.primary)
                } else {
                    TextField(placeholder, text: $text)
                        .foregroundColor(.primary)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                if isSecure {
                    Button(action: { isPasswordVisible.toggle() }) {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.vertixFieldBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
        }
    }
}

// Add this to your Color extension from Phase 2
extension Color {
    // The very soft warm beige used inside the text fields
    static let vertixFieldBackground = Color(red: 248/255, green: 245/255, blue: 240/255)
}