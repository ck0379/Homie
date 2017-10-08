// COMP90018 Mobile Computing Assgnment2
// IOS Mobile APP: Homie  - Become your safe companions on your way.
// Group Member:
// 732329 Jinghan Liang
// 732355 Zhen Jia
// 764696 Renyi Hou
//
//  Created by group:homie on 2017/9/20.
//  Copyright © 2017 group:Homie. All rights reserved.

//MonitorViewController.swift
//This is the board for whom aiming to monitor friend's location (to become the friend's companion) only if receiving the friend's msg with the friend's username and access code. Friend's location will be refreshed every 5 secs. On the map, it also shows the real-time location, the rest distance and time to destination

import UIKit
import GoogleMaps
import GooglePlaces
import SwiftyJSON
import Alamofire
import MessageUI
import AudioToolbox



class MonitorViewController: UIViewController, GMSMapViewDelegate,CLLocationManagerDelegate{
    
    //**************************************************************//
    //******************Variables Declaration***********************//
    //**************************************************************//
    
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var userNameText: UITextField!
    @IBOutlet weak var arriveTime: UITextField!
    @IBOutlet weak var transMode: UITextField!
    @IBOutlet weak var distance: UITextField!
    @IBOutlet weak var googleMaps: GMSMapView!
    @IBOutlet weak var loadingWait: UIActivityIndicatorView!
    @IBOutlet weak var nameInput: UITextField!
    
    @IBOutlet weak var callBtn: UIButton!

    @IBOutlet weak var watchLoginView: UIView!
    
    var distanceRest:String?
    var arriveTimeRest:String?
    var friendLocation = CLLocation()
    var userID = ""
    var userName = ""
    var friPhoNum = ""
    var locationStart = CLLocation()
    var locationEnd = CLLocation()
    var travelModes = "driving"
    var friendMarker = GMSMarker()
    
    let client = MSClient(applicationURLString: "https://homie.azurewebsites.net")
    var table : MSTable!
    
