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
import duell.helpers.CommandHelper;
import duell.helpers.TestHelper;
import duell.helpers.PlatformHelper;

import duell.objects.Arguments;
import duell.objects.DuellLib;
import duell.objects.Haxelib;

import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;

using StringTools;

class PlatformBuild
{
	public var requiredSetups = [{name: "mac", version: "1.0.0"}];
	public var supportedHostPlatforms = [MAC];

	public static inline var TEST_RESULT_FILENAME = "test_result_ios.xml";

	/// VARIABLES SET AFTER PARSING
	var targetDirectory : String;
	var projectDirectory : String;
	var fullTestResultPath : String;
	var duellBuildIOSPath : String;

	public function new() : Void
	{
        checkArguments();
	}

    public function parse()
    {
        parseProject();
    }

    public function prepareBuild()
    {
		/// Additional Configuration
    	prepareVariables();
		convertDuellAndHaxelibsIntoHaxeCompilationFlags();
		//addHaxeApplicationLibToTheTemplate();
		addHXCPPLibs();
		convertFrameworksToXCodeParts();
		convertParsingDefinesToCompilationDefines();
		forceDeprecationWarnings();

		overrideTargetDevices();

        prepareXcodeBuild();
    }

	public function build()
	{
		runXCodeBuild();

		sign();
	}

	public function run()
	{
		runApp();
	}

	public function fast()
	{
		parseProject();
		prepareVariables();
		runXCodeBuild();
		sign();

		if (Arguments.isSet("-test"))
			testApp();
		else
			runApp();
	}

	public function publish()
	{
		throw "Publish is not yet implemented";
	}

	public function test()
	{
		testApp();
	}

	private function prepareVariables()
	{
    	/// Set variables
		targetDirectory = Path.join([Configuration.getData().OUTPUT, "ios"]);
		fullTestResultPath = Path.join([Configuration.getData().OUTPUT, "test", TEST_RESULT_FILENAME]);
		projectDirectory = targetDirectory + "/" + Configuration.getData().APP.FILE + "/";
		duellBuildIOSPath = DuellLib.getDuellLib("duellbuildios").getPath();

		Configuration.getData().PLATFORM.IOS_VERSION = XCodeHelper.getIOSVersion();
		Configuration.getData().PLATFORM.OUTPUT_FILE = Path.join([targetDirectory, "build", (Configuration.getData().PLATFORM.DEBUG?"Debug":"Release") + (Configuration.getData().PLATFORM.SIMULATOR?"-iphonesimulator":"-iphoneos"), Configuration.getData().APP.FILE + ".app"]);
	}

	private function checkArguments()
	{
		if (Arguments.isSet("-debug"))
		{
			Configuration.getData().PLATFORM.DEBUG = true;
			Configuration.addParsingDefine("debug");
		}
		else
		{
			Configuration.addParsingDefine("release");
		}

		var isArmv7 = Arguments.isSet("-armv7");
		var isArmv7s = Arguments.isSet("-armv7s");
		var isArm64 = Arguments.isSet("-arm64");
		var isSimulator = Arguments.isSet("-simulator");

		if (isArmv7 || isArmv7s || isArm64)
		{

			if (isSimulator)
				LogHelper.error("simulator arguments is incompatible with architecture arguments such as -armv7s");

			Configuration.getData().PLATFORM.ARCHS = [];

			if (isArmv7)
				Configuration.getData().PLATFORM.ARCHS.push("armv7");
			if (isArmv7s)
				Configuration.getData().PLATFORM.ARCHS.push("armv7s");
			if (isArm64)
				Configuration.getData().PLATFORM.ARCHS.push("arm64");
		}

		if (isSimulator || Arguments.isSet("-test"))
		{
			Configuration.getData().PLATFORM.SIMULATOR = true;
			Configuration.addParsingDefine("simulator");
			Configuration.getData().PLATFORM.ARCHS = ["i386"];
		}

		if (Arguments.isSet("-test"))
		{
			Configuration.addParsingDefine("test");
		}
	}

	private function convertParsingDefinesToCompilationDefines()
	{
		for (define in DuellProjectXML.getConfig().parsingConditions)
		{
			if (define == "cpp") /// not allowed
				continue;

			if (define == "debug") /// already there
				continue;

			if (define == "release") /// already there
				continue;

			Configuration.getData().HAXE_COMPILE_ARGS.push("-D " + define);
		}
	}

	private function forceDeprecationWarnings(): Void
	{
		Configuration.getData().HAXE_COMPILE_ARGS.push("-D deprecation-warnings");
	}

