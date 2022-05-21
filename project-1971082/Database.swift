//
//  Database.swift
//  ch09-1971082-tableView
//
//  Created by 김다연 on 2022/04/20.
//

import Foundation


enum DbAction{
    case Add, Delete, Modify
}
protocol Database{
    init(parentNotification: ((Plan?, DbAction?) -> Void)?)
    func queryPlan()
    func saveChange(plan: Plan, action: DbAction)
}
