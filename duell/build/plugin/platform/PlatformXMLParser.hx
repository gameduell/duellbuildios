/**
 * @autor rcam
 * @date 04.08.2014.
 * @company Gameduell GmbH
 */
package duell.build.plugin.platform;


import duell.build.objects.DuellProjectXML;
import duell.build.objects.Configuration;

import duell.build.plugin.platform.PlatformConfiguration;

import duell.build.helpers.XCodeHelper;

import duell.helpers.XMLHelper;
import duell.helpers.LogHelper;


import haxe.xml.Fast;

class PlatformXMLParser
{
	private var parsingConditions : Array<String>; /// used in validating elements for "if" or "unless"

	private function new() : Void
	{
		parsingConditions = [];

		parsingConditions.concat(Configuration.getConfigParsingDefines());
		parsingConditions.concat(PlatformConfiguration.getConfigParsingDefines());
	}

	private static var cache : PlatformXMLParser;
	public static function getConfig() : PlatformXMLParser
	{
		if(cache == null)
		{
			cache = new PlatformXMLParser();
			return cache;
		}

		return cache;
	}
	public function parse(xml : Fast) : Void
	{
		for (element in xml.elements) 
		{
			switch(element.name)
			{
				case 'ios':
					parsePlatform(element);
			}
		}
	}


	public function parsePlatform(xml : Fast) : Void
	{
		for (element in xml.elements) 
		{
			if (!XMLHelper.isValidElement(element, parsingConditions))
				continue;

			switch(element.name)
			{
				case 'architecture':
					parseArchitectureElement(element);

				case 'icon':
					parseIconElement(element);

				case 'splashscreen':
					parseSplashscreenElement(element);

				case 'framework':
					parseFrameworkElement(element);

				case 'hxcpp-compilation-arg':
					parseHXCPPCompilationArgElement(element);

				case 'xcode-link-arg':
					parseXCodeLinkArgElement(element);

				case 'xcode-build-arg':
					parseXCodeBuildArgElement(element);

				case 'xcode-project-flag':
					parseXCodeProjectFlagElement(element);

				case 'xcode-target-flag':
					parseXCodeTargetFlagElement(element);

				case 'pre-rendered-icon':
					parsePreRenderedIconElement(element);

				case 'deployment-target':
					parseDeploymentTargetElement(element);

				case 'target-devices':
					parseTargetDevicesElement(element);

				case 'key-store-identity':
					parseKeyStoreIdentityElement(element);

				case 'fullscreen':
					parseFullscreenElement(element);

				case 'orientation':
					parseOrientationElement(element);

				case 'required-capability':
					parseRequiredCapabilityElement(element);

				case 'entitlements':
					parseEntitlementsElement(element);

			}
		}
	}

	private function parseArchitectureElement(element : Fast)
	{
		if (element.has.name)
		{
			if (PlatformConfiguration.getData().ARCHS.indexOf(element.att.name) == -1)
			{
				PlatformConfiguration.getData().ARCHS.push(element.att.name);
			}
		}
	}

	private function parseIconElement(element : Fast)
	{
		if (element.has.path)
		{
			PlatformConfiguration.getData().ICON_PATH = resolvePath(element.att.path);
		}
	}

	private function parseSplashscreenElement(element : Fast)
	{
		if (element.has.path)
		{
			PlatformConfiguration.getData().SPLASHSCREEN_PATH = resolvePath(element.att.path);
		}
	}

	private function parseFrameworkElement(element : Fast)
	{
		if (element.has.name)
		{
			if (PlatformConfiguration.getData().FRAMEWORKS.indexOf(element.att.name) == -1)
			{
				PlatformConfiguration.getData().FRAMEWORKS.push(element.att.name);
			}

			if (element.has.path)
			{
				PlatformConfiguration.addFramework(element.att.name, resolvePath(element.att.path));
			}
			else
			{
				PlatformConfiguration.addFramework(element.att.name);
			}
		}

		if (element.has.path)
		{
			if (PlatformConfiguration.getData().FRAMEWORK_SEARCH_PATHS.indexOf(element.att.path) == -1)
			{
				PlatformConfiguration.getData().FRAMEWORK_SEARCH_PATHS.push(resolvePath(element.att.path));
			}
		}

	}

