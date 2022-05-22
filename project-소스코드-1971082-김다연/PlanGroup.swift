//
//  PlanGroup.swift
//  ch09-1971082-tableView
//
//  Created by 김다연 on 2022/04/20.
//

import Foundation


class PlanGroup: NSObject{
    var plans = [Plan]()            // var plans: [Plan] = []와 동일, 퀴리를 만족하는 plan들만 저장한다.
    var fromDate, toDate: Date?     // queryPlan 함수에서 주어진다.
    var database: Database!
    var parentNotification: ((Plan?, DbAction?) -> Void)?
    
    init(parentNotification: ((Plan?, DbAction?) -> Void)? ){
        super.init()
        self.parentNotification = parentNotification
        database = DbFirebase(parentNotification: receivingNotification) // 데이터베이스 생성
    }
    func receivingNotification(plan: Plan?, action: DbAction?){
        // 데이터베이스로부터 메시지를 받고 이를 부모에게 전달한다
        if let plan = plan{
            switch(action){    // 액션에 따라 적절히 plans에 적용한다
                case .Add: addPlan(plan: plan)
                case .Modify: modifyPlan(modifiedPlan: plan)
                case .Delete: removePlan(removedPlan: plan)
                default: break
            }
        }
        if let parentNotification = parentNotification{
            parentNotification(plan, action) // 역시 부모에게 알림내용을 전달한다.
        }
    }
}

extension PlanGroup{
    func queryPlan(from: Date, to: Date){
        plans.removeAll()
        fromDate = from.firstOfMonth().firstOfWeek()
        toDate = to.lastOfMonth().lastOfWeek()
        database.queryPlan(fromDate: fromDate!, toDate: toDate!)
    }
    
    func saveChange(plan: Plan, action: DbAction){
        print("SAVECHANGE")
        database.saveChange(plan: plan, action: action)
    }
}

extension PlanGroup {
    func getPlans(date: Date? = nil) -> [Plan] {
        if let date = date {
            var planForDate: [Plan] = []
            let start = date.firstOfDay()
            let end = date.lastOfDay()
            for plan in plans{
                if plan.date >= start && plan.date <= end {
                    planForDate.append(plan)
                }
            }
            return planForDate
        }
        return plans
    }
}

extension PlanGroup{     // PlanGroup.swift
    
    private func count() -> Int{ return plans.count }
    
    func isIn(date: Date) -> Bool{
        if let from = fromDate, let to = toDate{
            return (date >= from && date <= to) ? true: false
        }
        return false
    }
    
    private func find(_ key: String) -> Int?{
        for i in 0..<plans.count{
            if key == plans[i].key{
                return i
            }
        }
        return nil
    }
}

extension PlanGroup{         // PlanGroup.swift
    private func addPlan(plan:Plan){ plans.append(plan) }
    private func modifyPlan(modifiedPlan: Plan){
        if let index = find(modifiedPlan.key){
            plans[index] = modifiedPlan
        }
    }
    private func removePlan(removedPlan: Plan){
        if let index = find(removedPlan.key){
            plans.remove(at: index)
        }
    }
    func changePlan(from: Plan, to: Plan){
        if let fromIndex = find(from.key), let toIndex = find(to.key) {
            plans[fromIndex] = to
            plans[toIndex] = from
        }
    }
}
