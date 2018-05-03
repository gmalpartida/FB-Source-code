package com.firstborn.pepsi.display.gpu.brand.flavors.vertical {
	import starling.display.Image;
	import starling.display.Quad;
	import starling.textures.Texture;

	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.assets.FontLibrary;
	import com.firstborn.pepsi.data.inventory.Flavor;
	import com.firstborn.pepsi.display.gpu.brand.flavors.FlavorSelectorItem;
	import com.firstborn.pepsi.display.gpu.common.AnimationPlayer;
	import com.firstborn.pepsi.display.gpu.common.PillImage;
	import com.firstborn.pepsi.display.gpu.common.TextBitmap;
	import com.firstborn.pepsi.display.gpu.common.TextureLibrary;
	import com.firstborn.pepsi.display.gpu.common.blobs.PillBitmap;
	import com.zehfernando.data.types.Color;
	import com.zehfernando.utils.MathUtils;

	import flash.display.BitmapData;

	/**
	 * @author zeh fernando
	 */
	public class FlavorSelectorVerticalItem extends FlavorSelectorItem {

		// Properties
		private var marginFlavorLeft:Number;
		private var marginFlavorIcon:Number;
		private var marginFlavorRight:Number;
		private var assumedWidthFruit:Number;
		private var fontSize:Number;
		private var fontTracking:Number;
		private var _height:Number;
		private var pillExtensionLeft:Number;
		private var pillExtensionRight:Number;
		private var drawFocusImage:Boolean;

		private var selectorImageCropLeft:Number;				// How much is "cropped" to the left of the selector (normally, in case it doesn't have animations)

		// Instances
		private var quadHit:Quad;
		private var fruitAnimations:AnimationPlayer;
		private var focusImage:Image;

		//For the language...
		private var imageName : Vector.<Image> = new Vector.<Image>(FountainFamily.MAX_LANGUAGES);
		private var selectorImage : Vector.<PillImage> = new Vector.<PillImage>(FountainFamily.MAX_LANGUAGES);



		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function FlavorSelectorVerticalItem(__language, __flavor:Flavor, __marginFlavorLeft:Number, __assumedWidthFruit:Number, __marginFlavorIcon:Number, __marginFlavorRight:Number, __fontSize:Number, __fontTracking:Number, __fruitScale:Number, __height:Number, __verticalMargin:Number, __drawFocusImage:Boolean = true) {
			super(__flavor);

			currentLanguage = __language;
			marginFlavorLeft = __marginFlavorLeft;
			marginFlavorIcon = __marginFlavorIcon;
			marginFlavorRight = __marginFlavorRight;
			assumedWidthFruit = __assumedWidthFruit;
			fontSize = __fontSize;
			fontTracking = __fontTracking;
			_height = __height;
			drawFocusImage = __drawFocusImage;

			// Create elements
			var imageId : String = "";
			var j : uint = 0;
			for(j = 0 ; j < FountainFamily.LOCALE_ISO.length; j ++) {
				imageId = "TextImageFlavorVertical_" + flavor.name.toUpperCase() + "_" + fontSize + FountainFamily.LOCALE_ISO[j];
				if (!FountainFamily.objectRecycler.has(imageId)) FountainFamily.objectRecycler.putNew(imageId, new Image(TextBitmap.createTexture(flavor.names[j].toUpperCase(), FountainFamily.LANGUAGES_FONTS[j] ? FontLibrary.EXTERNAL_REGULAR : FontLibrary.BOOSTER_FY_REGULAR, null, fontSize, NaN, 0xffffff, -1, 1, 1, fontTracking, fontTracking, null, false, NaN, 0, null, 10)));
				imageName[j] = FountainFamily.objectRecycler.get(imageId);
				imageName[j].scaleX = imageName[j].scaleY = 1;
				imageName[j].pivotY = imageName[j].height * 0.41;
				//imageName[j].x = __marginLeft;
				imageName[j].y = Math.round(height * 0.508);
				imageName[j].smoothing = FountainFamily.platform.getTextureProfile(TextureLibrary.TEXTURE_ID_GENERIC_TEXT).smoothing;
				//imageName[j].filter = BlurFilter.createDropShadow(1, Math.PI * 0.25, 0x000000, 0.3, 0, 0.5);
				//imageName[j].color = flavor.colorText;
				addChild(imageName[j]);
				imageName[j].visible = false;
			}

			imageName[currentLanguage].visible = true;

			// Selector
			pillExtensionLeft = Math.round(assumedWidthFruit * 0.52);
			pillExtensionRight = Math.round(assumedWidthFruit * 1.2);

			selectorImageCropLeft = 0;
			if (flavor.design.animationIntro.length == 0 && flavor.design.animationSelect.length == 0 && flavor.design.animationDeselect.length == 0) selectorImageCropLeft = pillExtensionLeft + assumedWidthFruit * 0.25 + marginFlavorIcon;

			var ph : int = 0;
			var pw : int = 0;
			var pillId : String = "";
			for(j = 0 ; j < FountainFamily.LOCALE_ISO.length; j ++) {
				ph = Math.round(height - __verticalMargin * 2);
				pw = Math.round(assumedWidthFruit * 0.5 + marginFlavorIcon + imageName[j].width + pillExtensionLeft + pillExtensionRight - selectorImageCropLeft);
				pillId = "PillImage_" + pw + "_" + ph + "_" + flavor.design.colorBackground + FountainFamily.LOCALE_ISO[j];
				if (!FountainFamily.objectRecycler.has(pillId)) FountainFamily.objectRecycler.putNew(pillId, new PillImage(pw, ph, 1, flavor.design.colorBackground, FountainFamily.platform.getTextureProfile("brand-flavor-selector").smoothing, FountainFamily.platform.getTextureProfile("brand-flavor-selector").format));
				selectorImage[j] = FountainFamily.objectRecycler.get(pillId);
				//selectorImage_OLD.x = __marginLeft * 0.2;
				selectorImage[j].visibility = 1;
				selectorImage[j].y = height * 0.5 - ph * 0.5;
				selectorImage[j].touchable = false;
				if (currentLanguage == j) addChildAt(selectorImage[j], 0);
			}

			// Fruit animations
			fruitAnimations = new AnimationPlayer();
			//fruitAnimations.x = __marginLeft * 0.5;
			fruitAnimations.y = height * 0.5;
			fruitAnimations.touchable = false;
			fruitAnimations.scaleX = fruitAnimations.scaleY = __fruitScale;
			addChild(fruitAnimations);

			fruitAnimations.playAnimation(flavor.design.animationIntro, false, true);

			// Focus border
			if (drawFocusImage) {
				var pillFocusId:String = "PillFocusImage_" + pw + "_" + ph;
				if (!FountainFamily.objectRecycler.has(pillFocusId)) {
					var focusBitmap:BitmapData = new PillBitmap(pw, ph, 5, FountainFamily.adaInfo.hardwareFocusBorderWidth, FountainFamily.adaInfo.hardwareFocusFilters);
					var focusTexture:Texture = Texture.fromBitmapData(focusBitmap, false, false, 1, FountainFamily.platform.getTextureProfile("brand-flavor-focus").format);
					FountainFamily.objectRecycler.putNew(pillFocusId, new Image(focusTexture));
				}
				focusImage = FountainFamily.objectRecycler.get(pillFocusId);
				//focusImage.x = selectorImage_OLD.x;
				focusImage.y = selectorImage[0].y;
				focusImage.color = FountainFamily.adaInfo.hardwareFocusBorderColor.toRRGGBB();
				focusImage.smoothing = FountainFamily.platform.getTextureProfile("brand-flavor-focus").smoothing;
				focusImage.touchable = false;
				addChild(focusImage);
			}

			// Hit quad
			quadHit = new Quad(64, 64, 0x000000);
			quadHit.x = -pillExtensionLeft;
			quadHit.y = 0;
			quadHit.width = selectorImage[0].width;
			quadHit.height = height;
			quadHit.alpha = FountainFamily.DEBUG_DRAW_HIT_AREAS ? 0.1 : 0;
			addChild(quadHit);

			redrawFocused();
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		override protected function redrawAvailable():void {
			redrawVisibility();
		}

		override protected function redrawEnabledPhase():void {
			redrawVisibility();
		}

		override protected function redrawSelectedPhase():void {
			for(var j : uint = 0; j < FountainFamily.LOCALE_ISO.length; j ++) {
				selectorImage[j].visibility = _selectedPhase;
				imageName[j].color = Color.interpolateRRGGBB(flavor.design.colorTextSelected, flavor.design.colorText, _selectedPhase);
			}

//			redrawScale();
		}

		override protected function redrawPressedPhase():void {
			for(var j : uint = 0; j < FountainFamily.LOCALE_ISO.length; j ++) if (imageName[j] != null) imageName[j].scaleX = imageName[j].scaleY = MathUtils.map(_pressedPhase * _enabledPhase, 0, 1, 1, 0.9);

		}

		override protected function redrawVisibility():void {
			alpha = MathUtils.map(_visibility, 0, 1, 0.5, 1, true) * MathUtils.map(_enabledPhase, 0, 1, flavor.design.opacityDisabled, 1) * MathUtils.map(_available, 0, 1, flavor.design.opacityDisabled, 1);
			visible = _visibility > 0;
			for(var j : uint = 0; j < FountainFamily.LOCALE_ISO.length; j ++) {
				imageName[j].x = MathUtils.map(_visibility, 0, 1, -imageName[j].width, assumedWidthFruit + marginFlavorIcon);
				selectorImage[j].x = MathUtils.map(_visibility, 0, 1, -selectorImage[j].width, -pillExtensionLeft + selectorImageCropLeft);
			}
			fruitAnimations.x = MathUtils.map(_visibility, 0, 1, -assumedWidthFruit * 2, assumedWidthFruit * 0.5);
			if (drawFocusImage) focusImage.x = selectorImage[0].x;
		}

//		override protected function redrawScale():void {
//			//if (imageFruit != null) imageFruit.scaleX = imageFruit.scaleY = MathUtils.map(Equations.backInOut(_selectedPhase), 0, 1, 1, 1.2) * _scale * FountainFamily.platform.densityScale;
//			imageName_OLD.scaleX = imageName_OLD.scaleY = _scale * 0.25 + 0.75;
//		}

		override protected function redrawFocused():void {
			if (focusImage != null) {
				focusImage.alpha = keyboardFocused;
				focusImage.visible = keyboardFocused > 0;
			}
			super.redrawFocused();
		}

		override protected function animatedSelectedChanged():void {
			super.animatedSelectedChanged();

			if (isSelected) {
				fruitAnimations.playAnimation(flavor.design.animationSelect, false, true);
			} else {
				fruitAnimations.playAnimation(flavor.design.animationDeselect, false, true);
			}
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		override public function set language(value : uint) : void {
			super.language = value;
			for(var j : uint = 0; j < FountainFamily.LOCALE_ISO.length; j ++) {
				if(imageName[j] != null) imageName[j].visible = false;
				removeChild(selectorImage[j]);
			}
			if(imageName[value] != null) imageName[value].visible = false;
			addChildAt(selectorImage[value], 0);
		}

		public function getLeftCrop():Number {
			// Returns the amount of inner cropping (negative padding) that is taking place
			return selectorImageCropLeft;
		}

		override public function dispose():void {
			for(var j : uint = 0; j < FountainFamily.LOCALE_ISO.length; j ++) {
				removeChild(selectorImage[j]);
				FountainFamily.objectRecycler.putBack(selectorImage[j]);
				selectorImage[j] = null;

				removeChild(imageName[j]);
				FountainFamily.objectRecycler.putBack(imageName[j]);
				imageName[j] = null;
			}


			if (drawFocusImage) {
				removeChild(focusImage);
				FountainFamily.objectRecycler.putBack(focusImage);
				focusImage = null;
			}

			removeChild(fruitAnimations, true);
			fruitAnimations = null;

			removeChild(quadHit, true);
			quadHit = null;

			super.dispose();
		}

		override public function get width():Number {
			return assumedWidthFruit + marginFlavorIcon + imageName[currentLanguage].texture.nativeWidth;
		}

		override public function get height():Number {
			return _height;
		}
	}
}
