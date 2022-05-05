//
//  Plan.swift
//  ch09-1971082-tableView
//
//  Created by 김다연 on 2022/04/20.
//

import Foundation

class Plan: NSObject /*, NS Coding*/{
    var key: String
    var date: Date
    var owner: String?
    var name: String?
    var content: String?
    
    init(date: Date, owner: String?, name: String?, content: String){
        self.key=UUID().uuidString
        self.date = Date(timeInterval: 0, since: date)
        self.owner = Owner.getOwner()
        self.name = name
        self.content = content
        super.init()
    }
    
}

extension Plan{
    convenience init(date:Date? = nil, withData: Bool = false){
        self.init(date:date ?? Date(), owner: "me", name: "New Album", content:"shared album with plan")
    }

    func clone() -> Plan {
        let clonee = Plan()

        clonee.key = self.key    // key는 String이고 String은 struct이다. 따라서 복제가 된다
        clonee.date = Date(timeInterval: 0, since: self.date) // Date는 struct가 아니라 class이기 때문
        clonee.owner = self.owner
        clonee.name = self.name   // enum도 struct처럼 복제가 된다
        clonee.content = self.content
        return clonee
    }
}
