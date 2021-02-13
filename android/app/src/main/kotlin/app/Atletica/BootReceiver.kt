/*package app.Atletica;

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import app.Atletica.
//import android.util.Log;

class BootReceiver : BroadcastReceiver() {

    override public fun onReceive (context: Context, intent: Intent) {
        val action : String = intent.getAction();

        //val message : String = "BootDeviceReceiver onReceive, action is " + action;

        //Toast.makeText(context, message, Toast.LENGTH_LONG).show();

        //Log.d(TAG_BOOT_BROADCAST_RECEIVER, action);

        if (Intent.ACTION_BOOT_COMPLETED == action)
            //startServiceDirectly(context);
            startServiceByAlarm(context);
        }
    }

    /* Start RunAfterBootService service directly and invoke the service every 10 seconds. */
 /*   private fun startServiceDirectly(context: Context) {
        try {
            while (true) {
                //val message : String = "BootDeviceReceiver onReceive start service directly.";

                //Toast.makeText(context, message, Toast.LENGTH_LONG).show();

                //Log.d(TAG_BOOT_BROADCAST_RECEIVER, message);

                // This intent is used to start background service. The same service will be invoked for each invoke in the loop.
                val startServiceIntent : Intent = Intent(context, MainService::class.java);
                context.startService(startServiceIntent);

                // Current thread will sleep one second.
                Thread.sleep(10000);
            }
        }catch(e : InterruptedException) {
            e.printStackTrace();
        }
    }

    /* Create an repeat Alarm that will invoke the background service for each execution time.
     * The interval time can be specified by your self.  */
/*    private fun startServiceByAlarm(context: Context) {
        // Get alarm manager.
        val alarmManager : AlarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager;

        // Create intent to invoke the background service.
        val intent : Intent = Intent(context, MainService::class.java);
        val pendingIntent : PendingIntent = PendingIntent.getService(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT);

        val startTime : Long = System.currentTimeMillis();
        val intervalTime : Long = 1800*1000;

        //String message = "Start service use repeat alarm. ";

        //Toast.makeText(context, message, Toast.LENGTH_LONG).show();

        //Log.d(TAG_BOOT_BROADCAST_RECEIVER, message);

        // Create repeat alarm.
        alarmManager.setRepeating(AlarmManager.RTC_WAKEUP, startTime, intervalTime, pendingIntent);
    }
}*/