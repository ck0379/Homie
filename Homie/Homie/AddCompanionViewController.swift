// COMP90018 Mobile Computing Assgnment2
// IOS Mobile APP: Homie  - Become your safe companions on your way.
// Group Member:
// 732329 Jinghan Liang
// 732355 Zhen Jia
// 764696 Renyi Hou
//
//  Created by group:homie on 2017/9/20.
//  Copyright © 2017 group:Homie. All rights reserved.

//AddCompanionViewController.swift
//This is the board for whom aiming to add friends as his/her companions. This board will show the user's friends list by querying the database according to user's id. After seclected, it sends messages to the selected friends. Within the msg, there is user's name and accesscode.

import UIKit
import MessageUI

protocol SelectCompanionDelegate{
    func didCompanions(companions : [String])
}

class AddCompanionViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,MFMessageComposeViewControllerDelegate{
    
    //**************************************************************//
    //******************Variables Declaration***********************//
    //**************************************************************//

    //@IBOutlet weak var showCompanions: UITableView!
    
    @IBOutlet weak var showCompanions: UITableView!
    
    var companions : [String] = []
    //store the index of selected items
    var selectedIndexs = [Int]()
    var selectedFriend : [String] = []
    var friendsPhoNum : [String] = []
    var delegate : SelectCompanionDelegate?
    
    var userID = ""
    let client = MSClient(applicationURLString: "https://homie.azurewebsites.net")

    //***************************************************************//
    //************************** Load View **************************//
    //**************************************************************//
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showCompanions.delegate = self
        showCompanions.dataSource = self
        self.view.addSubview(showCompanions)
        
        //creat a cell can be reused
        self.showCompanions.register(UITableViewCell.self,forCellReuseIdentifier: "SwiftCell")
        
        //insert friend's
//        let table_friend = client.table(withName: "friends")
        
//        let itemToInsert = ["user_id":"002","friends_id":"001"] as [String : Any]
//        let itemToInsert2 = ["user_id":"002","friends_id":"003"] as [String : Any]
//        let itemToInsert3 = ["user_id":"002","friends_id":"004"] as [String : Any]
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
                    //step2: for each friend's id, query the username to show on the cell
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
                    })
                    
                }
            }})
        
    }
    
    //***************************************************************//
    //************************* Tableview Control *******************//
    //**************************************************************//
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return companions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let identify:String = "SwiftCell"
        //reuseable cell
        let cell = tableView.dequeueReusableCell(withIdentifier: identify,
                                                 for: indexPath) as UITableViewCell
        //let cell: UITableViewCell = UITableViewCell()
        cell.textLabel?.text = companions[indexPath.row]
        
        //tick at the end of the cell
        if selectedIndexs.contains(indexPath.row) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //whether the cell has been selected before
        if let index = selectedIndexs.index(of: indexPath.row){
            selectedIndexs.remove(at: index) //cancel the tick if ticked
        }else{
            selectedIndexs.append(indexPath.row) //add the tick if unticked
        }
        
        //refresh the cell
        self.showCompanions.reloadRows(at: [indexPath], with: .automatic)
    }
    
    
    func canSendText() -> Bool{
        return MFMessageComposeViewController.canSendText()
    }
    
    //***************************************************************//
    //************************** Message Control*********************//
    //**************************************************************//
    
    func configuredMessageComposeViewController() -> MFMessageComposeViewController{
        self.friendsPhoNum = ["0426499520","0451528797"]
        let accessCode = Int(arc4random()%10000)+1
        //var query = MSQuery()
        //let table = client.table(withName: "user_location")
        let messageComposeVC = MFMessageComposeViewController()
        messageComposeVC.messageComposeDelegate = self
        messageComposeVC.recipients = self.friendsPhoNum
        messageComposeVC.body = "I invite you to be my tripHomie! Open the Homie and type my username: \(self.userID) and Access Code: \(accessCode)  You can watch my location in real-time!"
        
//        //query the phone number of selected companions
//        for friend in selectedFriend{
//            query = (table.query(with: NSPredicate(format: "id == 001")))
//            query.read(completion: {(result, error) in
//                if let err = error {
//                    print("ERROR ", err)
//                } else if let items = result?.items {
//                    for item in items {
//                        self.friendsPhoNum.append(String(item["user_phoneNum"] as! Int))
//                    }
//                    
//                }
//                print(self.friendsPhoNum)
//                messageComposeVC.messageComposeDelegate = self
//                messageComposeVC.recipients = self.friendsPhoNum
//                messageComposeVC.body = "I invite you to be my tripHomie! Open the Homie and type my user_name \(self.userID) You can watch my location in real-time!"
//            })
//        }
        return messageComposeVC
        
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: {
            if((self.delegate) != nil){
            self.dismiss(animated: true, completion: nil)
            self.delegate?.didCompanions(companions: self.selectedFriend)
            }
})
    }
    
    //***************************************************************//
    //************************* Save Companions *********************//
    //**************************************************************//
    
    // save the selected friends.
    @IBAction func saveBtn(_ sender: Any) {
        for index in selectedIndexs {
            selectedFriend.append("\(self.companions[index])")
        }
        if self.canSendText(){
            let messageVC = self.configuredMessageComposeViewController()
            present(messageVC, animated: true, completion: nil)
        } else {
            let errorAlert = UIAlertView(title: "Failed:", message: "your device don't have message function", delegate: self, cancelButtonTitle: "cancel")
            errorAlert.show()
        }
        
    }
    
    @IBAction func cancelBtn(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
