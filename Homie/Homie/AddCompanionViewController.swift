//
//  AddCompanionViewController.swift
//  Homie
//
//  Created by jinghan liang on 2017/10/8.
//  Copyright © 2017年 Microsoft. All rights reserved.
//

import UIKit

protocol SelectCompanionDelegate{
    func didCompanions(companions : [String])
}

class AddCompanionViewController: UIViewController,UITableViewDelegate,UITableViewDataSource{
    
    //**************************************************************//
    //******************Variables Declaration***********************//
    //**************************************************************//

    //@IBOutlet weak var showCompanions: UITableView!
    
    @IBOutlet weak var showCompanions: UITableView!
    
    var companions = ["jinghan","zhen","renyi"]
    //store the index of selected items
    var selectedIndexs = [Int]()
    var selectedFriend : [String] = []
    var delegate : SelectCompanionDelegate?
    
    var userID = ""
    let client = MSClient(applicationURLString: "https://homie.azurewebsites.net")
//    var table_user : MSTable!
//    var table_friend : MSTable!
    //***************************************************************//
    //************************** Load View **************************//
    //**************************************************************//
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showCompanions.delegate = self
        showCompanions.dataSource = self
        self.view.addSubview(showCompanions)
        
        //创建一个重用的单元格
        self.showCompanions.register(UITableViewCell.self,forCellReuseIdentifier: "SwiftCell")
        
//        //insert friend's
//        table_friend = client.table(withName: "friends")
//        
//        let itemToInsert = ["user_id":"\(userID)","friends_id":"002"] as [String : Any]
//        let itemToInsert2 = ["user_id":"\(userID)","friends_id":"003"] as [String : Any]
//        let itemToInsert3 = ["user_id":"\(userID)","friends_id":"004"] as [String : Any]
//        
//        table_friend.insert(itemToInsert) {
//            (item, error) in
//            if error != nil {
//                print("Error: " + (error! as NSError).description)
//            }
//        }
//        table_friend.insert(itemToInsert2) {
//            (item, error) in
//            if error != nil {
//                print("Error: " + (error! as NSError).description)
//            }
//        }
//        table_friend.insert(itemToInsert3) {
//            (item, error) in
//            if error != nil {
//                print("Error: " + (error! as NSError).description)
//            }
//        }
        
        //query the friend's of current user
        let table_user = client.table(withName: "user_location")
        let table_friend = client.table(withName: "friends")
        //var allFriends : [String] = []
        
        //var showCompanions:UITableView = UITableView(frame: UIScreen.main.bounds, style: .plain)
        //step1: query all friend's id from table "friends"
        let query = table_friend.query(with: NSPredicate(format: "user_id == \(userID)"))
        query.read(completion: {(result, error) in
            if let err = error {
                print("ERROR ", err)
            } else if let items = result?.items {
                for item in items {
                    let friendID = item["friends_id"]!
                    //allFriends.append("\(friendID)")
                    let query2 = table_user.query(with: NSPredicate(format: "id == \(friendID)"))
                    
                    query2.read(completion: {(result, error) in
                        if let err = error {
                            print("ERROR ", err)
                        } else if let items = result?.items {
                            for item in items {
                                let userName = item["user_name"]!
                                self.companions.append("\(userName)")
                                self.showCompanions.reloadData()
                            }
                            
                        }
                        print(self.companions)
                        
                        //showCompanions = UITableView(frame: UIScreen.main.bounds, style: .plain)
                    })
                    
                }
            }})
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return companions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //为了提供表格显示性能，已创建完成的单元需重复使用
        let identify:String = "SwiftCell"
        //同一形式的单元格重复使用，在声明时已注册
        let cell = tableView.dequeueReusableCell(withIdentifier: identify,
                                                 for: indexPath) as UITableViewCell
        //let cell: UITableViewCell = UITableViewCell()
        cell.textLabel?.text = companions[indexPath.row]
        
        //判断是否选中（选中单元格尾部打勾）
        if selectedIndexs.contains(indexPath.row) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //判断该行原先是否选中
        if let index = selectedIndexs.index(of: indexPath.row){
            selectedIndexs.remove(at: index) //原来选中的取消选中
        }else{
            selectedIndexs.append(indexPath.row) //原来没选中的就选中
        }
        
        ////刷新该行
        self.showCompanions.reloadRows(at: [indexPath], with: .automatic)
    }
    
    @IBAction func saveBtn(_ sender: Any) {
        
//        print("selected index：", selectedIndexs)
//        print("selected items：")
        for index in selectedIndexs {
            selectedFriend.append("\(self.companions[index])")
        }
        //print(self.selectedFriend)
        if((delegate) != nil){
            self.dismiss(animated: true, completion: nil)
            self.delegate?.didCompanions(companions: self.selectedFriend)
        }
    }
    
    @IBAction func cancelBtn(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
