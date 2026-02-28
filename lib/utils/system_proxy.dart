
import 'dart:io';
import 'package:path/path.dart';
import 'package:tm/protos/protos/sysproxy.pb.dart';


class LinuxSystemProxy {
  static Future<void> setSystemProxy(SysProxyConfig settings) async {
    try {
      // Set system proxy using gsettings (GNOME/Unity)
      await _setGsettingsProxy(settings);
      
      // Set environment variables for applications that don't use gsettings
      await _setEnvironmentProxy(settings);
      
      // Set proxy for KDE (if available)
      await _setKdeProxy(settings);
      
      print('Linux system proxy configured successfully');
    } catch (e) {
      print('Failed to set Linux system proxy: $e');
      rethrow;
    }
  }

  static Future<void> unsetSystemProxy() async {
    try {
      // Remove gsettings proxy
      await _unsetGsettingsProxy();
      
      // Remove environment variables
      await _unsetEnvironmentProxy();
      
      // Remove KDE proxy
      await _unsetKdeProxy();
      
      print('Linux system proxy removed successfully');
    } catch (e) {
      print('Failed to remove Linux system proxy: $e');
      rethrow;
    }
  }

  /// Set proxy using gsettings (GNOME/Unity desktop environments)
  static Future<void> _setGsettingsProxy(SysProxyConfig settings) async {
    try {
      // Set proxy mode to manual
      await Process.run('gsettings', [
        'set',
        'org.gnome.system.proxy',
        'mode',
        'manual'
      ]);

      // Set HTTP proxy
      if (settings.hasHttpProxyAddress() && settings.hasHttpProxyPort()) {
        await Process.run('gsettings', [
          'set',
          'org.gnome.system.proxy.http',
          'host',
          settings.httpProxyAddress
        ]);
        await Process.run('gsettings', [
          'set',
          'org.gnome.system.proxy.http',
          'port',
          settings.httpProxyPort.toString()
        ]);
        await Process.run('gsettings', [
          'set',
          'org.gnome.system.proxy.http',
          'enabled',
          'true'
        ]);
      }

      // Set HTTPS proxy
      if (settings.hasHttpsProxyAddress() && settings.hasHttpsProxyPort()) {
        await Process.run('gsettings', [
          'set',
          'org.gnome.system.proxy.https',
          'host',
          settings.httpsProxyAddress
        ]);
        await Process.run('gsettings', [
          'set',
          'org.gnome.system.proxy.https',
          'port',
          settings.httpsProxyPort.toString()
        ]);
        await Process.run('gsettings', [
          'set',
          'org.gnome.system.proxy.https',
          'enabled',
          'true'
        ]);
      }

      // Set SOCKS proxy
      if (settings.hasSocksProxyAddress() && settings.hasSocksProxyPort()) {
        await Process.run('gsettings', [
          'set',
          'org.gnome.system.proxy.socks',
          'host',
          settings.socksProxyAddress
        ]);
        await Process.run('gsettings', [
          'set',
          'org.gnome.system.proxy.socks',
          'port',
          settings.socksProxyPort.toString()
        ]);
        await Process.run('gsettings', [
          'set',
          'org.gnome.system.proxy.socks',
          'enabled',
          'true'
        ]);
      }

      // Set bypass list (localhost and private networks)
      await Process.run('gsettings', [
        'set',
        'org.gnome.system.proxy',
        'ignore-hosts',
        "['localhost', '127.0.0.0/8', '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16']"
      ]);
    } catch (e) {
      print('Failed to set gsettings proxy: $e');
      // Don't rethrow as gsettings might not be available on all systems
    }
  }

  /// Remove gsettings proxy configuration
  static Future<void> _unsetGsettingsProxy() async {
    try {
      await Process.run('gsettings', [
        'set',
        'org.gnome.system.proxy',
        'mode',
        'none'
      ]);
    } catch (e) {
      print('Failed to unset gsettings proxy: $e');
    }
  }

  /// Set environment variables for proxy
  static Future<void> _setEnvironmentProxy(SysProxyConfig settings) async {
    try {
      final envVars = <String, String>{};
      
      if (settings.hasHttpProxyAddress() && settings.hasHttpProxyPort()) {
        final httpProxy = '${settings.httpProxyAddress}:${settings.httpProxyPort}';
        envVars['http_proxy'] = httpProxy;
        envVars['HTTP_PROXY'] = httpProxy;
        envVars['https_proxy'] = httpProxy;
        envVars['HTTPS_PROXY'] = httpProxy;
      }
      
      if (settings.hasSocksProxyAddress() && settings.hasSocksProxyPort()) {
        final socksProxy = 'socks5://${settings.socksProxyAddress}:${settings.socksProxyPort}';
        envVars['all_proxy'] = socksProxy;
        envVars['ALL_PROXY'] = socksProxy;
      }
      
      // Set no_proxy for localhost and private networks
      envVars['no_proxy'] = 'localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16';
      envVars['NO_PROXY'] = 'localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16';
      
      // Write to a shell script that can be sourced
      final script = StringBuffer();
      script.writeln('#!/bin/bash');
      for (final entry in envVars.entries) {
        script.writeln('export ${entry.key}="${entry.value}"');
      }
      
      final scriptFile = File('/tmp/umivpn_proxy_env.sh');
      await scriptFile.writeAsString(script.toString());
      await Process.run('chmod', ['+x', scriptFile.path]);
      
    } catch (e) {
      print('Failed to set environment proxy: $e');
    }
  }

