package org.bigbluebutton.modules.videoconf.events
{
	import flash.events.Event;
	
	public class ShowNextManagerEvent extends Event
	{
		public static const SHOW_NEXT_MANAGER:String = "SHOW_NEXT_MANAGER";
		public var managerID:String;
		public var meetingID:String;
		
		public function ShowNextManagerEvent(type:String = SHOW_NEXT_MANAGER)
		{
			super(type, true, false);
		}
		
	}
}


