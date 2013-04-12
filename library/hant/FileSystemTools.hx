package hant;

import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
using StringTools;

#if neko
import neko.Lib;
#elseif php
import php.Lib;
#end

class FileSystemTools 
{
    var log : Log;

	#if neko
	var native : Native;
	#end
    
    public function new(?log:Log, ?ndll:String)
    {
        this.log = log != null ? log : new Log(0);
		
		#if neko
		this.native = ndll != null ? new Native(ndll) : null;
		#end
    }
    
    public function findFiles(path:String, ?onFile:String->Void, ?onDir:String->Bool) : Void
    {
		if (FileSystem.exists(path))
		{
			if (FileSystem.isDirectory(path))
			{
				for (file in FileSystem.readDirectory(path))
				{
					var isDir : Bool = null;
					try 
					{
						isDir = FileSystem.isDirectory(path + "/" + file);
					}
					catch (e:Dynamic) 
					{
						log.trace("ERROR: FileSystem.isDirectory('" + path + "/" + file + "')");
					}
					
					if (isDir == true)
					{
						if (file != ".svn" && file != ".hg" && file != ".git")
						{
							if (onDir == null || onDir(path + "/" + file))
							{
								findFiles(path + "/" + file, onFile, onDir);
							}
						}
					}
					else
					if (isDir == false)
					{
						if (onFile != null) onFile(path + "/" + file);
					}
				}
			}
			else
			{
				if (onFile != null) onFile(path);
			}
		}
    }
    
    public function createDirectory(path:String)
    {
        if (!FileSystem.exists(path))
		{
			log.start("Create directory '" + path + "'");
			try
			{
				path = PathTools.path2normal(path);
				var dirs : Array<String> = path.split("/");
				for (i in 0...dirs.length)
				{
					var dir = dirs.slice(0, i + 1).join("/");
					if (!dir.endsWith(":"))
					{
						if (!FileSystem.exists(dir))
						{
							FileSystem.createDirectory(dir);
						}
					}
				}
				log.finishOk();
			}
			catch (message:String)
			{
				log.finishFail(message);
			}
		}
    }
    
    public function copyFolderContent(src:String, dest:String)
    {
		src = PathTools.path2normal(src);
        dest = PathTools.path2normal(dest);
		
		log.start("Copy directory '" + src + "' => '" + dest + "'");
        
		findFiles(src, function(path)
		{
			copyFile(path, dest + path.substr(src.length));
		});
		
		log.finishOk();
    }
	
	public function copyFile(src:String, dest:String)
	{
		#if neko
		if (native != null)
		{
			native.copyFilePreservingAttributes(src, dest);
		}
		#else
		File.copy(src, dest);
		#end
	}
    
	public function rename(path:String, newpath:String)
    {
        log.start("Rename '" + path + "' => '" + newpath + "'");
        try
        {
            if (FileSystem.exists(path))
            {
                if (!FileSystem.isDirectory(path))
				{
					if (FileSystem.exists(newpath))
					{
						FileSystem.deleteFile(newpath);
					}
					FileSystem.rename(path, newpath);
				}
				else
				{
					if (FileSystem.exists(newpath))
					{
						FileSystem.deleteDirectory(newpath);
					}
					FileSystem.rename(path, newpath);
				}
            }
            else
            {
                throw "File '" + path + "' not found.";
            }
            log.finishOk();
        }
        catch (message:String)
        {
            log.finishFail(message);
        }
    }
    
    public function deleteDirectory(path:String)
    {
        if (FileSystem.exists(path))
		{
			log.start("Delete directory '" + path + "'");
			try
			{
				for (file in FileSystem.readDirectory(path))
				{
					if (FileSystem.isDirectory(path + "/" + file))
					{
						deleteDirectory(path + "/" + file);
					}
					else
					{
						deleteFile(path + "/" + file);
					}
				}

				FileSystem.deleteDirectory(path);
				log.finishOk();
			}
			catch (message:String)
			{
				log.finishFail(message);
			}
		}
    }
	
    public function deleteFile(path:String)
    {
        if (FileSystem.exists(path))
		{
			log.start("Delete file '" + path + "'");
			try
			{
				FileSystem.deleteFile(path);
				log.finishOk();
			}
			catch (message:String)
			{
				log.finishFail(message);
			}
		}
    }
	
	public function deleteAny(path:String)
	{
		if (FileSystem.exists(path))
		{
			if (FileSystem.isDirectory(path))
			{
				deleteDirectory(path);
			}
			else
			{
				deleteFile(path);
			}
		}
	}
	
	/*public function runCmd(fileName:String, args:Array<String>)
	{
		var env = Sys.environment();
		if (!env.exists("ComSpec") || !FileSystem.exists(env.get("ComSpec")))
		{
			throw "Command processor not found (please, set 'ComSpec' environment variable).";
		}
		return run(env.get("ComSpec"), [ "/C", fileName.replace("/", "\\") ].concat(args));
	}*/
    
    /*public function getWindowsRegistryValue(key:String) : String
    {
        var dir = neko.Sys.getEnv("TMP");
		if (dir == null)
        {
			dir = "."; 		
        }
        var temp = dir + "/hant-tasks-get_windows_registry_value.txt";
		if (neko.Sys.command('regedit /E "' + temp + '" "' + key + '"') != 0) 
        {
			// might fail without appropriate rights
			return null;
		}
		// it's possible that if registry access was disabled the proxy file is not created
		var content = try neko.io.File.getContent(temp) catch ( e : Dynamic ) return null;
        content = content.replace("\x00", "").replace('\r', '').replace('\\\\', '\\');
		neko.FileSystem.deleteFile(temp);
        
        var re = new EReg('^@="(.*)"$', 'm');
        if (re.match(content)) return re.matched(1);
        
        return content;
    }*/
	
	public function restoreFileTimes(src:String, dest:String, ?filter:EReg)
	{
		findFiles(src, function(srcFile)
		{
			if (filter == null || filter.match(srcFile))
			{
				var destFile = dest + srcFile.substr(src.length);
				if (File.getContent(srcFile) == File.getContent(destFile))
				{
					rename(srcFile, destFile);
				}
			}
		});
	}
	
	public function getHaxePath()
    {
        var r = Sys.getEnv("HAXEPATH");
        
        if (r == null)
        {
            throw "HaXe not found (HAXEPATH environment variable not set).";
        }
		
		r = r.replace("\\", "/");
        while (r.endsWith("/"))
        {
            r = r.substr(0, r.length - 1);
        }
        r += '/';
        
        if (!FileSystem.exists(r + "haxe.exe"))
        {
            throw "HaXe not found (file '" + r + "haxe.exe' does not exist).";
        }
        
        return r;
    }
    
	public function getHiddenFileAttribute(path:String) : Bool
	{
		if (Sys.systemName() == "Windows")
		{
			var p = new Process("attrib", [ path ]);
			var s = p.stdout.readAll().toString();
			if (s.length > 12)
			{
				s = s.substr(0, 12);
				return s.indexOf("H") >= 0;
			}
		}
		return false;
	}
	
	public function setHiddenFileAttribute(path:String, hidden:Bool) : Void
	{
		if (Sys.systemName() == "Windows")
		{
			Sys.command("attrib", [ (hidden ? "+" : "-") + "H", path ]);
		}
	}
}