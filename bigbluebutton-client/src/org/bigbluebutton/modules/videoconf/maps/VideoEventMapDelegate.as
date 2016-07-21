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
package org.bigbluebutton.modules.videoconf.maps {

import com.asfusion.mate.utils.debug.Debugger;
import com.asfusion.mate.utils.debug.DebuggerUtil;

import flash.events.IEventDispatcher;
import flash.external.ExternalInterface;
import flash.media.Camera;

import mx.collections.ArrayCollection;

import org.bigbluebutton.common.LogUtil;
import org.bigbluebutton.common.events.CloseWindowEvent;
import org.bigbluebutton.common.events.OpenWindowEvent;
import org.bigbluebutton.common.events.ToolbarButtonEvent;
import org.bigbluebutton.core.UsersUtil;
import org.bigbluebutton.core.events.ConnectAppEvent;
import org.bigbluebutton.core.events.PrivateChatEvent;
import org.bigbluebutton.core.managers.UserManager;
import org.bigbluebutton.core.vo.CameraSettingsVO;
import org.bigbluebutton.main.events.BBBEvent;
import org.bigbluebutton.main.events.MadePresenterEvent;
import org.bigbluebutton.main.events.StoppedViewingWebcamEvent;
import org.bigbluebutton.main.events.UserJoinedEvent;
import org.bigbluebutton.main.events.UserLeftEvent;
import org.bigbluebutton.main.model.users.BBBUser;
import org.bigbluebutton.main.model.users.events.BroadcastStartedEvent;
import org.bigbluebutton.main.model.users.events.BroadcastStoppedEvent;
import org.bigbluebutton.main.model.users.events.StreamStartedEvent;
import org.bigbluebutton.modules.broadcast.services.MessageSender;
import org.bigbluebutton.modules.videoconf.business.VideoProxy;
import org.bigbluebutton.modules.videoconf.business.VideoProxyView;
import org.bigbluebutton.modules.videoconf.business.VideoProxyView;
import org.bigbluebutton.modules.videoconf.business.VideoProxyView;
import org.bigbluebutton.modules.videoconf.business.VideoWindowItf;
import org.bigbluebutton.modules.videoconf.events.CloseAllWindowsEvent;
import org.bigbluebutton.modules.videoconf.events.ClosePublishWindowEvent;
import org.bigbluebutton.modules.videoconf.events.ConnectedEvent;
import org.bigbluebutton.modules.videoconf.events.ConnectedViewEvent;
import org.bigbluebutton.modules.videoconf.events.OpenVideoWindowEvent;
import org.bigbluebutton.modules.videoconf.events.ShareCameraRequestEvent;
import org.bigbluebutton.modules.videoconf.events.ShowNextManagerEvent;
import org.bigbluebutton.modules.videoconf.events.StartBroadcastEvent;
import org.bigbluebutton.modules.videoconf.events.StopBroadcastEvent;
import org.bigbluebutton.modules.videoconf.events.WebRTCWebcamRequestEvent;
import org.bigbluebutton.modules.videoconf.model.VideoConfOptions;
import org.bigbluebutton.modules.videoconf.views.AvatarWindow;
import org.bigbluebutton.modules.videoconf.views.PublishWindow;
import org.bigbluebutton.modules.videoconf.views.ToolbarButton;
import org.bigbluebutton.modules.videoconf.views.VideoWindow;
import org.flexunit.runner.manipulation.filters.IncludeAllFilter;
import org.bigbluebutton.main.events.PresenterStatusEvent;
import org.bigbluebutton.main.api.JSLog;
import org.bigbluebutton.modules.videoconf.events.CloseWindowForEvent;
import org.bigbluebutton.modules.users.services.MessageSender;
import org.bigbluebutton.core.BBB;
public class VideoEventMapDelegate {
    static private var PERMISSION_DENIED_ERROR:String = "PermissionDeniedError";

    private var options:VideoConfOptions = new VideoConfOptions();
    private var uri:String;
    private var nginxUri:String ="rtmp://nginxBalancer-1430494642.eu-central-1.elb.amazonaws.com/video";// "rtmp://52.28.104.103/video";

    private var webcamWindows:WindowManager = new WindowManager();
    private var videoProxyConnections:VideoConnectionManager = new VideoConnectionManager();

    private var button:ToolbarButton = new ToolbarButton();
    private var proxy:VideoProxy;
    private var streamName:String;

    private var _dispatcher:IEventDispatcher;
    private var _ready:Boolean = false;
    private var _isPublishing:Boolean = false;
    private var _isPreviewWebcamOpen:Boolean = false;
    private var _isWaitingActivation:Boolean = false;
    private var _chromeWebcamPermissionDenied:Boolean = false;

    public function VideoEventMapDelegate(dispatcher:IEventDispatcher) {
        _dispatcher = dispatcher;
    }

    private function get me():String {
        return UsersUtil.getMyUsername();
    }

    public function start(uri:String):void {
        trace("VideoEventMapDelegate:: [" + me + "] Video Module Started.");
        //var logData:Object = new Object();


        //JSLog.debug("))__)__)_))_)__)VideoConf start uri: " + uri, logData);
        //JSLog.debug("(((_(_()_)__)VideoConf start user role: " + UsersUtil.getMyRole()+"   "+UsersUtil.getInternalMeetingID(), logData);

            this.uri = uri;


    }

    public function viewCamera(userID:String, stream:String, name:String, mock:Boolean = false):void {
        trace("VideoEventMapDelegate:: [" + me + "] viewCamera. ready = [" + _ready + "]");

        if (!_ready) return;
        trace("VideoEventMapDelegate:: [" + me + "] Viewing [" + userID + " stream [" + stream + "]");
        if (!UserManager.getInstance().getConference().amIThisUser(userID)) {
            openViewWindowFor(userID);
        }
    }

    public function handleUserLeftEvent(event:UserLeftEvent):void {
        trace("VideoEventMapDelegate:: [" + me + "] handleUserLeftEvent. ready = [" + _ready + "]");

        if (!_ready) return;

        closeWindow(event.userID);
    }

    public function handleUserJoinedEvent(event:UserJoinedEvent):void {
        trace("VideoEventMapDelegate:: [" + me + "] handleUserJoinedEvent. ready = [" + _ready + "]");

        if (!_ready) return;

        if (options.displayAvatar) {
            openAvatarWindowFor(event.userID);
        }
    }

    private function displayToolbarButton():void {
        button.isPresenter = true;

        if (options.presenterShareOnly) {
            if (UsersUtil.amIPresenter()) {
                button.isPresenter = true;
            } else {
                button.isPresenter = false;
            }
        }

    }

    private function addToolbarButton():void {
        LogUtil.debug("****************** Adding toolbar button. presenter?=[" + UsersUtil.amIPresenter() + "]");
        if (proxy.videoOptions.showButton) {

            displayToolbarButton();

            var event:ToolbarButtonEvent = new ToolbarButtonEvent(ToolbarButtonEvent.ADD);
            event.button = button;
            event.module = "Webcam";
            _dispatcher.dispatchEvent(event);
        }
    }

    private function autoStart():void {
        if (options.skipCamSettingsCheck) {
            skipCameraSettingsCheck();
        } else {
            _dispatcher.dispatchEvent(new ShareCameraRequestEvent());
        }
    }

    private function changeDefaultCamForMac():Camera {
        for (var i:int = 0; i < Camera.names.length; i++) {
            if (Camera.names[i] == "USB Video Class Video") {
                /** Set as default for Macs */
                return Camera.getCamera("USB Video Class Video");
            }
        }

        return null;
    }

    private function getDefaultResolution(resolutions:String):Array {
        var res:Array = resolutions.split(",");
        if (res.length > 0) {
            var resStr:Array = (res[0] as String).split("x");
            var resInts:Array = [Number(resStr[0]), Number(resStr[1])];
            return resInts;
        } else {
            return [Number("320"), Number("240")];
        }
    }

    private function skipCameraSettingsCheck():void {
        var cam:Camera = changeDefaultCamForMac();
        if (cam == null) {
            cam = Camera.getCamera();
        }

        var videoOptions:VideoConfOptions = new VideoConfOptions();

        var resolutions:Array = getDefaultResolution(videoOptions.resolutions);
        var camWidth:Number = resolutions[0];
        var camHeight:Number = resolutions[1];
        trace("Skipping cam check. Using default resolution [" + camWidth + "x" + camHeight + "]");
        cam.setMode(camWidth, camHeight, videoOptions.camModeFps);
        cam.setMotionLevel(5, 1000);
        cam.setKeyFrameInterval(videoOptions.camKeyFrameInterval);

        cam.setQuality(videoOptions.camQualityBandwidth, videoOptions.camQualityPicture);
        initCameraWithSettings(cam.index, cam.width, cam.height);
    }

    private function openWebcamWindows():void {
        trace("VideoEventMapDelegate:: [" + me + "] openWebcamWindows:: ready = [" + _ready + "]");

        var uids:ArrayCollection = UsersUtil.getUserIDs();

        for (var i:int = 0; i < uids.length; i++) {
            var u:String = uids.getItemAt(i) as String;
            trace("VideoEventMapDelegate:: [" + me + "] openWebcamWindows:: open window for = [" + u + "]");
            openWebcamWindowFor(u);
        }
    }

    private function openWebcamWindowFor(userID:String):void {
        trace("VideoEventMapDelegate:: [" + me + "] openWebcamWindowFor:: open window for = [" + userID + "]");
        if (!UsersUtil.isMe(userID) && UsersUtil.hasWebcamStream(userID)) {
            trace("VideoEventMapDelegate:: [" + me + "] openWebcamWindowFor:: Not ME and user = [" + userID + "] is publishing.");

            if (webcamWindows.hasWindow(userID)) {
                trace("VideoEventMapDelegate:: [" + me + "] openWebcamWindowFor:: user = [" + userID + "] has a window open. Close it.");
                closeWindow(userID);
            }
            trace("VideoEventMapDelegate:: [" + me + "] openWebcamWindowFor:: View user's = [" + userID + "] webcam.");
            openViewWindowFor(userID);
        } else {
            if (UsersUtil.isMe(userID) && options.autoStart) {
                trace("VideoEventMapDelegate:: [" + me + "] openWebcamWindowFor:: It's ME and AutoStart. Start publishing.");
                autoStart();
            } else {
                if (options.displayAvatar) {
                    trace("VideoEventMapDelegate:: [" + me + "] openWebcamWindowFor:: It's NOT ME and NOT AutoStart. Open Avatar for user = [" + userID + "]");
                    openAvatarWindowFor(userID);
                } else {
                    trace("VideoEventMapDelegate:: [" + me + "] openWebcamWindowFor:: Is THERE another option for user = [" + userID + "]");
                }
            }
        }
    }

    private function openAvatarWindowFor(userID:String):void {
        if (!UsersUtil.hasUser(userID)) return;
        //var logData:Object = new Object();

        //JSLog.debug("))__)__)_))_)__)Open AvatarWindow close", logData);
        var window:AvatarWindow = new AvatarWindow();
        window.userID = userID;
        window.title = UsersUtil.getUserName(userID);

        trace("VideoEventMapDelegate:: [" + me + "] openAvatarWindowFor:: Closing window for [" + userID + "] [" + UsersUtil.getUserName(userID) + "]");
        closeWindow(userID);

        webcamWindows.addWindow(window);

        trace("VideoEventMapDelegate:: [" + me + "] openAvatarWindowFor:: Opening AVATAR window for [" + userID + "] [" + UsersUtil.getUserName(userID) + "]");

        openWindow(window);
        dockWindow(window);
    }

    private function openPublishWindowFor(userID:String, camIndex:int, camWidth:int, camHeight:int):void {
        var publishWindow:PublishWindow = new PublishWindow();
        publishWindow.userID = userID;
        publishWindow.title = UsersUtil.getUserName(userID);
        publishWindow.camIndex = camIndex;
        publishWindow.setResolution(camWidth, camHeight);
        publishWindow.videoOptions = options;
        publishWindow.quality = options.videoQuality;
        publishWindow.chromePermissionDenied = _chromeWebcamPermissionDenied;
        publishWindow.resolutions = options.resolutions.split(",");


        trace("VideoEventMapDelegate:: [" + me + "] openPublishWindowFor:: Closing window for [" + userID + "] [" + UsersUtil.getUserName(userID) + "]");
        closeWindow(userID);

        webcamWindows.addWindow(publishWindow);

        trace("VideoEventMapDelegate:: [" + me + "] openPublishWindowFor:: Opening PUBLISH window for [" + userID + "] [" + UsersUtil.getUserName(userID) + "]");

        openWindow(publishWindow);
        dockWindow(publishWindow);
    }

    private function closeWindow(userID:String):void {
        if (!webcamWindows.hasWindow(userID)) {
            trace("VideoEventMapDelegate:: [" + me + "] closeWindow:: No window for [" + userID + "] [" + UsersUtil.getUserName(userID) + "]");
            return;
        }

        var win:VideoWindowItf = webcamWindows.removeWindow(userID);
        if (win != null) {
            trace("VideoEventMapDelegate:: [" + me + "] closeWindow:: Closing [" + win.getWindowType() + "] for [" + userID + "] [" + UsersUtil.getUserName(userID) + "]");
            win.close();
            var cwe:CloseWindowEvent = new CloseWindowEvent();
            cwe.window = win;
            _dispatcher.dispatchEvent(cwe);
        } else {
            trace("VideoEventMapDelegate:: [" + me + "] closeWindow:: Not Closing. No window for [" + userID + "] [" + UsersUtil.getUserName(userID) + "]");
        }
    }


    private function closeConnectionForView(userID:String):void {
        if (!videoProxyConnections.hasConnection(userID)) {
            trace("VideoEventMapDelegate:: [" + me + "] closeConnection:: No connection for [" + userID + "] [" + UsersUtil.getUserName(userID) + "]");
            return;
        }

        var conn:VideoProxyView = videoProxyConnections.removeConnection(userID);
        if (conn != null) {
            trace("VideoEventMapDelegate:: [" + me + "] closeConnection:: Closing connection for [" + userID + "] [" + UsersUtil.getUserName(userID) + "]");
            conn.disconnect();

        } else {
            trace("VideoEventMapDelegate:: [" + me + "] closeConnection:: Not Closing. No connections for [" + userID + "] [" + UsersUtil.getUserName(userID) + "]");
        }
    }

    public function handleCloseWindowFor(e:CloseWindowForEvent):void{
        closeWindow(e.userID);
    }

    public function handleOpenViewWindowFor(event:ConnectedViewEvent):void{
        //var logData:Object = new Object();


        //JSLog.debug("(())))__)__)_))_)__)NGINX CONNECTED: " + nginxUri, logData);

        openNGNXViewWindowFor(event.userID);
    }

    private function openNGNXViewWindowFor(userID:String):void {
        trace("VideoEventMapDelegate:: [" + me + "] openViewWindowFor:: Opening VIEW window for [" + userID + "]");

        var window:VideoWindow = new VideoWindow();
        window.userID = userID;
        window.videoOptions = options;
        window.resolutions = options.resolutions.split(",");
        window.title = UsersUtil.getUserName(userID);

        closeWindow(userID);


        var bbbUser:BBBUser = UsersUtil.getUser(userID);
        trace("stream name before:"+bbbUser.streamName);
        //var logData:Object = new Object();
        //JSLog.critical("stream name before:"+bbbUser.streamName, logData);
        //if(!UsersUtil.amIModerator()) {
            //var proxytmp:VideoProxy;
            //proxytmp = new VideoProxy(uri);
            //proxytmp.connect();
            window.startVideo((videoProxyConnections.getConnection(userID)).connection, bbbUser.streamName + UsersUtil.getInternalMeetingID());
        //}else{
           // window.startVideo(proxy.connection, bbbUser.streamName);
        //}
        /*

         var bbbUser:BBBUser = UsersUtil.getUser(userID);
         trace("stream name before:"+bbbUser.streamName);
         //var logData:Object = new Object();
         //JSLog.critical("stream name before:"+bbbUser.streamName, logData);
         window.startVideo(proxy.connection, bbbUser.streamName);
         /*

         window.startVideo(proxy.connection, streamPresenter);
         var user:BBBUser = UserManager.getInstance().getConference().getUser(UsersUtil.getMyUserID());
         var streemUser:BBBUser = UserManager.getInstance().getConference().getUser(window.userID);
         if (!user.isPrivateChat&&!streemUser.presenter){
         return;
         }*/
        //
        webcamWindows.addWindow(window);
        openWindow(window);
        dockWindow(window);
    }

     private function openViewWindowFor(userID:String):void {
         trace("VideoEventMapDelegate:: [" + me + "] openViewWindowFor:: Opening VIEW window for [" + userID + "]");
         closeConnectionForView(userID);
         var proxyNGINX: VideoProxyView = new VideoProxyView(nginxUri,userID);
         proxyNGINX.connect();
         videoProxyConnections.addConnection(proxyNGINX);
     }

     /*
    private function openViewWindowFor(userID:String):void {
        var user:BBBUser = UserManager.getInstance().getConference().getUser(UsersUtil.getMyUserID());
        var bbbUser:BBBUser = UsersUtil.getUser(userID);
        trace("*********Open video for user: " + userID + " privateChat is:" + bbbUser.isPrivateChat + " my private chat:" + user.isPrivateChat);
        if (user.isPrivateChat) {
            if (!bbbUser.isPrivateChat) {
                closeWindow(userID);
                return;
            } else {
                if (user.presenterForPrivateChat != bbbUser.presenterForPrivateChat) {
                    closeWindow(userID);
                    return;
                }
            }
        } else {
            if (bbbUser.isPrivateChat) {
                closeWindow(userID);
                return;
            }
            if (!bbbUser.presenter) {
                closeWindow(userID);
                return;
            }
        }
        trace("VideoEventMapDelegate:: [" + me + "] openViewWindowFor:: Opening VIEW window for [" + userID + "] [" + UsersUtil.getUserName(userID) + "]");

        var window:VideoWindow = new VideoWindow();
        window.userID = userID;
        window.videoOptions = options;
        window.resolutions = options.resolutions.split(",");
        window.title = UsersUtil.getUserName(userID);

        closeWindow(userID);


        trace("stream name before:" + bbbUser.streamName);
        trace("presenter id:" + UsersUtil.getPresenterUserID());
        var streamPresenter:String = "320x240-" + UsersUtil.getPresenterUserID();
        trace("stream name after:" + streamPresenter);

        window.startVideo(proxy.connection, bbbUser.streamName);
        /*
         window.startVideo(proxy.connection, streamPresenter);
         var user:BBBUser = UserManager.getInstance().getConference().getUser(UsersUtil.getMyUserID());
         var streemUser:BBBUser = UserManager.getInstance().getConference().getUser(window.userID);
         if (!user.isPrivateChat&&!streemUser.presenter){
         return;
         }
         //
        webcamWindows.addWindow(window);
        openWindow(window);
        dockWindow(window);
    }
*/
    public function handlePrivateChatEvent(event:PrivateChatEvent):void {
        trace("-------handle Private Chat Event for manager :" + event.managerID);
        var me:BBBUser = UserManager.getInstance().getConference().getMyUser();
        if (!me.isPrivateChat) {
            closeWindow(event.managerID);
        } else {
            if (me.presenterForPrivateChat != event.managerID) {
                closeWindow(event.managerID);
            }
        }
    }

    public function handlePresenterNameChange(userID:String):void {

        var bbbUser:BBBUser = UsersUtil.getUser(userID);

        var window:VideoWindow = new VideoWindow();
        window.userID = userID;
        window.videoOptions = options;
        window.resolutions = options.resolutions.split(",");
        window.title = UsersUtil.getUserName(userID);

        closeWindow(userID);


        trace("stream name before:" + bbbUser.streamName);
        trace("presenter id:" + UsersUtil.getPresenterUserID());
        var streamPresenter:String = "320x240-" + UsersUtil.getPresenterUserID();
        trace("stream name after:" + streamPresenter);

        if(!UsersUtil.amIModerator()) {
            window.startVideo((videoProxyConnections.getConnection(userID)).connection, bbbUser.streamName + UsersUtil.getInternalMeetingID());
        }else{
            window.startVideo(proxy.connection, bbbUser.streamName);
        }
        /*
         window.startVideo(proxy.connection, streamPresenter);
         var user:BBBUser = UserManager.getInstance().getConference().getUser(UsersUtil.getMyUserID());
         var streemUser:BBBUser = UserManager.getInstance().getConference().getUser(window.userID);
         if (!user.isPrivateChat&&!streemUser.presenter){
         return;
         }
         //*/
        webcamWindows.addWindow(window);
        openWindow(window);
        dockWindow(window);
    }

    public function handleShowNextManagerEvent(event:ShowNextManagerEvent):void {
        trace("+_+++++++ShowNextManagerEvent:" + event.managerID);
        openViewWindowFor(event.managerID);
    }

    private function openWindow(window:VideoWindowItf):void {
        var windowEvent:OpenWindowEvent = new OpenWindowEvent(OpenWindowEvent.OPEN_WINDOW_EVENT);
        windowEvent.window = window;
        _dispatcher.dispatchEvent(windowEvent);
    }

    private function dockWindow(window:VideoWindowItf):void {
        // this event will dock the window, if it's enabled
        var openVideoEvent:OpenVideoWindowEvent = new OpenVideoWindowEvent();
        openVideoEvent.window = window;
        _dispatcher.dispatchEvent(openVideoEvent);
    }

    public function connectToVideoApp():void {
        //var logData:Object = new Object();

       // JSLog.debug("1111117890--0-0-0-0connectToVideoApp: " + UsersUtil.getInternalMeetingID(), logData);
        proxy = new VideoProxy(uri);
        proxy.connect();
    }

    public function connectToNextManagerVideo():void {

        //var logData:Object = new Object();

        //JSLog.debug("-=-=-=-=-=connectToNextManagerVideo " + UsersUtil.getInternalMeetingID(), logData);
        UserManager.getInstance().getConference().removeAllParticipants();
        closeAllWindows();
        videoProxyConnections.disconnectAll();
        proxy.disconnect();
        proxy = new VideoProxy(uri);
        proxy.connect();
        BBB.initConnectionManager().readyConnectToNextRoom();
    }

    public function startPublishing(e:StartBroadcastEvent):void {
        LogUtil.debug("VideoEventMapDelegate:: [" + me + "] startPublishing:: Publishing stream to: " + proxy.connection.uri + "/" + e.stream);
        streamName = e.stream;
        proxy.startPublishing(e);

        _isWaitingActivation = false;
        _isPublishing = true;
        UsersUtil.setIAmPublishing(true);

        var broadcastEvent:BroadcastStartedEvent = new BroadcastStartedEvent();
        broadcastEvent.stream = e.stream;
        broadcastEvent.userid = UsersUtil.getMyUserID();
        broadcastEvent.isPresenter = UsersUtil.amIPresenter();
        broadcastEvent.camSettings = UsersUtil.amIPublishing();

        _dispatcher.dispatchEvent(broadcastEvent);
        if (proxy.videoOptions.showButton) {
            button.publishingStatus(button.START_PUBLISHING);
        }
    }

    public function stopPublishing(e:StopBroadcastEvent):void {
        trace("VideoEventMapDelegate:: [" + me + "] Stop publishing. ready = [" + _ready + "]");
        stopBroadcasting();
    }

    private function stopBroadcasting():void {
        trace("Stopping broadcast of webcam");

        proxy.stopBroadcasting();

        _isPublishing = false;
        UsersUtil.setIAmPublishing(false);
        var broadcastEvent:BroadcastStoppedEvent = new BroadcastStoppedEvent();
        broadcastEvent.stream = streamName;
        broadcastEvent.userid = UsersUtil.getMyUserID();
        broadcastEvent.avatarURL = UsersUtil.getAvatarURL();
        _dispatcher.dispatchEvent(broadcastEvent);


        if (proxy.videoOptions.showButton) {
            //Make toolbar button enabled again
            button.publishingStatus(button.STOP_PUBLISHING);
        }

        closeWindow(UsersUtil.getMyUserID());

        if (options.displayAvatar) {
            trace("VideoEventMapDelegate:: [" + me + "] Opening avatar");
            openAvatarWindowFor(UsersUtil.getMyUserID());
        }

        var sender:org.bigbluebutton.modules.users.services.MessageSender = new org.bigbluebutton.modules.users.services.MessageSender();
        sender.closeVideoWindowFor(UsersUtil.getMyUserID());

    }

    public function handleClosePublishWindowEvent(event:ClosePublishWindowEvent):void {
        trace("Closing publish window");
        if (_isPublishing || _chromeWebcamPermissionDenied) {
            stopBroadcasting();
        }
        trace("Resetting flags for publish window.");
        // Reset flags to determine if we are publishing or previewing webcam.
        _isPublishing = false;
        _isWaitingActivation = false;
    }

    public function handleShareCameraRequestEvent(event:ShareCameraRequestEvent):void {
        if (options.skipCamSettingsCheck) {
            skipCameraSettingsCheck();
        } else {
            trace("Webcam: " + _isPublishing + " " + _isPreviewWebcamOpen + " " + _isWaitingActivation);
            if (!_isPublishing && !_isPreviewWebcamOpen && !_isWaitingActivation) {
                openWebcamPreview(event.publishInClient);
            }
        }
    }

    public function handleCamSettingsClosedEvent(event:BBBEvent):void {
        _isPreviewWebcamOpen = false;
    }

    private function openWebcamPreview(publishInClient:Boolean):void {
        var openEvent:BBBEvent = new BBBEvent(BBBEvent.OPEN_WEBCAM_PREVIEW);
        openEvent.payload.publishInClient = publishInClient;
        openEvent.payload.resolutions = options.resolutions;
        openEvent.payload.chromePermissionDenied = _chromeWebcamPermissionDenied;

        _isPreviewWebcamOpen = true;

        _dispatcher.dispatchEvent(openEvent);
    }

    public function stopModule():void {
        trace("VideoEventMapDelegate:: stopping video module");
        closeAllWindows();
        proxy.disconnect();
        videoProxyConnections.disconnectAll();
    }

    public function closeAllWindows():void {
        trace("VideoEventMapDelegate:: closing all windows");
        if (_isPublishing) {
            stopBroadcasting();
        }

        _dispatcher.dispatchEvent(new CloseAllWindowsEvent());
    }

    public function switchToPresenter(event:MadePresenterEvent):void {
        trace("VideoEventMapDelegate:: [" + me + "] Got Switch to presenter event. ready = [" + _ready + "]");
        var me:BBBUser = UserManager.getInstance().getConference().getMyUser();

        /*if (!me.isPrivateChat && !UsersUtil.amIModerator()) {
            handlePresenterNameChange(event.userID);
        }
        */
        if (options.showButton) {
            displayToolbarButton();
        }
    }

    public function switchToViewer(event:MadePresenterEvent):void {
        trace("VideoEventMapDelegate:: [" + me + "] Got Switch to viewer event. ready = [" + _ready + "]");
        var me:BBBUser = UserManager.getInstance().getConference().getMyUser();

        /*if (!me.isPrivateChat && !UsersUtil.amIModerator()) {
            handlePresenterNameChange(event.userID);
        }*/
        if (options.showButton) {
            LogUtil.debug("****************** Switching to viewer. Show video button?=[" + UsersUtil.amIPresenter() + "]");
            displayToolbarButton();
            if (_isPublishing && options.presenterShareOnly) {
                stopBroadcasting();
            }
        }
    }

    public function connectedToVideoApp():void {
        trace("VideoEventMapDelegate:: [" + me + "] Connected to video application.");
        _ready = true;
        addToolbarButton();
        openWebcamWindows();
    }

    public function handleCameraSetting(event:BBBEvent):void {
        var cameraIndex:int = event.payload.cameraIndex;
        var camWidth:int = event.payload.cameraWidth;
        var camHeight:int = event.payload.cameraHeight;
        trace("VideoEventMapDelegate::handleCameraSettings [" + cameraIndex + "," + camWidth + "," + camHeight + "]");
        initCameraWithSettings(cameraIndex, camWidth, camHeight);
    }

    private function initCameraWithSettings(camIndex:int, camWidth:int, camHeight:int):void {
        var camSettings:CameraSettingsVO = new CameraSettingsVO();
        camSettings.camIndex = camIndex;
        camSettings.camWidth = camWidth;
        camSettings.camHeight = camHeight;

        UsersUtil.setCameraSettings(camSettings);

        _isWaitingActivation = true;
        openPublishWindowFor(UsersUtil.getMyUserID(), camIndex, camWidth, camHeight);
    }

    public function handleStoppedViewingWebcamEvent(event:StoppedViewingWebcamEvent):void {
        trace("VideoEventMapDelegate::handleStoppedViewingWebcamEvent [" + me + "] received StoppedViewingWebcamEvent for user [" + event.webcamUserID + "]");
        //var logData:Object = new Object();

        //JSLog.debug("()))()9999__999____handleStoppedViewingWebcamEvent ", logData);
        closeWindow(event.webcamUserID);

        if (options.displayAvatar && UsersUtil.hasUser(event.webcamUserID) && !UsersUtil.isUserLeaving(event.webcamUserID)) {
            trace("VideoEventMapDelegate::handleStoppedViewingWebcamEvent [" + me + "] Opening avatar for user [" + event.webcamUserID + "]");
            openAvatarWindowFor(event.webcamUserID);
        }
    }
}
}
