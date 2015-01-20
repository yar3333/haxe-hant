package hant;

import stdlib.Exception;
import stdlib.Std;
import sys.FileSystem;
import sys.io.File;
using stdlib.StringTools;

class FlashDevelopProject 
{
	public var projectFilePath : String;
	public var binPath : String;
	public var classPaths : Array<String>;
	public var libs : Map<String,String>;
	public var isDebug : Bool;
	public var platform : String;
	public var additionalCompilerOptions : Array<String>;
	public var directives : Array<String>;
	
	public var allClassPaths(default, null) : Array<String>;
	
	public function new(projectFilePath:String, binPath:String, classPaths:Array<String>, libs:Array<String>, isDebug:Bool, platform:String, additionalCompilerOptions:Array<String>, directives:Array<String>)
	{
		this.projectFilePath = projectFilePath;
		this.binPath = binPath;
		this.classPaths  = classPaths;
		this.libs = Haxelib.getPaths(libs);
		this.isDebug = isDebug;
		this.platform = platform;
		this.additionalCompilerOptions = additionalCompilerOptions;
		this.directives = directives;
		
		allClassPaths = [ Haxelib.getStdLibPath() ].concat(Lambda.array(this.libs).concat(classPaths));
	}
	
	public function addLibs(libs:Array<String>)
	{
		var paths = Haxelib.getPaths(libs);
		for (lib in libs)
		{
			this.libs.set(lib, paths.get(lib));
		}
	}
	
	public static function load(path:String) : FlashDevelopProject
	{
		var projectFilePath = null;
		if (path != null && (path == "" || FileSystem.exists(path)))
		{
			projectFilePath = path == "" || FileSystem.isDirectory(path) ? findProjectFile(path) : path;
		}
		if (projectFilePath == null) return null;
		
		var xml = Xml.parse(File.getContent(projectFilePath));
		
		return new FlashDevelopProject
		(
			projectFilePath,
			getBinPath(xml),
			getClassPaths(xml),
			getLibs(xml),
			getIsDebug(xml),
			getPlatform(xml),
			getAdditionalCompilerOptions(xml),
			getDirectives(xml)
		);

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
	
	static function getBinPath(xml:Xml) : String
	{
		var fast = new haxe.xml.Fast(xml.firstElement());
		
		if (fast.hasNode.output)
		{
			for (elem in fast.node.output.elements)
			{
				if (elem.name == "movie" && elem.has.bin)
				{
					return elem.att.bin;
				}
			}
		}
		
		return "bin";
	}
	
    static function getClassPaths(xml:Xml) : Array<String>
    {
        var r = new Array<String>();
		var fast = new haxe.xml.Fast(xml.firstElement());
		
		if (fast.hasNode.classpaths)
		{
			var classpaths = fast.node.classpaths;
			for (elem in classpaths.elements)
			{
				if (elem.name == 'class' && elem.has.path)
				{
					var path = elem.att.path.trim().replace('\\', '/').rtrim('/');
					if (path == "")
					{
						path = ".";
					}
					r.push(path.rtrim("/") + "/");
				}
			}
		}
		
		return r;
    }
	
    static function getLibs(xml:Xml) : Array<String>
	{
		var fast = new haxe.xml.Fast(xml.firstElement());
		var libs = new Array<String>();
		if (fast.hasNode.haxelib)
		{
			var haxelibs = fast.node.haxelib;
			for (elem in haxelibs.elements)
			{
				if (elem.name == 'library' && elem.has.name)
				{
					libs.push(elem.att.name);
				}
			}
		}
		return libs;
	}
	
	static function getIsDebug(xml:Xml) : Bool
	{
		var fast = new haxe.xml.Fast(xml.firstElement());
		if (fast.hasNode.build)
		{
			for (elem in fast.node.build.elements)
			{
				if (elem.name == 'option' && elem.has.enabledebug)
				{
					return Std.bool(elem.att.enabledebug);
				}
			}
		}
		return true;
	}
	
	static function getPlatform(xml:Xml) : String
	{
		var fast = new haxe.xml.Fast(xml.firstElement());
		
		if (fast.hasNode.output)
		{
			for (elem in fast.node.output.elements)
			{
				if (elem.name == "movie" && elem.has.platform)
				{
					return elem.att.platform.toLowerCase();
				}
			}
		}
		
		return "";
	}
	
	static function getDirectives(xml:Xml) : Array<String>
	{
		var fast = new haxe.xml.Fast(xml.firstElement());
		
		if (fast.hasNode.build)
		{
			for (elem in fast.node.build.elements)
			{
				if (elem.name == "option" && elem.has.directives)
				{
					var s = elem.att.directives.replace("&#xA;", "\n").trim();
					return s != "" ? ~/\s+/g.split(s) : [];
				}
			}
		}
		
		return [];
	}
	
	static function getAdditionalCompilerOptions(xml:Xml) : Array<String>
	{
		var fast = new haxe.xml.Fast(xml.firstElement());
		
		if (fast.hasNode.build)
		{
			for (elem in fast.node.build.elements)
			{
				if (elem.name == "option" && elem.has.additional)
				{
					var s = elem.att.additional.replace("&#xA;", "\n").trim();
					return s != "" ? ~/\s+/g.split(s) : [];
				}
			}
		}
		
		return [];
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
		
        var params = new Array<String>();
        
		for (name in libs.keys())
        {
			params.push("-lib"); params.push(name);
		}
		
		for (name in addLibs)
		{
			if (!libs.exists(name)) params.push("-lib"); params.push(name);
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
		
		params.push("-main");
		params.push("Main");
		
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
}