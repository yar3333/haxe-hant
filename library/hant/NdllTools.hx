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
	static var systemName : String;
	static var paths : Map<String, String>;
	
	/**
	 * Search for ndll file by library name. Returns path without ".ndll" extension.
	 * Paths to test: 
	 * 		1) <dir_of_*.n_file>/<name>-<platform>.ndll // for example: "c:/dir/curl-windows64.ndll";
	 * 		2) <dir_of_*.n_file>/ndll/<Platform>/<name>.ndll // for example: "c:/dir/ndll/Windows64/curl.ndll";
	 * 		3) <std_paths_(NEKOPATH)>/<name>.ndll;
	 * 		4) <path_from_haxelib>/ndll/<Platform>/<name>.ndll // C:/motion-twin/haxe/lib/hant/1,5,2/ndll/Windows64/hant.ndll.
	 */
	public static function getPath(lib:String, throwNotFound=false) : String
	{
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
		
		if (systemName == null)
		{
			systemName = "" + Sys.systemName() + (Lib.load("std", "sys_is64", 0)() ? "64" : "");
		}
		
		{
			var s = exeDir + "/" + lib + "-" + systemName.toLowerCase();
			if (FileSystem.exists(s + ".ndll"))
			{
				paths.set(lib, s);
				return s;
			}
			testedPaths.push(s);
		}
		
		{
			var s = exeDir + "/ndll/" + systemName + "/" + lib;
			if (FileSystem.exists(s + ".ndll"))
			{
				paths.set(lib, s);
				return s;
			}
			testedPaths.push(s);
		}
		
		for (path in Loader.local().getPath())
		{
			var s = Path.addTrailingSlash(path) + lib;
			if (FileSystem.exists(s + ".ndll"))
			{
				paths.set(lib, s);
				return s;
			}
			testedPaths.push(s);
		}
		
		{
			try
			{
				var path = Haxelib.getPath(lib);
				if (path != null)
				{
					var s = path + "/ndll/" + systemName + "/" + lib;
					if (FileSystem.exists(s + ".ndll"))
					{
						paths.set(lib, s);
						return s;
					}
					testedPaths.push(s);
				}
			}
			catch (e:Dynamic) {}
		}
		
		if (throwNotFound) throw "Ndll flle for library '" + lib + "' is not found. Tested paths = " + testedPaths + ".";
		
		return null;
	}
	
	public static function load(lib:String, prim:String, nargs:Int) : Dynamic
	{
		return Lib.load(getPath(lib, true), prim, nargs);
	}
	
	public static function loadLazy(lib:String, prim:String, nargs:Int) : Dynamic
	{
		return Lib.loadLazy(getPath(lib, true), prim, nargs);
	}
}