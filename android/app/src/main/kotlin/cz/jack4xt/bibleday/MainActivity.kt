package cz.jack4xt.bibleday

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "cz.bibleday.app/import"
    private var pendingImportPath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingImportPath" -> {
                    result.success(pendingImportPath)
                    pendingImportPath = null
                }
                else -> result.notImplemented()
            }
        }

        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        if (intent.action == Intent.ACTION_VIEW) {
            val uri: Uri? = intent.data
            if (uri != null) {
                pendingImportPath = copyUriToCache(uri)
            }
        }
    }

    /// Zkopíruje obsah Uri (content:// nebo file://) do cache souboru,
    /// odkud ho může Dart strana spolehlivě přečíst jako obyčejnou cestu.
    private fun copyUriToCache(uri: Uri): String? {
        return try {
            val inputStream = contentResolver.openInputStream(uri) ?: return null
            val outFile = java.io.File(cacheDir, "bibleday_import.json")
            FileOutputStream(outFile).use { output ->
                inputStream.copyTo(output)
            }
            inputStream.close()
            outFile.absolutePath
        } catch (e: Exception) {
            null
        }
    }
}
