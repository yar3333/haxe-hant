import hant.Log;
import hant.Path;

class Main 
{
	static function main() 
	{
        var args = Sys.args();
		
		var exeDir = Path.normalize(Sys.getCwd());
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
					Sys.exit(commands.fdbuild(args));
					
				case "path":
					Sys.exit(commands.path(args));
					
				default:
					fail("Unknow command.");
			}
		}
		else
		{
			Sys.println("Hant is a tool to support haxe projects.");
			Sys.println("Usage: haxelib run hant [-v] <command> <args>");
			Sys.println("where '-v' is the verbose key and <command> may be:");
			Sys.println("");
			Sys.println("    fdbuild         Build using FlashDevelop project (*.hxproj).");
			Sys.println("    path            Get class paths of the specified haxe libraries.");
			Sys.println("");
			Sys.println("Type 'haxelib run hant <command> --help' to get help about specified command.");
		}
		
		Sys.exit(1);
	}
	
	static function fail(message:String)
	{
		Sys.println("ERROR: " + message);
		Sys.exit(1);
	}
}
