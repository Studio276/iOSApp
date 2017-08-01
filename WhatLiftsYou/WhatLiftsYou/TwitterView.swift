//
//  TwitterView.swift
//  WhatLiftsYou
//
//  Created by Thomas Pearson on 2/21/17.
//  Copyright © 2017 WhatLiftsYou. All rights reserved.
//

protocol TwitterViewDelegate {
    func sendTweet(button:UIButton)
    func cancelTweet(button:UIButton)
}

import Foundation
class TwitterView: UIView, UITextViewDelegate {
    
    var delegate:TwitterViewDelegate!
    private var _tweet:String?
    var tweet:String{
        
        get{
            return _tweet!
        }
        
        set(string){
            
            _tweet = string;
        }
    }
    
    @IBOutlet weak var cancelButton: UIButton!{
        
        didSet{
//            cancelButton.layer.borderColor = UIColor.darkGray.cgColor
//            cancelButton.layer.borderWidth = 1
//            cancelButton.layer.cornerRadius = 10
//            cancelButton.backgroundColor = UIColor.lightGray
        }
    }
    
    @IBAction func onCancelClick(_ sender: Any) {
        delegate.cancelTweet(button: sender as! UIButton)
    }
    
    @IBOutlet weak var twitterTextView: UITextView!
    
    @IBOutlet weak var sendButton: UIButton!{
        
        didSet{
//            sendButton.layer.borderColor = UIColor.darkGray.cgColor
//            sendButton.layer.borderWidth = 1
//            sendButton.layer.cornerRadius = 10
//            sendButton.backgroundColor = UIColor.lightGray
        }
    }
    @IBAction func onSendClick(_ sender: Any) {
        delegate.sendTweet(button: sender as! UIButton)
    }
    
    
    @IBOutlet weak var tweetText: UITextView!{
        
        didSet{
            tweetText.delegate = self
        }
    }
    
    @IBOutlet weak var characterCountTextView: UILabel!{
        
        didSet{
            characterCountTextView.textColor = UIColor.darkGray
        }
    }
    
    override init(frame: CGRect) {
        
        super.init(frame:frame);
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit(){
        
        self.layer.cornerRadius = 20
        self.frame = CGRect(x: 20, y: 100, width: UIScreen.main.bounds.size.width - 40, height: UIScreen.main.bounds.size.height - 390)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(_ notification:Notification){
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            print(keyboardSize.height)
            self.frame = CGRect(x: 20, y: 70, width: UIScreen.main.bounds.size.width - 40, height: UIScreen.main.bounds.size.height - 390)
        }
    }
    
    @objc func keyboardWillHide(_ notification:Notification){
        
        self.frame = CGRect(x: 20, y: 100, width: UIScreen.main.bounds.size.width - 40, height: UIScreen.main.bounds.size.height - 200)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        return tweetText.text.characters.count < 144
        //return tweetText.text.characters.count + (tweetText.text.characters.count - range.length) <= 144
    }
    
    func textViewDidChange(_ textView: UITextView){
        
        characterCountTextView.text = String(144 - tweetText.text.characters.count )
    }
}
