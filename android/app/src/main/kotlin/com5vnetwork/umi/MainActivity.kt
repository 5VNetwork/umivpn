package com5vnetwork.umi

import AndroidHostApi
import AndroidHostApiImpl
import io.flutter.embedding.android.FlutterActivity
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val hostApi = AndroidHostApiImpl(this, PigeonFlutterApi(flutterEngine.dartExecutor.binaryMessenger))
        AndroidHostApi.setUp(flutterEngine.dartExecutor.binaryMessenger, hostApi)
    }
}
