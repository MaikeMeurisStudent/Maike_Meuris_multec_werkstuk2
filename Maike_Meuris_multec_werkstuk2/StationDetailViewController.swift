//
//  StationDetailViewController.swift
//  Maike_Meuris_multec_werkstuk2
//
//  Created by Maike Meuris on 09/05/2018.
//  Copyright © 2018 Maike Meuris. All rights reserved.
//

import UIKit

class StationDetailViewController: UIViewController {

    var doorgegevenStation:String?
    var stations:[Station]?
    
    @IBOutlet weak var lblStationNaam: UILabel!
    @IBOutlet weak var lblOpenOfGesloten: UILabel!
    
    @IBOutlet weak var lblVrijePlaatsen: UILabel!
    @IBOutlet weak var lblBeschikbareFietsen: UILabel!
    
    @IBOutlet weak var lblStationAdres: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(stations!)
        
        getAangeklikteStation()
    }
    
    func getAangeklikteStation(){
        print(stations!.count)
        var station:Station?
        for index in 0 ... stations!.count-1{
            if stations![index].name == doorgegevenStation{
                
                station = stations![index]
                
                print(station)
                
                // Stoppen met for-loopen, want het station is gevonden en de rest van de array hoeft dus niet meer bekeken te worden
                break
            }
            print(index)
        }
        
        lblStationNaam.text = station!.name
        
        // Afhankelijk van de status en de taal het juiste woord en de juiste kleur zetten
        // "open" is in beide talen hetzelfde, maar is toch voorzien in het geval er nog meer beschikbare talen worden toegevoegd
        if station!.status == "OPEN" {
            lblOpenOfGesloten.text = NSLocalizedString("open", comment: "")
            lblOpenOfGesloten.textColor = UIColor(red: 0, green: 0.5765, blue: 0.1255, alpha: 1.0)
        } else{
            lblOpenOfGesloten.text = NSLocalizedString("gesloten", comment: "")
            lblOpenOfGesloten.textColor = UIColor.red
        }
        
        // Geen NumberFormatter nodig, want er komen geen decimalen of getallen met meer dan 2 digits in voor
        lblVrijePlaatsen.text = String(station!.available_bike_stands)
        lblBeschikbareFietsen.text = String(station!.available_bikes)
        
        lblStationAdres.text = station!.address
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
