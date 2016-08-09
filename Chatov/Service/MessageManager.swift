//
//  MessageManager.swift
//  Chatov
//
//  Created by Pavel Diatchenko on 5/08/16.
//  Copyright © 2016 Pavel Diatchenko. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage
import RxSwift
import ObjectMapper

/// This class is communicates with the server and receives and sends messages.
class MessageManager {
    static let messagesKey = "messages"

    static let sharedInstance = MessageManager()

    var databaseReference: FIRDatabaseReference!
    var messageHandle: FIRDatabaseHandle!
    var storageReference: FIRStorageReference!
    var messages = Variable<[Message]>([])
    var tempLocalMessagesByKey = [String: Message]()

    init() {
        configureDatabase()
    }

    deinit {
        databaseReference.child(MessageManager.messagesKey).removeObserverWithHandle(messageHandle)
    }

    private func configureDatabase() {
        FIRDatabase.database().persistenceEnabled = true
        databaseReference = FIRDatabase.database().reference()

        // Bind to server
        messageHandle = databaseReference.child(MessageManager.messagesKey).observeEventType(.ChildAdded, withBlock: { [unowned self] snapshot in
            // Check if already displayed locally
            if self.tempLocalMessagesByKey[snapshot.key] != nil {
                self.tempLocalMessagesByKey[snapshot.key] = nil
            }
            else {
                // Received from server
                self.messages.value.append(MessageManager.messageFromSnapshot(snapshot))
            }
        })

        storageReference = FIRStorage.storage().referenceForURL("gs://chatov2-4e52c.appspot.com")
    }

    /**
     Sends a message to the server

     - parameter message: message
     */
    func sendMessage(message: Message) {
        let messageRef = databaseReference.child(MessageManager.messagesKey).childByAutoId()

        // Add message
        tempLocalMessagesByKey[messageRef.key] = message
        messages.value.append(message)

        // Save to cloud
        messageRef.setValue(message.toJSON())

        // Check for media
        if let unsavedImage = message.image?.value {
            // Upload image
            _ = uploadImage(unsavedImage).subscribeNext { imageUrl in
                message.imageUrl = imageUrl
                messageRef.setValue(message.toJSON())
            }
        }
    }

    /**
     Uploads an image to the server

     - parameter image: image

     - returns: the path to the image on the server in an observable
     */
    func uploadImage(image: UIImage) -> Observable<String> {
        return Observable.create { observer in
            // Resize image
            let scale = min(1024.0 / image.size.width, 1024.0 / image.size.height, 1)
            let resizedImage = self.resizeImage(image, scale: scale)

            let imageData = UIImageJPEGRepresentation(resizedImage, 0.8)
            let imagePath = "/\(Int(NSDate.timeIntervalSinceReferenceDate() * 1000)).jpg"
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            let task = self.storageReference.child(imagePath).putData(imageData!, metadata: metadata) { (metadata, error) in
                if let error = error {
                    observer.on(.Error(error))
                    return
                }

                let path = self.storageReference.child((metadata?.path)!).description
                observer.onNext(path)
                observer.onCompleted()
            }

            return AnonymousDisposable {
                task.cancel()
            }
        }
    }

    /**
     Resizes an image.
     source: http://nshipster.com/image-resizing/

     - parameter image: image
     - parameter scale: scale
     */
    func resizeImage(image: UIImage, scale: CGFloat) -> UIImage {
        if scale == 1 {
            return image.copy() as! UIImage
        }

        let size = CGSizeApplyAffineTransform(image.size, CGAffineTransformMakeScale(scale, scale))
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen

        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        image.drawInRect(CGRect(origin: CGPointZero, size: size))

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return scaledImage
    }

    /**
     Downloads an image from the server.

     - parameter imageUrl: image url

     - returns: the image in an observable
     */
    func downloadImage(imageUrl: String) -> Observable<UIImage> {
        return Observable.create { observer in
            let task = FIRStorage.storage().referenceForURL(imageUrl).dataWithMaxSize(INT64_MAX) { (data, error) in
                if let error = error {
                    observer.on(.Error(error))
                    return
                }
                if let image = UIImage(data: data!) {
                    observer.onNext(image)
                    observer.onCompleted()
                }
                else {
                    observer.on(.Error(NSError(domain: "Manager", code: 0, userInfo: nil)))
                }
            }

            return AnonymousDisposable {
                task.cancel()
            }
        }
    }

    private static func messageFromSnapshot(snapshot: FIRDataSnapshot) -> Message {
        return Mapper<Message>().map(snapshot.value)!
    }
}