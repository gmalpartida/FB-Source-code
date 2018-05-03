package com.firstborn.pepsi.common.display.debug {
	import starling.core.RenderSupport;
	import starling.core.Starling;

	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.assets.FontLibrary;
	import com.firstborn.pepsi.display.gpu.GPURoot;
	import com.firstborn.pepsi.display.gpu.common.MastheadView;
	import com.zehfernando.display.components.text.TextSprite;
	import com.zehfernando.display.components.text.TextSpriteAlign;
	import com.zehfernando.display.shapes.Box;
	import com.zehfernando.utils.DelayedCalls;
	import com.zehfernando.utils.console.error;
	import com.zehfernando.utils.console.info;

	import flash.display.BitmapData;
	import flash.display.PNGEncoderOptions;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	/**
	 * @author zeh fernando
	 */
	public class ImageCapturePanel extends Sprite {

		// Properties
		private var _width:Number;
		private var _height:Number;
		private var _visible:Boolean;
		private var autoCapture:Boolean;
		private var currentImageId:String;

		// Instances
		private var capturedImages:Vector.<ByteArray>;
		private var capturedImageNames:Vector.<String>;
		private var allCapturedImageIds:Vector.<String>;
		private var saveFileReference:FileReference;
		private var textName:TextSprite;
		private var textTotals:TextSprite;
		private var buttonCapture:Box;
		private var buttonAutoCapture:Box;
		private var buttonSave:Box;
		private var background:Box;
		private var starling:Starling;
		private var gpuRoot:GPURoot;
		private var masthead:MastheadView;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function ImageCapturePanel(__width:Number, __height:Number, __starling:Starling, __gpuRoot:GPURoot, __masthead:MastheadView) {
			_width = __width;
			_height = __height;
			_visible = false;
			starling = __starling;
			gpuRoot = __gpuRoot;
			masthead = __masthead;

			autoCapture = false;

			// Initializations
			capturedImages = new Vector.<ByteArray>();
			capturedImageNames = new Vector.<String>();
			allCapturedImageIds = new Vector.<String>();

			saveFileReference = new FileReference();
			saveFileReference.addEventListener(flash.events.Event.COMPLETE, onSaveImageComplete);
			saveFileReference.addEventListener(IOErrorEvent.IO_ERROR, onSaveImageIOError);

			// Interface

			var margin:Number = 20;
			var buttonHeight:Number = 50;
			var w:Number = _width;

			background = new Box(_width, _height, 0xeeeeee);
			background.alpha = 0.99;
			addChild(background);

			var posY:Number = margin;

			textName = new TextSprite(FontLibrary.BOOSTER_FY_REGULAR, 20, 0x000000, 1);
			textName.align = textName.blockAlignHorizontal = TextSpriteAlign.CENTER;
			textName.text = "x";
			textName.x = width * 0.5;
			textName.y = posY;
			textName.width = w - margin * 2;
			addChild(textName);

			posY += textName.height + margin;

			buttonCapture = createButton("CAPTURE", margin, Math.round(posY), w - margin * 2, buttonHeight);
			buttonCapture.addEventListener(MouseEvent.CLICK, onClickCapture);

			posY += buttonHeight + margin;

			buttonAutoCapture = createButton("AUTO-CAPTURE", margin, Math.round(posY), w - margin * 2, buttonHeight);
			buttonAutoCapture.addEventListener(MouseEvent.CLICK, onClickAutoCapture);

			posY += buttonHeight + margin;

			textTotals = new TextSprite(FontLibrary.BOOSTER_FY_REGULAR, 20, 0x000000, 1);
			textTotals.align = textTotals.blockAlignHorizontal = TextSpriteAlign.CENTER;
			textTotals.text = "x";
			textTotals.x = width * 0.5;
			textTotals.y = posY;
			textTotals.width = w - margin * 2;
			addChild(textTotals);

			posY += textTotals.height + margin;

			buttonSave = createButton("SAVE", margin, Math.round(posY), w - margin * 2, buttonHeight);
			buttonSave.addEventListener(MouseEvent.CLICK, onClickSave);

			// Events

			// End
			applyVisible();
			updateCurrentImageId();
			updateTextTotals();
			updateAutoCaptureButton();
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function applyVisible():void {
			super.visible = _visible;
			if (_visible) {
				updateCurrentImageId();
				if (masthead != null) masthead.canUseStageVideo = false;
				gpuRoot.onChangedView.add(onGPURootChangedView);
			} else {
				if (masthead != null) masthead.canUseStageVideo = true;
				gpuRoot.onChangedView.remove(onGPURootChangedView);
			}
		}

		private function updateCurrentImageId():void {
			currentImageId = gpuRoot.getUniqueNavigationId();
			updateTextName();
		}

		private function updateTextName():void {
			textName.text = "Id: [" + currentImageId + "]";
		}

		private function updateTextTotals():void {
			textTotals.text = "Images captured: " + capturedImages.length;
		}

		private function updateAutoCaptureButton():void {
			buttonAutoCapture.alpha = autoCapture ? 1 : 0.4;
		}

		private function autoCaptureImage():void {
			// Capture the image only if it hasn't been captured yet
			if (allCapturedImageIds.indexOf(currentImageId) == -1) {
				// Wait 2 seconds before capturing
				DelayedCalls.add(2000, captureImageInternal);
			}
		}

		private function captureImageInternal():void {
			// Capture the current screen as an image

			// Create GPU bitmap
			var support:RenderSupport = new RenderSupport();
			var showStats:Boolean = starling.showStats;
			starling.showStats = false;
			RenderSupport.clear(stage.color, 1.0);
			support.setOrthographicProjection(0, 0, FountainFamily.platform.width, FountainFamily.platform.heightMinusMasthead);
			//support.setOrthographicProjection(0, 0, starling.stage.stageWidth, starling.stage.stageHeight);
			starling.stage.render(support, 1.0);
			support.finishQuadBatch();

			var gpuBitmap:BitmapData = new BitmapData(FountainFamily.platform.width, FountainFamily.platform.heightMinusMasthead, true, 0xff000000);
			Starling.context.drawToBitmapData(gpuBitmap);
			starling.showStats = showStats;

			// Create final bitmap
			var bitmap:BitmapData = new BitmapData(FountainFamily.platform.width, FountainFamily.platform.height, true, 0xff000000);

			// Copy GPU bitmap
			bitmap.copyPixels(gpuBitmap, gpuBitmap.rect, new Point(0, FountainFamily.platform.mastheadHeight), null, null, true);

			// Copy masthead bitmap
			if (FountainFamily.platform.mastheadHeight > 0) {
				var videoFrame:BitmapData = masthead.getFrame();
				bitmap.copyPixels(videoFrame, videoFrame.rect, new Point(0, 0), null, null, true);
			}

			// Warning: it always crops the context bitmap data to the size of the visible screen, so you always need to be in fullscreen mode prior to capturing the image

			// Figure out image name
			var imageName:String = currentImageId + ".png";

			// Encodes the image
			var byteArray:ByteArray = new ByteArray();
			bitmap.encode(bitmap.rect, new PNGEncoderOptions(), byteArray);

			// Adds to the list
			capturedImages.push(byteArray);
			capturedImageNames.push(imageName);
			allCapturedImageIds.push(currentImageId);

			updateTextTotals();

			// Dispose of everything
			gpuBitmap.dispose();
			gpuBitmap = null;

			bitmap.dispose();
			bitmap = null;
		}

		private function saveNextImage():void {
			// Save the next captured image as an image file
			if (capturedImages.length > 0) {
				saveFileReference.save(capturedImages[0], capturedImageNames[0]);
			}
		}

		private function createButton(__caption:String, __x:Number, __y:Number, __width:Number, __height:Number):Box {
			var backgroundDark:Box = new Box(__width, __height, 0x999999);
			backgroundDark.x = __x;
			backgroundDark.y = __y;
			backgroundDark.buttonMode = true;
			addChild(backgroundDark);

			var outline:Box = new Box(backgroundDark.width, backgroundDark.height, 0x000000, 1);
			outline.x = backgroundDark.x;
			outline.y = backgroundDark.y;
			outline.mouseChildren = outline.mouseEnabled = false;
			outline.alpha = 0.2;
			addChild(outline);

			var textSprite:TextSprite;

			// Caption
			textSprite = new TextSprite(FontLibrary.BOOSTER_FY_REGULAR, 28, 0xffffff, 1);
			textSprite.text = __caption;
			textSprite.filters = [new GlowFilter(0x000000, 0.2, 4, 4, 2, 3)];
			textSprite.blockAlignVertical = TextSpriteAlign.MIDDLE;
			textSprite.blockAlignHorizontal = TextSpriteAlign.CENTER;
			textSprite.x = backgroundDark.x + backgroundDark.width * 0.5;
			textSprite.y = backgroundDark.y + backgroundDark.height * 0.52;
			textSprite.mouseChildren = textSprite.mouseEnabled = false;
			addChild(textSprite);

			return backgroundDark;
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		private function onGPURootChangedView():void {
			updateCurrentImageId();
			if (autoCapture) autoCaptureImage();
		}

		private function onClickCapture(__e:Event):void {
			captureImageInternal();
		}

		private function onClickAutoCapture(__e:Event):void {
			autoCapture = !autoCapture;
			updateAutoCaptureButton();
			if (autoCapture) autoCaptureImage();
		}

		private function onClickSave(__e:Event):void {
			saveNextImage();
		}

		private function onSaveImageComplete(__e:flash.events.Event):void {
			info("Image saved");
			if (capturedImages.length > 0) {
				capturedImages.splice(0, 1);
				capturedImageNames.splice(0, 1);
				updateTextTotals();
			}
		}

		private function onSaveImageIOError(__e:flash.events.IOErrorEvent):void {
			error("Error saving image: " + __e);
		}

		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function captureImage():void {
			captureImageInternal();
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		override public function get width():Number {
			return _width;
		}

		override public function get height():Number {
			return _height;
		}

		override public function get visible():Boolean {
			return _visible;
		}
		override public function set visible(__value:Boolean):void {
			if (_visible != __value) {
				_visible = __value;
				applyVisible();
			}
		}
	}
}
