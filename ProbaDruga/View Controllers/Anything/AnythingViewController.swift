//
//  AnythingViewController.swift
//  ProbaDruga
//
//  Created by Jola on 30/09/22.
//

import UIKit

class AnythingViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Anything"
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
}