	private function parseProject()
	{
		var projectXML = DuellProjectXML.getConfig();
		projectXML.parse();
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

	private function overrideTargetDevices()
	{
		if (PlatformConfiguration.getData().TARGET_DEVICES == "")
			PlatformConfiguration.getData().TARGET_DEVICES = "1,2";
	}

	private function prepareXcodeBuild()
	{
		convertPlistEntriesToSections();
		createDirectoriesAndCopyTemplates();
		copyNativeFiles();
		handleIcons();
		handleSplashscreens();
		handleNDLLs();
	}

	private function runXCodeBuild()
	{
		var argsString = File.getContent(Path.join([targetDirectory, "xcodebuild_args"]));
		var args = argsString.split("\n");
		args = args.filter(function(str) return str != "");
		var result = CommandHelper.runCommand(targetDirectory, "xcodebuild", args, {errorMessage: "running the xcode build"});

		if (result != 0)
			throw "Build error";
	}

	private static function convertPlistEntriesToSections()
	{
		for (entry in PlatformConfiguration.getData().INFOPLIST_ENTRIES)
		{
			var xmlString: String = '<key>${entry.KEY}</key>';
			var value: String = entry.VALUE;

			switch (entry.TYPE)
			{
				case DYNAMIC:
					xmlString = xmlString + value;

				case BOOL:
					var boolValue: Bool = value.toLowerCase() == "true" || value.toLowerCase() == "yes";
					xmlString = '$xmlString<$boolValue/>';

				case NUMBER:
					var number: Float = Std.parseFloat(value);

					if (number == null || Math.isNaN(number))
					{
						throw 'Invalid argument "$value" for key "${entry.KEY}"';
					}

					xmlString = '$xmlString<real>$number</real>';

				case STRING:
					xmlString = '$xmlString<string>$value</string>';
			}

			PlatformConfiguration.getData().INFOPLIST_SECTIONS.push(xmlString);
		}
	}

	private function createDirectoriesAndCopyTemplates()
	{
		PathHelper.mkdir(targetDirectory);
		PathHelper.mkdir(projectDirectory);
		PathHelper.mkdir(projectDirectory + "/haxe");

		TemplateHelper.recursiveCopyTemplatedFiles(duellBuildIOSPath + "/template/ios/PROJ/haxe", projectDirectory + "/haxe", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);

		TemplateHelper.recursiveCopyTemplatedFiles(duellBuildIOSPath + "/template/ios/PROJ/Classes", projectDirectory + "/Classes", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
        TemplateHelper.copyTemplateFile(duellBuildIOSPath + "template/ios/PROJ/PROJ-Entitlements.plist", projectDirectory + "/" + Configuration.getData().APP.FILE + "-Entitlements.plist", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
        TemplateHelper.copyTemplateFile(duellBuildIOSPath + "template/ios/PROJ/PROJ-Info.plist", projectDirectory + "/" + Configuration.getData().APP.FILE + "-Info.plist", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
		TemplateHelper.copyTemplateFile(duellBuildIOSPath + "template/ios/PROJ/PROJ-Prefix.pch", projectDirectory + "/" + Configuration.getData().APP.FILE + "-Prefix.pch", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
		TemplateHelper.recursiveCopyTemplatedFiles(duellBuildIOSPath + "template/ios/PROJ.xcodeproj", targetDirectory + "/" + Configuration.getData().APP.FILE + ".xcodeproj", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
		TemplateHelper.copyTemplateFile(duellBuildIOSPath + "template/ios/xcodebuild_args", targetDirectory + "/xcodebuild_args", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
		TemplateHelper.copyTemplateFile(duellBuildIOSPath + "template/ios/codesign_args", targetDirectory + "/codesign_args", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
		TemplateHelper.copyTemplateFile(duellBuildIOSPath + "template/ios/rundevice_args", targetDirectory + "/rundevice_args", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
		TemplateHelper.copyTemplateFile(duellBuildIOSPath + "template/ios/runsimulator_args", targetDirectory + "/runsimulator_args", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
	}

	private function copyNativeFiles()
	{
		TemplateHelper.recursiveCopyTemplatedFiles(duellBuildIOSPath + "/native/include", projectDirectory + "/Classes", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
	}

	private function addHXCPPLibs()
	{
		var binPath = Path.join([Haxelib.getHaxelib("hxcpp").getPath(), "bin"]);
		var buildFilePath = Path.join([Haxelib.getHaxelib("hxcpp").getPath(), "project", "Build.xml"]);

		Configuration.getData().NDLLS.push({NAME : "std", BIN_PATH : binPath, BUILD_FILE_PATH : buildFilePath, REGISTER_STATICS : true, DEBUG_SUFFIX : false});
		Configuration.getData().NDLLS.push({NAME : "regexp", BIN_PATH : binPath, BUILD_FILE_PATH : buildFilePath, REGISTER_STATICS : true, DEBUG_SUFFIX : false});
		Configuration.getData().NDLLS.push({NAME : "zlib", BIN_PATH : binPath, BUILD_FILE_PATH : buildFilePath, REGISTER_STATICS : true, DEBUG_SUFFIX : false});
	}

	private function convertDuellAndHaxelibsIntoHaxeCompilationFlags()
	{
		for (haxelib in Configuration.getData().DEPENDENCIES.HAXELIBS)
		{
            var version = haxelib.version;
            if (version.startsWith("ssh") || version.startsWith("http"))
                version = "git";
            Configuration.getData().HAXE_COMPILE_ARGS.push("-lib " + haxelib.name + (version != "" ? ":" + version : ""));
       }

		for (duelllib in Configuration.getData().DEPENDENCIES.DUELLLIBS)
		{
			Configuration.getData().HAXE_COMPILE_ARGS.push("-cp " + DuellLib.getDuellLib(duelllib.name, duelllib.version).getPath());
		}

		for (path in Configuration.getData().SOURCES)
		{
			Configuration.getData().HAXE_COMPILE_ARGS.push("-cp " + path);
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
		for (archID in 0...4)
		{
			var arch = ["armv7", "armv7s", "arm64", "i386"][archID];

			var argsForBuild = [["-Diphoneos", "-DHXCPP_ARMV7"],
								["-Diphoneos", "-DHXCPP_ARMV7S"],
								["-Diphoneos", "-DHXCPP_ARM64"],
								["-Diphonesim"]][archID];

			if (Configuration.getData().PLATFORM.DEBUG)
			{
				argsForBuild.push("-Ddebug");
			}

			var libExt = [ ".iphoneos-v7.a", ".iphoneos-v7s.a", ".iphoneos-64.a", ".iphonesim.a" ][archID];

			if (Configuration.getData().PLATFORM.ARCHS.indexOf(arch) == -1)
				continue;

			PathHelper.mkdir (projectDirectory + "/lib/" + arch);
			PathHelper.mkdir (projectDirectory + "/lib/" + arch + "-debug");

			for (ndll in Configuration.getData().NDLLS)
			{
				/// this is not needed anymore with newer versions of hxcpp, but is kept here for backwards compatibility
        		var argsForBuildSpecific = argsForBuild;
				var additionalArgsPath = Path.join([Path.directory(ndll.BUILD_FILE_PATH), "Build.args"]);

				if (FileSystem.exists(additionalArgsPath))
				{
					var argsString = File.getContent(additionalArgsPath);
					var additionalArgs = argsString.split("\n");
					additionalArgs = additionalArgs.filter(function(str) return str != "");
					argsForBuildSpecific = argsForBuildSpecific.concat(additionalArgs);
				}

        		var result = CommandHelper.runHaxelib(Path.directory(ndll.BUILD_FILE_PATH), ["run", "hxcpp", Path.withoutDirectory(ndll.BUILD_FILE_PATH)].concat(argsForBuildSpecific));

				copyNDLL(ndll, arch, argsForBuildSpecific, libExt);
			}
		}
	}

	private function copyNDLL(ndll : {NAME:String, BIN_PATH:String, BUILD_FILE_PATH:String, REGISTER_STATICS:Bool, DEBUG_SUFFIX: Bool},
								arch : String, argsForBuild : Array<String>, libExt : String)
	{
		/// if there is no suffix, tbe release version might be used.
		var debugSuffix = ndll.DEBUG_SUFFIX? "-debug": "";

		var releaseDest = projectDirectory + "/lib/" + arch + "/lib" + ndll.NAME + ".a";
		var debugDest = projectDirectory + "/lib/" + arch + "-debug/lib" + ndll.NAME + ".a";

		/// Try debug version
		var releaseLib = Path.join([ndll.BIN_PATH, "iPhone", "lib" + ndll.NAME + libExt]);
		var debugLib = Path.join([ndll.BIN_PATH, "iPhone", "lib" + ndll.NAME + debugSuffix + libExt]);

		/// Doesn't exist, so use the release on as debug
		if (!FileSystem.exists(debugLib))
		{
			debugLib = releaseLib;
		}

		/// Release doesn't exist so force the extension. Used mainly for trying to compile a armv7 lib without -v7, and universal libs
		if (!Configuration.getData().PLATFORM.DEBUG && !FileSystem.exists(releaseLib))
		{
			releaseLib = Path.join([ndll.BIN_PATH, "iPhone", "lib" + ndll.NAME + ".iphoneos.a"]);
		}

		/// Debug doesn't exist so force the extension. Used mainly for trying to compile a armv7 lib without -v7, and universal libs
		if (Configuration.getData().PLATFORM.DEBUG && !FileSystem.exists(debugLib))
		{
			debugLib = Path.join([ndll.BIN_PATH, "iPhone", "lib" + ndll.NAME + debugSuffix + ".iphoneos.a"]);
		}

		/// Copy!
		if (!Configuration.getData().PLATFORM.DEBUG)
		{
			if (!FileSystem.exists(releaseLib))
			{
				LogHelper.error("Could not find release lib for ndll" + ndll.NAME + " built with build file " + ndll.BUILD_FILE_PATH + " and having output folder " + ndll.BIN_PATH);
			}

			FileHelper.copyIfNewer(releaseLib, releaseDest);

			if (!FileSystem.exists(debugLib) && FileSystem.exists(debugDest))
			{
				/// If debug wasn't supposed to be there
				FileSystem.deleteFile(debugDest);
			}
		}
		else
		{
			if (!FileSystem.exists(debugLib))
			{
				LogHelper.error("Could not find release lib for ndll" + ndll.NAME + " built with build file " + ndll.BUILD_FILE_PATH + " and having output folder " + ndll.BIN_PATH);
			}

			FileHelper.copyIfNewer (debugLib, debugDest);

			if (!FileSystem.exists(releaseLib) && FileSystem.exists(releaseDest))
			{
				/// If release wasn't supposed to be there
				FileSystem.deleteFile(releaseDest);
			}
		}
	}

	private function sign()
	{
		if (Configuration.getData().PLATFORM.SIMULATOR)
		{
			return;
		}

		var argsString = File.getContent(Path.join([targetDirectory, "codesign_args"]));
		var args = argsString.split("\n");
		args = args.filter(function(str) return str != "");

		CommandHelper.runCommand(targetDirectory, "codesign", args, {exitOnError: false, errorMessage: "signing the app"});
	}

	private function runApp()
	{
		if (Configuration.getData().PLATFORM.SIMULATOR)
		{
			var argsString = File.getContent(Path.join([targetDirectory, "runsimulator_args"]));
			var args = argsString.split("\n");
			args = args.filter(function(str) return str != "");

			var launcher = Path.join([duellBuildIOSPath , "bin", "ios-sim"]);
			CommandHelper.runCommand("", "chmod", ["+x", launcher], {errorMessage: "setting permissions on the simulator launcher"});


			var launcherPath = Path.directory(launcher);

			CommandHelper.runCommand(launcherPath, "ios-sim", args, {systemCommand: false, errorMessage: "running the simulator"});
		}
		else
		{
			var argsString = File.getContent(Path.join([targetDirectory, "rundevice_args"]));
			var args = argsString.split("\n");
			args = args.filter(function(str) return str != "");

			var launcher = Path.join([duellBuildIOSPath , "bin", "ios-deploy"]);
			CommandHelper.runCommand("", "chmod", ["+x", launcher], {errorMessage: "setting permission on the ios deploy tool"});

			CommandHelper.runCommand("", launcher, args, {errorMessage: "deploying the app into the device"});
		}
	}

	private function testApp()
	{
		/// DELETE PREVIOUS TEST
		if (sys.FileSystem.exists(fullTestResultPath))
		{
			sys.FileSystem.deleteFile(fullTestResultPath);
		}

		/// CREATE TARGET FOLDER
		PathHelper.mkdir(Path.directory(fullTestResultPath));

		/// RUN THE APP IN A THREAD
		neko.vm.Thread.create(runApp);

		/// RUN THE LISTENER
		TestHelper.runListenerServer(300, 8181, fullTestResultPath);
	}

	public function clean()
	{
		prepareVariables();
		addHXCPPLibs();

		LogHelper.info('Cleaning ios part of export folder...');

		if (FileSystem.exists(targetDirectory))
		{
			PathHelper.removeDirectory(targetDirectory);
		}

		for (ndll in Configuration.getData().NDLLS)
		{
			LogHelper.info('Cleaning ndll ' + ndll.NAME + "...");
    		var result = CommandHelper.runHaxelib(Path.directory(ndll.BUILD_FILE_PATH), ["run", "hxcpp", Path.withoutDirectory(ndll.BUILD_FILE_PATH), "clean"], {errorMessage: "cleaning ndll"});

			if (result != 0)
				LogHelper.error("Problem cleaning ndll " + ndll.NAME);

			var destFolder = Path.join([ndll.BIN_PATH, "iPhone"]);
			if (FileSystem.exists(destFolder))
			{
				PathHelper.removeDirectory(destFolder);
			}
		}
	}
}
