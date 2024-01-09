// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:get/get.dart';
import 'package:ibeacon_integration/controller.dart';
import 'package:ibeacon_integration/permission_services.dart';
import 'package:open_settings/open_settings.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  StreamSubscription<RangingResult>? _streamRanging;
  StreamSubscription<BluetoothState>? _streamBluetooth;
  final _regionBeacons = <Region, List<Beacon>>{};
  final controller = Get.put(Controller());

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _checkBluetoothPermission();
    WidgetsBinding.instance.addObserver(this);

    controller.startStream.listen((flag) {
      if (flag == true) {
        initScanBeacon();
      }
    });

    controller.pauseStream.listen((flag) {
      if (flag == true) {
        pauseScanBeacon();
      }
    });

    listeningState();
    checkAllRequirements();
    initScanBeacon();
  }

  _checkLocationPermission() async {
    try {
      bool status = await PermissionService.checkLocationPermission();
      if (status) {
        print(Permission.bluetoothScan.status);
      } else {
        print(Permission.bluetoothScan.status);
        bool locationPermissionStatus = await PermissionService.requestLocationPermission(context);
        if (locationPermissionStatus) {
          showBluetoothDialog();
          // await _fetchDataFromDataBase();
        } // SystemNavigator.pop();
      }
    } catch (e) {
      print(e);
    }
  }

  _checkBluetoothPermission() async {
    try {
      bool status = await PermissionService.checkBluetoothPermission();
      if (status) {
        print('Bluetooth Permission: ${Permission.bluetoothScan.status}');
      } else {
        print('Bluetooth Permission: ${Permission.bluetoothScan.status}');
        bool bluetoothPermissionStatus =
            await PermissionService.requestBluetoothPermission(context);
        if (bluetoothPermissionStatus) {
          showBluetoothDialog();
          // await _fetchDataFromDataBase();
        } // SystemNavigator.pop();
      }
    } catch (e) {}
  }

  showLocationDialog() {
    print('location dialog');
    if (Platform.isIOS) {
      return CupertinoAlertDialog(
        title: const Text("UJ Wayfinder Location"),
        content: const Text(
            "App collects location data to enable scanning of beacon around you to enhance your navigation experience even when the app is close or not in use."),
        actions: <Widget>[
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("Yes"),
            onPressed: () async {
              Navigator.pop(context);
              await Permission.location.request();
              // showBluetoothDialog();
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
            child: const Text("No"),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      );
    } else {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: const Text(
                  'App collects location data to enable scanning of beacon around you to enhance your navigation experience even when the app is close or not in use.'),
              actions: [
                TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await Permission.location.request();
                      Navigator.pop(context);
                    },
                    child: const Text('Allow')),
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Deny'))
              ],
            );
          });
    }
  }

  showBluetoothDialog() {
    print('bluetooth dialog');
    if (Platform.isIOS) {
      return CupertinoAlertDialog(
        title: const Text("UJ Wayfinder Location"),
        content: const Text(
            'App wants your bluetooth to be turn ON to enable scanning of beacon around you to enhance your navigation experience.'),
        actions: <Widget>[
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("Yes"),
            onPressed: () async {
              Navigator.pop(context);
              await Permission.bluetoothScan.request();
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
            child: const Text("No"),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      );
    } else {
      return showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: const Text(
                  'App wants your bluetooth to be turn ON to enable scanning of beacon around you to enhance your navigation experience.'),
              actions: [
                TextButton(
                    onPressed: () async {
                      OpenSettings.openBluetoothSetting();
                    },
                    child: const Text('Allow')),
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Deny'))
              ],
            );
          });
    }
  }

  void listeningState() async {
    print('Listening to bluetooth state');
    await flutterBeacon.initializeAndCheckScanning;
    _streamBluetooth = flutterBeacon.bluetoothStateChanged().listen((BluetoothState state) async {
      controller.updateBluetoothState(state);
      checkAllRequirements();
    });
  }

  void checkAllRequirements() async {
    print('CHECKALLREQUIRMENTS');
    final bluetoothState = await flutterBeacon.bluetoothState;
    controller.updateBluetoothState(bluetoothState);
    print('BLUETOOTH $bluetoothState');
    final authorizationStatus = await flutterBeacon.authorizationStatus;
    print('AUTHORIZATION 1$authorizationStatus');
    controller.updateAuthorizationStatus(authorizationStatus);
    print('AUTHORIZATION 2$authorizationStatus');

    final locationServiceEnabled = await flutterBeacon.checkLocationServicesIfEnabled;
    controller.updateLocationService(locationServiceEnabled);
    print('LOCATION SERVICE $locationServiceEnabled');

    if (controller.bluetoothEnabled &&
        controller.authorizationStatusOk &&
        controller.locationServiceEnabled) {
      print('STATE READY');
      print('SCANNING 1');
      controller.startScanning();
    } else {
      print('STATE NOT READY');
      controller.pauseScanning();
    }
  }

  initScanBeacon() async {
    await flutterBeacon.initializeScanning;
    if (!controller.authorizationStatusOk ||
        !controller.locationServiceEnabled ||
        !controller.bluetoothEnabled) {
      print('RETURNED, authorizationStatusOk=${controller.authorizationStatusOk}, '
          'locationServiceEnabled=${controller.locationServiceEnabled}, '
          'bluetoothEnabled=${controller.bluetoothEnabled}');
      return;
    }

    final regions = <Region>[];

    regions.add(
        Region(identifier: 'wifi_area', proximityUUID: "702F0AFC-B84B-4F2E-BC8A-B0808FC98C8C"));

    if (_streamRanging!.isPaused) {
      _streamRanging!.resume();
      return;
    }

    _streamRanging = flutterBeacon.ranging(regions).listen((RangingResult result) {
      print("result: $result");
      try {
        if (mounted) {
          setState(() {
            // _regionBeacons[result.region] =
            result.beacons.forEach((beacon) {
              if (_regionBeacons[result.region]![0].rssi == 0) {
                print('major: ${beacon.major} \n minor: ${beacon.minor} \n rssi: ${beacon.rssi}');
              } else {
                controller.beacons.clear();
                for (var list in _regionBeacons.values) {
                  controller.beacons.addAll(list);
                  controller.beacons.sort(_compareParameters);
                }
              }
            });
          });
        }
      } catch (e) {
        print('Flutter beacon ranging error $e');

        showDialog(
            context: context,
            builder: (context) {
              return const AlertDialog(
                content: Text('Flutter beacon ranging error'),
              );
            });
      }
    });
  }

  pauseScanBeacon() async {
    _streamRanging!.pause();
    if (controller.beacons.isNotEmpty) {
      // setState(() {
      controller.beacons.clear();
      // });
    }
  }

  int _compareParameters(Beacon a, Beacon b) {
    int compare = b.proximityUUID.compareTo(a.proximityUUID);

    if (compare == 0) {
      compare = b.rssi.compareTo(a.rssi);
    }

    if (compare == 0) {
      compare = a.major.compareTo(b.major);
    }

    if (compare == 0) {
      compare = a.minor.compareTo(b.minor);
    }

    return compare;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    print('AppLifecycleState = $state');
    if (state == AppLifecycleState.resumed) {
      if (_streamBluetooth!.isPaused) {
        _streamBluetooth!.resume();
      }
      checkAllRequirements();
    } else if (state == AppLifecycleState.paused) {
      _streamBluetooth!.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.amberAccent,
          title: const Text(
            'FLUTTER BEACON',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            ),
            tooltip: 'Back',
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
          centerTitle: false,
          actions: <Widget>[
            Obx(() {
              if (!controller.locationServiceEnabled) {
                return IconButton(
                  tooltip: 'Not Determined',
                  icon: const Icon(Icons.portable_wifi_off),
                  color: Colors.grey,
                  onPressed: () {},
                );
              }

              if (!controller.authorizationStatusOk) {
                return IconButton(
                  tooltip: 'Not Authorized',
                  icon: const Icon(Icons.portable_wifi_off),
                  color: Colors.red,
                  onPressed: () async {
                    await flutterBeacon.requestAuthorization;
                  },
                );
              }

              return IconButton(
                tooltip: 'Authorized',
                icon: const Icon(Icons.wifi_tethering),
                color: Colors.blue,
                onPressed: () async {
                  await flutterBeacon.requestAuthorization;
                },
              );
            }),
            Obx(() {
              return IconButton(
                tooltip: controller.locationServiceEnabled
                    ? 'Location Service ON'
                    : 'Location Service OFF',
                icon: Icon(
                  controller.locationServiceEnabled ? Icons.location_on : Icons.location_off,
                ),
                color: controller.locationServiceEnabled ? Colors.blue : Colors.red,
                onPressed: () {},
              );
            }),
            Obx(() {
              final state = controller.bluetoothState.value;

              if (state == BluetoothState.stateOn) {
                return IconButton(
                  tooltip: 'Bluetooth ON',
                  icon: const Icon(Icons.bluetooth_connected),
                  onPressed: () {},
                  color: Colors.lightBlueAccent,
                );
              }

              if (state == BluetoothState.stateOff) {
                return IconButton(
                  tooltip: 'Bluetooth OFF',
                  icon: const Icon(Icons.bluetooth),
                  onPressed: () {
                    OpenSettings.openBluetoothSetting();
                  },
                  color: Colors.red,
                );
              }

              return IconButton(
                icon: const Icon(Icons.bluetooth_disabled),
                tooltip: 'Bluetooth State Unknown',
                onPressed: () {},
                color: Colors.grey,
              );
            }),
          ],
        ),
        body: Obx(
          () => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Total Beacons Found by this UUID: ${controller.beacons.value.length}',
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),
                for (var i = 0; i < controller.beacons.value.length; i++)
                  Container(child: Text(' RSSI: ${controller.beacons[i].rssi.toString()}')),
                const SizedBox(height: 20),
                SizedBox(
                  height: 500,
                  child: controller.beacons.value.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          children: ListTile.divideTiles(
                            context: context,
                            tiles: controller.beacons.value.map(
                              (beacon) {
                                return ListTile(
                                  title: Text(
                                    beacon.proximityUUID,
                                    style: const TextStyle(fontSize: 15.0),
                                  ),
                                  subtitle: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: <Widget>[
                                      Flexible(
                                        flex: 1,
                                        fit: FlexFit.tight,
                                        child: Text(
                                          'Major: ${beacon.major}\nMinor: ${beacon.minor}',
                                          style: const TextStyle(fontSize: 13.0),
                                        ),
                                      ),
                                      Flexible(
                                        flex: 2,
                                        fit: FlexFit.tight,
                                        child: Text(
                                          'Accuracy: ${beacon.accuracy}m\nRSSI: ${beacon.rssi}',
                                          style: const TextStyle(fontSize: 13.0),
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                          ).toList(),
                        ),
                ),
              ],
            ),
          ),
        ));
  }
}
