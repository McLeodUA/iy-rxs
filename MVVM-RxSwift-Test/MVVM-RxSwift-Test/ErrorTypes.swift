//
//  ErrorTypes.swift
//  MVVM-RxSwift-Test
//

import Foundation


enum FileError : Error {
   case notExists(message:String? = nil)
   case failedToConvert
}
