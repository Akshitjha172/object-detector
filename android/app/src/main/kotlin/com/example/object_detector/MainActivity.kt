package com.example.object_detector

import android.Manifest
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayInputStream


class MainActivity: FlutterActivity() {
    private val PERMISSION_CHANNEL = "com.example.object_detector/permissions"
    private val DETECTION_CHANNEL = "com.example.object_detector/detector"
    private val CAMERA_REQUEST_CODE = 1001

    private var resultPending: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Handle permission
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "requestCameraPermission") {
                resultPending = result
                if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
                    ActivityCompat.requestPermissions(this, arrayOf(android.Manifest.permission.CAMERA), CAMERA_REQUEST_CODE)
                } else {
                    result.success(true)
                }
            } else {
                result.notImplemented()
            }
        }

        // Handle object detection (mocked for now)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DETECTION_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "detectObjects") {
                val byteArray = call.argument<ByteArray>("image") ?: byteArrayOf()
                val width = call.argument<Int>("width") ?: 0
                val height = call.argument<Int>("height") ?: 0

                // Decode image (not used in mock)
                val inputStream = ByteArrayInputStream(byteArray)
                val bitmap = BitmapFactory.decodeStream(inputStream)

                // Send mock detection response
                result.success(listOf(
                    mapOf(
                        "left" to 100,
                        "top" to 200,
                        "right" to 300,
                        "bottom" to 400,
                        "label" to "MockObject",
                        "confidence" to 0.9
                    )
                ))
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == CAMERA_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            resultPending?.success(granted)
            resultPending = null
        }
    }
}
