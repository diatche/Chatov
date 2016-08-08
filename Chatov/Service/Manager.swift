//
//  Manager.swift
//  Chatov
//
//  Created by Pavel Diatchenko on 5/08/16.
//  Copyright © 2016 Pavel Diatchenko. All rights reserved.
//

import Foundation
import Firebase
import RxSwift
import ObjectMapper

class Manager {
    static let messagesKey = "messages"

    static let sharedInstance = Manager()

    var databaseReference: FIRDatabaseReference!
    var messageHandle: FIRDatabaseHandle!
    var storageReference: FIRStorageReference!
    var messages = Variable<[Message]>([])

    init() {
        configureDatabase()
    }

    deinit {
        databaseReference.child(Manager.messagesKey).removeObserverWithHandle(messageHandle)
    }

    private func configureDatabase() {
        databaseReference = FIRDatabase.database().reference()

        messageHandle = databaseReference.child(Manager.messagesKey).observeEventType(.ChildAdded, withBlock: { [unowned self] snapshot in
            self.messages.value.append(Manager.messageFromSnapshot(snapshot))
        })

        storageReference = FIRStorage.storage().referenceForURL("gs://chatov-e9822.appspot.com")
    }

    func sendMessage(message: Message) {
        databaseReference.child(Manager.messagesKey).childByAutoId().setValue(message.toJSON())
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