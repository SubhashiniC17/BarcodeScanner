//
//  ViewController.swift
//  BarCodeScanner
//
//  Created by Subhashini Chandranathan on 05/05/24.

import AVFoundation
import UIKit

protocol ScannerViewDelegate{
    func didFindScannedText(text: String)
}

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var delegate : ScannerViewDelegate? = nil
    var rearCamera : AVCaptureDevice!
    var scanImage : UIImageView!
    var timeoutTimer : Timer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        print("Session created")
        self.navigationItem.hidesBackButton = true
        captureSession = AVCaptureSession()
        let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera], mediaType: AVMediaType.video, position: .back)
        
        self.rearCamera = session.devices.first
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print( "Your device is not applicable for video process")
            return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("Your device doesn't provide video input")
            return
        }
        if let rearCamera = self.rearCamera {
            try? rearCamera.lockForConfiguration()
            //          rearCamera.focusMode = .autoFocus
            rearCamera.unlockForConfiguration()
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce,.code39,.code39Mod43,.code93,.code128,.aztec]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        let customFrame = CGRect(x: 50, y: 250, width: 300 , height:view.frame.height / 8)
        previewLayer.frame = customFrame
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        view.layer.addSublayer(previewLayer)
        scanImage = UIImageView(frame: customFrame)
        scanImage.contentMode = .scaleAspectFit
        scanImage.image = UIImage(named: "")
        view.addSubview(scanImage)
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
            
        }
        self.startTimeoutTimer()
        
    }
    
    
    func failed() {
        self.captureSession.stopRunning()
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .cancel){_ in
            ac.dismiss(animated: false)
            self.found(code: "")
            self.navigationController?.popViewController(animated: true)
        }
        ac.addAction(okAction)
        present(ac, animated: true)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (captureSession?.isRunning == false) {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        }
        startTimeoutTimer()
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        DispatchQueue.global(qos: .background).async {
            self.captureSession.stopRunning()
        }
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
        dismiss(animated: true)
    }
    
    func found(code: String) {
        print("code",code)
        delegate?.didFindScannedText(text: code)
        self.navigationController?.popViewController(animated: true)
    }
    func startTimeoutTimer() {
        print("start timer")
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.stopCaptureSession()
            self?.failed()
        }
    }
    
    func stopCaptureSession() {
        print("stop capture")
        captureSession.stopRunning()
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
}
