package com.firstborn.pepsi.display.gpu.common {
	import starling.display.Sprite;
	import starling.textures.Texture;

	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.data.AnimationDefinition;
	import com.zehfernando.display.starling.AnimatedImage;
	import com.zehfernando.signals.SimpleSignal;
	import com.zehfernando.utils.MathUtils;
	import com.zehfernando.utils.console.error;
	import com.zehfernando.utils.console.warn;

	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.ImageDecodingPolicy;
	import flash.system.LoaderContext;
	import flash.system.System;
	import flash.utils.ByteArray;

	/**
	 * @author zeh fernando
	 */
	public class AnimationPlayer extends Sprite {

		// Properties
		private var previousAnimatedImage:int;
		private var currentAnimatedImage:int;
		private var isLoadingSomething:Boolean;
		private var willLoopCurrentAnimation:Boolean;
		private var mustPauseAnimation:Boolean;

		private var _alignX:Number;										// -1 (left) to 1 (right)
		private var _alignY:Number;										// -1 (top) to 1 (bottom)
		private var _color:uint;
		private var _hasColor:Boolean;
		private var _cropMargin:Number;
		private var _scale:Number;

		// Instances
		private var texturesDisposable:Vector.<Boolean>;
		private var textures:Vector.<Texture>;
		private var animatedImages:Vector.<AnimatedImage>;
		private var urlLoaders:Vector.<URLLoader>;						// For ATF loading
		private var imgLoaders:Vector.<Loader>;							// For PNG/JPG loading
		private var animationDefinitions:Vector.<AnimationDefinition>;

		private var _onFinishedPlaying:SimpleSignal;

		private static var imageLoaderContext:LoaderContext;


		// ================================================================================================================
		// STATIC CONSTRUCTOR ---------------------------------------------------------------------------------------------

		{
			imageLoaderContext = new LoaderContext();
			imageLoaderContext.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
			imageLoaderContext.allowCodeImport = false;
		}


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function AnimationPlayer() {
			texturesDisposable = new Vector.<Boolean>();
			textures = new Vector.<Texture>();
			animatedImages = new Vector.<AnimatedImage>();
			urlLoaders = new Vector.<URLLoader>();
			imgLoaders = new Vector.<Loader>();
			animationDefinitions = new Vector.<AnimationDefinition>();
			_onFinishedPlaying = new SimpleSignal();

			_alignX = 0; // Center
			_alignY = 0;
			_cropMargin = 0;
			_scale = 1;

			_hasColor = false;
			_color = 0x000000;

			previousAnimatedImage = -1;
			currentAnimatedImage = -1;
			isLoadingSomething = false;

			applyScale();
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function addAnimation(__id:String):void {
			var animationDef:AnimationDefinition = getAnimationDefinition(__id);
			if (animationDef != null) {
				animationDefinitions.push(animationDef);

				if (FountainFamily.textureLibrary.hasLoadedTexture(animationDef.image)) {
					// Texture already exists, uses it instead!
					imgLoaders.push(null);
					urlLoaders.push(null);
					texturesDisposable.push(false);
					textures.push(null);
					animatedImages.push(null);

//					log("Playing pre-loaded animation: " + __id);

					createImageFromTexture(textures.length-1, FountainFamily.textureLibrary.getLoadedTexture(animationDef.image));
				} else {
					// Doesn't exist, must load
//					log("Loading animation: " + __id);

					var extension:String = animationDef.image.substr(-3, 3);

					if (extension == "atf") {
						// From ATF data
						var urlLoader:URLLoader = new URLLoader();
						urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
						urlLoader.addEventListener(Event.COMPLETE, onLoaderComplete);
						urlLoaders.push(urlLoader);
						imgLoaders.push(null);
					} else {
						// From normal image
						var imgLoader:Loader = new Loader();
						imgLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
						urlLoaders.push(null);
						imgLoaders.push(imgLoader);
					}

					texturesDisposable.push(true);
					textures.push(null);
					animatedImages.push(null);

					if (!isLoadingSomething) {
						//log("loading next image");
						loadNextImage();
					}
				}
			}
		}

		private function hasAnimation(__id:String):Boolean {
			for (var i:int = 0; i < animationDefinitions.length; i++) {
				if (animationDefinitions[i].id == __id) return true;
			}
			return false;
		}

		private function getAnimationIndex(__id:String):int {
			for (var i:int = 0; i < animationDefinitions.length; i++) {
				if (animationDefinitions[i].id == __id) return i;
			}
			error("Tried to read index of an animation [" + __id + "] that doesn't exist!");
			return -1;
		}

		private function getAnimationDefinition(__id:String):AnimationDefinition {
			return AnimationDefinition.getAnimationDefinition(__id, FountainFamily.animationDefinitions);
		}

		private function createImage(__index:int):void {
			var animatedTexture:Texture;

			if (urlLoaders[__index] != null) {
				// From URLLoader: ATF data
				animatedTexture = Texture.fromAtfData(urlLoaders[__index].data as ByteArray, 1, false);
				createImageFromTexture(__index, animatedTexture, true);
			} else if (imgLoaders[__index] != null) {
				// From Loader: normal image
				var bitmap:Bitmap = imgLoaders[__index].content as Bitmap;
				if (bitmap != null) {
					animatedTexture = Texture.fromBitmapData(bitmap.bitmapData, false, true, 1, animationDefinitions[__index].format);
				} else {
					warn("Loaded data is not an image");
					animatedTexture = Texture.empty(2, 2);
				}
				bitmap = null;
				createImageFromTexture(__index, animatedTexture, true);
			} else {
				warn("Tried to create an image with an index without loaders!");
			}
		}

		private function createImageFromTexture(__index:int, __texture:Texture, __canDispose:Boolean = false):void {
			if (__index >= animationDefinitions.length > 0) {
				// Animation definition doesn't exist - it probably means the player was disposed of DURING loading of the bitmap
				if (__canDispose) __texture.dispose();
				warn("Tried creating an image from a texture that has been disposed of!");
				return;
			}
			var animationDef:AnimationDefinition = animationDefinitions[__index];

			var animatedImage:AnimatedImage = new AnimatedImage(__texture, animationDef.frameWidth, animationDef.frameHeight, animationDef.frames, animationDef.fps * FountainFamily.timeScale);

			animatedImage.smoothing = animationDef.smoothing;
			animatedImage.visible = false;
			animatedImage.x = -animationDef.frameWidth * 0.5;
			animatedImage.y = -animationDef.frameHeight * 0.5;
			animatedImage.scaleX = animatedImage.scaleY = animationDef.scale;
			animatedImage.onFinished.add(onFinishedPlayingImage);
			if (_hasColor) animatedImage.color = _color;
			addChild(animatedImage);

			animatedImages[__index] = animatedImage;
			textures[__index] = __texture;

			applyAlignment(__index);
			applyCropMargin(__index);

			if (__index == currentAnimatedImage) {
				playAnimationInternal(__index);
			}
		}

		private function removeLoaders(__index:uint):void {
			if (urlLoaders[__index] != null) {
				urlLoaders[__index].removeEventListener(Event.COMPLETE, onLoaderComplete);
				urlLoaders[__index].close();
				urlLoaders[__index] = null;
			}
			if (imgLoaders[__index] != null) {
				imgLoaders[__index].contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoaderComplete);

				// Close loading Loaders
				try {
					imgLoaders[__index].close();
				} catch(__e:Error) {
				}

				// Dispatch of images
				try {
					(imgLoaders[__index].content as Bitmap).bitmapData.dispose();
					(imgLoaders[__index].content as Bitmap).bitmapData = null;
				} catch(__e:Error) {
				}

				// Basic unload
				imgLoaders[__index].unload();
				imgLoaders[__index] = null;
			}
		}

		private function removeCurrentAnimation():void {
			// Removes the current animation, if any
			if (previousAnimatedImage >= 0) {
				animatedImages[previousAnimatedImage].visible = false;
				animatedImages[previousAnimatedImage].stop();
				previousAnimatedImage = -1;
			}
		}

		private function playAnimationInternal(__index:int, __fromStart:Boolean = false):void {
			if (__index != previousAnimatedImage && previousAnimatedImage > -1) {
				// An old image exists, hide it
				removeCurrentAnimation();
			}

			if (__index != currentAnimatedImage && currentAnimatedImage > -1) {
				if (animatedImages[__index] != null) {
					// New image exists, so just hide the current one
					animatedImages[currentAnimatedImage].visible = false;
					animatedImages[currentAnimatedImage].stop();
				} else {
					// New image doesn't exist, so keep the current one as old for now (until the new one loads; just about one frame)
					previousAnimatedImage = currentAnimatedImage;
				}
			}

			currentAnimatedImage = __index;
			if (animatedImages[currentAnimatedImage] != null) {
				if (__fromStart) animatedImages[currentAnimatedImage].stop();
				animatedImages[currentAnimatedImage].loop = willLoopCurrentAnimation;
				animatedImages[currentAnimatedImage].visible = true;
				if (mustPauseAnimation) {
					mustPauseAnimation = false;
				} else {
					animatedImages[currentAnimatedImage].play();
				}
			}
		}

		private function loadNextImage():void {
			for (var i:int = 0; i < urlLoaders.length; i++) {
				if (urlLoaders[i] != null) {
					isLoadingSomething = true;
//					log("Loading new url @ " + animationDefinitions[i].image);
					urlLoaders[i].load(new URLRequest(animationDefinitions[i].image));
					break;
				}
				if (imgLoaders[i] != null) {
					isLoadingSomething = true;
//					log("Loading new img @ " + animationDefinitions[i].image);
					imgLoaders[i].load(new URLRequest(animationDefinitions[i].image), imageLoaderContext);
					break;
				}
			}
		}

		private function applyAlignment(__index:int = -1):void {
			// Re-align the image based on alignX/alignY

			var animationDef:AnimationDefinition;
			for (var i:int = 0; i < animationDefinitions.length; i++) {
				if ((__index < 0 || i == __index) && animatedImages[i] != null) {
					animationDef = animationDefinitions[i];
					animatedImages[i].x = MathUtils.map(alignX, -1, 1, 0, -animationDef.frameWidth, true) * animationDef.scale;
					animatedImages[i].y = MathUtils.map(alignY, -1, 1, 0, -animationDef.frameHeight, true) * animationDef.scale;
				}
			}
		}

		private function applyCropMargin(__index:int = -1):void {
			// Applies the crop margin to animated images
			for (var i:int = 0; i < animatedImages.length; i++) {
				if ((__index < 0 || i == __index) && animatedImages[i] != null) {
					animatedImages[i].cropMargin = _cropMargin;
				}
			}
		}

		private function applyScale():void {
			// Apply the current color to all animated images
			scaleX = scaleY = _scale;
		}

		private function applyColor():void {
			// Apply the current color to all animated images
			for (var i:int = 0; i < animatedImages.length; i++) {
				if (_hasColor && animatedImages[i] != null) animatedImages[i].color = _color;
			}
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		private function onLoaderComplete(__e:Event):void {
			isLoadingSomething = false;

			var urlLoader:URLLoader = __e.currentTarget as URLLoader;
			var imgLoaderInfo:LoaderInfo = __e.currentTarget as LoaderInfo;
			var idx:int;

//			log("Completed loading");

			idx = urlLoaders.indexOf(urlLoader);
			if (urlLoader != null && idx >= 0) {
				// URL Loader
				createImage(idx);
				removeLoaders(idx);
			} else {
				idx = imgLoaderInfo == null ? -1 : imgLoaders.indexOf(imgLoaderInfo.loader);
				if (idx >= 0) {
					// Loader
					createImage(idx);
					removeLoaders(idx);
				} else {
					warn("Loader completed but not found!");
				}
			}

			System.gc();

			loadNextImage();
		}

		private function onFinishedPlayingImage(__animatedImage:AnimatedImage):void {
			_onFinishedPlaying.dispatch(this);
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function playAnimation(__id:String, __loop:Boolean, __fromStart:Boolean = false):void {
			if (__id.length == 0 || __id == null) {
				// Just remove the current animation
				removeCurrentAnimation();
				return;
			}

			if (!hasAnimation(__id)) {
				// Must load first
				addAnimation(__id);
			}

			var i:int = getAnimationIndex(__id);
			if (i >= 0) {
				// Play
				willLoopCurrentAnimation = __loop;
				playAnimationInternal(i, __fromStart);
			}
		}

		public function pauseAnimation():void {
			if (animationDefinitions.length > 0 && animatedImages[currentAnimatedImage] != null) {
				animatedImages[currentAnimatedImage].pause();
				mustPauseAnimation = false;
			} else {
				mustPauseAnimation = true;
			}
		}

		override public function dispose():void {
			_onFinishedPlaying.removeAll();
			_onFinishedPlaying = null;

			while (animationDefinitions.length > 0) {

				// Removes image
				if (animatedImages[0] != null) {
					removeChild(animatedImages[0]);
					animatedImages[0].dispose();
				}
				animatedImages.splice(0, 1);

				// Removes texture, disposing if allowed
				if (textures[0] != null && texturesDisposable[0]) textures[0].dispose();
				textures.splice(0, 1);
				texturesDisposable.splice(0, 1);

				// Removes loaders
				if (urlLoaders[0] != null || imgLoaders[0] != null) removeLoaders(0);
				urlLoaders.splice(0, 1);
				imgLoaders.splice(0, 1);

				// Finally, remove the animation definition itself
				animationDefinitions.splice(0, 1);
			}

			texturesDisposable = null;
			textures = null;
			animatedImages = null;
			urlLoaders = null;
			imgLoaders = null;
			animationDefinitions = null;

			super.dispose();
		}

		public function getCurrentAnimatedImage():AnimatedImage {
			return animatedImages[currentAnimatedImage];
		}

		public function getCurrentAnimationDefinition():AnimationDefinition {
			return animationDefinitions[currentAnimatedImage];
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		override public function get width():Number {
			if (animationDefinitions.length > 0) return animationDefinitions[0].frameWidth * animationDefinitions[0].scale;
			return 0;
		}

		override public function get height():Number {
			if (animationDefinitions.length > 0) return animationDefinitions[0].frameHeight * animationDefinitions[0].scale;
			return 0;
		}

		public function get alignX():Number {
			return _alignX;
		}
		public function set alignX(__value:Number):void {
			if (_alignX != __value) {
				_alignX = __value;
				applyAlignment();
			}
		}

		public function get alignY():Number {
			return _alignY;
		}
		public function set alignY(__value:Number):void {
			if (_alignY != __value) {
				_alignY = __value;
				applyAlignment();
			}
		}

		public function get cropMargin():Number {
			return _cropMargin;
		}
		public function set cropMargin(__value:Number):void {
			if (_cropMargin != __value) {
				_cropMargin = __value;
				applyCropMargin();
			}
		}
		public function get onFinishedPlaying():SimpleSignal {
			return _onFinishedPlaying;
		}

		public function get color():uint {
			return _color;
		}
		public function set color(__value:uint):void {
			if (_color != __value) {
				_color = __value;
				_hasColor = true;
				applyColor();
			}
		}

		public function get scale():Number {
			return _scale;
		}
		public function set scale(__value:Number):void {
			if (_scale != __value) {
				_scale = __value;
				applyScale();
			}
		}
	}
}
