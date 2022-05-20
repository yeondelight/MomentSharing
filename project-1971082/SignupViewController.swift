//
//  SignupViewController.swift
//  project-1971082
//
//  Created by 김다연 on 2022/05/19.
//

import UIKit
import Firebase
import FirebaseAuth

class SignupViewController: UIViewController {

    @IBOutlet weak var IDTextField: UITextField!
    @IBOutlet weak var PWTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    @IBAction func confirm(_ sender: UIButton) {
        if let id = IDTextField.text, let passwd = PWTextField.text{
            let email = id + "@test.app"

            Auth.auth().createUser(withEmail: email, password: passwd) { result, error in
                if let error = error{
                    print("Reg Error: \(error)")
                    return
                }
                print("Reg Success")
                self.presentingViewController?.dismiss(animated: true)
            }
        }
    }
    
    @IBAction func gotoBack(_ sender: UIButton) {
        self.presentingViewController?.dismiss(animated: true)
    }
}
