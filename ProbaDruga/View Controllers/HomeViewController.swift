//
//  HomeViewController.swift
//  ProbaDruga
//
//  Created by Jola on 30/07/22.
//

import UIKit

class HomeViewController: UIViewController {
    
    override func viewDidLoad() {
       super.viewDidLoad()
        
        self.title = "Home"
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarButton()
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
    
    func getCustomerInformation() {
        ProgressHUD.show()
        ApolloManager.shared.client.fetch(query: GetCustomerInformationQuery()) { result in
            ProgressHUD.dismiss()
            switch result {
            case .success(let graphQLResult):
                if graphQLResult.data?.customer == nil {
                    _ = CustomUserDefaults.resetCustomerData()
                }
                let scene = UIApplication.shared.connectedScenes.first
                if let sd : SceneDelegate = (scene?.delegate as? SceneDelegate) {
                    sd.mainTabbarController?.updateBadgeValue()
                }
            
            case .failure(let error):
                print("Error loading data \(error)")
            }
        }
    }
}

extension HomeViewController: RefreshControllerDelegate {
    func refreshControllerAction() {
        setNavigationBarButton()
    }
}
