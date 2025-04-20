import Foundation
import MLKit
import UIKit

class ObjectDetector {
    private var objectDetector: MLKObjectDetector?
    
    init() {
        let options = MLKObjectDetectorOptions()
        options.detectorMode = .stream
        options.shouldEnableClassification = true
        options.shouldEnableMultipleObjects = true
        
        objectDetector = MLKObjectDetector.objectDetector(options: options)
    }
    
    func detectObjects(imageData: Data, width: Int, height: Int) -> [[String: Any]] {
        guard let image = UIImage(data: imageData) else {
            return []
        }
        
        let visionImage = MLKVisionImage(image: image)
        visionImage.orientation = .up
        
        var detectedObjects: [[String: Any]] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        objectDetector?.process(visionImage) { objects, error in
            defer {
                semaphore.signal()
            }
            
            guard error == nil, let objects = objects, !objects.isEmpty else {
                return
            }
            
            for object in objects {
                let frame = object.frame
                
                var label = "Unknown"
                var confidence = 0.0
                
                if let topLabel = object.labels.first {
                    label = topLabel.text
                    confidence = Double(topLabel.confidence)
                }
                
                let objectDict: [String: Any] = [
                    "left": Int(frame.minX),
                    "top": Int(frame.minY),
                    "right": Int(frame.maxX),
                    "bottom": Int(frame.maxY),
                    "label": label,
                    "confidence": confidence
                ]
                
                detectedObjects.append(objectDict)
            }
        }
        
        _ = semaphore.wait(timeout: .now() + 5.0)
        return detectedObjects
    }
    
    func close() {
        // Nothing to close in MLKit for iOS
    }
}