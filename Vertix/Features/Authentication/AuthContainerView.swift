import SwiftUI

struct AuthContainerView: View {
    @State private var showRegister: Bool = false
    
    var body: some View {
        Group {
            if showRegister {
                RegisterView(showRegister: $showRegister)
                    .transition(.move(edge: .trailing))
            } else {
                LoginView(showRegister: $showRegister)
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showRegister)
    }
}
