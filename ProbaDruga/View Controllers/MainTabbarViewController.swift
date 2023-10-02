//
//  MainTabbarViewController.swift
//  ProbaDruga
//
//  Created by Jola on 24/09/22.
//

import UIKit

class MainTabbarViewController: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            let tabBarAppearance: UITabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithDefaultBackground()
            UITabBar.appearance().standardAppearance = tabBarAppearance

            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
        }
        
        self.tabBar.layer.borderColor = UIColor.gray.cgColor
        self.tabBar.clipsToBounds = true
        self.tabBar.shadowImage = UIImage.init(named: "line")
        self.tabBar.backgroundColor = UIColor.white
        
        self.delegate = self
        manageTabbar()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateBadgeValue()
    }
    
    
    private func manageTabbar() {
        let homeVC = getNavController("Main", "HomeViewController")
        let homeTabItem = UITabBarItem(title: "Home", image: UIImage(named: "home_icon"), selectedImage: UIImage(named: "home_icon"))
        homeVC.tabBarItem = homeTabItem
        
        let anythingVC = getNavController("Main", "AnythingViewController")
        let anythingTabItem = UITabBarItem(title: "Anything", image: UIImage(named: "anything_icon"), selectedImage: UIImage(named: "anything_icon"))
        anythingVC.tabBarItem = anythingTabItem
        
        let wishListVC = getNavController("Main", "WishlistViewController")
        let wishListTabItem = UITabBarItem(title: "Wishlist", image: UIImage(named: "wishlist_icon"), selectedImage: UIImage(named: "wishlist_icon"))
        wishListVC.tabBarItem = wishListTabItem
        
        let cartVC = getNavController("Main", "CartViewController")
        let cartTabItem = UITabBarItem(title: "Cart", image: UIImage(named: "cart_icon"), selectedImage: UIImage(named: "cart_icon"))
        cartVC.tabBarItem = cartTabItem
        
        let accountVC = getNavController("Main", "ProfileViewController")
        let accountTabItem = UITabBarItem(title: "Account", image: UIImage(named: "account_icon"), selectedImage: UIImage(named: "account_icon"))
        accountVC.tabBarItem = accountTabItem
        
        self.viewControllers = [homeVC, anythingVC, wishListVC, cartVC, accountVC ]
    }
    
    func getNavController(_ storyboardString: String, _ controllerName: String) -> UINavigationController {
        let storyBoard = UIStoryboard(name: storyboardString, bundle: nil)
        let controller = storyBoard.instantiateViewController(withIdentifier: controllerName)
        let navController = UINavigationController(rootViewController: controller)
        navController.isNavigationBarHidden = false
        return navController
    }
    
    
    func updateBadgeValue() {
        if let tabItems = self.tabBar.items {
            if tabItems.count >= 4 {
                let tabItem = tabItems[3]
                
                if let cartItemCount = CustomUserDefaults.getCartItemCount(), cartItemCount > 0 {
                    tabItem.badgeValue = "\(cartItemCount)"
                    tabItem.badgeColor = UIColor.red
                } else {
                    tabItem.badgeValue = nil
                    tabItem.badgeColor = UIColor.clear
                }
            }
        }
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
        
    }
    

    // UITabBarControllerDelegate
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        print("Selected view controller")
    }
}
