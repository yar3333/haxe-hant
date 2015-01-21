package hant;

import stdlib.Exception;
using stdlib.StringTools;

class Haxelib
{
	public static function getPaths(libs:Array<String>, ?r:Map<String, String>) : Map<String,String>
	{
		if (r == null) r = new Map<String,String>();

		libs = libs.filter(function(lib) return !r.exists(lib));

		var output = Process.run("haxelib", [ "path" ].concat(libs), null, false, false).output;
		var lines = output.split("\n");
		
		var count = 0;
		
		for (i in 0...lines.length)
		{
			if (lines[i].startsWith("-D "))
			{
				var lib = lines[i].substr("-D ".length);
				if (Lambda.has(libs, lib))
				{
					var path = lines[i - 1].trim();
					if (path == "") path = ".";
					var p = path.replace("\\", "/").rtrim("/") + "/";
					r.set(lib, p);
					count++;
				}
			}
		}
		
		if (Lambda.count(r) != libs.length)
		{
			throw new Exception("haxelib error: haxelib path " + libs.join(" ") + "\n" + output);
		}
		
		return r;
	}
	
	public static function getStdLibPath()
	{
		var haxeStdPath = Sys.getEnv("HAXE_STD_PATH");
		if (haxeStdPath != null && haxeStdPath != "") return haxeStdPath.rtrim("\\/");
		var haxePath = Sys.getEnv("HAXEPATH");
		if (haxePath != null && haxePath != "") return haxe.io.Path.addTrailingSlash(haxePath) + "std";
		return Sys.systemName() == "Windows" ? "C:\\HaxeToolkit\\haxe\\std" : "/usr/share/haxe/std";
	}
}