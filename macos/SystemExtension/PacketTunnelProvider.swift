// Copyright (C) 2026 5V Network LLC <5vnetwork@proton.me>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

//
//  PacketTunnelProvider.swift
//  PacketTunnel
//
//  Created by v on 2024/12/2.
//

import Foundation
import NetworkExtension
import Tm

let XTunnelErrorDomain: String = "XTunnelErrorDomain"

public enum XTunnelError: Error {
    case invalidOptions
    case badConfiguration
    case cannotGetFd
    case xCreateFailed
    case xStartFailed
    case writeToTunFailed
    case nilArgument
    case redirectErrorFailed
    case noXConfig
}

@available(macOSApplicationExtension 11.0, *)
class PacketTunnelProvider: NEPacketTunnelProvider {
    private var x: X_darwinX?
    // used to get fd
    private let CTLIOCGINFO: UInt = 0xc064_4e03
    private let monitor = NWPathMonitor(prohibitedInterfaceTypes: [NWInterface.InterfaceType.other])

    private static var defaultSharedDirectory: URL! {
        let groupIdentifier =
            "K4FDLB3LLD.com.5vnetwork.umivpn.system"
            
        return FileManager.default
            .containerURL(
                forSecurityApplicationGroupIdentifier: groupIdentifier
            )
    }

