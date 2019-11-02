//
//  ImagePickerObjectDetectorViewController.swift
//  KakaoEmoji
//
//  Created by 정기욱 on 2019/11/02.
//  Copyright © 2019 kiwook. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ImagePickerObjectDetector: UIViewController {
    
    let albumPicker = UIImagePickerController()
    
    var imgWidth : Int = 0
    var imgHeight : Int = 0
    
    @IBOutlet weak var imgView: UIImageView!
    @IBAction func imgPick(_ sender: Any) {
        present(albumPicker, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        albumPicker.allowsEditing = false
        albumPicker.delegate = self
        albumPicker.sourceType = .photoLibrary
               
        albumPicker.modalPresentationStyle = .fullScreen
    }

}

extension ImagePickerObjectDetector: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
           dismiss(animated: true, completion: nil)
    }
       
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
           dismiss(animated: true, completion: nil)
           
           guard let image = info[.originalImage] as? UIImage else {
               fatalError("이미지르 로드 할 수 없습니다.")
           }
           
           self.imgView.image = image
           self.imgWidth = Int(self.view.bounds.size.width)
           //self.imgHeight = Int(self.view.bounds.size.height)
           self.imgHeight = 538
           guard let ciImage = CIImage(image: image) else {
               fatalError("UIImage를 CIImage로 전환할 수 없습니다.")
           }
           
           // 이미지 분석
           coreMLProcessing(image: ciImage)
       }
    
}

extension ImagePickerObjectDetector {
    func coreMLProcessing(image: CIImage) {
        
        // 모델 등록 - VNCoreMLModel(for:)
        guard let model = try? VNCoreMLModel(for: YOLOv3().model) else {
            fatalError("TubeApeach ML Model을 로드할 수 없습니다.")
        }
   
        // 등록한 모델을 사용해서 이미지 분석을 요청 - VNCoreMLRequest(model:)
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            
            //print(request.results)
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                return
            }
            guard let firstItem = results.first else {
                return
            }
            
           // 바운딩 박스
            let objectBounds = VNImageRectForNormalizedRect(firstItem.boundingBox, self?.imgWidth ?? 0, self?.imgHeight ?? 0)
            
            print(results)
            
            guard let shapeLayer = self?.createRoundedRectLayerWithBounds(objectBounds) else {
                return
            }
        

            
            DispatchQueue.main.async { [weak self] in
                self?.view.layer.addSublayer(shapeLayer)
            }
        }
        
        
        
        // 핸들러로 요청 실행 - VNImageRequestHandler(ciImage:)
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
            print("실행")
        }
        
        
    }
    
    // 바운딩 박스에 들어갈 텍스트 및 정확도 설정
    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        print(bounds)
        var newBounds = bounds
        newBounds.origin.y += newBounds.origin.y
        shapeLayer.bounds = newBounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Found Object"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.00, 0.58, 0.48, 0.4])
        shapeLayer.cornerRadius = 7
        return shapeLayer
    }
}
