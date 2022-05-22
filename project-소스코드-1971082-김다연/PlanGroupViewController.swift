//
//  ViewController.swift
//  ch09-1971082-tableView
//
//  Created by 김다연 on 2022/04/20.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage

class PlanGroupViewController: UIViewController {
    
    var availableYear: [Int] = []
    var allMonth: [Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    var selectedStartYear = 0
    var selectedStartMonth = 0
    var selectedEndYear = 0
    var selectedEndMonth = 0
    var todayYear = "0"
    var todayMonth = "0"

    @IBOutlet weak var planGroupTableView: UITableView!
    @IBOutlet weak var addPlanBtn: UIButton!
    
    @IBOutlet weak var addPlanTrailing: NSLayoutConstraint!
    @IBOutlet weak var addPlanBottom: NSLayoutConstraint!
    
    var datePicker = UIPickerView()
    @IBOutlet weak var dateTextField: UITextField!
    
    var planGroup: PlanGroup!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addPlanBtnCustom()
        barButtonCustom()
        configureDatePicker()
        
        planGroupTableView.dataSource = self        // 테이블뷰의 데이터 소스로 등록
        planGroupTableView.delegate = self        // 딜리게이터로 등록

        // 단순히 planGroup객체만 생성한다
        planGroup = PlanGroup(parentNotification: receivingNotification)
        
        // datePicker를 위한 tap gesture 설정
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        // tableViewCell의 tap을 무시하지 않도록 설정
        tap.cancelsTouchesInView = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let startdate = stringToDate(string:"\(selectedStartYear)년 \(selectedStartMonth)월 1일")
        let enddate = stringToDate(string: "\(selectedEndYear)년 \(selectedEndMonth)월 1일")
        print("****************************")
        print(startdate)
        print(enddate)
        planGroup.queryPlan(from: startdate!, to:enddate!)
    }
    
    @objc func dismissKeyboard(sender:UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    @objc func logout(){
        do {
            try Auth.auth().signOut()
            let login = UIStoryboard.init(name: "Login", bundle: nil)
            guard let loginController = login.instantiateViewController(withIdentifier: "LoginController")as? LoginViewController else {return}
            loginController.modalPresentationStyle = .fullScreen
            self.present(loginController, animated: false, completion: nil)
        }
        catch {
            print(error)
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
    func addPlanBtnCustom() {
        // btnCustom
        addPlanBtn.layer.shadowColor = UIColor.black.cgColor // 색깔
        addPlanBtn.layer.masksToBounds = false  // 내부에 속한 요소들이 UIView 밖을 벗어날 때, 잘라낼 것인지. 그림자는 밖에 그려지는 것이므로 false 로 설정
        addPlanBtn.layer.shadowOffset = CGSize(width: 0, height: 4) // 위치조정
        addPlanBtn.layer.shadowRadius = 3 // 반경
        addPlanBtn.layer.shadowOpacity = 0.3 // alpha값
        
        let width = UIScreen.main.bounds.size.width
        addPlanBottom.constant = width * 0.1
        addPlanTrailing.constant = width * 0.1
        self.view.bringSubviewToFront(addPlanBtn)
    }

    // logoutBtn custom
    func barButtonCustom() {
        // title 왼쪽
        let titleLabel = UILabel()
        titleLabel.textColor = .black
        titleLabel.text = "Moment List"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: titleLabel)
        
        // barbutton에 이미지 넣기
        let logoutBtn = UIButton()
        logoutBtn.setImage(UIImage(named: "logout.png")?.resizeImage(size: CGSize(width: 4, height: 15)), for: .normal)
        let attribute = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10)]
        logoutBtn.addTarget(self, action: #selector(logout), for: .touchUpInside)
        let rightBarButtonItem = UIBarButtonItem(customView: logoutBtn)
        navigationItem.rightBarButtonItem = rightBarButtonItem
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
                (cell?.contentView.subviews[0] as! UIImageView).image = UIImage(named: "logo.png")
            }
            else {
                let item = result!.items[safe: 0]
                if item != nil {
                    item!.getData(maxSize: 1*1024*1024) { [self] data, error in
                        if let error = error {
                            print(error)
                            (cell?.contentView.subviews[0] as! UIImageView).image = UIImage(named: "logo.png")
                        }
                        else {
                            (cell?.contentView.subviews[0] as! UIImageView).image = UIImage(data: data!)!
                        }
                    }
                }
                else {
                    (cell?.contentView.subviews[0] as! UIImageView).image = UIImage(named: "logo.png")
                }
            }
        }
        
        
        (cell?.contentView.subviews[1] as! UILabel).text = plan.name
        (cell?.contentView.subviews[2] as! UILabel).text = plan.owner
        (cell?.contentView.subviews[4] as! UILabel).text = plan.date.toStringDate()
        
        return cell!
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
            // 이 때 Firebase에 저장하고 가야 사용자가 수정해도 저장된다.
            let newPlan = Plan(date:Date(), owner: Auth.auth().currentUser!.email!.components(separatedBy: "@")[0], withData: false)
            planDetailViewController.plan = newPlan
            planGroupTableView.selectRow(at: nil, animated: true, scrollPosition: .none)
        }
    }

}

