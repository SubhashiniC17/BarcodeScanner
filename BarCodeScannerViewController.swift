//
//  BarCodeScannerViewController.swift
//  BarCodeScanner
//
//  Created by Subhashini Chandranathan on 07/05/24.
//

import UIKit


class BarCodeScannerViewController: UIViewController {
    
    @IBOutlet weak var barcodeHeader : UILabel!
    @IBOutlet weak var scannedSubTitle : UILabel!
    @IBOutlet weak var scannedText : UILabel!
    @IBOutlet weak var scanButton : UIButton!
    
    let scannerViewController = ViewController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scannerViewController.delegate = self
    }
    
    @IBAction func nav2Scanner(_ sender : UIButton){
        self.navigationController?.pushViewController(scannerViewController, animated: true)
    }
    
    
}
extension BarCodeScannerViewController : ScannerViewDelegate{
    func didFindScannedText(text: String) {
        if text.isEmpty  {
            scannedText.text = ""
        }else{
            scannedText.text = text
        }
    }
}
