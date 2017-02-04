//
//  ViewController.swift
//  Graffiti
//
//  Created by Juan Manuel Jimenez Sanchez on 1/02/17.
//  Copyright © 2017 Juan Manuel Jimenez Sanchez. All rights reserved.
//

import UIKit
import MapKit

class CurrentLocationViewController: UIViewController {

    @IBOutlet weak var getButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tagButton: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var graffiti: Graffiti?
    let locationManager = CLLocationManager()
    let geocoder = CLGeocoder()
    var updatingLocation = false {
        didSet {
            if updatingLocation {
                self.getButton.setImage(#imageLiteral(resourceName: "btn_localizar_off"), for: .normal)
                self.activityIndicator.isHidden = false
                self.activityIndicator.startAnimating()
                self.getButton.isUserInteractionEnabled = false
            } else {
                self.getButton.setImage(#imageLiteral(resourceName: "btn_localizar_on"), for: .normal)
                self.activityIndicator.isHidden = true
                self.activityIndicator.stopAnimating()
                self.getButton.isUserInteractionEnabled = true
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let image = UIImage(named: "img_navbar_title")
        self.navigationItem.titleView = UIImageView(image: image)
        
        self.updatingLocation = false
    }
    
    @IBAction func getLocation(_ sender: UIButton) {
        self.startLocationManager()
    }
    
    //Solicita la autorización para localizar al usuario, la habilita y hace zoom sobre la ubicación
    func startLocationManager() {
        let authStatus = CLLocationManager.authorizationStatus()
        
        switch authStatus {
        case .notDetermined:
            self.locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            self.showLocationServicesDeniedAlert()
        default:
            if CLLocationManager.locationServicesEnabled() {
                self.updatingLocation = true
                self.tagButton.isEnabled = false
                
                self.locationManager.delegate = self
                self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                self.locationManager.requestLocation()
                
                //Hacemos zoom sobre la localización del usuario
                let region = MKCoordinateRegionMakeWithDistance(self.mapView.userLocation.coordinate, 1000, 1000)
                self.mapView.setRegion(self.mapView.regionThatFits(region), animated: true)
            }
        }
    }
    
    //Si no se puede habilitar la localización entonces muestra un alert
    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Localización desactivada", message: "Por favor activa la localización para esta app en ajustes", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    //Arma la dirección a la que corresponde la ubicación del usuario
    func stringFromPlacemark(placemark: CLPlacemark) -> String {
        var line1 = ""
        if let s = placemark.thoroughfare {
            line1 += s + ", "
        }
        if let s = placemark.subThoroughfare {
            line1 += s
        }
        
        var line2 = ""
        if let s = placemark.postalCode {
            line2 += s + " "
        }
        if let s = placemark.locality {
            line2 += s
        }
        
        var line3 = ""
        if let s = placemark.administrativeArea {
            line3 += s
        }
        
        return line1 + "\n" + line2 + "\n" + line3
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TagGraffiti" {
            let navigationController = segue.destination as! UINavigationController
            let detailVC = navigationController.topViewController as! GraffitiDetailViewController
            detailVC.taggedGraffiti = self.graffiti
            detailVC.delegate = self
        }
    }
}

extension CurrentLocationViewController: GraffitiDetailViewControllerDelegate {
    func graffitiDidFinishGetTagged(sender: GraffitiDetailViewController, tagged: Graffiti) {
        
    }
}

extension CurrentLocationViewController: CLLocationManagerDelegate {
    //Si hay un error
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("****** Error en Core Location ******")
    }
    
    //Le dice al delegado que los datos de la nueva localización están disponibles
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else {
            return
        }
        let latitude = Double(newLocation.coordinate.latitude)
        let longitude = Double(newLocation.coordinate.longitude)
        
        //A partir de la latitud y longitud obtenemos la dirección
        self.geocoder.reverseGeocodeLocation(newLocation) { (placemarks, error) in
            if error == nil  {
                var address = "No se ha podido determinar"
                if let placemark = placemarks?.last {
                    address = self.stringFromPlacemark(placemark: placemark)
                }
                self.graffiti = Graffiti(address: address, latitude: latitude, longitude: longitude, imageUrl: "")
            }
            self.updatingLocation = false
            self.tagButton.isEnabled = true
        }
    }
}
