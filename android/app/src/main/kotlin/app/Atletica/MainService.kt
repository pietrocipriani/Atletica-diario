/*package app.Atletica;

import android.app.Service
import android.content.Intent
import android.os.IBinder

public class RunAfterBootService : Service () {

    override public fun onBind(intent: Intent) : IBinder {
        // TODO: Return the communication channel to the service.
        throw UnsupportedOperationException("Not yet implemented");
    }

    override public fun onCreate() {
        super.onCreate();
        //Log.d(TAG_BOOT_EXECUTE_SERVICE, "RunAfterBootService onCreate() method.");

    }

    override public fun onStartCommand(intent: Intent, flags: Int, startId: Int) : Int {

        //String message = "RunAfterBootService onStartCommand() method.";

        //Toast.makeText(getApplicationContext(), message, Toast.LENGTH_LONG).show();

        //Log.d(TAG_BOOT_EXECUTE_SERVICE, "RunAfterBootService onStartCommand() method.");

        return super.onStartCommand(intent, flags, startId);
    }

    override public fun onDestroy() {
        super.onDestroy();
    }
}*/