/**
 * Created by hector.arellano on 2/8/16.
 */
package com.firstborn.pepsi.display {
import com.firstborn.pepsi.application.FountainFamily;
import com.firstborn.pepsi.display.gpu.common.blobs.BlobShape;
import com.firstborn.pepsi.events.TouchHandler;
import com.zehfernando.display.templates.application.SimpleApplication;
import com.zehfernando.localization.StringList;
import flash.display.GradientType;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageQuality;
import flash.display.StageScaleMode;
import flash.events.MouseEvent;
import flash.events.NetStatusEvent;
import flash.events.StageVideoAvailabilityEvent;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.media.Camera;
import flash.media.H264Level;
import flash.media.H264Profile;
import flash.media.H264VideoStreamSettings;
import flash.media.Microphone;
import flash.media.StageVideo;
import flash.media.StageVideoAvailability;
import flash.media.Video;
import flash.net.NetConnection;
import flash.net.NetStream;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.utils.clearInterval;
import flash.utils.setInterval;

public class VideoClient extends SimpleApplication {

    public static const NAME_XML_CONFIG:String = "config_xml";
    public static var configList:StringList; // List of configuration switches
    private var video:StageVideo;
    private var camera:Camera;
    private var mic:Microphone = Microphone.getMicrophone(1);
    private var activeVideoButton:Sprite;
    private var sizeVideoButton:Sprite;
    private var toggleVideo:Boolean = false;
    private var _remoteStreamConnection:NetConnection;
    private var _remoteStream:NetStream = null;
    private var _machineStreamConnection:NetConnection;
    private var _machineStream:NetStream = null;
    private var _metaData:Object = new Object();
    private var ownVideo:Video;
    private var format:TextFormat;
    private var _cameraMask:Sprite;
    private var videoContainer:Sprite;
    private var application:FountainFamily;
    private var holder:Sprite;
    private var fullscreenSizeVideo:Boolean = true;
    private var slider : Sprite;
    private var sliderContainer : Sprite;
    private var blobShape : BlobShape;
    private var blobStroke : BlobShape;
    private var blobAnimation : uint;
    private var centerer : Sprite;
    private var machineVideo : Video;
    private var talentVideo : Video;

    //Constructor
    public function VideoClient() {

        trace(mic.name);

        stage.quality = StageQuality.HIGH;
        stage.align = StageAlign.TOP;
        stage.scaleMode = StageScaleMode.NO_SCALE;

        camera = Camera.getCamera('0');
        var scaler : Number= 1;
        camera.setMode(300 * scaler, 400 * scaler, 12, true);
        camera.setQuality(125000 * 6, 80);
        camera.setKeyFrameInterval(12);

        //stage.addEventListener(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY, onStageVideoState);

        application = new FountainFamily(false);
        addChild(application);

        format = new TextFormat();
        format.align = TextFormatAlign.CENTER;
        format.bold = true;
        format.color = 0X0c323c;
        format.size = 20;

        activeVideoButton = generateButton("Enable video");
        activeVideoButton.addEventListener(MouseEvent.CLICK, clickListener);

        sizeVideoButton = generateButton("Bubble size video");
        sizeVideoButton.visible = false;

        //For the slider to control the bubble size
        sliderContainer = new Sprite;
        sliderContainer.graphics.beginFill(0x152023);
        sliderContainer.graphics.drawRect(0, 10, 170, 3);
        sliderContainer.graphics.endFill();
        sliderContainer.visible = false;


        slider = new Sprite;
        slider.graphics.beginFill(0x152023);
        slider.graphics.drawRect(0, 0, 7, 23);
        slider.graphics.endFill();
        slider.buttonMode = true;

        var scl : Number = 2;
        var separation: Number = 40;
        machineVideo = new Video(600 * scl, 960 * scl);
        machineVideo.x = 1080 + separation;
        addChild(machineVideo);

        talentVideo = new Video(600 * scl, 960 * scl);
        talentVideo.x = 1080 + 600 * (scl) + separation + 30;;
        addChild(talentVideo);
        talentVideo.attachCamera(camera);

        sliderContainer.addChild(slider);

        slider.addEventListener(MouseEvent.MOUSE_DOWN, slideEvent);

        function slideEvent(e : MouseEvent) : void {
            slider.startDrag(true, new Rectangle(0, 0, 163, 0));
            stage.addEventListener(MouseEvent.MOUSE_MOVE, onSliderDragged);
        }

        holder = new Sprite();
        holder.addChild(activeVideoButton);
        holder.addChild(sizeVideoButton);
        holder.addChild(sliderContainer);

        activeVideoButton.y = 0;
        sizeVideoButton.y = 50;
        sliderContainer.y = 110;

        holder.x = 50;
        holder.y = 50;

        videoContainer = new Sprite();
        videoContainer.visible = false;
        videoContainer.x = 100;
        videoContainer.y = 100;
        videoContainer.buttonMode = true;

        slider.x = 163 * 200 / 500;
        generateBubble(200);

        videoContainer.addEventListener(MouseEvent.MOUSE_DOWN, onDownEvent);
        stage.addEventListener(MouseEvent.MOUSE_UP, onUpEvent);

        addChild(videoContainer);
        addChild(holder);


        ownVideo.mask = _cameraMask;
    }

        private function onSliderDragged(e : MouseEvent) : void {
            var minSize:Number = 0;
            var maxSize:Number = 500;
            var size : uint = Math.floor(minSize + (maxSize - minSize) * slider.x / 163);
            generateBubble(size);
            _remoteStream.send("bubbleSize", String(size));
        }

        private function generateBubble(size : Number) : void {


            if(_cameraMask) while(_cameraMask.numChildren > 0) _cameraMask.removeChildAt(0);
            if(centerer) while(centerer.numChildren > 0) centerer.removeChildAt(0);
            if(videoContainer) while(videoContainer.numChildren > 0) videoContainer.removeChildAt(0);

            blobShape = null;
            blobStroke = null;
            ownVideo = null;
            centerer = null;
            _cameraMask = null;

            clearInterval(blobAnimation);

            if(size > 0) {
                ownVideo = new Video(size * 2, size * 2);
                ownVideo.smoothing = true;
                videoContainer.addChild(ownVideo);
                ownVideo.attachCamera(camera);
                ownVideo.cacheAsBitmap = true;

                blobShape = new BlobShape(size, 0xff0000, 1, 0xff0000, 0, 0 , NaN, 2, 1, false, 2);
                blobShape.x = size;
                blobShape.y = size;

                blobStroke = new BlobShape(size, 0x000000, 0, 0X666666, 1, 2, NaN, 2, 1, false, 2);
                blobStroke.x = size;
                blobStroke.y = size;

                _cameraMask = new Sprite();
                _cameraMask.addChild(blobShape);
                _cameraMask.cacheAsBitmap = true;

                centerer = new Sprite();
                centerer.addChild(ownVideo);
                centerer.addChild(_cameraMask);
                centerer.addChild(blobStroke);
                centerer.x = -size;
                centerer.y = -size;

                videoContainer.addChild(centerer);

                ownVideo.mask = _cameraMask;

                blobAnimation = setInterval(function ():void {
                    blobShape.rotation += 1.8;
                    blobStroke.rotation -= 1.5;
                }, 100);
            }
        }

        private function onDownEvent(e:MouseEvent):void {
            e.stopImmediatePropagation();
            e.stopPropagation();
            videoContainer.startDrag();
            stage.addEventListener(MouseEvent.MOUSE_MOVE, sendVideoPosition);
        }

        private function sendVideoPosition(e:MouseEvent):void {
            try {
                trace(String(videoContainer.x).concat(" ").concat(videoContainer.y));
                _remoteStream.send("videoPosition", String(videoContainer.x).concat(" ").concat(videoContainer.y));
            } catch (e) {

            }
        }

        private function onUpEvent(e:MouseEvent):void {

            slider.stopDrag();
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onSliderDragged);

            if (e.target == videoContainer) {
                e.stopImmediatePropagation();
                e.stopPropagation();
            }
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, sendVideoPosition);
            videoContainer.stopDrag();
        }

        private function generateButton(text:String):Sprite {

            var sprite:Sprite = new Sprite();

            var videoText:TextField = new TextField();
            videoText.textColor = 0Xffffff;
            videoText.text = text;
            videoText.width = 170;
            videoText.selectable = false;
            videoText.setTextFormat(format);
            videoText.y = 8;
            videoText.mouseEnabled = false;
            videoText.height = 30;
            sprite.addChild(videoText);

            changeButtonColor(0x152023, sprite);

            var ghost:Sprite = new Sprite();
            ghost.graphics.clear();
            ghost.graphics.beginFill(0X33000000);
            ghost.graphics.drawRect(0, 0, 170, 40);
            ghost.graphics.endFill();
            ghost.buttonMode = true;
            ghost.alpha = 0;
            sprite.addChild(ghost);

            return sprite;
        }

        private function onRemoteStreamConnection(e:NetStatusEvent):void {

            switch (e.info.code) {
                case "NetConnection.Connect.Success":
                    trace("Connection made to the remote stream");
                    _remoteStream = new NetStream(_remoteStreamConnection);

                    var metaSniffer:Object = new Object();
                    _remoteStream.client = metaSniffer; //stream is the NetStream instance
                    metaSniffer.onMetaData = function ():void {
                    };

                    _remoteStream.addEventListener(NetStatusEvent.NET_STATUS, checkStreamStatus);
                    _remoteStream.checkPolicyFile = true;
                    _remoteStream.attachCamera(camera);
                    //_remoteStream.attachAudio(mic);
                    _remoteStream.bufferTime = 0.1;

                    var h264Settings:H264VideoStreamSettings = new H264VideoStreamSettings();
                    h264Settings.setProfileLevel(H264Profile.BASELINE, H264Level.LEVEL_3_1)
                    _remoteStream.videoStreamSettings = h264Settings;

                    _metaData.codec = _remoteStream.videoStreamSettings.codec;
                    _metaData.profile = h264Settings.profile;
                    _metaData.level = h264Settings.level;
                    _metaData.fps = camera.fps;
                    _metaData.height = camera.height;
                    _metaData.width = camera.width;
                    _metaData.keyFrameInterval = camera.keyFrameInterval;

                    _remoteStream.send("@setDataFrame", "onMetaData", _metaData);

                    //Send the up status mouse for every asset of the screen
                    stage.addEventListener(MouseEvent.MOUSE_UP, function (e:MouseEvent):void {

                        //Up position on any part from the screen
                        try {
                            if (e.target != centerer && e.target != holder && e.target != videoContainer) _remoteStream.send("upPosition", String(stage.mouseX).concat(" ").concat(stage.mouseY));
                        } catch (ev:Error) {

                        }

                    });

                    //For the blob buttons (water, pour, back and ADA)
                    stage.addEventListener(MouseEvent.MOUSE_DOWN, function (e:MouseEvent):void {

                        try {
                            if (e.target != centerer && e.target != holder && e.target != videoContainer) _remoteStream.send("downPosition", String(stage.mouseX).concat(" ").concat(stage.mouseY));
                        } catch (ev:Error) {

                        }
                    });

                    //Up position on the fullscreen button video
                    sizeVideoButton.addEventListener(MouseEvent.CLICK, function (e:MouseEvent):void {
                        trace(sizeVideoButton.height);
                        try {
                            fullscreenSizeVideo = !fullscreenSizeVideo;
                            TextField(Sprite(e.currentTarget).getChildAt(0)).text = fullscreenSizeVideo ? "Set bubble size" : "Set fullscreen";
                            TextField(Sprite(e.currentTarget).getChildAt(0)).setTextFormat(format);
                            _remoteStream.send("videoSize", fullscreenSizeVideo ? "fullscreen" : "smallSize");
                        } catch (e) {

                        }
                    });

                    break;
            }
        }

        private function onMachineStreamStatus(e:NetStatusEvent):void {
            switch (e.info.code) {
                case "NetConnection.Connect.Success":
                    trace("Connection made to the machine stream");
                    _machineStream = new NetStream(_machineStreamConnection);
                    _machineStream.addEventListener(NetStatusEvent.NET_STATUS, checkStreamStatus);
                    _machineStream.checkPolicyFile = true;
                    machineVideo.attachNetStream(_machineStream);
                    _machineStream.play(configList.getString("streams/machine-stream-name/"));

                    var client : Object = new Object();

                    client.upPosition = function(data) : void {
                        var info : Array = data.split(" ");
                        TouchHandler.searchTouchObject(info[0], info[1], "CLICK");
                    }

                    client.downPosition = function(data) : void {
                        var info : Array = data.split(" ");
                        TouchHandler.searchTouchObject(info[0], info[1], "DOWN");
                    }

                    _machineStream.client = client;

                    break;
            }
        }

        private function checkStreamStatus(e:NetStatusEvent):void {
            switch (e.info.code) {
                case "NetStream.Play.StreamNotFound":
                    break;
                case "NetStream.Play.PublishNotify":
            }
        }

        private function clickListener(e:MouseEvent):void {

            try {
                FountainFamily.attractorInfo.delayBrand = 0;
                FountainFamily.attractorInfo.delayBrandADA = 0;
                FountainFamily.attractorInfo.delayHome = 0;
                FountainFamily.attractorInfo.delayHomeADA = 0;

                toggleVideo = !toggleVideo;
                toggleVideo ? _remoteStream.publish(configList.getString("streams/remote-stream-name/")) : _remoteStream.dispose();
                videoContainer.visible = toggleVideo;
                sizeVideoButton.visible = toggleVideo;
                sliderContainer.visible = toggleVideo;
                TextField(Sprite(e.currentTarget).getChildAt(0)).text = toggleVideo ? "Broadcasting" : "Enable video";
                TextField(Sprite(e.currentTarget).getChildAt(0)).setTextFormat(format);
                changeButtonColor(toggleVideo ? 0X990000 : 0x152023, activeVideoButton);

                if (toggleVideo) {
                    fullscreenSizeVideo = true;
                    TextField(sizeVideoButton.getChildAt(0)).text = "Set bubble size";
                    TextField(sizeVideoButton.getChildAt(0)).setTextFormat(format);
                }


            } catch (e) {


            }
        }

