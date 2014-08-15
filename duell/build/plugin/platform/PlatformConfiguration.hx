/**
 * @autor rcam
 * @date 04.08.2014.
 * @company Gameduell GmbH
 */
package duell.build.plugin.platform;

import haxe.io.Path;

import duell.build.helpers.XCodeHelper;



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
	FRAMEWORKS : Array<String>,
	FRAMEWORK_SEARCH_PATHS : Array<String>,
	DEPLOYMENT_TARGET : String,
	TARGET_DEVICES : String,
	ARCHS : Array<String>,
	KEY_STORE_IDENTITY : String,
	FULLSCREEN : String,
	ORIENTATIONS : Array<String>,
	REQUIRED_CAPABILITIES : KeyValueArray,
	ENTITLEMENTS_PATH : String,

	/// derived from the data above
	ADDL_PBX_BUILD_FILE : Array<String>,
	ADDL_PBX_FILE_REFERENCE : Array<String>,
	ADDL_PBX_FRAMEWORKS_BUILD_PHASE : Array<String>,
	ADDL_PBX_FRAMEWORK_GROUP : Array<String>
}

class PlatformConfiguration
{
	public static var _configuration : PlatformConfigurationData = null;
	private static var _parsingDefines : Array<String> = ["ios", "cpp"];
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

	public static function addParsingDefine(str : String)
	{
		_parsingDefines.push(str);
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
			XCODE_LINK_ARGS : [],
			XCODE_PROJECT_FLAGS : [],
			XCODE_TARGET_FLAGS : [],
			XCODE_BUILD_ARGS : [],
			FRAMEWORKS : [],
			FRAMEWORK_SEARCH_PATHS : [],
			DEPLOYMENT_TARGET : "5",
			TARGET_DEVICES : "", //1 for iphone, 2 for ipad, 1,2 for both
			ARCHS : ["armv7"],
			KEY_STORE_IDENTITY : "iPhone Developer",
			FULLSCREEN : "true",
			ORIENTATIONS : ["UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight", "UIInterfaceOrientationPortrait", "UIInterfaceOrientationPortraitUpsideDown"],
			REQUIRED_CAPABILITIES : [],
			ENTITLEMENTS_PATH : "",

			ADDL_PBX_BUILD_FILE : [],
			ADDL_PBX_FILE_REFERENCE : [],
			ADDL_PBX_FRAMEWORKS_BUILD_PHASE : [],
			ADDL_PBX_FRAMEWORK_GROUP : []
		};

		addFramework("Foundation.framework");
		addFramework("UIKit.framework");
	}

	public static function addFramework(name : String, path : String = "System/Library/Frameworks/")
	{
		if (PlatformConfiguration.getData().FRAMEWORKS.indexOf(name) == -1)
		{
			PlatformConfiguration.getData().FRAMEWORKS.push(name);

			var frameworkID = XCodeHelper.getUniqueIDForXCode();
			var fileID = XCodeHelper.getUniqueIDForXCode();

			PlatformConfiguration.getData().ADDL_PBX_BUILD_FILE.push("      " + frameworkID + " /* " + name + " in Frameworks */ = {isa = PBXBuildFile; fileRef = " + fileID + " /* " + name + " */; };");
			PlatformConfiguration.getData().ADDL_PBX_FILE_REFERENCE.push("      " + fileID + " /* " + name + " */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = " + name + "; path = " + path + "/" + name + "; sourceTree = SDKROOT; };");
			PlatformConfiguration.getData().ADDL_PBX_FRAMEWORKS_BUILD_PHASE.push("            " + frameworkID + " /* " + name + " in Frameworks */,");
			PlatformConfiguration.getData().ADDL_PBX_FRAMEWORK_GROUP.push("            " + fileID + " /* " + name + " */,");
		}
	}
}