//
//  ViewController.swift
//  ch09-1971082-tableView
//
//  Created by 김다연 on 2022/04/20.
//

import UIKit
import Firebase
import FirebaseStorage

class PlanGroupViewController: UIViewController {

    @IBOutlet weak var planGroupTableView: UITableView!
    @IBOutlet weak var addPlanBtn: UIButton!
    
    @IBOutlet weak var addPlanTrailing: NSLayoutConstraint!
    @IBOutlet weak var addPlanBottom: NSLayoutConstraint!
    
    var planGroup: PlanGroup!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Plan List"
        
        addPlanBtnCustom()
        
        planGroupTableView.dataSource = self        // 테이블뷰의 데이터 소스로 등록
        planGroupTableView.delegate = self        // 딜리게이터로 등록

        // 단순히 planGroup객체만 생성한다
        planGroup = PlanGroup(parentNotification: receivingNotification)
        planGroup.queryPlan(date: Date())       // 이달의 데이터를 가져온다. 데이터가 오면 planGroupListener가 호출된다.
        
        let leftBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editingPlans))
        navigationItem.leftBarButtonItem = leftBarButtonItem
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // 여기서 호출하는 이유는 present라는 함수 ViewController의 함수인데 이함수는 ViewController의 Layout이 완료된 이후에만 동작하기 때문
        Owner.loadOwner(sender: self)
        
    }
    
    @IBAction func editingPlans(_ sender: UIBarButtonItem) {
        if planGroupTableView.isEditing == true{
            planGroupTableView.isEditing = false
            sender.title = "Edit"
        }else{
            planGroupTableView.isEditing = true
            sender.title = "Done"
        }

    }
    
    @IBAction func addingPlans(_ sender: UIButton) {
        performSegue(withIdentifier: "AddPlan", sender: self)
    }
    
    func receivingNotification(plan: Plan?, action: DbAction?){
        // 데이터가 올때마다 이 함수가 호출되는데 맨 처음에는 기본적으로 add라는 액션으로 데이터가 온다.
        self.planGroupTableView.reloadData()  // 속도를 증가시키기 위해 action에 따라 개별적 코딩도 가능하다.
    }

    // for addPlanBtn custom
    func addPlanBtnCustom(){
        // btnCustom
        addPlanBtn.layer.cornerRadius = addPlanBtn.layer.frame.size.width/2
        addPlanBtn.layer.shadowColor = UIColor.black.cgColor // 색깔
        addPlanBtn.layer.masksToBounds = false  // 내부에 속한 요소들이 UIView 밖을 벗어날 때, 잘라낼 것인지. 그림자는 밖에 그려지는 것이므로 false 로 설정
        addPlanBtn.layer.shadowOffset = CGSize(width: 0, height: 4) // 위치조정
        addPlanBtn.layer.shadowRadius = 3 // 반경
        addPlanBtn.layer.shadowOpacity = 0.3 // alpha값
        
        let width = UIScreen.main.bounds.size.width
        addPlanBottom.constant = width * 0.1
        addPlanTrailing.constant = width * 0.1
    }

}

extension PlanGroupViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if let planGroup = planGroup{
            return planGroup.getPlans().count
        }
        return 0    // planGroup가 생성되기전에 호출될 수도 있다
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        //let cell = UITableViewCell(style: .value1, reuseIdentifier: "") // TableViewCell을 생성한다
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlainTableViewCell")
        
        // planGroup는 대략 1개월의 플랜을 가지고 있다.
        let plan = planGroup.getPlans()[indexPath.row] // Date를 주지않으면 전체 plan을 가지고 온다
        
        // 0, 1, 2순서가 맞아야 한다. 안맞으면 스트로보드에서 다시 맞도록 위치를 바꾸어야 한다
        // Thumbnail img는 앨범에 사진이 있으면 앨범의 첫번째 사진으로,
        // 앨범에 사진이 없거나 불러올 수 없는 상태이면 defaultImg로 설정된다.
        let ref = Storage.storage().reference().child(plan.key);
        ref.listAll { (result, error) in
            if let error = error {
                print(error)
                (cell?.contentView.subviews[0] as! UIImageView).image = UIImage(named: "apple.png")
            }
            else {
                
                result!.items[0].getData(maxSize: 1*1024*1024) { [self] data, error in
                    if let error = error {
                        print(error)
                        (cell?.contentView.subviews[0] as! UIImageView).image = UIImage(named: "apple.png")
                    }
                    else {
                        (cell?.contentView.subviews[0] as! UIImageView).image = UIImage(data: data!)!
                    }
                }
            }
        }
        
        
        (cell?.contentView.subviews[1] as! UILabel).text = plan.name
        (cell?.contentView.subviews[2] as! UILabel).text = plan.owner
        (cell?.contentView.subviews[4] as! UILabel).text = plan.date.toStringDate()
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete{
            
            let plan = self.planGroup.getPlans()[indexPath.row]
            let title = "Delete \(plan.name!)"
            let message = "이 앨범에 접근할 수 있는 다른 사람에게서도 앨범이 삭제됩니다."

            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (action:UIAlertAction) -> Void in
                
                // 선택된 row의 플랜을 가져온다
                let plan = self.planGroup.getPlans()[indexPath.row]
                // 단순히 데이터베이스에 지우기만 하면된다. 그러면 꺼꾸로 데이터베이스에서 지워졌음을 알려준다
                self.planGroup.saveChange(plan: plan, action: .Delete)
            })
            
            alertController.addAction(cancelAction)
            alertController.addAction(deleteAction)
            present(alertController, animated: true, completion: nil) //여기서 waiting 하지 않는다
        }
    }
    
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        // 이것은 데이터베이스에 까지 영향을 미치지 않는다. 그래서 planGroup에서만 위치 변경
        let from = planGroup.getPlans()[sourceIndexPath.row]
        let to = planGroup.getPlans()[destinationIndexPath.row]
        planGroup.changePlan(from: from, to: to)
        tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
    }
}


extension PlanGroupViewController{

    // prepare함수에서 PlanDetailViewController에게 전달한다
    func saveChange(plan: Plan){

        // 만약 현재 planGroupTableView에서 선택된 row가 있다면,
        // 즉, planGroupTableView의 row를 클릭하여 PlanDetailViewController로 전이 한다면
        if planGroupTableView.indexPathForSelectedRow != nil{
            planGroup.saveChange(plan: plan, action: .Modify)
        }else{
            // 이경우는 나중에 사용할 것이다.
            planGroup.saveChange(plan: plan, action: .Add)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("prepare in pgc")
        if segue.identifier == "ShowPlan"{
            let planDetailViewController = segue.destination as! PlanDetailViewController
            // plan이 수정되면 이 saveChangeDelegate를 호출한다
            planDetailViewController.saveChangeDelegate = saveChange
            planDetailViewController.plan = planGroup.getPlans()[planGroupTableView.indexPathForSelectedRow!.row].clone()
        }
        if segue.identifier == "AddPlan"{
            print("AddPlan")
            let planDetailViewController = segue.destination as! PlanDetailViewController
            planDetailViewController.saveChangeDelegate = saveChange
                        
            // 빈 plan을 생성하여 전달한다
            planDetailViewController.plan = Plan(date:nil, withData: false)
            planGroupTableView.selectRow(at: nil, animated: true, scrollPosition: .none)
        }
    }

}
