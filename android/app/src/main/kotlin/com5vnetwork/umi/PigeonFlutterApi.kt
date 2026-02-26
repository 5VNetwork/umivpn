package com5vnetwork.umi

import AndroidFlutterApi
import io.flutter.embedding.engine.plugins.FlutterPlugin

class PigeonFlutterApi(binary:  io.flutter.plugin.common.BinaryMessenger)  {
    var flutterApi: AndroidFlutterApi? = null

    init {
        flutterApi = AndroidFlutterApi(binary)
    }

    fun defaultNetwork(isPhysical: Boolean) {
        flutterApi!!.defaultNetworkChanged(isPhysical) {  }
    }
}