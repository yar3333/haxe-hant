package hant;

import haxe.io.Path;
import haxe.xml.Fast;
import stdlib.Exception;
import stdlib.Std;
import sys.FileSystem;
import sys.io.File;
using stdlib.StringTools;

class FlashDevelopProject 
{
	static var libsPathCache = new Map<String,String>();
	
	public var projectFilePath = "";
	
	public var outputType = "Application";
	public var binPath = "";
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
	
	public var allClassPaths(get, never) : Array<String>;
	function get_allClassPaths() return [ Haxelib.getStdLibPath() ].concat(Lambda.array(getLibPaths()).concat(classPaths));
	
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
					if (elem.has.bin) r.binPath = elem.att.bin;
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
					var path = PathTools.normalize(elem.att.path.trim());
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
						var s = elem.att.directives.htmlUnescape().trim();
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
	
	public function getLibPaths() : Map<String, String>
	{
		Haxelib.getPaths(libs, libsPathCache);
		var r = new Map<String, String>();
		for (lib in libs) r.set(lib, libsPathCache.get(lib));
		return r;
	}
	
	public function findFile(relativeFilePath:String) : String
	{
		var i = allClassPaths.length - 1;
		while (i >= 0)
		{
			if (FileSystem.exists(allClassPaths[i] + relativeFilePath))
			{
				return allClassPaths[i] + relativeFilePath;
			}
			i--;
		}
		return null;
	}
	
	public function getBuildParams(?platform:String, ?destPath:String, ?addDefines:Array<String>, ?addLibs:Array<String>) : Array<String>
	{
		if (platform == null) platform = this.platform;
		if (addDefines == null) addDefines = [];
		if (addLibs == null) addLibs = [];
		
		platform = platform.toLowerCase();
		if (platform == "javascript") platform = "js";
		
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
		
		params.push("-" + platform);
		if (destPath != null && destPath != "")
		{
			params.push(destPath);
		}
		else
		{
			params.push("null");
			params.push("--no-output");
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
	
	public function build(?addParams:Array<String>, port=0, echo=true, verbose=true)
	{
		if (addParams == null) addParams = [];
		
		var saveCwd : String = null;
		if (projectFilePath != null && projectFilePath != "")
		{
			var dir = Path.directory(projectFilePath);
			if (dir != "")
			{
				saveCwd = Sys.getCwd();
				Sys.setCwd(dir);
			}
		}
		
		try
		{
			runCommands("Running Pre-Build Command Line...", preBuildCommand, echo, verbose);
			
			var r = outputType == "Application"
				? HaxeCompiler.run(getBuildParams().concat(addParams), port, projectFilePath != null && projectFilePath != "" ? FileSystem.fullPath(Path.directory(projectFilePath)) : ".", echo, verbose)
				: 0;
			
			if (r == 0 || alwaysRunPostBuild)
			{
				runCommands("Running Post-Build Command Line...", postBuildCommand, echo, verbose);
			}
		}
		catch (e:Dynamic)
		{
			if (saveCwd != null) Sys.setCwd(saveCwd);
			Exception.rethrow(e);
		}
		
		if (saveCwd != null) Sys.setCwd(saveCwd);
	}
	
	function runCommands(message:String, commandString:String, echo:Bool, verbose:Bool)
	{
		var commands = commandString.replace("\r\n", "\n").replace("\r", "\n").split("\n").map(std.StringTools.trim).filter(function(s) return s != "");
		if (commands.length > 0)
		{
			if (verbose) Sys.println(message);
			for (command in commands)
			{
				command = bindVars(command, verbose);
				if (verbose) Sys.println("cmd: " + command);
				Sys.command(command);
			}
		}
	}
	
	function bindVars(text:String, verbose:Bool) : String
	{
		return ~/\$\(([a-zA-Z0-9_]+)\)/g.map(text, function(re)
		{
			return switch (re.matched(1))
			{
				case "ProjectName": Path.withoutDirectory(Path.withoutExtension(projectFilePath));
				case "OutputDir": Path.directory(binPath);
				case "OutputName": Path.withoutDirectory(binPath);
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
			throw new Exception("Several FlashDevelop project files in the '" + dir + "' directory found, so you must specify full path to file.");
		}
		
		return r.length == 1 ? r[0] : null;
	}
}