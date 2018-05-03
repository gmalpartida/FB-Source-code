package com.firstborn.pepsi.display.gpu.brand.liquid {

import flash.display.BlendMode;

import starling.display.BlendMode;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;

	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.data.inventory.Beverage;
	import com.firstborn.pepsi.display.gpu.common.TextureLibrary;
	import com.zehfernando.display.starling.VideoImage;
	import com.zehfernando.utils.MathUtils;

	import flash.geom.Rectangle;

	/**
	 * @author zeh fernando
	 */
	public class LiquidVideos extends Sprite {

		// Constants
		private static const SPEED_POUR:Number = 0.25;							// % of total pour to be done per second; this is not very precise but it's close and better than a simple frame-based ease

//		private static const TARGET_WIDTH:int = 1080;
//		private static const TARGET_HEIGHT:int = 976;

		// Properties
		private var liquidOffsetX:Number;
		private var liquidOffsetY:Number;
		private var liquidPouredOffsetY:Number;

		// Instances
		private var videoPositionRect:Rectangle;
		private var isWaitingToPlayQueuedVideo:Boolean;
		private var framesToWaitToPlayQueuedVideo:int;

		private var videoContainer:Sprite;
		private var videoIntro:VideoImage;
		private var videoIdle:VideoImage;

		private var currentVideo:VideoImage;
		private var queuedVideo:VideoImage;

		private var background:Image;
		private var noiseImage:Image;

		private var pourAmountCurrent:Number;
		private var pourAmountTarget:Number;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function LiquidVideos(__left:Number, __top:Number, __right:Number, __bottom:Number, __beverage:Beverage, __liquidOffsetX:Number, __liquidOffsetY:Number, __liquidPouredOffsetY:Number) {
			isWaitingToPlayQueuedVideo = false;
			pourAmountCurrent = 0;
			pourAmountTarget = 0;
			liquidOffsetX = __liquidOffsetX;
			liquidOffsetY = __liquidOffsetY;
			liquidPouredOffsetY = __liquidPouredOffsetY;

			videoPositionRect = new Rectangle();
			videoPositionRect.left = Math.round(__left);
			videoPositionRect.top = Math.round(__top);
			videoPositionRect.right = Math.round(__right);
			videoPositionRect.bottom = Math.round(__bottom);

			background = new Image(FountainFamily.textureLibrary.getLoadedTexture(__beverage.getDesign().imageLiquidBackground));
			background.blendMode = starling.display.BlendMode.NONE;
			background.width = FountainFamily.platform.width;
			background.height = FountainFamily.platform.heightMinusMasthead;
			background.smoothing = FountainFamily.platform.getTextureProfile(TextureLibrary.TEXTURE_ID_BRAND_LIQUID_BACKGROUND).smoothing;
			addChild(background);

			noiseImage = new Image(FountainFamily.textureLibrary.getNoiseTexture());
			noiseImage.width = FountainFamily.platform.width;
			noiseImage.height = FountainFamily.platform.heightMinusMasthead;
			noiseImage.smoothing = FountainFamily.platform.getTextureProfile(TextureLibrary.TEXTURE_ID_GENERIC_NOISE).smoothing;
			// Adjust dimensions so the noise is always 1:1
			var tileSide:int = noiseImage.texture.width;
			var tw:Number = noiseImage.width / tileSide;
			var th:Number = noiseImage.height / tileSide;
			noiseImage.setTexCoordsTo(0, 0, 0);
			noiseImage.setTexCoordsTo(1, tw, 0);
			noiseImage.setTexCoordsTo(2, 0, th);
			noiseImage.setTexCoordsTo(3, tw, th);
			noiseImage.alpha = __beverage.getDesign().noiseLiquidBackground;
			noiseImage.visible = __beverage.getDesign().noiseLiquidBackground > 0;
			addChild(noiseImage);

			videoContainer = new Sprite();
			videoContainer.x = liquidOffsetX;
			addChild(videoContainer);

			videoIntro = new VideoImage(__beverage.getDesign().videoLiquidIntro, false, true);
			videoIntro.onSeekComplete.add(onVideoSeekComplete);
			videoIntro.onFinishedPlaying.add(onVideoFinishedPlayIdle);
			videoIntro.onLoaded.add(onVideoLoadedLoadIdle);
			videoIntro.x = videoPositionRect.x;
			videoIntro.y = videoPositionRect.y;
			videoIntro.width = videoPositionRect.width;
			videoIntro.height = videoPositionRect.height;
			videoIntro.visibility = 0;
			videoIntro.doNotDisposeOfNetStream = true;
            videoContainer.addChild(videoIntro);

            videoIdle = new VideoImage(__beverage.getDesign().videoLiquidIdle, true, true);
			videoIdle.onSeekComplete.add(onVideoSeekComplete);
			videoIdle.x = videoPositionRect.x;
			videoIdle.y = videoPositionRect.y;
			videoIdle.width = videoPositionRect.width;
			videoIdle.height = videoPositionRect.height;
			videoIdle.visibility = 0;
			videoIdle.doNotDisposeOfNetStream = true;
            videoContainer.addChild(videoIdle);

			queueVideo(videoIntro, 0);

			if (FountainFamily.timeScale > 1) videoIdle.load();

			addEventListener(Event.ENTER_FRAME, onEnterFramePlayQueuedVideo);
			FountainFamily.looper.onTickedOncePerVisualFrame.add(update);
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function queueVideo(__video:VideoImage, __position:Number = 0):void {
			// Will play the selected video as soon as the seek to the position is complete
			queuedVideo = __video;
			if (!queuedVideo.isLoaded) queuedVideo.load();
			queuedVideo.seek(__position);
		}

		private function playVideo(__video:VideoImage):void {
			// Plays the video immediately
			if (currentVideo != null) currentVideo.visibility = 0;
			currentVideo = __video;
			currentVideo.resume();
			currentVideo.visibility = 1;
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		private function onVideoSeekComplete(__video:VideoImage):void {
			if (__video == queuedVideo) {
				//if (__video == videoIntro) log("Seek complete for queued intro video");

				// Has to wait a few frames until actually being able to show it - kinda shitty but necessary
				isWaitingToPlayQueuedVideo = true;
				framesToWaitToPlayQueuedVideo = 4;

				// But actually forces it to start playing invisibly
				queuedVideo.resume();
			}
		}

		private function onEnterFramePlayQueuedVideo(__e:Event):void {
			if (isWaitingToPlayQueuedVideo) {
				framesToWaitToPlayQueuedVideo--;
				queuedVideo.resume();
				if (framesToWaitToPlayQueuedVideo <= 0) {
					isWaitingToPlayQueuedVideo = false;
					playVideo(queuedVideo);
					queuedVideo = null;
				}
			}
		}

		private function update(__currentTimeSeconds:Number, __tickDeltaTimeSeconds:Number, __currentTick:int):void {
			// Update the liquid position depending on how much has been "poured"

			// Update value
			var pourAmount:Number = __tickDeltaTimeSeconds * SPEED_POUR;

			// Update visuals
			pourAmountCurrent += (pourAmountTarget - pourAmountCurrent) * pourAmount;
			videoContainer.y = MathUtils.map(pourAmountCurrent, 0, 1, liquidOffsetY, liquidPouredOffsetY);
		}

		private function onVideoFinishedPlayIdle(__video:VideoImage):void {
			//queueVideo(videoIdle, 0);
			playVideo(videoIdle);
		}

		private function onVideoLoadedLoadIdle(__video:VideoImage):void {
			if (!videoIdle.isLoaded) {
				videoIdle.load();
			}
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function startPour():void {
			pourAmountTarget = 1;
			//log("start pour!");
		}

		public function stopPour():void {
			pourAmountTarget = 0;
			//queueVideo(videoRefill, (1-getPourPosition()) * videoRefill.duration);
		}

		public function setClipRect(__rect:Rectangle):void {
			// Set the rectangle that the liquid videos have to be clipped at
			//background.setClipRect(__rect);
			//videoContainer.clipRect = __rect;

			clipRect = __rect;
			//if (videoIntro != null) videoIntro.setClipRect(__rect);
//			videoIdle.setClipRect(__rect);
		}

		override public function dispose():void {
			removeEventListener(Event.ENTER_FRAME, onEnterFramePlayQueuedVideo);
			FountainFamily.looper.onTickedOncePerVisualFrame.remove(update);

			videoContainer.removeChild(videoIntro);
			FountainFamily.garbageCan.put(videoIntro.netStream);
			videoIntro.dispose();
			videoIntro = null;

			videoContainer.removeChild(videoIdle);
			FountainFamily.garbageCan.put(videoIdle.netStream);
			videoIdle.dispose();
			videoIdle = null;

			removeChild(background);
			background.dispose();
			background = null;

			removeChild(noiseImage);
			noiseImage.dispose();
			noiseImage= null;

			currentVideo = null;
			queuedVideo = null;

			super.dispose();
		}
	}
}
