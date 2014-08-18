/**
 * @autor rcam
 * @date 05.08.2014.
 * @company Gameduell GmbH
 */

package duell.build.plugin.platform;

import duell.build.objects.DuellProjectXML;
import duell.build.objects.Configuration;
import duell.helpers.TemplateHelper;
import duell.build.helpers.XCodeHelper;

import duell.helpers.PathHelper;
import duell.helpers.LogHelper;
import duell.helpers.FileHelper;
import duell.helpers.ProcessHelper;

import duell.objects.DuellLib;
import duell.objects.Haxelib;

import sys.FileSystem;
import haxe.io.Path;

class PlatformBuild
{
	public var requiredSetups : Array<String>;

	var args : Array<String>;

	/// VARIABLES SET AFTER PARSING
	var targetDirectory : String;
	var projectDirectory : String;
	var duellBuildIOSPath : String;
	var isDebug : Bool = false;
	var isSimulator : Bool = false;
	var isBuildNDLL : Bool = true;

	public function new() : Void
	{
		requiredSetups = ["mac"];
	}

	public function build(args : Array<String>) : Void
	{
		this.args = args;

		checkArguments();

		parseProject();

		prepareBuild();

		runXCodeBuild();

		sign();
	}

	public function run(args : Array<String>) : Void
	{
		runApp();
	} 

	private function checkArguments()
	{	
		for (arg in args)
		{
			if (arg == "-debug")
			{
				isDebug = true;
			}
			else if (arg == "-simulator")
			{
				isSimulator = true;
			}
			else if (arg == "-nondllbuild")
			{
				isBuildNDLL = false;
			}
		}

		if (isDebug)
		{
			PlatformConfiguration.addParsingDefine("debug");
		}
		else
		{
			PlatformConfiguration.addParsingDefine("release");
		}

		if (isSimulator)
		{
			PlatformConfiguration.addParsingDefine("simulator");
		}
	}

	private function parseProject()
	{
		var projectXML = DuellProjectXML.getConfig();
		projectXML.parse();

		/// Set variables
		targetDirectory = Configuration.getData().OUTPUT + "/" + "ios";
		projectDirectory = targetDirectory + "/" + Configuration.getData().APP.TITLE + "/";
		duellBuildIOSPath = DuellLib.getDuellLib("duellbuildios").getPath();

		/// Additional Configuration
		convertDuellAndHaxelibsIntoHaxeCompilationFlags();
		addHaxeApplicationLibToTheTemplate();
		addHXCPPLibs();
		overrideArchsIfSimulator();
		convertFrameworksToXCodeParts();
	}

	private function overrideArchsIfSimulator()
	{
		if (isSimulator)
		{
			Configuration.getData().PLATFORM.ARCHS = ["i386"];
		}
	}

	private function convertFrameworksToXCodeParts()
	{
		for (framework in PlatformConfiguration.getData().FRAMEWORKS)
		{
			var frameworkID = XCodeHelper.getUniqueIDForXCode();
			var fileID = XCodeHelper.getUniqueIDForXCode();

			if (framework.PATH != null)
				PlatformConfiguration.getData().FRAMEWORK_SEARCH_PATHS.push(framework.PATH);
			
			PlatformConfiguration.getData().ADDL_PBX_BUILD_FILE.push("      " + frameworkID + " /* " + framework.NAME + " in Frameworks */ = {isa = PBXBuildFile; fileRef = " + fileID + " /* " + framework.NAME + " */; };");
			PlatformConfiguration.getData().ADDL_PBX_FILE_REFERENCE.push("      " + fileID + " /* " + framework.NAME + " */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = " + framework.NAME + "; path = " + framework.PATH + "/" + framework.NAME + "; sourceTree = SDKROOT; };");
			PlatformConfiguration.getData().ADDL_PBX_FRAMEWORKS_BUILD_PHASE.push("            " + frameworkID + " /* " + framework.NAME + " in Frameworks */,");
			PlatformConfiguration.getData().ADDL_PBX_FRAMEWORK_GROUP.push("            " + fileID + " /* " + framework.NAME + " */,");
		}
	}

