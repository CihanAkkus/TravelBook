//
//  ViewController.swift
//  TravelBook
//
//  Created by Cihan Akkuş on 16.02.2025.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    
    //Variables*********************************************
    var mapView = MKMapView()
    var locationManager = CLLocationManager()
    
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    let nameText = UITextField()
    let commentText = UITextField()
    
    let saveButton = UIButton()
    
    var chosenName = ""
    var chosenNameID : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    

    
    //viewDidLoad***********************************************
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let width = view.frame.size.width
        let height = view.frame.size.height
        
        nameText.placeholder = "Name"
        nameText.textAlignment = .center
        nameText.frame = CGRect(x:0, y: height*0.13, width: width, height: 20)
        view.addSubview(nameText)
        
        commentText.placeholder = "Comment"
        commentText.textAlignment = .center
        commentText.frame = CGRect(x:0, y: height*0.17, width: width, height: 20)
        view.addSubview(commentText)
        
        saveButton.setTitle("Save", for: UIControl.State.normal)
        saveButton.setTitleColor(UIColor.magenta, for: UIControl.State.normal)
        saveButton.frame = CGRect(x:0, y:height*0.85, width: width, height: 15)
        view.addSubview(saveButton)
        
        saveButton.addTarget(self, action: #selector(saveButtonClicked), for: UIControl.Event.touchUpInside)
        
        mapView.delegate = self
        
        mapView.frame = CGRect(x:0, y: height*0.25, width: width, height: height*0.55)
        view.addSubview(mapView)
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 2.5
        mapView.addGestureRecognizer(gestureRecognizer)
        
        let gestureRecognizerKeyboard = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(gestureRecognizerKeyboard)
        
        if chosenName != ""{
            
            saveButton.isHidden = true
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            
            let idString = chosenNameID?.uuidString
            
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString!)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                let results = try context.fetch(fetchRequest)
                
                if results.count > 0{
                    
                    for result in results as! [NSManagedObject]{
                        
                        if let title = result.value(forKey: "title") as? String{
                            self.nameText.text = title
                            annotationTitle = title
                        }
                        if let subtitle = result.value(forKey: "subtitle") as? String{
                            self.commentText.text = subtitle
                            self.annotationSubtitle = subtitle
                        }
                        if let latitude = result.value(forKey: "latitude") as? Double{
                            self.annotationLatitude = latitude
                            
                        }
                        if let longitude = result.value(forKey: "longitude") as? Double{
                            self.annotationLongitude = longitude
                            
                        }
                        let annotation = MKPointAnnotation()
                        annotation.title = self.annotationTitle
                        annotation.subtitle = self.annotationSubtitle
                        let coordinate = CLLocationCoordinate2D(latitude: self.annotationLatitude, longitude: self.annotationLongitude)
                        annotation.coordinate = coordinate
                        
                        mapView.addAnnotation(annotation)
                        locationManager.stopUpdatingLocation()
                        
                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        let region = MKCoordinateRegion(center: coordinate, span: span)
                        mapView.setRegion(region, animated: true)
                        

                    }
                    
                    
                }
                
                
                
                
            }catch{
                print("error")
            }
            
            
        }else{
            
            
        }
        
        
                                                             
    }
    
    
    //Functions******************************************************************************
    @objc func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    @objc func chooseLocation(gestureRecognizer:UILongPressGestureRecognizer){
        
            if gestureRecognizer.state == .began {
                if (nameText.text != "" && commentText.text != ""){
                    
                    let touchedPoint = gestureRecognizer.location(in: self.mapView)
                    let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
                    
                    chosenLatitude = touchedCoordinates.latitude
                    chosenLongitude = touchedCoordinates.longitude
                    
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = touchedCoordinates
                    annotation.title = nameText.text
                    annotation.subtitle = commentText.text
                    self.mapView.addAnnotation(annotation)
                }else{
                    alertMessage(title:"WARNING",message: "Please fill in both the 'Name' and 'Comment' fields to add a pin.")
                }
            }
            
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if chosenName == ""{
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)//we get the location
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)//Zooming
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
         
        
        let reuseID = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKMarkerAnnotationView
        
        
        if pinView == nil{
            
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        }else{
            pinView?.annotation = annotation
        }
        
        return pinView
        
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if chosenName != ""{
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation){(placemarks, error) in
                
                if let placemark = placemarks{
                    if placemark.count > 0{
                        
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.chosenName
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                        
                    }
                }
            }
        }
    }
    
    
    
    
    
    
    @objc func saveButtonClicked(){
        
        guard let name = nameText.text, !name.isEmpty, let comment = commentText.text, !comment.isEmpty else {
            alertMessage(title:"WARNING",message: "Please add a pin to save.")
            return
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places",into: context)//A new line is added to entity here.
        
        //attributes
        newPlace.setValue(nameText.text!,forKey: "title")
        newPlace.setValue(commentText.text!, forKey: "subtitle")
        newPlace.setValue(UUID(), forKey: "id")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        
        do{
            try context.save()
            print("success")
        }catch{
            print("error")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newData"), object: nil)
        self.navigationController?.popViewController(animated: true)
        
    }
    
    func alertMessage(title: String,message: String){
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        let okButton = UIAlertAction(title: "OK",style: UIAlertAction.Style.default, handler: nil)
        
        alert.addAction(okButton)
        
        self.present(alert, animated: true, completion: nil)
        
        
    }
    
    
    


}

