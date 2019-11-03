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
    
    

    @IBOutlet weak var btnName: UIButton!
    
    @IBOutlet weak var imgView: UIImageView!
    @IBAction func imgPick(_ sender: UIButton) {
        imgView.layer.sublayers?.removeAll()
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
           self.imgHeight = Int(self.imgView.image?.size.height ?? 400)
           
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
        guard let model = try? VNCoreMLModel(for: newEmojiAndCat().model) else {
            fatalError("TubeApeach ML Model을 로드할 수 없습니다.")
        }
   
        // 등록한 모델을 사용해서 이미지 분석을 요청 - VNCoreMLRequest(model:)
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            
            //print(request.results)
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                return
            }
//            guard let firstItem = results.first else {
//                return
//            }
            
            for objectObservation in results {
                let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, self?.imgWidth ?? 0, self?.imgHeight ?? 0)
                    
                    print(objectObservation.boundingBox)
                    print(objectObservation.confidence)
                    
                    guard let nameIdentifier = objectObservation.labels.first?.identifier else {
                        return
                    }
                    
                    guard let shapeLayer = self?.createRoundedRectLayerWithBounds(bounds: objectBounds, name: nameIdentifier) else {
                        return
                    }
                

                    
                    DispatchQueue.main.async { [weak self] in
                        //print(firstItem.labels.first?.identifier)
                        self?.btnName.setTitle(nameIdentifier, for: .normal)
                        self?.imgView.layer.addSublayer(shapeLayer)
                    }
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
    func createRoundedRectLayerWithBounds(bounds: CGRect, name: String) -> CALayer {
        let shapeLayer = CALayer()
       
        var color : CGColor = CGColor(srgbRed: 0.5, green: 0.5, blue: 0.5, alpha: 0.3)
        if let emojiOrCat = EmojiOrCat.init(rawValue: name) {
            color = boxColor(emojiOrCat)
        }

        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Found Object"
        shapeLayer.backgroundColor = color
       
        shapeLayer.cornerRadius = 7
        return shapeLayer
    }
    
    enum EmojiOrCat: String {
        case apeach = "Apeach"
        case tube = "Tube"
        case ryan = "Ryan"
        case benny = "Benny"
        case white = "WhiteCat"
        case black = "BlackCat"
        case taby = "TabyCat"
        case cheeze = "CheezeCat"
    }
    
    
    func boxColor(_ emojiOrCat: EmojiOrCat) -> CGColor {
        switch emojiOrCat {
        case .apeach: return CGColor(srgbRed: 1.00, green: 0.00, blue: 0.72, alpha: 0.3)
        case .tube: return CGColor(srgbRed: 0.66, green: 0.53, blue: 0.07, alpha: 0.3)
        case .benny: return CGColor(srgbRed: 0.89, green: 0.70, blue: 0.70, alpha: 0.3)
        case .taby: return CGColor(srgbRed: 0.20, green: 0.01, blue: 0.04, alpha: 0.3)
        case .black: return CGColor(srgbRed: 0.53, green: 0.18, blue: 0.66, alpha: 0.3)
        case .cheeze: return CGColor(srgbRed: 0.90, green: 0.88, blue: 0.39, alpha: 0.3)
        case .ryan: return CGColor(srgbRed: 0.90, green: 0.88, blue: 0.00, alpha: 0.3)
        case .white: return CGColor(srgbRed: 0.82, green: 0.93, blue: 0.93, alpha: 0.3)
        }
    }
}


