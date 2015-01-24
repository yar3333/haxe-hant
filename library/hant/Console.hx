package hant;

#if sys

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
					s = s.substring(0, s.length - 1);
					Sys.print(String.fromCharCode(8) + " " + String.fromCharCode(8));
				}
			}
			else
			{
				s += String.fromCharCode(c);
				Sys.print(String.fromCharCode(c));
			}
		}
		if (displayNewLineAtEnd) Sys.println("");
		return s;
	}
}

#end