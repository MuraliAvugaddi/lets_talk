import 'package:in_app_update/in_app_update.dart';
import 'package:get/get.dart';

class UpdateController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    checkAppUpdate();
  }

  Future<void> checkAppUpdate() async {
    try {
      // Correct method name is checkForUpdate()
      AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
      
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // Option A: Immediate update (Forces user to update)
        if (updateInfo.immediateUpdateAllowed) {
          InAppUpdate.performImmediateUpdate().catchError((e) {
            Get.snackbar("Update Failed", e.toString());
            return AppUpdateResult.userDeniedUpdate;
          });
        } 
        // Option B: Flexible update (Downloads in background)
        else if (updateInfo.flexibleUpdateAllowed) {
          InAppUpdate.startFlexibleUpdate().then((result) {
            if (result == AppUpdateResult.success) {
              InAppUpdate.completeFlexibleUpdate();
            }
          });
        }
      }
    } catch (e) {
      print("In-App Update error: $e");
    }
  }
}