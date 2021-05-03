//
//  Coin.swift
//  CoinAlert
//
//  Created by Andrew Sorenson on 4/17/21.
//

import UIKit

class Coin {
    
    // MARK: NS Stuff

    
//    func encode(with coder: NSCoder) {
//        print("encode")
//        coder.encode(rank, forKey: "rank")
//        coder.encode(name, forKey: "name")
//        coder.encode(symbol, forKey: "symbol")
//        coder.encode(id, forKey: "id")
//        coder.encode(price, forKey: "price")
//        coder.encode(change_7d, forKey: "change_7d")
//        coder.encode(change_24h, forKey: "change_24h")
//        coder.encode(change_1h, forKey: "change_1h")
//    }
//
//    required convenience init?(coder: NSCoder) {
//        print("decode")
//        guard   let rank = coder.decodeObject(forKey: "rank") as? Int,
//                let name = coder.decodeObject(forKey: "name") as? String,
//                let symbol = coder.decodeObject(forKey: "symbol") as? String,
//                let id = coder.decodeObject(forKey: "id") as? Int,
//                let price = coder.decodeObject(forKey: "price") as? Float,
//                let change_7d = coder.decodeObject(forKey: "change_7d") as? Float,
//                let change_24h = coder.decodeObject(forKey: "change_24h") as? Float,
//                let change_1h = coder.decodeObject(forKey: "change_1h") as? Float
//        else { return nil }
//
//        self.init(rank: rank, name: name, symbol: symbol, id: id, price: price, change_7d: change_7d, change_24h: change_24h, change_1h: change_1h)
//
//    }
    
    
    
    //MARK: Properties
    
    var rank: Int
    var name: String
    var symbol: String
    var id: Int
    var price: Float
    var change_7d: Float
    var change_24h: Float
    var change_1h: Float

    
    //MARK: Initialization
    
    
    init() {
        self.rank = 0
        self.name = ""
        self.symbol = ""
        self.id = 0
        self.price = 0
        self.change_7d = 0
        self.change_24h = 0
        self.change_1h = 0
    }
    
     
    init(rank: Int, name: String, symbol: String, id: Int, price: Float, change_7d: Float, change_24h: Float, change_1h: Float) {
        
        // Initialize stored properties.
        self.rank = rank
        self.name = name
        self.symbol = symbol
        self.id = id
        self.price = price
        self.change_7d = change_7d
        self.change_24h = change_24h
        self.change_1h = change_1h
        
        
    }
    
    
    // MARK: Static Methods
    
//    static func storeSavedCoins(_ savedCoins: [Coin]) {
//        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("selectedCoins")
//        do {
//            let data = try NSKeyedArchiver.archivedData(withRootObject: savedCoins, requiringSecureCoding: false)
//            try data.write(to: path)
//            print("saved")
//        } catch {
//            print("ERROR: \(error.localizedDescription)")
//        }
//
//    }
//
//
//
//    static func retrieveSavedCoins() -> [Coin] {
//        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("selectedCoins")
//        do {
//            print("1")
//            let data = try Data(contentsOf: path)
//            print("2")
//            let selectedCoins = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [Coin] ?? [Coin]()
//            print("returning nil")
//            return selectedCoins
//        } catch {
//            print("couldn't retrieve" + "ERROR: \(error.localizedDescription)")
//        }
//        print("here2")
//        return [Coin]()
//    }
    
    
}
