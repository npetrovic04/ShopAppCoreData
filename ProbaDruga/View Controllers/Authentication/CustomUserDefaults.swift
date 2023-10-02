//
//  CustomUserDefaults.swift
//  ProbaDruga
//
//  Created by Jola on 13/08/22.
//

import Foundation
import UIKit

let USER_EMAIL_ID = "User_Email_Id"
let USER_ACCESS_TOKEN = "User_Access_Token"
let USER_FIRST_NAME = "User_First_Name"
let USER_LAST_NAME = "User_Last_Name"
let CART_ITEM_COUNT = "Cart_Item_Count"

class CustomUserDefaults: NSObject {
    
    class func setUserEmailId(email: String?) {
        UserDefaults.standard.set(email, forKey: USER_EMAIL_ID)
    }

    class func getUserEmailId() -> String? {
        return UserDefaults.standard.value(forKey: USER_EMAIL_ID) as? String
    }
    
    class func setUserAccessToken(token: String?) {
        UserDefaults.standard.set(token, forKey: USER_ACCESS_TOKEN)
    }

    class func getUserAccessToken() -> String? {
        return UserDefaults.standard.value(forKey: USER_ACCESS_TOKEN) as? String
    }
    
    class func setUserFirstName(firstName: String?) {
        UserDefaults.standard.set(firstName, forKey: USER_FIRST_NAME)
    }

    class func getUserFirstName() -> String? {
        return UserDefaults.standard.value(forKey: USER_FIRST_NAME) as? String
    }
    
    class func setUserLastName(lastName: String?) {
        UserDefaults.standard.set(lastName, forKey: USER_LAST_NAME)
    }

    class func getUserLastName() -> String? {
        return UserDefaults.standard.value(forKey: USER_LAST_NAME) as? String
    }
    
    class func setCartItemCount(itemCount: Int?) {
        UserDefaults.standard.set(itemCount, forKey: CART_ITEM_COUNT)
    }

    class func getCartItemCount() -> Int? {
        return UserDefaults.standard.value(forKey: CART_ITEM_COUNT) as? Int
    }
    
    class func isCustomerLoggedIn() -> Bool {
        return getUserAccessToken() != nil
    }
    
    class func resetCustomerData() -> Bool {
        resetCustomer()
        
        let scene = UIApplication.shared.connectedScenes.first
        if let sd : SceneDelegate = (scene?.delegate as? SceneDelegate) {
            sd.mainTabbarController?.updateBadgeValue()
        }
        
        return true
    }
    
    class func resetCustomer() {
        self.setUserAccessToken(token: nil)
        self.setUserFirstName(firstName: nil)
        self.setUserLastName(lastName: nil)
        self.setUserEmailId(email: nil)
        self.setCartItemCount(itemCount: nil)
    }
 }
