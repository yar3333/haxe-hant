package hant;

import sys.FileSystem;
using StringTools;

class HaxeCompiler
{
	public static function getPath()
    {
        var r = Sys.getEnv("HAXEPATH");
        
        if (r == null)
        {
			return "haxe";
        }
		
		r = r.replace("\\", "/");
        while (r.endsWith("/"))
        {
            r = r.substr(0, r.length - 1);
        }
        r += "/haxe" + (Sys.systemName() == "Windows" ? ".exe" : "");
        
        if (!FileSystem.exists(r) || FileSystem.isDirectory(r))
        {
            throw "HaxeCompiler compiler is not found (file '" + r + "' does not exist).";
        }
        
        return r;
    }
	
	/**
	 * Run haxe compiler. If port specified, then ensure running haxe compiler server on that port.
	 */
	public static function run(params:Array<String>, port=0, dir=".", echo=true, verbose=true) : Int
	{
		if (port != 0)
		{
			var s = new sys.net.Socket();
			try
			{
				s.connect(new sys.net.Host("127.0.0.1"), port);
				s.close();
			}
			catch (e:Dynamic)
			{
				new sys.io.Process(getPath(), [ "--wait", Std.string(port) ]);
				Sys.sleep(1);
			}
			params = [ "--cwd", FileSystem.fullPath(dir) ,"--connect", Std.string(port) ].concat(params);
		}
		
		var r = Process.run(getPath(), params, echo, verbose);
		return r.exitCode;
	}
	
}