	private function parseHXCPPCompilationArgElement(element : Fast)
	{
		if (element.has.value)
		{
			PlatformConfiguration.getData().HXCPP_COMPILATION_ARGS.push(element.att.value);
		}
	}

	private function parseXCodeLinkArgElement(element : Fast)
	{
		if (element.has.value)
		{
			PlatformConfiguration.getData().XCODE_LINK_ARGS.push(element.att.value);
		}
	}

	private function parseXCodeBuildArgElement(element : Fast)
	{
		if (element.has.value)
		{
			PlatformConfiguration.getData().XCODE_BUILD_ARGS.push(element.att.value);
		}
	}

	private function parseXCodeProjectFlagElement(element : Fast)
	{
		var name = null;
		var value = "";
		if (element.has.name)
		{
			if (element.has.value)
			{
				value = element.att.value;
			}

			addUniqueKeyValueToKeyValueArray(PlatformConfiguration.getData().XCODE_PROJECT_FLAGS, name, value);
		}
	}

	private function parseXCodeTargetFlagElement(element : Fast)
	{
		var name = null;
		var value = "";
		if (element.has.name)
		{
			if (element.has.value)
			{
				value = element.att.value;
			}

			addUniqueKeyValueToKeyValueArray(PlatformConfiguration.getData().XCODE_TARGET_FLAGS, name, value);
		}
	}

	private function parsePreRenderedIconElement(element : Fast)
	{
		if (element.has.value)
		{
			PlatformConfiguration.getData().PRERENDERED_ICON = element.att.value;
		}	
	}

	private function parseDeploymentTargetElement(element : Fast)
	{
		if (element.has.value)
		{
			PlatformConfiguration.getData().DEPLOYMENT_TARGET = element.att.value;
		}	
	}

	private function parseTargetDevicesElement(element : Fast)
	{
		if (element.has.value)
		{
			PlatformConfiguration.getData().TARGET_DEVICES = element.att.value;
		}	
	}

	private function parseKeyStoreIdentityElement(element : Fast)
	{
		if (element.has.value)
		{
			PlatformConfiguration.getData().KEY_STORE_IDENTITY = element.att.value;
		}	
	}

	private function parseFullscreenElement(element : Fast)
	{
		if (element.has.value)
		{
			PlatformConfiguration.getData().FULLSCREEN = element.att.value;
		}	
	}

	private function parseOrientationElement(element : Fast)
	{
		if (element.has.value)
		{
			PlatformConfiguration.getData().ORIENTATIONS = (element.att.value).split(",").map(function (str) return StringTools.trim(str));
		}	
	}

	private function parseRequiredCapabilityElement(element : Fast)
	{
		var name = null;
		var value = "";
		if (element.has.name)
		{
			name = element.att.name;
			if (element.has.value)
			{
				value = element.att.value;
			}

			addUniqueKeyValueToKeyValueArray(PlatformConfiguration.getData().REQUIRED_CAPABILITIES, name, value);
		}
	}

	private function parseEntitlementsElement(element : Fast)
	{
		if (element.has.path)
		{
			PlatformConfiguration.getData().ENTITLEMENTS_PATH = resolvePath(element.att.path);
		}
	}

	/// HELPERS
	private function addUniqueKeyValueToKeyValueArray(keyValueArray : KeyValueArray, key : String, value : String)
	{
		for (keyValuePair in keyValueArray)
		{
			if (keyValuePair.NAME == key)
			{
				LogHelper.println('Overriting key $key value ${keyValuePair.VALUE} with value $value');
				keyValuePair.VALUE = value;
			}
		}

		keyValueArray.push({NAME : key, VALUE : value});
	}

	private function resolvePath(string : String) : String /// convenience method
	{
		return DuellProjectXML.getConfig().resolvePath(string);
	}
}