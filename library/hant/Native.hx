package hant;

import neko.Lib;

class Native
{
	static var copy_file_preserving_attributes : Dynamic->Dynamic->Dynamic;
	
	var ndll : String;
	
	public function new(ndll:String)
	{
		this.ndll = ndll;
	}
	
	public function copyFilePreservingAttributes(src:String, dst:String) : Void
	{
		if (copy_file_preserving_attributes == null)
		{
			copy_file_preserving_attributes = Lib.load(ndll, "copy_file_preserving_attributes", 2);
		}
		
		var r : Int = Lib.nekoToHaxe(copy_file_preserving_attributes(Lib.haxeToNeko(PathTools.path2native(src)), Lib.haxeToNeko(PathTools.path2native(dst))));
		
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
}
