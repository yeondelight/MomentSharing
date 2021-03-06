//
//  AlbumDetailViewController.swift
//  ch13-1971082-AlbumWithMemo
//
//  Created by κΉλ€μ° on 2022/05/04.
//

import UIKit

class AlbumDetailViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var emotionPickerView: UIPickerView!
    @IBOutlet weak var stackView: UIStackView!
    
    var key: String?
    var image: UIImage? {
        didSet {
            if let imageView = imageView{
                imageView.image = image
            }
        }
    }
    var emotionLists = ["π«", "βΉοΈ", "π", "π", "π₯°"]
    var emotionIndex: Int? {
        didSet {
            if index != nil{
                emotionPickerView.selectRow(emotionIndex!, inComponent: 0, animated: true)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = UIColor(displayP3Red: 255/255, green: 111/255, blue: 97/255, alpha: 1)
        
        imageView.image = image
        emotionPickerView.dataSource = self
        emotionPickerView.delegate = self 
        emotionPickerView.selectRow(emotionIndex ?? 2, inComponent: 0, animated: true)
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
        //listName.sort()           // μ΄λͺ¨μ§ μ λ ¬ λ°©μ§! (μμ λ°λ)
        return listName[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //selectorLabel.text = lists[pickerView.selectedRow(inComponent: 0)]
    }
}
