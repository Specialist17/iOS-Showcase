//
//  PostCell.swift
//  iOS-showcase
//
//  Created by Fernando on 3/19/16.
//  Copyright © 2016 Specialist. All rights reserved.
//

import UIKit
import Alamofire
import Firebase

class PostCell: UITableViewCell {
    @IBOutlet var profileImg: UIImageView!
    @IBOutlet var showcaseImg: UIImageView!
    @IBOutlet var descriptionText: UITextView!
    @IBOutlet var likesLbl: UILabel!
    @IBOutlet weak var likeImg: UIImageView!
    
    var post: Post!
    var request: Request?
    var likeRef: Firebase!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tap = UITapGestureRecognizer(target: self, action: "likeTapped:")
        tap.numberOfTapsRequired = 1
        likeImg.addGestureRecognizer(tap)
        likeImg.userInteractionEnabled = true
    }
    
    override func drawRect(rect: CGRect) {
        profileImg.layer.cornerRadius = profileImg.frame.size.width/2
        profileImg.clipsToBounds = true
        
        showcaseImg.clipsToBounds = true
    }

    func configureCell(post: Post, img: UIImage?) {
        self.post = post
        likeRef = DataService.DS.REF_USER_CURRENT.childByAppendingPath("likes").childByAppendingPath(post.postkey)
        self.descriptionText.text = post.postDescription
        self.likesLbl.text = "\(post.likes)"
        
        if post.imageUrl != nil {
            
            if img != nil {
                self.showcaseImg.image = img
            } else {
                
                request = Alamofire.request(.GET, post.imageUrl!).validate(contentType: ["image/*"]).response(completionHandler: { request, response, data, error in
                    if error == nil {
                        let img = UIImage(data: data!)!
                        self.showcaseImg.image = img
                        FeedVC.imageCache.setObject(img, forKey: self.post.imageUrl!)
                    }
                })
                
            }
            
        } else {
            self.showcaseImg.hidden = true
        }
        
        // See if you can find this like. If it exists, show the heart, otherwise, hide it
        likeRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            //In firebase, if there's no data in value (if it doen't exist), you get an NSNull
            if let doesNotExist = snapshot.value as? NSNull {
                //This means we haven't liked the post
                self.likeImg.image = UIImage(named: "heart-empty")
            } else {
                self.likeImg.image = UIImage(named: "heart-full")
            }
        })
    }
    
    func likeTapped(sender: UITapGestureRecognizer){
        likeRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            //In firebase, if there's no data in value (if it doen't exist), you get an NSNull
            if let doesNotExist = snapshot.value as? NSNull {
                
                //This means we haven't liked the post
                self.likeImg.image = UIImage(named: "heart-full")
                self.post.adjustLikes(true)
                self.likeRef.setValue(true)
            } else {
                self.likeImg.image = UIImage(named: "heart-empty")
                self.post.adjustLikes(false)
                self.likeRef.removeValue()
            }
        })
    }
}
