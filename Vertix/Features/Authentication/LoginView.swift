import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager
    @Binding var showRegister: Bool
    
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        ZStack {
            Color.vertixBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Logo Area
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.vertixDarkGreen)
                            .frame(width: 72, height: 72)
                        
                        // Placeholder for your actual logo image
                        Image(systemName: "figure.mind.and.body")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    }
                    
                    Text("VERTIX")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.vertixDarkGreen)
                        .tracking(2.0)
                }
                .padding(.top, 40)
                .padding(.bottom, 40)
                
                // MARK: - Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome Back")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Sign in to continue tracking your posture!")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
                
                // MARK: - Form Card
                VStack(spacing: 24) {
                    VertixInputField(
                        title: "EMAIL ADDRESS",
                        placeholder: "you@example.com",
                        leftIcon: "envelope",
                        text: $email
                    )
                    
                    VertixInputField(
                        title: "PASSWORD",
                        placeholder: "••••••••",
                        leftIcon: "lock",
                        text: $password,
                        isSecure: true
                    )
                    
                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            // Forgot password action
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.vertixDarkGreen)
                    }
                    .padding(.top, -8)
                    
                    // Login Button
                    Button(action: {
                        Task { await authManager.login(email: email, password: password) }
                    }) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Login")
                                Image(systemName: "arrow.right")
                            }
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(email.isEmpty || password.isEmpty ? Color.gray : Color.vertixDarkGreen)
                        .cornerRadius(16)
                    }
                    .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
                }
                .padding(32)
                .background(Color.white)
                .cornerRadius(32)
                .shadow(color: Color.black.opacity(0.03), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // MARK: - Footer
                Button(action: {
                    withAnimation { showRegister = true }
                }) {
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(.secondary)
                        Text("Sign Up")
                            .fontWeight(.bold)
                            .foregroundColor(Color.vertixDarkGreen)
                    }
                    .font(.system(size: 15))
                }
                .padding(.bottom, 20)
            }
        }
    }
}