    //***************************************************************//
    //************************** Load View *************************//
    //**************************************************************//

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(watchLoginView)
        googleMaps.isHidden = true
    }
    
    //***************************************************************//
    //********************* Watching View Load **********************//
    //**************************************************************//
    @IBAction func enterBtn(_ sender: UIButton) {
        
        watchLoginView.isHidden = true
        watchLoginView.endEditing(true)
        googleMaps.isHidden = false
        userID = nameInput.text!
        loadingWait.startAnimating()
        var timer : Timer!
        table = client.table(withName: "user_location")
        
        //obtain the friend's start and end place
        let query = table.query(with: NSPredicate(format: "id == \(userID)"))
        query.read(completion: {(result, error) in
            if let err = error {
                print("ERROR ", err)
            } else if let items = result?.items {
                for item in items {
                    
                    self.userName = (item["user_name"] as? String)!
                    //setup the "you are watching at:"
                    self.userNameText.text?.append(self.userName)
                    self.friPhoNum = String((item["user_phoneNum"])! as! Int)
                    self.travelModes = (item["tra_mode"] as? String)!
                    //setup the traveling modes: car, bus, walk, cycling
                    self.transMode.text = self.travelModes
                    
                    let ori_lat = Double(item["ori_lat"]as! String)
                    let ori_long = Double(item["ori_long"]as!  String)
                    let des_lat = Double(item["des_lat"]as!  String)
                    let des_long = Double(item["des_long"]as!  String)
                    self.locationStart = CLLocation(latitude: ori_lat!, longitude: ori_long!)
                    self.locationEnd = CLLocation(latitude: des_lat!, longitude: des_long!)
                    
                    //creat map marker
                    self.createMarker(titleMarker: "Start", iconMarker: #imageLiteral(resourceName: "pinkpin") , latitude: self.locationStart.coordinate.latitude, longitude:self.locationStart.coordinate.longitude)
                    self.createMarker(titleMarker: "End", iconMarker: #imageLiteral(resourceName: "greenpin"), latitude: self.locationEnd.coordinate.latitude, longitude:self.locationEnd.coordinate.longitude)
                    
                    //paint the route plan
                    self.drawPath(startLocation: self.locationStart, endLocation: self.locationEnd, routeColor: UIColor.red, travelMode: self.travelModes)
                    
                    //resize the map to fit the route
                    let bounds = GMSCoordinateBounds(coordinate: self.locationStart.coordinate, coordinate: self.locationEnd.coordinate)
                    self.googleMaps.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 30.0))
                }
            }})
        callBtn.setImage(#imageLiteral(resourceName: "call"), for: UIControlState.normal)
        
        googleMaps.addSubview(infoView)
        //timer starts, every 5 seconds send a request to obtation the user's location
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector:#selector(updateFriendLocation), userInfo: nil, repeats: true)
        loadingWait.stopAnimating()
    }

    // update the friend's location every 5 secs.
    @objc func updateFriendLocation(){
        
        friendMarker.map = nil
        //obtain the friend's real-time location
        table = client.table(withName: "user_location")
        let query = table.query(with: NSPredicate(format: "id == \(userID)"))
        query.read(completion: {(result, error) in
            if let err = error {
                print("ERROR ", err)
            } else if let items = result?.items {
                for item in items {
                    let curr_lat = Double(item["user_latitude"]as! String)
                    let curr_long = Double(item["user_longitude"]as!  String)
                    self.friendLocation = CLLocation(latitude: curr_lat!, longitude: curr_long!)
                    self.friendMarker.position = CLLocationCoordinate2DMake(curr_lat!, curr_long!)
                    self.friendMarker.title = "Your friend's location:"
                    self.friendMarker.icon = #imageLiteral(resourceName: "friendpin")
                    self.friendMarker.map = self.googleMaps
                    self.drawPath(startLocation: self.locationStart, endLocation: self.friendLocation, routeColor: UIColor.lightGray, travelMode: self.travelModes)
                    // request rest time and distance
                    self.timeAndDistanceRequest(startLocation: self.friendLocation, endLocation: self.locationEnd,travelMode: self.travelModes)
                }
            }})
        
        print("finish updating!!!!")
    }
    
    // "call" button to call the friend
    @IBAction func callFriend(_ sender: UIButton) {
        let urlString = "telprompt://\(friPhoNum)"
        if let url = URL(string: urlString) {
            //process based on different IOS version
            if #available(iOS 10, *) {
                UIApplication.shared.open(url, options: [:],
                                          completionHandler: {
                                            (success) in
                })
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    //************************************************************************//
    //**************************** Map Controller ****************************//
    //************************************************************************//
    
    // MARK: - GMSMapViewDelegate
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        googleMaps.isMyLocationEnabled = true
    }
    
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        googleMaps.isMyLocationEnabled = true
        
        if (gesture) {
            mapView.selectedMarker = nil
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        googleMaps.isMyLocationEnabled = true
        return false
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        print("COORDINATE \(coordinate)") // when you tapped coordinate
    }
    
    func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
        googleMaps.isMyLocationEnabled = true
        googleMaps.selectedMarker = nil
        return false
    }
    
    
    // MARK: function for create a marker pin on map
    func createMarker(titleMarker: String, iconMarker: UIImage, latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(latitude, longitude)
        marker.title = titleMarker
        marker.icon = iconMarker
        marker.map = googleMaps
    }
    
    // MARK: - function for create direction path, from start location to desination location
    func drawPath(startLocation: CLLocation, endLocation: CLLocation, routeColor:UIColor, travelMode:String)
    {
        let origin = "\(startLocation.coordinate.latitude),\(startLocation.coordinate.longitude)"
        let destination = "\(endLocation.coordinate.latitude),\(endLocation.coordinate.longitude)"
        
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=\(travelMode)"
        
        Alamofire.request(url).responseJSON { response in
            
            print(response.request as Any)  // original URL request
            print(response.response as Any) // HTTP URL response
            print(response.data as Any)     // server data
            print(response.result as Any)   // result of response serialization
            
            let json = JSON(data: response.data!)
            let routes = json["routes"].arrayValue
            
            // print route using Polyline
            for route in routes
            {
                let routeOverviewPolyline = route["overview_polyline"].dictionary
                let points = routeOverviewPolyline?["points"]?.stringValue
                let path = GMSPath.init(fromEncodedPath: points!)
                let polyline = GMSPolyline.init(path: path)
                polyline.strokeWidth = 6
                polyline.strokeColor = routeColor
                
                polyline.map = self.googleMaps
            }
            
        }
    }
    
    func timeAndDistanceRequest(startLocation: CLLocation, endLocation: CLLocation,travelMode:String){
        let origin = "\(startLocation.coordinate.latitude),\(startLocation.coordinate.longitude)"
        let destination = "\(endLocation.coordinate.latitude),\(endLocation.coordinate.longitude)"
        
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=\(travelMode)"
        
        Alamofire.request(url).responseJSON { response in
            
            print(response.request as Any)  // original URL request
            print(response.response as Any) // HTTP URL response
            print(response.data as Any)     // server data
            print(response.result as Any)   // result of response serialization
            
            let json = JSON(data: response.data!)
            let routes = json["routes"].arrayValue
            
            //obtain the travelling duration and distance based on different traveling modes
            for route in routes
            {
                let legs = route["legs"].arrayValue
                for leg in legs
                {
                    self.arriveTimeRest = leg["duration"].dictionary?["text"]?.stringValue
                    self.distanceRest = leg["distance"].dictionary?["text"]?.stringValue
                }
            }
            self.arriveTime.text? = self.arriveTimeRest!
            self.distance.text? = self.distanceRest!
        }
    }
}
