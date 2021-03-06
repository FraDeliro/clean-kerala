//
/*
LoginViewController.swift
Created on: 7/18/18

Abstract:
 this controller will allow users to login as well as logout from the App

 note: login is mandatory for adding/removing the toilets
*/

import UIKit
import FirebaseAuth
import Reachability

final class LoginViewController: UIViewController {
    
    // MARK: Properties
    
    /// PRIVATE
    @IBOutlet weak private var emailAddress: UITextField!
    @IBOutlet weak private var password: UITextField!
    @IBOutlet weak private var loginButton: UIButton!
    @IBOutlet weak private var logoutButton: UIButton!
    private let reachability = Reachability()!
    private struct C {
        struct Alert {
            static let title = "Authentication"
            static let successLoginMessage = "You have successfully logged in."
            static let successLogoutMessage = "You have successfully logged out."
            static let okayTitle = "Okay"
            static let noNetworkMessage = "No Network connectivity"
        }
        static let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        static let validEmailErrorMessage = "Please enter a valid email address"
        static let validPasswordErrorMessage = "Please enter a valid password"
    }
    
    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateUI()
    }
    
    // MARK: Button Actions
    
    @IBAction func onCancel(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onLogin(_ sender: UIButton) {
        
        // GUARD: checks for valid email address
        guard let emailString = emailAddress.text, let email = validateEmailAddress(emailString) else {
            presentAlert(C.validEmailErrorMessage, completion: nil)
            return
        }
        
        // GUARD: checks for valid password
        guard let pass = password.text, pass.count > 0 else {
            presentAlert(C.validPasswordErrorMessage, completion: nil)
            return
        }
        
        guard reachability.connection != .none else {
            presentAlert(C.Alert.noNetworkMessage, completion: nil)
            return
        }
        
        login(email, password: pass)
    }
    
    @IBAction func onLogout(_ sender: UIButton) {
        Overlay.shared.show()
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        
        Overlay.shared.remove()
        presentAlert(C.Alert.successLogoutMessage, completion: { [unowned self] (_) in
            self.dismiss(animated: true, completion: nil)
        })
    }
}

// MARK: Private helper functions

private extension LoginViewController {
    
    /**
     one time UI setup is done inside this function. it gets called when view is finished loading.
     */
    func configureUI() {
        let loggedIn = Auth.auth().currentUser != nil
        loginButton.isEnabled = !loggedIn
        logoutButton.isEnabled = loggedIn
        
        // if logged in, users should mainly see logout.
        // when they are logged out, they should see login.
        loginButton.alpha = loggedIn ? 0.5 : 1.0
        logoutButton.alpha = loggedIn ? 1.0: 0.5
    }
    
    
    /**
     update the UI whenever the view is shown.
     */
    func updateUI() {
        navigationController?.isNavigationBarHidden = false
    }
    
    /**
     logs in with the given email address and password. If success show an alert and will dismiss
     - parameters:
        - email: self descriptive
        - password: self descriptive
     */
    func login(_ email: String, password: String) {
        Overlay.shared.show()
        Auth.auth().signIn(withEmail: email, password: password) { [unowned self] (result, error) in
            Overlay.shared.remove()
            guard error == nil else {
                self.presentAlert((error!.localizedDescription), completion: nil)
                return
            }
            
            self.presentAlert(C.Alert.successLoginMessage, completion: { [unowned self] (_) in
                self.dismiss(animated: true, completion: nil)
            })
        }
    }
    
    /**
     this will validate the passed in string as a valid email address or not. returns the string if its valid email else
     nil.
     */
    func validateEmailAddress(_ email: String) -> String? {
        let emailTest = NSPredicate(format:"SELF MATCHES %@", C.emailRegex)
        if emailTest.evaluate(with: email) {
            return email
        }
        return nil
    }
    
    func presentAlert(_ message: String, completion: ((UIAlertAction) -> Swift.Void)? = nil) {
        let alertvc = UIAlertController(title: C.Alert.title,
                                        message: message,
                                        preferredStyle: .alert)
        let okay = UIAlertAction(title: C.Alert.okayTitle,
                                 style: .default,
                                 handler: completion)
        alertvc.addAction(okay)
        present(alertvc, animated: true, completion: nil)
    }
}
