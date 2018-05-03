package com.firstborn.pepsi.display.gpu.common {
	import com.firstborn.pepsi.data.MastheadInfo;
	import com.zehfernando.display.containers.StageVideoSprite;
	import com.zehfernando.display.shapes.Box;
	import com.zehfernando.utils.DelayedCalls;

	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	/**
	 * @author zeh fernando
	 */
	public class MastheadView extends Sprite {

		// Properties
		private var _width:Number;
		private var _height:Number;
		private var _visibility:Number;

		private var currentVideo:int;
		private var isPlaying:Boolean;

		// Instances
		private var mastheadInfo:MastheadInfo;
		private var videoPlayer:StageVideoSprite;
		private var coverBox:Box;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function MastheadView(__width:Number, __height:Number, __mastheadInfo:MastheadInfo) {
			_width = __width;
			_height = __height;
			mastheadInfo = __mastheadInfo;
			currentVideo = -1;
			isPlaying = false;

			videoPlayer = new StageVideoSprite(_width, _height);
			//videoPlayer.canUseStageVideo = false;
			videoPlayer.loop = false;
			videoPlayer.addEventListener(StageVideoSprite.EVENT_PLAY_FINISH, onFinishedPlayingVideo);
			addChild(videoPlayer);

			coverBox = new Box(__width, __height, 0xffffff);
			addChild(coverBox);

			_visibility = 1;

			loadNextVideo();
			redrawVisibility();
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function loadNextVideo():void {
			currentVideo = currentVideo < 0 ? 0 : ((currentVideo + 1) % mastheadInfo.videos.length);
			videoPlayer.autoPlay = isPlaying;
			videoPlayer.load(mastheadInfo.videos[currentVideo]);
		}

		private function redrawVisibility():void {
			coverBox.alpha = 1 - _visibility;
			coverBox.visible = _visibility < 1;
			visible = _visibility > 0;
			videoPlayer.visible = _visibility > 0;
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		private function onFinishedPlayingVideo(__e:Event):void {
			videoPlayer.unload();

			if (currentVideo == mastheadInfo.videos.length - 1) {
				// Last video, wait for the cycle time
				DelayedCalls.add(mastheadInfo.timeBetweenCycles * 1000, loadNextVideo);
			} else {
				// Between videos, wait for the video time
				DelayedCalls.add(mastheadInfo.timeBetweenVideos * 1000, loadNextVideo);
			}
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function play():void {
			if (!isPlaying) {
				videoPlayer.playVideo();
				isPlaying = true;
			}
		}

		public function pause():void {
			if (isPlaying) {
				videoPlayer.pauseVideo();
				isPlaying = false;
			}
		}

		public function stop():void {
			if (isPlaying) {
				isPlaying = false;
			}
			videoPlayer.stopVideo();
		}

		public function dispose():void {
			stop();

			videoPlayer.dispose();
			videoPlayer.removeEventListener(StageVideoSprite.EVENT_PLAY_FINISH, onFinishedPlayingVideo);
			removeChild(videoPlayer);
			videoPlayer = null;

			mastheadInfo = null;
		}

		public function getFrame():BitmapData {
			return videoPlayer.getFrame();
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function get visibility():Number {
			return _visibility;
		}
		public function set visibility(__value:Number):void {
			if (_visibility != __value) {
				_visibility = __value;
				redrawVisibility();
			}
		}

		public function get canUseStageVideo():Boolean {
			return videoPlayer.canUseStageVideo;
		}
		public function set canUseStageVideo(__value:Boolean):void {
			videoPlayer.canUseStageVideo = __value;
		}
	}
}