    override func startTunnel(
        options: [String: NSObject]?
    ) async throws {
        nsLog(msg: "startTunnel")
        nsLog(msg: "options: \(String(describing: options))")
        nsLog(
            msg:
                "protocolConfiguration \(String(describing: (protocolConfiguration as! NETunnelProviderProtocol).providerConfiguration))"
        )
        
        ///Users/shan/Library/Group Containers/K4FDLB3LLD.com.5vnetwork.umivpn/Library/Caches/stderr.log
        ///
        var map: [String: NSObject]? = options

        // TODO: Read configuration by loadAllFromPreferences
        // Vpn is turned on through system center
        if map == nil {
            // TODO: use config file from disk
            let protocolConfiguration =
                protocolConfiguration as! NETunnelProviderProtocol
            map =
                protocolConfiguration.providerConfiguration?["options"]
                as? [String: NSObject]
            map?["config"] = nil
        }

        guard let map else {
            throw fatalError(errorStr: "startTunnel no options")
        }
        
        var enable6 = true
        // four only
        if map["tun46Setting"] as! NSNumber == 0 {
            enable6 = false
        } else if map["tun46Setting"] as! NSNumber == 1 {
            enable6 = true
        } else {
            let turnOnByApp = options != nil
            if turnOnByApp {
                enable6 = map["defaultNicSupport6"] as! NSNumber as! Bool
            } else {
                var enableIpv6: ObjCBool = false
                var error: NSError?
                X_darwinHasNICHavingGlobalIPv6Address(&enableIpv6, &error)
                if error == nil {
                    enable6 = enableIpv6.boolValue
                }
            }
        }

        let settings = try getNetworkSetting(map: map, enableIpv6: enable6)

        nsLog(msg: "networkSetting \(String(describing: settings))")
        try await setTunnelNetworkSettings(settings)

        //        // Start reading packets to get the file descriptor
        //        let _ = await packetFlow.readPackets()

        let fd = getFd()
        if fd != nil {
            let tunName = interfaceName(tunnelFileDescriptor: fd!)
            nsLog(msg: "fd is \(fd!) tun name is \(tunName ?? "")")
        }

        var error: NSError?
        // setup log
        if map["log"] as! NSNumber as! Bool {
            nsLog(msg: "redirect log")
            X_darwinRedirectStderr(
                PacketTunnelProvider.defaultSharedDirectory
                    .appendingPathComponent("latest.txt").relativePath, &error
            )
            if let error {
                throw fatalError(errorStr: error.localizedDescription)
            }
        }

        // x config
        var config = map["config"] as? Data
        if config == nil {
            throw fatalError(errorStr: "no x config")
//            do {
//                NSLog("config path \(map["configPath"] as! String)")
//                config = try Data(contentsOf: URL(fileURLWithPath: map["configPath"] as! String))
//                nsLog(msg: "config file \(String(describing: config!))")
//            } catch {
//                
//            }
        }

        let useFd = map["useFd"] as! NSNumber as! Bool
        x = X_darwinNew(
            config,
            Interface(
                packetTunnelProvider: self,
                isDebug: false,
                useFD: useFd),
            enable6,
            map["geoConfig"] as? Data,
            &error)
        if let error {
            throw fatalError(
                errorStr: "failed to create x: \(error.localizedDescription)")
        }
        do {
            try x!.start()
        } catch {
            throw fatalError(
                errorStr: "failed to start x: \(error.localizedDescription)")
        }
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                self.nsLog(msg: "connected")
                let first = path.availableInterfaces.first { NWInterface in
                    !NWInterface.name.contains("utun")
                }
                if first != nil {
                    X_darwinUpdateDefaultRouteInterface(first!.name)
                }
                path.availableInterfaces.forEach { NWInterface in
                    self.nsLog(msg: "available nic \(NWInterface.name)")
                }
                path.gateways.forEach { NWEndpoint in
                    self.nsLog(msg: "available gateway \(NWEndpoint.debugDescription)")
                }
                self.nsLog(msg: "support ipv6: \(path.supportsIPv6)")
            } else {
                self.nsLog(msg: "no connection")
            }
        }
        monitor.start(queue: DispatchQueue.global())
        if #available(macOS 15.0, *) {
            nsLog(msg: virtualInterface?.name ?? "aaa")
        } else {
            // Fallback on earlier versions
        }
    }

    private func getNetworkSetting(map: [String: NSObject], enableIpv6: Bool)
        throws
        -> NEPacketTunnelNetworkSettings
    {
        let settings = NEPacketTunnelNetworkSettings(
            tunnelRemoteAddress: "127.0.0.1"
        )
        settings.mtu = map["mtu"] as? NSNumber ?? NSNumber(value: 1500)

        var dnsServers = [String]()
        let dnsServers4 = map["dnsServers4"] as? NSArray as? [String]
        if dnsServers4 != nil {
            dnsServers.append(contentsOf: dnsServers4!)
        }
        let dnsServers6 = map["dnsServers6"] as? NSArray as? [String]
        if enableIpv6 && dnsServers6 != nil {
            dnsServers.append(contentsOf: dnsServers6!)
        }
        if dnsServers.count > 0 {
            settings.dnsSettings = NEDNSSettings(servers: dnsServers)
            settings.dnsSettings!.matchDomains = [""]
            settings.dnsSettings!.matchDomainsNoSearch = true

        }

        if let ipv4Addresses = map["ipv4Addresses"] as? NSArray as? [String] {
            if let ipv4SubnetMasks = map["ipv4SubnetMasks"] as? NSArray
                as? [String]
            {
                settings.ipv4Settings = NEIPv4Settings(
                    addresses: ipv4Addresses, subnetMasks: ipv4SubnetMasks)
            } else {
                throw fatalError(errorStr: "invalid ipv4 subnet mask")
            }
            if let ipv4IncludedRoutes = map["ipv4IncludedRoutes"] as? NSArray
                as? [[String: String]]
            {
                settings.ipv4Settings!.includedRoutes = ipv4IncludedRoutes.map {
                    route in
                    NEIPv4Route(
                        destinationAddress: route["destinationAddress"]!,
                        subnetMask: route["subnetMask"]!
                    )
                }
                //                settings.ipv4Settings!.includedRoutes = [
                //                    NEIPv4Route.default()
                //                ]
            }
            if let ipv4ExcludedRoutes = map["ipv4ExcludedRouteAddresses"]
                as? NSArray
                as? [[String: String]]
            {
                settings.ipv4Settings!.excludedRoutes = ipv4ExcludedRoutes.map {
                    route in
                    NEIPv4Route(
                        destinationAddress: route["destinationAddress"]!,
                        subnetMask: route["subnetMask"]!
                    )
                }
            }
        }

        if enableIpv6 {
            if let ipv6Addresses = map["ipv6Addresses"] as? NSArray as? [String]
            {
                if let ipv6NetworkPrefixLengths = map[
                    "ipv6NetworkPrefixLengths"]
                    as? NSArray as? [Int]
                {
                    settings.ipv6Settings = NEIPv6Settings(
                        addresses: ipv6Addresses,
                        networkPrefixLengths: ipv6NetworkPrefixLengths.map {
                            NSNumber(value: $0)
                        }
                    )
                } else {
                    throw fatalError(
                        errorStr: "invalid ipv6 network prefix length")
                }
                if let ipv6IncludedRoutes = map["ipv6IncludedRoutes"]
                    as? NSArray
                    as? [[String: Any]]
                {
                    settings.ipv6Settings!.includedRoutes =
                        ipv6IncludedRoutes.map {
                            route in
                            NEIPv6Route(
                                destinationAddress: route["destinationAddress"]
                                    as! String,
                                networkPrefixLength: (route[
                                    "networkPrefixLength"]
                                    as! Int64) as NSNumber
                            )
                        }
                }
                if let ipv6ExcludedRoutes = map["ipv6ExcludedRoutes"]
                    as? NSArray
                    as? [[String: Any]]
                {
                    settings.ipv6Settings!.excludedRoutes =
                        ipv6ExcludedRoutes.map {
                            route in
                            NEIPv6Route(
                                destinationAddress: route["destinationAddress"]
                                    as! String,
                                networkPrefixLength: (route[
                                    "networkPrefixLength"]
                                    as! Int64) as NSNumber
                            )
                        }
                }
            }
        }

        return settings
    }

    func resetNetworkSetting(enable6: Bool) throws {
        nsLog(msg: "reset network setting: \(enable6.description)")
        let protocolConfiguration =
            protocolConfiguration as! NETunnelProviderProtocol
        let map: [String: NSObject]? =
            protocolConfiguration.providerConfiguration?["options"]
            as? [String: NSObject]
        guard let map else {
            throw fatalError(errorStr: "no providerConfigurations")
        }
        let settings = try getNetworkSetting(map: map, enableIpv6: enable6)
        nsLog(msg: "networkSetting \(String(describing: settings))")
        setTunnelNetworkSettings(settings) { error in
            if error != nil {
                self.nsLog(msg: error?.localizedDescription ?? "")
                self.cancelTunnelWithError(error)
            }
        }
    }

    private func fatalError(errorStr: String) -> Error {
        nsLog(msg: errorStr)
        let err = NSError(domain: errorStr, code: 0)
        cancelTunnelWithError(err)
        return err
    }

    func nsLog(msg: String) {
        #if DEBUG
            NSLog(msg)
        #endif
    }

    func getFd() -> Int32? {
        var fd =
            packetFlow.value(forKeyPath: "socket.fileDescriptor")
            as? Int32
        if fd != nil {
            nsLog(msg: "getFd first method works!")
            return fd
        }

        fd = X_darwinGetFd()
        if fd! > 0 {
            return fd
        }
        return nil

    }

    public func interfaceName(tunnelFileDescriptor: Int32) -> String? {
        var buffer = [UInt8](repeating: 0, count: Int(IFNAMSIZ))

        return buffer.withUnsafeMutableBufferPointer { mutableBufferPointer in
            guard let baseAddress = mutableBufferPointer.baseAddress else {
                return nil
            }

            var ifnameSize = socklen_t(IFNAMSIZ)
            let result = getsockopt(
                tunnelFileDescriptor,
                2 /* SYSPROTO_CONTROL */,
                2 /* UTUN_OPT_IFNAME */,
                baseAddress,
                &ifnameSize)

            if result == 0 {
                return String(cString: baseAddress)
            } else {
                return nil
            }
        }
    }

    override func stopTunnel(
        with reason: NEProviderStopReason,
        completionHandler: @escaping () -> Void
    ) {
        nsLog(msg: "stopTunnel reason: \(reason)")
        do {
            try x?.close()
            x = nil
        } catch {
            nsLog(msg: "close x failed: \(error)")
        }
        monitor.cancel()
        completionHandler()
    }

    override func handleAppMessage(
        _ messageData: Data, completionHandler: ((Data?) -> Void)?
    ) {
        nsLog(msg: "handleAppMessage")

        // Add code here to handle the message.
        if let handler = completionHandler {
            handler(messageData)
        }
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        // Add code here to get ready to sleep.
        completionHandler()
    }

    override func wake() {
        // Add code here to wake up.
    }
}

