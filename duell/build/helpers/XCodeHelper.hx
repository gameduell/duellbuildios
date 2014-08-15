/**
 * @autor rcam
 * @date 30.07.2014.
 * @company Gameduell GmbH
 */
 
package duell.build.helpers;

using StringTools;

import duell.helpers.ProcessHelper;

import sys.FileSystem;

class XCodeHelper
{

	private static var seedNumber = 0;
	static public function getUniqueIDForXCode() : String
	{
		return "11C0000000000018" + StringTools.hex(seedNumber++, 8);
	}

	private static var iosVersion : String = null; 
	public static function getIOSVersion() : String 
	{
		if (iosVersion != null) 
			return iosVersion;

		var devPath = haxe.io.Path.join([getDeveloperDir(), "/Platforms/iPhoneOS.platform/Developer/SDKs"]);

		if (FileSystem.exists(devPath)) 
		{
			var best = "";
			var files = FileSystem.readDirectory(devPath);
			var extractVersion = ~/^iPhoneOS(.*).sdk$/;
			
			for (file in files) 
			{
				if (extractVersion.match(file)) 
				{
					var ver = extractVersion.matched (1);
					if (ver > best)
						best = ver;
				}
			}
			
			iosVersion = best;
		}

		return iosVersion;
	}

	private static var developerDir : String = null; 
	public static function getDeveloperDir() : String
	{
		if (developerDir != null)
			return developerDir;

		developerDir = ProcessHelper.runProcess("", "xcode-select", ["--print-path"]);

		if (developerDir.endsWith("\n"))
		{
			developerDir = developerDir.substr(0, developerDir.length - 1);
		}

		return developerDir;
	}
}
