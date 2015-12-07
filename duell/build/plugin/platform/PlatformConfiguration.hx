/*
 * Copyright (c) 2003-2015, GameDuell GmbH
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package duell.build.plugin.platform;

import duell.build.helpers.XCodeHelper;

enum EntryType
{
	STRING;
	BOOL;
	NUMBER;
	DYNAMIC;
}

typedef PlistEntry =
{
	KEY : String,
	TYPE : EntryType,
	VALUE : String
};

typedef ExceptionDomain =
{
	URL : String,
	PROPERTIES : KeyValueArray
}

typedef KeyValueArray = Array<{NAME : String, VALUE : String}>;

typedef PlatformConfigurationData = {
	PLATFORM_NAME : String,
	ICON_PATH : String,
	PRERENDERED_ICON : String,
	SPLASHSCREEN_PATH : String,
	HXCPP_COMPILATION_ARGS : Array<String>,
	XCODE_LINK_ARGS : Array<String>,
	XCODE_PROJECT_FLAGS : KeyValueArray,
	XCODE_TARGET_FLAGS : KeyValueArray,
	XCODE_BUILD_ARGS : Array<String>,
	FRAMEWORKS : Array<{NAME : String, PATH : String}>,
	DEPLOYMENT_TARGET : String,
	TARGET_DEVICES : String,
	ARCHS : Array<String>,
	KEY_STORE_PATH : String,
	KEY_STORE_PASSWORD : String,
	KEY_STORE_IDENTITY : String,
	PROVISIONING_PROFILE_PATH: String,
	FULLSCREEN : String,
	ORIENTATIONS : Array<String>,
	REQUIRED_CAPABILITIES : KeyValueArray,
	ENTITLEMENTS_PATH : String,
	INFOPLIST_SECTIONS: Array<String>,
	INFOPLIST_ENTRIES: Array<PlistEntry>,
	EXCEPTION_DOMAINS: Array<ExceptionDomain>,

	/// derived from the data above
	FRAMEWORK_SEARCH_PATHS : Array<String>,
	ADDL_PBX_BUILD_FILE : Array<String>,
	ADDL_PBX_FILE_REFERENCE : Array<String>,
	ADDL_PBX_FRAMEWORKS_BUILD_PHASE : Array<String>,
	ADDL_PBX_FRAMEWORK_GROUP : Array<String>,
	ADDL_PBX_GROUP : Array<String>,
	ADDL_PBX_RESOURCE_GROUP : Array<String>,
	ADDL_PBX_RESOURCES_BUILD_PHASE : Array<String>,

	/// derived from the arguments
	DEBUG : Bool,
	SIMULATOR : Bool,
	SIM_DEVICE : String,
	SIM_OS : String,
	OUTPUT_FILE : String,
	IOS_VERSION : String,

	// generated from publish,
	PUBLISHED_IPA_PATH: String,
	PUBLISHED_DSYM_PATH: String
}

class PlatformConfiguration
{
	public static var _configuration : PlatformConfigurationData = null;
	private static var _parsingDefines : Array<String> = ["apple", "ios", "cpp"];
	public static function getData() : PlatformConfigurationData
	{
		if (_configuration == null)
			initConfig();
		return _configuration;
	}

	public static function getConfigParsingDefines() : Array<String>
	{
		return _parsingDefines;
	}

	private static function initConfig()
	{
		_configuration =
		{
			PLATFORM_NAME : "ios",
			ICON_PATH : "Icons/ios",
			PRERENDERED_ICON : "true",
			SPLASHSCREEN_PATH : "Splashscreens/ios",
			HXCPP_COMPILATION_ARGS : [],
			XCODE_LINK_ARGS : ["-stdlib=libc++"],
			XCODE_PROJECT_FLAGS : [],
			XCODE_TARGET_FLAGS : [],
			XCODE_BUILD_ARGS : [],
			FRAMEWORKS : [{NAME:"Foundation.framework", PATH:null}, {NAME:"UIKit.framework", PATH:null}, {NAME:"QuartzCore.framework", PATH:null}],
			DEPLOYMENT_TARGET : "5",
			TARGET_DEVICES : "", //1 for iphone, 2 for ipad, 1,2 for both
			ARCHS : ["armv7"],
			KEY_STORE_PATH : "",
			KEY_STORE_PASSWORD : "",
			KEY_STORE_IDENTITY : "iPhone Developer",
			PROVISIONING_PROFILE_PATH: "",
			FULLSCREEN : "true",
			ORIENTATIONS : ["UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight", "UIInterfaceOrientationPortrait", "UIInterfaceOrientationPortraitUpsideDown"],
			REQUIRED_CAPABILITIES : [],
			ENTITLEMENTS_PATH : "",
			INFOPLIST_SECTIONS: [],
			INFOPLIST_ENTRIES: [],
			EXCEPTION_DOMAINS: [],

			FRAMEWORK_SEARCH_PATHS : [],
			ADDL_PBX_BUILD_FILE : [],
			ADDL_PBX_FILE_REFERENCE : [],
			ADDL_PBX_FRAMEWORKS_BUILD_PHASE : [],
			ADDL_PBX_FRAMEWORK_GROUP : [],
			ADDL_PBX_GROUP : [],
			ADDL_PBX_RESOURCES_BUILD_PHASE : [],
			ADDL_PBX_RESOURCE_GROUP : [],

			DEBUG : false,
			SIMULATOR : false,
			SIM_DEVICE : 'iPhone-4s',
			SIM_OS : '9.0',
			OUTPUT_FILE : "",
			IOS_VERSION : "",

			PUBLISHED_IPA_PATH : "",
			PUBLISHED_DSYM_PATH : ""
		};
	}
}
