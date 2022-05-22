//
//  LoginViewController.swift
//  project-1971082
//
//  Created by 김다연 on 2022/05/19.
//

import UIKit
import Firebase
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBOutlet weak var IDTextField: UITextField!
    @IBOutlet weak var PWTextField: UITextField!
    @IBOutlet weak var signInBtn: UIButton!
    @IBOutlet weak var signUpBtn: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var btnStackViewConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // buttonCustom
        buttonCustom()
        errorLabel.isHidden = true
        btnStackViewConstraint.constant = 16
        
        // Keyboard를 위한 tap gesture 설정
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        // keyboard listener가 collectionViewCell의 tap을 무시하지 않도록 설정
        tap.cancelsTouchesInView = false
    }
    
    @objc func dismissKeyboard(sender:UITapGestureRecognizer) {
        // collectionViewCell과 충돌하지 않기 위해 코드 수정
        //contentTextField.resignFirstResponder()
        view.endEditing(true)
    }
    
    @IBAction func signIn(_ sender: UIButton) {
        if let id = IDTextField.text, let passwd = PWTextField.text{
            let email = id + "@test.app"

            Auth.auth().signIn(withEmail: email, password: passwd) { result, error in
                if let error = error as NSError? {
                    let errorCode = AuthErrorCode(_nsError: error)
                    switch errorCode.code {
                        case .userNotFound, .invalidEmail:
                            self.errorLabel.text = "!! 존재하지 않는 사용자입니다."
                        case .wrongPassword:
                            self.errorLabel.text = "!! 비밀번호를 다시 확인해주세요."
                            self.IDTextField.text = id
                        default:
                            self.errorLabel.text = "!! 에러가 발생했습니다. 다시 시도해주세요."
                    }
                    self.PWTextField.text = ""
                    self.errorLabel.isHidden = false
                    self.btnStackViewConstraint.constant = 40
                    return
                }
                print("Login Success")
                let main = UIStoryboard.init(name: "Main", bundle: nil)
                guard let navigationController = main.instantiateViewController(withIdentifier: "NavigationController")as? UINavigationController else {return}
                        
                navigationController.modalPresentationStyle = .fullScreen
                self.present(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func signUp(_ sender: UIButton) {
        guard let secondViewController = self.storyboard?.instantiateViewController(withIdentifier: "Signup") as? SignupViewController else { return }
        // 화면 전환 애니메이션 설정
        secondViewController.modalTransitionStyle = .crossDissolve
        // 전환된 화면이 보여지는 방법 설정 (fullScreen)
        secondViewController.modalPresentationStyle = .fullScreen
        self.present(secondViewController, animated: true, completion: nil)
    }
    
    // TextField 흔들기 애니메이션
    func shakeTextField(textField: UITextField) -> Void{
        UIView.animate(withDuration: 0.2, animations: {
            textField.frame.origin.x -= 10
        }, completion: { _ in
            UIView.animate(withDuration: 0.2, animations: {
                textField.frame.origin.x += 20
             }, completion: { _ in
                 UIView.animate(withDuration: 0.2, animations: {
                    textField.frame.origin.x -= 10
                })
            })
        })
    }
    
    func buttonCustom() {
        // btnCustom
        signInBtn.layer.cornerRadius = signInBtn.layer.frame.size.height/2
        signUpBtn.layer.cornerRadius = signUpBtn.layer.frame.size.height/2
    }
        
}