@available(macOSApplicationExtension 11.0, *)
class Interface: NSObject, X_darwinInterfaceProtocol {
    func setTunSupport6(_ support6: Bool) throws {
        try packetTunnelProvider.resetNetworkSetting(enable6: support6)
    }

    private let packetTunnelProvider: PacketTunnelProvider
    private let isDebug: Bool
    private let useFD: Bool

    init(
        packetTunnelProvider: PacketTunnelProvider,
        isDebug: Bool, useFD: Bool
    ) {
        self.packetTunnelProvider = packetTunnelProvider
        self.isDebug = isDebug
        self.useFD = useFD

    }

    //    func getLogger() -> (any X_darwinLoggerProtocol)? {
    //        if isDebug {
    //            return Logger(packetTunnelProvider: packetTunnelProvider)
    //        } else {
    //            return nil
    //        }
    //    }

    //    func useFd() -> Bool {
    //        return useFD
    //    }

    //    func getTun() -> (any X_darwinTunProtocol)? {
    //        return Tun(packetTunnelProvider: self.packetTunnelProvider)
    //    }

    func getFd(_ ret0_: UnsafeMutablePointer<Int32>?) throws {
        let fd = packetTunnelProvider.getFd()
        if fd == nil {
            throw XTunnelError.cannotGetFd as NSError
        }
        if ret0_ == nil {
            throw XTunnelError.nilArgument as NSError
        }
        ret0_!.pointee = fd!
    }

