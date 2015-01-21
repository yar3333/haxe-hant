import hant.FileSystemTools;
import hant.Log;
import hant.PathTools;
import neko.Lib;

class Main 
{
	static function main() 
	{
        var args = Sys.args();
		
		var exeDir = PathTools.normalize(Sys.getCwd());
		if (args.length > 0)
		{
			var dir = args.pop();
			try
			{
				Sys.setCwd(dir);
			}
			catch (e:Dynamic)
			{
				fail("Error: could not change dir to '" + dir + "'.");
			}
		}
        
		if (args.length > 0)
		{
			Log.instance = new Log(5);
			
			var verbose = false;
			
			var k = args.shift();
			if (k == "-v")
			{
				verbose = true;
				k = args.shift();
			}
			
			var commands = new Commands(exeDir, verbose);
			
			switch (k)
			{
				case "fdbuild":
					commands.fdbuild(args);
					
				default:
					fail("Unknow command.");
			}
		}
		else
		{
			summaryHelp();
		}
		
		Sys.exit(0);
	}
	
	static function fail(message:String)
	{
		Lib.println("ERROR: " + message);
		Sys.exit(1);
	}
	
	static function summaryHelp()
	{
		Lib.println("Hant is a tool to support haxe projects.");
		Lib.println("Usage: haxelib run hant [-v] <command> <args>");
		Lib.println("where '-v' is the verbose key and <command> may be:");
		Lib.println("");
		Lib.println("    fdbuild         Build using FlashDevelop project (*.hxproj).");
		Lib.println("");
		Lib.println("Type 'haxelib run hant <command> --help' to get help about specified command.");
	}
}
