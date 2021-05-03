//
//  CoinTableViewController.swift
//  CoinAlert
//
//  Created by Andrew Sorenson on 4/17/21.
//

import UIKit
import Firebase
import UserNotifications
import os.log

class CoinTableViewController: UITableViewController, UISearchBarDelegate {
    
    
    //MARK: - Properties
     
    
    //array of Coin objects...to be displayed in table view
    var coins = [Coin]()
    
    //for Firebase Database
    var ref: DatabaseReference!
    
    //whether user is currently selecting coins
    var isSelecting: Bool = false
    
    //save selected coin IDs to UserDefaults
    static var selectedCoinsIDs = [Int]()
    
    //list of selected coins to be notified about (up to 4)
    static var selectedCoins = [Coin]()
    
    //keeps track of current user token
    static var userToken: String = ""
    
    @IBOutlet weak var coinSelectButton: UIBarButtonItem!
    @IBOutlet weak var alertButton: UIBarButtonItem!
    
    //for searching
    @IBOutlet weak var searchBar: UISearchBar!
    
    var searching: Bool = false
    
    var searchResults = [Coin]()
    
    //dictionary mapping names and symbols to current coin rank
    static var searchMap = [String: Int]()
    
    //list of currently searched coins
    static var searchResults = [Coin]()
    
    
    
    // MARK: - View
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchBar.delegate = self
        
        setupViewColors()
        
        //retrieve user-saved coin IDs
        let defaults = UserDefaults.standard
        CoinTableViewController.selectedCoinsIDs = defaults.object(forKey:"selectedCoinIDs") as? [Int] ?? [Int]()
        
