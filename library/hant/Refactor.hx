package hant;

import sys.FileSystem;
import sys.io.Process;
import sys.io.File;
using StringTools;

class Refactor
{
	var baseDir : String;
	
	public function new(baseDir:String);
	{
		this.baseDir = baseDir.replace("\\", "/").rtrim("/");
	}
	
	public function rename(srcPack:String, destPack:String, moveCommand:Array<String>)
	{
		var srcPath = baseDir + "/" + srcPack.replace(".", "/");
		var destPath = baseDir + "/" + destPack.replace(".", "/");
		if (FileSystem.exists(srcPath) && !FileSystem.exists(destPath))
		{
			if (moveCommand != null && moveCommand.length > 0)
			{
				Sys.command(moveCommand[0], Lambda.array(Lambda.map(moveCommand.slice(1), function(s) return s.replace("{src}", srcPath).replace("{dest}", destPath))));
			}
			
			for (file in FileSystem.readDirectory(destPath)
			{
				if (file.endsWith(".hx"))
				{
					replaceInFile(destPath + "/" + file, [ 
						{ 
							  search: "\\bpackage\\s+" + srcPack.replace(".", "[.]") + "\\b"
							, replacement: "package " + destPack
						}
					]);
				}
			}
		}
	}
	
	/**
	 * Find and replace in file.
	 * @param	path		Path to file.
	 * @param	rules		Regular expression to find and replacement string. In replacements use $1-$9 to specify groups. Use '^' and 'v' between '$' and number to make uppercase/lowercase (for example, "x $^1 $v2 $3").
	 */
	public function replace(path:String, rules:Array<{ search:String, replacement:String }>)
	{
		var srcText = File.getContent(path);
		
		var dstText = srcText;
		
		for (rule in rules)
		{
			dstText = new EReg(rule.search, "g").customReplace(dstText, function(re)
			{
				var s = "";
				var i = 0;
				while (i < rule.replacement.length)
				{
					var c = rule.replacement.charAt(i++);
					if (c != "$")
					{
						s += c;
					}
					else
					{
						c = rule.replacement.charAt(i++);
						if (c == "$")
						{
							s += "$";
						}
						else
						{
							var command = "";
							if ("0123456789".indexOf(c) < 0)
							{
								command = c;
								c = rule.replacement.charAt(i++);
							}
							var number = Std.parseInt(c);
							var t = re.matched(number);
							switch(command)
							{
								case "^": t = t.toUpperCase();
								case "v": t = t.toLowerCase();
							}
							s += t;
						}
					}
				}
				return s;
			});
		}
		
		if (dstText != srcText)
		{
			if (getHiddenFileAttribute(path) == false)
			{
				File.saveContent(path, dstText);
			}
			else
			{
				setHiddenFileAttribute(path, false);
				File.saveContent(path, dstText);
				setHiddenFileAttribute(path, true);
			}
		}
		
	}
	
	function getHiddenFileAttribute(path:String) : Bool
	{
		var p = new Process("attrib", [ path ]);
		var s = p.stdout.readAll().toString();
		if (s.length > 12)
		{
			s = s.substr(0, 12);
			return s.indexOf("H") >= 0;
		}
		return false;
	}
	
	function setHiddenFileAttribute(path:String, hidden:Bool) : Void
	{
		Sys.command("attrib", [ (hidden ? "+" : "-") + "H", path ]);
	}
	
}