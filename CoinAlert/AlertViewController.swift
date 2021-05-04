//
//  AlertViewController.swift
//  CoinAlert
//
//  Created by Andrew Sorenson on 4/20/21.
//

import UIKit
import Firebase

class AlertViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    //MARK: - Properties


    var lastButtonPressed: String = "cancelButton"

    //represents the initial frequency when this view was opened
    static var initialFrequency: String = ""
    
    let possibleSettingsArray: [String] = ["NoNotifications", "15Min", "30Min", "1Hour", "2Hours", "4Hours", "8Hours", "1Day"]
    
    //switches
    @IBOutlet weak var switchNoNotifications: UISwitch!
    @IBOutlet weak var switch15Min: UISwitch!
    @IBOutlet weak var switch30Min: UISwitch!
    @IBOutlet weak var switch1Hour: UISwitch!
    @IBOutlet weak var switch2Hours: UISwitch!
    @IBOutlet weak var switch4Hours: UISwitch!
    @IBOutlet weak var switch8Hours: UISwitch!
    @IBOutlet weak var switch1Day: UISwitch!
    
    //buttons
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    //switch labels
    @IBOutlet weak var switchLabelNoNotifications: UILabel!
    @IBOutlet weak var switchLabel15Min: UILabel!
    @IBOutlet weak var switchLabel30Min: UILabel!
    @IBOutlet weak var switchLabel1Hour: UILabel!
    @IBOutlet weak var switchLabel2Hours: UILabel!
    @IBOutlet weak var switchLabel4Hours: UILabel!
    @IBOutlet weak var switchLabel8Hours: UILabel!
    @IBOutlet weak var switchLabel1Day: UILabel!
    
    //other labels
    @IBOutlet weak var freqLabel: UILabel!
    @IBOutlet weak var coinsLabel: UILabel!
    
    @IBOutlet weak var SelectedCoinTableView: UITableView!
    
    
    // MARK: - Views
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        //load saved alert frequency onto switches
        let defaults = UserDefaults.standard
        AlertViewController.initialFrequency = defaults.object(forKey:"alertFrequency") as? String ?? "1Day"
        self.setSwitchValues(AlertViewController.initialFrequency)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //do stuff
        SelectedCoinTableView.delegate = self
        SelectedCoinTableView.dataSource = self
        setupViewColors()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        //save switch state if save button pressed
        if lastButtonPressed == "saveButton" {
            let newFrequency: String = getSwitchSettings()
            let defaults = UserDefaults.standard
            defaults.set(newFrequency, forKey:"alertFrequency")
        }
        //otherwise, do nothing
    }
    
    
    
    // MARK: - Populate TableView Data
    

    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        //makes sure there is always at least one row in the section
        let selectedCoins: [Coin] = CoinTableViewController.selectedCoins
        return max(selectedCoins.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "SelectedCoinTableViewCell"
 
        //downcast cell UITableViewCall to CoinTableViewCell
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? CoinTableViewCell  else {
            fatalError("The dequeued cell is not an instance of CoinTableViewCell.")
        }
        
        let selectedCoins: [Coin] = CoinTableViewController.selectedCoins
        
        //if no selected coins, return "No Selected Coins" template
        if (indexPath.row == 0) && (selectedCoins.count == 0) {
            return loadNoCoins(cell)
        }
        
        // otherwise, fetches the appropriate coin for the table view row.
        let coin = selectedCoins[indexPath.row]
        
        CoinTableViewController.formatCoinRank(coin.rank, cell)
        CoinTableViewController.formatCoinName(coin.name, cell)
        CoinTableViewController.formatCoinSymbol(coin.symbol, cell)
        CoinTableViewController.formatCoinChange(coin.change_24h, cell)
        CoinTableViewController.formatCoinPrice(coin.price, cell)
        
        if indexPath.row.isMultiple(of: 2) {
            cell.backgroundColor = UIColor.init(red: 50/255.0, green: 50/255.0, blue: 62/255.0, alpha: 1.0)
        } else {
            cell.backgroundColor = UIColor.init(red: 54/255.0, green: 54/255.0, blue: 66/255.0, alpha: 1.0)
        }

        return cell
    }

    
    
    // MARK: - Navigation
    
    
    
    @IBAction func saveButton(_ sender: UIBarButtonItem) {
        
        if CoinTableViewController.isConnectedToInternet {
            //store button press
            lastButtonPressed = "saveButton"
            //update Databse
            updateDatabasePreference(AlertViewController.initialFrequency)
            //return to coin table view controller
            navigationController?.popViewController(animated: true)
        } else {
            CoinTableViewController.alertNoInternet(self)
        }
    }
    
    @IBAction func cancelButton(_ sender: UIBarButtonItem) {
        
        //store button press
        lastButtonPressed = "cancelButton"
        //return to coin table view controller
        navigationController?.popViewController(animated: true)
    }
    
    
    
    // MARK: - Private Methods
    
    
    
    private func loadNoCoins(_ cell: CoinTableViewCell) -> CoinTableViewCell {
        cell.backgroundColor = UIColor.init(red: 50/255.0, green: 50/255.0, blue: 62/255.0, alpha: 1.0)
        cell.rankLabel.text = ""
        cell.rankLabel.textColor = UIColor.systemRed
        cell.nameLabel.text = "No Coins Selected"
        cell.nameLabel.textColor = UIColor.systemRed
        cell.symbolLabel.text = ""
        cell.symbolLabel.textColor = UIColor.systemRed
        cell.changeLabel.text = ""
        cell.changeLabel.textColor = UIColor.systemRed
        cell.priceLabel.text = "----------"
        cell.priceLabel.textColor = UIColor.systemRed
        return cell
    }
    
    private func setupViewColors() {
        
        //Table view background color
        SelectedCoinTableView.backgroundColor = UIColor.init(red: 54/255.0, green: 54/255.0, blue: 66/255.0, alpha: 1.0)
        
        //View background color
        self.view.backgroundColor = UIColor.init(red: 46/255.0, green: 46/255.0, blue: 60/255.0, alpha: 1.0)
        
        freqLabel.textColor = UIColor.white
        coinsLabel.textColor = UIColor.white
        
        cancelButton.tintColor = UIColor.init(red: 116/255.0, green: 140/255.0, blue: 230/255.0, alpha: 1.0)
        saveButton.tintColor = UIColor.init(red: 116/255.0, green: 140/255.0, blue: 230/255.0, alpha: 1.0)
        
        let switchLabelArray: [UILabel] = [switchLabelNoNotifications, switchLabel15Min, switchLabel30Min, switchLabel1Hour, switchLabel2Hours, switchLabel4Hours, switchLabel8Hours, switchLabel1Day]
        
        for element in switchLabelArray{
            element.textColor = UIColor.white
        }
    }
    
    private func updateDatabasePreference(_ oldAlertFrequency: String) {
        
        let userToken: String = CoinTableViewController.userToken
        
        var ref: DatabaseReference!
        //remove old alert frequency info from Firebase Database
        ref = Database.database().reference(withPath: "alert_info/\(oldAlertFrequency)/\(userToken)")

        //delete the userToken from old preference list
        ref!.removeValue()
        
        //get new saved Button preference
        let newFrequency: String = getSwitchSettings()
    
        let selectedCoinsIDs: [Int] = CoinTableViewController.selectedCoinsIDs
        //add new alert frequency info to Firebase Database
        ref = Database.database().reference(withPath: "alert_info/\(newFrequency)")
        ref!.child(userToken).setValue(selectedCoinsIDs)
    }
    
    private func setSwitchValues(_ alertFrequency: String) {
        
        //array of switches in view controller
        let switchArray: [UISwitch] = [switchNoNotifications, switch15Min, switch30Min, switch1Hour, switch2Hours, switch4Hours, switch8Hours, switch1Day]
        
        var index: Int = 0
        for element in switchArray {
            if alertFrequency == possibleSettingsArray[index] {
                element.setOn(true, animated: false)
            } else {
                element.setOn(false, animated: true)
            }
            index += 1
        }
    }
    
    private func getSwitchSettings() -> String {
        //return a string representing the chosen alert frequency
        
        //array of switches in view controller
        let switchArray: [UISwitch] = [switchNoNotifications, switch15Min, switch30Min, switch1Hour, switch2Hours, switch4Hours, switch8Hours, switch1Day]
        
        var alertFrequency: String = "1Day"
        var index: Int = 0
        for element in switchArray {
            if element.isOn{
                alertFrequency = possibleSettingsArray[index]
                //once "on" switch is found, return corresponding value
                return(alertFrequency)
            } else {
                index += 1
            }
        }
        return("1Day")
    }
    
    
    
    // MARK: - Handle Switch Toggling
    
    
    
    @IBAction func switchChangeNoNotifications(_ sender: UISwitch) {
        setSwitchValues("NoNotifications")
    }
    @IBAction func switchChange15Min(_ sender: UISwitch) {
        setSwitchValues("15Min")
    }
    @IBAction func switchChange30Min(_ sender: UISwitch) {
        setSwitchValues("30Min")
    }
    @IBAction func switchChange1Hour(_ sender: UISwitch) {
        setSwitchValues("1Hour")
    }
    @IBAction func switchChange2Hours(_ sender: UISwitch) {
        setSwitchValues("2Hours")
    }
    @IBAction func switchChange4Hours(_ sender: UISwitch) {
        setSwitchValues("4Hours")
    }
    @IBAction func switchChange8Hours(_ sender: UISwitch) {
        setSwitchValues("8Hours")
    }
    @IBAction func switchChange1Day(_ sender: UISwitch) {
        setSwitchValues("1Day")
    }
    
}
