package com.firstborn.pepsi.common.display.debug {
	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.assets.FontLibrary;
	import com.firstborn.pepsi.common.backend.BackendModel;
	import com.firstborn.pepsi.data.inventory.Beverage;
	import com.firstborn.pepsi.display.gpu.GPURoot;
	import com.zehfernando.data.types.Color;
	import com.zehfernando.display.components.HorizontalSlider;
	import com.zehfernando.display.components.Slider;
	import com.zehfernando.display.components.text.TextSprite;
	import com.zehfernando.display.components.text.TextSpriteAlign;
	import com.zehfernando.display.shapes.Box;
	import com.zehfernando.display.shapes.GradientBox;
	import com.zehfernando.transitions.ZTween;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	/**
	 * @author zeh fernando
	 */
	public class ColorEditPanel extends Sprite {

		// Properties
		private var _width:Number;
		private var _height:Number;
		private var backendSuspended:Boolean;

		private var showBrightnessSliders:Boolean;
		private var showTimeSliders:Boolean;

		// Instances
		private var textLighting:TextSprite;
		private var sliderR:HorizontalSlider;
		private var sliderG:HorizontalSlider;
		private var sliderB:HorizontalSlider;
		private var sliderH:HorizontalSlider;
		private var sliderS:HorizontalSlider;
		private var sliderV:HorizontalSlider;
		private var sliderBrightness:HorizontalSlider;
		private var sliderTransition:HorizontalSlider;
		private var buttonLight:Box;
		private var buttonSave:Box;
		private var sliderNozzleBrightness:HorizontalSlider;
		private var sliderNozzleTransition:HorizontalSlider;
		private var buttonNozzle:Box;
		private var background:Box;
		private var gpuRoot:GPURoot;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function ColorEditPanel(__width:Number, __height:Number, __gpuRoot:GPURoot = null) {
			_width = __width;
			_height = __height;
			gpuRoot = __gpuRoot;

			showBrightnessSliders = false;
			showTimeSliders = false;

			// Initializations

			var margin:Number = 20;
			var w:Number = _width;
			var numRows:int = 11 + (showBrightnessSliders ? 1 : 0) + (showTimeSliders ? 2 : 0);
			var gutter:Number = 5;
			var rowHeight:Number = (_height - (numRows - 1) * gutter) / numRows;

			var textSprite:TextSprite;

			background = new Box(_width, _height, 0xeeeeee);
			background.alpha = 0.99;
			addChild(background);

			var posY:Number = 0;

			// Light color
			textSprite = new TextSprite(FontLibrary.BOOSTER_FY_REGULAR, 40, 0x000000, 1);
			textSprite.text = "LIGHTING";
			textSprite.x = margin;
			textSprite.y = posY + rowHeight * 0.5 - textSprite.height * 0.45;
			addChild(textSprite);

			textLighting = textSprite;

			posY += rowHeight;

			sliderR = createRowSlider("RED", margin, posY, w - margin * 2, rowHeight, 0, 255, [0x000000, 0xff0000]);
			sliderR.addEventListener(Slider.EVENT_POSITION_CHANGED_BY_USER, onChangedColorSlidersRGB);
			posY += sliderR.height + gutter;
			sliderG = createRowSlider("GREEN", margin, posY, w - margin * 2, rowHeight, 0, 255, [0x000000, 0x00ff00]);
			sliderG.addEventListener(Slider.EVENT_POSITION_CHANGED_BY_USER, onChangedColorSlidersRGB);
			posY += sliderG.height + gutter;
			sliderB = createRowSlider("BLUE", margin, posY, w - margin * 2, rowHeight, 0, 255, [0x000000, 0x0000ff]);
			sliderB.addEventListener(Slider.EVENT_POSITION_CHANGED_BY_USER, onChangedColorSlidersRGB);
			posY += sliderB.height + gutter;
			sliderH = createRowSlider("HUE", margin, posY, w - margin * 2, rowHeight, 0, 360, [0xff0000, 0xffff00, 0x00ff00, 0x00ffff, 0x0000ff, 0xff00ff, 0xff0000]);
			sliderH.addEventListener(Slider.EVENT_POSITION_CHANGED_BY_USER, onChangedColorSlidersHSV);
			posY += sliderH.height + gutter;
			sliderS = createRowSlider("SAT", margin, posY, w - margin * 2, rowHeight, 0, 100, [0x666666, 0xffffff]);
			sliderS.addEventListener(Slider.EVENT_POSITION_CHANGED_BY_USER, onChangedColorSlidersHSV);
			posY += sliderS.height + gutter;
			sliderV = createRowSlider("BRIGHT", margin, posY, w - margin * 2, rowHeight, 0, 100, [0x000000, 0xffffff]);
			sliderV.addEventListener(Slider.EVENT_POSITION_CHANGED_BY_USER, onChangedColorSlidersHSV);
			posY += sliderB.height + gutter;
			sliderBrightness = createRowSlider("ALPHA", margin, posY, w - margin * 2, rowHeight, 0, 255, [0x000000, 0xffffff]);
			sliderBrightness.addEventListener(Slider.EVENT_POSITION_CHANGED_BY_USER, onChangedColorSlidersRGB);
			if (showBrightnessSliders) {
				posY += sliderBrightness.height + gutter;
			} else {
				(sliderBrightness.extra["container"] as Sprite).visible = false;
			}
			sliderTransition = createRowSlider("TIME MS", margin, posY, w - margin * 2, rowHeight, 0, 5000, [0xaaaaaa, 0xaaaaaa]);
			if (showTimeSliders) {
				posY += sliderTransition.height + gutter;
			} else {
				(sliderTransition.extra["container"] as Sprite).visible = false;
			}

			buttonLight = createRowButton("RE-APPLY", margin, posY, w - margin * 2, rowHeight);
			buttonLight.addEventListener(MouseEvent.CLICK, onClickApplyColor);

			buttonSave = createRowButton("SAVE", margin + buttonLight.width * 0.7, posY, w - margin * 2, rowHeight, 100);
			buttonSave.color = 0x333333;
			buttonSave.addEventListener(MouseEvent.CLICK, onClickSaveColor);

			posY += sliderR.height + gutter;

			// Nozzle color
			textSprite = new TextSprite(FontLibrary.BOOSTER_FY_REGULAR, 40, 0x000000, 1);
			textSprite.text = "LIGHTING.NOZZLE";
			textSprite.x = margin;
			textSprite.y = posY + rowHeight * 0.5 - textSprite.height * 0.45;
			addChild(textSprite);

			posY += rowHeight;

			sliderNozzleBrightness = createRowSlider("BRIGHT", margin, posY, w - margin * 2, rowHeight, 0, 255, [0x000000, 0xffffff]);
			posY += sliderNozzleBrightness.height + gutter;
			sliderNozzleBrightness.addEventListener(Slider.EVENT_POSITION_CHANGED_BY_USER, onChangedNozzleSliders);
			sliderNozzleTransition = createRowSlider("TIME MS", margin, posY, w - margin * 2, rowHeight, 0, 5000, [0xaaaaaa, 0xaaaaaa]);
			if (showTimeSliders) {
				posY += sliderNozzleTransition.height + gutter;
			} else {
				(sliderNozzleTransition.extra["container"] as Sprite).visible = false;
			}

			buttonNozzle = createRowButton("RE-APPLY", margin, posY, w - margin * 2, rowHeight);
			buttonNozzle.addEventListener(MouseEvent.CLICK, onClickApplyNozzle);
			posY += sliderR.height + gutter;

			FountainFamily.backendModel.addEventListener(BackendModel.EVENT_LIGHT_COLOR_CHANGE, onBackendLightColorChanged);
			FountainFamily.backendModel.addEventListener(BackendModel.EVENT_LIGHT_NOZZLE_BRIGHTNESS_CHANGE, onBackendLightNozzleBrightnessChanged);

			// End
			updateColorFromBackend(true);
			updateNozzleFromBackend(true);
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function updateLightCodeFromRGB(__applyToHSV:Boolean = true):void {
			buttonLight.colorR = sliderR.value/255;
			buttonLight.colorG = sliderG.value/255;
			buttonLight.colorB = sliderB.value/255;
			buttonLight.alpha = sliderBrightness.value/255;
			textLighting.text = "LIGHTING (#" + getHH(sliderBrightness.value) + " " + getHH(sliderR.value) + " " + getHH(sliderG.value) + " " + getHH(sliderB.value) + ")";
			if (__applyToHSV) updateHSVSliders();
			updateSliderBackgrounds();
		}

		private function updateHSVSliders():void {
			// Update the HSV sliders based on the value from the RGB ones
			var c:Color = Color.fromRGB(sliderR.value / 255, sliderG.value / 255, sliderB.value / 255);
			sliderH.value = c.h;
			sliderS.value = c.s * 100;
			sliderV.value = c.v * 100;
		}

		private function updateLightCodeFromHSV():void {
			var c:Color = Color.fromHSV(sliderH.value, sliderS.value / 100, sliderV.value / 100);
			sliderR.value = c.r * 255;
			sliderG.value = c.g * 255;
			sliderB.value = c.b * 255;
			updateLightCodeFromRGB(false);
		}

		private function updateSliderBackgrounds():void {
			var c:Color = Color.fromRGB(sliderR.value / 255, sliderG.value / 255, sliderB.value / 255);
			var c1:Color, c2:Color;

			c1 = c.clone();
			c2 = c.clone();
			c1.s = 0;
			c2.s = 100;
			(sliderS.extra["gradientBox"] as GradientBox).colors = [c1.toRRGGBB(), c2.toRRGGBB()];

			c1 = c.clone();
			c2 = c.clone();
			c1.v = 0;
			c2.v = 100;
			(sliderV.extra["gradientBox"] as GradientBox).colors = [c1.toRRGGBB(), c2.toRRGGBB()];
		}

		private function updateColorFromBackend(__forceImmediately:Boolean = false):void {
			var tt:Number = FountainFamily.backendModel.getLightColorTransitionTime() / 1000;
			var nc:Color = FountainFamily.backendModel.getLightColor();

			if (__forceImmediately || tt == 0) {
				sliderR.value = nc.r * 255;
				sliderG.value = nc.g * 255;
				sliderB.value = nc.b * 255;
				sliderBrightness.value = nc.a * 255;
				updateLightCodeFromRGB();
			} else {
				ZTween.add(sliderR, {value:nc.r * 255}, {time:tt});
				ZTween.add(sliderG, {value:nc.g * 255}, {time:tt});
				ZTween.add(sliderB, {value:nc.b * 255}, {time:tt});
				ZTween.add(sliderBrightness, {value:nc.a * 255}, {time:tt, onUpdate:updateLightCodeFromRGB});
			}
		}

		private function updateNozzleFromBackend(__forceImmediately:Boolean = false):void {
			var tt:Number = FountainFamily.backendModel.getLightNozzleColorTransitionTime() / 1000;
			var nb:Number = FountainFamily.backendModel.getLightNozzleBrightness();

			if (__forceImmediately || tt == 0) {
				sliderNozzleBrightness.value = nb;
				updateLightCodeFromRGB();
			} else {
				ZTween.add(sliderNozzleBrightness, {value:nb}, {time:tt, onUpdate:updateLightCodeFromRGB});
			}
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		private function onBackendLightColorChanged(__e:Event):void {
			if (!backendSuspended) updateColorFromBackend();
		}

		private function onBackendLightNozzleBrightnessChanged(__e:Event):void {
			updateNozzleFromBackend();
		}

		private function onChangedColorSlidersRGB(__e:Event):void {
			updateLightCodeFromRGB();
			onClickApplyColor(null);
		}

		private function onChangedColorSlidersHSV(__e:Event):void {
			updateLightCodeFromHSV();
			onClickApplyColor(null);
		}

		private function getHH(__value:Number):String {
			return ("00" + (Math.round(__value).toString(16))).substr(-2,2);
		}

		private function onChangedNozzleSliders(__e:Event):void {
			buttonNozzle.alpha = sliderNozzleBrightness.value/255;
			onClickApplyNozzle(null);
		}

		private function onClickApplyColor(__e:Event):void {
			backendSuspended = true;
			FountainFamily.backendModel.setLightColor(Math.round(sliderR.value), Math.round(sliderG.value), Math.round(sliderB.value), Math.round(sliderBrightness.value), Math.round(sliderTransition.value));
			backendSuspended = false;
		}

		private function onClickSaveColor(__e:Event):void {
			// Saves the current color to the current brand
			if (gpuRoot != null) {
				var beverage:Beverage = gpuRoot.debug_getCurrentBeverage();
				var currentColor:uint = (Math.round(sliderBrightness.value & 0xff) << 24) | (Math.round(sliderR.value & 0xff) << 16) | (Math.round(sliderG.value & 0xff) << 8) | Math.round(sliderB.value & 0xff);
				if (beverage != null) {
					// Beverage color
					beverage.getDesign().colorLight = currentColor;
				} else {
					// Main color
					FountainFamily.lightingInfo.colorStandby = currentColor;
				}
			}
		}

		private function onClickApplyNozzle(__e:Event):void {
			FountainFamily.backendModel.setLightNozzleBrightness(Math.round(sliderNozzleBrightness.value), Math.round(sliderNozzleTransition.value));
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function createRowButton(__caption:String, __x:Number, __y:Number, __width:Number, __height:Number, __buttonWidth:Number = 300):Box {
			var backgroundDark:Box = new Box(100, 100, 0x000000);
			backgroundDark.x = Math.round(__x + __width * 0.5 - __buttonWidth * 0.5);
			backgroundDark.y = Math.round(__y);
			backgroundDark.width = Math.round(__buttonWidth);
			backgroundDark.height = Math.round(__height);
			addChild(backgroundDark);

			var background:Box = new Box(backgroundDark.width, backgroundDark.height, 0xeeeeee);
			background.x = backgroundDark.x;
			background.y = backgroundDark.y;
			background.buttonMode = true;
			addChild(background);

			var outline:Box = new Box(background.width, background.height, 0x000000, 1);
			outline.x = background.x;
			outline.y = background.y;
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
			textSprite.x = background.x + background.width * 0.5;
			textSprite.y = background.y + background.height * 0.52;
			textSprite.mouseChildren = textSprite.mouseEnabled = false;
			addChild(textSprite);

			return background;
		}

		private function createRowSlider(__caption:String, __x:Number, __y:Number, __width:Number, __height:Number, __min:Number, __max:Number, __colors:Array):HorizontalSlider {
			var sideMarginL:Number = 120;
			var sideMarginR:Number = 90;
			var textMargin:Number = 10;

			var container:Sprite = new Sprite();
			addChild(container);

			var gradient:GradientBox = new GradientBox(100, 100, 0, __colors);
			gradient.x = Math.round(__x + sideMarginL);
			gradient.y = Math.round(__y);
			gradient.width = Math.round(__width - sideMarginL - sideMarginR);
			gradient.height = Math.round(__height);
			container.addChild(gradient);

			var slider:HorizontalSlider = new HorizontalSlider(null);
			slider.x = gradient.x;
			slider.y = gradient.y;
			slider.width = gradient.width;
			slider.height = gradient.height;
			slider.backgroundColor = 0x999999;
			slider.backgroundAlpha = 0;
			slider.pickerColor = 0xffffff;
			slider.pickerAlpha = 0.6;
			slider.pickerScale = __height / slider.width;
			slider.minValue = __min;
			slider.maxValue = __max;
			slider.value = 0;
			container.addChild(slider);

			var outline:Box = new Box(gradient.width, gradient.height, 0x000000, 1);
			outline.x = gradient.x;
			outline.y = gradient.y;
			outline.mouseChildren = outline.mouseEnabled = false;
			outline.alpha = 0.1;
			container.addChild(outline);

			var textSprite:TextSprite;

			// Caption
			textSprite = new TextSprite(FontLibrary.BOOSTER_FY_REGULAR, 25, 0x000000, 1);
			textSprite.text = __caption;
			textSprite.blockAlignVertical = TextSpriteAlign.MIDDLE;
			textSprite.x = __x;
			textSprite.y = __y + __height * 0.5;
			textSprite.width = sideMarginL - textMargin;
			textSprite.mouseChildren = textSprite.mouseEnabled = false;
			container.addChild(textSprite);

			// Value
			textSprite = new TextSprite(FontLibrary.BOOSTER_FY_REGULAR, 25, 0x000000, 1);
			textSprite.align = TextSpriteAlign.RIGHT;
			textSprite.blockAlignHorizontal = TextSpriteAlign.RIGHT;
			textSprite.blockAlignVertical = TextSpriteAlign.MIDDLE;
			textSprite.text = Math.round(slider.value).toString(10);
			textSprite.x = __x + __width;
			textSprite.y = __y + __height * 0.5;
			textSprite.width = sideMarginR - textMargin;
			textSprite.mouseChildren = textSprite.mouseEnabled = false;
			container.addChild(textSprite);

			slider.addEventListener(Slider.EVENT_POSITION_CHANGED, function(__e:Event):void {
				textSprite.text = Math.round(slider.value).toString(10);
			});

			slider.extra = {gradientBox:gradient, container:container};

			return slider;
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		override public function get width():Number {
			return _width;
		}

		override public function get height():Number {
			return _height;
		}
	}
}
