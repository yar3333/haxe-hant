package hant;

class PathTools 
{
	public static function path2normal(path:String) : String
	{
		path = StringTools.replace(path, "\\", "/");
		
		while (path.substr(path.length - 1) == "/")
		{
			path = path.substr(0, path.length - 1);
		}
		
		return path;
	}
	
	public static function path2native(path:String) : String
	{
		return Sys.systemName() != "Windows" ? path : StringTools.replace(path, "/", "\\");
	}
}