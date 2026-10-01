package app.hamro_fix

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        System.setProperty("java.net.preferIPv4Stack", "true")
        System.setProperty("java.net.preferIPv6Addresses", "false")
        super.onCreate(savedInstanceState)
    }
}
