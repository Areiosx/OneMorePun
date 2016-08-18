//
//  ViewController.swift
//  One More Pun
//
//  Created by Nicholas Laughter on 12/6/15.
//  Copyright © 2015 Areios. All rights reserved.
//

import UIKit
import MessageUI
import Firebase



class ViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    let colorCollection = ColorCollection()
    var pun = Pun(body: "")
    var color = UIColor()
    var punsReadCount = 0 {
        didSet {
            if punsReadCount >= PunController.shared.punsArray.count {
                presentEndOfPunsAlert()
            }
        }
    }
    
    var retrievingFromNetwork: Bool = false {
        didSet {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = retrievingFromNetwork
        }
    }
    
    func printFonts() {
        for familyName in UIFont.familyNames() {
            print("\n-- \(familyName) \n")
            for fontName in UIFont.fontNamesForFamilyName(familyName) {
                print(fontName)
            }
        }
    }
    
    @IBOutlet weak var punLabel: UILabel!
    @IBOutlet weak var submitterLabel: UILabel!
    @IBOutlet weak var punButtonColor: UIButton!
    @IBOutlet weak var infoButtonColor: UIButton!
    @IBOutlet weak var addPunButtonColor: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        printFonts()
        
        UserController.shared.getLoggedInUser { (user) in
            if user == nil {
                self.showLoginSignUpView()
            }
        }
        
        checkUserAndReloadData()
        
        infoButtonColor.hidden = true
        addPunButtonColor.hidden = true
        
        let rate = RateMyApp.sharedInstance
        rate.appID = "1008575898"
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            rate.trackAppUsage()
        })
        
        getNewPunAndColor()
    }
    
    // MARK: - Pun Info Options
    
    @IBAction func infoButtonTapped(sender: AnyObject) {
        showPunInfoActionSheet()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        getNewPunAndColor()
    }
    
    func checkUserAndReloadData() {
        UserController.shared.checkUserAgainstDatabase { (success, error) -> Void in
            if success {
                self.punLabel.text = "Fetching puns..."
                PunController.shared.observePuns { (puns) in
                    self.retrievingFromNetwork = true
                    PunController.shared.punsArray = puns
                    dispatch_async(dispatch_get_main_queue(), {
                        self.retrievingFromNetwork = false
                        self.getNewPunAndColor()
                    })
                }
            } else {
                guard let error = error else { return }
                self.presentErrorAlert(error.localizedDescription, completion: {
                    self.showLoginSignUpView()
                })
            }
        }
    }
    
    func showLoginSignUpView() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewControllerWithIdentifier("LoginViewController") as? LoginTableViewController else { return }
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    @IBAction func nextPunButton(sender: AnyObject) {
        getNewPunAndColor()
    }
    
    @IBAction func addPunButtonTapped(sender: AnyObject) {
        presentSubmitPunAlert(nil)
    }
    
    func getNewPunAndColor() {
        pun = PunController.shared.randomPun()
        setUpColor()
        punLabel.text = pun.body
        submitterLabel.text = submitterLabelText(pun)
    }
    
    func setUpColor() {
        color = colorCollection.randomColor()
        view.backgroundColor = color
        punButtonColor.tintColor = color
        infoButtonColor.hidden = false
        infoButtonColor.tintColor = color
        addPunButtonColor.hidden = false
        addPunButtonColor.tintColor = color
    }
    
    func submitterLabelText(pun: Pun) -> String {
        if let submitter = pun.submitter {
            return "Submitted by \(submitter)"
        } else {
            return ""
        }
    }
    
    // MARK: - AlertController
    
    func presentSubmitPunAlert(storedPun: String?) {
        let alert = UIAlertController(title: "Got a pun?", message: "Submitting puns is punderful.", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (punTextField) in
            punTextField.placeholder = "Enter pun here"
            punTextField.text = storedPun
            punTextField.autocorrectionType = .Yes
            punTextField.autocapitalizationType = .Sentences
            punTextField.spellCheckingType = .Yes
        }
        let submitAction = UIAlertAction(title: "Submit", style: .Default) { (_) in
            guard let textFields = alert.textFields,
                punTextField = textFields.first,
                punText = punTextField.text where !punText.isEmpty else { return }
            self.presentSubmitPunConfirmationAlert(punText)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alert.addAction(submitAction)
        alert.addAction(cancelAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func presentSubmitPunConfirmationAlert(punBody: String) {
        let alert = UIAlertController(title: "All done?", message: "This is your pun:\n\(punBody)", preferredStyle: .Alert)
        let submitAction = UIAlertAction(title: "Looks good!", style: .Default) { (_) in
            PunController.shared.createPun(punBody)
        }
        let reEnterAction = UIAlertAction(title: "Re-enter", style: .Cancel) { (_) in
            self.presentSubmitPunAlert(punBody)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alert.addAction(submitAction)
        alert.addAction(reEnterAction)
        alert.addAction(cancelAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func presentErrorAlert(error: String, completion: (() -> Void)?) {
        let alert = UIAlertController(title: "Error!", message: error, preferredStyle: .Alert)
        let okayAction = UIAlertAction(title: "Okay", style: .Default) { (_) in
            if let completion = completion {
                completion()
            }
        }
        alert.addAction(okayAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func presentEndOfPunsAlert() {
        let alert = UIAlertController(title: "You're about to run out of puns!", message: "One More Pun only works if people like you submit puns! Tap the + to add one!", preferredStyle: .Alert)
        let submitAction = UIAlertAction(title: "Let's go!", style: .Default) { (_) in
            self.punsReadCount = 0
            self.presentSubmitPunAlert(nil)
        }
        let cancelAction = UIAlertAction(title: "No thanks", style: .Cancel) { (_) in
            self.punsReadCount = 0
        }
        alert.addAction(submitAction)
        alert.addAction(cancelAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func showPunInfoActionSheet() {
        let actionSheet = UIAlertController(title: "Options", message: nil, preferredStyle: .ActionSheet)
        let shareAction = UIAlertAction(title: "Share Pun", style: .Default) { (_) in
            self.share()
        }
        let googleAction = UIAlertAction(title: "Don't get it?", style: .Default) { (_) in
            self.openGoogleForPun()
        }
        let reportAction = UIAlertAction(title: "Report", style: .Default) { (_) in
            self.presentReportPunAlert()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        actionSheet.addAction(shareAction)
        actionSheet.addAction(googleAction)
        actionSheet.addAction(reportAction)
        actionSheet.addAction(cancelAction)
        presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    func share() {
        let point = CGPointMake(10, 10)
        let imageSize = CGSize(width: 1024, height: 1024)
        let imageWithColor = getImageWithColor(color, size: imageSize)
        let image = textToImage(PunController.getPunTextAndSubmitter(pun), inImage: imageWithColor, atPoint: point)
        let comment = "Shared via One More Pun!\n"
        guard let url = NSURL(string: "http://tinyurl.com/OneMorePun") else { return }
        
        let activityViewController = UIActivityViewController(activityItems: [image, comment, url], applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityTypeCopyToPasteboard, UIActivityTypeAirDrop, UIActivityTypeAddToReadingList, UIActivityTypeAssignToContact, UIActivityTypePostToTencentWeibo, UIActivityTypePostToVimeo, UIActivityTypePrint, UIActivityTypePostToWeibo]
        presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    func openGoogleForPun() {
        let replaced = pun.body.stringByReplacingOccurrencesOfString(" ", withString: "+")
        if let url = NSURL(string: "http://lmgtfy.com/?q=\(replaced)") {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    func presentReportPunAlert() {
        let alert = UIAlertController(title: "Report pun?", message: "Only use this feature if you want to report this pun as inappropriate or not a real pun.", preferredStyle: .Alert)
        let reportAction = UIAlertAction(title: "Report", style: .Destructive) { (_) in
            PunController.shared.reportPun(self.pun)
            self.presentPunReportedConfirmation()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alert.addAction(reportAction)
        alert.addAction(cancelAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func presentPunReportedConfirmation() {
        let alert = UIAlertController(title: "Pun Reported", message: "Your complaint has been recorded. Thank you for keeping One More Pun awesome!", preferredStyle: .Alert)
        let okayAction = UIAlertAction(title: "Okay", style: .Default, handler: nil)
        alert.addAction(okayAction)
        presentViewController(alert, animated: true, completion: nil)
    }
}

extension ViewController {
    
    // MARK: - Image Helper
    
    func getImageWithColor(color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRectMake(0, 0, size.width, size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func textToImage(drawText: NSString, inImage: UIImage, atPoint: CGPoint) -> UIImage {
        guard let font = UIFont(name: "CoolveticaRg-Regular", size: 100) else { return UIImage() }
        let textColor: UIColor = UIColor.whiteColor()
        UIGraphicsBeginImageContext(inImage.size)
        let textFontAttributes = [
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: textColor,
            ]
        inImage.drawInRect(CGRectMake(0, 0, inImage.size.width, inImage.size.height))
        let rect: CGRect = CGRectMake(atPoint.x, atPoint.y, inImage.size.width, inImage.size.height)
        drawText.drawInRect(rect, withAttributes: textFontAttributes)
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}