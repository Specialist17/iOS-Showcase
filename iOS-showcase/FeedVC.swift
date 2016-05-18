//
//  FeedVC.swift
//  iOS-showcase
//
//  Created by Fernando on 3/19/16.
//  Copyright © 2016 Specialist. All rights reserved.
//

import UIKit
import Firebase
import Alamofire

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet var feedTable: UITableView!
    @IBOutlet var imageSelectorImg: UIImageView!
    @IBOutlet var postField: MaterialTextField!
    
    var activityInd = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
    var photoImg = UIImage(named: "camera.png")!
    var posts = [Post]()
    static var imageCache = NSCache()
    var imagePicker: UIImagePickerController!
    var imageSelected: Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        feedTable.delegate = self
        feedTable.dataSource = self
        feedTable.estimatedRowHeight = 335
        
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self

        DataService.DS.REF_POSTS.observeEventType(.Value, withBlock: {snapshot in
            print(snapshot.value)
            
            self.posts = []
            if let snapshots = snapshot.children.allObjects as? [FDataSnapshot]{
                for snap in snapshots {
                    print("Snap: \(snap)")
                    
                    if let postDict = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        let post = Post(postKey: key, dictionary: postDict)
                        self.posts.append(post)
                    }
                
                }
                
            }
            
            self.feedTable.reloadData()
        })
        self.view.addSubview(self.activityInd)
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let post = posts[indexPath.row]
        print(post.postDescription)
        
        if let cell = feedTable.dequeueReusableCellWithIdentifier("PostCell") as? PostCell {
            cell.request?.cancel()
            var img: UIImage?
            
            if let url = post.imageUrl {
                img = FeedVC.imageCache.objectForKey(url) as? UIImage
            }
            
            cell.configureCell(post, img: img)
            return cell
        }else{
            return PostCell()
        }
    }

    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let post = posts[indexPath.row]
        if post.imageUrl == nil {
            return 170
        } else {
            return feedTable.estimatedRowHeight
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        imageSelectorImg.image = image
        imageSelected = true
    }
    
    @IBAction func selectImage(sender: UITapGestureRecognizer) {
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func makePost(sender: AnyObject) {
        
        if let txt = postField.text where txt != ""{
        
            if let img = imageSelectorImg.image where imageSelected == true{
                let urlStr = "https://post.imageshack.us/upload_api.php"
                let url = NSURL(string: urlStr)!
                let imgData = UIImageJPEGRepresentation(img, 2.0)!
                let keyData = "SMK14ZTU3cee1f1eb197d4172c97c0293c3308b9".dataUsingEncoding(NSUTF8StringEncoding)!
                let keyJSON = "json".dataUsingEncoding(NSUTF8StringEncoding)!
                
                Alamofire.upload(.POST, url, multipartFormData: { multipartFormData in
                    self.activityInd.startAnimating()
                    
                    //the multipart form is used because the image has a different format than the rest of the json
                    multipartFormData.appendBodyPart(data: imgData, name: "fileupload", fileName: "image", mimeType: "image/jpeg")
                    multipartFormData.appendBodyPart(data: keyData, name: "key")
                    multipartFormData.appendBodyPart(data: keyJSON, name: "format")
                    
                    }) { encodingResult in
                        
                        switch encodingResult{
                        case .Success(let upload, _, _):
                            upload.responseJSON(completionHandler: { response in
                                if let info = response.result.value as? Dictionary<String,AnyObject>{
                                    if let links = info["links"] as? Dictionary<String,AnyObject>{
                                        if let imgLink = links["image_link"] as? String{
                                            print("LINK: \(imgLink)")
                                            self.postToFirebase(imgLink)
                                            self.activityInd.stopAnimating()
                                        }
                                    }
                                }
                            })
                        case .Failure(let error):
                            print(error)
                        }
                        
                }
            }else{
                self.postToFirebase(nil)
            }
        }
    }
    
    func postToFirebase(imgUrl: String?){
        var post: Dictionary<String,AnyObject> = [
            "description": postField.text!,
            "likes": 0
        ]
        
        if imgUrl != nil{
            post["imageUrl"] = imgUrl!
        }
        
        let firebasePost = DataService.DS.REF_POSTS.childByAutoId()
        firebasePost.setValue(post)
        
        postField.text = ""
        imageSelectorImg.image = UIImage(named: "camera")
        imageSelected = false
        
        feedTable.reloadData()
        
    }
    
}