  /// Remove environment proxy variables
  static Future<void> _unsetEnvironmentProxy() async {
    try {
      final script = StringBuffer();
      script.writeln('#!/bin/bash');
      script.writeln('unset http_proxy HTTP_PROXY https_proxy HTTPS_PROXY');
      script.writeln('unset all_proxy ALL_PROXY no_proxy NO_PROXY');
      
      final scriptFile = File('/tmp/umivpn_proxy_env.sh');
      await scriptFile.writeAsString(script.toString());
      await Process.run('chmod', ['+x', scriptFile.path]);
    } catch (e) {
      print('Failed to unset environment proxy: $e');
    }
  }

  /// Set proxy for KDE desktop environment
  static Future<void> _setKdeProxy(SysProxyConfig settings) async {
    try {
      // Check if KDE is available
      final kdeCheck = await Process.run('which', ['kwriteconfig5']);
      if (kdeCheck.exitCode != 0) return;

      // Set HTTP proxy
      if (settings.hasHttpProxyAddress() && settings.hasHttpProxyPort()) {
        await Process.run('kwriteconfig5', [
          '--file',
          'kioslaverc',
          '--group',
          'Proxy Settings',
          '--key',
          'ProxyType',
          '1' // Manual proxy
        ]);
        await Process.run('kwriteconfig5', [
          '--file',
          'kioslaverc',
          '--group',
          'Proxy Settings',
          '--key',
          'httpProxy',
          '${settings.httpProxyAddress} ${settings.httpProxyPort}'
        ]);
      }

      // Set HTTPS proxy
      if (settings.hasHttpsProxyAddress() && settings.hasHttpsProxyPort()) {
        await Process.run('kwriteconfig5', [
          '--file',
          'kioslaverc',
          '--group',
          'Proxy Settings',
          '--key',
          'httpsProxy',
          '${settings.httpsProxyAddress} ${settings.httpsProxyPort}'
        ]);
      }

      // Set SOCKS proxy
      if (settings.hasSocksProxyAddress() && settings.hasSocksProxyPort()) {
        await Process.run('kwriteconfig5', [
          '--file',
          'kioslaverc',
          '--group',
          'Proxy Settings',
          '--key',
          'socksProxy',
          '${settings.socksProxyAddress} ${settings.socksProxyPort}'
        ]);
      }

      // Set bypass list
      await Process.run('kwriteconfig5', [
        '--file',
        'kioslaverc',
        '--group',
        'Proxy Settings',
        '--key',
        'NoProxyFor',
        'localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16'
      ]);
    } catch (e) {
      print('Failed to set KDE proxy: $e');
    }
  }

  /// Remove KDE proxy configuration
  static Future<void> _unsetKdeProxy() async {
    try {
      final kdeCheck = await Process.run('which', ['kwriteconfig5']);
      if (kdeCheck.exitCode != 0) return;

      await Process.run('kwriteconfig5', [
        '--file',
        'kioslaverc',
        '--group',
        'Proxy Settings',
        '--key',
        'ProxyType',
        '0' // No proxy
      ]);
    } catch (e) {
      print('Failed to unset KDE proxy: $e');
    }
  }

  /// Check if the system supports system proxy configuration
  static Future<bool> isSystemProxySupported() async {
    try {
      // Check for gsettings (GNOME/Unity)
      final gsettingsCheck = await Process.run('which', ['gsettings']);
      if (gsettingsCheck.exitCode == 0) return true;

      // Check for KDE
      final kdeCheck = await Process.run('which', ['kwriteconfig5']);
      if (kdeCheck.exitCode == 0) return true;

      // Check for XFCE
      final xfceCheck = await Process.run('which', ['xfconf-query']);
      if (xfceCheck.exitCode == 0) return true;

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get current system proxy configuration
  static Future<SysProxyConfig?> getCurrentProxy() async {
    try {
      final config = SysProxyConfig();
      
      // Try to get gsettings proxy
      final httpHost = await Process.run('gsettings', [
        'get',
        'org.gnome.system.proxy.http',
        'host'
      ]);
      
      if (httpHost.exitCode == 0 && httpHost.stdout.toString().trim() != "''") {
        final httpPort = await Process.run('gsettings', [
          'get',
          'org.gnome.system.proxy.http',
          'port'
        ]);
        
        if (httpPort.exitCode == 0) {
          config.httpProxyAddress = httpHost.stdout.toString().trim().replaceAll("'", "");
          config.httpProxyPort = int.tryParse(httpPort.stdout.toString().trim()) ?? 0;
        }
      }
      
      return config;
    } catch (e) {
      print('Failed to get current proxy: $e');
      return null;
    }
  }
}