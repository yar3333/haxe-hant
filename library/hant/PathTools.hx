package hant;

using StringTools;

class PathTools 
{
	public static function normalize(path:String) : String
	{
		path = StringTools.replace(path, "\\", "/");
		
		while (path.substr(path.length - 1) == "/")
		{
			path = path.substr(0, path.length - 1);
		}
		
		return path;
	}
	
	public static function makeNative(path:String) : String
	{
		return Sys.systemName() != "Windows" ? path : StringTools.replace(path, "/", "\\");
	}
	
	public static function getRelative(basePath:String, absolutePath:String) : String
	{
        if (basePath == null || basePath == "") basePath = sys.FileSystem.fullPath(".");
        
		basePath = basePath.replace("\\", "/");
        absolutePath = absolutePath.replace("\\", "/");
		
        var r = "";
        var commonPart = "";
        var basePathFolders = basePath.split("/");
        var absolutePathFolders = absolutePath.split("/");
        var i = 0;
        while (i < basePathFolders.length && i < absolutePathFolders.length)
        {
            if (basePathFolders[i].toLowerCase() == absolutePathFolders[i].toLowerCase())
            {
                commonPart += basePathFolders[i] + "/";
            }
            else
            {
                break;
            }
            i++;
        }
        if (commonPart.length > 0)
        {
            for (dir in basePath.substr(commonPart.length - 1).split("/"))
            {
                if (dir != "") r += "../";
            }
        }
        r += absolutePath.substr(commonPart.length);
        return r;
    }	
}