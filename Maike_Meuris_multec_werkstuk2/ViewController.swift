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
    
    var managedContext:NSManagedObjectContext?
    
    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager()
    
    @IBOutlet weak var lblBijgewerkt: UILabel!
    @IBOutlet weak var btnHerladen: UIButton!
    
    @IBAction func clickBtnHerladen(_ sender: Any) {
        //De gebruiker kan de gegevens opnieuw laten ophalen via Core Data en bijgevolg de data in Core Data laten vernieuwen.
        
        // Eerst de bestaande core data leeg maken
        let stations = haalStationsUitCoreData()
        /*print("Er zijn nu zoveel stations in code data")
        print(stations.count)*/
        for station in stations{
            managedContext?.delete(station)
        }
        /*print("Nu moeten ze verwijderd zijn")
        let stations2 = haalStationsUitCoreData()
        print(stations2.count)*/
        
        // Dan de data opnieuw uitladen uit de JSON
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
        
        // Kijken of core data leeg is of niet (of de station al zijn opgehaald uit JSON)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        self.managedContext = appDelegate.persistentContainer.viewContext
        
        let stations = haalStationsUitCoreData()
        
        print("Aantal stations:")
        print(stations.count)
        
        if(stations.count == 0){ // Als er nog geen stations zijn, gaan we ze ophalen uit JSON
            laadDataIn()
        } else{ // Anders worden er gewoon de stations getoond die in de core data zitten
            haalStationsOp()
        }
        
    }
    
    func haalStationsUitCoreData() -> [Station]{
        let coreDataStations = NSFetchRequest<NSFetchRequestResult>(entityName: "Station")
        let opgehaaldeStations:[Station]
        do {
            opgehaaldeStations = try managedContext!.fetch(coreDataStations) as! [Station]
            
            return opgehaaldeStations
            
        } catch {
            fatalError("Failed to fetch stations: \(error)")
        }
    }
    
    func haalStationsOp(){
        // Stations uit core data ophalen
        
        let coreDataStations = NSFetchRequest<NSFetchRequestResult>(entityName: "Station")
        let opgehaaldeStations:[Station]
        do {
            opgehaaldeStations = try managedContext!.fetch(coreDataStations) as! [Station]
            voegStationsToe(stations: opgehaaldeStations)
        } catch {
            fatalError("Failed to fetch stations: \(error)")
        }
    }
    
    func voegStationsToe(stations: [Station]){
        print("voeg stations toe")
        for station in stations{
            
            let titel = station.name
            let coordinaat = CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)
            
            let myAnnotation = MyAnnotation(coordinate: coordinaat, title: titel)
            
            self.mapView.addAnnotation(myAnnotation)
        }
    }
    
    
    func laadDataIn(){
        
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
                    
                    let station = NSEntityDescription.insertNewObject(forEntityName: "Station", into: self.managedContext!) as! Station
                    
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
                    try self.managedContext!.save()
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
                    self.haalStationsOp()
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("station aangeklikt")
        print(view.annotation?.title!)
        performSegue(withIdentifier: "naarStationDetail", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "naarStationDetail" {
            if let nextVC = segue.destination as? StationDetailViewController {
                //nextVC.doorgegevenFoto = persoon!.foto
            }
        }
    }

}

