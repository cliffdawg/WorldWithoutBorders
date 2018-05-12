//
//  ConversationsViewController.swift
//  WorldWithoutBorders
//
//  Created by Clifford Yin on 2/11/18.
//  Copyright © 2018 Clifford Yin. All rights reserved.
//

import Foundation
import MessageKit
import Firebase
import IQKeyboardManagerSwift
import BulletinBoard
import NVActivityIndicatorView
import Hero

protocol RemoveTapDelegate {
    func removeTap()
}

/* Controller that represents the chat component of the home view */
class ConversationViewController: MessagesViewController, RefreshControllerDelegate, ResponseDelegate, UITextFieldDelegate {
    
    // MARK: Properties
    
    // Store messages in here
    var messageList: [Message] = []
    var isTyping = false
    let refreshControl = UIRefreshControl()
    var loadCounter = 0
    
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var sendMessage: UIButton!
    @IBOutlet weak var message: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        CloudCalls.sharedInstance.delegate = self
        var messagesToFetch = 0
        if (SampleData.shared.messages.count > 9) {
            messagesToFetch = 10
        } else {
            messagesToFetch = SampleData.shared.messages.count
        }
        
        // Initial loading indicator
        let frame = CGRect(x: self.view.frame.midX - 60, y: self.view.frame.midY - 60, width: 120, height: 120)
        let activity = NVActivityIndicatorView(frame: frame, type: NVActivityIndicatorType(rawValue: 30), color: .blue, padding: nil)
        self.view.addSubview(activity)
        activity.startAnimating()
        let when = DispatchTime.now() + 4
        // Load messages
        DispatchQueue.global(qos: .userInitiated).async {
            SampleData.shared.getMessages(count: messagesToFetch) { messages in
                DispatchQueue.main.async {
                    activity.stopAnimating()
                    self.messageList = messages
                    self.messagesCollectionView.reloadData()
                    self.messagesCollectionView.scrollToBottom()
                }
            }
        }
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.alpha = 0.0
        scrollsToBottomOnKeybordBeginsEditing = true // default false
        // Enable refreshing
        messagesCollectionView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(ConversationViewController.loadMoreMessages), for: .valueChanged)
        self.view.bringSubview(toFront: toolBar)
        message.delegate = self
    }
    
    // MARK: IBOutlets/Actions
    
    // The action to send a message
    @IBAction func sendMessage(_ sender: Any) {
        if ((CurrentChat.sharedInstance.convoID != "") && ((message.text?.trimmingCharacters(in: .whitespaces).isEmpty)! == false)) {
            CloudCalls.sharedInstance.runCommand(action: "sendMessage", params: ["displayName": (CurrentUser.sharedInstance.user.profile.name!), "photoUrl": (CurrentUser.sharedInstance.urled!), "recipientUID": CurrentChat.sharedInstance.otherUser, "text": message.text])
            message.endEditing(true)
            message.text = ""
            sendMessage.isEnabled = false
        } else {
            //Use Whisper to notify need message
        }
    }
    
    // Have to re-instantiate data with every message, if observeSingle
    func response(success: String) {
        if success == "sendMessage" {
            let when = DispatchTime.now() + 1
            DispatchQueue.main.asyncAfter(deadline: when) {
                SampleData.shared.instantiate(CurrentChat.sharedInstance.convoID)
                }
            refresh()
            sendMessage.isEnabled = true
            loadCounter = 1
        } else if success == "fail" {
            print("Operation failed")
        }
    }
    
    // Reloads messages after one is sent
    func reloadAfterSend() {
        print("reloadAfterSend")
        DispatchQueue.global(qos: .userInitiated).async {
            SampleData.shared.getMessages(count: self.messageList.count) { messages in
                DispatchQueue.main.async {
                    self.messageList = messages
                    self.messagesCollectionView.reloadData()
                    self.messagesCollectionView.scrollToBottom()
                }
            }
        }
    }
    
    func textFieldDidBeginEditing(_ message: UITextField) {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ConversationViewController.dismissKeyboard))
        self.view.addGestureRecognizer(tap)
        
    }
    
    @objc
    func dismissKeyboard(_ sender: Any) {
        message.endEditing(true)
        self.view.gestureRecognizers?.removeAll()
    }
    
    @objc func handleTyping() {
        defer {
            isTyping = !isTyping
        }
        if isTyping {
            messageInputBar.topStackView.arrangedSubviews.first?.removeFromSuperview()
            messageInputBar.topStackViewPadding = .zero
        } else {
            let label = UILabel()
            label.text = "typing..."
            label.font = UIFont.boldSystemFont(ofSize: 16)
            messageInputBar.topStackView.addArrangedSubview(label)
            messageInputBar.topStackViewPadding.top = 6
            messageInputBar.topStackViewPadding.left = 12
            messageInputBar.backgroundColor = messageInputBar.backgroundView.backgroundColor
        }
    }
    
    // Refresh the messages.
    // If more than 10 messages available, load 10, otherwise load what is left
    func refresh() {
        let frame = CGRect(x: self.view.frame.midX - 60, y: self.view.frame.midY - 60, width: 120, height: 120)
        let activity = NVActivityIndicatorView(frame: frame, type: NVActivityIndicatorType(rawValue: 30), color: .blue, padding: nil)
        self.view.addSubview(activity)
        activity.startAnimating()
        let when = DispatchTime.now() + 4
        DispatchQueue.main.asyncAfter(deadline: when) {
            activity.stopAnimating()
        }
        
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: DispatchTime.now() + 4) {
            var messagesToFetch = 0
            if (SampleData.shared.messages.count > 9) {
                messagesToFetch = 10
            } else {
                messagesToFetch = SampleData.shared.messages.count
            }
            SampleData.shared.getMessages(count: messagesToFetch) { messages in
                DispatchQueue.main.async {
                    self.messageList = messages
                    self.messagesCollectionView.reloadData()
                    self.messagesCollectionView.scrollToBottom()
                }
            }
        }
    }
    
    // On a refresh attempt, load additional messages
    // When a messages is added, [recent -> later] shift
    @objc func loadMoreMessages() {
        let frame = CGRect(x: self.view.frame.midX - 60, y: self.view.frame.midY - 60, width: 120, height: 120)
        let activity = NVActivityIndicatorView(frame: frame, type: NVActivityIndicatorType(rawValue: 30), color: .blue, padding: nil)
        self.view.addSubview(activity)
        activity.startAnimating()
        let when = DispatchTime.now() + 4
        DispatchQueue.main.asyncAfter(deadline: when) {
            activity.stopAnimating()
        }
        DispatchQueue.global(qos: .userInitiated).async {
            SampleData.shared.getMessages(count: self.messageList.count) { messages in
                DispatchQueue.main.async {
                    self.messageList = messages
                    self.load()
                    self.messagesCollectionView.reloadData()
                }
            }
        }
    }
    
    // If more than 10 messages available, load 10, otherwise load what is left
    func load() {
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: DispatchTime.now() + 4) {
            var fetch = 0
            if(SampleData.shared.messages.count - self.messageList.count > 9) {
                fetch = 10
            } else {
                fetch = SampleData.shared.messages.count - self.messageList.count
            }
            SampleData.shared.fifoMessages(count: fetch, index: self.messageList.count) { messages in
                DispatchQueue.main.async {
                    self.messageList.insert(contentsOf: messages, at: 0)
                    self.messagesCollectionView.reloadDataAndKeepOffset()
                    self.refreshControl.endRefreshing()
                }
            }
        }
    }
    
    // MARK: MessageKit functions/demo data source
    
    @objc func handleKeyboardButton() {
        
        messageInputBar.inputTextView.resignFirstResponder()
        let actionSheetController = UIAlertController(title: "Change Keyboard Style", message: nil, preferredStyle: .actionSheet)
        let actions = [
            UIAlertAction(title: "Slack", style: .default, handler: { _ in
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: {
                    self.slack()
                })
            }),
            UIAlertAction(title: "iMessage", style: .default, handler: { _ in
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: {
                    self.iMessage()
                })
            }),
            UIAlertAction(title: "Default", style: .default, handler: { _ in
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: {
                    self.defaultStyle()
                })
            }),
            UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        ]
        actions.forEach { actionSheetController.addAction($0) }
        actionSheetController.view.tintColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
        present(actionSheetController, animated: true, completion: nil)
    }
    
    // MARK: - Keyboard Style
    func slack() {
        defaultStyle()
        messageInputBar.backgroundView.backgroundColor = .white
        messageInputBar.isTranslucent = false
        messageInputBar.inputTextView.backgroundColor = .clear
        messageInputBar.inputTextView.layer.borderWidth = 0
        let items = [
            makeButton(named: "ic_camera").onTextViewDidChange { button, textView in
                button.isEnabled = textView.text.isEmpty
            },
            makeButton(named: "ic_at").onSelected {
                $0.tintColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
                print("@ Selected")
            },
            makeButton(named: "ic_hashtag").onSelected {
                $0.tintColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
                print("# Selected")
            },
            .flexibleSpace,
            makeButton(named: "ic_library").onTextViewDidChange { button, textView in
                button.tintColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
                button.isEnabled = textView.text.isEmpty
            },
            messageInputBar.sendButton
                .configure {
                    $0.layer.cornerRadius = 8
                    $0.layer.borderWidth = 1.5
                    $0.layer.borderColor = $0.titleColor(for: .disabled)?.cgColor
                    $0.setTitleColor(.white, for: .normal)
                    $0.setTitleColor(.white, for: .highlighted)
                    $0.setSize(CGSize(width: 52, height: 30), animated: true)
                }.onDisabled {
                    $0.layer.borderColor = $0.titleColor(for: .disabled)?.cgColor
                    $0.backgroundColor = .white
                }.onEnabled {
                    $0.backgroundColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
                    $0.layer.borderColor = UIColor.clear.cgColor
                }.onSelected {
                    // We use a transform becuase changing the size would cause the other views to relayout
                    $0.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                }.onDeselected {
                    $0.transform = CGAffineTransform.identity
            }
        ]
        items.forEach { $0.tintColor = .lightGray }
        
        // We can change the container insets if we want
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
        
        // Since we moved the send button to the bottom stack lets set the right stack width to 0
        messageInputBar.setRightStackViewWidthConstant(to: 0, animated: true)
        
        // Finally set the items
        messageInputBar.setStackViewItems(items, forStack: .bottom, animated: true)
    }
    
    func iMessage() {
        defaultStyle()
        messageInputBar.isTranslucent = false
        messageInputBar.backgroundView.backgroundColor = .white
        messageInputBar.separatorLine.isHidden = true
        messageInputBar.inputTextView.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
        messageInputBar.inputTextView.placeholderTextColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 36)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 36)
        messageInputBar.inputTextView.layer.borderColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1).cgColor
        messageInputBar.inputTextView.layer.borderWidth = 1.0
        messageInputBar.inputTextView.layer.cornerRadius = 16.0
        messageInputBar.inputTextView.layer.masksToBounds = true
        messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        messageInputBar.setRightStackViewWidthConstant(to: 36, animated: true)
        messageInputBar.setStackViewItems([messageInputBar.sendButton], forStack: .right, animated: true)
        messageInputBar.sendButton.imageView?.backgroundColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
        messageInputBar.sendButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        messageInputBar.sendButton.setSize(CGSize(width: 36, height: 36), animated: true)
        messageInputBar.sendButton.image = #imageLiteral(resourceName: "ic_up")
        messageInputBar.sendButton.title = nil
        messageInputBar.sendButton.imageView?.layer.cornerRadius = 16
        messageInputBar.sendButton.backgroundColor = .clear
        messageInputBar.textViewPadding.right = -38
    }
    
    func defaultStyle() {

    }
    
    // MARK: - Helpers
    
    func makeButton(named: String) -> InputBarButtonItem {
      
        return InputBarButtonItem()
            .configure {
                $0.spacing = .fixed(10)
                $0.image = UIImage(named: named)?.withRenderingMode(.alwaysTemplate)
                $0.setSize(CGSize(width: 30, height: 30), animated: true)
            }.onSelected {
                $0.tintColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
            }.onDeselected {
                $0.tintColor = UIColor.lightGray
            }.onTouchUpInside { _ in
        }
    }
}

