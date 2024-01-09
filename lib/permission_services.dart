import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _permissions = PermissionService._internal();

  factory PermissionService() {
    return _permissions;
  }

  PermissionService._internal();

  static Future<bool> checkSystemOverlayPermission() async {
    return await Permission.systemAlertWindow.status.isGranted;
  }

  static Future<bool> checkLocationPermission() async {
    return await Permission.locationAlways.status.isGranted;
  }

  static Future<bool> checkBluetoothPermission() async {
    return await Permission.bluetooth.status.isGranted;
  }

  static Future<bool> requestSystemOverLayPermission() async {
    PermissionStatus status = await Permission.systemAlertWindow.request();
    return status.isGranted;
  }

  static Future<bool> requestLocationPermission(context) async {
    if (Platform.isIOS) {
      LocationPermission permission = await Geolocator.requestPermission();
      if (LocationPermission.always == permission) {
        return true;
      } else {
        return await showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
                  content: const Text('Set Permission to Always'),
                  actions: <Widget>[
                    CupertinoDialogAction(
                      child: const Text("Continue"),
                      onPressed: () {
                        Geolocator.openLocationSettings();
                        Navigator.pop(context, true);
                      },
                    ),
                    CupertinoDialogAction(
                      child: const Text("Cancel"),
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                    ),
                  ],
                ));
      }
    } else {
      var status = await Permission.locationAlways.request();
      if (status.isGranted) {
        return status.isGranted;
      } else if (status.isPermanentlyDenied) {
        return await Geolocator.openLocationSettings();
      } else if (status.isPermanentlyDenied) {
        return await Geolocator.openLocationSettings();
      } else if (status.isRestricted) {
        return await Geolocator.openLocationSettings();
      } else {
        return await Geolocator.openLocationSettings();
      }
    }
  }

  static Future requestBluetoothPermission(context) async {
    if (Platform.isIOS) {
      PermissionStatus permission = await Permission.bluetooth.request();
      if (PermissionStatus.granted == permission) {
        return true;
      } else {
        return await showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
                  content: const Text(
                      'App wants your bluetooth to be turn ON to enable scanning of beacon around you to enhance your navigation experience.'),
                  actions: <Widget>[
                    CupertinoDialogAction(
                        onPressed: () {
                          AppSettings.openDeviceSettings();
                          Navigator.pop(context, true);
                        },
                        child: const Text("Continue")),
                    CupertinoDialogAction(
                      child: const Text("Cancel"),
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                    ),
                  ],
                ));
      }
    }
  }
}
