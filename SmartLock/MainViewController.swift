//
//  MainViewController.swift
//  SmartLock
//
//  Created by Elliot Barer on 2014-12-08.
//  Copyright (c) 2014 Elliot Barer. All rights reserved.
//

import UIKit

class MainViewController: UITabBarController {

	var gblSmartLock = SmartLock()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // segue.destinationViewController.
    }

}