// for datePicker(pickerView) - textField
extension PlanGroupViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func configureDatePicker(){
        datePicker.delegate = self
        datePicker.dataSource = self
        datePicker.backgroundColor = .white
        dateTextField.inputView = datePicker
        dateTextField.tintColor = .clear
        
        setAvailableDate()
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 5
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0:
            return availableYear.count
        case 1:
            return allMonth.count
        case 2:
            return 1
        case 3:
            return availableYear.count
        case 4:
            return allMonth.count
        default:
            return 0
        }
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0:
            return String(availableYear[row]) + "년"
        case 1:
            return String(allMonth[row]) + "월"
        case 2:
            return "-"
        case 3:
            return String(availableYear[row]) + "년"
        case 4:
            return String(allMonth[row]) + "월"
        default:
            return ""
        }
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0:
            selectedStartYear = availableYear[row]
        case 1:
            selectedStartMonth = allMonth[row]
        case 3:
            selectedEndYear = availableYear[row]
        case 4:
            selectedEndMonth = allMonth[row]
        default:
            break
        }
        
        // 미래 연월 방지
        if (Int(todayYear) == selectedStartYear && Int(todayMonth)! < selectedStartMonth) {
            pickerView.selectRow(Int(todayMonth)!-1, inComponent: 1, animated: true)
            selectedStartMonth = Int(todayMonth)!
        }
        if (Int(todayYear) == selectedEndYear && Int(todayMonth)! < selectedEndMonth) {
            pickerView.selectRow(Int(todayMonth)!-1, inComponent: 4, animated: true)
            selectedEndMonth = Int(todayMonth)!
        }
        
        // 미래 < 과거 방지 : 년
        if (selectedStartYear > selectedEndYear) {
            pickerView.selectRow(selectedEndYear - 2000, inComponent: 0, animated: true)
            selectedStartYear = selectedEndYear
            // 월 다시 확인
            if (self.datePicker.selectedRow(inComponent: 1) > self.datePicker.selectedRow(inComponent: 4)) {
                pickerView.selectRow(selectedEndMonth - 1, inComponent: 1, animated: true)
                selectedStartMonth = selectedEndMonth
            }
        }
        
        // 미래 < 과거 방지 : 월
        if (selectedStartYear == selectedEndYear && selectedStartMonth > selectedEndMonth) {
            pickerView.selectRow(selectedEndMonth - 1, inComponent: 1, animated: true)
            selectedStartMonth = selectedEndMonth
        }
        
        dateTextField.text = "\(selectedStartYear)년 \(selectedStartMonth)월  -  \(selectedEndYear)년 \(selectedEndMonth)월"
        
        let startdate = stringToDate(string: "\(selectedStartYear)년 \(selectedStartMonth)월 1일")
        let enddate = stringToDate(string:"\(selectedEndYear)년 \(selectedEndMonth)월 1일")
        print("****************************")
        print(startdate)
        print(enddate)
        
        // queryPlan
        planGroup.queryPlan(from: startdate!, to:enddate!)
    }
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let view = UIView(frame: CGRect(x:0, y:0, width: 100, height: 60))
        let subLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 60))
        subLabel.textAlignment = .center
        subLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        switch component{
        case 0:
            subLabel.text = String(availableYear[row]) + "년"
        case 1:
            subLabel.text = String(allMonth[row]) + "월"
        case 2:
            subLabel.text = "-"
        case 3:
            subLabel.text = String(availableYear[row]) + "년"
        case 4:
            subLabel.text = String(allMonth[row]) + "월"
        default:
            subLabel.text = ""
        }
        view.addSubview(subLabel)
        return view
    }
    func setAvailableDate() {
        let formatterYear = DateFormatter()
        formatterYear.dateFormat = "yyyy"
        todayYear = formatterYear.string(from: Date())
        
        formatterYear.dateFormat="MM"
        todayMonth = formatterYear.string(from: Date())
        
        for i in 2000...Int(todayYear)! {
            availableYear.append(i)
        }
        
        selectedStartYear = Int(todayYear)!
        selectedStartMonth = Int(todayMonth)! - 2 > 0  ? Int(todayMonth)! - 2 : 1
        selectedEndYear = Int(todayYear)!
        selectedEndMonth = Int(todayMonth)!
        dateTextField.text = "\(selectedStartYear)년 \(selectedStartMonth)월  -  \(selectedEndYear)년 \(selectedEndMonth)월"
        
        // pickerView 미리 변경
        datePicker.selectRow(selectedStartYear - 2000, inComponent: 0, animated: false)
        datePicker.selectRow(selectedStartMonth - 1, inComponent: 1, animated: false)
        datePicker.selectRow(selectedEndYear - 2000, inComponent: 3, animated: false)
        datePicker.selectRow(selectedEndMonth - 1, inComponent: 4, animated: false)
    }
    
    func dateToString(date: Date) -> String! {
        let formmater = DateFormatter()
        formmater.dateFormat = "yyyy년 MM월 dd일"
        formmater.locale = Locale(identifier: "ko_KR")
        return formmater.string(from: date)
    }
    func stringToDate(string: String) -> Date! {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 MM월 dd일"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        return dateFormatter.date(from: string)
    }
}
