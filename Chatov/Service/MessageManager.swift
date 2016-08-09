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

        storageReference = FIRStorage.storage().referenceForURL("gs://chatov-e9822.appspot.com")
    }

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

    func uploadImage(image: UIImage) -> Observable<String> {
        return Observable.create { observer in
            let imageData = UIImageJPEGRepresentation(image, 0.8)
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