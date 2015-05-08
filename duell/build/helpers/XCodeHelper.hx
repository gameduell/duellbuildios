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
 
package duell.build.helpers;

using StringTools;

import duell.helpers.CommandHelper;
import duell.objects.DuellProcess;

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

        var proc = new DuellProcess("", "xcode-select", ["--print-path"], {block:true, systemCommand:true, errorMessage: "trying to determine the developer directory"});
        developerDir = proc.getCompleteStdout().toString(); 

		if (developerDir.endsWith("\n"))
		{
			developerDir = developerDir.substr(0, developerDir.length - 1);
		}

		return developerDir;
	}
}
