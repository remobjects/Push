namespace SampleServer
{
    partial class Engine
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary> 
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Component Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.components = new System.ComponentModel.Container();
            this.ipHttpServerChannel = new RemObjects.SDK.Server.IpHttpServerChannel(this.components);
            this.binMessage = new RemObjects.SDK.BinMessage();
            ((System.ComponentModel.ISupportInitialize)(this.ipHttpServerChannel)).BeginInit();
            // 
            // ipHttpServerChannel
            // 
            this.ipHttpServerChannel.Active = true;
            this.ipHttpServerChannel.Dispatchers.Add(new RemObjects.SDK.Server.MessageDispatcher("bin", this.binMessage, true, true));
            // 
            // 
            // 
            this.ipHttpServerChannel.HttpServer.Port = 8099;
            this.ipHttpServerChannel.HttpServer.ServerName = "RemObjects SDK for .NET HTTP Server";
            this.ipHttpServerChannel.SendClientAccessPolicyXml = RemObjects.SDK.Server.ClientAccessPolicyType.AllowNone;
            this.ipHttpServerChannel.SendCrossOriginHeader = false;
            // 
            // binMessage
            // 
            this.binMessage.ContentType = "application/octet-stream";
            this.binMessage.SerializerInstance = null;
            ((System.ComponentModel.ISupportInitialize)(this.ipHttpServerChannel)).EndInit();

        }

        #endregion

        private RemObjects.SDK.Server.IpHttpServerChannel ipHttpServerChannel;
        private RemObjects.SDK.BinMessage binMessage;
    }
}
