//
//  ProfileViewController.swift
//  ProbaDruga
//
//  Created by Jola on 24/08/22.
//

import UIKit

class ProfileViewController: UIViewController {
    @IBOutlet var firstNameLabel: UILabel!
    @IBOutlet var lastNameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    
    @IBOutlet var noAccessView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "My Profile"
        setTextValues()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setNavigationBarButton()
        
        if CustomUserDefaults.isCustomerLoggedIn() {
            getCustomerInformation()
            noAccessView.isHidden = true
        } else {
            noAccessView.isHidden = false
        }
    }
    
    func setNavigationBarButton() {
        let leftNavBarButton = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal"), style: .plain, target: self, action: #selector(didTapMenu))
        leftNavBarButton.tintColor = .black
        self.navigationItem.leftBarButtonItem  = leftNavBarButton
    }
    
    @objc func didTapMenu() {
        // opens side menu
        sideMenuController?.revealMenu()
        sideMenuController?.menuViewController.viewWillAppear(true)
    }
    
    
    @IBAction func actionOnSignIn(_ sender: UIButton) {
        doSignIn()
    }
    
    
    func setTextValues(){
        self.firstNameLabel.text = CustomUserDefaults.getUserFirstName()
        self.lastNameLabel.text = CustomUserDefaults.getUserLastName()
        self.emailLabel.text = CustomUserDefaults.getUserEmailId()
    }
    
    func getCustomerInformation() {
        ProgressHUD.show()
        ApolloManager.shared.client.fetch(query: GetCustomerInformationQuery()) { result in
            ProgressHUD.dismiss()
            switch result {
            case .success(let graphQLResult):
                if let customer = graphQLResult.data?.customer {
                    CustomUserDefaults.setUserFirstName(firstName: customer.firstname)
                    CustomUserDefaults.setUserLastName(lastName: customer.lastname)
                    CustomUserDefaults.setUserEmailId(email: customer.email)
                    self.firstNameLabel.text = "\(customer.firstname ?? "")"
                    self.lastNameLabel.text = "\(customer.lastname ?? "")"
                    self.emailLabel.text = "\(customer.email ?? "")"
                } else {
                    _ = CustomUserDefaults.resetCustomerData()
                    self.setTextValues()
                    self.noAccessView.isHidden = false
                    self.doSignIn()
//                    print(graphQLResult.errors?.debugDescription)
                }
            
            case .failure(let error):
                print("Error loading data \(error)")
            }
        }
    }
    
    func doSignIn() {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        guard let vC = storyBoard.instantiateViewController(withIdentifier: "SignInViewController") as? SignInViewController else {
            return
        }
        vC.isFirstFlow = true
        vC.delegate = self
        self.present(vC, animated: true, completion: nil)
    }
}


extension ProfileViewController: RefreshControllerDelegate {
    func refreshControllerAction() {
        if CustomUserDefaults.isCustomerLoggedIn() {
            getCustomerInformation()
            noAccessView.isHidden = true
        } else {
            noAccessView.isHidden = false
        }
    }
}
