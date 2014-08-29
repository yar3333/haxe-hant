package hant;

#if sys

#if neko
import neko.Lib;
#elseif php
import php.Lib;
#elseif cpp
import cpp.Lib;
#end
using stdlib.StringTools;

class Console
{
	public static function readLine(displayNewLineAtEnd=true) : String
	{
		var s = "";
		while (true)
		{
			var c = Sys.getChar(false);
			if (c == 13) break;
			if (c == 8)
			{
				if (s.length > 0)
				{
					s = s.substr(0, s.length - 1);
					Lib.print(String.fromCharCode(8) + " " + String.fromCharCode(8));
				}
			}
			else
			{
				s += String.fromCharCode(c);
				Lib.print(String.fromCharCode(c));
			}
		}
		if (displayNewLineAtEnd) Lib.println("");
		return s;
	}
}

#end