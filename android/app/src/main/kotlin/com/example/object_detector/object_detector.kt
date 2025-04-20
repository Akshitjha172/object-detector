package com.example.object_detector
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Rect
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.objects.DetectedObject
import com.google.mlkit.vision.objects.ObjectDetection
import com.google.mlkit.vision.objects.ObjectDetector
import com.google.mlkit.vision.objects.defaults.ObjectDetectorOptions
import java.nio.ByteBuffer
import kotlinx.coroutines.tasks.await

class ObjectDetector(private val context: Context) {
    private var objectDetector: ObjectDetector

    init {
        // Real-time detection, process only new frames
        val options = ObjectDetectorOptions.Builder()
            .setDetectorMode(ObjectDetectorOptions.STREAM_MODE)
            .enableMultipleObjects()
            .enableClassification()
            .build()

        objectDetector = ObjectDetection.getClient(options)
    }

    suspend fun detectObjects(imageBytes: ByteArray, width: Int, height: Int): List<Map<String, Any>> {
        val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)

        // Convert to input image
        val inputImage = InputImage.fromBitmap(bitmap, 0)

        // Process image
        val results = objectDetector.process(inputImage).await()

        // Convert results to a format suitable for Flutter
        return results.map { detectedObject ->
            val boundingBox = detectedObject.boundingBox

            val label = if (detectedObject.labels.isNotEmpty()) {
                detectedObject.labels[0].text
            } else {
                "Unknown"
            }

            val confidence = if (detectedObject.labels.isNotEmpty()) {
                detectedObject.labels[0].confidence
            } else {
                0.0f
            }

            mapOf(
                "left" to boundingBox.left,
                "top" to boundingBox.top,
                "right" to boundingBox.right,
                "bottom" to boundingBox.bottom,
                "label" to label,
                "confidence" to confidence.toDouble()
            )
        }
    }

    fun close() {
        objectDetector.close()
    }
}