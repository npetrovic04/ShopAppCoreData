//
//  SignUpViewController.swift
//  ProbaDruga
//
//  Created by Jola on 21/08/22.
//

import UIKit

protocol RefreshControllerDelegate {
    func refreshControllerAction()
}

class SignUpViewController: UIViewController {
    @IBOutlet var firstNameTextField: UITextField!
    @IBOutlet var lastNameTextField: UITextField!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    
    var isFirstFlow: Bool = false
    var delegate: RefreshControllerDelegate?
    
    @IBAction func actionOnSubmit(_ sender: UIButton) {
        let validationResult = validateFields()
        if validationResult.isValidated {
            let firstName = firstNameTextField.text!
            let lastName = lastNameTextField.text!
            let email = emailTextField.text!
            let password = passwordTextField.text!
            newUserRegistration(firstName: firstName, lastName: lastName, email: email, password: password)
        } else {
            self.showAlert(message: validationResult.errorMessage ?? "")
        }
    }
    
    func newUserRegistration(firstName: String, lastName: String, email: String, password: String) {
        let newUser = NewCustomerRegistrationMutation(firstName: firstName, lastName: lastName, email: email, password: password)
        ProgressHUD.show()
        ApolloManager.shared.client.perform(mutation: newUser) { result in
            ProgressHUD.dismiss()
            switch result {
            case .success(let graphQLResult):
                if graphQLResult.data?.createCustomerV2?.customer != nil {
                    let alert = UIAlertController(title: "Registered Successfully", message: "Your account is under verification, once account is verified you can sign in to the app.", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "Ok", style: .default, handler: {_ in
                        self.dismiss(animated: true, completion: nil)
                    })
                    
                    alert.addAction(ok)
                    self.present(alert, animated: true, completion: nil)
                } else if let errorMessages = graphQLResult.errors, errorMessages.count > 0 {
                    self.showAlert(message: errorMessages[0].message ?? "Something went wrong, please try again later.")
                } else {
                    self.showAlert(message: "Something went wrong, please try again later.")
                }
            case .failure(let error):
                print("Error loading data \(error)")
            }
        }
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .default, handler: {_ in })
        
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func validateFields() -> (isValidated: Bool, errorMessage: String?) {
        
        if firstNameTextField.text!.trimmingCharacters(in: .whitespaces) == "" {
            return (false, "Please enter first name")
        }
        
        if lastNameTextField.text!.trimmingCharacters(in: .whitespaces) == "" {
            return (false, "Please enter last name")
        }
        
        if let emailText = emailTextField.text {
            if !emailText.isValidEmail() {
                return (false, "Please enter valid email")
            }
        } else {
            return (false, "Please enter your email")
        }
        
        if let passwordText = passwordTextField.text {
            if !passwordText.isValidPassword() {
                return (false, "Enter password with characters: Lower Case, Upper Case, Digits, Special Characters.")
            }
        } else {
            return (false, "Please enter your password")
        }
        return (true, nil)
    }
    
    
    @IBAction func actionOnLogin(_ sender: UIButton) {
        if isFirstFlow {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            guard let vC = storyBoard.instantiateViewController(withIdentifier: "SignInViewController") as? SignInViewController else {
                return
            }
            vC.delegate = delegate
            self.present(vC, animated: true, completion: nil)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func actionOnGoBack(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
