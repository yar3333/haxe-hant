package hant;

import haxe.io.Path;
import neko.Lib;

class Native
{
	static var copy_file_preserving_attributes : Dynamic->Dynamic->Dynamic;
	
	public static function copyFilePreservingAttributes(exeDir:String, src:String, dst:String) : Void
	{
		if (copy_file_preserving_attributes == null)
		{
			copy_file_preserving_attributes = Lib.load(exeDir + "haqnative-" + Sys.systemName().toLowerCase(), "copy_file_preserving_attributes", 2);
		}
		
		var r : Int = Lib.nekoToHaxe(copy_file_preserving_attributes(Lib.haxeToNeko(path2native(src)), Lib.haxeToNeko(path2native(dst))));
		
		if (r != 0)
		{
			if (r == 1)
			{
				throw "Error open source file ('" + src + "').";
			}
			else
			if (r == 2)
			{
				throw "Error open dest file ('" + dst + "').";
			}
			else
			if (r == 3)
			{
				throw "Error get attributes from source file ('" + src + "').";
			}
			else
			if (r == 4)
			{
				throw "Error set attributes to dest file ('" + dst + "').";
			}
			else
			{
				throw "Error code is " + r + ".";
			}
		}
	}
	
	static function path2native(s:String) : String
	{
		return Sys.systemName() != "Windows" ? s : StringTools.replace(s, "/", "\\");
	}
}
