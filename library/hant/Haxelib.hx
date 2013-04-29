package hant;

import stdlib.Exception;
using stdlib.StringTools;

class Haxelib
{
	public static function getPaths(libs:Array<String>) : Hash<String>
	{
		var r = new Hash<String>();
		
		var haxelibOutput = Process.run("haxelib", [ "path" ].concat(libs)).stdOut;
		if (haxelibOutput.indexOf("is not installed") >= 0)
		{
			throw new Exception("haxelib error:\n" + haxelibOutput);
		}
		var lines = haxelibOutput.split("\n");
		
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
				}
			}
		}
		
		return r;
	}
}