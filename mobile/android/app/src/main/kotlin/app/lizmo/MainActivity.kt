package app.lizmo

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Notifications turned off for good can only be turned back on in the
        // phone's settings, so the account menu offers a way straight there.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.lizmo/settings")
            .setMethodCallHandler { call, result ->
                if (call.method == "openNotificationSettings") {
                    startActivity(notificationSettings())
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun notificationSettings(): Intent =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.fromParts("package", packageName, null))
        }
}
