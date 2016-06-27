package org.bigbluebutton.main.events
{
import flash.events.Event;

public class GoToNextManagerEvent extends Event
{

    public static const SWITCH_TO_NEXT_MANAGER:String = "SWITCH_TO_NEXT_MANAGER";

    public var meetingId:String;

    public function GoToNextManagerEvent(type:String)
    {
        super(type, true, false);
    }

}
}