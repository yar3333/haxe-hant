package hant;

import stdlib.Exception;
using stdlib.StringTools;

class Haxelib
{
	public static function getPaths(libs:Array<String>, ?r:Map<String, String>) : Map<String,String>
	{
		if (r == null) r = new Map<String,String>();

		libs = libs.filter(function(lib) return !r.exists(lib));
		
		if (libs.length == 0) return r;

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
					r.set(lib, Path.normalize(path));
					count++;
				}
			}
		}
		
		if (count != libs.length)
		{
			throw new Exception("haxelib error: haxelib path " + libs.join(" ") + "\n" + output);
		}
		
		return r;
	}
	
	public static function getStdLibPath()
	{
		var haxeStdPath = Sys.getEnv("HAXE_STD_PATH");
		if (haxeStdPath != null && haxeStdPath != "") return Path.normalize(haxeStdPath);
		var haxePath = Sys.getEnv("HAXEPATH");
		if (haxePath != null && haxePath != "") return Path.normalize(Path.join([ haxePath, "std" ]));
		return Sys.systemName() == "Windows" ? "C:/HaxeToolkit/haxe/std" : "/usr/share/haxe/std";
	}
}