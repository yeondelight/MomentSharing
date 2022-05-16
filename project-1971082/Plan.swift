//
//  Plan.swift
//  ch09-1971082-tableView
//
//  Created by 김다연 on 2022/04/20.
//

import FirebaseStorage
import Foundation
import UIKit

class Plan: NSObject, NSCoding{
    var key: String
    var date: Date
    var owner: String?
    var name: String?
    var content: String?
    var album: [String: Int]
    
    init(date: Date, owner: String?, name: String?, content: String, album: [String: Int]){
        self.key=UUID().uuidString
        self.date = Date(timeInterval: 0, since: date)
        self.owner = Owner.getOwner()
        self.name = name
        self.content = content
        self.album = album
        super.init()
    }
    
    // archiving할때 호출된다
    func encode(with aCoder: NSCoder) {
        aCoder.encode(key, forKey: "key")       // 내부적으로 String의 encode가 호출된다
        aCoder.encode(date, forKey: "date")
        aCoder.encode(owner, forKey: "owner")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(content, forKey: "content")
        print("############################")
        aCoder.encode(album, forKey: "album")
        print("############################")
    }
    
    // unarchiving할때 호출된다
    required init(coder aDecoder: NSCoder) {
        key = aDecoder.decodeObject(forKey: "key") as! String? ?? "" // 내부적으로 String.init가 호출된다
        date = aDecoder.decodeObject(forKey: "date") as! Date
        owner = aDecoder.decodeObject(forKey: "owner") as? String
        name = aDecoder.decodeObject(forKey: "name") as? String
        content = aDecoder.decodeObject(forKey: "content") as! String? ?? ""
        album = aDecoder.decodeObject(forKey: "album") as! [String: Int]? ?? [:]
        super.init()
    }
}

extension Plan{
    convenience init(date:Date? = nil, withData: Bool = false){
        self.init(date:date ?? Date(), owner: "me", name: "New Album", content:"shared album with plan", album:[:])
    }
    
    func clone() -> Plan {
        let clonee = Plan()

        clonee.key = self.key    // key는 String이고 String은 struct이다. 따라서 복제가 된다
        clonee.date = Date(timeInterval: 0, since: self.date) // Date는 struct가 아니라 class이기 때문
        clonee.owner = self.owner
        clonee.name = self.name   // enum도 struct처럼 복제가 된다
        clonee.content = self.content
        clonee.album = self.album
        return clonee
    }
}