//        private function onStageVideoState(e):void {
//            if (e.availability == StageVideoAvailability.AVAILABLE) {
//
//                video = stage.stageVideos[0];
//                video.attachNetStream(_machineStream);
//                video.viewPort = new Rectangle(500, 0, 1080, 840);
//
//                //If the machine is already sending the data
//                try {
//                    _machineStream.play(configList.getString("streams/machine-stream-name/"));
//                } catch (e) {
//
//                }
//
//            } else {
//                //Should generate a default video for this case
//            }
//        }

        private function changeButtonColor(color:uint, asset:Sprite):void {
            asset.graphics.clear();
            asset.graphics.lineStyle(2, 0x152023, 1);
            asset.graphics.lineStyle(2, color, 1);

            var fillType:String = GradientType.LINEAR;
            var colors:Array = [0xffffff, 0xebebeb];
            var alphas:Array = [1, 1];
            var ratios:Array = [0x00, 0xFF];
            var matr:Matrix = new Matrix();
            matr.createGradientBox(170, 40, Math.PI * 0.5, 0, 0);
            asset.graphics.beginGradientFill(fillType, colors, alphas, ratios, matr);

            //asset.graphics.drawRect(0, 0, 200, 60);
            asset.graphics.drawRoundRect(0, 0, 170, 40, 20);
            asset.graphics.endFill();
        }

        override protected function addDynamicAssetsFirstPass():void {
            addDynamicAsset("config.xml", NAME_XML_CONFIG);
        }

        override protected function addDynamicAssetsSecondPass():void {

            configList = StringList.getList("config_xml_internal");
            configList.setFromXML(getAssetLibrary().getXML(NAME_XML_CONFIG));

            //Connection to the remote stream to publish on the server
            _remoteStreamConnection = new NetConnection();
            _remoteStreamConnection.addEventListener(NetStatusEvent.NET_STATUS, onRemoteStreamConnection);
            _remoteStreamConnection.connect(configList.getString("streams/remote-stream-url/"));

            //Connection to the machine stream to see the video stream from the users.
            _machineStreamConnection = new NetConnection();
            _machineStreamConnection.addEventListener(NetStatusEvent.NET_STATUS, onMachineStreamStatus);
            _machineStreamConnection.connect(configList.getString("streams/machine-stream-url/"));


        }

        override protected function getDynamicAssetSecondPassPhaseSize():Number {
            return 0.8;
        }

    }

}
