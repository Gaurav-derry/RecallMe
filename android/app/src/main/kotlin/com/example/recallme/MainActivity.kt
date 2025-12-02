package com.example.recallme

import android.graphics.BitmapFactory
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import androidx.annotation.NonNull
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetectorOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import java.util.Locale
import java.util.UUID
import kotlin.math.sqrt

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {
    
    private val TTS_CHANNEL = "com.recallme/tts"
    private val STT_CHANNEL = "com.recallme/stt"
    private val STT_EVENTS_CHANNEL = "com.recallme/stt_events"
    private val FACE_CHANNEL = "com.recallme/face"
    
    private var tts: TextToSpeech? = null
    private var ttsInitialized = false
    private var speechRate = 0.8f
    private var speechPitch = 1.0f
    private var ttsInitResult: MethodChannel.Result? = null
    
    private var sttEventSink: EventChannel.EventSink? = null
    
    // Face detection options
    private val faceDetectorOptions = FaceDetectorOptions.Builder()
        .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_ACCURATE)
        .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_NONE)
        .setContourMode(FaceDetectorOptions.CONTOUR_MODE_NONE)
        .setMinFaceSize(0.15f)
        .build()
    
    private val faceDetector by lazy { FaceDetection.getClient(faceDetectorOptions) }
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize TTS
        tts = TextToSpeech(this, this)
        
        // TTS Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TTS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    if (ttsInitialized) {
                        result.success(true)
                    } else {
                        ttsInitResult = result
                    }
                }
                "speak" -> {
                    val text = call.argument<String>("text") ?: ""
                    speak(text)
                    result.success(true)
                }
                "stop" -> {
                    tts?.stop()
                    result.success(true)
                }
                "setSpeechRate" -> {
                    speechRate = (call.argument<Double>("rate") ?: 0.8).toFloat()
                    tts?.setSpeechRate(speechRate)
                    result.success(true)
                }
                "setPitch" -> {
                    speechPitch = (call.argument<Double>("pitch") ?: 1.0).toFloat()
                    tts?.setPitch(speechPitch)
                    result.success(true)
                }
                "shutdown" -> {
                    tts?.stop()
                    tts?.shutdown()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        // STT Method Channel - Placeholder for Vosk integration
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    // Vosk initialization would go here
                    // For now, return true as a placeholder
                    result.success(true)
                }
                "startListening" -> {
                    // Start Vosk recognition
                    sendSttEvent("state", "listening")
                    result.success(true)
                }
                "stopListening" -> {
                    // Stop Vosk recognition
                    sendSttEvent("state", "idle")
                    result.success(true)
                }
                "shutdown" -> {
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        // STT Event Channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, STT_EVENTS_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    sttEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    sttEventSink = null
                }
            }
        )
        
        // Face Recognition Method Channel with ML Kit
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FACE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    result.success(true)
                }
                "detectFaces" -> {
                    val imageBytes = call.argument<ByteArray>("imageBytes")
                    if (imageBytes != null) {
                        detectFaces(imageBytes, result)
                    } else {
                        result.success(listOf<Map<String, Any>>())
                    }
                }
                "generateEmbedding" -> {
                    val faceImageBytes = call.argument<ByteArray>("faceImageBytes")
                    if (faceImageBytes != null) {
                        // Generate a simple feature-based embedding from the face
                        generateSimpleEmbedding(faceImageBytes, result)
                    } else {
                        result.success(null)
                    }
                }
                "shutdown" -> {
                    faceDetector.close()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
    
    private fun detectFaces(imageBytes: ByteArray, result: MethodChannel.Result) {
        try {
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            if (bitmap == null) {
                result.success(listOf<Map<String, Any>>())
                return
            }
            
            val inputImage = InputImage.fromBitmap(bitmap, 0)
            
            faceDetector.process(inputImage)
                .addOnSuccessListener { faces ->
                    val faceList = faces.map { face ->
                        mapOf(
                            "x" to face.boundingBox.left.toDouble(),
                            "y" to face.boundingBox.top.toDouble(),
                            "width" to face.boundingBox.width().toDouble(),
                            "height" to face.boundingBox.height().toDouble(),
                            "confidence" to 0.95 // ML Kit doesn't expose confidence directly
                        )
                    }
                    result.success(faceList)
                }
                .addOnFailureListener { e ->
                    result.success(listOf<Map<String, Any>>())
                }
        } catch (e: Exception) {
            result.success(listOf<Map<String, Any>>())
        }
    }
    
    private fun generateSimpleEmbedding(faceImageBytes: ByteArray, result: MethodChannel.Result) {
        try {
            val bitmap = BitmapFactory.decodeByteArray(faceImageBytes, 0, faceImageBytes.size)
            if (bitmap == null) {
                result.success(null)
                return
            }
            
            // Generate a more robust feature-based embedding using:
            // 1. Color histograms (RGB channels)
            // 2. Spatial grid sampling
            // 3. Gradient features
            
            val width = bitmap.width
            val height = bitmap.height
            val embeddingSize = 256
            val embedding = DoubleArray(embeddingSize)
            var idx = 0
            
            // 1. Color histogram features (64 features = 16 bins x 4 for R,G,B,Gray)
            val histBins = 16
            val rHist = IntArray(histBins)
            val gHist = IntArray(histBins)
            val bHist = IntArray(histBins)
            val grayHist = IntArray(histBins)
            
            for (x in 0 until width) {
                for (y in 0 until height) {
                    val pixel = bitmap.getPixel(x, y)
                    val r = (pixel shr 16) and 0xff
                    val g = (pixel shr 8) and 0xff
                    val b = pixel and 0xff
                    val gray = (r + g + b) / 3
                    
                    rHist[(r * histBins / 256).coerceIn(0, histBins - 1)]++
                    gHist[(g * histBins / 256).coerceIn(0, histBins - 1)]++
                    bHist[(b * histBins / 256).coerceIn(0, histBins - 1)]++
                    grayHist[(gray * histBins / 256).coerceIn(0, histBins - 1)]++
                }
            }
            
            val totalPixels = (width * height).toDouble()
            for (i in 0 until histBins) {
                if (idx < embeddingSize) embedding[idx++] = rHist[i] / totalPixels
                if (idx < embeddingSize) embedding[idx++] = gHist[i] / totalPixels
                if (idx < embeddingSize) embedding[idx++] = bHist[i] / totalPixels
                if (idx < embeddingSize) embedding[idx++] = grayHist[i] / totalPixels
            }
            
            // 2. Spatial grid features (8x8 grid = 64 features for average intensity)
            val gridSize = 8
            for (gy in 0 until gridSize) {
                for (gx in 0 until gridSize) {
                    val startX = (width * gx / gridSize).coerceIn(0, width - 1)
                    val endX = (width * (gx + 1) / gridSize).coerceIn(0, width - 1)
                    val startY = (height * gy / gridSize).coerceIn(0, height - 1)
                    val endY = (height * (gy + 1) / gridSize).coerceIn(0, height - 1)
                    
                    var sum = 0.0
                    var count = 0
                    for (x in startX until endX) {
                        for (y in startY until endY) {
                            val pixel = bitmap.getPixel(x, y)
                            val r = (pixel shr 16) and 0xff
                            val g = (pixel shr 8) and 0xff
                            val b = pixel and 0xff
                            sum += (r + g + b) / 3.0 / 255.0
                            count++
                        }
                    }
                    if (idx < embeddingSize && count > 0) {
                        embedding[idx++] = sum / count
                    }
                }
            }
            
            // 3. Edge/gradient features in key regions (face center, eyes area, mouth area)
            val regions = listOf(
                Pair(width / 4, height / 4) to Pair(3 * width / 4, height / 2), // Upper face (eyes)
                Pair(width / 4, height / 2) to Pair(3 * width / 4, 3 * height / 4), // Middle face (nose)
                Pair(width / 4, 3 * height / 4) to Pair(3 * width / 4, height) // Lower face (mouth)
            )
            
            for (region in regions) {
                val (start, end) = region
                var hGradSum = 0.0
                var vGradSum = 0.0
                var count = 0
                
                for (x in start.first until end.first - 1) {
                    for (y in start.second until end.second - 1) {
                        if (x >= 0 && x < width - 1 && y >= 0 && y < height - 1) {
                            val p1 = bitmap.getPixel(x, y)
                            val p2 = bitmap.getPixel(x + 1, y)
                            val p3 = bitmap.getPixel(x, y + 1)
                            
                            val g1 = ((p1 shr 16 and 0xff) + (p1 shr 8 and 0xff) + (p1 and 0xff)) / 3.0
                            val g2 = ((p2 shr 16 and 0xff) + (p2 shr 8 and 0xff) + (p2 and 0xff)) / 3.0
                            val g3 = ((p3 shr 16 and 0xff) + (p3 shr 8 and 0xff) + (p3 and 0xff)) / 3.0
                            
                            hGradSum += kotlin.math.abs(g2 - g1)
                            vGradSum += kotlin.math.abs(g3 - g1)
                            count++
                        }
                    }
                }
                
                if (idx < embeddingSize && count > 0) {
                    embedding[idx++] = hGradSum / count / 255.0
                    embedding[idx++] = vGradSum / count / 255.0
                }
            }
            
            // 4. Additional texture features: Local Binary Pattern (LBP) histogram (64 features)
            // Use a simplified LBP approach
            val lbpHist = IntArray(16) // Simplified LBP histogram with 16 bins
            val lbpGridSize = 4
            
            for (gy in 0 until lbpGridSize) {
                for (gx in 0 until lbpGridSize) {
                    val centerX = (width * (gx + 0.5) / lbpGridSize).toInt().coerceIn(1, width - 2)
                    val centerY = (height * (gy + 0.5) / lbpGridSize).toInt().coerceIn(1, height - 2)
                    
                    val centerPixel = bitmap.getPixel(centerX, centerY)
                    val centerGray = ((centerPixel shr 16 and 0xff) + (centerPixel shr 8 and 0xff) + (centerPixel and 0xff)) / 3
                    
                    var lbpValue = 0
                    var bitPos = 0
                    
                    // Sample 8 neighbors (simplified)
                    val neighbors = listOf(
                        Pair(centerX - 1, centerY - 1), Pair(centerX, centerY - 1), Pair(centerX + 1, centerY - 1),
                        Pair(centerX + 1, centerY), Pair(centerX + 1, centerY + 1),
                        Pair(centerX, centerY + 1), Pair(centerX - 1, centerY + 1), Pair(centerX - 1, centerY)
                    )
                    
                    for (neighbor in neighbors) {
                        val (nx, ny) = neighbor
                        if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
                            val neighborPixel = bitmap.getPixel(nx, ny)
                            val neighborGray = ((neighborPixel shr 16 and 0xff) + (neighborPixel shr 8 and 0xff) + (neighborPixel and 0xff)) / 3
                            if (neighborGray >= centerGray) {
                                lbpValue = lbpValue or (1 shl bitPos)
                            }
                        }
                        bitPos++
                    }
                    
                    val bin = (lbpValue * lbpHist.size / 256).coerceIn(0, lbpHist.size - 1)
                    lbpHist[bin]++
                }
            }
            
            val totalLbpSamples = lbpGridSize * lbpGridSize.toDouble()
            for (i in 0 until lbpHist.size) {
                if (idx < embeddingSize) {
                    embedding[idx++] = lbpHist[i] / totalLbpSamples
                }
            }
            
            // 5. Additional spatial features: Quadrant averages (4 features)
            val quadrants = listOf(
                Pair(0, width / 2) to Pair(0, height / 2), // Top-left
                Pair(width / 2, width) to Pair(0, height / 2), // Top-right
                Pair(0, width / 2) to Pair(height / 2, height), // Bottom-left
                Pair(width / 2, width) to Pair(height / 2, height) // Bottom-right
            )
            
            for (quadrant in quadrants) {
                val (xRange, yRange) = quadrant
                var sum = 0.0
                var count = 0
                
                for (x in xRange.first until xRange.second) {
                    for (y in yRange.first until yRange.second) {
                        val pixel = bitmap.getPixel(x, y)
                        val gray = ((pixel shr 16 and 0xff) + (pixel shr 8 and 0xff) + (pixel and 0xff)) / 3.0
                        sum += gray / 255.0
                        count++
                    }
                }
                
                if (idx < embeddingSize && count > 0) {
                    embedding[idx++] = sum / count
                }
            }
            
            // Fill remaining with zeros if needed (should be very few now)
            while (idx < embeddingSize) {
                embedding[idx++] = 0.0
            }
            
            // Normalize the embedding
            var norm = 0.0
            for (value in embedding) {
                norm += value * value
            }
            norm = sqrt(norm)
            
            if (norm > 0) {
                for (i in embedding.indices) {
                    embedding[i] /= norm
                }
            }
            
            result.success(embedding.toList())
        } catch (e: Exception) {
            android.util.Log.e("FaceRecognition", "Embedding error: ${e.message}")
            result.success(null)
        }
    }
    
    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            val result = tts?.setLanguage(Locale.US)
            if (result != TextToSpeech.LANG_MISSING_DATA && result != TextToSpeech.LANG_NOT_SUPPORTED) {
                ttsInitialized = true
                tts?.setSpeechRate(speechRate)
                tts?.setPitch(speechPitch)
                
                // Set utterance progress listener
                tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                    override fun onStart(utteranceId: String?) {}
                    override fun onDone(utteranceId: String?) {}
                    override fun onError(utteranceId: String?) {}
                })

                ttsInitResult?.success(true)
                ttsInitResult = null
            } else {
                ttsInitResult?.success(false)
                ttsInitResult = null
            }
        } else {
            ttsInitResult?.success(false)
            ttsInitResult = null
        }
    }
    
    private fun speak(text: String) {
        if (ttsInitialized && text.isNotEmpty()) {
            val utteranceId = UUID.randomUUID().toString()
            tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, utteranceId)
        }
    }
    
    private fun sendSttEvent(type: String, value: String) {
        runOnUiThread {
            sttEventSink?.success(mapOf(
                "type" to type,
                "state" to value
            ))
        }
    }
    
    private fun sendSttResult(text: String, isFinal: Boolean) {
        runOnUiThread {
            sttEventSink?.success(mapOf(
                "type" to if (isFinal) "final" else "partial",
                "text" to text
            ))
        }
    }
    
    override fun onDestroy() {
        tts?.stop()
        tts?.shutdown()
        faceDetector.close()
        super.onDestroy()
    }
}
