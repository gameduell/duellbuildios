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
import duell.helpers.TestHelper;
import duell.helpers.PlatformHelper;

import duell.objects.Arguments;
import duell.objects.DuellLib;
import duell.objects.Haxelib;
import duell.objects.DuellProcess;

import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;

class PlatformBuild
{
	public var requiredSetups = ["mac"];
	public var supportedHostPlatforms = [WINDOWS, MAC];
	
	public static inline var TEST_RESULT_FILENAME = "test_result_ios.xml";

	/// VARIABLES SET AFTER PARSING
	var targetDirectory : String;
	var projectDirectory : String;
	var fullTestResultPath : String;
	var duellBuildIOSPath : String;

	/// WORKAROUND
	//var iosSimulatorProcess : DuellProcess;

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
		addHaxeApplicationLibToTheTemplate();
		addHXCPPLibs();
		overrideArchsIfSimulator();
		convertFrameworksToXCodeParts();
		convertParsingDefinesToCompilationDefines();
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

		if (Arguments.isSet("-simulator") || Arguments.isSet("-test"))
		{
			Configuration.getData().PLATFORM.SIMULATOR = true;
			Configuration.addParsingDefine("simulator");

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

			Configuration.getData().HAXE_COMPILE_ARGS.push("-D " + define);
		}
	}

	private function parseProject()
	{
		var projectXML = DuellProjectXML.getConfig();
		projectXML.parse();
	}

	private function overrideArchsIfSimulator()
	{
		if (Configuration.getData().PLATFORM.SIMULATOR)
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

	private function overrideTargetDevices()
	{
		if (PlatformConfiguration.getData().TARGET_DEVICES == "")
			PlatformConfiguration.getData().TARGET_DEVICES = "1,2";
	}

	private function prepareXcodeBuild()
	{
		createDirectoriesAndCopyTemplates();
		handleIcons();
		handleSplashscreens();
		handleNDLLs();
	}

	private function runXCodeBuild()
	{
		var argsString = File.getContent(Path.join([targetDirectory, "xcodebuild_args"]));
		var args = argsString.split("\n");
		args = args.filter(function(str) return str != "");
		var result = ProcessHelper.runCommand(targetDirectory, "xcodebuild", args);

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
        TemplateHelper.copyTemplateFile(duellBuildIOSPath + "template/ios/PROJ/PROJ-Entitlements.plist", projectDirectory + "/" + Configuration.getData().APP.FILE + "-Entitlements.plist", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
        TemplateHelper.copyTemplateFile(duellBuildIOSPath + "template/ios/PROJ/PROJ-Info.plist", projectDirectory + "/" + Configuration.getData().APP.FILE + "-Info.plist", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
		TemplateHelper.copyTemplateFile(duellBuildIOSPath + "template/ios/PROJ/PROJ-Prefix.pch", projectDirectory + "/" + Configuration.getData().APP.FILE + "-Prefix.pch", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
		TemplateHelper.recursiveCopyTemplatedFiles(duellBuildIOSPath + "template/ios/PROJ.xcodeproj", targetDirectory + "/" + Configuration.getData().APP.FILE + ".xcodeproj", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
		TemplateHelper.copyTemplateFile(duellBuildIOSPath + "template/ios/xcodebuild_args", targetDirectory + "/xcodebuild_args", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
		TemplateHelper.copyTemplateFile(duellBuildIOSPath + "template/ios/codesign_args", targetDirectory + "/codesign_args", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
		TemplateHelper.copyTemplateFile(duellBuildIOSPath + "template/ios/rundevice_args", targetDirectory + "/rundevice_args", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
		TemplateHelper.copyTemplateFile(duellBuildIOSPath + "template/ios/runsimulator_args", targetDirectory + "/runsimulator_args", Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
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

		Configuration.getData().PLATFORM.XCODE_LINK_ARGS.push("-lHaxeApplication");
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
			Configuration.getData().HAXE_COMPILE_ARGS.push("-lib " + haxelib.name + (haxelib.version != "" ? ":" + haxelib.version : ""));
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
		for (archID in 0...3) 
		{
			var arch = ["armv6", "armv7", "i386"][archID];

			var argsForBuild = [["-Diphoneos"],
								["-Diphoneos", "-DHXCPP_ARMV7"],
								["-Diphonesim"]][archID];

			if (Configuration.getData().PLATFORM.DEBUG)
			{
				argsForBuild.push("-Ddebug");
			}

			var libExt = [ ".iphoneos.a", ".iphoneos-v7.a", ".iphonesim.a" ][archID];
			
			if (Configuration.getData().PLATFORM.ARCHS.indexOf(arch) == -1)
				continue;
			
			PathHelper.mkdir (projectDirectory + "/lib/" + arch);
			PathHelper.mkdir (projectDirectory + "/lib/" + arch + "-debug");
			
			for (ndll in Configuration.getData().NDLLS) 
			{
        		var argsForBuildSpecific = argsForBuild;
				var additionalArgsPath = Path.join([Path.directory(ndll.BUILD_FILE_PATH), "Build.args"]);
				
				if (FileSystem.exists(additionalArgsPath))
				{
					var argsString = File.getContent(additionalArgsPath);
					var additionalArgs = argsString.split("\n");
					additionalArgs = additionalArgs.filter(function(str) return str != "");
					argsForBuildSpecific = argsForBuildSpecific.concat(additionalArgs);
				}

        		var result = duell.helpers.ProcessHelper.runCommand(Path.directory(ndll.BUILD_FILE_PATH), "haxelib", ["run", "hxcpp", Path.withoutDirectory(ndll.BUILD_FILE_PATH)].concat(argsForBuildSpecific));


				if (result != 0)
					LogHelper.error("Problem building ndll " + ndll.NAME);

				copyNDLL(ndll, arch, argsForBuildSpecific, libExt);
			}
		}
	}

	private function copyNDLL(ndll : {NAME:String, BIN_PATH:String, BUILD_FILE_PATH:String, REGISTER_STATICS:Bool},
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
		if (!Configuration.getData().PLATFORM.DEBUG && !FileSystem.exists(releaseLib))
		{
			releaseLib = Path.join([ndll.BIN_PATH, "iPhone", "lib" + ndll.NAME + ".iphoneos.a"]);
		}
		
		/// Debug doesn't exist so force the extension. Used mainly for trying to compile a armv7 lib without -v7, and universal libs
		if (Configuration.getData().PLATFORM.DEBUG && !FileSystem.exists(debugLib)) 
		{
			debugLib = Path.join([ndll.BIN_PATH, "iPhone", "lib" + ndll.NAME + "-debug" + ".iphoneos.a"]);
		}

		/// Copy!
		if (!Configuration.getData().PLATFORM.DEBUG)
		{
			FileHelper.copyIfNewer(releaseLib, releaseDest);
		}
		
		if (Configuration.getData().PLATFORM.DEBUG && FileSystem.exists(debugLib) && debugLib != releaseLib) 
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
		if (Configuration.getData().PLATFORM.SIMULATOR)
		{
			return;
		}

		var argsString = File.getContent(Path.join([targetDirectory, "codesign_args"]));
		var args = argsString.split("\n");
		args = args.filter(function(str) return str != "");
		
		var result = ProcessHelper.runCommand(targetDirectory, "codesign", args, true, true);

		if (result != 0)
			throw "Sign error";
	}

	private function runApp()
	{
		if (Configuration.getData().PLATFORM.SIMULATOR) 
		{
			var argsString = File.getContent(Path.join([targetDirectory, "runsimulator_args"]));
			var args = argsString.split("\n");
			args = args.filter(function(str) return str != "");

			var launcher = Path.join([duellBuildIOSPath , "bin", "ios-sim"]);
			Sys.command ("chmod", ["+x", launcher]);

			var launcherPath = Path.directory(launcher);


			/// WARNING the latest version of the ios sim has some output issues, it only seems to work by running with Sys.command
			/// for now we will use that until a solution is found

			//iosSimulatorProcess = new DuellProcess(launcherPath, "ios-sim", args, {logOnlyIfVerbose:false});
			
			//iosSimulatorProcess.blockUntilFinished();

			//if (iosSimulatorProcess.exitCode() != 0)
			//	throw "Execution error";

			/// WORKAROUND
			Sys.setCwd(launcherPath);
			Sys.command("./ios-sim", args);

		} 
		else 
		{
			var argsString = File.getContent(Path.join([targetDirectory, "rundevice_args"]));
			var args = argsString.split("\n");
			args = args.filter(function(str) return str != "");
			
			var launcher = Path.join([duellBuildIOSPath , "bin", "ios-deploy"]);
			Sys.command ("chmod", [ "+x", launcher ]);
			
			ProcessHelper.runCommand ("", launcher, args);
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
		
		/// WORKAROUND
		//iosSimulatorProcess.kill();
	}
}