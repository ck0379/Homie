//
//  LoginViewController.swift
//  Homie
//
//  Created by jinghan liang on 2017/10/7.
//  Copyright © 2017年 Microsoft. All rights reserved.
//

import UIKit


class LoginViewController: UIViewController{
    
    
    //obtain the userID
    @IBOutlet weak var userName: UITextField!
    
    let client = MSClient(applicationURLString: "https://homie.azurewebsites.net")
    var table : MSTable!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func LoginPressed(_ sender: UIButton) {
        // query database for the login userID
        
        table = client.table(withName: "user_location")
        
        let query = table?.query(with: NSPredicate(format: "id == \(userName.text!)"))
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
            }})
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!)
    {
        if segue.identifier == "LoadMain" {
            let main = segue.destination as! MapViewController
            main.user_id = userName.text!
        }
    }
    
}