        //get Firebase reference
        ref = Database.database().reference(withPath: "coin_info")
        //read from database!
        ref!.observe(.value, with: {
            snapshot in
            CoinTableViewController.selectedCoins = [Coin]()
            CoinTableViewController.searchMap = [String: Int]()
            let n = snapshot.childrenCount
            for i in 1...n {
                let index = Int(i)
                //get snapshot at current coin rank
                let childSnaphot = snapshot.childSnapshot(forPath: "\(i)")
                let oldCoin: Coin
                if self.coins.count < index {
                    //list not filled in yet
                    oldCoin = Coin()
                    self.coins.append(oldCoin)
                } else {
                    //list already initialized
                    oldCoin = self.coins[index-1]
                }
                
                //add new attributes, from database
                oldCoin.rank = index
                //get coin dictionary from snapshot
                let childDictionary = childSnaphot.value as! [String: Any]
                let coinName = childDictionary["Name"] as! String
                oldCoin.name = coinName
                let coinSymbol = childDictionary["Symbol"] as! String
                oldCoin.symbol = coinSymbol
                oldCoin.id = childDictionary["ID"] as! Int
                oldCoin.price = Float(truncating: childDictionary["Price"] as! NSNumber)
                oldCoin.change_7d = Float(truncating: childDictionary["7d_Change"] as! NSNumber)
                oldCoin.change_24h = Float(truncating: childDictionary["24h_Change"] as! NSNumber)
                oldCoin.change_1h = Float(truncating: childDictionary["1h_Change"] as! NSNumber)
                //update coin info
                self.coins[index-1] = oldCoin
                //populate searchMap
                CoinTableViewController.searchMap[oldCoin.name] = index
                CoinTableViewController.searchMap[oldCoin.symbol] = index
                //populate selected coin list on start-up
                for ID in CoinTableViewController.selectedCoinsIDs {
                    if ID == oldCoin.id {
                        CoinTableViewController.selectedCoins.append(oldCoin)
                    }
                }
            }
            //must reload tableView data after fetching update price info
            self.tableView.reloadData()
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //ask user to enable notifications if they haven't
        if !AppDelegate.notificationsEnabled {
            askToEnableNotifications()
        }
    }
    

    
    // MARK: - Populate TableView Data
    
    

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searching {
            return CoinTableViewController.searchResults.count
        } else {
            return coins.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "CoinTableViewCell"
 
        //downcast cell UITableViewCall to CoinTableViewCell
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? CoinTableViewCell  else {
            fatalError("The dequeued cell is not an instance of CoinTableViewCell.")
        }
        
        // Fetches the appropriate coin for the data source layout (whether searching or not).
        
        var coin = coins[indexPath.row]
        
        if searching {
            coin = CoinTableViewController.searchResults[indexPath.row]
        }
        
        CoinTableViewController.formatCoinRank(coin.rank, cell)
        CoinTableViewController.formatCoinName(coin.name, cell)
        CoinTableViewController.formatCoinSymbol(coin.symbol, cell)
        CoinTableViewController.formatCoinChange(coin.change_24h, cell)
        CoinTableViewController.formatCoinPrice(coin.price, cell)
        
        //turn off selection coloring
        cell.selectionStyle = .none

        //color cells (if selecting, then color all currently selected coins)
        if isSelecting && CoinTableViewController.selectedCoinsIDs.contains(coin.id) {
            cell.backgroundColor = UIColor.init(red: 116/255.0, green: 140/255.0, blue: 230/255.0, alpha: 1.0)
        } else
        
        if indexPath.row.isMultiple(of: 2) {
            cell.backgroundColor = UIColor.init(red: 50/255.0, green: 50/255.0, blue: 62/255.0, alpha: 1.0)
        } else {
            cell.backgroundColor = UIColor.init(red: 54/255.0, green: 54/255.0, blue: 66/255.0, alpha: 1.0)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //what to do when a row is selected
        var coin_id: Int
        if searching {
            coin_id = CoinTableViewController.searchResults[indexPath.row].id
        } else {
            coin_id = coins[indexPath.row].id
        }
        
        //if deselecting a row
        if CoinTableViewController.selectedCoinsIDs.contains(coin_id) {
            CoinTableViewController.selectedCoinsIDs.removeAll { value in
                return value == coin_id
            }
        }
        
        //don't allow more selections if already have max number
        else if CoinTableViewController.selectedCoinsIDs.count >= 16 {
            //alert the user you can only select 4 coins
            let alertController = UIAlertController(title: "Howdy, partner", message:
                    "You can only select up to 16 coins!", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(alertController, animated: true, completion: nil)
        }
        
        // if we allow this new coin to be selected
        else {
            CoinTableViewController.selectedCoinsIDs.append(coin_id)
        }
        self.tableView.reloadData()
    }
    
    
    
    // MARK: - Search Bar
    
    
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = true
        //if for some reason we are already in search mode, do not reset search results to all coins
        if !searching {
            CoinTableViewController.searchResults = coins
        }
        searching = true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        if searchText.isEmpty {
            CoinTableViewController.searchResults = coins
        } else {
            //apply filter
            var searchedCoinMap = [String: Int]()
            searchedCoinMap = CoinTableViewController.searchMap.filter { key, value in
                key.lowercased().prefix(searchText.count) == searchText.lowercased()
            }
            //now, extract all the ranks
            var searchedCoinRanks = Set<Int>()
            for (_, value) in searchedCoinMap {
                searchedCoinRanks.insert(value)
            }
            let ranksToDisplay = searchedCoinRanks.sorted()
            CoinTableViewController.searchResults = [Coin]()
            for rank in ranksToDisplay {
                CoinTableViewController.searchResults.append(coins[rank-1])
            }
        }
        self.tableView.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searching = false
        searchBar.text = ""
        //hide keyboard
        searchBar.resignFirstResponder()
        self.searchBar.showsCancelButton = false
        self.tableView.reloadData()
    }
    
    

    //MARK: - Navigation
    
    
    
    @IBAction func showAlertSettings(_ sender: UIBarButtonItem) {
        
        if alertButton.title == "Deselect All" {
            //deselect all coins
            deselectAllCoins()
        } else if alertButton.title == "Alerts" {
            //create new instance of destination view controller
            let settingsVC = storyboard?.instantiateViewController(identifier: "alertSettings") as! AlertViewController
            //naviagte to destination
            navigationController?.pushViewController(settingsVC, animated: true)
        }
    }
    
    
    
    // MARK: - Handle Coin Selection
    
    
    
    @IBAction func selectCoins(_ sender: UIBarButtonItem) {
        
        if coinSelectButton.title == "Select Coins" {
            
            //do if entering coin selection mode
            isSelecting = true
            coinSelectButton.title = "Done"
            self.tableView.allowsMultipleSelection = true
            alertButton.title = "Deselect All"
            self.tableView.reloadData()
            
        } else {
            
            //do if entering normal view mode
            isSelecting = false
            coinSelectButton.title = "Select Coins"
            self.tableView.allowsMultipleSelection = false
            alertButton.title = "Alerts"

            //save selected coins
            CoinTableViewController.selectedCoins = [Coin]()
            for coin in coins {
                if CoinTableViewController.selectedCoinsIDs.contains(coin.id) {
                    CoinTableViewController.selectedCoins.append(coin)
                }
            }
            
            //save selected coins IDs
            let defaults = UserDefaults.standard
            defaults.set(CoinTableViewController.selectedCoinsIDs, forKey:"selectedCoinIDs")
            
            //save new coins to database
            let alertFrequency = defaults.object(forKey:"alertFrequency") as? String ?? "1Day"
            saveDatabaseCoins(alertFrequency)
            
            self.tableView.reloadData()
        }
    }
    
    
    
    //MARK: - Private Methods
    
    
    
    private func askToEnableNotifications() {
        
        //ask user to enable notifications if they have not
        let alertController = UIAlertController(title: "Please enable Push Notifications!", message: "This is how we can send you price alerts for your favorite cryptos", preferredStyle: .alert)
        //add actions
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
        let notificationAction = UIAlertAction(title: "Turn On", style: .default, handler: { action in
            self.openNotificationPreferences()
        })
        alertController.addAction(notificationAction)
        alertController.preferredAction = notificationAction
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func openNotificationPreferences() {
        
        //take the user to the notification page for CoinAlert in settings
        if let bundleIdentifier = Bundle.main.bundleIdentifier, let appSettings = URL(string: UIApplication.openSettingsURLString + bundleIdentifier) {
            if UIApplication.shared.canOpenURL(appSettings) {
                UIApplication.shared.open(appSettings)
            }
        }
    }
    
    private func deselectAllCoins() {
        
        //deselect all coins and remove their IDs from the list of selected
        CoinTableViewController.selectedCoinsIDs = [Int]()
        CoinTableViewController.selectedCoins = [Coin]()
        self.tableView.reloadData()
    }
    
    private func saveDatabaseCoins(_ alertFrequency: String) {
        
        //save selected coins to the database corresponding to user token and desired alert frequency
        let userToken: String = CoinTableViewController.userToken
        let selectedCoinsIDs: [Int] = CoinTableViewController.selectedCoinsIDs
        
        var ref: DatabaseReference!
        //update saved coins in Database
        ref = Database.database().reference(withPath: "alert_info/\(alertFrequency)")
        ref!.child(userToken).setValue(selectedCoinsIDs)
    }
     
    private func loadSampleCoins() {
        
        let coin1 = Coin(rank: 1, name: "Bitcoin", symbol: "BTC", id: 1, price: 61485.78, change_7d: 0.30531848, change_24h: 0.30979578, change_1h: -0.16832789)
        let coin2 = Coin(rank: 2, name: "Bitcoin2", symbol: "BTC", id: 1, price: 61485.78, change_7d: 0.30531848, change_24h: 0.30979578, change_1h: -0.16832789)
        let coin3 = Coin(rank: 3, name: "Bitcoin3", symbol: "BTC", id: 1, price: 61485.78, change_7d: 0.30531848, change_24h: 0.30979578, change_1h: -0.16832789)
        coins += [coin1, coin2, coin3]
    }
    
    private func setupViewColors() {
        
        //Navigation bar coloring
        navigationController?.navigationBar.barTintColor = UIColor.init(red: 66/255.0, green: 66/255.0, blue: 80/255.0, alpha: 1.0)
        coinSelectButton.tintColor = UIColor.init(red: 116/255.0, green: 140/255.0, blue: 230/255.0, alpha: 1.0)
        alertButton.tintColor = UIColor.init(red: 116/255.0, green: 140/255.0, blue: 230/255.0, alpha: 1.0)
        //Navigation title coloring
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.init(red: 255/255.0, green: 215/255.0, blue: 0/255.0, alpha: 1.0)]
        //Table view background color
        self.tableView.backgroundColor = UIColor.init(red: 54/255.0, green: 54/255.0, blue: 66/255.0, alpha: 1.0)
    }
    
    
    
    // MARK: - Static Methods
    
    
    
    static func formatCoinChange(_ changeFloat: Float, _ cell: CoinTableViewCell) {
        let coinChange = "\(changeFloat)"
        if coinChange.prefix(1) == "-" {
            cell.changeLabel.text = String(coinChange.prefix(5)) + "%"
            cell.changeLabel.textColor = UIColor.systemRed
        } else {
            cell.changeLabel.text = "+" + String(coinChange.prefix(4)) + "%"
            cell.changeLabel.textColor = UIColor.systemGreen
        }
    }

    static func formatCoinPrice(_ priceFloat: Float, _ cell: CoinTableViewCell) {
        cell.priceLabel.textColor = UIColor.white
        //make string that has 2 or 3 characters after decimal place
        let coinPrice = "\(priceFloat)"
        let coinPriceStringArray = coinPrice.split(separator: ".")
        let coinPricePrefix = String(coinPriceStringArray[0])
        let coinPriceSuffix = String(coinPriceStringArray[1])
        if coinPricePrefix.count < 3 {
            cell.priceLabel.text = String("$" + coinPricePrefix + "." + coinPriceSuffix.prefix(3))
        } else {
            cell.priceLabel.text = String("$" + coinPricePrefix + "." + coinPriceSuffix.prefix(2))
        }
    }
    
    static func formatCoinRank(_ coinRank: Int, _ cell: CoinTableViewCell) {
        cell.rankLabel.textColor = UIColor.white
        cell.rankLabel.text = String(coinRank)
    }
    
    static func formatCoinName(_ coinName: String, _ cell: CoinTableViewCell) {
        cell.nameLabel.textColor = UIColor.white
        cell.nameLabel.text = coinName
    }
    
    static func formatCoinSymbol(_ coinSymbol: String, _ cell: CoinTableViewCell) {
        cell.symbolLabel.textColor = UIColor.white
        cell.symbolLabel.text = coinSymbol
    }
    
    
    
    // MARK: - Retired Methods
    
    
    
    static func backgroundProcess(_ coin_id: Int) {
        
        //fetches new database information
        singleEventDatabaseRetrieve(coin_id, { price in
            if let price = price {
                //use the return value
                backgroundNotificationPost(price)
            } else {
                //handle nil response
                backgroundNotificationPost(69.69)
            }
        })
    }
    
    static func backgroundNotificationPost(_ coin_price: Float) {
        
        //Step 1: Ask for permission
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound])
            { (granted, error) in
            //ask user to grant notification access
        }
        
        //Step 2: Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Price Alert"
        content.body = "The price is \(coin_price)"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: (5), repeats: false)
        
