//
//  GameViewController.swift
//  augmentReality
//
//  Created by Kristopher Merolla on 7/7/17.
//  Copyright © 2017 Kristopher Merolla. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import AVFoundation
import CoreMotion

class GameViewController2: UIViewController, SCNSceneRendererDelegate {
    
    var gameView:SCNView!
    var gameScene:SCNScene!
    var cameraNode:SCNNode!
    var targetCreationTime:TimeInterval = 0
    
    // for CoreMotion
    var motionManager = CMMotionManager()
    let opQueue = OperationQueue()

    // import camera and scan views
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var scnView: SCNView!
    
    let scene = SCNScene(named: "art.scnassets/ship.scn")!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //getting plane to move with accelerometerData
        motionManager.startAccelerometerUpdates()
        motionManager.accelerometerUpdateInterval = 0.3
        
        
//        func renderer(_ <#T##renderer: SCNSceneRenderer##SCNSceneRenderer#>, updateAtTime time: TimeInterval){
//            if let accelerometerData = motionManager.accelerometerData {
//                scene.physicsWorld.gravity = SCNVector3(accelerometerData.acceleration.y * 20, -10, (accelerometerData.acceleration.x - 0.5) * 5)
//            }
//        }
        
        // get variables from CoreMotion
        func startReadingMotionData() {
            // set read speed
            motionManager.deviceMotionUpdateInterval = 1
            // start reading
            motionManager.startDeviceMotionUpdates(to: opQueue) {
                (data: CMDeviceMotion?, error: Error?) in
                
                if let mydata = data {
                    print("mydata", mydata.attitude)
                    //                print("pitch", self.degrees(mydata.attitude.pitch))
                }
            }
        }
        
        
        
        
        // create a new scene
        
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 45)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the ship node
        _ = scene.rootNode.childNode(withName: "ship", recursively: true)!
        
        // animate the 3d object
        // ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))
        
        // retrieve the SCNView
//        let scnView = self.view as! SCNView
        
        
        // set the scene to the view
        scnView.scene = scene
        scnView.isPlaying = true
        scnView.delegate = self
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
//        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.clear // changed to clear
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        // start tracking motion for CoreMotion
        if motionManager.isDeviceMotionAvailable {
            print("We can detect device motion")
            startReadingMotionData()
        }
        else {
            print("We cannot detect device motion")
        }
    }
    

    
    // convert degrees to radians (use for CoreMotion conversions)
    func degrees(_ radians: Double) -> Double {
        return 180/Double.pi * radians
    }
    
    // control 3D object with touch
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result: AnyObject = hitResults[0]
            
            // get its material
            let material = result.node!.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = UIColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
        }
    }
    
//    override var shouldAutorotate: Bool {
//        return true
//    }
//    
//    override var prefersStatusBarHidden: Bool {
//        return true
//    }
//    
//    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        if UIDevice.current.userInterfaceIdiom == .phone {
//            return .allButUpsideDown
//        } else {
//            return .all
//        }
//    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // Below pulls the image from camera
    
    var preview: AVCaptureVideoPreviewLayer?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // create a capture session for the camera input
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        
        // Choose the back camera as input device
        let backCamera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        var error: NSError?
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
        } catch let cameraError as NSError {
            error = cameraError
            input = nil
        }
        
        // check if the camera input is available
        if error == nil && captureSession.canAddInput(input) {
            // ad camera input to the capture session
            captureSession.addInput(input)
            let photoImageOutput = AVCapturePhotoOutput()
            
            // Create an UIlayer with the capture session output
            photoImageOutput.photoSettingsForSceneMonitoring = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecJPEG])
            if captureSession.canAddOutput(photoImageOutput) {
                captureSession.addOutput(photoImageOutput)
                
                preview = AVCaptureVideoPreviewLayer(session: captureSession)
                preview?.videoGravity = AVLayerVideoGravityResizeAspectFill
                preview?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
                preview?.frame = cameraView.frame
                cameraView.layer.addSublayer(preview!)
                captureSession.startRunning()
            }
        }
        
    }

}
