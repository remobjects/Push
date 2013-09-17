package com.remobjects.push.sample;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.graphics.BitmapFactory;
import android.support.v4.app.NotificationCompat;
import android.util.Log;

import com.google.android.gcm.GCMBaseIntentService;
import com.google.android.gcm.GCMRegistrar;

public class GCMIntentService extends GCMBaseIntentService {
    private static final String TAG = "GCMIntentService";

    public GCMIntentService() {
        super(CommonUtilities.SENDER_ID); // sender ID is static

    }

    @Override
    protected void onRegistered(Context context, String registrationId) {

        // get the registration id and pass it to the RO server to REGISTER

        Log.i(TAG, "Device registered: regId = " + registrationId);
        CommonUtilities.displayMessage(context, getString(R.string.gcm_registered));
        ServerUtilities.register(context, registrationId);
    }

    @Override
    protected void onUnregistered(Context context, String registrationId) {

        // get the registration id and pass it to the RO server to UNREGISTER
        Log.i(TAG, "Device unregistered");
        CommonUtilities.displayMessage(context, getString(R.string.gcm_unregistered));
        if (GCMRegistrar.isRegisteredOnServer(context)) {
            ServerUtilities.unregister(context, registrationId);
        } else {
            // This callback results from the call to unregister made on
            // ServerUtilities when the registration to the server failed.
            Log.i(TAG, "Ignoring unregister callback");
        }

    }

    @Override
    protected void onMessage(Context context, Intent intent) {

        // Called when RO server sends a message to GCM, and GCM delivers it to the device.
        // If the message has a payload, its contents are available as extras in the intent.

        Log.i(TAG, "Received message");
        String message = intent.getStringExtra("message");
        if (message == null || message.length() == 0)
            message = getString(R.string.gcm_message);
        int badge = 0;
        try {
            badge = Integer.parseInt(intent.getStringExtra("badge"));
        } catch (NumberFormatException e) {
        }
        String title = intent.getStringExtra("title");
        if (title == null || title.length() == 0)
            title = context.getString(R.string.app_name);
        if (badge != 0)
            title = title + " (" + badge  + ")";
        // sound ignored
        // sync ignored
        // image ignored
        
        CommonUtilities.displayMessage(context, message);
        // notifies user
        generateNotification(context, title, message);

    }

    @Override
    protected void onDeletedMessages(Context context, int total) {
        Log.i(TAG, "Received deleted messages notification");
        String message = getString(R.string.gcm_deleted, total);
        String title = getString(R.string.app_name);
        CommonUtilities.displayMessage(context, message);
        // notifies user
        generateNotification(context, title, message);
    }

    @Override
    public void onError(Context context, String errorId) {
        Log.i(TAG, "Received error: " + errorId);
        CommonUtilities.displayMessage(context, getString(R.string.gcm_error, errorId));
    }

    @Override
    protected boolean onRecoverableError(Context context, String errorId) {
        // log message
        Log.i(TAG, "Received recoverable error: " + errorId);
        CommonUtilities.displayMessage(context, getString(R.string.gcm_recoverable_error, errorId));
        return super.onRecoverableError(context, errorId);
    }

    /**
     * Issues a notification to inform the user that server has sent a message.
     */
    private static void generateNotification(Context context, String title, String message) {
        
        NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        
        Intent notificationIntent = new Intent(context, MainActivity.class);
        // set intent so it does not start a new activity
        notificationIntent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        PendingIntent intent = PendingIntent.getActivity(context, 0, notificationIntent, 0);
        
        Notification noti = new NotificationCompat.Builder(context)
                                                  .setContentText(message)
                                                  .setWhen(System.currentTimeMillis())
                                                  .setContentTitle(title)
                                                  .setSmallIcon(R.drawable.ic_stat_gcm)
                                                  .setLargeIcon(BitmapFactory.decodeResource(context.getResources(), R.drawable.ic_launcher))
                                                  .setContentIntent(intent)
                                                  .setAutoCancel(true)
                                                  .build();
        
        notificationManager.notify(0, noti);
    }
}
