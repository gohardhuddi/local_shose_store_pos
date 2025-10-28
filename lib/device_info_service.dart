// lib/services/device_info_service.dart
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:platform/platform.dart';
import 'package:uuid/uuid.dart';

class DeviceInfoService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();
  static const String _storageKey = 'app_device_id_v1';
  static final LocalPlatform _platform = LocalPlatform();

  /// Returns a Map with platform: <string>, and platform-specific fields.
  /// Includes a computed 'deviceId' (SHA256 hash).
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final Map<String, dynamic> map = <String, dynamic>{};

    try {
      // ---------- PLATFORM SPECIFIC INFO ----------
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        map['platform'] = 'web';
        map.addAll(_cleanMap(webInfo.toMap()));
      } else if (_platform.isAndroid) {
        final android = await _deviceInfo.androidInfo;
        map['platform'] = 'android';
        map.addAll(_readAndroidInfo(android));
      } else if (_platform.isIOS) {
        final ios = await _deviceInfo.iosInfo;
        map['platform'] = 'ios';
        map.addAll(_readIosInfo(ios));
      } else if (_platform.isMacOS) {
        final mac = await _deviceInfo.macOsInfo;
        map['platform'] = 'macos';
        map.addAll(_readMacOsInfo(mac));
      } else if (_platform.isWindows) {
        final win = await _deviceInfo.windowsInfo;
        map['platform'] = 'windows';
        map.addAll(_readWindowsInfo(win));
      } else if (_platform.isLinux) {
        final linux = await _deviceInfo.linuxInfo;
        map['platform'] = 'linux';
        map.addAll(_readLinuxInfo(linux));
      } else {
        map['platform'] = 'unknown';
      }

      // ---------- DEVICE ID / FINGERPRINT ----------
      final deviceId = await _getOrCreateDeviceId(map);
      map['deviceId'] = deviceId;
    } catch (e, st) {
      map['error'] = 'Failed to get device info: $e';
      final id = await _getOrCreateDeviceId({});
      map['deviceId'] = id;
      map['exceptionStack'] = st.toString();
    }

    return map;
  }

  // Persisted fingerprint id (skip secure storage on macOS for now)
  static Future<String> _getOrCreateDeviceId(Map<String, dynamic> info) async {
    // ✅ Skip secure storage only on macOS to avoid entitlement crash
    if (_platform.isMacOS) {
      print(
        "⚠️ macOS detected — using temporary device ID (no secure storage)",
      );
      return _generateHashedId(info);
    }

    // ✅ Normal secure storage path (Android, iOS, Windows, Linux)
    final stored = await _secureStorage.read(key: _storageKey);
    if (stored != null && stored.isNotEmpty) return stored;

    final id = _generateHashedId(info);

    // store securely
    await _secureStorage.write(key: _storageKey, value: id);
    return id;
  }

  // Actually creates the hash from available identifiers
  static String _generateHashedId(Map<String, dynamic> info) {
    String candidate = '';

    if (info.containsKey('androidId') &&
        (info['androidId'] as String).isNotEmpty) {
      candidate = info['androidId'] as String;
    } else if (info.containsKey('identifierForVendor') &&
        (info['identifierForVendor'] as String).isNotEmpty) {
      candidate = info['identifierForVendor'] as String;
    } else if (info.containsKey('machineId') &&
        (info['machineId'] as String).isNotEmpty) {
      candidate = info['machineId'] as String;
    } else if (info.containsKey('computerName') &&
        (info['computerName'] as String).isNotEmpty) {
      candidate = info['computerName'] as String;
    } else {
      // fallback build
      final parts = <String>[];
      if (info.containsKey('model')) parts.add('${info['model']}');
      if (info.containsKey('manufacturer'))
        parts.add('${info['manufacturer']}');
      if (info.containsKey('osVersion')) parts.add('${info['osVersion']}');
      candidate = parts.join('|');
    }

    if (candidate.trim().isEmpty) {
      candidate = const Uuid().v4(); // final fallback
    }

    final raw = '${info['platform'] ?? 'unknown'}|$candidate';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  // ---- Device info normalization helpers ----
  static Map<String, dynamic> _readAndroidInfo(AndroidDeviceInfo a) {
    return _cleanMap({
      'manufacturer': a.manufacturer,
      'brand': a.brand,
      'device': a.device,
      'model': a.model,
      'product': a.product,
      'androidId': a.id ?? '',
      'versionSdkInt': a.version.sdkInt,
      'versionRelease': a.version.release,
    });
  }

  static Map<String, dynamic> _readIosInfo(IosDeviceInfo i) {
    return _cleanMap({
      'name': i.name,
      'systemName': i.systemName,
      'systemVersion': i.systemVersion,
      'model': i.model,
      'identifierForVendor': i.identifierForVendor ?? '',
      'utsname': i.utsname.machine,
    });
  }

  static Map<String, dynamic> _readMacOsInfo(MacOsDeviceInfo m) {
    return _cleanMap({
      'computerName': m.computerName,
      'hostName': m.hostName,
      'model': m.model,
      'arch': m.arch,
      'kernelVersion': m.kernelVersion,
      'osRelease': m.osRelease,
      'activeCPUs': m.activeCPUs,
      'memorySize': m.memorySize,
    });
  }

  static Map<String, dynamic> _readWindowsInfo(WindowsDeviceInfo w) {
    return _cleanMap({
      'computerName': w.computerName,
      'numberOfCores': w.numberOfCores,
      'systemMemoryInMegabytes': w.systemMemoryInMegabytes,
      'deviceId': w.deviceId,
      'productName': w.productName,
      'buildNumber': w.buildNumber,
    });
  }

  static Map<String, dynamic> _readLinuxInfo(LinuxDeviceInfo l) {
    return _cleanMap({
      'name': l.name,
      'version': l.version,
      'id': l.id,
      'machineId': l.machineId,
    });
  }

  static Map<String, dynamic> _cleanMap(Map<String, dynamic> m) {
    final out = <String, dynamic>{};
    m.forEach((k, v) {
      if (v == null) return;
      if (v is num || v is bool || v is String) {
        out[k] = v;
      } else {
        out[k] = v.toString();
      }
    });
    return out;
  }
}
