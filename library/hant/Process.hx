package hant;

import neko.Lib;
using StringTools;

class Process extends sys.io.Process 
{
	public static function run(log:Log, fileName:String, args:Array<String>) : { exitCode:Int, stdOut:String, stdErr:String }
	{
		var p = new Process(fileName, args);
		
		var stdOut = "";
		try
		{
			while (true)
			{
				Sys.sleep(0.1);
				stdOut += p.stdout.readLine() + "\n";
			}
		}
		catch (e:haxe.io.Eof) {}
		
		var exitCode = p.exitCode();
		var stdErr = p.stderr.readAll().toString().replace("\r\n", "\n");
		p.close();
		
		if (exitCode != 0)
		{
			log.trace(fileName.replace("/", "\\") + " " + args.join(" ") + " ");
			log.trace("Run error: " + exitCode);
		}
		
		return { exitCode:exitCode, stdOut:stdOut, stdErr:stdErr };
	}
}