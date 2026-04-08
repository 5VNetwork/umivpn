import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Build
import android.util.Log
import io.tm.android.x_android.StringList
import io.tm.android.x_android.X_android
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.app.StatusBarManager
import android.content.ComponentName
import android.net.NetworkRequest
import androidx.annotation.RequiresApi
import androidx.core.graphics.drawable.IconCompat
import com5vnetwork.tm_android.MyTileService
import com5vnetwork.umi.PigeonFlutterApi

class AndroidHostApiImpl(
    private val context: Context,
    private val flutterApi: PigeonFlutterApi
) : AndroidHostApi {
    private var defaultNetworkCallbackObject: ConnectivityManager.NetworkCallback? = null

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

    override fun requestAddTile() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            Log.w("QS", "requestAddTile ignored: requires Android 13+")
            return
        }

        val drawableResourceId: Int = com5vnetwork.tm_android.R.drawable.tile_icon

        val icon = IconCompat.createWithResource(
            context, drawableResourceId
        )

        val statusBarService = context.getSystemService(
            StatusBarManager::class.java
        )

        if (statusBarService == null) {
            Log.w("QS", "requestAddTile ignored: StatusBarManager unavailable")
            return
        }

        try {
            statusBarService.requestAddTileService(
                ComponentName(context, MyTileService::class.java),
                "Umi",
                icon.toIcon(context),
                {}
            ) { result ->
                Log.d("QS", "requestAddTileService result: $result")
            }
        } catch (e: NoSuchMethodError) {
            Log.w("QS", "requestAddTile ignored: framework method not available", e)
        } catch (e: Throwable) {
            Log.e("QS", "requestAddTile failed", e)
        }
    }

    override fun startBindToDefaultNetwork() {
        startMonitorDefaultNIC()
    }

    private val handler = Handler(Looper.getMainLooper())
    private fun startMonitorDefaultNIC() {
        val connectivityManager = context.getSystemService(ConnectivityManager::class.java)
        // This monitor default network change, both VPN or physical
        defaultNetworkCallbackObject = object : ConnectivityManager.NetworkCallback() {
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
        connectivityManager.registerDefaultNetworkCallback(defaultNetworkCallbackObject!!)

        // This only monitor default physical network change
//        val networkRequest = NetworkRequest.Builder()
//            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
//            .removeTransportType(NetworkCapabilities.TRANSPORT_VPN)
//            .build()
//        networkChangeCallbackObject = object : ConnectivityManager.NetworkCallback() {
//            override fun onAvailable(network: Network) {
//                super.onAvailable(network)
//                Log.d("NetworkChangeMonitor", "Network is available $network")
//            }
//
//            override fun onLinkPropertiesChanged(network: Network, linkProperties: LinkProperties) {
//                super.onLinkPropertiesChanged(network, linkProperties)
//                Log.d("NetworkChangeMonitor", "Link properties changed: $linkProperties")
//                onNetworkChange(network)
//            }
//        }
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
//            connectivityManager.registerBestMatchingNetworkCallback(
//                networkRequest,
//                networkChangeCallbackObject!!,
//                handler
//            )
//        } else {
//            connectivityManager.requestNetwork(
//                networkRequest,
//                networkChangeCallbackObject!!,
//                handler
//            )
//        }
    }

    private fun notifyFlutter(networkCapabilities: NetworkCapabilities) {
        if (networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_VPN)) {
            handler.post { flutterApi.defaultNetwork(true) }
        } else if (networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
            handler.post { flutterApi.defaultNetwork(false) }
        }
    }

    // get current active network and notify nic listeners
    private fun onNetworkChange(network: Network) {
        val connectivityManager = context.getSystemService(ConnectivityManager::class.java)
//        val active = connectivityManager.activeNetwork
        val linkProperties = connectivityManager.getLinkProperties(network)
        if (linkProperties != null) {
            val dnsServers = ArrayList<String?>()
            for (inetAddress in linkProperties.dnsServers) {
                dnsServers.add(inetAddress.hostAddress)
            }
            val dnsServerList = object : StringList {
                val l = linkProperties.dnsServers.size.toLong()
                val strings = dnsServers
                override fun get(var1: Long): String? {
                    return strings[var1.toInt()]
                }

                override fun len(): Long {
                    return l
                }
            }
            val linkAddresses = ArrayList<String?>()
            for (linkAddress in linkProperties.linkAddresses) {
                linkAddresses.add(linkAddress.address.hostAddress)
            }
            val nicAddressList = object : StringList {
                val l = linkProperties.linkAddresses.size.toLong()
                val strings = linkAddresses
                override fun get(var1: Long): String? {
                    return strings[var1.toInt()]
                }

                override fun len(): Long {
                    return l
                }
            }
            X_android.updateDefaultNICInfo(
                linkProperties.interfaceName,
                nicAddressList,
                dnsServerList
            )
        }
    }
}

