package hant;

import neko.Lib;
using StringTools;

class Process extends sys.io.Process 
{
	public static function run(?log:Log, fileName:String, args:Array<String>, verbose=false) : { exitCode:Int, stdOut:String, stdErr:String }
	{
		if (log != null)
		{
			log.trace(fileName.replace("/", "\\") + " " + args.join(" "));
		}		
		
		var p = new Process(fileName, args);
		
		var stdOut = "";
		try
		{
			while (true)
			{
				Sys.sleep(0.01);
				var s = p.stdout.readLine();
				if (verbose) Lib.println(s);
				stdOut += s + "\n";
			}
		}
		catch (e:haxe.io.Eof) {}
		
		var exitCode = p.exitCode();
		var stdErr = p.stderr.readAll().toString().replace("\r\n", "\n");
		p.close();
		
		if (exitCode != 0)
		{
			if (log != null)
			{
				log.trace("Run error: " + exitCode);
			}
		}
		
		return { exitCode:exitCode, stdOut:stdOut.replace("\r", ""), stdErr:stdErr };
	}
}