package org.bigbluebutton.modules.videoconf.events
{
import flash.events.Event;

public class CloseWindowForEvent extends Event
{
    public static const CLOSE_WINDOW_FOR:String = "closeWindowFor";

    public var userID:String;

    public function CloseWindowForEvent(userID:String)
    {
        this.userID=userID;
        super(CLOSE_WINDOW_FOR, true, false);
    }
}
}