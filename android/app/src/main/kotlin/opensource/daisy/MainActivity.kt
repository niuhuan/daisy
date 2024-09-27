package opensource.daisy

import android.content.ContentValues
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.Settings
import android.view.Display
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import io.flutter.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity: FlutterActivity() {

    private val pool = Executors.newCachedThreadPool { runnable ->
        Thread(runnable).also { it.isDaemon = true }
    }
    private val uiThreadHandler = Handler(Looper.getMainLooper())

    private val notImplementedToken = Any()
    private fun MethodChannel.Result.withCoroutine(exec: () -> Any?) {
        pool.submit {
            try {
                val data = exec()
                uiThreadHandler.post {
                    when (data) {
                        notImplementedToken -> {
                            notImplemented()
                        }
                        is Unit, null -> {
                            success(null)
                        }
                        else -> {
                            success(data)
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e("Method", "Exception", e)
                uiThreadHandler.post {
                    error("", e.message, "")
                }
            }
        }
    }

    private fun downloadsDir(): File {
        return context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
            ?: throw java.lang.IllegalStateException()
    }

    private fun defaultPikapikaDir(): File {
        return File(downloadsDir(), "daisy")
    }

    private fun androidDefaultExportsDir(): File {
        return File(defaultPikapikaDir(), "exports")
    }

    @RequiresApi(Build.VERSION_CODES.KITKAT)
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Method Channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "cross"
        ).setMethodCallHandler { call, result ->
            result.withCoroutine {
                when (call.method) {
                    "root" -> context!!.filesDir.absolutePath
                    "saveImageToGallery" -> saveImageToGallery(call.arguments as String)
                    "androidGetModes" -> {
                        modes()
                    }
                    "androidSetMode" -> {
                        setMode(call.argument("mode")!!)
                    }
                    "androidGetVersion" -> Build.VERSION.SDK_INT
                    "androidAppInfo" -> {
                        goAppInfo()
                    }
                    "androidDefaultExportsDir" -> {
                        androidDefaultExportsDir().absolutePath
                    }
                    else -> {
                        notImplementedToken
                    }
                }
            }
        }
    }

    private fun saveImageToGallery(path: String) {
        BitmapFactory.decodeFile(path)?.let { bitmap ->
            val contentValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, System.currentTimeMillis().toString())
                put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) { //this one
                    put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_PICTURES)
                    put(MediaStore.MediaColumns.IS_PENDING, 1)
                }
            }
            contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
                ?.let { uri ->
                    contentResolver.openOutputStream(uri)?.use { fos ->
                        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, fos)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) { //this one
                        contentValues.clear()
                        contentValues.put(MediaStore.Video.Media.IS_PENDING, 0)
                        contentResolver.update(uri, contentValues, null, null)
                    }
                }
        }
    }

    // fps mods
    private fun mixDisplay(): Display? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display?.let {
                return it
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            windowManager.defaultDisplay?.let {
                return it
            }
        }
        return null
    }

    private fun modes(): List<String> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            mixDisplay()?.let { display ->
                return display.supportedModes.map { mode ->
                    mode.toString()
                }
            }
        }
        return ArrayList()
    }

    private fun setMode(string: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            mixDisplay()?.let { display ->
                if (string == "") {
                    uiThreadHandler.post {
                        window.attributes = window.attributes.also { attr ->
                            attr.preferredDisplayModeId = 0
                        }
                    }
                    return
                }
                return display.supportedModes.forEach { mode ->
                    if (mode.toString() == string) {
                        uiThreadHandler.post {
                            window.attributes = window.attributes.also { attr ->
                                attr.preferredDisplayModeId = mode.modeId
                            }
                        }
                        return
                    }
                }
            }
        }
    }

    fun goAppInfo() {
        var packageURI = Uri.fromParts("package", packageName, null)
        var intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, packageURI)
        startActivity(intent)
    }

}

