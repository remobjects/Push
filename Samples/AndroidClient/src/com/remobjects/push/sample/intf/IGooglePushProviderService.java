//----------------------------------------------------------------------
// This file was automatically generated by the RemObjects SDK from a
// RODL file associated with this project.
//
// Do not modify this file manually, or your changes will be lost when
// it is regenerated the next time you update your RODL.
//----------------------------------------------------------------------

package com.remobjects.push.sample.intf;

public interface IGooglePushProviderService {

	void registerDevice(
		String registrationId,
		String additionalInfo
	);
	void unregisterDevice(
		String registrationId
	);

}
