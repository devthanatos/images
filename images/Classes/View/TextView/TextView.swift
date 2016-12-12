//
//  TextView.swift
//  images
//
//  Created by Michael Akopyants on 12/12/2016.
//  Copyright © 2016 devthanatos. All rights reserved.
//

import UIKit

class TextView: UIView {
    
    @IBOutlet weak var textField: UITextField!
 
    init()
    {
        super.init(frame: CGRect())
        loadView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadView()
    {
        let textField = UITextField()
        textField.delegate = self
        self.textField = textField
        self.textField.returnKeyType = .done
        self.textField.tintColor = UIColor.white
        self.textField.textColor = UIColor.white
        self.textField.backgroundColor = UIColor.clear
        self.textField.textAlignment = .center
        self.backgroundColor = UIColor.clear
        
        self.addSubview(self.textField)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.textField.frame = self.bounds
    }
}

extension TextView : UITextFieldDelegate{
        
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
