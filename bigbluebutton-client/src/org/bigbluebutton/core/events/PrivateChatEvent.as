package org.bigbluebutton.core.events
{
	import flash.events.Event;
	
	public class PrivateChatEvent extends Event
	{
		public static const PRIVATE_CHAT:String = "PRIVATE_CHAT";
		
		public var managerID:String;
		
		public function PrivateChatEvent(type:String)
		{
			super(type, true, false);
		}
	}
}


