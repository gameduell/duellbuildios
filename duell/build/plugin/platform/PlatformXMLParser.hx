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
	public static function parse(xml : Fast) : Void
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

	public static function parsePlatform(xml : Fast) : Void
	{
		for (element in xml.elements) 
		{
			if (!XMLHelper.isValidElement(element, DuellProjectXML.getConfig().parsingConditions))
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

				case 'infoplist-section':
					parseInfoPlistSectionElement(element);

				case 'infoplist-entry':
					parseInfoPlistEntryElement(element);
			}
		}
	}

	private static function parseArchitectureElement(element : Fast)
	{
		if (element.has.name)
		{
			if (PlatformConfiguration.getData().ARCHS.indexOf(element.att.name) == -1)
			{
				PlatformConfiguration.getData().ARCHS.push(element.att.name);
			}
		}
	}

	private static function parseIconElement(element : Fast)
	{
		if (element.has.path)
		{
			PlatformConfiguration.getData().ICON_PATH = resolvePath(element.att.path);
		}
	}

	private static function parseSplashscreenElement(element : Fast)
	{
		if (element.has.path)
		{
			PlatformConfiguration.getData().SPLASHSCREEN_PATH = resolvePath(element.att.path);
		}
	}

	private static function parseFrameworkElement(element : Fast)
	{
		if (element.has.name)
		{
			var name = element.att.name;
			var path = null;

			for (framework in PlatformConfiguration.getData().FRAMEWORKS)
			{
				if (framework.NAME == name)
					return;
			}

			if (element.has.path)
				path = resolvePath(element.att.path);

			PlatformConfiguration.getData().FRAMEWORKS.push({NAME:name, PATH:path});
		}
	}

	private static function parseHXCPPCompilationArgElement(element : Fast)
	{
		if (element.has.value)
		{
			PlatformConfiguration.getData().HXCPP_COMPILATION_ARGS.push(element.att.value);
		}
	}

	private static function parseXCodeLinkArgElement(element : Fast)
	{
		if (element.has.value)
		{
			PlatformConfiguration.getData().XCODE_LINK_ARGS.push(element.att.value);
		}
	}

	private static function parseXCodeBuildArgElement(element : Fast)
	{
		if (element.has.value)
		{
			PlatformConfiguration.getData().XCODE_BUILD_ARGS.push(element.att.value);
		}
	}

	private static function parseXCodeProjectFlagElement(element : Fast)
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

	private static function parseXCodeTargetFlagElement(element : Fast)
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

	private static function parsePreRenderedIconElement(element : Fast)
	{
		if (element.has.value)
		{
			PlatformConfiguration.getData().PRERENDERED_ICON = element.att.value;
		}	
	}

	private static function parseDeploymentTargetElement(element : Fast)
	{
		if (element.has.value)
		{
			PlatformConfiguration.getData().DEPLOYMENT_TARGET = element.att.value;
		}	
	}

	private static function parseTargetDevicesElement(element : Fast)
	{
		if (element.has.value)
		{
			PlatformConfiguration.getData().TARGET_DEVICES = element.att.value;
		}	
	}

	private static function parseKeyStoreIdentityElement(element : Fast)
	{
		if (element.has.value)
		{
			PlatformConfiguration.getData().KEY_STORE_IDENTITY = element.att.value;
		}	
	}

	private static function parseFullscreenElement(element : Fast)
	{
		if (element.has.value)
		{
			PlatformConfiguration.getData().FULLSCREEN = element.att.value;
		}	
	}

	private static function parseOrientationElement(element : Fast)
	{
		if (element.has.value)
		{
			PlatformConfiguration.getData().ORIENTATIONS = (element.att.value).split(",").map(function (str) return StringTools.trim(str));
		}	
	}

	private static function parseRequiredCapabilityElement(element : Fast)
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

	private static function parseEntitlementsElement(element : Fast)
	{
		if (element.has.path)
		{
			PlatformConfiguration.getData().ENTITLEMENTS_PATH = resolvePath(element.att.path);
		}
	}

	private static function parseInfoPlistSectionElement(element : Fast)
	{
		PlatformConfiguration.getData().INFOPLIST_SECTIONS.push(element.innerHTML);
	}

	private static function parseInfoPlistEntryElement(element : Fast)
	{
		var key: String = null;

		if (element.has.key)
		{
			key = element.att.key;

			var value: String = "";
			var type: EntryType = EntryType.DYNAMIC;

			if (element.has.type)
			{
				type = Type.createEnum(EntryType, element.att.type.toUpperCase());
			}

			if (element.has.value)
			{
				value = element.att.value;
			}

			var entry: PlistEntry =
			{
				KEY : key,
				TYPE : type,
				VALUE : value
			};

			PlatformConfiguration.getData().INFOPLIST_ENTRIES.push(entry);
		}
	}

	/// HELPERS
	private static function addUniqueKeyValueToKeyValueArray(keyValueArray : KeyValueArray, key : String, value : String)
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

	private static function resolvePath(string : String) : String /// convenience method
	{
		return DuellProjectXML.getConfig().resolvePath(string);
	}
}