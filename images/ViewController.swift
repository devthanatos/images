//
//  ViewController.swift
//  images
//
//  Created by Michael Akopyants on 11/12/2016.
//  Copyright © 2016 devthanatos. All rights reserved.
//

import UIKit


class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    var previousPoint: CGPoint!
    var previousScale: CGFloat!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.isUserInteractionEnabled = true
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        self.showCamera()
    }
    
    func showCamera(){
        self.imageView.subviews.forEach{$0.removeFromSuperview()}
        
        let storyboard = UIStoryboard(name:"Main", bundle:nil)
        let vc = storyboard.instantiateViewController(withIdentifier:"CameraController") as! CameraViewController
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overCurrentContext
        vc.delegate = self
        self.navigationController?.present(vc, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func changePhotoAction(_ sender: Any) {
        self.showCamera()
    }
    
    @IBAction func addStickerAction(_ sender: Any) {
        let imgView = UIImageView()
        imgView.image = UIImage.init(named: "enot");
        imgView.frame = CGRect.init(x: 50, y: 50, width: 100, height: 100)
        imgView.isUserInteractionEnabled = true
        let panImgGestureRecognizer = UIPanGestureRecognizer.init(target: self, action: #selector(panItemGestureAction))
        imgView.addGestureRecognizer(panImgGestureRecognizer)
        
        let rotationGestureRecognizer = UIRotationGestureRecognizer.init(target: self, action: #selector(rotateItemGestureAction))
        imgView.addGestureRecognizer(rotationGestureRecognizer)
        
        self.imageView.addSubview(imgView)
    }
    
    @IBAction func addTextAction(_ sender: Any) {
        let txtView = TextView()
        var frame = txtView.frame
        frame.origin.x = 0
        frame.origin.y = 100
        frame.size.width = self.view.frame.width
        frame.size.height = 24
        txtView.frame = frame
        self.imageView.addSubview(txtView);
        txtView.textField.becomeFirstResponder()
        let panTextGestureRecognizer = UIPanGestureRecognizer.init(target: self, action: #selector(panItemGestureAction))
        txtView.addGestureRecognizer(panTextGestureRecognizer)
        
    }
    
    
    func rotateItemGestureAction(_ sender:UIRotationGestureRecognizer)
    {
        sender.view?.transform = (sender.view?.transform.rotated(by:sender.rotation))!
        sender.rotation = 0
    }
    
    func panItemGestureAction(_ sender:UIPanGestureRecognizer)
    {
        let point = sender.location(in: self.imageView)
        let senderViewCenter = sender.view?.center
        switch sender.state
        {
        case .began:
            previousPoint = point
            break
        case .changed:
            let dPoint = CGPoint(x:(senderViewCenter?.x)! + (point.x - previousPoint.x),y:(senderViewCenter?.y)! + (point.y - previousPoint.y))
            sender.view?.center = dPoint            
            previousPoint = point
            break
        default:
            previousPoint = CGPoint.zero
            break
        }
    }
}

extension ViewController: CameraControllerDelegate{
    func didTakeImage(image: UIImage){        
        self.imageView.image = image;
    }
}

