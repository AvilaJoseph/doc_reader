package com.avilajoseph.doc_reader

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Recibe documentos de otras apps ("Abrir con…" y "Compartir") y se los
 * pasa a Flutter por el canal `folio/open_with`.
 *
 * El archivo se copia a la caché en un hilo aparte (los content:// de
 * WhatsApp, Gmail o Archivos solo son legibles mientras dura el permiso
 * temporal) y Dart lo importa a la biblioteca.
 */
class MainActivity : FlutterActivity() {
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var channel: MethodChannel? = null
    private var initialIntent: Intent? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initialIntent = intent
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "takeInitialFile" -> {
                        val pending = initialIntent
                        initialIntent = null
                        copyInBackground(pending) { file -> result.success(file) }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        copyInBackground(intent) { file ->
            if (file != null) channel?.invokeMethod("onFile", file)
        }
    }

    private fun copyInBackground(intent: Intent?, done: (Map<String, Any>?) -> Unit) {
        val uri = intent?.let(::documentUri)
        if (uri == null) {
            done(null)
            return
        }
        val type = intent?.type
        io.execute {
            val file = try {
                copyToCache(uri, type)
            } catch (e: Exception) {
                null
            }
            main.post { done(file) }
        }
    }

    private fun documentUri(intent: Intent): Uri? = when (intent.action) {
        Intent.ACTION_VIEW -> intent.data
        Intent.ACTION_SEND ->
            if (Build.VERSION.SDK_INT >= 33) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
            }
        else -> null
    }

    private fun copyToCache(uri: Uri, type: String?): Map<String, Any>? {
        val name = sanitize(displayName(uri, type))
        val dir = File(cacheDir, "open_with").apply { mkdirs() }
        val target = File(dir, name)
        val input = contentResolver.openInputStream(uri) ?: return null
        input.use { source -> target.outputStream().use { source.copyTo(it) } }
        return mapOf("path" to target.absolutePath, "name" to name, "size" to target.length())
    }

    /** Nombre visible del archivo, con extensión aunque la app no la dé. */
    private fun displayName(uri: Uri, type: String?): String {
        var name: String? = null
        if (uri.scheme == "content") {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { cursor ->
                    if (cursor.moveToFirst()) name = cursor.getString(0)
                }
        }
        if (name.isNullOrBlank()) name = uri.lastPathSegment?.substringAfterLast('/')
        if (name.isNullOrBlank()) name = "documento"
        val mime = type ?: contentResolver.getType(uri)
        if (!name!!.contains('.') && mime != null) {
            val ext = MimeTypeMap.getSingleton().getExtensionFromMimeType(mime)
                ?: EXTRA_EXTENSIONS[mime]
            if (ext != null) name = "$name.$ext"
        }
        return name!!
    }

    private fun sanitize(name: String) = name.replace(Regex("[\\\\/:*?\"<>|]"), "_")

    companion object {
        private const val CHANNEL = "folio/open_with"
        private val EXTRA_EXTENSIONS = mapOf(
            "text/markdown" to "md",
            "text/x-markdown" to "md",
            "text/comma-separated-values" to "csv",
        )
    }
}