// MARK: - MessagesDataSource
extension ConversationViewController: MessagesDataSource {
    
    func currentSender() -> Sender {
        return SampleData.shared.currentSender
    }
    
    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageList.count
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messageList[indexPath.section]
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }
    
    // IMPLEMENT THE DATE COMPONENT FOR THESE MESSAGES
//    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
//        // Date!
//        return NSAttributedString(string: date, attributes: [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption1)])
//    }
    
}

// MARK: - MessagesDisplayDelegate
extension ConversationViewController: MessagesDisplayDelegate {
    
    // MARK: - Text Messages
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .white
    }
    
    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedStringKey : Any] {
        return MessageLabel.defaultAttributes
    }
    
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .date]
    }
    
    // MARK: - All Messages
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1) : UIColor(red: 0/255, green: 166/255, blue: 228/255, alpha: 1)
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
    
    func configureAvatarView(avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let avatar = SampleData.shared.getAvatarFor(sender: message.sender)
        avatarView.set(avatar: avatar)
    }
    
    func animationBlockForLocation(message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> ((UIImageView) -> Void)? {
        return { view in
            view.layer.transform = CATransform3DMakeScale(0, 0, 0)
            view.alpha = 0.0
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [], animations: {
                view.layer.transform = CATransform3DIdentity
                view.alpha = 1.0
            }, completion: nil)
        }
    }
}

