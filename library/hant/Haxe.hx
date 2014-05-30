package hant;

class Haxe
{
	public function getHaxePath()
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
        
        if (!FileSystem.exists(r))
        {
            throw "Haxe compiler is not found (file '" + r + "' does not exist).";
        }
        
        return r;
    }
}