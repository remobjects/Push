//----------------------------------------------------------------------
// This file was automatically generated by the RemObjects SDK from a
// RODL file associated with this project.
//
// Do not modify this file manually, or your changes will be lost when
// it is regenerated the next time you update your RODL.
//----------------------------------------------------------------------

package com.remobjects.push.sample.intf;

import com.remobjects.sdk.ClientChannel;
import com.remobjects.sdk.Message;
import com.remobjects.sdk.ReferenceType;
import com.remobjects.sdk.TypeManager;
import java.net.URI;

public class GooglePushProviderService_Proxy extends com.remobjects.sdk.Proxy implements IGooglePushProviderService {

	public GooglePushProviderService_Proxy() {
		super();
		TypeManager.setPackage(this.getClass().getPackage().getName().toString());
	}

	public GooglePushProviderService_Proxy(Message aMessage, ClientChannel aClientChannel) {
		super(aMessage, aClientChannel);
		TypeManager.setPackage(this.getClass().getPackage().getName().toString());
	}

	public GooglePushProviderService_Proxy(Message aMessage, ClientChannel aClientChannel, String aOverrideInterfaceName) {
		super(aMessage, aClientChannel, aOverrideInterfaceName);
		TypeManager.setPackage(this.getClass().getPackage().getName().toString());
	}

	public GooglePushProviderService_Proxy(URI aSchema) {
		super(aSchema);
		TypeManager.setPackage(this.getClass().getPackage().getName().toString());
	}

	public GooglePushProviderService_Proxy(URI aSchema, String aOverrideInterfaceName) {
		super(aSchema, aOverrideInterfaceName);
		TypeManager.setPackage(this.getClass().getPackage().getName().toString());
	}

	@Override
	public String _getInterfaceName() {
		return "GooglePushProviderService";
	}

	@Override
	public void registerDevice(
		String registrationId,
		String additionalInfo
	) {
		Message _localMessage = (Message)getProxyMessage().clone();
		_localMessage.initializeAsRequestMessage("PushProvider", _getActiveInterfaceName(), "registerDevice");
		try {
			_localMessage.writeAnsiString("registrationId", registrationId);
			_localMessage.writeAnsiString("additionalInfo", additionalInfo);
			_localMessage.finalizeMessage();
			getProxyClientChannel().dispatch(_localMessage);
		} finally {
			synchronized (getProxyMessage()) {
				getProxyMessage().setClientID(_localMessage.getClientID());
			}
			_localMessage.clear();
		}
	}

	@Override
	public void unregisterDevice(
		String registrationId
	) {
		Message _localMessage = (Message)getProxyMessage().clone();
		_localMessage.initializeAsRequestMessage("PushProvider", _getActiveInterfaceName(), "unregisterDevice");
		try {
			_localMessage.writeAnsiString("registrationId", registrationId);
			_localMessage.finalizeMessage();
			getProxyClientChannel().dispatch(_localMessage);
		} finally {
			synchronized (getProxyMessage()) {
				getProxyMessage().setClientID(_localMessage.getClientID());
			}
			_localMessage.clear();
		}
	}

}