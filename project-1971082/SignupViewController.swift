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
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var btnConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        errorLabel.isHidden = true
        btnConstraint.constant = 16
    }
    @IBAction func confirm(_ sender: UIButton) {
        if let id = IDTextField.text, let passwd = PWTextField.text{
            let email = id + "@test.app"

            Auth.auth().createUser(withEmail: email, password: passwd) { result, error in
                if let error = error as NSError? {
                    let errorCode = AuthErrorCode(_nsError: error)
                    switch errorCode.code {
                        case .invalidEmail:
                            self.errorLabel.text = "!! ID는 영어와 숫자만 입력할 수 있습니다."
                        case .accountExistsWithDifferentCredential, .credentialAlreadyInUse, .emailAlreadyInUse:
                            self.errorLabel.text = "!! 이미 사용중인 ID입니다."
                        case .weakPassword:
                            self.errorLabel.text = "!! 6자 이상의 비밀번호를 입력해주세요."
                        default:
                            print("Create User Error: \(error)")
                    }
                    self.IDTextField.text = ""
                    self.PWTextField.text = ""
                    self.errorLabel.isHidden = false
                    self.btnConstraint.constant = 40
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
