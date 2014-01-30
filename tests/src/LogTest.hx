package;

import hant.Log;

class LogTest extends haxe.unit.TestCase
{
    public function testSimple()
    {
		var log = new Log(2, 1);
		
		print("\n");
		
		log.start("start deep 0, level 0", 0);
			log.start("start deep 1, level 1", 1);
				log.start("start deep 2, level 2", 2);
					log.start("start deep 3, level 3", 3);
						log.start("start deep 4, level 1", 1);
							log.trace("trace deep 4, level 1", 1);
							log.trace("trace deep 4, level 2", 2);
							log.trace("trace deep 4, level 3", 3);
						log.finishOk();
					log.finishOk();
				log.finishOk();
			log.finishOk();
		log.finishOk();
		
		log.start("start deep 0, level 0", 0);
			log.start("start deep 1, level 5", 5);
				log.start("start deep 2, level 2", 2);
					log.start("start deep 3, level 3", 3);
						log.start("start deep 4, level 1", 1);
						log.finishOk();
					log.finishOk();
				log.finishOk();
			log.finishOk();
		log.finishOk();
		
		assertTrue(true);
    }
	
}
