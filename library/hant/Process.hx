package hant;

import haxe.io.Bytes;
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
			var buffer = new StringBuf();
			try
			{
				while (true)
				{
					var bytes = Bytes.alloc(4096);
					var n = p.stdout.readBytes(bytes, 0, 4096);
					var s = bytes.getString(0, n);
					for (i in 0...s.length)
					{
						var c = s.charAt(i);
						if (verbose && c == "\n")
						{
							var bufStr = buffer.toString();
							var n = bufStr.lastIndexOf("\n");
							Lib.println(n < 0 ? bufStr : bufStr.substr(n + 1));
						}
						buffer.add(c);
					}
				}
			}
			catch (e:haxe.io.Eof) { }
			output = buffer.toString();
		});
		
		var error : String;
		Thread.create(function()
		{
			var buffer = new StringBuf();
			try
			{
				while (true)
				{
					var bytes = Bytes.alloc(4096);
					var n = p.stdout.readBytes(bytes, 0, 4096);
					var s = bytes.getString(0, n);
					for (i in 0...s.length)
					{
						var c = s.charAt(i);
						if (verbose && c == "\n")
						{
							var bufStr = buffer.toString();
							var n = bufStr.lastIndexOf("\n");
							Lib.println(n < 0 ? bufStr : bufStr.substr(n + 1));
						}
						buffer.add(c);
					}
				}
			}
			catch (e:haxe.io.Eof) { }
			error = buffer.toString();
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