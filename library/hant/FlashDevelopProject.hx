package hant;

import haxe.xml.Fast;
import stdlib.Exception;
import stdlib.Std;
import sys.FileSystem;
import sys.io.File;
using stdlib.StringTools;

class AmbiguousProjectFilesException extends Exception {}
class LibPathNotFoundException extends Exception {}

class FlashDevelopProject 
{
	public var projectFilePath = "";
	
	public var outputType = "Application";
	public var outputPath = "";
	public var classPaths : Array<String> = [];
	public var libs : Array<String> = [];
	public var isDebug = false;
	public var platform = "";
	public var additionalCompilerOptions : Array<String> = [];
	public var directives : Array<String> = [];
	public var mainClass = "";
	public var preBuildCommand = "";
	public var postBuildCommand = "";
	public var alwaysRunPostBuild = false;
	
	public function new() { }
	
	public static function load(path:String) : FlashDevelopProject
	{
		var r = new FlashDevelopProject();
		
		r.projectFilePath = null;
		if (path != null && (path == "" || FileSystem.exists(path)))
		{
			r.projectFilePath = path == "" || FileSystem.isDirectory(path) ? findProjectFile(path) : path;
		}
		if (r.projectFilePath == null) return null;
		
		var xml = Xml.parse(File.getContent(r.projectFilePath));
		var fast = new Fast(xml.firstElement());
		
		if (fast.hasNode.output)
		{
			for (elem in fast.node.output.elements)
			{
				if (elem.name == "movie")
				{
					if (elem.has.path) r.outputPath = elem.att.path;
					else
					if (elem.has.platform) r.platform = elem.att.platform.toLowerCase();
					else
					if (elem.has.outputType) r.outputType = elem.att.outputType;
				}
			}
		}
		
		if (fast.hasNode.classpaths)
		{
			for (elem in fast.node.classpaths.elements)
			{
				if (elem.name == 'class' && elem.has.path)
				{
					var path = Path.normalize(elem.att.path.trim());
					if (path == "") path = ".";
					r.classPaths.push(path);
				}
			}
		}
		
		if (fast.hasNode.haxelib)
		{
			for (elem in fast.node.haxelib.elements)
			{
				if (elem.name == 'library' && elem.has.name)
				{
					r.libs.push(elem.att.name);
				}
			}
		}
		
		if (fast.hasNode.build)
		{
			for (elem in fast.node.build.elements)
			{
				if (elem.name == 'option')
				{
					if (elem.has.enabledebug) r.isDebug = Std.bool(elem.att.enabledebug);
					else
					if (elem.has.directives)
					{
						var s = elem.att.directives.htmlUnescape().htmlUnescape().trim();
						r.directives = s != "" ? ~/\s+/g.split(s) : [];
					}
					else
					if (elem.has.mainClass) r.mainClass =  elem.att.mainClass;
					else
					if (elem.has.additional)
					{
						var s = elem.att.additional.htmlUnescape().trim();
						r.additionalCompilerOptions = s != "" ? ~/\s+/g.split(s) : [];
					}
				}
			}
		}
		
		if (fast.hasNode.preBuildCommand)
		{
			r.preBuildCommand = fast.node.preBuildCommand.innerHTML.htmlUnescape().htmlUnescape();
		}
		
		if (fast.hasNode.postBuildCommand)
		{
			r.postBuildCommand = fast.node.postBuildCommand.innerHTML.htmlUnescape().htmlUnescape();
			if (fast.node.postBuildCommand.has.alwaysRun)
			{
				r.alwaysRunPostBuild = Std.bool(fast.node.postBuildCommand.att.alwaysRun);
			}
		}
		
		return r;
	}
	
	public function getAllClassPaths(includeStdPath=true) : Array<String>
	{
		var r = [];
		
		if (includeStdPath) r.push(Haxelib.getStdPath());
		
		for (lib in libs)
		{
			var path = Haxelib.getPath(lib);
			if (path == null) throw new LibPathNotFoundException("Path to library '" + lib + "' is not found.");
			r.push(path);
		}
		
		r = r.concat(classPaths);
		
		for (i in 0...additionalCompilerOptions.length)
		{
			if (additionalCompilerOptions[i] == "-lib" && i < additionalCompilerOptions.length - 1)
			{
				var path = Haxelib.getPath(additionalCompilerOptions[i + 1]);
				if (path == null) throw new LibPathNotFoundException("Path to library '" + additionalCompilerOptions[i + 1] + "' is not found.");
				r.push(path);
			}
			else
			if (additionalCompilerOptions[i] == "-cp" && i < additionalCompilerOptions.length - 1)
			{
				r.push(additionalCompilerOptions[i + 1]);
			}
		}
		
		return r;
	}
	
	public function findFile(relativeFilePath:String) : String
	{
		var allClassPaths = getAllClassPaths();
		var i = allClassPaths.length - 1; while (i >= 0)
		{
			if (FileSystem.exists(Path.join([ allClassPaths[i], relativeFilePath ])))
			{
				return Path.join([ allClassPaths[i], relativeFilePath ]);
			}
			i--;
		}
		return null;
	}
	
