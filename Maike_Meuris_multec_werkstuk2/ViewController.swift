//
//  ViewController.swift
//  Maike_Meuris_multec_werkstuk2
//
//  Created by Maike Meuris on 03/05/2018.
//  Copyright © 2018 Maike Meuris. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager()
    
    @IBOutlet weak var lblBijgewerkt: UILabel!
    @IBOutlet weak var btnHerladen: UIButton!
    
    @IBAction func clickBtnHerladen(_ sender: Any) {
        //De gebruiker kan de gegevens opnieuw laten ophalen via Core Data en bijgevolg de data in Core Data laten vernieuwen.
        laadDataIn()
    }
    
    var nu = Date()
    let formatter = DateFormatter()
    var laatstGeupdate:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        //De gegevens van de JSON webservice die we in onze app zullen gebruiken worden bij de eerste opstart van de app gepersisteerd via Core Data.
        laadDataIn()
    }
    
    func haalStationsOp(appDelegate: AppDelegate, managedContext: NSManagedObjectContext){
        // Stations uit core data ophalen
        
        let coreDataStations = NSFetchRequest<NSFetchRequestResult>(entityName: "Station")
        let opgehaaldeStations:[Station]
        do {
            opgehaaldeStations =
                try managedContext.fetch(coreDataStations) as! [Station]
            print(opgehaaldeStations[0].name!)
            print(opgehaaldeStations[1].name!)
            print(opgehaaldeStations[2].name!)
            voegStationsToe(stations: opgehaaldeStations, appDelegate: appDelegate, managedContext: managedContext)
        } catch {
            fatalError("Failed to fetch stations: \(error)")
        }
    }
    
    func voegStationsToe(stations: [Station], appDelegate: AppDelegate, managedContext: NSManagedObjectContext){
        print("voeg stations toe")
        for station in stations{
            
            let titel = station.name
            let coordinaat = CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)
            
            let myAnnotation = MyAnnotation(coordinate: coordinaat, title: titel)
            
            self.mapView.addAnnotation(myAnnotation)
        }
        
        
    }
    
    
    func laadDataIn(){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        
        DispatchQueue.main.async {
            
            let url = URL(string: "https://api.jcdecaux.com/vls/v1/stations?apiKey=6d5071ed0d0b3b68462ad73df43fd9e5479b03d6&contract=Bruxelles-Capitale")
            
            let urlRequest = URLRequest(url: url!)
            
            let session = URLSession(configuration: URLSessionConfiguration.default)
            
            let task = session.dataTask(with: urlRequest) {
                (data, response, error) in
                // check for errors
                guard error == nil else {
                    print("error calling GET")
                    print(error!)
                    return
                }
                // make sure we got data
                guard let responseData = data else {
                    print("Error: did not receive data")
                    return
                }
                
                guard let villoData = try? JSONSerialization.jsonObject(with: responseData, options: []) as? [AnyObject] else {
                    
                    print("failed JSONSerialization")
                    return
                }
                
                
                for i in 0...(villoData!.count-1){
                    
                    let station = NSEntityDescription.insertNewObject(forEntityName: "Station", into: managedContext) as! Station
                    
                    let stationData:[String:AnyObject] = villoData![i] as! [String : AnyObject]
                    
                    station.number = stationData["number"] as! Int16
                    station.name = stationData["name"] as! String
                    station.address = stationData["address"] as! String
                    station.latitude = stationData["position"]!["lat"] as! Double
                    station.longitude = stationData["position"]!["lng"] as! Double
                    station.banking = (stationData["banking"] != nil)
                    station.bonus = (stationData["bonus"] != nil)
                    station.status = stationData["status"] as! String
                    station.contract_name = stationData["contract_name"] as! String
                    station.bike_stands = stationData["bike_stands"] as! Int16
                    station.available_bike_stands = stationData["available_bike_stands"] as! Int16
                    station.available_bikes = stationData["available_bikes"] as! Int16
                    station.last_update = stationData["last_update"] as! Int64
                    
                }
                
                do {
                    try managedContext.save()
                } catch {
                    fatalError("Failure to save context: \(error)")
                }
                
                //De gebruiker kan zien wanneer de data in Core Data voor het laatst werd bijgewerkt.
                self.nu = Date()
                self.formatter.dateFormat = "dd-MM-yyyy' om 'HH:mm:ss"
                self.laatstGeupdate = self.formatter.string(from: self.nu)
                print("Nieuwe tijdstip wordt in var gestopt")
                
                // UI aanpassen in main thread
                DispatchQueue.main.async {
                    self.lblBijgewerkt.text = self.laatstGeupdate
                    print("Var tekst tijdstip wordt in label gezet")
                    self.haalStationsOp(appDelegate: appDelegate, managedContext: managedContext)
                }
                
            }
            task.resume()
            
            
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let center = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
    }

}

