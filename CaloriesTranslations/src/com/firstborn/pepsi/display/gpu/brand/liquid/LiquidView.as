package com.firstborn.pepsi.display.gpu.brand.liquid {
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.extensions.pixelmask.PixelMaskDisplayObject;

	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.data.TextureProfile;
	import com.firstborn.pepsi.data.inventory.Beverage;
	import com.firstborn.pepsi.display.gpu.brand.view.BrandViewOptions;
	import com.zehfernando.utils.MathUtils;
	import com.zehfernando.utils.RandomGenerator;

	import flash.geom.Point;
	import flash.geom.Rectangle;

	/**
	 * @author zeh fernando
	 */
	public class LiquidView extends Sprite {

		// Constants
		private static const LAYOUT_BOTTOM_BLOB_RADIUS:Number = 900;
		private static const LAYOUT_BOTTOM_CENTER_X:Number = 0.63;							// In 0-1 of view size
		private static const LAYOUT_BOTTOM_CENTER_Y_4:Number = 0.93;						// In 0-1 of view size, for 4 flavors
		private static const LAYOUT_BOTTOM_CENTER_Y_6:Number = 0.98;						// In 0-1 of view size, for 6 flavors
		private static const LAYOUT_BOTTOM_CENTER_Y_MIX:Number = 0.98;						// In 0-1 of view size, for MIXED beverages

		private static const LAYOUT_RIGHT_BLOB_RADIUS:Number = 780;
		private static const LAYOUT_RIGHT_CENTER_X:Number = 1090 / 1080; //1;
		private static const LAYOUT_RIGHT_CENTER_Y:Number = 780 / 1180; // 0.6656;

		private static const VIDEO_ORIGINAL_WIDTH:Number = 648;
		private static const VIDEO_ORIGINAL_HEIGHT:Number = 584;

		private static const BLOB_MENU_SCALE_TWEAK:Number = 0.9;							// How much more the big blob is in relation to the main menu bubble... necessary because they have different noise types

		// Properties
		private var speedBigBlobRotation:Number;
		private var speedStrokeRotation:Number;

		private var _visibility:Number;
		private var _width:Number;
		private var _height:Number;

		private var blobCenterX:Number;
		private var blobCenterY:Number;
		private var blobRadius:Number;

		private var offsetPoint:Point;

		// Instances
		private var beverage:Beverage;

		private var liquidVideos:LiquidVideos;								// Actual videos
		private var liquidVideosMask:Image;									// Mask blob that rotates
		private var liquidVideosContainer:PixelMaskDisplayObject;			// Container for the masked videos
		private var imageStroke:Image;										// Stroke that rotates


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function LiquidView(__layout:String, __beverage:Beverage, __strokeColor:uint, __width:Number, __height:Number, __liquidOffsetX:Number, __liquidOffsetY:Number, __liquidPouredOffsetY:Number) {
			_visibility = 1;
			_width = __width;
			_height = __height;
			beverage = __beverage;

			switch (__layout) {
				case BrandViewOptions.LIQUID_LAYOUT_BOTTOM:
					blobCenterX = _width * LAYOUT_BOTTOM_CENTER_X;
					blobCenterY = _height * (__beverage.isMix ? LAYOUT_BOTTOM_CENTER_Y_MIX : MathUtils.map(beverage.flavorIds.length, 4, 6, LAYOUT_BOTTOM_CENTER_Y_4, LAYOUT_BOTTOM_CENTER_Y_6, true));
					blobRadius = LAYOUT_BOTTOM_BLOB_RADIUS;
					break;
				case BrandViewOptions.LIQUID_LAYOUT_RIGHT:
					blobCenterX = _width * LAYOUT_RIGHT_CENTER_X;
					blobCenterY = _height * LAYOUT_RIGHT_CENTER_Y;
					blobRadius = LAYOUT_RIGHT_BLOB_RADIUS;
					break;
			}

			var tpf:TextureProfile;
			var im:Image;

			var direction:Boolean = RandomGenerator.getBoolean();
			speedBigBlobRotation = (direction ? 1 : -1) * RandomGenerator.getInRange(70, 72);
			speedStrokeRotation = (!direction ? 1 : -1) * RandomGenerator.getInRange(40, 42);
			//speedBigBlobRotation = 0;

			// Video container: width of the visible bubble, and then aligned to the bottom
			var videoLeft:Number = Math.max(0, Math.floor(blobCenterX - LAYOUT_BOTTOM_BLOB_RADIUS));
			var videoRight:Number = Math.min(_width, Math.ceil(blobCenterX + LAYOUT_BOTTOM_BLOB_RADIUS));
			var videoWidth:Number = videoRight - videoLeft;
			var videoHeight:Number = Math.round((videoWidth / VIDEO_ORIGINAL_WIDTH) * VIDEO_ORIGINAL_HEIGHT);

			liquidVideos = new LiquidVideos(videoLeft, _height - videoHeight, videoRight, _height, __beverage, __liquidOffsetX, __liquidOffsetY, __liquidPouredOffsetY);
			// Original (pre-scaling of the videos to the blob size):
			//liquidVideos = new LiquidVideos(0, _height - videoHeight, videoWidth, _height, __beverage, __liquidOffsetX, __liquidOffsetY, __liquidPouredOffsetY);
			liquidVideos.y -= FountainFamily.platform.maskViewportCompensationY;

			// Big blob mask
			var hugeBlobMaskImageId:String = "LiquidView_hugeBlobMask";
			if (!FountainFamily.objectRecycler.has(hugeBlobMaskImageId)) {
				tpf = FountainFamily.platform.getTextureProfile("blob-huge-mask");
				im = new Image(FountainFamily.textureLibrary.getLiquidBlob());
				im.pivotX = im.texture.nativeWidth * 0.5;
				im.pivotY = im.texture.nativeHeight * 0.5;
				im.smoothing = tpf.smoothing;
				im.width = im.height = blobRadius * 2;
				FountainFamily.objectRecycler.putNew(hugeBlobMaskImageId, im);
			}
			liquidVideosMask = FountainFamily.objectRecycler.get(hugeBlobMaskImageId);
			liquidVideosMask.rotation = 0;
			liquidVideosMask.scaleX = liquidVideosMask.scaleY = 1;
			liquidVideosMask.width = liquidVideosMask.height = blobRadius * 2;

			// Create masked container
			var maskedContainerId:String = "LiquidView_masked";
			if (!FountainFamily.objectRecycler.has(maskedContainerId)) {
				FountainFamily.objectRecycler.putNew(maskedContainerId, new PixelMaskDisplayObject());
			}
			liquidVideosContainer = FountainFamily.objectRecycler.get(maskedContainerId);
			liquidVideosContainer.mask = FountainFamily.DEBUG_LIQUID_VIDEOS_ARE_UNMASKED ? null : liquidVideosMask;
			liquidVideosContainer.y = FountainFamily.platform.maskViewportCompensationY;
			liquidVideosContainer.addChild(liquidVideos);
			addChild(liquidVideosContainer);

			// Stroke blob
			var hugeBlobStrokeImageId:String = "LiquidView_hugeBlobStroke";
			if (!FountainFamily.objectRecycler.has(hugeBlobStrokeImageId)) {
				tpf = FountainFamily.platform.getTextureProfile("blob-huge-stroke");
				im = new Image(FountainFamily.textureLibrary.getLiquidStroke());
				im.pivotX = im.texture.nativeWidth * 0.5;
				im.pivotY = im.texture.nativeHeight * 0.5;
				im.width = im.height = blobRadius * 2;
				im.smoothing = tpf.smoothing;
				FountainFamily.objectRecycler.putNew(hugeBlobStrokeImageId, im);
			}
			imageStroke = FountainFamily.objectRecycler.get(hugeBlobStrokeImageId);
			imageStroke.color = __strokeColor;
			addChild(imageStroke);

			// End
			redrawVisibility();

			FountainFamily.looper.onTickedOncePerVisualFrame.add(update);
			FountainFamily.looper.updateOnce(update);
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function update(__currentTimeSeconds:Number, __tickDeltaTimeSeconds:Number, __currentTick:int):void {
			liquidVideosMask.rotation = MathUtils.rangeMod(__currentTimeSeconds * Math.PI * 2 / speedBigBlobRotation, -Math.PI, Math.PI);
			imageStroke.rotation = MathUtils.rangeMod(__currentTimeSeconds * Math.PI * 2 / speedStrokeRotation, -Math.PI, Math.PI);
		}

		private function redrawVisibility():void {
			visible = _visibility > 0;
			liquidVideos.alpha = _visibility;
			imageStroke.alpha = _visibility;
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function startPour():void {
			liquidVideos.startPour();
		}

		public function stopPour():void {
			liquidVideos.stopPour();
		}

		public function setLiquidClipRect(__rectangle:Rectangle):void {
			// Set the rectangle that the liquid videos have to be clipped at
			// Done AFTER the visibility is set

			//liquidVideos.setClipRect(__rectangle);

			if (offsetPoint == null) offsetPoint = FountainFamily.platform.getUnscaledPoint(localToGlobal(new Point(0, 0)));

			imageStroke.x = liquidVideosMask.x = (__rectangle.left + __rectangle.width * 0.5 - offsetPoint.x) * 1;
			imageStroke.y = liquidVideosMask.y = (__rectangle.top + __rectangle.height * 0.5 - offsetPoint.y) * 1;
			liquidVideosMask.y -= FountainFamily.platform.maskViewportCompensationY;

			var sizeScale:Number = MathUtils.map(_visibility, 0, 1, BLOB_MENU_SCALE_TWEAK, 1);

			imageStroke.scaleX = imageStroke.scaleY = __rectangle.width / imageStroke.texture.nativeWidth * sizeScale;
			liquidVideosMask.scaleX = liquidVideosMask.scaleY = __rectangle.width / liquidVideosMask.texture.nativeWidth * sizeScale;

			// Needed because it's not calculating properly?
			//liquidVideosContainer.forceRefreshRenderTextures();
		}

		override public function dispose():void {
			FountainFamily.looper.onTickedOncePerVisualFrame.remove(update);

			liquidVideosContainer.removeChild(liquidVideos);
			liquidVideos.dispose();
			liquidVideos = null;

			removeChild(liquidVideosContainer);
			liquidVideosContainer.mask = null;
			//liquidVideosContainer.dispose();
			FountainFamily.objectRecycler.putBack(liquidVideosContainer);
			liquidVideosContainer = null;

			//liquidVideosMask.dispose();
			FountainFamily.objectRecycler.putBack(liquidVideosMask);
			liquidVideosMask = null;

			removeChild(imageStroke);
			//imageStroke.dispose();
			FountainFamily.objectRecycler.putBack(imageStroke);
			imageStroke = null;

			super.dispose();
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

		public function getMaskCenter():Point {
			// Returns the center point of the liquid's blob, in the GLOBAL space
			return FountainFamily.platform.getUnscaledPoint(localToGlobal(new Point(blobCenterX, blobCenterY)));
		}

		public function getMaskRadius():Number {
			return blobRadius;
		}

		override public function get width():Number {
			return _width;
		}
		override public function set width(__value:Number):void {
		}

		override public function get height():Number {
			return _height;
		}
		override public function set height(__value:Number):void {
		}
	}
}
