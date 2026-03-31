import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class AppProvider extends ChangeNotifier {
  bool _isServiceRunning = false;
  bool _allPermissionsGranted = false;
  String _statusMessage = 'الخدمة متوقفة';
  
  bool get isServiceRunning => _isServiceRunning;
  bool get allPermissionsGranted => _allPermissionsGranted;
  String get statusMessage => _statusMessage;

  /// Check and request all required permissions
  Future<bool> checkPermissions() async {
    final permissions = [
      Permission.phone,
      Permission.microphone,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();
    
    _allPermissionsGranted = statuses.values.every(
      (status) => status.isGranted,
    );
    
    notifyListeners();
    return _allPermissionsGranted;
  }

  /// Request specific permission
  Future<bool> requestPermission(Permission permission) async {
    final status = await permission.request();
    await checkPermissions();
    return status.isGranted;
  }

  void setServiceRunning(bool running) {
    _isServiceRunning = running;
    _statusMessage = running ? 'الخدمة تعمل - في انتظار المكالمات' : 'الخدمة متوقفة';
    notifyListeners();
  }

  void updateStatus(String message) {
    _statusMessage = message;
    notifyListeners();
  }
}
