package com.firstborn.pepsi.display.gpu.common.components {
import com.firstborn.pepsi.application.FountainFamily;
import com.firstborn.pepsi.display.gpu.common.blobs.MultiBlobBitmap;
import com.firstborn.pepsi.display.gpu.common.components.BlobButton;
import com.firstborn.pepsi.display.gpu.common.components.BlobButton;

import starling.core.Starling;
	import starling.display.BlendMode;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.textures.Texture;

	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.assets.FontLibrary;
	import com.firstborn.pepsi.display.gpu.common.BlobButtonStyle;
	import com.firstborn.pepsi.display.gpu.common.TextBitmap;
	import com.firstborn.pepsi.display.gpu.common.blobs.MultiBlobBitmap;
	import com.firstborn.pepsi.display.gpu.common.blobs.TiledBitmapData;
	import com.firstborn.pepsi.events.TouchHandler;
	import com.zehfernando.controllers.focus.FocusController;
	import com.zehfernando.controllers.focus.IFocusable;
	import com.zehfernando.data.types.Color;
	import com.zehfernando.signals.SimpleSignal;
	import com.zehfernando.transitions.Equations;
	import com.zehfernando.transitions.ZTween;
	import com.zehfernando.utils.MathUtils;
	import com.zehfernando.utils.RandomGenerator;
	import com.zehfernando.utils.VectorUtils;

	import flash.geom.Rectangle;
	import flash.utils.ByteArray;

	/**
	 * @author zeh fernando
	 */
	public class BlobButton extends Sprite implements IFocusable {

		// Constants
		public static const COLOR_TEXT_NEUTRAL:uint = 0xa8b3ba; // 70% of 0x83939d;
		public static const COLOR_ICON_NEUTRAL:uint = 0xd1d6db; // 70% of 0x83939d;

		public static const NOISE_RADIUS_SCALE:Number = 1; // Applied on top of BlobShape.NOISE_RADIUS_SCALE_STANDARD

		// Styles
		public static const STYLE_POUR_TOWER:String = "style-pour-tower";
		public static const STYLE_POUR_TOWER_ADA:String = "style-pour-tower-ada";
		public static const STYLE_POUR_BRIDGE:String = "style-pour-bridge";
		public static const STYLE_POUR_BRIDGE_ADA:String = "style-pour-bridge-ada";
		public static const STYLE_NEUTRAL_MEDIUM:String = "style-neutral-medium";
		public static const STYLE_NEUTRAL_SMALL:String = "style-neutral-small";
		public static const STYLE_BACK_SMALL:String = "style-back-small";
		public static const STYLE_BACK_TINY:String = "style-back-tiny";

		// Old enums for sizes
		public static const STROKE_WIDTH_SMALL_THIN:Number = 1;

		private static const BLOB_TEXTURE_MARGIN:int = 1;							// Margin per image for proper antialias
		private static const MARGIN_TEXT_BOTTOM:Number = 12;

		private static const TIME_ANIMATE_PRESS:Number = 0.5;
		private static const TIME_ANIMATE_RELEASE:Number = 1.2;
		private static const TIME_ANIMATE_SELECTION:Number = 0.4;

		// For speed
		private static const PI_2:Number = Math.PI * 2;

		//Save all the instances to change the language.
		public static var instances : Array = new Array();
		private static var imageCaptionVisible:uint = 0;

		// Properties
		private var _radius:Number;
		private var _visibility:Number;
		private var _enabled:Number;
		private var _pressed:Number;
		private var _selected:Number;
		private var _keyboardFocused:Number;
		private var _wasClickSimulated:Boolean;
		private var captionOutside:Boolean;
		private var iconColor:uint;
		private var iconScale:Number;
		private var drawFocusImage:Boolean;

		private var focusImageIndex:int;
		private var selectedImageIndex:int;
		private var isStarted:Boolean;

		// Instances
		private var texture:Texture;
		private var textureBitmap:MultiBlobBitmap;

        private var imageCashless : Image;
        private var textureCashless : Texture;

		private var imageCaption: Vector.<Image>;
		private var imageIcon:Image;

		private var layerImages:Vector.<Image>;
		private var layerImagesBlendModes:Vector.<String>;
		private var layerImagesSpeeds:Vector.<Number>;
		private var layerImagesScales:Vector.<Number>;
		private var layerImagesColors:Vector.<uint>;
		private var layerImagesOpacities:Vector.<Number>;

		private var touchHandler:TouchHandler;

		private var _onTapped:SimpleSignal;
		private var _onPressed:SimpleSignal;
		private var _onReleased:SimpleSignal;
		private var _onPressCanceled:SimpleSignal;

        private var _usesTimer : Boolean;

        private var speedDirection : Boolean;
        private var w : Number;
        private var shapeSeed :int;
        private var _timerAngle : Number = 0;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function BlobButton(__radius:Number, __caption: Vector.<String>, __blobLayers:Array = null, __captionColor:uint = 0x000000, __captionEmphasisColor:uint = 0x000000, __captionSize:Number = 20, __captionEmphasisSize:Number = 20, __captionBold:Boolean = false, __captionEmphasisBold:Boolean = false, __captionAlpha:Number = 1, __captionEmphasisAlpha:Number = 1, __captionTracking:Number = 20, __captionEmphasisTracking:Number = 20, __captionLeading:Number = 0, __captionOutside:Boolean = false, __captionAlignment:String = null, __atfIcon:ByteArray = null, __iconColor:uint = 0x000000, __iconScale:Number = 1, __drawFocusImage:Boolean = true, __usesTimer : Boolean = false, __timerColor : uint = 0X00ff00, __isADA : Boolean = false) {

            _usesTimer = __usesTimer;
			_radius = __radius;
			_visibility = 1;
			_enabled = 1;
			_pressed = 0;
			_selected = 0;
			_keyboardFocused = 0;
			isStarted = false;
			drawFocusImage = __drawFocusImage;

			captionOutside = __captionOutside;
			iconColor = __iconColor;
			iconScale = __iconScale;

			_onTapped = new SimpleSignal();
			_onPressed = new SimpleSignal();
			_onReleased = new SimpleSignal();
			_onPressCanceled = new SimpleSignal();

			w = Math.ceil(__radius * 2 + BLOB_TEXTURE_MARGIN * 2);
			var i:int;

			var blobLayers:Vector.<BlobButtonLayer> = new Vector.<BlobButtonLayer>();
			for each (var blobLayer:BlobButtonLayer in __blobLayers) blobLayers.push(blobLayer);

			// Count the number of layers needed
			var numLayers:int = 0;
			if (drawFocusImage) numLayers++;
			numLayers++; // Selection solid
			for (i = 0; i < blobLayers.length; i++) {
				if (blobLayers[i].alphaSolid > 0) numLayers++;
				if (blobLayers[i].alphaStroke > 0) numLayers++;
                if(_usesTimer) numLayers ++;
			}

			// Create textures for blobs
		    speedDirection = RandomGenerator.getBoolean();
			layerImages = new Vector.<Image>();
			layerImagesBlendModes = new Vector.<String>();
			layerImagesSpeeds = new Vector.<Number>();
			layerImagesScales = new Vector.<Number>();
			layerImagesColors = new Vector.<uint>();
			layerImagesOpacities = new Vector.<Number>();
			textureBitmap = new MultiBlobBitmap(FountainFamily.platform.gpuTextureMaximumDimensions, w, numLayers, BLOB_TEXTURE_MARGIN);

			shapeSeed = RandomGenerator.getInIntegerRange(0, 999);

			// Creates all layers
			for (i = 0; i < blobLayers.length; i++) {
				if (blobLayers[i].alphaSolid > 0) {
					// New solid
					textureBitmap.addBlob(0xffffffff, 1, 0x000000, 0, 0, NOISE_RADIUS_SCALE, false, null, false, false, i + shapeSeed);
					layerImagesSpeeds.push((speedDirection ? 1 : -1) * (RandomGenerator.getFromSeed(i + shapeSeed) * 10 + 8));
					layerImagesBlendModes.push(blobLayers[i].blendMode == null ? BlendMode.NORMAL : blobLayers[i].blendMode);
					layerImagesScales.push(blobLayers[i].scale);
					layerImagesColors.push(blobLayers[i].colorSolid);
					layerImagesOpacities.push(blobLayers[i].alphaSolid);
				}

                //For Bobcat Cashless
                if(_usesTimer) {
                    textureBitmap.addBlob(0, 0, 0xffffffff, 1, 30, NOISE_RADIUS_SCALE, false, null, false, false, i + shapeSeed, 360, true);
                    layerImagesSpeeds.push((speedDirection ? 1 : -1) * (RandomGenerator.getFromSeed(i + shapeSeed) * 10 + 8));
                    layerImagesBlendModes.push(blobLayers[i].blendMode == null ? BlendMode.NORMAL : blobLayers[i].blendMode);
                    layerImagesScales.push(blobLayers[i].scale * (__isADA ? 1: 0.9));
                    layerImagesColors.push(0x57C9E8);
                    layerImagesOpacities.push(blobLayers[i].alphaStroke);
                }

				if (blobLayers[i].alphaStroke > 0) {
					// New stroke
					textureBitmap.addBlob(0, 0, 0xffffffff, 1, blobLayers[i].widthStroke, NOISE_RADIUS_SCALE, false, null, false, false, i + shapeSeed);
					layerImagesSpeeds.push((speedDirection ? 1 : -1) * (RandomGenerator.getFromSeed(i + shapeSeed) * 10 + 8));
					layerImagesBlendModes.push(blobLayers[i].blendMode == null ? BlendMode.NORMAL : blobLayers[i].blendMode);
					layerImagesScales.push(blobLayers[i].scale);
					layerImagesColors.push(blobLayers[i].colorStroke);
					layerImagesOpacities.push(blobLayers[i].alphaStroke);
				}

				speedDirection = !speedDirection;
			}

			// Focus stroke
			if (drawFocusImage) {
				textureBitmap.addBlob(FountainFamily.adaInfo.hardwareFocusFillColor.toRRGGBB(), FountainFamily.adaInfo.hardwareFocusFillColor.a, FountainFamily.adaInfo.hardwareFocusBorderColor.toRRGGBB(), 1, FountainFamily.adaInfo.hardwareFocusBorderWidth, FountainFamily.adaInfo.hardwareFocusScaleNoise, false, FountainFamily.adaInfo.hardwareFocusFilters);
				layerImagesSpeeds.push((speedDirection ? 1 : -1) * RandomGenerator.getInRange(8, 18));
				layerImagesBlendModes.push(BlendMode.NORMAL);
				layerImagesScales.push(1);
				layerImagesColors.push(-1);
				layerImagesOpacities.push(NaN);
				focusImageIndex = layerImagesSpeeds.length-1;
			}

			// Selection solid
			textureBitmap.addBlob(0xffffffff, 1, 0x000000, 0, 0, NOISE_RADIUS_SCALE, false, null, false, false, shapeSeed + blobLayers.length-1);
			layerImagesSpeeds.push(layerImagesSpeeds[blobLayers.length-1]);
			layerImagesBlendModes.push(BlendMode.NORMAL);
			layerImagesScales.push(1);
			layerImagesColors.push(blobLayers[blobLayers.length-1].colorStroke);
			layerImagesOpacities.push(1);
			selectedImageIndex = layerImagesSpeeds.length-1;

			texture = Texture.fromBitmapData(textureBitmap, false, false, FountainFamily.platform.gpuTextureDensity, FountainFamily.platform.getTextureProfile("blob-button-shapes").format);
			if (!FountainFamily.FLAG_PREVENT_LOST_CONTEXT) {
				textureBitmap.dispose();
				textureBitmap = null;
			}

			// Create visual assets
			var smoothing:String = FountainFamily.platform.getTextureProfile("blob-button-shapes").smoothing;

			var image:Image;
			for (i = 0; i < layerImagesSpeeds.length; i++) {
				image = new Image(Texture.fromTexture(texture, TiledBitmapData.getTileRectangle(texture.width, texture.height, w, i)));
				image.smoothing = smoothing;
				image.pivotX = image.width * 0.5;
				image.pivotY = image.height * 0.5;
				image.blendMode = layerImagesBlendModes[i];
				if (layerImagesColors[i] > -1) image.color = layerImagesColors[i];
				addChild(image);
				layerImages.push(image);
			}

            if(__usesTimer) {
                //The animated part of the cashless
                //=============================================================================
                var textureBitmapCashless : MultiBlobBitmap = new MultiBlobBitmap(FountainFamily.platform.gpuTextureMaximumDimensions, w, 1, BLOB_TEXTURE_MARGIN);
                textureBitmapCashless.addBlob(0, 0, 0xffffffff, 1, 20, NOISE_RADIUS_SCALE, false, null, false, false, 0 + shapeSeed, 0);
                layerImagesSpeeds.push((speedDirection ? 1 : -1) * (RandomGenerator.getFromSeed(0 + shapeSeed) * 10 + 8));
                layerImagesBlendModes.push(BlendMode.NORMAL);
                layerImagesScales.push(__isADA ? 1 : 0.9);
                layerImagesColors.push(__timerColor);
                layerImagesOpacities.push(1);

                textureCashless = Texture.fromBitmapData(textureBitmapCashless, false, false, FountainFamily.platform.gpuTextureDensity, FountainFamily.platform.getTextureProfile("blob-button-shapes").format);
                imageCashless = new Image(Texture.fromTexture(textureCashless, TiledBitmapData.getTileRectangle(texture.width, texture.height, w, 0)));
                imageCashless.smoothing = smoothing;
                imageCashless.pivotX = imageCashless.width * 0.5;
                imageCashless.pivotY = imageCashless.height * 0.5;
                imageCashless.blendMode = layerImagesBlendModes[0];
                imageCashless.color = __timerColor;
                addChild(imageCashless);
                layerImages.push(imageCashless);
                //=============================================================================
            }


			// Events
			touchHandler = new TouchHandler();
			touchHandler.onTapped.add(onBlobTapped);
			touchHandler.onPressed.add(onBlobPressed);
			touchHandler.onReleased.add(onBlobReleased);
			touchHandler.onPressCanceled.add(onBlobPressCanceled);
			touchHandler.attachTo(this);

			var imageCaptionId:String = "";
			imageCaption = new Vector.<Image>(7);
			// Create text caption for all the possible texts...
			for (i = 0; i < __caption.length; i ++) {
				if (__caption[i] != null && __caption[i].length > 0) {
					imageCaptionId = "BlobButtonImageCaption_" + __caption[i];
					if (!FountainFamily.objectRecycler.has(imageCaptionId)) FountainFamily.objectRecycler.putNew(imageCaptionId, new Image(TextBitmap.createTexture(__caption[i], __captionBold ? FontLibrary.BOOSTER_NEXT_FY_BOLD : FontLibrary.BOOSTER_FY_REGULAR, __captionEmphasisBold ? FontLibrary.BOOSTER_NEXT_FY_BOLD : FontLibrary.BOOSTER_FY_REGULAR, __captionSize, __captionEmphasisSize, __captionColor, __captionEmphasisColor, __captionAlpha, __captionEmphasisAlpha, __captionTracking, __captionEmphasisTracking, __captionAlignment, false, NaN, __captionLeading)));

					imageCaption[i] = FountainFamily.objectRecycler.get(imageCaptionId);
					imageCaption[i].scaleX = imageCaption[i].scaleY = 1;
					imageCaption[i].pivotX = Math.round(imageCaption[i].texture.width * 0.5);
					imageCaption[i].pivotY = Math.round(imageCaption[i].texture.height * 0.5);
					imageCaption[i].smoothing = "bilinear";
					if (captionOutside) {
						imageCaption[i].pivotY = 0;
						imageCaption[i].y = Math.round(__radius + MARGIN_TEXT_BOTTOM);
					} else if (__atfIcon != null) {
						imageCaption[i].y = Math.round(__radius * -0.06);
					}
                    if (__iconScale == 0) {
                        imageCaption[i].y = Math.round(imageCaption[i].texture.height * 0.25);
                    }
					addChild(imageCaption[i]);
					imageCaption[i].visible = false;
				}
			}

			if(imageCaption[imageCaptionVisible] != null) imageCaption[imageCaptionVisible].visible = true;


			// Create icon
			if (__atfIcon != null) {
				imageIcon = new Image(Texture.fromAtfData(__atfIcon, 1, false));
				imageIcon.pivotX = imageIcon.texture.width * 0.5;
				imageIcon.pivotY = imageIcon.texture.height * 0.5;
				//imageIcon.color = __iconColor; // done on redrawSelected
				if (imageCaption[imageCaptionVisible] != null && !captionOutside) {
					imageIcon.y = __radius * 0.42;
				}
				if(__iconScale != 0) addChild(imageIcon);
			}

			// End
			start();

			instances.push(this);
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function update(__currentTimeSeconds:Number, __tickDeltaTimeSeconds:Number, __currentTick:int):void {
			// Updates the visible representation of a node with the attributes of the mesh node

			var s:Number = __currentTimeSeconds * PI_2;

			for (var i:int = 0; i < layerImages.length; i++) {
				layerImages[i].rotation = FountainFamily.platform.id == "bobcat" ? 0 : MathUtils.rangeMod(s / layerImagesSpeeds[i], -Math.PI, Math.PI);
			}
		}

		private function redrawVisibility():void {
			visible = _visibility > 0;

			var i : uint = 0;
			for(i = 0; i < imageCaption.length; i ++) {
				if (imageCaption[i] != null) {
					imageCaption[i].alpha = _visibility;
					redrawCaptionScale(i);
				}
			}


			if (imageIcon != null) {
				imageIcon.alpha = _visibility;
				redrawIconScale();
			}

			var dt:Number = 0.15;
			var d:Number = layerImages.length * dt;
			for (i = 0; i < layerImages.length; i++) {
				if (drawFocusImage && i == focusImageIndex) {
					// Is focus image
					layerImages[i].alpha = _visibility * (1-_selected);
					layerImages[i].scaleX = layerImages[i].scaleY = MathUtils.map(Math.max(0, Equations.backOut(_visibility * (1 + d) - d)), 0, 1, 0, 1) * layerImagesScales[i];
				} else if (i == selectedImageIndex) {
					// Is selected image
					layerImages[i].alpha = _visibility * _selected * layerImagesOpacities[i];
					layerImages[i].scaleX = layerImages[i].scaleY = MathUtils.map(Math.max(0, Equations.backOut(_visibility * (1 + d) - d)), 0, 1, 0, 1) * layerImagesScales[i];
				} else {
					// Normal image
					if (i == 0) {
						// First layer is always visible
						layerImages[i].alpha = _visibility * layerImagesOpacities[i];
					} else {
						// Only visible if not selected
						layerImages[i].alpha = _visibility * (1-_selected) * layerImagesOpacities[i];
					}
					layerImages[i].scaleX = layerImages[i].scaleY = MathUtils.map(Math.max(0, Equations.backOut(_visibility * (1 + d) - d)), 0, 1, 0, 1) * FountainFamily.adaInfo.hardwareFocusScaleButton * layerImagesScales[i];
				}
				layerImages[i].visible = layerImages[i].alpha > 0;
				d -= dt;
			}

			redrawFocused();
		}

		private function redrawEnabled():void {

		}

		private function redrawPressed():void {
			scaleX = scaleY = MathUtils.map(_pressed, 0, 1, 1, 0.95);
			redrawCaptionScale(0);
			redrawIconScale();
		}

		private function redrawSelected():void {
			if (imageIcon != null) imageIcon.color = Color.interpolateRRGGBB(0xffffff, iconColor, _selected);
		}

		private function redrawFocused():void {
			if (drawFocusImage) layerImages[focusImageIndex].alpha = _visibility * _keyboardFocused;
		}

		private function redrawCaptionScale(i):void {
			// Bad design to have this separated... need to be careful if it starts getting out of hand with states
			if (imageCaption[i] != null) {
				imageCaption[i].scaleX = imageCaption[i].scaleY = MathUtils.map(Math.max(0, Equations.backOut(_visibility * 1.5 - 0.45)), 0, 1, 0, 1) - _pressed * 0.08;
			}
		}

		private function redrawIconScale():void {
			// Bad design to have this separated... need to be careful if it starts getting out of hand with states
			if (imageIcon != null) {
				imageIcon.scaleX = imageIcon.scaleY = (MathUtils.map(Math.max(0, Equations.backOut(_visibility * 1.5 - 0.45)), 0, 1, 0, 1) - _pressed * 0.08) * iconScale;
			}
		}

		private function set language(value : uint) : void{
			for(var i: uint = 0; i < imageCaption.length; i ++) if(imageCaption[i] != null) imageCaption[i].visible = false;
			imageCaptionVisible = value;
			if(imageCaption[imageCaptionVisible] != null) imageCaption[imageCaptionVisible].visible = true;
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		private function onBlobTapped():void {
			_onTapped.dispatch(this);
		}

		private function onBlobPressed():void {
			if (!_wasClickSimulated && FountainFamily.focusController.hasElement(this)) FountainFamily.focusController.executeCommand(FocusController.COMMAND_DEACTIVATE);

			ZTween.remove(this, "pressed");
			ZTween.add(this, {pressed:1}, {time:TIME_ANIMATE_PRESS, transition:Equations.expoOut});
			_onPressed.dispatch(this);
		}

		private function onBlobReleased():void {
			ZTween.remove(this, "pressed");
			ZTween.add(this, {pressed:0}, {time:TIME_ANIMATE_RELEASE, transition:Equations.elasticOut});
			_onReleased.dispatch(this);
		}

		private function onBlobPressCanceled():void {
			ZTween.remove(this, "pressed");
			ZTween.add(this, {pressed:0}, {time:TIME_ANIMATE_RELEASE, transition:Equations.elasticOut});
			_onPressCanceled.dispatch(this);
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		//This beautiful static function changes the languages for all the Blobs!!!!
		public static function set language(value: uint) : void {
			imageCaptionVisible = value;
			for(var i : uint in instances) {
				instances[i].language = value;
			}
		}

		public function setSelected(__selected:Boolean):void {
			ZTween.remove(this, "selected");
			ZTween.add(this, {selected:__selected ? 1 : 0}, {time:TIME_ANIMATE_SELECTION, transition:Equations.quadInOut});
			_onPressCanceled.dispatch(this);
		}

		public function setFocused(__isFocused:Boolean, __immediate:Boolean = false):void {
			ZTween.remove(this, "keyboardFocused");
			if (__immediate) {
				keyboardFocused = __isFocused ? 1 : 0;
			} else {
				ZTween.add(this, {keyboardFocused:__isFocused ? 1 : 0}, {time:FountainFamily.adaInfo.hardwareFocusTimeAnimate});
			}
		}

		public function getVisualBounds():Rectangle {
			return getBounds(Starling.current.stage);
		}

		public function canReceiveFocus():Boolean {
			return _enabled == 1;
		}

		public function simulateEnterDown():void {
			_wasClickSimulated = true;
			onBlobPressed();
		}

		public function simulateEnterUp():void {
			onBlobReleased();
			onBlobTapped();
			_wasClickSimulated = false;
		}

		public function simulateEnterCancel():void {
			_wasClickSimulated = false;
			onBlobReleased();
		}

		public function wasClickSimulated():Boolean {
			return _wasClickSimulated;
		}

		public function stop():void {
			if (isStarted) {
				FountainFamily.looper.onTickedOncePerVisualFrame.remove(update);

				isStarted = false;
			}
		}

		public  function start():void {
			if (!isStarted) {
				redrawVisibility();
				redrawPressed();
				redrawFocused();
				redrawSelected();

				FountainFamily.looper.onTickedOncePerVisualFrame.add(update);
				FountainFamily.looper.updateOnce(update);

				isStarted = true;
			}
		}

		override public function dispose():void {
			stop();

			touchHandler.dettachFrom(this);
			touchHandler.dispose();
			touchHandler = null;

			_onTapped.removeAll();
			_onPressed.removeAll();
			_onReleased.removeAll();
			_onPressCanceled.removeAll();

			while (layerImages.length > 0) {
				removeChild(layerImages[0]);
				FountainFamily.garbageCan.put(layerImages[0].texture);
				//layerImages[0].texture.dispose();
				layerImages[0].dispose();
				layerImages.splice(0, 1);
			}

			layerImagesBlendModes = null;
			layerImagesSpeeds = null;
			layerImagesScales = null;

			for(var i : uint = 0; i < imageCaption.length; i ++) {
				if (imageCaption[i] != null) {
					removeChild(imageCaption[i]);
					//imageCaption.texture.dispose();
					//FountainFamily.garbageCan.put(imageCaption.texture);
					//imageCaption.dispose();
					FountainFamily.objectRecycler.putBack(imageCaption[i]);
					imageCaption[i] = null;
				}
			}


			if (imageIcon != null) {
				removeChild(imageIcon);
				FountainFamily.garbageCan.put(imageIcon.texture);
				//imageIcon.texture.dispose();
				imageIcon.dispose();
				imageIcon = null;
			}

			FountainFamily.garbageCan.put(texture);
			//texture.dispose();
			texture = null;
			if (textureBitmap != null) {
				textureBitmap.dispose();
				textureBitmap = null;
			}

			super.dispose();
		}

		public function recycle():void {
			_wasClickSimulated = false;
			visibility = 1;
			enabled = 1;
			pressed = 0;
			selected = 0;
			keyboardFocused = 0;
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

        public function set timerAngle(angle : Number) : void {
            if(_usesTimer) {
                _timerAngle = angle;
                var textureBitmapCashless : MultiBlobBitmap = new MultiBlobBitmap(FountainFamily.platform.gpuTextureMaximumDimensions, w, 1, BLOB_TEXTURE_MARGIN);
                textureBitmapCashless.addBlob(0, 0, 0xffffffff, 1, 30, NOISE_RADIUS_SCALE, false, null, false, false, 0 + shapeSeed, angle, true);
                imageCashless.texture = Texture.fromBitmapData(textureBitmapCashless, false, false, FountainFamily.platform.gpuTextureDensity, FountainFamily.platform.getTextureProfile("blob-button-shapes").format);
                textureBitmapCashless = null;
            }
        }

        public function get timerAngle() : Number {
            return _timerAngle;
        }

		public function get radius():Number {
			return _radius;
		}

		public function get bottomHeight():Number {
			return captionOutside ? imageCaption[imageCaptionVisible].y + imageCaption[imageCaptionVisible].height : _radius;
		}

		public function get visibility():Number {
			return _visibility;
		}
		public function set visibility(__value:Number):void {
			if (_visibility != __value) {
				_visibility = __value;
				redrawVisibility();
			}
		}

		public function get enabled():Number {
			return _enabled;
		}
		public function set enabled(__value:Number):void {
			if (_enabled != __value) {
				_enabled = __value;
				redrawEnabled();
			}
		}

		public function get pressed():Number {
			return _pressed;
		}
		public function set pressed(__value:Number):void {
			if (_pressed != __value) {
				_pressed = __value;
				redrawPressed();
			}
		}

		public function get selected():Number {
			return _selected;
		}
		public function set selected(__value:Number):void {
			if (_selected != __value) {
				_selected = __value;
				redrawSelected();
				redrawVisibility();
			}
		}

		public function get keyboardFocused():Number {
			return _keyboardFocused;
		}

		public function set keyboardFocused(__value:Number):void {
			if (_keyboardFocused != __value) {
				_keyboardFocused = __value;
				redrawFocused();
			}
		}

		public function get onTapped():SimpleSignal {
			return _onTapped;
		}

		public function get onPressed():SimpleSignal {
			return _onPressed;
		}

		public function get onReleased():SimpleSignal {
			return _onReleased;
		}

		public function get onPressCanceled():SimpleSignal {
			return _onPressCanceled;
		}

		public function get imgCaption():Image
		{
			return imageCaption[imageCaptionVisible];
		}

		// Lee:
		public function get imgIcon():Image
		{
			return imageIcon;
		}

		public static function getButtonStyle(__styleId:String):BlobButtonStyle {
			var blobButtonStyle:BlobButtonStyle = new BlobButtonStyle();

			switch (__styleId) {
				case STYLE_POUR_TOWER:
					blobButtonStyle.radius = 176;
					blobButtonStyle.margin = 65;
					blobButtonStyle.gutter = 0;
					blobButtonStyle.strokeWidths = VectorUtils.arrayToNumberVector([1, 3]);
					blobButtonStyle.iconScale = 0.85;
					blobButtonStyle.fontSize = 16;
					blobButtonStyle.fontBold = true;
					blobButtonStyle.fontAlpha = 0.7;
					blobButtonStyle.fontTracking = 120;
					blobButtonStyle.fontEmphasisSize = 65;
					blobButtonStyle.fontEmphasisBold = false;
					blobButtonStyle.fontEmphasisAlpha = 1;
					blobButtonStyle.fontEmphasisTracking = -30;
					blobButtonStyle.fontLeading = 6;
					break;
				case STYLE_POUR_TOWER_ADA:
					blobButtonStyle.radius = 138;
					blobButtonStyle.margin = 30;
					blobButtonStyle.gutter = 0;
					blobButtonStyle.strokeWidths = VectorUtils.arrayToNumberVector([1, 2]);
					blobButtonStyle.iconScale = 0.85;
					blobButtonStyle.fontSize = 16;
					blobButtonStyle.fontBold = true;
					blobButtonStyle.fontAlpha = 0.7;
					blobButtonStyle.fontTracking = 120;
					blobButtonStyle.fontEmphasisSize = 65;
					blobButtonStyle.fontEmphasisBold = false;
					blobButtonStyle.fontEmphasisAlpha = 1;
					blobButtonStyle.fontEmphasisTracking = -30;
					blobButtonStyle.fontLeading = 6;
					break;
				case STYLE_POUR_BRIDGE:
					blobButtonStyle.radius = 112;
					blobButtonStyle.margin = 40;
					blobButtonStyle.gutter = 0;
					blobButtonStyle.strokeWidths = VectorUtils.arrayToNumberVector([1, 3]);
					blobButtonStyle.iconScale = 0.64;
					blobButtonStyle.fontSize = 11;
					blobButtonStyle.fontBold = true;
					blobButtonStyle.fontAlpha = 0.7;
					blobButtonStyle.fontTracking = 100;
					blobButtonStyle.fontEmphasisSize = 45;
					blobButtonStyle.fontEmphasisBold = false;
					blobButtonStyle.fontEmphasisAlpha = 1;
					blobButtonStyle.fontEmphasisTracking = -20;
					blobButtonStyle.fontLeading = 6;
					break;
				case STYLE_POUR_BRIDGE_ADA:
					blobButtonStyle.radius = 104;
					blobButtonStyle.margin = 18;
					blobButtonStyle.gutter = 0;
					blobButtonStyle.strokeWidths = VectorUtils.arrayToNumberVector([1, 2]);
					blobButtonStyle.iconScale = 0.64;
					blobButtonStyle.fontSize = 11;
					blobButtonStyle.fontBold = true;
					blobButtonStyle.fontAlpha = 0.7;
					blobButtonStyle.fontTracking = 100;
					blobButtonStyle.fontEmphasisSize = 45;
					blobButtonStyle.fontEmphasisBold = false;
					blobButtonStyle.fontEmphasisAlpha = 1;
					blobButtonStyle.fontEmphasisTracking = -20;
					blobButtonStyle.fontLeading = 6;
					break;
				case STYLE_NEUTRAL_MEDIUM:
					blobButtonStyle.radius = 74; // Set this to 65 eventually, and start using style-neutral-medium instead of style-back-small maybe
					blobButtonStyle.margin = 31;
					blobButtonStyle.gutter = 18;
					blobButtonStyle.strokeWidths = VectorUtils.arrayToNumberVector([3]);
					blobButtonStyle.iconScale = 1;
					blobButtonStyle.fontSize = 16;
					blobButtonStyle.fontBold = false;
					blobButtonStyle.fontTracking = -10;
					blobButtonStyle.fontEmphasisSize = 18;
					blobButtonStyle.fontEmphasisBold = false;
					blobButtonStyle.fontEmphasisAlpha = 1;
					blobButtonStyle.fontEmphasisTracking = -10;
					blobButtonStyle.fontLeading = 0;
					break;
				case STYLE_NEUTRAL_SMALL:
					blobButtonStyle.radius = 55;
					blobButtonStyle.margin = 18;
					blobButtonStyle.gutter = 0;
					blobButtonStyle.strokeWidths = VectorUtils.arrayToNumberVector([2]);
					blobButtonStyle.iconScale = 0.82;
					blobButtonStyle.fontSize = 12;
					blobButtonStyle.fontBold = false;
					blobButtonStyle.fontAlpha = 1;
					blobButtonStyle.fontTracking = -10;
					blobButtonStyle.fontEmphasisSize = 14;
					blobButtonStyle.fontEmphasisBold = true;
					blobButtonStyle.fontEmphasisAlpha = 1;
					blobButtonStyle.fontEmphasisTracking = -10;
					blobButtonStyle.fontLeading = 0;
					break;
				case STYLE_BACK_SMALL:
					blobButtonStyle.radius = 64;
					blobButtonStyle.margin = 31;
					blobButtonStyle.gutter = 18; // wrong/not used
					blobButtonStyle.strokeWidths = VectorUtils.arrayToNumberVector([3]);
					blobButtonStyle.iconScale = 0.86;
					blobButtonStyle.fontSize = 17;
					blobButtonStyle.fontBold = false;
					blobButtonStyle.fontAlpha = 1;
					blobButtonStyle.fontTracking = -10;
					blobButtonStyle.fontEmphasisSize = 17;
					blobButtonStyle.fontEmphasisBold = false;
					blobButtonStyle.fontEmphasisAlpha = 1;
					blobButtonStyle.fontEmphasisTracking = -10;
					blobButtonStyle.fontLeading = 0;
					break;
				case STYLE_BACK_TINY:
					blobButtonStyle.radius = 50;
					blobButtonStyle.margin = 18;
					blobButtonStyle.gutter = 8; // wrong/not used
					blobButtonStyle.strokeWidths = VectorUtils.arrayToNumberVector([2]);
					blobButtonStyle.iconScale = 0.86;
					blobButtonStyle.fontSize = 14;
					blobButtonStyle.fontBold = false;
					blobButtonStyle.fontAlpha = 1;
					blobButtonStyle.fontTracking = -10;
					blobButtonStyle.fontEmphasisSize = 14;
					blobButtonStyle.fontEmphasisBold = true;
					blobButtonStyle.fontEmphasisAlpha = 1;
					blobButtonStyle.fontEmphasisTracking = -10;
					blobButtonStyle.fontLeading = 0;
					break;
			}

			return blobButtonStyle;

		}
	}
}
