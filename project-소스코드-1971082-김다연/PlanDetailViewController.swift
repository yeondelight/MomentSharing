//
//  PlanDetailViewController.swift
//  ch10-1971082-stackView
//
//  Created by 김다연 on 2022/04/28.
//

import UIKit

import Photos
import PhotosUI
import Firebase
import FirebaseAuth
import FirebaseStorage

class PlanDetailViewController: UIViewController{

    @IBOutlet weak var planName: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var contentTextField: UITextField!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var saveBtn: UIButton!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    let fireStoreID: String = "gs://iostermproject-a0b92.appspot.com/"
    
    private let datePicker = UIDatePicker()
    var planDate: Date!
    
    var plan: Plan? // 나중에 PlanGroupViewController로부터 데이터를 전달받는다
    var saveChangeDelegate: ((Plan)-> Void)?
    
    var storage = Storage.storage()
    var refList: [StorageReference] =  []
    
    var emotionLists = ["😫", "☹️", "😐", "😊", "🥰"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = UIColor(displayP3Red: 255/255, green: 111/255, blue: 97/255, alpha: 1)
        
        // 앨범 소유자가 아닌 경우 앨범 정보 변경이 불가능하다.
        // 사진에 대한 표현은 바꿀 수 있으며, 사진 또한 추가할 수 있다.
        if plan?.owner != Auth.auth().currentUser!.email!.components(separatedBy: "@")[0] {
            planName.isUserInteractionEnabled = false
            dateTextField.isUserInteractionEnabled = false
            contentTextField.isUserInteractionEnabled = false
            deleteBtn.isHidden = true
            saveBtn.isHidden = true
        }
        
        // Do any additional setup after loading the view.
        // firebase에서 모든 plan을 가져온다.
        // group을 배열에 저장해둬야할듯
        plan = plan ?? Plan(date: Date(), withData: true)
        planName.text = plan?.name
        planDate = plan?.date ?? Date()
        dateTextField.text = dateToString(date: planDate)
        ownerLabel.text = plan?.owner
        contentTextField.text = plan?.content
        
        navigationItem.title = ""
        
        setFlowLayout() // 한줄에 사진 3개씩만 보이도록
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        // dateTextField에서 datePicker가 나오도록
        configureDatePicker()
        
        // Keyboard를 위한 tap gesture 설정
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        // keyboard listener가 collectionViewCell의 tap을 무시하지 않도록 설정
        tap.cancelsTouchesInView = false
    }

    override func viewDidAppear(_ animated: Bool){
        // plan의 key를 이용해 해당 폴더 내의 이미지들을 가져와 imgList에 저장한다.
        refList = []
        let ref = storage.reference().child(plan!.key);
        ref.listAll { (result, error) in
            if let error = error {
                print(error)
            }
            else {
                for item in result!.items {
                    self.refList.append(item)
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    @objc func dismissKeyboard(sender:UITapGestureRecognizer) {
        // collectionViewCell과 충돌하지 않기 위해 코드 수정
        //contentTextField.resignFirstResponder()
        view.endEditing(true)
    }
    
    // deleteBtn
    @IBAction func deletePlan(_ sender: Any) {
        let title = "\(planName.text!)을 삭제할까요?"
        let message = "모든 사용자에게서 이 앨범이 삭제됩니다."

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Confirm", style: .destructive, handler: { [self] (action:UIAlertAction) -> Void in
            let pgvc = self.navigationController?.children[0] as! PlanGroupViewController
            pgvc.planGroup.saveChange(plan: plan!, action: .Delete)
            self.navigationController?.popViewController(animated: true)
        })
        
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        return present(alertController, animated: true)
    }
    
    // saveBtn
    @IBAction func gotoBack(_ sender: UIButton) {
        if let saveChangeDelegate = saveChangeDelegate{
            plan!.name = planName.text
            plan!.date = planDate!
            plan!.owner = ownerLabel.text
            plan!.content = contentTextField.text
            saveChangeDelegate(plan!)
        }
        navigationController?.popViewController(animated: true)
    }
}

// for album
extension PlanDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // 사진의 갯수를 리턴한다.
        return refList.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionViewCell", for:  indexPath) as! ImageCollectionViewCell
        // refList를 바탕으로 이미지를 가져온다.
        refList[indexPath.row].getData(maxSize: 1*1024*1024) { [self] data, error in
            if let error = error {
                print(error)
                cell.imageView.image = nil
            }
            else {
                cell.imageView.image = UIImage(data: data!)!
            }
        }
        
        let url = refList[indexPath.row].downloadURL(){ url, error in
            if let error = error {
                print(error)
            }
            else {
                let albumKey = self.fireStoreID + url!.absoluteString.components(separatedBy: ".com/o/")[1].components(separatedBy: "?alt=")[0].replacingOccurrences(of: "%2F", with: "/")
                
                let index = try? self.plan?.album[albumKey]
                cell.emotion.text = self.emotionLists[index ?? 2]
                print("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&")
                print(index, cell.emotion.text)
                
            }
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            // CollectionView에 하나의 이미지의 크기를 리턴한다.
            // indexPath에 따라 크리를 조정하는 것도 가능하다.
        return CGSize(width: 90, height: 90)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 이 이미지를 클릭하면 자세히 보기로 전이한다. Send가 self가 아니고 클릭된 Cell의 indexPath이다.
        print("is clicked.")
        performSegue(withIdentifier: "album", sender: indexPath)
    }
    
    func setFlowLayout(){
        let flowLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 1
        flowLayout.minimumInteritemSpacing = 1
        let myWidth: CGFloat = self.collectionView.frame.width / 3
        flowLayout.itemSize = CGSize(width: myWidth, height: myWidth)
        self.collectionView.collectionViewLayout = flowLayout
    }
}

// for album segue
extension PlanDetailViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "album" {
            let albumDetailViewController = segue.destination as! AlbumDetailViewController