	private function prepareBuild()
	{
		createDirectoriesAndCopyTemplates();
		handleIcons();
		handleSplashscreens();
		handleNDLLs();
	}

	private function runXCodeBuild()
	{
		var platformName = "iphoneos";
		
		if (isSimulator) 
		{
			platformName = "iphonesimulator";
		}
		
		var configuration = "Release";
		
		if (isDebug) 
		{
			configuration = "Debug";
		}
			
		var iphoneVersion = XCodeHelper.getIOSVersion();
		var commands = [ "-configuration", configuration, "PLATFORM_NAME=" + platformName, "SDKROOT=" + platformName + iphoneVersion];
			
		if (isSimulator) 
		{
			commands.push ("-arch");
			commands.push ("i386");
		}
		
		commands = commands.concat(Configuration.getData().PLATFORM.XCODE_BUILD_ARGS);
		
		var result = ProcessHelper.runCommand(targetDirectory, "xcodebuild", commands);

		if (result != 0)
			throw "Build error";
	}

	private function createDirectoriesAndCopyTemplates()
	{
		PathHelper.mkdir(targetDirectory);
		PathHelper.mkdir(projectDirectory);
		PathHelper.mkdir(projectDirectory + "/haxe");

		TemplateHelper.recursiveCopyTemplatedFiles(duellBuildIOSPath + "/template/ios/PROJ/haxe", projectDirectory + "/haxe", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
		
		TemplateHelper.recursiveCopyTemplatedFiles(duellBuildIOSPath + "/template/ios/PROJ/Classes", projectDirectory + "/Classes", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
        TemplateHelper.copyTemplateFile(duellBuildIOSPath + "template/ios/PROJ/PROJ-Entitlements.plist", projectDirectory + "/" + Configuration.getData().APP.TITLE + "-Entitlements.plist", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
        TemplateHelper.copyTemplateFile(duellBuildIOSPath + "template/ios/PROJ/PROJ-Info.plist", projectDirectory + "/" + Configuration.getData().APP.TITLE + "-Info.plist", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
		TemplateHelper.copyTemplateFile(duellBuildIOSPath + "template/ios/PROJ/PROJ-Prefix.pch", projectDirectory + "/" + Configuration.getData().APP.TITLE + "-Prefix.pch", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
		TemplateHelper.recursiveCopyTemplatedFiles(duellBuildIOSPath + "template/ios/PROJ.xcodeproj", targetDirectory + "/" + Configuration.getData().APP.TITLE + ".xcodeproj", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
	}

	private function addHaxeApplicationLibToTheTemplate() 
	{
		var armv7LibID = XCodeHelper.getUniqueIDForXCode();
		var armv6LibID = XCodeHelper.getUniqueIDForXCode();

		Configuration.getData().PLATFORM.ADDL_PBX_FRAMEWORKS_BUILD_PHASE.push("            " + armv6LibID + " /* lib/HaxeApplication.a in Frameworks */,");
		
		if (Configuration.getData().PLATFORM.ARCHS.indexOf("armv7") != -1)
		{
			Configuration.getData().PLATFORM.ADDL_PBX_FRAMEWORKS_BUILD_PHASE.push("            " + armv7LibID + " /* lib/HaxeApplication-v7.a in Frameworks */,");
		}
	}

	private function addHXCPPLibs()
	{

		var binPath = Path.join([Haxelib.getHaxelib("hxcpp").getPath(), "bin"]);
		var buildFilePath = Path.join([Haxelib.getHaxelib("hxcpp").getPath(), "project", "Build.xml"]);

		Configuration.getData().NDLLS.push({NAME : "std", BIN_PATH : binPath, BUILD_FILE_PATH : buildFilePath, REGISTER_STATICS : true});
		Configuration.getData().NDLLS.push({NAME : "regexp", BIN_PATH : binPath, BUILD_FILE_PATH : buildFilePath, REGISTER_STATICS : true});
		Configuration.getData().NDLLS.push({NAME : "zlib", BIN_PATH : binPath, BUILD_FILE_PATH : buildFilePath, REGISTER_STATICS : true});
	}

	private function convertDuellAndHaxelibsIntoHaxeCompilationFlags()
	{
		for (haxelib in Configuration.getData().DEPENDENCIES.HAXELIBS)
		{
			Configuration.getData().HAXE_COMPILE_ARGS.push("-cp");
			Configuration.getData().HAXE_COMPILE_ARGS.push(Haxelib.getHaxelib(haxelib.name, haxelib.version).getPath());
		}

		for (duelllib in Configuration.getData().DEPENDENCIES.DUELLLIBS)
		{
			Configuration.getData().HAXE_COMPILE_ARGS.push("-cp");
			Configuration.getData().HAXE_COMPILE_ARGS.push(DuellLib.getDuellLib(duelllib.name, duelllib.version).getPath());
		}

		for (path in Configuration.getData().SOURCES)
		{
			Configuration.getData().HAXE_COMPILE_ARGS.push("-cp");
			Configuration.getData().HAXE_COMPILE_ARGS.push(path);
		}
	}

	private function handleIcons()
	{
		if (!FileSystem.exists(PlatformConfiguration.getData().ICON_PATH))
		{
			LogHelper.println('Icon path ${PlatformConfiguration.getData().ICON_PATH} is not accessible.');
			return;
		}

		var iconNames = [ "Icon.png", "Icon@2x.png", "Icon-60.png", "Icon-60@2x.png", "Icon-72.png", "Icon-72@2x.png", "Icon-76.png", "Icon-76@2x.png" ];
		
		for (icon in iconNames) 
		{
			var iconPath = PlatformConfiguration.getData().ICON_PATH + "/" + icon;
			if(!FileSystem.exists(iconPath))
			{
				LogHelper.println('Icon $icon not found.');
				continue;
			}

			FileHelper.copyIfNewer(iconPath, projectDirectory + "/" + icon);
		}
	}

	private function handleSplashscreens()
	{		
		if (!FileSystem.exists(PlatformConfiguration.getData().SPLASHSCREEN_PATH))
		{
			LogHelper.println('Splashscreen path ${PlatformConfiguration.getData().SPLASHSCREEN_PATH} is not accessible.');
			return;
		}

		var splashscreenNames = [ "Default.png", "Default@2x.png", "Default-568h@2x.png", "Default-Portrait.png", "Default-Landscape.png", "Default-Portrait@2x.png", "Default-Landscape@2x.png" ];
		
		for (splashscreen in splashscreenNames) 
		{
			var splashscreenPath = PlatformConfiguration.getData().SPLASHSCREEN_PATH + "/" + splashscreen;
			if(!FileSystem.exists(splashscreenPath))
			{
				LogHelper.println('Splashscreen $splashscreen not found.');
				continue;
			}
			
			FileHelper.copyIfNewer(splashscreenPath, projectDirectory + "/" + splashscreen);
		}
	}

	private function handleNDLLs()
	{
		for (archID in 0...3) 
		{
			var arch = ["armv6", "armv7", "i386"][archID];

			var argsForBuild = [["-Diphoneos"],
								["-Diphoneos", "-DHXCPP_ARMV7"],
								["-Diphonesim"]][archID];

			var libExt = [ ".iphoneos.a", ".iphoneos-v7.a", ".iphonesim.a" ][archID];
			
			if (Configuration.getData().PLATFORM.ARCHS.indexOf(arch) == -1)
				continue;
			
			PathHelper.mkdir (projectDirectory + "/lib/" + arch);
			PathHelper.mkdir (projectDirectory + "/lib/" + arch + "-debug");
			
			for (ndll in Configuration.getData().NDLLS) 
			{
				if (isBuildNDLL)
				{
	        		var result = duell.helpers.ProcessHelper.runCommand(Path.directory(ndll.BUILD_FILE_PATH), "haxelib", ["run", "hxcpp", Path.withoutDirectory(ndll.BUILD_FILE_PATH)].concat(argsForBuild));

					if (result != 0)
						LogHelper.error("Problem building ndll " + ndll.NAME);
				}

				handleNDLL(ndll, arch, argsForBuild, libExt);
			}
		}
	}

	private function handleNDLL(ndll : {NAME:String, BIN_PATH:String, BUILD_FILE_PATH:String, REGISTER_STATICS:Bool},
								arch : String, argsForBuild : Array<String>, libExt : String)
	{
		/// Try debug version
		var releaseLib = Path.join([ndll.BIN_PATH, "iPhone", "lib" + ndll.NAME + libExt]);
		var debugLib = Path.join([ndll.BIN_PATH, "iPhone", "lib" + ndll.NAME + "-debug" + libExt]);

		/// Doesn't exist, so use the release on as debug
		if (!FileSystem.exists(debugLib))
		{
			debugLib = releaseLib;
		}

		var releaseDest = projectDirectory + "/lib/" + arch + "/lib" + ndll.NAME + ".a";
		var debugDest = projectDirectory + "/lib/" + arch + "-debug/lib" + ndll.NAME + ".a";
		
		/// Release doesn't exist so force the extension. Used mainly for trying to compile a armv7 lib without -v7, and universal libs
		if (!FileSystem.exists(releaseLib)) 
		{
			releaseLib = Path.join([ndll.BIN_PATH, "iPhone", "lib" + ndll.NAME + ".iphoneos.a"]);
			debugLib = Path.join([ndll.BIN_PATH, "iPhone", "lib" + ndll.NAME + "-debug" + ".iphoneos.a"]);
		}

		/// Copy!
		FileHelper.copyIfNewer(releaseLib, releaseDest);
		
		if (FileSystem.exists(debugLib) && debugLib != releaseLib) 
		{
			FileHelper.copyIfNewer (debugLib, debugDest);
		} 
		else if (FileSystem.exists(debugDest)) 
		{
			/// If debug wasn't supposed to be there
			FileSystem.deleteFile(debugDest);
		}
	}

	private function sign()
	{
		if (isSimulator)
		{
			return;
		}

		var configuration = "Release";
		
		if (isDebug) 
		{
			configuration = "Debug";
		}
		
		var identity = "iPhone Developer";
		
		if (Configuration.getData().PLATFORM.KEY_STORE_IDENTITY != "") 
		{
			identity = Configuration.getData().PLATFORM.KEY_STORE_IDENTITY;	
		}
		
		var commands = ["-s", identity];
		
		if (Configuration.getData().PLATFORM.ENTITLEMENTS_PATH != "") {
			
			commands.push ("--entitlements");
			commands.push (Configuration.getData().PLATFORM.ENTITLEMENTS_PATH);
			
		}
		
		var applicationPath = Path.join([targetDirectory, "build", configuration + "-iphoneos", Configuration.getData().APP.TITLE + ".app"]);
			
		commands.push(applicationPath);
		
		var result = ProcessHelper.runCommand(targetDirectory, "codesign", commands, true, true);

		if (result != 0)
			throw "Sign error";
	}

	private function runApp()
	{
		var configuration = "Release";
		
		if (isDebug) 
		{
			configuration = "Debug";
		}
		
		if (isSimulator) 
		{
			var applicationPath = Path.join([targetDirectory, "build", configuration + "-iphonesimulator", Configuration.getData().APP.TITLE + ".app"]);
			
			var family = "iphone";
			
			if (Configuration.getData().PLATFORM.TARGET_DEVICES == "2") 
			{
				family = "ipad";
			}
			
			var launcher = Path.join([duellBuildIOSPath , "bin", "ios-sim"]);
			Sys.command ("chmod", ["+x", launcher]);

			var launcherPath = Path.directory(launcher);
			
			var result = ProcessHelper.runCommand(launcherPath, "./ios-sim", [ "launch", FileSystem.fullPath(applicationPath), "--sdk", XCodeHelper.getIOSVersion(), "--family", family, "--timeout", "60" ] );
			
			if (result != 0)
				throw "Execution error";
		} 
		else 
		{
			var applicationPath = Path.join([targetDirectory, "build", configuration + "-iphoneos", Configuration.getData().APP.TITLE + ".app"]);
			
			var launcher = Path.join([duellBuildIOSPath , "bin", "ios-deploy"]);
			Sys.command ("chmod", [ "+x", launcher ]);
			
			ProcessHelper.runCommand ("", launcher, [ "install", "--timeout", "5", "--bundle", applicationPath]);
		}
	}
}