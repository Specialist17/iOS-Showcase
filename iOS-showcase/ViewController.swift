//
//  ViewController.swift
//  iOS-showcase
//
//  Created by Fernando on 3/18/16.
//  Copyright © 2016 Specialist. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class ViewController: UIViewController {
    
    @IBOutlet var emailTxtField: UITextField!
    @IBOutlet var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
       emailTxtField.textColor = UIColor.yellowColor()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) != nil {
            self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
        }
        
    }
    
    @IBAction func didPressFBButton(sender: UIButton!){
        let facebookLogin = FBSDKLoginManager()
        
        facebookLogin.logInWithReadPermissions(["email"], /*This next line is an update to the method*/ fromViewController: self) {(facebookResult: FBSDKLoginManagerLoginResult!, facebookError: NSError!) -> Void in
            
            if facebookError != nil{
                print("Facebook login failed. Error \(facebookError)")
            }else{
                let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                print("Succesfully loged in with facebook. \(accessToken)")
                
                DataService.DS.REF_BASE.authWithOAuthProvider("facebook", token: accessToken, withCompletionBlock: { error, authData in
                    if error != nil{
                        print("Login failed. \(error)")
                    } else {
                        print("Logged in \(authData)")
                        
                        let user = ["provider": authData.provider!, "blah!":"test"]
                        DataService.DS.createFirebaseUser(authData.uid, user: user)
                        
                        NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: KEY_UID)
                        self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                    }
                })
            }
        }
    }
    
    @IBAction func emailLoginBtnPressed(sender: UIButton!){
        if let email = emailTxtField.text where email != "",
            let pwd = passwordField.text where pwd != ""{
                
                DataService.DS.REF_BASE.authUser(email, password: pwd, withCompletionBlock: { error, authData in
                    if error != nil {
                        print(error)
                        
                        if error.code == STATUS_ACCOUNT_NOT_EXISTS {
                            self.showErrorAlert(title: "Wrong email or password", message: "Please verify your email and password")
                        } else if error.code == STATUS_PASSWORD_INCORRECT {
                            self.showErrorAlert(title: "Wrong email or password", message: "Please verify your email and password")
                        }
                        
                        
                    } else {
                        NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: KEY_UID)
                        self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                    }
                })
                
        } else {
            showErrorAlert(title: "Email and Password required", message: "You must enter an email and password")
        }
    }
    
    @IBAction func emailSignUpBtnPressed (sender: UIButton!){
        if let email = emailTxtField.text where email != "",
            let pwd = passwordField.text where pwd != ""{
                
                DataService.DS.REF_BASE.createUser(email, password: pwd, withValueCompletionBlock: { error, result in
                    
                    if error != nil {
                        if error.code == -9 {
                            self.showErrorAlert(title: "Could not create account", message: "An account with this email already exists")
                        } else {
                            print(error)
                            
                        }
                        
                    }
                    else {
                        DataService.DS.REF_BASE.authUser(email, password: pwd, withCompletionBlock: { error, authData in
                            let user = ["provider": authData.provider!, "blah!":"emailTest"]
                            DataService.DS.createFirebaseUser(authData.uid, user: user)
                        })
                        self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                        NSUserDefaults.standardUserDefaults().setValue(result[KEY_UID], forKey: KEY_UID)
                    }
                    
                })
                
                
        } else {
            showErrorAlert(title: "Email and password required", message: "You must enter an email and password to create an account")
        }
        
    }
    
    func showErrorAlert(title title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
        
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
        
    }
    
    //closes the keyboard when touching on main view
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    //function to close the keyboard when pressing on "return"
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}

