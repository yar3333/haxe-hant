package hant;

import neko.Lib;
import neko.vm.Thread;
using StringTools;

class Process extends sys.io.Process 
{
	public static function run(fileName:String, args:Array<String>, ?input:String, verbose=false, ?log:Log) : { exitCode:Int, output:String, error:String }
	{
		if (log != null)
		{
			log.trace(fileName.replace("/", "\\") + " " + args.join(" "));
		}		
		
		var p = new Process(fileName, args);
		
		if (input != null)
		{
			p.stdin.writeString(input);
			p.stdin.close();
		}
		
		var output : String;
		Thread.create(function()
		{
			var buffer = "";
			try
			{
				while (true)
				{
					var s = String.fromCharCode(p.stdout.readByte());
					if (verbose && s == "\n")
					{
						var n = buffer.lastIndexOf("\n");
						Lib.println(n < 0 ? buffer : buffer.substr(n + 1));
					}
					buffer += s;
				}
			}
			catch (e:haxe.io.Eof) { }
			output = buffer;
		});
		
		var error : String;
		Thread.create(function()
		{
			var buffer = "";
			try
			{
				while (true)
				{
					var s = String.fromCharCode(p.stderr.readByte());
					if (verbose && s == "\n")
					{
						var n = buffer.lastIndexOf("\n");
						Lib.println(n < 0 ? buffer : buffer.substr(n + 1));
					}
					buffer += s;
				}
			}
			catch (e:haxe.io.Eof) { }
			error = buffer;
		});
		
		var exitCode = p.exitCode();
		
		while (output == null || error == null) Sys.sleep(0.01);
		
		p.close();
		
		if (exitCode != 0)
		{
			if (log != null)
			{
				log.trace("Run error: " + exitCode);
			}
		}
		
		return { exitCode:exitCode, output:output.replace("\r", ""), error:error };
	}
}