	public function getBuildParams(?platform:String, ?outputPath:String, ?addDefines:Array<String>, ?addLibs:Array<String>) : Array<String>
	{
		if (platform == null) platform = this.platform;
		if (outputPath == null) outputPath = this.outputPath;
		if (addDefines == null) addDefines = [];
		if (addLibs == null) addLibs = [];
		
		platform = platform.toLowerCase();
		if (platform == "javascript") platform = "js";
		else
		if (platform == "c++") platform = "cpp";
		
        var params = new Array<String>();
        
		for (name in libs)
        {
			params.push("-lib"); params.push(name);
		}
		
		for (name in addLibs)
		{
			if (libs.indexOf(name) < 0)
			{
				params.push("-lib"); params.push(name);
			}
		}
		
		for (path in classPaths)
        {
			params.push("-cp"); params.push(path.rtrim("/"));
        }
		
		if (platform != "custom")
		{
			params.push("-" + platform);
			if (outputPath != null)
			{
				params.push(outputPath != "" ? outputPath : ".");
			}
			else
			{
				params.push("null");
				params.push("--no-output");
			}
		}
		
		if (mainClass != null && mainClass != "")
		{
			params.push("-main"); params.push(mainClass);
		}
		
		if (isDebug)
		{
			params.push("-debug");
		}
		
		for (d in directives.concat(addDefines))
		{
			if (d != null && d != "")
			{
				params = params.concat([ "-D", d ]);
			}
		}
		
		params = params.concat(additionalCompilerOptions);
		
		return params;
	}
	
	public function build(?addParams:Array<String>, port=0, verbose=true) : Int
	{
		return runInDir(projectFilePath != null ? Path.directory(projectFilePath):null, function()
		{
			var r1 = runCommands("Running Pre-Build Command Line...", preBuildCommand, verbose);
			if (r1 != 0) return r1;
			
			var projectDir = projectFilePath != null ? Path.directory(projectFilePath) : "";
			
			var r2 = outputType.toLowerCase() == "application"
				? HaxeCompiler.run(getBuildParams().concat(addParams != null ? addParams : []), port, projectDir != "" ? FileSystem.fullPath(projectDir) : ".", true, verbose)
				: 0;
			
			if (r2 == 0 || alwaysRunPostBuild)
			{
				var r3 = runCommands("Running Post-Build Command Line...", postBuildCommand, verbose);
				if (r3 != 0) return r3;
			}
			
			return r2;
		});
	}
	
	function runCommands(message:String, commandString:String, verbose:Bool) : Int
	{
		var commands = commandString.replace("\r\n", "\n").replace("\r", "\n").split("\n").map(std.StringTools.trim).filter(function(s) return s != "");
		if (commands.length > 0)
		{
			if (verbose) Sys.println(message);
			for (command in commands)
			{
				command = bindVars(command, verbose);
				if (verbose) Sys.println("cmd: " + command);
				var r = Sys.command(command);
				if (r != 0) return r;
			}
		}
		return 0;
	}
	
	function bindVars(text:String, verbose:Bool) : String
	{
		return ~/\$\(([a-zA-Z0-9_]+)\)/g.map(text, function(re)
		{
			return switch (re.matched(1))
			{
				case "ProjectName": Path.withoutDirectory(Path.withoutExtension(projectFilePath));
				case "OutputDir": Path.directory(outputPath);
				case "OutputName": Path.withoutDirectory(outputPath);
				case "OutputFile": outputPath;
				case "ProjectDir": Path.directory(projectFilePath);
				case "ProjectPath": projectFilePath;
				case "TargetPlatform": platform;
				case "CompilerPath": Path.directory(HaxeCompiler.getPath());
				case _:
					if (verbose) Log.echo("WARNING: unknow variable $(" + re.matched(1) + ")");
					re.matched(0);
			}
		});

	}
	
	static function findProjectFile(dir:String) : String
	{
		dir = dir.trim();
		if (dir == "") dir = ".";
		dir = dir.replace("\\", "/").rtrim("/");
		
		var r = [];
		for (file in FileSystem.readDirectory(dir))
		{
			if (file.endsWith(".hxproj") && !FileSystem.isDirectory(dir + "/" + file))
			{
				r.push(dir + "/" + file);
			}
		}
		
		if (r.length > 1)
		{
			throw new AmbiguousProjectFilesException("Several FlashDevelop project files in the '" + dir + "' directory found, so you must specify a path to file.");
		}
		
		return r.length == 1 ? r[0] : null;
	}
	
	static function runInDir(dir:String, func:Void->Int) : Int
	{
		var saveCwd : String = null;
		if (dir != null && dir != "" && dir != ".")
		{
			saveCwd = Sys.getCwd();
			Sys.setCwd(dir);
		}
		
		var r : Int = null;
		
		try
		{
			r = func();
		}
		catch (e:Dynamic)
		{
			if (saveCwd != null) Sys.setCwd(saveCwd);
			Exception.rethrow(e);
		}
		
		if (saveCwd != null) Sys.setCwd(saveCwd);
		
		return r;
	}
}