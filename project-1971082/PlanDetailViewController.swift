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
import FirebaseStorage

class PlanDetailViewController: UIViewController{

    @IBOutlet weak var planName: UITextField!
    @IBOutlet weak var dateDatePicker: UIDatePicker!
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var contentTextField: UITextField!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var plan: Plan? // 나중에 PlanGroupViewController로부터 데이터를 전달받는다
    var saveChangeDelegate: ((Plan)-> Void)?
    
    var storage = Storage.storage()
    var imgList: [UIImage] = []
    var imgEmotion: [UIImage: Int] = [:]
    
    var fetchResult: PHFetchResult<PHAsset>!    // 사진에 대한 메타 데이터 저장
    var emotionGroup = EmotionGroup()              // 메모들을 읽어온다
    var emotionLists = ["😫", "☹️", "😐", "😊", "🥰"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        // firebase에서 모든 plan을 가져온다.
        // group을 배열에 저장해둬야할듯
        plan = plan ?? Plan(date: Date(), withData: true)
        planName.text = plan?.name
        dateDatePicker.date = plan?.date ?? Date()
        ownerLabel.text = plan?.owner
        contentTextField.text = plan?.content
        
        navigationItem.title = plan?.name
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        // Keyboard를 위한 tap gesture 설정
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        // keyboard listener가 collectionViewCell의 tap을 무시하지 않도록 설정
        tap.cancelsTouchesInView = false
    }

    override func viewDidAppear(_ animated: Bool){
        // plan의 key를 이용해 해당 폴더 내의 이미지들을 가져와 imgList에 저장한다.
        imgList = []
        imgEmotion = [:]
        let ref = storage.reference().child(plan!.key);
        ref.listAll { (result, error) in
            if let error = error {
                print(error)
            }
            else {
                for item in result!.items {
                    item.getData(maxSize: 1*1024*1024) { [self] data, error in
                        if let error = error {
                            print(error)
                        }
                        else {
                            self.imgList.append(UIImage(data: data!)!)
                            self.imgEmotion[UIImage(data: data!)!] = self.plan?.album[item]     // emotion과 연결
                            
                            print(imgEmotion)
                        }
                        // 늦게 실행되므로 reload는 여기서 이뤄져야 함.
                        collectionView.reloadData()
                    }
                }
            }
        }
    }
    
    @objc func dismissKeyboard(sender:UITapGestureRecognizer) {
        // collectionViewCell과 충돌하지 않기 위해 코드 수정
        //contentTextField.resignFirstResponder()
        view.endEditing(true)
    }
    
    // saveBtn
    @IBAction func gotoBack(_ sender: UIButton) {
        if let saveChangeDelegate = saveChangeDelegate{
            plan!.name = planName.text
            plan!.date = dateDatePicker.date
            plan!.owner = ownerLabel.text    // 수정할 수 없는 UILabel이므로 필요없는 연산임
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
        return imgList.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionViewCell", for:  indexPath) as! ImageCollectionViewCell
        cell.imageView.image = imgList[indexPath.row]
        cell.emotion.text = emotionLists[imgEmotion[imgList[indexPath.row]] ?? 2]
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
        performSegue(withIdentifier: "ShowDetail", sender: indexPath)
    }
}

// for album segue
extension PlanDetailViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let albumDetailViewController = segue.destination as! AlbumDetailViewController

        // 이미지에 대한 정보를 가져온다
        let indexPath = sender as! IndexPath    // sender이 indexPath이다.
        let image = imgList[indexPath.row]
        print(image)
        albumDetailViewController.setImage(img: image)      // albumDetailViewController의 이미지 변경
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
                    print("Success")
                    self.afterSaveImage(image)
                }
            }
        }
    }
    
    func afterSaveImage(_ image: UIImage) {
        // plan의 key를 이용해 해당 폴더 내의 이미지들을 가져와 imgList에 저장한다.
        imgList = []
        imgEmotion = [:]
        let ref = storage.reference().child(plan!.key);
        ref.listAll { (result, error) in
            if let error = error {
                print(error)
            }
            else {
                for item in result!.items {
                    item.getData(maxSize: 1*1024*1024) { [self] data, error in
                        if let error = error {
                            print(error)
                        }
                        else {
                            self.imgList.append(UIImage(data: data!)!)
                            self.imgEmotion[UIImage(data: data!)!] = self.plan?.album[item]     // emotion과 연결
                            
                            print(imgEmotion)
                        }
                        // 늦게 실행되므로 reload는 여기서 이뤄져야 함.
                        collectionView.reloadData()
                    }
                }
            }
        }
        
        // 새로운 페이지로는... 못넘어가겠다...
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
