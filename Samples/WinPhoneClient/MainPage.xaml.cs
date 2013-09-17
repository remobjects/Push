using System;
using System.Collections.Generic;
using System.IO.IsolatedStorage;
using System.Linq;
using System.Net;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Shapes;
using Microsoft.Phone.Controls;
using Microsoft.Phone.Notification;
using RemObjects.SDK;
using WinPhoneClient.Intf;
using ThreadPool = System.Threading.ThreadPool;

namespace WinPhoneClient
{
    public partial class MainPage : PhoneApplicationPage
    {
        private ClientChannel clientChannel;
        private Message message;
        private Guid deviceId;
        private HttpNotificationChannel pushChannel;

        // Constructor
        public MainPage()
        {
            var lChannel = new WinInetHttpClientChannel {TargetUrl = "http://toxa.dyndns.org:8099"};
            this.clientChannel = lChannel;

            var lMessage = new BinMessage();
            this.message = lMessage;

            // If we have previously created the unique id, use it otherwise create one.
            if (IsolatedStorageSettings.ApplicationSettings.Contains("DeviceId"))
            {
                // Retrieve the unique id saved in the isolated storage.
                this.deviceId = (Guid)IsolatedStorageSettings.ApplicationSettings["DeviceId"];
            }
            else
            {
                // Create a new guid and save it in the isolated storage
                this.deviceId = Guid.NewGuid();
                IsolatedStorageSettings.ApplicationSettings["DeviceId"] = this.deviceId;
            }

            InitializeComponent();

            RegisterOnMpns();
        }

        private void RegisterOnMpns()
        {
            // The name of our push channel.
            const string channelName = "RO Push Raw Channel";

            pushChannel = HttpNotificationChannel.Find(channelName);

            if (pushChannel == null)
            {
                Log("Creating new notification channel.\n");
                pushChannel = new HttpNotificationChannel(channelName);

                // Register for all the events before attempting to open the channel.
                pushChannel.ChannelUriUpdated += PushChannelOnChannelUriUpdated;
                pushChannel.ErrorOccurred += PushChannelOnErrorOccurred;
                pushChannel.HttpNotificationReceived += PushChannelOnHttpNotificationReceived;

                pushChannel.Open();
            }
            else
            {
                Log("Existing notification channel found.\n");
                // The channel was already open, so just register for all the events.
                pushChannel.ChannelUriUpdated += PushChannelOnChannelUriUpdated;
                pushChannel.ErrorOccurred += PushChannelOnErrorOccurred;
                pushChannel.HttpNotificationReceived += PushChannelOnHttpNotificationReceived;


                // Display the URI for testing purposes. Normally, the URI would be passed back to your web service at this point.
                Log("Channel URI is: {0}\n", pushChannel.ChannelUri.ToString());

                RegisterOnServer(pushChannel.ChannelUri.ToString());
            }
        }

        private void PushChannelOnChannelUriUpdated(object sender, NotificationChannelUriEventArgs e)
        {
            Log("URI update invoked\n");

            // Display the new URI for testing purposes. Normally, the URI would be passed back to your web service at this point.
            RegisterOnServer(e.ChannelUri.ToString());
        }

        private void PushChannelOnErrorOccurred(object sender, NotificationChannelErrorEventArgs e)
        {
            Log("A push notification {0} error occurred.\n  {1} ({2}) {3}\n", e.ErrorType, e.Message, e.ErrorCode, e.ErrorAdditionalData);
        }

        private void PushChannelOnHttpNotificationReceived(object sender, HttpNotificationEventArgs e)
        {
            string message;

            using (System.IO.StreamReader reader = new System.IO.StreamReader(e.Notification.Body))
            {
                message = reader.ReadToEnd();
            }


            Log("Received Notification {0}:\n{1}", DateTime.Now.ToShortTimeString(), message);
        }

        private void RegisterOnServer(String notificationUri)
        {
            var lService = new WindowsPhonePushProviderService_AsyncProxy(message, clientChannel);
            lService.BeginRegisterDevice(deviceId.ToString(), notificationUri,
                                         Environment.OSVersion.Version.ToString(), "WinPhoneClient",
                                         ar =>
                                         {
                                             try
                                             {
                                                 lService.EndRegisterDevice(ar);
                                                 Log("Channel URI sent to server\n");
                                             }
                                             catch (Exception ex)
                                             {
                                                 Log("Exception during URI update on the server:\n{0}", ex.Message);
                                             }
                                         }, null);
        }

        private void UnregisterOnServer()
        {
            var lService = new WindowsPhonePushProviderService_AsyncProxy(message, clientChannel);
            lService.BeginUnregisterDevice(deviceId.ToString(),
                                         ar =>
                                         {
                                             try
                                             {
                                                 lService.EndUnregisterDevice(ar);
                                                 Log("Device unsubscribed from notifications.\n");
                                             }
                                             catch (Exception ex)
                                             {
                                                 Log("Exception during unsivscribing.\n{0}", ex.Message);
                                             }
                                         }, null);
        }

        private void Log(String aTemplate, params Object[] aParams)
        {
            if (!Dispatcher.CheckAccess())
                Dispatcher.BeginInvoke(new Action<String, Object[]>(Log), new object[] { aTemplate, aParams });
            else
            {
                tbLog.Text += String.Format(aTemplate, aParams);
            }
        }

        private void BtRegister_OnClick(object sender, EventArgs e)
        {
            if (pushChannel == null)
                RegisterOnMpns();
        }

        private void BtUnregister_OnClick(object sender, EventArgs e)
        {
            pushChannel.Close();
            pushChannel = null;
            UnregisterOnServer();
        }
    }
}