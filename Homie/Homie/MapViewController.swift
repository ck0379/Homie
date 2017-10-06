// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
import UIKit
import GoogleMaps
import GooglePlaces
import SwiftyJSON
import Alamofire
import MessageUI
import AudioToolbox
import SRCountdownTimer

enum Location {
    case startLocation
    case destinationLocation
}

enum travelModes:String{
    case driving
    case walking
    case cycling
    case transit
}


class MapViewController: UIViewController, GMSMapViewDelegate,CLLocationManagerDelegate,MFMessageComposeViewControllerDelegate {
    
    //**************************************************************//
    //******************Variables Declaration***********************//
    //**************************************************************//
    
    //Map View
    @IBOutlet weak var googleMaps: GMSMapView!
    @IBOutlet weak var destinationLocation: UITextField!
    @IBOutlet weak var startLocation: UITextField!
    @IBOutlet weak var displayLabel: UILabel!
    @IBOutlet weak var start: UIButton!
    @IBOutlet weak var end: UIButton!
    @IBOutlet weak var helpView: UIView!
    
    //Alert View
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var countdownTimer: SRCountdownTimer!
    @IBOutlet weak var safetyBtn: UIButton!
    
    var locationManager = CLLocationManager()
    var locationSelected = Location.startLocation
    var travelMode = travelModes.driving.rawValue
    
    var locationStart = CLLocation()
    var locationEnd = CLLocation()
    
    //***************************************************************//
    //************************** Load View **************************//
    //**************************************************************//
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startMonitoringSignificantLocationChanges()
        
