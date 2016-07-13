package org.bigbluebutton.modules.videoconf.events {

    import flash.events.Event;

    public class ConnectedViewEvent extends Event {
        public static const VIDEO_CONNECTED_FOR_VIEW:String = "connectedToNginxForView";

        public var userID:String;


        public function ConnectedViewEvent(userID:String) {
            this.userID=userID;
            super(VIDEO_CONNECTED_FOR_VIEW, true, false);
        }
    }
}