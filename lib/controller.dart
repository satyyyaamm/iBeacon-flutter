import 'dart:async';

import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class Controller extends GetxController {
  var bluetoothState = BluetoothState.stateOff.obs;
  var authorizationStatus = AuthorizationStatus.notDetermined.obs;
  var locationService = false.obs;
  late StreamSubscription<RangingResult> streamRanging;
  final beacons = <Beacon>[].obs;
  final _startBroadcasting = false.obs;
  final _startScanning = false.obs;
  final _pauseScanning = false.obs;
  bool get bluetoothEnabled => bluetoothState.value == BluetoothState.stateOn;
  bool get authorizationStatusOk =>
      authorizationStatus.value == AuthorizationStatus.allowed ||
      authorizationStatus.value == AuthorizationStatus.always;
  bool get locationServiceEnabled => locationService.value;

  updateBluetoothState(BluetoothState state) {
    bluetoothState.value = state;
  }

  updateAuthorizationStatus(AuthorizationStatus status) {
    authorizationStatus.value = status;
  }

  updateLocationService(bool flag) {
    locationService.value = flag;
  }

  startBroadcasting() {
    _startBroadcasting.value = true;
  }

  stopBroadcasting() {
    _startBroadcasting.value = false;
  }

  startScanning() {
    _startScanning.value = true;
    _pauseScanning.value = false;
  }

  pauseScanning() {
    _startScanning.value = false;
    _pauseScanning.value = true;
  }

  stopStreamRanging() async {
    await streamRanging.cancel();
  }

  Stream<bool> get startBroadcastStream {
    return _startBroadcasting.stream;
  }

  Stream<bool> get startStream {
    return _startScanning.stream;
  }

  Stream<bool> get pauseStream {
    return _pauseScanning.stream;
  }
}
