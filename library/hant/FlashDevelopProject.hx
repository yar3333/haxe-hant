package hant;

import stdlib.Exception;
import stdlib.Std;
import sys.FileSystem;
import sys.io.File;
using stdlib.StringTools;

class FlashDevelopProject 
{
	public var projectFilePath(default, null) : String;
	
	public var binPath(default, null) : String;
	public var classPaths(default, null) : Array<String>;
	public var libPaths(default, null) : Map<String,String>;
	public var allClassPaths(default, null) : Array<String>;
	public var isDebug(default, null) : Bool;
	public var srcPath(default, null) : String;
	public var platform(default, null) : String;
	public var additionalCompilerOptions(default, null) : Array<String>;
	
	var directives : Array<String>;
	
	public function new(path:String) 
	{
		projectFilePath = null;
		if (path != null && (path == "" || FileSystem.exists(path)))
		{
			projectFilePath = path == "" || FileSystem.isDirectory(path) ? findProjectFile(path) : path;
		}
		if (projectFilePath == null)
		{
			throw new Exception("FlashDevelop project file is not found by path '" + path + "'.");
		}
		
		var xml = Xml.parse(File.getContent(projectFilePath));
		
		binPath = getBinPath(xml);
		classPaths = getClassPaths(xml);
		libPaths = getLibPaths(xml);
		allClassPaths = [ Haxelib.getStdLibPath() ].concat(Lambda.array(libPaths).concat(classPaths));
		isDebug = getIsDebug(xml);
		srcPath = getSrcPath(xml);
		platform = getPlatform(xml);
		additionalCompilerOptions = getAdditionalCompilerOptions(xml);
		
		directives = getDirectives(xml);
	}
	
	function findProjectFile(dir:String) : String
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
	
	function getBinPath(xml:Xml) : String
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
	
    function getClassPaths(xml:Xml) : Array<String>
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
	
    function getLibPaths(xml:Xml) : Map<String,String>
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
		return Haxelib.getPaths(libs);
    }
	
	function getIsDebug(xml:Xml) : Bool
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
	
	function getSrcPath(xml:Xml) : String
	{
		var r = "src/";
		
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
					r = path.rtrim("/") + "/";
				}
			}
		}
		
		return r;
	}

	function getPlatform(xml:Xml) : String
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
	
	function getAdditionalCompilerOptions(xml:Xml) : Array<String>
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
	
	public function getBuildParams(platform:String, destPath:String, addDefines:Array<String>, removeDefines:Array<String>, libs:Array<String>) : Array<String>
	{
        var params = new Array<String>();
        
		for (name in libPaths.keys())
        {
			params.push("-lib"); params.push(name);
		}
		
		for (name in libs)
		{
			if (!libPaths.exists(name)) params.push("-lib"); params.push(name);
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
			if (d != null && d != "" && (removeDefines == null || !Lambda.has(removeDefines, d)))
			{
				params = params.concat([ "-D", d ]);
			}
		}
		
		params = params.concat(additionalCompilerOptions);
		
		return params;
	}
	
	function getDirectives(xml:Xml) : Array<String>
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
	
	/*
	public function defined(directive:String)
	{
		return Lambda.has(directives, directive);
	}*/
}