        //Step 4: Create the request
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
        
        //Step 5: Register request with notification center
        center.add(request) { (error) in
            //check the error parameter and handle any errors
        }
    }
    
    static func singleEventDatabaseRetrieve(_ coin_id: Int, _ completion: @escaping (Float?)->()) {
        var ref: DatabaseReference!
        //get Firebase reference
        ref = Database.database().reference(withPath: "id_to_price")
        ref!.getData { (error, snapshot) in
            if let error = error {
                print("Error getting data \(error)")
                completion(nil)
            }
            else if snapshot.exists() {
                let childSnaphot = snapshot.childSnapshot(forPath: "\(coin_id)")
                let childFloat = Float(truncating: childSnaphot.value as! NSNumber)
                completion(childFloat)
            }
            else {
                print("No data available")
                completion(nil)
            }
        }
    }
    
    private func sendNotification(_ center: UNUserNotificationCenter) {
        
        //Step 2: Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Price Alerts"
        content.body = coins[0].name + ": $" + String(coins[0].price) + "\n" + coins[1].name + ": $" + String(coins[1].price) + "\ntest" + "\ntest"
        
        //Step 3: Create the trigger
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: (20), repeats: false)
        
        //Step 4: Create the request
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
        
        //Step 5: Register request with notification center
        center.add(request) { (error) in
            //check the error parameter and handle any errors
        }
    }
    
}
