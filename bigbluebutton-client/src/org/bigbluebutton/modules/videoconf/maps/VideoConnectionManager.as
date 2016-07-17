package org.bigbluebutton.modules.videoconf.maps
{
import flash.media.Video;

import mx.collections.ArrayCollection;

import org.bigbluebutton.core.UsersUtil;
import org.bigbluebutton.modules.videoconf.business.VideoProxyView;

public class VideoConnectionManager
{
    private var videoProxyViews:ArrayCollection = new ArrayCollection();

    private function get me():String {
        return UsersUtil.getMyUsername();
    }

    public function addConnection(Connection:VideoProxyView):void {
        videoProxyViews.addItem(Connection);
        trace("[" + me + "] addConnection:: userID = [" + Connection.userID + "] numConnections = [" + videoProxyViews.length + "]");
    }

    public function removeConnection(userID:String):VideoProxyView {
        for (var i:int = 0; i < videoProxyViews.length; i++) {
            var conn:VideoProxyView = videoProxyViews.getItemAt(i) as VideoProxyView;
            trace("[" + me + "] removeConnection:: [" + conn.userID + " == " + userID + "] equal = [" + (conn.userID == userID) + "]");
            if (conn.userID == userID) {
                return videoProxyViews.removeItemAt(i) as VideoProxyView;
            }
        }

        return null;
    }

    public function hasConnection(userID:String):Boolean {
        trace("[" + me + "] hasConnection:: user [" + userID + "] numConnections = [" + videoProxyViews.length + "]");
        for (var i:int = 0; i < videoProxyViews.length; i++) {
            var conn:VideoProxyView = videoProxyViews.getItemAt(i) as VideoProxyView;
            trace("[" + me + "] hasConnection:: [" + conn.userID + " == " + userID + "] equal = [" + (conn.userID == userID) + "]");
            if (conn.userID == userID) {
                return true;
            }
        }

        return false;
    }

    public function getConnection(userID:String):VideoProxyView {
        for (var i:int = 0; i < videoProxyViews.length; i++) {
            var conn:VideoProxyView = videoProxyViews.getItemAt(i) as VideoProxyView;
            trace("[" + me + "] getConnection:: [" + conn.userID + " == " + userID + "] equal = [" + (conn.userID == userID) + "]");
            if (conn.userID == userID) return conn;
        }

        return null;
    }

    public function disconnectAll(): void{
        for (var i:int = 0; i < videoProxyViews.length; i++) {
            var conn:VideoProxyView = videoProxyViews.getItemAt(i) as VideoProxyView;
            conn.disconnect();
        }
    }
}
}