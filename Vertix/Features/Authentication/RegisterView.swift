import SwiftUI

struct RegisterView: View {
    @Environment(AuthManager.self) private var authManager
    @Binding var showRegister: Bool
    
    @State private var name = ""
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
                    Text("Welcome to Vertix!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Sign up to start tracking your posture!")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
                
                // MARK: - Form Card
                VStack(spacing: 24) {
                    VertixInputField(
                        title: "NAME",
                        placeholder: "Your Name",
                        leftIcon: "person",
                        text: $name
                    )
                    
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
                    
                    // Register Button
                    Button(action: {
                        Task { await authManager.register(name: name, email: email, password: password) }
                    }) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Register")
                                Image(systemName: "arrow.right")
                            }
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(name.isEmpty || email.isEmpty || password.isEmpty ? Color.gray : Color.vertixDarkGreen)
                        .cornerRadius(16)
                    }
                    .disabled(name.isEmpty || email.isEmpty || password.isEmpty || authManager.isLoading)
                    .padding(.top, 8)
                }
                .padding(32)
                .background(Color.white)
                .cornerRadius(32)
                .shadow(color: Color.black.opacity(0.03), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // MARK: - Footer
                Button(action: {
                    withAnimation { showRegister = false }
                }) {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(.secondary)
                        Text("Log In")
                            .fontWeight(.bold)
                            .foregroundColor(Color.vertixDarkGreen)
                    }
                    .font(.system(size: 15))
                }
                .padding(.bottom, 20)
            }
        }
        // MARK: - Error Alert
        .alert("Registration Failed", isPresented: Binding<Bool>(
            get: { authManager.errorMessage != nil },
            set: { if !$0 { authManager.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authManager.errorMessage ?? "")
        }
    }
}