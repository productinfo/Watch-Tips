//
//  InterfaceController.swift
//  tips WatchKit Extension
//
//  Created by Stephen Rogers on 13/02/2017
//

import WatchKit
import WatchConnectivity
import Foundation


class InterfaceController: WKInterfaceController, WCSessionDelegate, WKCrownDelegate {

    
    var tipAmount: Int = 10
    var splitBetween: Int = 1
    var billTotal = Double(0)
    var focusButton: Int = 0
    var accumulatedCrownDelta = 0.0


    
    @IBOutlet var currentTip: WKInterfaceButton!
    @IBOutlet var currentTotal: WKInterfaceLabel!
    @IBOutlet var currentSplit: WKInterfaceButton!
    @IBOutlet var costEach: WKInterfaceLabel!
    @IBOutlet var withTip: WKInterfaceLabel!
    @IBOutlet var billButton: WKInterfaceButton!
    
    override init() {
        super.init()
    }

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        if #available(watchOS 3.0, *) {
            crownSequencer.delegate = self
        }
        updateCalc()
    }

    override func willActivate() {
        super.willActivate()
        if WCSession.isSupported() {
            let session = WCSession.default()
            session.delegate = self
            session.activate()
        }
        if #available(watchOS 3.0, *) {
            crownSequencer.focus()
        }
        updateCalc()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }

    @available(watchOS 2.2, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // This will be called when the activation of a session finishes.
    }
    
    
    
    @available(watchOSApplicationExtension 3.0, *)
    func crownDidBecomeIdle(_ crownSequencer: WKCrownSequencer?) {
        accumulatedCrownDelta = 0.0
    }
    
    @available(watchOSApplicationExtension 3.0, *)
    func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {

        accumulatedCrownDelta += rotationalDelta
        
        let threshold = 0.05
    
        // do nothing if delta is less that threshold
        guard abs(accumulatedCrownDelta) > threshold else {
            return
        }
        
        if focusButton == 1 {
            if accumulatedCrownDelta > 0 {
                splitBetween += 1
            } else {
                splitBetween -= 1
            }
            if splitBetween < 1 {
                splitBetween = 1
            }
            if splitBetween > 50 {
                splitBetween = 50
            }
        }
            
        if focusButton == 2 {
            if accumulatedCrownDelta > 0 {
                tipAmount += 1
            } else {
                tipAmount -= 1
            }
            if tipAmount < 0 {
                tipAmount = 0
            }
            if tipAmount > 100 {
                tipAmount = 100
            }
        }

        accumulatedCrownDelta = 0
        updateCalc()

        
    }
    
    // show the Split Controller
    @IBAction func showSplitController() {
        if #available(watchOS 3.0, *) {
            resetButtonFocus()
            currentSplit?.setBackgroundColor(UIColor(red: 0/255, green: 128/255, blue: 255/255, alpha: 1.0))
            focusButton = 1
            
        } else {
            presentController(withName: "SplitController", context: self)
        }

    }
    
    
    // show the Tip controller
    @IBAction func showTipController() {
        if #available(watchOS 3.0, *) {
            resetButtonFocus()
            currentTip?.setBackgroundColor(UIColor(red: 0/255, green: 128/255, blue: 255/255, alpha: 1.0))
            focusButton = 2
        } else {
            presentController(withName: "TipController", context: self)
        }
    }
    
    
    // reset the focus to the currently selected button
    func resetButtonFocus(){
        focusButton = 0
        currentSplit?.setBackgroundColor(UIColor.darkGray)
        currentTip?.setBackgroundColor(UIColor.darkGray)
        billButton?.setBackgroundColor(UIColor.darkGray)
    }
    
    
    // Show the Bill Controller
    @IBAction func showBillController() {
        resetButtonFocus()
        presentController(withName: "BillController", context: self)
    }
    
    /** testing various message sending processes
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let status = applicationContext["status"] as? String {
            currentTip.setTitle(status)
        } else {
            currentTip.setTitle("NOSTAT")
            
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        currentTip.setTitle("MSGRLPY")
    }

    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        currentTip.setTitle("MSGDATA")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        currentTip.setTitle("MSGNOR")
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        if let data = userInfo["data"] as? String {
            currentTip.setTitle(data)
        } else {
            currentTip.setTitle("NOUINF")
            
        }
    }
     **/

    // Update the actual calculations
    func updateCalc(){
        
        // do bill calculations
        let tip = (billTotal/100) * Double(tipAmount)
        let billWithTip = billTotal + tip
        let perPerson = billWithTip / Double(splitBetween)
        
        // update display
        currentTip.setTitle("\(tipAmount)%")
        currentSplit.setTitle("\(splitBetween)")
        currentTotal.setText(String(format: "%.2f", billTotal))
        withTip.setText(String(format: "%.2f", billWithTip))
        costEach.setText(String(format: "%.2f", perPerson))
        
        // now see if we can sent the calc data back to the app
        if WCSession.isSupported() {
            let session = WCSession.default()
            let calcInfo = [
                "tip":"\(tipAmount)",
                "split": "\(splitBetween)",
                "bill": "\(billTotal)"
            ] as [String : Any];
            session.transferUserInfo(calcInfo)
        }
    }

    
}
