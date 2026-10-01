package app.hamro_fix

import android.app.Application

class HamroFixApplication : Application() {
    override fun attachBaseContext(base: android.content.Context) {
        System.setProperty("java.net.preferIPv4Stack", "true")
        System.setProperty("java.net.preferIPv6Addresses", "false")
        super.attachBaseContext(base)
    }

    override fun onCreate() {
        System.setProperty("java.net.preferIPv4Stack", "true")
        System.setProperty("java.net.preferIPv6Addresses", "false")
        super.onCreate()
    }
}
