import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityController extends GetxController {
  // Reactive variable to store connection status
  var isConnected = true.obs;
  late StreamSubscription<List<ConnectivityResult>> subscription;

  @override
  void onInit() {
    super.onInit();
    // 1. Check initial status
    checkInternet();

    // 2. Listen to network changes
    subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateStatus(results);
    });
  }

  // Helper to update status based on result list
  void _updateStatus(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) {
      isConnected.value = false;
    } else {
      isConnected.value = true;
    }
  }

  // Manually check internet (useful for retry buttons)
  Future<void> checkInternet() async {
    var results = await Connectivity().checkConnectivity();
    _updateStatus(results);
  }

  @override
  void onClose() {
    subscription.cancel();
    super.onClose();
  }
}