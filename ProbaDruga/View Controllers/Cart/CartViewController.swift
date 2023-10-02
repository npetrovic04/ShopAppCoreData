//
//  CartViewController.swift
//  ProbaDruga
//
//  Created by Jola on 07/10/22.
//

import UIKit
import Apollo

class CartViewController: BaseViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var subTotalTitle: UILabel!
    @IBOutlet var subTotalAmount: UILabel!
    
    @IBOutlet var noAccessView: UIView!
    
    var cartItems: [GetCustomerCartItemsQuery.Data.CustomerCart.Item?]?
    var cartId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Cart"
        
        self.subTotalTitle.text = "Sub Total (0 Item)"
        self.subTotalAmount.text = "---"
        
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarButton()
        
        if CustomUserDefaults.isCustomerLoggedIn() {
            getCartItems()
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
    
    func doSignIn() {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        guard let vC = storyBoard.instantiateViewController(withIdentifier: "SignInViewController") as? SignInViewController else {
            return
        }
        vC.isFirstFlow = true
        vC.delegate = self
        self.present(vC, animated: true, completion: nil)
    }
    
    
    func getCartItems() {
        ProgressHUD.show()
        ApolloManager.shared.client.clearCache()
        ApolloManager.shared.client.fetch(query: GetCustomerCartItemsQuery()) { result in
            ProgressHUD.dismiss()
            switch result {
            case .success(let graphQLResult):
                if let cartId = graphQLResult.data?.customerCart.id, let cartItems = graphQLResult.data?.customerCart.items, let totalPrice = graphQLResult.data?.customerCart.prices?.grandTotal {
                    self.cartId = cartId
                    self.cartItems?.removeAll()
                    self.cartItems = cartItems
                    self.tableView.reloadData()
                    
                    var itemQuantityTotal = 0
                    for item in cartItems {
                        if let item = item {
                            itemQuantityTotal += Int(item.quantity)
                        }
                    }
                    
                    if itemQuantityTotal > 0 {
                        self.subTotalTitle.text = "Sub Total (\(itemQuantityTotal) \((itemQuantityTotal > 1) ? "Items" : "Item"))"
                        
                        let currencySymbol = totalPrice.currency?.rawValue ?? "$"
                        self.subTotalAmount.text = "\(currencySymbol) \(totalPrice.value ?? 0.0)"
                    } else {
                        self.subTotalTitle.text = "Your cart is empty."
                        self.subTotalAmount.text = ""
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
    
    
    func updateCartItems(cartId: String, quantity: Double, cart_item_uid: String) {
        ProgressHUD.show()
        ApolloManager.shared.client.perform(mutation: UpdateCartItemsMutation(cart_id: cartId, quantity: quantity, cart_item_uid: cart_item_uid)) { result in
            ProgressHUD.dismiss()
            switch result {
            case .success(let graphQLResult):
                print(graphQLResult.errors?.debugDescription)
                self.getCartItems()
            case .failure(let error):
                print("Error loading data \(error)")
                self.showAlert(title: "Error", message: "Failed to update item to cart, please try later.")
            }
        }
    }
}

extension CartViewController: RefreshControllerDelegate {
    func refreshControllerAction() {
        if CustomUserDefaults.isCustomerLoggedIn() {
            noAccessView.isHidden = true
            getCartItems()
        } else {
            noAccessView.isHidden = false
        }
    }
}



extension CartViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cartItems?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CartTableViewCell", for: indexPath) as! CartTableViewCell
        if let dataObj = cartItems?[indexPath.row] {
            
            cell.itemImageView.sd_setImage(with: URL(string: dataObj.product.image?.url ?? ""), completed: nil)
            cell.itemName.text = dataObj.product.name?.capitalized
            cell.itemSku.text = "SKU: \(dataObj.product.sku ?? "")"
            let currencySymbol = dataObj.product.priceRange.minimumPrice.finalPrice.currency?.rawValue ?? "$"
            cell.itemPrice?.text = "\(currencySymbol) \(dataObj.product.priceRange.minimumPrice.finalPrice.value ?? 0.0)"
            cell.itemQuantity.text = "\(Int(dataObj.quantity))"
            
            cell.decreasingQuanityHandler = {
                var qty = dataObj.quantity
                qty -= 1
                
                if qty >= 1 {
                    cell.itemQuantity.text = "\(Int(qty))"
                    self.updateCartItems(cartId: self.cartId, quantity: Double(qty), cart_item_uid: dataObj.uid)
                } else {
                    self.showAlert(title: "Alert", message: "Minimum 1 quantity.")
                }
            }
            
            cell.increasingQuanityHandler = {
                var qty = dataObj.quantity
                qty += 1
                cell.itemQuantity.text = "\(Int(qty))"
                self.updateCartItems(cartId: self.cartId, quantity: Double(qty), cart_item_uid: dataObj.uid)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let dataObj = cartItems?[indexPath.row] {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            guard let vC = storyBoard.instantiateViewController(withIdentifier: "ProductDetailsViewController") as? ProductDetailsViewController else { return }
            vC.sku = dataObj.product.sku
            self.navigationController?.pushViewController(vC, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
     
            let deleteAction = UIContextualAction(style: .destructive, title: "Delete") {
                (action, sourceView, completionHandler) in
                
                let alertController = UIAlertController(title: "Alert", message: "Do you want to delete this?", preferredStyle: .alert)
                let oKAction = UIAlertAction(title: "Yes", style: .default, handler: {_ in
                    self.swipeDeleteAction(indexPath: indexPath)
                })
                
                let cancelAction = UIAlertAction(title: "No", style: .destructive, handler: nil)
                
                alertController.addAction(oKAction)
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: nil)
                
            }
            
            let swipeConfiguration = UISwipeActionsConfiguration(actions: [deleteAction])
            swipeConfiguration.performsFirstActionWithFullSwipe = false
            
            return swipeConfiguration
            
        }
    
    
    func swipeDeleteAction(indexPath: IndexPath) {
            
        if let dataObj = self.cartItems?[indexPath.row] {
            self.updateCartItems(cartId: self.cartId, quantity: 0, cart_item_uid: dataObj.uid)
        }
    }
}