// MARK: - MessagesLayoutDelegate
extension ConversationViewController: MessagesLayoutDelegate {
    
    func avatarPosition(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> AvatarPosition {
        return AvatarPosition(horizontal: .natural, vertical: .messageBottom)
    }
    
    func avatar(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> Avatar {
        let avatar = SampleData.shared.getAvatarFor(sender: message.sender)
        return avatar
    }
    
    // Handles lateral spacing of messages
    func messagePadding(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIEdgeInsets {
   
        if isFromCurrentSender(message: message) {
            return UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 4)
        } else {
            return UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 30)
        }
    }
    
    func cellTopLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment {
      
        if isFromCurrentSender(message: message) {
            return .messageTrailing(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10))
        } else {
            return .messageLeading(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0))
        }
    }
    
    func cellBottomLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment {
        
        if isFromCurrentSender(message: message) {
            return .messageLeading(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0))
        } else {
            return .messageTrailing(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10))
        }
    }
    
    func footerViewSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        // Adds a spacing to balance initial offset
        if ((indexPath.section == messageList.count - 1) && (loadCounter == 0)) {
            return CGSize(width: messagesCollectionView.bounds.width, height: 60)
        } else {
            return CGSize(width: messagesCollectionView.bounds.width, height: 10)
        }
    }
    
    // MARK: - Location Messages
    func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 200
    }
}

// MARK: - MessageCellDelegate
extension ConversationViewController: MessageCellDelegate {
    
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("Avatar tapped")
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("Message tapped")
    }
    
    func didTapTopLabel(in cell: MessageCollectionViewCell) {
        print("Top label tapped")
    }
    
    func didTapBottomLabel(in cell: MessageCollectionViewCell) {
        print("Bottom label tapped")
    }
    
}

// MARK: - MessageLabelDelegate
extension ConversationViewController: MessageLabelDelegate {
    
    func didSelectAddress(_ addressComponents: [String : String]) {
        print("Address Selected: \(addressComponents)")
    }
    
    func didSelectDate(_ date: Date) {
        print("Date Selected: \(date)")
    }
    
    func didSelectPhoneNumber(_ phoneNumber: String) {
        print("Phone Number Selected: \(phoneNumber)")
    }
    
    func didSelectURL(_ url: URL) {
        print("URL Selected: \(url)")
    }
    
}

// MARK: - MessageInputBarDelegate
extension ConversationViewController: MessageInputBarDelegate {
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        inputBar.inputTextView.text = String()
        messagesCollectionView.scrollToBottom()
    }
    
}
