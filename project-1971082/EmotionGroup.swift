//
//  MemoGroup.swift
//  ch13-1971082-AlbumWithMemo
//
//  Created by 김다연 on 2022/05/04.
//

import UIKit
import Foundation

class EmotionGroup{
    
    let emotionUrl: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    var emotions: [String: Int]!
    
    init(){
        let photoEmotionsDir = emotionUrl.appendingPathComponent("Photos/emotionIndex")
        try? FileManager.default.createDirectory(atPath: photoEmotionsDir.path, withIntermediateDirectories: true, attributes: nil)
        
        emotions = [:]
        let unarchived = try? Data(contentsOf: photoEmotionsDir.appendingPathComponent("emotions.archive"))//읽어온다
        if let unarchived = unarchived{
            emotions = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(unarchived) as? [String: Int] // 복원한다
        }
    }
    
    func saveEmotionGroup(){
        guard let emotions = emotions else{ return }
        let photoEmotionsDir = emotionUrl.appendingPathComponent("Photos/emotionIndex")
        try? FileManager.default.createDirectory(atPath: photoEmotionsDir.path, withIntermediateDirectories: true, attributes: nil)
        let archived = try? NSKeyedArchiver.archivedData(withRootObject: emotions, requiringSecureCoding: false) // 압축한다
        try? archived?.write(to: photoEmotionsDir.appendingPathComponent("emotions.archive")) // 저장한다
    }
    
    func getEmotionIndex(key: String) -> Int?{
        return emotions?[key]
    }
    
    func putEmotion(key: String, emotionIndex: Int){
        emotions?[key] = emotionIndex
    }
}