            // 이미지에 대한 정보를 가져온다
            let indexPath = sender as! IndexPath    // sender이 indexPath이다.
            var image: UIImage!
            var emotionIndex: Int!
            
            refList[indexPath.row].getData(maxSize: 1*1024*1024) { [self] data, error in
                if let error = error {
                    print(error)
                    image = nil
                }
                else {
                    image = UIImage(data: data!)!
                    
                    let url = refList[indexPath.row].downloadURL(){ url, error in
                        if let error = error {
                            print(error)
                        }
                        else {
                            let albumKey = self.fireStoreID + url!.absoluteString.components(separatedBy: ".com/o/")[1].components(separatedBy: "?alt=")[0].replacingOccurrences(of: "%2F", with: "/")
                            emotionIndex = try? self.plan?.album[albumKey]
                            print(emotionIndex)
                            albumDetailViewController.key = albumKey                // for return
                            albumDetailViewController.image = image                 // albumDetailViewController의 이미지 변경
                            albumDetailViewController.emotionIndex = emotionIndex ?? 2   // albumDetailViewController의 emotion 변경
                        }
                    }
                }
            }
        }
    }
    
    // AlbumDetailViewController로부터 emotionIndex 얻기
    @IBAction func unwind(sender: UIStoryboardSegue) {
        if let albumDetailViewController = sender.source as? AlbumDetailViewController {
            let key = albumDetailViewController.key
            let index = albumDetailViewController.emotionPickerView.selectedRow(inComponent: 0)
            plan?.album[key!] = index
            self.saveChangeDelegate?(self.plan!)
        }
    }

}

// for save btn
extension PlanDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    // local album에서 사진 가져와 저장
    @IBAction func addPhoto(_ sender: UIButton) {
        let pickerViewController = UIImagePickerController()
        pickerViewController.sourceType = .photoLibrary
        pickerViewController.delegate = self
        present(pickerViewController, animated: true, completion: nil)
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // 이미지를 가져온다
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        picker.dismiss(animated: true, completion: nil)

        // 앨범에 저장을 요청하면서 저장 완료에 대한 handler를 제공한다
        var data = Data()
        data = image.jpegData(compressionQuality: 0.8)!
        let metaData = StorageMetadata()
        metaData.contentType = "image/png"
        if let filePath = plan?.key {
            let fileName = "/"+random(15)+".png"
            storage.reference().child(filePath+fileName).putData(data, metadata: metaData){
                (metaData, error) in if let error = error {
                    print(error)
                    return
                }else{
                    let albumKey = self.fireStoreID + filePath + fileName
                    let storageRef = self.storage.reference(forURL: albumKey)
                    self.plan!.album[albumKey] = 2
                    self.saveChangeDelegate?(self.plan!)
                    self.afterSaveImage(image)
                }
            }
        }
    }
    
    func afterSaveImage(_ image: UIImage) {
        // plan의 key를 이용해 해당 폴더 내의 이미지들을 가져와 imgList에 저장한다.
        refList = []
        let ref = storage.reference().child(plan!.key);
        ref.listAll { (result, error) in
            if let error = error {
                print(error)
            }
            else {
                for item in result!.items {
                    self.refList.append(item)
                    self.collectionView.reloadData()
                }
            }
        }
    }
}

// for datePicker - textField
extension PlanDetailViewController {
    func configureDatePicker(){
        self.datePicker.datePickerMode = .date
        self.datePicker.preferredDatePickerStyle = .wheels
        self.datePicker.backgroundColor = .white
        self.datePicker.setDate(plan!.date, animated: false)
        self.datePicker.addTarget(self, action: #selector(datePickerValueDidChanged(_:)), for: .valueChanged)
        self.dateTextField.inputView = self.datePicker
        self.dateTextField.tintColor = .clear
    }
    @objc func datePickerValueDidChanged(_ datePicker: UIDatePicker){
        let formmater = DateFormatter()
        formmater.dateFormat = "yyyy년 MM월 dd일"
        formmater.locale = Locale(identifier: "ko_KR")
        self.planDate = datePicker.date
        self.datePicker.locale = Locale(identifier: "ko-KR")
        self.dateTextField.text = formmater.string(from: datePicker.date)
        planDate = datePicker.date
    }
    func dateToString(date: Date) -> String! {
        let formmater = DateFormatter()
        formmater.dateFormat = "yyyy년 MM월 dd일"
        formmater.locale = Locale(identifier: "ko_KR")
        return formmater.string(from: date)
    }
    func stringToDate(string: String) -> Date! {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 MM월 dd일"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        return dateFormatter.date(from: string)
    }
}


extension PlanDetailViewController {
    // for file hash
    func random(_ n: Int) -> String {
        let a = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
        var s = ""
        for _ in 0..<n {
            let r = Int(arc4random_uniform(UInt32(a.count)))
            s += String(a[a.index(a.startIndex, offsetBy: r)])
        }
        return s
    }
}
