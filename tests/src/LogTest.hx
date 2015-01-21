package;

import hant.Log;

class LogTest extends haxe.unit.TestCase
{
    public function testSimple()
    {
		var log = new Log(2, 1);
		
		print("\n");
		
		Log.start("start deep 0, level 0", 0);
			Log.start("start deep 1, level 1", 1);
				Log.start("start deep 2, level 2", 2);
					Log.start("start deep 3, level 3", 3);
						Log.start("start deep 4, level 1", 1);
							Log.echo("trace deep 4, level 1", 1);
							Log.echo("trace deep 4, level 2", 2);
							Log.echo("trace deep 4, level 3", 3);
						Log.finishSuccess();
					Log.finishSuccess();
				Log.finishSuccess();
			Log.finishSuccess();
		Log.finishSuccess();
		
		Log.start("start deep 0, level 0", 0);
			Log.start("start deep 1, level 5", 5);
				Log.start("start deep 2, level 2", 2);
					Log.start("start deep 3, level 3", 3);
						Log.start("start deep 4, level 1", 1);
						Log.finishSuccess();
					Log.finishSuccess();
				Log.finishSuccess();
			Log.finishSuccess();
		Log.finishSuccess();
		
		assertTrue(true);
    }
	
}
