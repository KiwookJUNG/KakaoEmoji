//
//  ViewController.swift
//  KakaoEmoji
//
//  Created by 정기욱 on 2019/11/01.
//  Copyright © 2019 kiwook. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ImagePcikerClassifierViewController: UIViewController {

    
    let imgPicker = UIImagePickerController()
    
    @IBAction func imgPick(_ sender: Any) {
        present(imgPicker, animated: true)
    }
    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var confidenceLbl: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        imgPicker.allowsEditing = false
        imgPicker.delegate = self
        imgPicker.sourceType = .photoLibrary
                     
        imgPicker.modalPresentationStyle = .fullScreen
    }


}

extension ImagePcikerClassifierViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
   func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)
        
        guard let image = info[.originalImage] as? UIImage else {
            fatalError("이미지를 로드 할 수 없습니다.")
        }
        
        self.imgView.image = image
        
        guard let ciImage = CIImage(image: image) else {
            fatalError("UIImage를 CIImage로 전환할 수 없습니다.")
        }
        
        // 이미지 분석
        coreMLProcessing(image: ciImage)
    }
    
}

extension ImagePcikerClassifierViewController {
    
    func coreMLProcessing(image: CIImage) {
        
        // 모델 등록 - VNCoreMLModel(for:)
        guard let model = try? VNCoreMLModel(for: EmojiAndCatClassifier().model) else {
            fatalError("TubeApeach ML Model을 로드할 수 없습니다.")
        }
        
        
        
        // 등록한 모델을 사용해서 이미지 분석을 요청 - VNCoreMLRequest(model:)
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            
            guard let results = request.results as? [VNClassificationObservation] else {
                return
            }
            guard let firstItem = results.first else {
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.nameLbl.text = firstItem.identifier
                self?.confidenceLbl.text = String(firstItem.confidence)
            }
        }
        
        
        
        // 핸들러로 요청 실행 - VNImageRequestHandler(ciImage:)
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
        
        
    }
}
