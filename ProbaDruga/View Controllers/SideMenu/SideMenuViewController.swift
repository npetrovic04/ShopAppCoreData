//
//  SideMenuViewController.swift
//  ProbaDruga
//
//  Created by Jola on 22/07/22.
//

import UIKit
import SideMenu


class SideMenuViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var signIn: UIButton!
    @IBOutlet var signUp: UIButton!
    @IBOutlet var signOut: UIButton!
    
    
    var categories: [CategoryListQuery.Data.CategoryList.Child] = []
    var mainCategoryId = "Mg=="
    
    
    override func viewDidLoad() {
       super.viewDidLoad()
        signIn.layer.cornerRadius = 6
        signUp.layer.cornerRadius = 6
        signOut.layer.cornerRadius = 6
        
        tableView.delegate = self
        tableView.dataSource = self
        
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        doLoginCheck()
    }
    
    func doLoginCheck() {
        if CustomUserDefaults.isCustomerLoggedIn() {
            signOut.isHidden = false
            signIn.isHidden = true
            signUp.isHidden = true
        } else {
            signOut.isHidden = true
            signIn.isHidden = false
            signUp.isHidden = false
        }
    }
    
    @IBAction func actionOnSignIn(_ sender: UIButton) {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        guard let vC = storyBoard.instantiateViewController(withIdentifier: "SignInViewController") as? SignInViewController else {
            return
        }
        vC.delegate = self
        vC.isFirstFlow = true
        self.present(vC, animated: true, completion: nil)
    }
    
    @IBAction func actionOnSignUp(_ sender: UIButton) {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        guard let vC = storyBoard.instantiateViewController(withIdentifier: "SignUpViewController") as? SignUpViewController else {
            return
        }
        vC.delegate = self
        vC.isFirstFlow = true
        self.present(vC, animated: true, completion: nil)
    }
    
    @IBAction func actionOnSignOut(_ sender: UIButton) {
        ApolloManager.shared.client.perform(mutation: LogoutCustomerMutation()) { result in
            switch result {
            case .success(let graphQLResult):
                ApolloManager.shared.setClient()
                let domain = Bundle.main.bundleIdentifier!
                UserDefaults.standard.removePersistentDomain(forName: domain)
                UserDefaults.standard.synchronize()
                let sceneDelegate = UIApplication.shared.connectedScenes
                        .first!.delegate as! SceneDelegate
                sceneDelegate.setRootViewController()
            case .failure(let error):
                print("Error loading data \(error)")
            }
        }
    }
}

extension SideMenuViewController {
    func loadData() {
        let query = CategoryListQuery(categoryId: mainCategoryId)
        ProgressHUD.show()
        ApolloManager.shared.client.fetch(query: query, cachePolicy: .returnCacheDataAndFetch) { result in
            ProgressHUD.dismiss()
            switch result {
            case .success(let graphQLResult):
                if let categories = graphQLResult.data?.categoryList![0]?.children!.compactMap({ $0 }) {
                    let filteredCategories = categories.filter {$0.includeInMenu == 1}
                    self.categories = filteredCategories
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print("Error loading data \(error)")
            }
        }
    }
}

extension SideMenuViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return (section == 0) ? 1 : categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoriesCell")!
        
        if indexPath.section == 0 {
            cell.textLabel?.text = "Home"
        } else {
            let category = categories[indexPath.row]
            cell.textLabel?.text = category.name
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            sideMenuController?.setContentViewController(with: "MainTabbar")
            sideMenuController?.hideMenu()
        } else {
            let category = categories[indexPath.row]
            
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            if (category.children?.count ?? 0) > 0 {
                // Navigation to Sub Category Listing Screen
                guard let vC = storyBoard.instantiateViewController(withIdentifier: "CategoryViewController") as? CategoryViewController else {
                    return
                }
                vC.parentCategoryId = category.uid
                vC.parentCategoryTitle = category.name?.capitalized ?? ""
                sideMenuController?.contentViewController = UINavigationController(rootViewController: vC)
                sideMenuController?.hideMenu()
            } else {
                // Navigation to Product Listing Screen
                guard let vC = storyBoard.instantiateViewController(withIdentifier: "ProductViewController") as? ProductViewController else {
                    return
                }
                vC.isRootController = true
                vC.productCategoryId = category.uid
                vC.productCategoryTitle = category.name?.capitalized ?? ""
                sideMenuController?.contentViewController = UINavigationController(rootViewController: vC)
                sideMenuController?.hideMenu()
            }
        }
    }
}
extension SideMenuViewController: RefreshControllerDelegate {
    func refreshControllerAction() {
        self.doLoginCheck()
    }
}
