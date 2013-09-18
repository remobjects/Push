using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Mime;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using RemObjects.SDK.Push;
using RemObjects.SDK.Push.MPNS;

namespace SampleServer
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        private static MainWindow fInstance;
        private Engine fEngine;
        public static MainWindow Instance { get { return fInstance; } }

        public static readonly DependencyProperty BadgeProperty =
            DependencyProperty.Register("Badge", typeof(string), typeof(MainWindow), new UIPropertyMetadata("0"));
        public String Badge
        {
            get { return (string)GetValue(BadgeProperty); }
            set { SetValue(BadgeProperty, value); }
        }

        public MainWindow()
        {
            fInstance = this;
            InitializeComponent();

            fEngine = new Engine();

            PushManager.DeviceManager = new FileDeviceManager("devices.xml");
            PushManager.RequireSession = false;
            PushManager.DeviceRegistered += OnDeviceRegistered;
            PushManager.DeviceUnregistered += OnDeviceRegistered;

            PushManager.PushConnect.GCMConnect.ApiKey = "AIzaSyBfF-423MN7zx2wbmTqZLaR0G-lyZohqug";

            //PushManager.PushConnect.MPNSConnect.WebServiceCertificate = instance of your certifacate here if you have it.

            PushManager.PushConnect.APSConnect.LoadCertificatesFromBaseFilename(this.GetType().Assembly.Location);
            new WindowsPhonePushProviderService();
            // or
            //PushManager.PushConnect.APSConnect.MacCertificateFile = ""; // mac certificate file location
            //PushManager.PushConnect.APSConnect.iOSCertificateFile = ""; // iOs certificate file location
            //PushManager.PushConnect.APSConnect.WebCertificateFile = ""; // web certificate file location

            tblNumDevices.Text = PushManager.DeviceManager.Devices.Count().ToString();
        }

        protected override void OnClosing(System.ComponentModel.CancelEventArgs e)
        {
            fEngine.Dispose();
        }

        private void OnDeviceRegistered(object sender, DeviceEventArgs ea)
        {
            if (!this.Dispatcher.CheckAccess())
                this.Dispatcher.BeginInvoke(new Action<object, DeviceEventArgs>(OnDeviceRegistered), new object[] { sender, ea });
            else
            {
                tblNumDevices.Text = PushManager.DeviceManager.Devices.Count().ToString();
            }

        }

        private void grTypeChecked(object sender, RoutedEventArgs e)
        {
            tbText.IsEnabled = grText.IsChecked == true || grCommon.IsChecked == true;
            tbBadge.IsEnabled = grBadge.IsChecked == true || grCommon.IsChecked == true;
            tbSound.IsEnabled = grSound.IsChecked == true || grCommon.IsChecked == true;
            tbImage.IsEnabled = grCommon.IsChecked == true;
            cbSync.IsEnabled = grSync.IsChecked == true || grCommon.IsChecked == true;
        }

        private void btSend_Click(object sender, RoutedEventArgs e)
        {
            if (cbSendRawAsToast.IsChecked.GetValueOrDefault(false))
            {
                PushManager.PushConnect.MessageCreating += PushConnectOnMessageCreating;
            }
            else
            {
                PushManager.PushConnect.MessageCreating -= PushConnectOnMessageCreating;
            }

            try
            {
                PushManager.PushConnect.CheckSetup();
            }
            catch (InvalidSetupException ex)
            {
                tbConnectErrors.Text = String.Format("{0}: {1}", ex.Connect.GetType().Name, ex.Message);
                return;
            }

            var lData = new
                {
                    IsTextSelected = grText.IsChecked.GetValueOrDefault(false),
                    IsBadgeSelected = grBadge.IsChecked.GetValueOrDefault(false),
                    IsSoundSelected = grSound.IsChecked.GetValueOrDefault(false),
                    IsSyncSelected = grSync.IsChecked.GetValueOrDefault(false),
                    IsCommonSelected = grCommon.IsChecked.GetValueOrDefault(false),
                    Title = "RO Push Sample",
                    Text = tbText.Text,
                    SoundFile = tbSound.Text,
                    ImageFile = tbImage.Text,
                    Badge = Convert.ToInt32(tbBadge.Text),
                };

            Task.Factory.StartNew(() =>
                {
                    if (lData.IsTextSelected)
                    {
                        PushManager.PushMessage(lData.Title, lData.Text);
                    }
                    else if (lData.IsSoundSelected)
                    {
                        PushManager.PushSound(lData.SoundFile);
                    }
                    else if (lData.IsBadgeSelected)
                    {
                        PushManager.PushBadge(lData.Badge);
                    }
                    else if (lData.IsSyncSelected)
                    {
                        PushManager.PushSyncNeeded();
                    }
                    else if (lData.IsCommonSelected)
                    {
                        PushManager.PushCommon(lData.Title, lData.Text, lData.Badge, lData.SoundFile, lData.ImageFile);
                    }

                });
        }

        private void PushConnectOnMessageCreating(object aSender, MessageCreateEventArgs anArgs)
        {
            var lDevice = anArgs.Device as WindowsPhonePushDeviceInfo;
            if (lDevice != null)
            {
                var lMessage = new MPNSToastMessage();
                lMessage.Text1 = anArgs.MessageData.Title;
                lMessage.Text2 = anArgs.MessageData.Text;
                lMessage.NotificationURI = lDevice.NotificationURI.ToString();
                anArgs.Message = lMessage;
            }
        }

        private void btSendToastToWP_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                PushManager.PushConnect.CheckSetup();
            }
            catch (InvalidSetupException ex)
            {
                tbConnectErrors.Text = String.Format("{0}: {1}", ex.Connect.GetType().Name, ex.Message);
                return;
            }

            var lData = new
                    {
                        IsTextSelected = grText.IsChecked.GetValueOrDefault(false),
                        IsBadgeSelected = grBadge.IsChecked.GetValueOrDefault(false),
                        IsSoundSelected = grSound.IsChecked.GetValueOrDefault(false),
                        IsSyncSelected = grSync.IsChecked.GetValueOrDefault(false),
                        IsCommonSelected = grCommon.IsChecked.GetValueOrDefault(false),
                        Title = String.Empty,
                        Text = tbText.Text,
                        SoundFile = tbSound.Text,
                        ImageFile = tbImage.Text,
                        Badge = Convert.ToInt32(tbBadge.Text),
                    };

            Task.Factory.StartNew(() =>
                    {
                        if (lData.IsCommonSelected)
                        {
                            foreach (var device in PushManager.DeviceManager.Devices)
                            {
                                if (device is WindowsPhonePushDeviceInfo)
                                {
                                    var lMessage = new MPNSToastMessage();
                                    lMessage.OSVersion = MPNSDeviceVersion.Seven;
                                    lMessage.NotificationURI = (device as WindowsPhonePushDeviceInfo).NotificationURI.ToString();
                                    lMessage.Text1 = lData.Title + " (" + lData.Badge + ")";
                                    lMessage.Text2 = lData.Text;
                                    PushManager.PushConnect.MPNSConnect.PushMessage(lMessage);
                                }
                            }
                        }
                    });
        }
    }
}
