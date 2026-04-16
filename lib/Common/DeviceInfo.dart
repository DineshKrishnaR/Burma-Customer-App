import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:localstorage/localstorage.dart';
import 'dart:developer' as developer;


class Device {
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  final LocalStorage storage = new LocalStorage('app_store');

  Map<String, dynamic> _deviceData = <String, dynamic>{};
  initPlatformState() async {
    var deviceData = <String, dynamic>{};

    try {
      // if (kIsWeb) {
      //   deviceData = _readWebBrowserInfo(await deviceInfoPlugin.webBrowserInfo);
      // } else {
      if (Platform.isAndroid) {
         AndroidDeviceInfo build = await deviceInfoPlugin.androidInfo;
        // deviceData = _readAndroidBuildData(await deviceInfoPlugin.androidInfo);
        // await storage.setItem('device_id', deviceData['androidId']?.toString() ?? '');
        // print('****DEVICE ID:********${deviceData['androidId']}');
        await storage.setItem('device_name', "${build.brand} ${build.model}");
  await storage.setItem('device_model', build.model ?? "");
  await storage.setItem('os_version', build.version.release ?? "");
  await storage.setItem('device_id', build.fingerprint ?? "");
        // print(deviceInfoPlugin.androidInfo);
      }
       else if (Platform.isIOS) {
        deviceData = _readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
        print('****DEVICE ID:********${deviceData['identifierForVendor']}');
        await storage.setItem('device_id', deviceData['identifierForVendor']?.toString() ?? '');
      }
      //  else if (Platform.isLinux) {
      //   deviceData = _readLinuxDeviceInfo(await deviceInfoPlugin.linuxInfo);
      //    storage.setItem('device_id', deviceData['androidId']);
      // } else if (Platform.isMacOS) {
      //   deviceData = _readMacOsDeviceInfo(await deviceInfoPlugin.macOsInfo);
      // } else if (Platform.isWindows) {
      //   deviceData = _readWindowsDeviceInfo(await deviceInfoPlugin.windowsInfo);
      //    storage.setItem('device_id', deviceData['androidId']);
      // }
      return deviceData;
      // }
    } on PlatformException {
      return deviceData = <String, dynamic>{
        'Error:': 'Failed to get platform version.'
      };
    }

    // if (!mounted) return;

    // setState(() {
    //   _deviceData = deviceData;
    // });
  }

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
     
      'version.securityPatch': build.version.securityPatch,
      'version.sdkInt': build.version.sdkInt,
      'version.release': build.version.release,
      'version.previewSdkInt': build.version.previewSdkInt,
      'version.incremental': build.version.incremental,
      'version.codename': build.version.codename,
      'version.baseOS': build.version.baseOS,
      'board': build.board,
      'bootloader': build.bootloader,
      'brand': build.brand,
      'device': build.device,
      'display': build.display,
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'host': build.host,
      'id': build.id,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'supported32BitAbis': build.supported32BitAbis,
      'supported64BitAbis': build.supported64BitAbis,
      'supportedAbis': build.supportedAbis,
      'tags': build.tags,
      'type': build.type,                           
      'isPhysicalDevice': build.isPhysicalDevice,
      'systemFeatures': build.systemFeatures,
      'serialNumber': build.serialNumber,
      'isLowRamDevice': build.isLowRamDevice,
      'androidId': build.id,
      // 'displaySizeInches':
      //     ((build.displayMetrics.sizeInches * 10).roundToDouble() / 10),
      // 'displayWidthPixels': build.displayMetrics.widthPx,
      // 'displayWidthInches': build.displayMetrics.widthInches,
      // 'displayHeightPixels': build.displayMetrics.heightPx,
      // 'displayHeightInches': build.displayMetrics.heightInches,
      // 'displayXDpi': build.displayMetrics.xDpi,
      // 'displayYDpi': build.displayMetrics.yDpi,
      // 'serialNumber': build.serialNumber,
    };
  }

  Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return <String, dynamic>{
      'name': data.name,
      'systemName': data.systemName,
      'systemVersion': data.systemVersion,
      'model': data.model,
      'localizedModel': data.localizedModel,
      'identifierForVendor': data.identifierForVendor,
      'isPhysicalDevice': data.isPhysicalDevice,
      'utsname.sysname:': data.utsname.sysname,
      'utsname.nodename:': data.utsname.nodename,
      'utsname.release:': data.utsname.release,
      'utsname.version:': data.utsname.version,
      'utsname.machine:': data.utsname.machine,
    };
  }

}
