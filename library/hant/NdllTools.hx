package hant;

import haxe.io.Path;
import neko.Lib;
import neko.vm.Loader;
import neko.vm.Module;
import sys.FileSystem;
using StringTools;

class NdllTools
{
	static var exeDir : String;
	static var systemDir : String;
	static var paths : Map<String, String>;
	
	public static function getPath(lib:String) : String
	{
		if (lib.endsWith(".ndll")) return lib;
		
		if (paths == null) paths = new Map<String, String>();
		
		if (paths.exists(lib)) return paths.get(lib);
		
		if (exeDir == null)
		{
			var moduleName = Module.local().name;
			exeDir = Path.directory(moduleName != "" ? moduleName : Sys.executablePath());
			if (exeDir == "") exeDir = ".";
			exeDir = FileSystem.fullPath(exeDir);
		}
		
		var testedPaths = [];
		
		{
			var s = exeDir + "/" + lib + ".ndll";
			if (FileSystem.exists(s))
			{
				paths.set(lib, s);
				return s;
			}
			testedPaths.push(s);
		}
		
		if (systemDir == null)
		{
			systemDir = "ndll/" + Sys.systemName() + (Lib.load("std", "sys_is64", 0)() ? "64" : "");
		}
		
		{
			var s = exeDir + "/" + systemDir + "/" + lib + ".ndll";
			if (FileSystem.exists(s))
			{
				paths.set(lib, s);
				return s;
			}
			testedPaths.push(s);
		}
		
		for (path in Loader.local().getPath())
		{
			var s = Path.addTrailingSlash(path) + lib + ".ndll";
			if (FileSystem.exists(s))
			{
				paths.set(lib, s);
				return s;
			}
			testedPaths.push(s);
		}
		
		{
			try
			{
				var haxelibPaths = Haxelib.getPaths([ lib ]);
				if (haxelibPaths.get(lib) != null)
				{
					var s = haxelibPaths.get(lib) + systemDir + "/" + lib + ".ndll";
					if (FileSystem.exists(s))
					{
						paths.set(lib, s);
						return s;
					}
					testedPaths.push(s);
				}
			}
			catch (e:Dynamic) {}
		}
		
		return null;
	}
	
	public static function load(lib:String, prim:String, nargs:Int) : Dynamic
	{
		return Lib.load(getPath(lib), prim, nargs);
	}
	
	public static function loadLazy(lib:String, prim:String, nargs:Int) : Dynamic
	{
		return Lib.loadLazy(getPath(lib), prim, nargs);
	}
}