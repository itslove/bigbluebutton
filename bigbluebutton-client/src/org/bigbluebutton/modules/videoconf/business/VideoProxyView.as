/**
 * BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
 *
 * Copyright (c) 2012 BigBlueButton Inc. and by respective authors (see below).
 *
 * This program is free software; you can redistribute it and/or modify it under the
 * terms of the GNU Lesser General Public License as published by the Free Software
 * Foundation; either version 3.0 of the License, or (at your option) any later
 * version.
 *
 * BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 * PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License along
 * with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.
 *
 */
package org.bigbluebutton.modules.videoconf.business
{
import com.asfusion.mate.events.Dispatcher;

import flash.events.AsyncErrorEvent;
import flash.events.IOErrorEvent;
import flash.events.NetStatusEvent;
import flash.events.SecurityErrorEvent;
import flash.media.H264Level;
import flash.media.H264Profile;
import flash.media.H264VideoStreamSettings;
import flash.net.NetConnection;
import flash.net.NetStream;
import flash.system.Capabilities;

import mx.collections.ArrayCollection;

import org.bigbluebutton.common.LogUtil;
import org.bigbluebutton.core.BBB;
import org.bigbluebutton.core.UsersUtil;
import org.bigbluebutton.core.managers.UserManager;
import org.bigbluebutton.main.model.users.BBBUser;
import org.bigbluebutton.main.model.users.events.StreamStartedEvent;
import org.bigbluebutton.modules.videoconf.events.ConnectedViewEvent;
import org.bigbluebutton.modules.videoconf.events.StartBroadcastEvent;
import org.bigbluebutton.modules.videoconf.model.VideoConfOptions;


public class VideoProxyView
{
    public var videoOptions:VideoConfOptions;

    private var nc:NetConnection;
    private var ns:NetStream;
    private var _url:String;
    public var userID:String;

    private function parseOptions():void {
        videoOptions = new VideoConfOptions();
        videoOptions.parseOptions();
    }

    public function VideoProxyView(url:String,_userID:String)
    {
        _url = url;
        userID = _userID;
        parseOptions();
        nc = new NetConnection();
        nc.proxyType = "best";
        nc.client = this;
        nc.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onAsyncError);
        nc.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
        nc.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
        nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);

    }

    public function connect():void {
        nc.connect(_url, UsersUtil.getInternalMeetingID(), UsersUtil.getMyUserID());
    }

    private function onAsyncError(event:AsyncErrorEvent):void{
    }

    private function onIOError(event:NetStatusEvent):void{
    }

    private function onConnectedToNginx():void{
        var dispatcher:Dispatcher = new Dispatcher();
        dispatcher.dispatchEvent(new ConnectedViewEvent(userID));
    }

    private function onNetStatus(event:NetStatusEvent):void{
        switch(event.info.code){
            case "NetConnection.Connect.Success":
                ns = new NetStream(nc);
                onConnectedToNginx();
                break;
            default:
                LogUtil.debug("[" + event.info.code + "] for [" + _url + "]");
                break;
        }
    }

    private function onSecurityError(event:NetStatusEvent):void{
    }

    public function get connection():NetConnection{
        return this.nc;
    }




    public function disconnect():void {
        trace("VideoProxyView:: disconnecting from Video application");

        if (nc != null) nc.close();
    }

    public function onBWCheck(... rest):Number {
        return 0;
    }

    public function onBWDone(... rest):void {
        var p_bw:Number;
        if (rest.length > 0) p_bw = rest[0];
        // your application should do something here
        // when the bandwidth check is complete
        trace("bandwidth = " + p_bw + " Kbps.");
    }


}
}
