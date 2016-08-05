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
    var messageStream = PublishSubject<[Message]>()

    init() {
        configureDatabase()
    }

    deinit {
        databaseReference.child(Manager.messagesKey).removeObserverWithHandle(messageHandle)
    }

    private func configureDatabase() {
        databaseReference = FIRDatabase.database().reference()

        messageHandle = databaseReference.child(Manager.messagesKey).observeEventType(.ChildAdded, withBlock: { [unowned self] snapshot in
            self.messageStream.on(.Next(Manager.messagesFromSnapshot(snapshot)))
        })
    }

    func sendMessage(message: Message) {
        databaseReference.child(Manager.messagesKey).childByAutoId().setValue(message.toJSON())
    }

    private static func messagesFromSnapshot(snapshot: FIRDataSnapshot) -> [Message] {
        return Mapper<Message>().mapArray(snapshot.value)!
    }
}