import SwiftUI
import Observation
import FirebaseAuth
import FirebaseDatabase

@Observable
class AuthManager {
    var isAuthenticated: Bool = false
    var currentUser: User? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil // To handle and display Firebase errors
    
    // Reference to the root of your Realtime Database
    private let dbRef = Database.database().reference()
    
    init() {
        // Automatically log the user in if Firebase remembers their session
        if let user = Auth.auth().currentUser {
            self.isAuthenticated = true
            Task { await fetchUserData(uid: user.uid) }
        }
    }
    
    @MainActor
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Authenticate with Firebase Auth
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            
            // 2. Fetch the user's custom profile from Realtime DB
            await fetchUserData(uid: result.user.uid)
            
            // 3. If fetchUserData failed to find a profile, create one from Auth data
            //    This handles the "partial registration" case where Auth succeeded but DB write failed previously
            if self.currentUser == nil {
                let fallbackName = result.user.displayName ?? "User"
                let fallbackEmail = result.user.email ?? email
                
                let userData: [String: Any] = [
                    "id": result.user.uid,
                    "name": fallbackName,
                    "email": fallbackEmail
                ]
                
                // Attempt to repair the missing DB entry
                try? await dbRef.child("users").child(result.user.uid).setValue(userData)
                self.currentUser = User(id: result.user.uid, name: fallbackName, email: fallbackEmail)
            }
            
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func register(name: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Create the secure user in Firebase Auth
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let uid = result.user.uid
            
            // 2. Create a dictionary of the custom data we want to save
            let userData: [String: Any] = [
                "id": uid,
                "name": name,
                "email": email
            ]
            
            // 3. Save it to Realtime Database under the path: users/uid/...
            //    If this fails, delete the Auth user to prevent a "partial registration"
            do {
                try await dbRef.child("users").child(uid).setValue(userData)
            } catch {
                // Rollback: delete the Auth account so the user can retry cleanly
                try? await result.user.delete()
                errorMessage = "Account created but failed to save profile. Please try again."
                isLoading = false
                return
            }
            
            // 4. Update local app state
            self.currentUser = User(id: uid, name: name, email: email)
            self.isAuthenticated = true
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    private func fetchUserData(uid: String) async {
        do {
            // Read data from Realtime Database
            let snapshot = try await dbRef.child("users").child(uid).getData()
            
            // Parse the dictionary back into our Swift User struct
            // Use fallback values so a missing field doesn't leave currentUser nil
            if let dict = snapshot.value as? [String: Any] {
                let name = dict["name"] as? String ?? "User"
                let email = dict["email"] as? String ?? ""
                self.currentUser = User(id: uid, name: name, email: email)
            }
            // If snapshot.value is not a dictionary, currentUser stays nil
            // The caller (login) handles this case
        } catch {
            print("Error fetching user data from DB: \(error)")
        }
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            currentUser = nil
        } catch {
            print("Error signing out: \(error)")
        }
    }
}