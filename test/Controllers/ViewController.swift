//
//  ViewController.swift
//  test
//
//  Created by Guilherme Souza on 24/03/22.
//

import UIKit
import MapKit
import Foundation
import CoreLocation

class ViewController: UIViewController {
    
    @IBOutlet var toBlurView: UIView!
    @IBOutlet var toHideView: UIView!
    @IBOutlet var routeLabel: UILabel!
    @IBOutlet var memezin: UIImageView!
    @IBOutlet var passengerTextField: UITextField!
    @IBOutlet var passengerLabel: UILabel!
    @IBOutlet var originTextField: UITextField!
    @IBOutlet var destinationTextField: UITextField!
    @IBOutlet var confirmButton: UIButton!
    @IBOutlet var passOne: UITextField!
    @IBOutlet var passTwo: UITextField!
    @IBOutlet var passThree: UITextField!
    @IBOutlet var passFour: UITextField!
    @IBOutlet var detailLabel: UILabel!
    @IBOutlet var aboutButton: UIButton!
    @IBOutlet var aboutImage: UIImageView!
    @IBOutlet var returnButton: UIButton!
    @IBOutlet var detailTextField: UITextField!
    @IBOutlet var recalcButton: UIButton!
    @IBOutlet var blur: UIVisualEffectView!
    
