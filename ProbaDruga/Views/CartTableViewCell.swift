//
//  CartTableViewCell.swift
//  ProbaDruga
//
//  Created by Jola on 12/10/22.
//

import UIKit

class CartTableViewCell: UITableViewCell {
    @IBOutlet var itemImageView: UIImageView!
    @IBOutlet var itemName: UILabel!
    @IBOutlet var itemSku: UILabel!
    @IBOutlet var itemPrice: UILabel!
    @IBOutlet var itemQuantity: UILabel!
    @IBOutlet var quantityBorderView: UIStackView!
    @IBOutlet var contentBorderView: UIView!
    
    var decreasingQuanityHandler:()->Void = { }
    var increasingQuanityHandler:()->Void = { }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentBorderView.layer.cornerRadius = 5
        contentBorderView.layer.shadowRadius = 5
        contentBorderView.layer.shadowColor = UIColor.darkGray.cgColor
        contentBorderView.layer.shadowOffset = CGSize(width: -1, height: -1)
        contentBorderView.layer.shadowOpacity = 0.5
        
        quantityBorderView.layer.cornerRadius = 15
        quantityBorderView.layer.borderWidth = 1
        quantityBorderView.layer.borderColor = UIColor.systemGray2.cgColor
        quantityBorderView.layer.masksToBounds = true
    }
    
    
    @IBAction func actionOnMinusQty(_ sender: UIButton) {
        decreasingQuanityHandler()
    }
    
    @IBAction func actionOnPlusQty(_ sender: UIButton) {
        increasingQuanityHandler()
    }
}