        //Map initiation code
        let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 8.0)
        self.googleMaps.camera = camera
        self.googleMaps.delegate = self
        self.googleMaps?.isMyLocationEnabled = true
        self.googleMaps.settings.myLocationButton = true
        self.googleMaps.settings.compassButton = true
        self.googleMaps.settings.zoomGestures = true
        
        start.isHidden = false //"start" button shows initially
        end.isHidden = true //"end" button hides initially
        googleMaps.addSubview(helpView)
        
        self.becomeFirstResponder() // To get shake gesture
    }
    
    
    //************************************************************************//
    //**************************** Map Controller ****************************//
    //************************************************************************//
    
    //MARK: - Location Manager delegates
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error to get location : \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last
        createMarker(titleMarker: "You are in:", iconMarker: #imageLiteral(resourceName: "mapspin") , latitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!)
        
        self.locationManager.stopUpdatingLocation()
        
    }
    
    
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
    func drawPath(startLocation: CLLocation, endLocation: CLLocation)
    {
        googleMaps.clear()
        createMarker(titleMarker: "Start", iconMarker: #imageLiteral(resourceName: "mapspin"), latitude: startLocation.coordinate.latitude, longitude:startLocation.coordinate.longitude)
        createMarker(titleMarker: "End", iconMarker: #imageLiteral(resourceName: "mapspin"), latitude: endLocation.coordinate.latitude, longitude:endLocation.coordinate.longitude)
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
                polyline.strokeColor = UIColor.red
                
            
                let bounds = GMSCoordinateBounds(coordinate: startLocation.coordinate, coordinate:endLocation.coordinate)
                let camera = self.googleMaps.camera(for: bounds, insets:UIEdgeInsets())!
                self.googleMaps.camera = camera
                
                polyline.map = self.googleMaps
                
                //obtain the travelling duration and distance based on different traveling modes
                let legs = route["legs"].arrayValue
                for leg in legs
                {
                    let duration = leg["duration"].dictionary?["text"]?.stringValue
                    let distance = leg["distance"].dictionary?["text"]?.stringValue
                    self.displayLabel.text = duration! + distance!
                }
            }
        }
    }
    
    //**********************************************************************************//
    //**************************** Map About Button Functions **************************//
    //**********************************************************************************//
    
    // Mark: select original place
    @IBAction func openStartLocation(_ sender: UIButton) {
        start.isHidden = false
        end.isHidden = true
        let autoCompleteController = GMSAutocompleteViewController()
        autoCompleteController.delegate = self
        
        // selected location
        locationSelected = .startLocation
        
        // Change text color
        UISearchBar.appearance().setTextColor(color: UIColor.black)
        self.locationManager.stopUpdatingLocation()
        
        self.present(autoCompleteController, animated: true, completion: nil)
    }
    
    // Mark: select destination
    @IBAction func openDestinationLocation(_ sender: UIButton) {
        start.isHidden = false
        end.isHidden = true
        let autoCompleteController = GMSAutocompleteViewController()
        autoCompleteController.delegate = self
        
        // selected location
        locationSelected = .destinationLocation
        
        // Change text color
        UISearchBar.appearance().setTextColor(color: UIColor.black)
        self.locationManager.stopUpdatingLocation()
        
        self.present(autoCompleteController, animated: true, completion: nil)
    }
    
    // Mark: "Start" the route direction
    @IBAction func showDirection(_ sender: UIButton) {
        // when button direction tapped, must call drawpath func
        self.drawPath(startLocation: locationStart, endLocation: locationEnd)
        start.isHidden = true;
        end.isHidden = false;
    }
    
    
    // Mark: "End" the route direction
    @IBAction func endDirection(_ sender: UIButton) {
        
        let endActionsheet = UIAlertController(title: "", message: "", preferredStyle:UIAlertControllerStyle.actionSheet)
        let cancelAction = UIAlertAction(title: "Cancle", style: UIAlertActionStyle.cancel, handler: nil)
        let endTripAction = UIAlertAction(title: "End the trip", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            self.googleMaps.clear()
            self.start.isHidden = false
            self.end.isHidden = true
            self.startLocation.text = ""
            self.destinationLocation.text = ""
            self.displayLabel.text = ""
        })
        let arriveSafelyAction = UIAlertAction(title: "I've arrived safely", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            self.googleMaps.clear()
            self.start.isHidden = false
            self.end.isHidden = true
            self.startLocation.text = ""
            self.destinationLocation.text = ""
        })
        endActionsheet.addAction(cancelAction)
        endActionsheet.addAction(endTripAction)
        endActionsheet.addAction(arriveSafelyAction)
        self.present(endActionsheet, animated: true, completion: nil)
    }
    
    // Mark: reverse the original place and destination
    @IBAction func reverseBtn(_ sender: UIButton) {
        let temp1 = locationStart
        locationStart = locationEnd
        locationEnd = temp1
        let temp2 = startLocation.text
        startLocation.text = destinationLocation.text
        destinationLocation.text = temp2
        drawPath(startLocation: locationStart, endLocation: locationEnd)
    }
    
    // Mark:travel modes selector
    @IBAction func travelModePressed(_ sender: UIButton) {
        if(sender.tag == 0){
            travelMode = travelModes.driving.rawValue
        }
        else if(sender.tag == 1){
            travelMode = travelModes.walking.rawValue
        }
        else if(sender.tag == 2){
            travelMode = travelModes.cycling.rawValue
        }
        else{
            travelMode = travelModes.transit.rawValue
        }
        self.drawPath(startLocation: locationStart, endLocation: locationEnd)
    }
    
    //**********************************************************************************//
    //*************************** "Help" About Button Functions ************************//
    //**********************************************************************************//
    
    // Mark: "I feel Nervous" button: send message to companions
    @IBAction func nervousBtn(_ sender: UIButton) {
        if self.canSendText(){
            let messageVC = self.configuredMessageComposeViewController()
            present(messageVC, animated: true, completion: nil)
        } else {
            let errorAlert = UIAlertView(title: "Failed:", message: "your device don't have message function", delegate: self, cancelButtonTitle: "cancel")
            errorAlert.show()
        }
    }
    
    func canSendText() -> Bool{
        return MFMessageComposeViewController.canSendText()
    }
    
    func configuredMessageComposeViewController() -> MFMessageComposeViewController{
        let phones = ["0426499520"];
        let messageComposeVC = MFMessageComposeViewController()
        messageComposeVC.messageComposeDelegate = self
        messageComposeVC.recipients = phones
        messageComposeVC.body = "I feel so nervous! Please check my safty!!!"
        return messageComposeVC
        
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    
    // Mark: "Call Police " button : call "000"
    @IBAction func callPoliceBtn(_ sender: UIButton) {
        //automatically turn to Phone page and dial
        let urlString = "telprompt://0426499520"
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
    
    
    //********************************************************************************//
    //***************************** Shake Motion Detection ***************************//
    //********************************************************************************//
    
    // MARK: Mapview is to become first responder to get shake motion
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    
    // MARK: Enable detection of shake motion
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            //Step1: pop up "Alert View"
            alertView.isHidden = false
            alertView.backgroundColor = UIColor.gray.withAlphaComponent(0.8)
            self.view.insertSubview(alertView, aboveSubview: view)
            
            //Step2: vibrate the phone
            let soundID = SystemSoundID(kSystemSoundID_Vibrate) //Build "Vibrate" Sound
            AudioServicesPlaySystemSound(soundID) //Play "Vibrate"
            
            //Step3: load circular timer//
            countdownTimer.labelFont = UIFont(name: "HelveticaNeue-Light", size: 40.0)
            countdownTimer.lineColor = UIColor.green
            countdownTimer.sizeToFit()
            countdownTimer.lineWidth = 6
            countdownTimer.start(beginingValue: 30, interval: 1)
            self.safetyBtn.layer.cornerRadius = self.safetyBtn.frame.size.width/2
            self.safetyBtn.backgroundColor = UIColor.white
        }
    }
    
    // Mark: "Yes,I am safe" button to confirm the safety
    @IBAction func safeConfirm(_ sender: UIButton) {
        countdownTimer.end()
        alertView.isHidden = true
    }
    
}

//******************************************************************************//
//******************************** Extensions **********************************//
//******************************************************************************//


// MARK: - GMS Auto Complete Delegate, for autocomplete search location
extension MapViewController: GMSAutocompleteViewControllerDelegate {
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print("Error \(error)")
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        // Change map location
        let camera = GMSCameraPosition.camera(withLatitude: place.coordinate.latitude, longitude: place.coordinate.longitude, zoom: 14.0
        )
        
        // set coordinate to text
        if locationSelected == .startLocation {
            startLocation.text = "\(place.name)"
            locationStart = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
            createMarker(titleMarker: "Start:"+"\(place.name)", iconMarker: #imageLiteral(resourceName: "mapspin"), latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        } else {
            destinationLocation.text = "\(place.name)"
            locationEnd = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
            createMarker(titleMarker: "End:"+"\(place.name)", iconMarker: #imageLiteral(resourceName: "mapspin"), latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        }

        self.googleMaps.camera = camera
        self.dismiss(animated: true, completion: nil)
        
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}

public extension UISearchBar {
    
    public func setTextColor(color: UIColor) {
        let svs = subviews.flatMap { $0.subviews }
        guard let tf = (svs.filter { $0 is UITextField }).first as? UITextField else { return }
        tf.textColor = color
    }
    
}