    let passengers = ["1", "2", "3", "4"]
    var pickerView = UIPickerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        pickerView.delegate = self
        pickerView.dataSource = self
        passengerTextField.inputView = pickerView
        passengerTextField.textAlignment = .center
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            view.endEditing(true)
    }

    //assync function to get distances between origin and destination first
    //then origin to stop
    //then stop to destination
    //the calcPay will be done here to
    //then we'll append the output of the assync function to detail text field
    @IBAction func getDistance(_ sender: UIButton) {
        
        let origin = getOrigin()
        let destination = getDestination()
        let nameAndAddress = getNameAndAddress()
        let names = nameAndAddress.names
        let addresses = nameAndAddress.address
        let name = names.components(separatedBy: ", ")
        let address = addresses.components(separatedBy: "; ")
//        print (origin)
//        print (destination)
//        print (nameAndAddress)
//        print (names)
//        print (addresses)
//        print (name)
//        print (address)
        //
        getIdealRoute(origin: origin, destination: destination) { idealRoute in
            print("the ideal route from \(origin) to \(destination) is \(idealRoute) km")
            for (i, a) in address.enumerated() {
                self.getIdealRoute(origin: origin, destination: a) { route1 in
                    print("the stop number \(i+1) at \(a) is \(route1) km from \(origin)")
                    self.getIdealRoute(origin: a, destination: destination) { [self] route2 in
                        print("the distance between stop number \(i+1) at \(a) and \(destination) is \(route2) km")
                        let detour = ((route1 + route2) - idealRoute)
                        print("the detour from the ideal route is \(detour) km")
                        let cost = calcPay(dinamic: self.calcDinamicValue(), detour: detour).rounded()

                        detailTextField.text?.append(contentsOf: "\(name[i]): R$ \(cost); ")
                        
                        print(cost)
                        
                        toHideView.isHidden = true
                        detailLabel.isHidden = false
                        detailTextField.isHidden = false
                        memezin.isHidden = false
                        recalcButton.isHidden = false
                        passengerLabel.isHidden = true
                        
                        
                    }
                }
            }
        }
        
    }
    
    //hiding and showing things to reset the app
    @IBAction func recalcAct() {
        
        toHideView.isHidden = false
        detailLabel.isHidden = true
        detailTextField.isHidden = true
        detailTextField.text = nil
        memezin.isHidden = true
        recalcButton.isHidden = true
        passengerLabel.isHidden = false
        passengerTextField.isHidden = false
        passengerTextField.text = nil
        routeLabel.isHidden = true
        originTextField.text = nil
        originTextField.isHidden = true
        destinationTextField.text = nil
        destinationTextField.isHidden = true
        passOne.text = nil
        passOne.isHidden = true
        passTwo.text = nil
        passTwo.isHidden = true
        passThree.text = nil
        passThree.isHidden = true
        passFour.text = nil
        passFour.isHidden = true
        confirmButton.isHidden = true
        pickerView.reloadAllComponents()
        
    }
    
    //the original assync geolocation function
    func getIdealRoute(origin: String, destination: String, completionHander: @escaping (_ idealRoute: Double) -> Void) {
        
        let geocoder = CLGeocoder()
        var idealRoute: Double = 0
        geocoder.geocodeAddressString(origin) { (placemarks: [CLPlacemark]? , error: Error?) in
            if let placemarks = placemarks {
                let start_placemark = placemarks[0]
                geocoder.geocodeAddressString(destination, completionHandler: { ( placemarks: [CLPlacemark]?, error: Error?) in
                    if let placemarks = placemarks {
                        let end_placemark = placemarks[0]

                        let start = MKMapItem(placemark: MKPlacemark(coordinate: start_placemark.location!.coordinate))
                        let end = MKMapItem(placemark: MKPlacemark(coordinate: end_placemark.location!.coordinate))

                        let request: MKDirections.Request = MKDirections.Request()
                        request.source = start
                        request.destination = end
                        request.transportType = MKDirectionsTransportType.automobile

                        let directions = MKDirections(request: request)
                        directions.calculate(completionHandler: { (response: MKDirections.Response?, error: Error?) in

                            if let routes = response?.routes {
                                let route = routes[0]
                                idealRoute = route.distance/1000
                                completionHander(idealRoute)
                            }
                        })
                    }
                })
            }
        }
    }
    
    func calcPay(dinamic: Double, detour: Double) -> Double {
        //receives dinamic value, initial tax and detour calc
        return 2 + 0.58 * detour * dinamic
    }
    
    func calcDinamicValue() -> Double {
        //gets dinamic value from current time
        //peak hours
        var dinamicValue: Double
        dinamicValue = 0
        let today = Date()
        let hours = (Calendar.current.component(.hour, from: today))
        if (hours >= 7 && hours <= 9) || (hours >= 12 && hours <= 13)
            || (hours >= 17 && hours <= 19) {
            
            dinamicValue = 1.2
            
        } else {
            
            dinamicValue = 1
            
        }
        //print(dinamicValue)
        return dinamicValue
    }
    
    func getOrigin() -> String {
        
        let zipcode = " Pernambuco Brasil"
        let origin: String = originTextField.text! + zipcode
        return origin
        
    }
    
    func getDestination() -> String {
        
        let zipcode = " Pernambuco Brasil"
        let destination: String = destinationTextField.text! + zipcode
        return destination
        
    }
    
    //we receive name; address
    //my intention is to return an string with the passengers names
    //and another string with the addresses

    func getNameAndAddress() -> (names: String, address: String) {
        
        let passengers = pickerView.selectedRow(inComponent: 0) + 1
        print (passengers)
        let zipcode = " Pernambuco Brasil"
        if passengers == 1 {
            let pass1: String = passOne.text ?? ""
            let aux = pass1.components(separatedBy: "; ")
            let names: String = aux[0]
            let addresses: String = aux[1] + zipcode
            return (names, addresses)
        } else if passengers == 2 {
            let pass1: String = passOne.text ?? ""
            let pass2: String = passTwo.text ?? ""
            let aux1 = pass1.components(separatedBy: "; ")
            let aux2 = pass2.components(separatedBy: "; ")
            let names: String = aux1[0] + ", " + aux2[0]
            let addresses: String = aux1[1] + "\(zipcode); " + aux2[1] + zipcode
            return (names, addresses)
        } else if passengers == 3 {
            let pass1: String = passOne.text ?? ""
            let pass2: String = passTwo.text ?? ""
            let pass3: String = passThree.text ?? ""
            let aux1 = pass1.components(separatedBy: "; ")
            let aux2 = pass2.components(separatedBy: "; ")
            let aux3 = pass3.components(separatedBy: "; ")
            let names: String = aux1[0] + ", " + aux2[0] + ", " + aux3[0]
            let addresses: String = aux1[1] + "\(zipcode); " + aux2[1] + " \(zipcode); " + aux3[1] + zipcode
            return (names, addresses)
        } else {
            let pass1: String = passOne.text ?? ""
            let pass2: String = passTwo.text ?? ""
            let pass3: String = passThree.text ?? ""
            let pass4: String = passFour.text ?? ""
            let aux1 = pass1.components(separatedBy: "; ")
            let aux2 = pass2.components(separatedBy: "; ")
            let aux3 = pass3.components(separatedBy: "; ")
            let aux4 = pass4.components(separatedBy: "; ")
            let names: String = aux1[0] + ", " + aux2[0] + ", " + aux3[0] + ", " + aux4[0]
            let addresses: String = aux1[1] + "\(zipcode); " + aux2[1] + "\(zipcode); " + aux3[1] + "\(zipcode); " + aux4[1] + zipcode
            return (names, addresses)
        }
    }
    
    @IBAction func openAbout() {
        
        print("Button Clicked")
        aboutImage.isHidden = false
        returnButton.isHidden = false
        blur.isHidden = false
        
    }
    
    @IBAction func returnHome() {
        
        print("We're back at home page")
        aboutImage.isHidden = true
        returnButton.isHidden = true
        blur.isHidden = true
        
    }

}

//picker view passenger count
extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return passengers.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return passengers[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        passengerTextField.text = passengers[row]
        passengerTextField.resignFirstResponder()
        routeLabel.isHidden = false
        originTextField.isHidden = false
        destinationTextField.isHidden = false
        if passengers[row].elementsEqual("1") {
            passOne.isHidden = false
            passTwo.isHidden = true
            passThree.isHidden = true
            passFour.isHidden = true
        } else if passengers[row].elementsEqual("2") {
            passOne.isHidden = false
            passTwo.isHidden = false
            passThree.isHidden = true
            passFour.isHidden = true
        } else if passengers[row].elementsEqual("3") {
            passOne.isHidden = false
            passTwo.isHidden = false
            passThree.isHidden = false
            passFour.isHidden = true
        } else {
            passOne.isHidden = false
            passTwo.isHidden = false
            passThree.isHidden = false
            passFour.isHidden = false
        }
        confirmButton.isHidden = false
        print(passengers[row])
    }
    
}
