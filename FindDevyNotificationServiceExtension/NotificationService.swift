//
//  NotificationService.swift
//  FindDevyNotificationServiceExtension
//
//  Created by hyeoktae kwon on 2020/07/18.
//  Copyright © 2020 hyeoktae kwon. All rights reserved.
//

import OneSignal
import UserNotifications 

class NotificationService: UNNotificationServiceExtension {
  
  var receivedRequest: UNNotificationRequest!
  var contentHandler: ((UNNotificationContent) -> Void)?
  var bestAttemptContent: UNMutableNotificationContent?
  
  override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
    self.receivedRequest = request;
    self.contentHandler = contentHandler
    bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
    
    if let bestAttemptContent = bestAttemptContent {
      // Modify the notification content here...
      OneSignal.didReceiveNotificationExtensionRequest(self.receivedRequest, with: self.bestAttemptContent)
      
      contentHandler(bestAttemptContent)
    }
  }
  
  override func serviceExtensionTimeWillExpire() {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
      OneSignal.serviceExtensionTimeWillExpireRequest(self.receivedRequest, with: self.bestAttemptContent)
      contentHandler(bestAttemptContent)
    }
  }
  
}
