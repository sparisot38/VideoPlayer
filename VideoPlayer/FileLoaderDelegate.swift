//
//  FileLoaderDelegate.swift
//  VideoPlayer
//
//  Created by sparisot on 08/09/2020.
//  Copyright © 2020 Stéphane Parisot. All rights reserved.
//

import Foundation
import UIKit

//
// This is the Delegate Protocol

protocol FileLoaderDelegate {
    func didFinishLoading(_ sender:FileLoader)
}
