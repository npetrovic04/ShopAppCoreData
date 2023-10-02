//
//  SignInViewController.swift
//  ProbaDruga
//
//  Created by Jola on 20/08/22.
//

import UIKit

class SignInViewController: UIViewController {
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    
    var isFirstFlow: Bool = false
    var delegate: RefreshControllerDelegate?
    
    @IBAction func actionOnSubmit(_ sender: UIButton) {
        let validationResult = validateFields()
        if validationResult.isValidated {
            let email = emailTextField.text!
            let password = passwordTextField.text!
            authenticateUser(email: email, password: password)
        } else {
            self.showAlert(message: validationResult.errorMessage ?? "")
        }
    }
    
    @IBAction func actionOnCreateNewAccount(_ sender: UIButton) {
        if isFirstFlow {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            guard let vC = storyBoard.instantiateViewController(withIdentifier: "SignUpViewController") as? SignUpViewController else {
                return
            }
            vC.delegate = delegate
            self.present(vC, animated: true, completion: nil)
        }
        else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func actionOnGoBack(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .default, handler: {_ in })
        
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
    func validateFields() -> (isValidated: Bool, errorMessage: String?) {
        
        if let emailText = emailTextField.text {
            if !emailText.isValidEmail() {
                return (false, "Please enter valid email")
            }
        } else {
            return (false, "Please enter your email")
        }
        
        if passwordTextField.text!.isEmpty {
            return (false, "Please enter your password")
        }
        
        return (true, nil)
    }
    
    func authenticateUser(email: String, password: String) {
        ProgressHUD.show()
        ApolloManager.shared.client.perform(mutation: LoginCustomerMutation(email: email, password: password)) { result in
            ProgressHUD.dismiss()
            switch result {
            case .success(let graphQLResult):
                
                if let token = graphQLResult.data?.generateCustomerToken?.token {
                    ApolloManager.shared.setClient()
                    CustomUserDefaults.setUserAccessToken(token: token)
                    self.getCartItems()
                    self.delegate?.refreshControllerAction()
                    let sceneDelegate = UIApplication.shared.connectedScenes
                            .first!.delegate as! SceneDelegate
                    sceneDelegate.window?.rootViewController?.dismiss(animated: true, completion: nil)
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
    
    func getCartItems() {
        ProgressHUD.show()
        ApolloManager.shared.client.clearCache()
        ApolloManager.shared.client.fetch(query: GetCustomerCartItemsQuery()) { result in
            ProgressHUD.dismiss()
            switch result {
            case .success(let graphQLResult):
                if let cartItems = graphQLResult.data?.customerCart.items {
                    
                    var itemQuantityTotal = 0
                    for item in cartItems {
                        if let item = item {
                            itemQuantityTotal += Int(item.quantity)
                        }
                    }
                    
                    CustomUserDefaults.setCartItemCount(itemCount: itemQuantityTotal)
                    let scene = UIApplication.shared.connectedScenes.first
                    if let sd : SceneDelegate = (scene?.delegate as? SceneDelegate) {
                        sd.mainTabbarController?.updateBadgeValue()
                    }
                }
                
            case .failure(let error):
                print("Error loading data \(error)")
            }
        }
    }
}
