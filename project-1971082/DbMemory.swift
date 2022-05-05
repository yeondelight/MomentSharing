//
//  DbMemory.swift
//  ch09-1971082-tableView
//
//  Created by 김다연 on 2022/04/20.
//

import Foundation

class DbMemory: Database {
    private var storage: [Plan]
    
    var parentNotification: ((Plan?, DbAction?) -> Void)?
    
    required init(parentNotification: ((Plan?, DbAction?) -> Void)?) {
        self.parentNotification = parentNotification
        storage = []
        
        let amount = 1
        for _ in 0...amount{
            let delta = Int(arc4random_uniform(UInt32(amount))) - amount/2
            let date = Date(timeInterval: TimeInterval(delta*24*60*60), since: Date())
            storage.append(Plan(date: date, withData: true))
        }
    }
}


extension DbMemory{    // DbMemory.swift
    // 이 함수는 fromDate~toDate사이의 플랜을 찾아서 리턴한다.
    // 재미있는 것은 찾아서 전부 한거번에 리턴하는 것이 아니라
    // parentNotification에게 한번에 1개씩 전해준다
    func queryPlan(fromDate: Date, toDate: Date) {
        
        for i in 0..<storage.count{
            if storage[i].date >= fromDate && storage[i].date <= toDate{
                if let parentNotification = parentNotification{
        parentNotification(storage[i], .Add) // 한개씩 여러번 전달한다
                }
            }
        }
    }
    
    func saveChange(plan: Plan, action: DbAction) {
        if action == .Add{
            storage.append(plan)
        } else {
            for i in 0..<storage.count{
                if plan.key == storage[i].key{
                    if action == .Delete{
                        storage.remove(at: i)
                    }
                    if action == .Modify {
                        storage[i] = plan
                    }
                    break
                }
            }
        }
        if let parentNotification = parentNotification{
            parentNotification(plan, action)
        }
    }
}
