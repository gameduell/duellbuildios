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


import duell.objects.Arguments;
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

				case 'sim-device':
					parseSimulatorDeviceElement(element);

				case 'sim-os':
					parseSimulatorOsElement(element);

				case 'key-store':
					parseKeyStoreElement(element);

				case 'provisioning-profile':
					parseProvisioningProfileElement(element);

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

				case 'transportsecurity':
					 parseTransportSecurity(element);

				case 'capability':
					parseCapabilityElement(element);

				case 'requires-fullscreen':
					parseRequiresFullScreenElement(element);
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

	private static function parseSimulatorOsElement(element : Fast)
	{
		if (element.has.value && !Arguments.isSet('-simos'))
		{
			PlatformConfiguration.getData().SIM_OS = element.att.value;
		}
	}

	private static function parseSimulatorDeviceElement(element : Fast)
	{
		if (element.has.value && !Arguments.isSet('-simdevice'))
		{
			PlatformConfiguration.getData().SIM_DEVICE = element.att.value;
		}
	}

	private static function parseTargetDevicesElement(element : Fast)
	{
		if (element.has.value)
		{
			PlatformConfiguration.getData().TARGET_DEVICES = element.att.value;
		}
	}

	private static function parseKeyStoreElement(element : Fast)
	{
		if (element.has.path)
		{
			PlatformConfiguration.getData().KEY_STORE_PATH = resolvePath(element.att.path);
		}

		if (element.has.password)
		{
			PlatformConfiguration.getData().KEY_STORE_PASSWORD = element.att.password;
		}

		if (element.has.identity)
		{
			PlatformConfiguration.getData().KEY_STORE_IDENTITY = element.att.identity;
		}
	}

	private static function parseProvisioningProfileElement(element : Fast)
	{
		if (element.has.path)
		{
			PlatformConfiguration.getData().PROVISIONING_PROFILE_PATH = element.att.path;
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

	private static function parseTransportSecurity(element : Fast)
	{
		for (e in element.elements)
		{
			switch(e.name)
			{
				case 'arbitraryloads':
					 parseArbitraryLoads( e );

				case 'exceptiondomain':
					 parseExceptionDomain( e );
			}
		}
	}

	private static function parseArbitraryLoads(element : Fast)
	{
		var val = element.att.value == "true" ? true : false;
		LogHelper.info("================> allow arbitrary loads: " + val);
		PlatformConfiguration.getData().ARBITRARY_LOADS = val;
	}

	private static function parseExceptionDomain(element : Fast)
	{
		var url : String = element.att.url;
		var key : String = "";
		var value : String = "";
		var properties : KeyValueArray = [];

		for (property in element.elements)
		{
			key = property.att.key;
			value = property.att.value;

			properties.push({NAME : key, VALUE : value});
		}

		var exception : ExceptionDomain = {
			URL : url,
			PROPERTIES : properties
		}

		PlatformConfiguration.getData().EXCEPTION_DOMAINS.push(exception);
	}

	private static function parseCapabilityElement(element : Fast)
	{
		var name : String = element.att.name;
		var value: String = "1";

		if (element.has.value)
			value = element.att.value;

		PlatformConfiguration.getData().CAPABILITIES.push({NAME: name, VALUE: value});
	}

	private static function parseRequiresFullScreenElement(element : Fast)
	{
		var value: String = "true";

		if (element.has.value)
			value = element.att.value;

		PlatformConfiguration.getData().REQUIRES_FULLSCREEN = value;
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
