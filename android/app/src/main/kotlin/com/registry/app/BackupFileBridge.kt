package com.registry.app

import android.app.Activity
import android.content.ContentResolver
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.system.ErrnoException
import android.system.Os
import android.system.OsConstants
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.IOException
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Saves and opens a backup through the system document picker.
 *
 * file_picker reports success when [android.content.ContentResolver.openOutputStream]
 * returns null and still names a guessed Downloads path. This bridge treats a missing
 * stream as a failed save, truncates an existing longer file, and reads the destination
 * back before reporting success.
 *
 * Opening a backup reads at most the caller's limit plus one byte. It does not copy the
 * provider file into cache and does not trust the size the provider reports.
 */
class BackupFileBridge : FlutterPlugin, ActivityAware, PluginRegistry.ActivityResultListener {
    private var channel: MethodChannel? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pending: MethodChannel.Result? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val io: ExecutorService = Executors.newSingleThreadExecutor()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler(::onMethodCall)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        io.shutdown()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
        replyError("write_failed", "The file dialog closed before the backup was saved.")
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "save" -> startSave(call, result)
            "pick" -> startPick(call, result)
            else -> result.notImplemented()
        }
    }

    private fun startSave(call: MethodCall, result: MethodChannel.Result) {
        val bytes = call.argument<ByteArray>("bytes")
        val name = call.argument<String>("name")
        if (bytes == null || bytes.isEmpty() || name.isNullOrBlank()) {
            result.error("write_failed", "The backup to save was empty.", null)
            return
        }
        if (!begin(result)) {
            return
        }
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/octet-stream"
            putExtra(Intent.EXTRA_TITLE, name)
        }
        launch(intent, REQUEST_SAVE, bytes)
    }

    private fun startPick(call: MethodCall, result: MethodChannel.Result) {
        val maxBytes = call.argument<Int>("maxBytes")
        if (maxBytes == null || maxBytes <= 0 || maxBytes > MAX_ACCEPTED_BYTES) {
            result.error("oversized", "The backup size limit is not usable.", null)
            return
        }
        if (!begin(result)) {
            return
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
        }
        launch(intent, REQUEST_PICK, ByteArray(0), maxBytes)
    }

    private fun begin(result: MethodChannel.Result): Boolean {
        synchronized(this) {
            if (pending != null) {
                result.error("write_failed", "A file dialog is already open.", null)
                return false
            }
            if (activityBinding?.activity == null) {
                result.error("write_failed", "The app is not in the foreground.", null)
                return false
            }
            pending = result
            return true
        }
    }

    private fun launch(
        intent: Intent,
        requestCode: Int,
        bytes: ByteArray,
        maxBytes: Int = 0,
    ) {
        val activity = activityBinding?.activity
        if (activity == null) {
            replyError("write_failed", "The app is not in the foreground.")
            return
        }
        pendingBytes = bytes
        pendingMaxBytes = maxBytes
        try {
            activity.startActivityForResult(intent, requestCode)
        } catch (error: Exception) {
            wipePendingBytes()
            replyError("write_failed", "The file dialog could not be opened.")
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_SAVE && requestCode != REQUEST_PICK) {
            return false
        }
        val bytes = releasePendingBytes()
        val maxBytes = pendingMaxBytes
        pendingMaxBytes = 0
        if (resultCode == Activity.RESULT_CANCELED) {
            bytes?.fill(0)
            reply(null)
            return true
        }
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            bytes?.fill(0)
            replyError("write_failed", "The selected file was not returned.")
            return true
        }
        val activity = activityBinding?.activity
        if (activity == null) {
            bytes?.fill(0)
            replyError("write_failed", "The app is not in the foreground.")
            return true
        }
        if (requestCode == REQUEST_SAVE) {
            if (bytes == null) {
                replyError("write_failed", "The backup to save was empty.")
                return true
            }
            io.execute {
                try {
                    writeVerified(activity, uri, bytes)
                    reply(true)
                } catch (error: BackupMissingStreamException) {
                    replyError("missing_stream", "The destination did not provide a stream.")
                } catch (error: Exception) {
                    val code = if (isNoSpace(error)) "no_space" else "write_failed"
                    replyError(code, "The destination could not be written.")
                } finally {
                    bytes.fill(0)
                }
            }
            return true
        }
        io.execute {
            try {
                val read = activity.contentResolver.openInputStream(uri)?.use { input ->
                    BackupStreams.readAtMost(input, maxBytes)
                } ?: throw BackupMissingStreamException()
                reply(read)
            } catch (error: BackupTransferLimitException) {
                replyError("oversized", "The selected file is too large.")
            } catch (error: BackupMissingStreamException) {
                replyError("missing_stream", "The selected file did not provide a stream.")
            } catch (error: Exception) {
                replyError("write_failed", "The selected file could not be read.")
            }
        }
        return true
    }

    private fun writeVerified(activity: Activity, uri: Uri, bytes: ByteArray) {
        val resolver = activity.contentResolver
        val descriptor = openDestination(resolver, uri)
        descriptor.use { opened ->
            val output = FileOutputStream(opened.fileDescriptor)
            try {
                BackupStreams.writeThenTruncate(output, bytes) { length ->
                    try {
                        Os.ftruncate(opened.fileDescriptor, length)
                    } catch (error: ErrnoException) {
                        throw IOException("The destination could not be resized.", error)
                    }
                }
                try {
                    Os.fsync(opened.fileDescriptor)
                } catch (error: ErrnoException) {
                    if (error.errno == OsConstants.ENOSPC) {
                        throw IOException("The destination is out of space.", error)
                    }
                }
            } finally {
                output.close()
            }
        }
        val read = resolver.openInputStream(uri)?.use { input ->
            try {
                BackupStreams.readAtMost(input, bytes.size)
            } catch (error: BackupTransferLimitException) {
                throw IOException("The destination kept bytes past the backup.")
            }
        } ?: throw BackupMissingStreamException()
        if (!read.contentEquals(bytes)) {
            throw IOException("The destination contents did not match the backup.")
        }
    }

    private fun openDestination(resolver: ContentResolver, uri: Uri): ParcelFileDescriptor {
        for (mode in arrayOf("rwt", "wt", "w")) {
            try {
                val opened = resolver.openFileDescriptor(uri, mode)
                if (opened != null) {
                    return opened
                }
            } catch (_: FileNotFoundException) {
                continue
            } catch (_: IllegalArgumentException) {
                continue
            }
        }
        throw BackupMissingStreamException()
    }

    private fun reply(value: Any?) {
        val result = takePending() ?: return
        mainHandler.post { result.success(value) }
    }

    private fun replyError(code: String, message: String) {
        val result = takePending() ?: return
        mainHandler.post { result.error(code, message, null) }
    }

    private fun takePending(): MethodChannel.Result? {
        synchronized(this) {
            val result = pending
            pending = null
            return result
        }
    }

    private fun releasePendingBytes(): ByteArray? {
        val bytes = pendingBytes
        pendingBytes = null
        return bytes
    }

    private fun wipePendingBytes() {
        pendingBytes?.fill(0)
        pendingBytes = null
        pendingMaxBytes = 0
    }

    private fun isNoSpace(error: Exception): Boolean {
        var current: Throwable? = error
        while (current != null) {
            if (current is ErrnoException && current.errno == OsConstants.ENOSPC) {
                return true
            }
            val message = current.message?.lowercase() ?: ""
            if (message.contains("no space") || message.contains("enospc")) {
                return true
            }
            current = current.cause
        }
        return false
    }

    private var pendingBytes: ByteArray? = null
    private var pendingMaxBytes: Int = 0

    companion object {
        const val CHANNEL = "com.registry.app/backup_file"
        private const val REQUEST_SAVE = 48121
        private const val REQUEST_PICK = 48122
        private const val MAX_ACCEPTED_BYTES = 32 * 1024 * 1024 + 512
    }
}
