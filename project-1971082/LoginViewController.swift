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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
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
                if let error = error{
                    print("Login Error: \(error)")
                    return
                }
                print("Login Success")
                let main = UIStoryboard.init(name: "Main", bundle: nil)
                guard let navigationController = main.instantiateViewController(withIdentifier: "Navigation Controller")as? UINavigationController else {return}
                        
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
        
}
