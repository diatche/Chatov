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

class Manager {
    static var sharedInstance = Manager()

    var databaseReference: FIRDatabaseReference!
    private var messageSnapshots: [FIRDataSnapshot] = []
    var messages = PublishSubject<[Message]>()

    init() {

    }

    func configureDatabase() {
        databaseReference = FIRDatabase.database().reference()

        messageSnapshots = databaseReference.child("messages").observeEventType(.ChildAdded, withBlock: { [unowned self] snapshot in
            self.messageSnapshots.append(snapshot)
        })
    }
}