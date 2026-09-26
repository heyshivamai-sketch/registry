package com.registry.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var backupFiles: BackupFileBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (backupFiles == null) {
            val bridge = BackupFileBridge()
            backupFiles = bridge
            flutterEngine.plugins.add(bridge)
        }
    }
}
