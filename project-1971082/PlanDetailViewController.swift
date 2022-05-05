//
//  PlanDetailViewController.swift
//  ch10-1971082-stackView
//
//  Created by 김다연 on 2022/04/28.
//

import UIKit
import Photos
import PhotosUI


class PlanDetailViewController: UIViewController {


    @IBOutlet weak var planName: UITextField!
    @IBOutlet weak var dateDatePicker: UIDatePicker!
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var contentTextField: UITextField!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var plan: Plan? // 나중에 PlanGroupViewController로부터 데이터를 전달받는다
    var saveChangeDelegate: ((Plan)-> Void)?
    
    var fetchResult: PHFetchResult<PHAsset>!    // 사진에 대한 메타 데이터 저장
    var emotionGroup = EmotionGroup()              // 메모들을 읽어온다
    var emotionLists = ["😫", "☹️", "😐", "😊", "🥰"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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

    override func viewDidAppear(_ animated: Bool) {
        // 모든 사진을 다 가져온다. 일부사진만 가져오는 것은
        // https://developer.apple.com/documentation/photokit/browsing_and_modifying_photo_albums 참조
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchResult = PHAsset.fetchAssets(with: allPhotosOptions) // 모든 사진의 목록을 갖는다
        collectionView.reloadData()
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
    
    // local album에서 사진 가져와 저장
    @IBAction func addPhoto(_ sender: UIButton) {
    }
}

// for album
extension PlanDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // 사진의 갯수를 리턴한다.
        return fetchResult == nil ? 0: fetchResult.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionViewCell", for:  indexPath) as! ImageCollectionViewCell
        
        let asset = fetchResult.object(at: indexPath.row)  // 이미지에 대한 메타 데이터를 가져온다
        PHCachingImageManager.default().requestImage(for: asset, targetSize: CGSize(), contentMode: .aspectFill, options: nil){
            (image, _) in    // 요청한 이미지를 디스크로부터 읽으면 이 함수가 호출 된다.
            cell.imageView.image = image  // 여기서 이미지를 보이게 한다
            cell.emotion.text = self.emotionLists[self.emotionGroup.getEmotionIndex(key: asset.localIdentifier) ?? 2]
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
        performSegue(withIdentifier: "ShowDetail", sender: indexPath)
    }
}

// for album segue
extension PlanDetailViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("pppppppppppppppppppp")
        let albumDetailViewController = segue.destination as! AlbumDetailViewController

        // 이미지에 대한 정보를 가져온다
        let indexPath = sender as! IndexPath    // sender이 indexPath이다.
        let asset = fetchResult.object(at: indexPath.row)
        albumDetailViewController.emotionIdentifier = asset.localIdentifier  // 이미지에 대한 식별자이다.
        albumDetailViewController.emotionGroup = emotionGroup

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat // 고해상도를 가져오기 우l함임
        PHCachingImageManager.default().requestImage(for: asset, targetSize: CGSize(), contentMode: .aspectFill, options: options, resultHandler: { image, _ in
            // 한참있다가 실행된다. 즉, albumDetailViewController가 로딩되고 appear한 후에 나타난다.
            albumDetailViewController.image = image  // 앞에서 didSet을 사용한 이유이다.
        })
    }
}
