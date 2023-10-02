//
//  BaseViewController.swift
//  ProbaDruga
//
//  Created by Jola on 25/09/22.
//

import UIKit
import SideMenu

class BaseViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // loading progress until it loads the products from the server
        ProgressHUD.animationType = .lineSpinFade
        ProgressHUD.colorHUD = .darkGray
        ProgressHUD.colorBackground = .darkGray
        ProgressHUD.colorAnimation = .black
        
    }
    
    //
    func addProductToCart(quantity: Double, sku: String, completionHandlerCart: @escaping(Bool) -> Void) {
        getCartId(completionHandler: { (isSuccess, cartId, message) in
            if isSuccess {
                ApolloManager.shared.client.perform(mutation: AddProductsToCartMutation(cartId: cartId!, quantity: quantity, sku: sku)) { result in
                    switch result {
                    case .success(let graphQLResult):
                        if let items = graphQLResult.data?.addProductsToCart?.cart.items {
                            completionHandlerCart(true)
                            
                            var itemQuantityTotal = 0
                            for item in items {
                                if let item = item {
                                    itemQuantityTotal += Int(item.quantity)
                                }
                            }
                            
                            CustomUserDefaults.setCartItemCount(itemCount: itemQuantityTotal)
                            self.updateCartBadgeCount()
                            print(itemQuantityTotal)
                            self.showAlert(title: "Successfully, added to cart", message: "")
                        } else {
                            completionHandlerCart(false)
                            self.showAlert(title: "Error", message: "Failed to add item to cart, please try later.")
                        }
                        
                    case .failure(let error):
                        print("Error loading data \(error)")
                        completionHandlerCart(false)
                        self.showAlert(title: "Error", message: "Failed to add item to cart, please try later.")
                    }
                }
                
                
            } else {
                completionHandlerCart(false)
                if message != "" {
                    self.showAlert(title: "Error", message: message)
                }
            }
        })
    }
    
    func getCartId(completionHandler: @escaping(_ isSuccess : Bool, _ cartId: String?, _ message: String) -> Void) {
        ApolloManager.shared.client.fetch(query: GetCustomerCartIdQuery()) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors, errors.count > 0 {
                    if let erroryType = errors[0].extensions?["category"] as? String, erroryType == "graphql-authorization" {
                        CustomUserDefaults.resetCustomer()
                        let alert = UIAlertController(title: "Alert", message: "Please login to add item to your cart.", preferredStyle: .alert)
                        let ok = UIAlertAction(title: "Login Now", style: .default, handler: {_ in
                            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                            guard let vC = storyBoard.instantiateViewController(withIdentifier: "SignInViewController") as? SignInViewController else {
                                return
                            }
//                                    vC.delegate = self
                            vC.isFirstFlow = true
                            self.present(vC, animated: true, completion: nil)
                        })
                        let cancel = UIAlertAction(title: "Cancel", style: .destructive, handler: {_ in })
                        
                        alert.addAction(ok)
                        alert.addAction(cancel)
                        self.present(alert, animated: true, completion: nil)
                        completionHandler(false, nil, "")
                    }
                } else {
                    if let cartId = graphQLResult.data?.customerCart.id, cartId != "" {
                        completionHandler(true, cartId, "Success")
                    } else {
                        completionHandler(false, nil, "Something went wrong, please try again later")
                    }
                }
            case .failure(let error):
                print("Error loading data \(error)")
                completionHandler(false, nil, "Something went wrong, please try again later")
            }
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .default, handler: {_ in })
        
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func updateCartBadgeCount() {
        let scene = UIApplication.shared.connectedScenes.first
        if let sd : SceneDelegate = (scene?.delegate as? SceneDelegate) {
            sd.mainTabbarController?.updateBadgeValue()
        }
    }
    
    
    func addItemToWishlist(quantity: Double, sku: String, completionHandlerCart: @escaping(Bool) -> Void) {
        ProgressHUD.show()
        ApolloManager.shared.client.fetch(query: GetCustomerWishListQuery()) { result in
            ProgressHUD.dismiss()
            switch result {
            case .success(let graphQLResult):
                var wishListId = "0"
                if let wishlists = graphQLResult.data?.customer?.wishlists, wishlists.count > 0, let oldWishListId = wishlists[0]?.id {
                    wishListId = oldWishListId
                }
                
                ApolloManager.shared.client.perform(mutation: AddProductsToWishlistMutation(wishListId: wishListId, quantity: quantity, sku: sku)) { result in
                    switch result {
                    case .success(let graphQLResult):
                        completionHandlerCart(true)
                        if let errors = graphQLResult.errors, errors.count > 0 {
                            if let erroryType = errors[0].extensions?["category"] as? String, erroryType == "graphql-authorization" {
                                CustomUserDefaults.resetCustomer()
                                let alert = UIAlertController(title: "Alert", message: "Please login to add item to your wishlist.", preferredStyle: .alert)
                                let ok = UIAlertAction(title: "Login Now", style: .default, handler: {_ in
                                    let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                                    guard let vC = storyBoard.instantiateViewController(withIdentifier: "SignInViewController") as? SignInViewController else {
                                        return
                                    }
//                                    vC.delegate = self
                                    vC.isFirstFlow = true
                                    self.present(vC, animated: true, completion: nil)
                                })
                                let cancel = UIAlertAction(title: "Cancel", style: .destructive, handler: {_ in })
                                
                                alert.addAction(ok)
                                alert.addAction(cancel)
                                self.present(alert, animated: true, completion: nil)
                            }
                        } else {
                            self.showAlert(title: "Successfully, added to wishlist", message: "")
                        }
                    case .failure(let error):
                        print("Error loading data \(error)")
                        completionHandlerCart(false)
                        self.showAlert(title: "Error", message: "Failed to add item to wishlist, please try later.")
                    }
                }
                
            case .failure(let error):
                print("Error loading data \(error)")
            }
        }
    }
    
    
    func removeItemFromWishlist(wishListId: String, wishListItemId: String, completionHandlerCart: @escaping(Bool) -> Void) {
        ProgressHUD.show()
        ApolloManager.shared.client.perform(mutation: RemoveProductFromWishListMutation(wishListId: wishListId, wishlistItemsId: wishListItemId)) { result in
            ProgressHUD.dismiss()
            switch result {
            case .success(let graphQLResult):
                completionHandlerCart(true)
                print(graphQLResult.errors?.debugDescription)
                self.showAlert(title: "Successfully, removed from wishlist", message: "")
                
            case .failure(let error):
                print("Error loading data \(error)")
            }
        }
    }
}