    func getTunName() -> String {
        packetTunnelProvider.nsLog(msg: "getTunName")
        if #available(macOS 15.0, *) {
            return packetTunnelProvider.virtualInterface?.name ?? ""
        } else {
            // Fallback on earlier versions
            return ""
        }
    }

    func getDnsServers(forInterface p0: String?) -> (
        any X_darwinStringsProtocol
    )? {
        return nil
    }

}

//class Logger: NSObject, X_darwinLoggerProtocol {
//    private let packetTunnelProvider: PacketTunnelProvider
//    init(packetTunnelProvider: PacketTunnelProvider) {
//        self.packetTunnelProvider = packetTunnelProvider
//    }
//
//    func log(_ p0: String?) {
//        if let p0 {
//            packetTunnelProvider.nsLog(msg: p0)
//        }
//    }
//}
//
//class Tun: NSObject, X_darwinTunProtocol {
//    private let packetTunnelProvider: PacketTunnelProvider
//    private var packets: [Data] = []
//
//    init(packetTunnelProvider: PacketTunnelProvider) {
//        self.packetTunnelProvider = packetTunnelProvider
//    }
//
//    func readPacket() throws -> Data {
//        // If we have cached packets, return the first one
//        if !packets.isEmpty {
//            let packet = packets.removeFirst()
//            return packet
//        }
//
//        // Read new packets
//        let semaphore = DispatchSemaphore(value: 0)
//        var newPackets: [Data] = []
//
//        packetTunnelProvider.packetFlow.readPackets { (packets, protocols) in
//            newPackets = packets
//            semaphore.signal()
//        }
//
//        // Wait indefinitely until packets are available
//        semaphore.wait()
//
//        // Cache remaining packets
//        if newPackets.count > 1 {
//            packets = Array(newPackets.dropFirst())
//        }
//
//        // Return first packet (we know there's at least one packet at this point)
//        return newPackets[0]
//    }
//
//    func writePacket(_ p0: Data?, p1: Int) throws {
//        packetTunnelProvider.nsLog(msg: "writePacket")
//        guard let packet = p0 else {
//            packetTunnelProvider.nsLog(msg: "writePacket has no data")
//            return
//        }
//
//        // Write the packet
//        let success = packetTunnelProvider.packetFlow.writePackets(
//            [packet], withProtocols: [NSNumber(value: Int32(p1))])
//        if !success {
//            packetTunnelProvider.nsLog(msg: "writePacket failed")
//            throw XTunnelError.writeToTunFailed as NSError
//        }
//    }
//}


