//
//  AlbumDetailViewController.swift
//  ch13-1971082-AlbumWithMemo
//
//  Created by 김다연 on 2022/05/04.
//

import UIKit

class AlbumDetailViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var emotionPickerView: UIPickerView!
    @IBOutlet weak var stackView: UIStackView!
    
    var emotionLists = ["😫", "☹️", "😐", "😊", "🥰"]
    
    var image: UIImage? { // 이미지 객체를 전달받는 변수임
        didSet {     // image값이 변경되면 항상 함수 didSet가 호출된다
            if let imageView = imageView{  // imageView가 만들어지기 전에 호출 될수도 있다
                imageView.image = image
            }
        }
    }

    var emotionIdentifier: String!      // 이미지 식별자를 전달 받음
    var emotionGroup: EmotionGroup!     // 메모 그룹을 전달 받음
    var emotionIndex: Int!              // emotionGroup은 pickerView의 index들을 저장한다.

    override func viewDidLoad() {
        super.viewDidLoad()
        emotionPickerView.dataSource = self
        emotionPickerView.delegate = self
        emotionIndex = emotionGroup.getEmotionIndex(key: emotionIdentifier)
        emotionPickerView.selectRow(emotionIndex, inComponent: 0, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        emotionGroup.emotions[emotionIdentifier] = emotionPickerView.selectedRow(inComponent: 0)
        emotionGroup.saveEmotionGroup()
    }
}

extension AlbumDetailViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        let listName = emotionLists
        return listName.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        var listName = emotionLists
        //listName.sort()           // 이모지 정렬 방지! (순서 바뀜)
        return listName[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //selectorLabel.text = lists[pickerView.selectedRow(inComponent: 0)]
    }
}
