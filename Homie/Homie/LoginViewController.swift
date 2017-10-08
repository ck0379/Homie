// COMP90018 Mobile Computing Assgnment2
// IOS Mobile APP: Homie  - Become your safe companions on your way.
// Group Member:
// 732329 Jinghan Liang
// 732355 Zhen Jia
// 764696 Renyi Hou
//
//  Created by group:homie on 2017/9/20.
//  Copyright © 2017 group:Homie. All rights reserved.

//LoginViewController.swift
//This is the entry point of the mobile app. It controls the login-about function. Send a query to Azure database about the typed login username and psw. Only when the result responsed successfully, mapView board (main board) will be loaded.


import UIKit


class LoginViewController: UIViewController{
    
    
    //obtain the userID
    @IBOutlet weak var userName: UITextField!
    
    @IBOutlet weak var loginWait: UIActivityIndicatorView!
    
    let client = MSClient(applicationURLString: "https://homie.azurewebsites.net")
    var table : MSTable!
    var userID = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginWait.isHidden = true
    }
    
    @IBAction func LoginPressed(_ sender: UIButton) {
        // query database for the login userID
        loginWait.startAnimating()
        loginWait.isHidden = false
        table = client.table(withName: "user_location")
        userID = self.userName.text!
        //predefined 4 items to assume other 3 are the user's friends
//        let itemToInsert1 = ["id":"jinghan","user_name": "Jinghan","user_phoneNum":"6199995555"] as [String : Any]
//        
//        self.table!.insert(itemToInsert1) {
//            (item, error) in
//            if error != nil {
//                print("Error: " + (error! as NSError).description)
//            }
//        }
//        let itemToInsert2 = ["id":"002","user_name": "Zhen","user_phoneNum":"6188888888"] as [String : Any]
//        
//        self.table!.insert(itemToInsert2) {
//            (item, error) in
//            if error != nil {
//                print("Error: " + (error! as NSError).description)
//            }
//        }
//        let itemToInsert3 = ["id":"003","user_name": "Renyi","user_phoneNum":"6100000000"] as [String : Any]
//        
//        self.table!.insert(itemToInsert3) {
//            (item, error) in
//            if error != nil {
//                print("Error: " + (error! as NSError).description)
//            }
//        }
//        let itemToInsert4 = ["id":"004","user_name": "Hao","user_phoneNum":"6177770000"] as [String : Any]
//        
//        self.table!.insert(itemToInsert4) {
//            (item, error) in
//            if error != nil {
//                print("Error: " + (error! as NSError).description)
//            }
//        }
        
        let query = table?.query(with: NSPredicate(format: "id == \(userID)"))
        query?.read(completion: {(result, error) in
            if let err = error {
                print("ERROR ", err)
            } else if let items = result?.items {
                //userID valid
                if (items.isEmpty == false) {
                    print("login success")
                    self.performSegue(withIdentifier: "LoadMain", sender: self)
                }
                //failed
                else{
                    let loginAlert = UIAlertController(title: "", message: "No user Found!Please sign up first", preferredStyle: UIAlertControllerStyle.alert)
                    let confirmAction = UIAlertAction(title: "Confirm", style: UIAlertActionStyle.cancel, handler: nil)
                    loginAlert.addAction(confirmAction)
                    self.present(loginAlert, animated: true, completion: nil)
                }
                self.loginWait.stopAnimating()
            }})
    }
    
    @IBAction func watchBtn(_ sender: UIButton) {
        self.performSegue(withIdentifier: "monitorStart", sender: self)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!)
    {
        if segue.identifier == "LoadMain" {
            let main = segue.destination as! MapViewController
            main.user_id = userName.text!
        }
        else if(segue.identifier == "monitorStart"){
            let monitor = segue.destination as! MonitorViewController
        }
    }
}

