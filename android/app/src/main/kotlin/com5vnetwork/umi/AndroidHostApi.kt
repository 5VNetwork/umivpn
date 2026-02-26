import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import android.util.Log
import io.tm.android.x_android.StringList
import io.tm.android.x_android.X_android
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.app.StatusBarManager
import android.content.ComponentName
import android.graphics.drawable.Icon
import androidx.annotation.RequiresApi
import androidx.core.graphics.drawable.IconCompat
import com5vnetwork.tm_android.MyTileService
import com5vnetwork.umi.PigeonFlutterApi

class AndroidHostApiImpl(private val context: Context,
                         private val flutterApi: PigeonFlutterApi) : AndroidHostApi {
    private var networkCallback: ConnectivityManager.NetworkCallback? = null


    override fun startXApiServer(config: ByteArray, callback: (Result<Unit>) -> Unit) {
        try {
            X_android.startApiServer(config)
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("", e.toString(), "")))
        }
        callback(Result.success(Unit))
    }

    override fun generateTls(): ByteArray {
        return X_android.generateTls()
    }

    override fun redirectStdErr(path: String) {
        X_android.redirectStderr(path);
    }

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    override fun requestAddTile() {
        val drawableResourceId: Int = com5vnetwork.tm_android.R.drawable.tile_icon

        val icon = IconCompat.createWithResource(
            context, drawableResourceId
        )

        val statusBarService = context.getSystemService(
            StatusBarManager::class.java
        )

        statusBarService.requestAddTileService(ComponentName(context, MyTileService::class.java),
            "UmiVPN",
            icon.toIcon(context),
            {}) { result ->
            Log.d("QS", "requestAddTileService result: $result")
        }
    }

    override fun startBindToDefaultNetwork() {
        startMonitorDefaultNIC()
    }

    private val handler = Handler(Looper.getMainLooper())
    private fun startMonitorDefaultNIC() {
        val connectivityManager = context.getSystemService(ConnectivityManager::class.java)
        networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                super.onAvailable(network)
                Log.d("NetworkChangeMonitor", "Network is available $network")
            }

            override fun onLinkPropertiesChanged(network: Network, linkProperties: LinkProperties) {
                super.onLinkPropertiesChanged(network, linkProperties)
                Log.d("NetworkChangeMonitor", "Link properties changed: $linkProperties")
            }

            override fun onCapabilitiesChanged(
                network: Network,
                networkCapabilities: NetworkCapabilities
            ) {
                super.onCapabilitiesChanged(network, networkCapabilities)
                Log.d("NetworkChangeMonitor", "capabilities changed: $networkCapabilities")
                notifyFlutter(networkCapabilities)
            }
        }
        connectivityManager.registerDefaultNetworkCallback(networkCallback!!)
    }

    private fun notifyFlutter(networkCapabilities: NetworkCapabilities) {
        if (networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_VPN)) {
            handler.post { flutterApi.defaultNetwork(true) }
        } else if (networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
            handler.post { flutterApi.defaultNetwork(false) }
        }
    }
}

