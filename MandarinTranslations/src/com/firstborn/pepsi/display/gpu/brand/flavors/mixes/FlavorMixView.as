package com.firstborn.pepsi.display.gpu.brand.flavors.mixes {
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Sprite;

	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.assets.FontLibrary;
	import com.firstborn.pepsi.data.inventory.Beverage;
	import com.firstborn.pepsi.data.inventory.Flavor;
	import com.firstborn.pepsi.display.gpu.brand.view.BrandViewOptions;
	import com.firstborn.pepsi.display.gpu.common.AnimationPlayer;
	import com.firstborn.pepsi.display.gpu.common.TextBitmap;
	import com.zehfernando.data.types.Color;
	import com.zehfernando.display.components.text.TextSpriteAlign;
	import com.zehfernando.localization.StringList;
	import com.zehfernando.transitions.Equations;
	import com.zehfernando.utils.MathUtils;
	import com.zehfernando.utils.console.warn;

	import flash.geom.Rectangle;

	/**
	 * @author zeh fernando
	 */
	public class FlavorMixView extends Sprite {

		// Properties
		private var _alignX:Number; // -1 to 1
		private var _alignY:Number; // -1 to 1
		private var _scale:Number;

		private var _width:Number;
		private var _height:Number;
		private var _visibility:Number;

		private var _orientation:String;
		private var _fontType:String;
		private var _itemType:String;
		private var _itemAlignment:String;

		// Params
		private var mixBeverage:Beverage;
		private var scaleLogo:Number;
		private var fontSize:Number;
		private var fontSizeGlueTop:Number;
		private var fontSizeGlueMid:Number;
		private var widthFruit:Number;
		private var scaleFruit:Number;
		private var itemSpacing:Number;
		private var isADA:Boolean;

		// Instances
		private var container:Sprite;
		private var logoImage:Image;
		private var logoRectangle:Rectangle;
		private var logoRectangleUsed:Rectangle;
		private var flavorTextImages:Vector.<Image>;
		private var flavorTextImagesRectangles:Vector.<Rectangle>;
		private var flavorTextGlueImages:Vector.<Image>;
		private var flavorTextGlueImagesRectangles:Vector.<Rectangle>;
		private var flavorAnimationImages:Vector.<AnimationPlayer>;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function FlavorMixView(__mixBeverage:Beverage, __fontType:String, __itemType:String, __itemAlignment:String, __orientation:String, __alignX:Number, __alignY:Number, __scale:Number, __scaleLogo:Number, __fontSize:Number, __fontSizeGlueTop:Number, __fontSizeGlueMid:Number, __widthFruit:Number, __scaleFruit:Number, __itemSpacing:Number, __isADA:Boolean) {
			super();

			_alignX = __alignX;
			_alignY = __alignY;
			_scale = __scale;
			_orientation = __orientation;
			_fontType = __fontType;
			_itemType = __itemType;
			_itemAlignment = __itemAlignment;

			mixBeverage = __mixBeverage;
			scaleLogo = __scaleLogo;
			fontSize = __fontSize;
			fontSizeGlueTop = __fontSizeGlueTop;
			fontSizeGlueMid = __fontSizeGlueMid;
			widthFruit = __widthFruit;
			scaleFruit = __scaleFruit;
			itemSpacing = __itemSpacing;
			isADA = __isADA;

			setDefaultValues();
			createElements();
			redrawElements();
			redrawVisibility();
			redrawScaleAndAlignment();
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function setDefaultValues():void {
			_visibility = 1;
			touchable = false;
		}

		private function createElements():void {
			// Main container
			container = new Sprite();
			addChild(container);

			// Target beverage logo
			//var targetBeverage:Beverage = FountainFamily.inventory.getBeverageByRecipeId(__beverageRecipeId);
			//var targetBeverageDesign:BeverageDesign = targetBeverage.getDesign(__isADA);

			var brandLogoURL:String = mixBeverage.getRelatedBrandImageLogo(isADA);
			var brandLogoScale:Number = mixBeverage.getRelatedBrandImageLogoScale(isADA);

			logoRectangle = FountainFamily.textureLibrary.getBlobLogoRectangle(brandLogoURL);
			var logoImageId:String = "BrandViewLogoImage_" + brandLogoURL;
			if (!FountainFamily.objectRecycler.has(logoImageId)) FountainFamily.objectRecycler.putNew(logoImageId, new Image(FountainFamily.textureLibrary.getBlobLogoTexture(brandLogoURL)));

			if (_orientation == BrandViewOptions.ORIENTATION_HORIZONTAL) {
				logoRectangleUsed = FountainFamily.textureLibrary.getBlobLogoRectangleUsed(brandLogoURL, 1, 0.3);
			} else {
				logoRectangleUsed = FountainFamily.textureLibrary.getBlobLogoRectangleUsed(brandLogoURL, 0.3, 1);
			}

			logoImage = FountainFamily.objectRecycler.get(logoImageId);
			logoImage.scaleX = logoImage.scaleY = 1;
			logoImage.pivotX = logoRectangle.x;
			logoImage.pivotY = logoRectangle.y;
			logoImage.scaleX = logoImage.scaleY = brandLogoScale * scaleLogo;
			container.addChild(logoImage);

			// Flavor text and image
			flavorTextGlueImages = new Vector.<Image>();
			flavorTextGlueImagesRectangles = new Vector.<Rectangle>();
			flavorTextImages = new Vector.<Image>();
			flavorTextImagesRectangles = new Vector.<Rectangle>();
			flavorAnimationImages = new Vector.<AnimationPlayer>;

			var flavorIds:Vector.<String> = mixBeverage.mixFlavorIds;
			var flavor:Flavor;
			var flavorTextImage:Image;
			var flavorTextImageId:String;
			var flavorTextImageRectangleId:String;
			var flavorTextGlueImageId:String;
			var flavorTextGlueImageRectangleId:String;
			var flavorTextGlueImage:Image;
			var flavorAnimationImage:AnimationPlayer;
			var fontName:String = _fontType == BrandViewOptions.FONT_TYPE_REGULAR ? (FountainFamily.LANGUAGES_FONTS[0] ? FontLibrary.EXTERNAL_REGULAR : FontLibrary.BOOSTER_FY_REGULAR) : (FountainFamily.LANGUAGES_FONTS[0] ? FontLibrary.EXTERNAL_LIGHT : FontLibrary.BOOSTER_NEXT_FY_LIGHT);
			var fontSizeGlue:Number;
			var fontColorGlue:int;
			var fontCaptionGlue:String;
			var prevFlavor:Flavor;
			var colorBefore:Color;
			for (var i:int = 0; i < flavorIds.length; i++) {
				flavor = FountainFamily.inventory.getFlavorById(flavorIds[i]);
				if (flavor != null) {
					// Glue text
					fontSizeGlue = i == 0 ? fontSizeGlueTop : fontSizeGlueMid;
					fontCaptionGlue = (i == 0 || _itemType == BrandViewOptions.FLAVOR_MIX_ITEM_TYPE_FRUIT) ? StringList.getList(FountainFamily.current_language).getString("brand/mixed-list-plus") : StringList.getList(FountainFamily.current_language).getString("brand/mixed-list-ampersand");
					//fontColorGlue = (_itemType == BrandViewOptions.FLAVOR_MIX_ITEM_TYPE_FRUIT ? flavor.design.colorText : (i == 0 ? mixBeverage.getDesign(isADA).colorStroke : Color.interpolateHSV(Color.fromRRGGBB(FountainFamily.inventory.getFlavorById(flavorIds[i-1]).design.colorText), Color.fromRRGGBB(flavor.design.colorText), 0.5).toRRGGBB())) & 0xffffff;
					if (i > 0) {
						colorBefore = Color.fromRRGGBB(prevFlavor == null ? flavor.design.colorText : prevFlavor.design.colorText);
						colorBefore.h -= 20;
					}
					fontColorGlue = (_itemType == BrandViewOptions.FLAVOR_MIX_ITEM_TYPE_FRUIT ? flavor.design.colorText : (i == 0 ? mixBeverage.getDesign(isADA).colorStroke : colorBefore.toRRGGBB())) & 0xffffff;

					var textRectangle:Rectangle = new Rectangle();
					flavorTextGlueImageId = "FlavorMixViewTextGlue_" + flavor.id + "_" + fontName + "_" + fontSizeGlue;
					flavorTextGlueImageRectangleId = "FlavorMixViewTextGlueRect_" + flavorTextGlueImageId;
					if (!FountainFamily.objectRecycler.has(flavorTextGlueImageId)) {
						FountainFamily.objectRecycler.putNew(flavorTextGlueImageId, new Image(TextBitmap.createTexture(fontCaptionGlue, fontName, null, fontSizeGlue, NaN, fontColorGlue, -1, 0.75, 1, -25, -25, TextSpriteAlign.CENTER, false, NaN, 0, textRectangle)));
						FountainFamily.objectRecycler.putNew(flavorTextGlueImageRectangleId, textRectangle);
					}
					flavorTextGlueImage = FountainFamily.objectRecycler.get(flavorTextGlueImageId);
					textRectangle = FountainFamily.objectRecycler.get(flavorTextGlueImageRectangleId);
					container.addChild(flavorTextGlueImage);
					flavorTextGlueImages.push(flavorTextGlueImage);
					flavorTextGlueImagesRectangles.push(textRectangle);

					// Flavor item itself
					if (_itemType == BrandViewOptions.FLAVOR_MIX_ITEM_TYPE_FRUIT) {
						// Fruit animation
						flavorAnimationImage = new AnimationPlayer();
						flavorAnimationImage.scaleX = flavorAnimationImage.scaleY = scaleFruit;
						container.addChild(flavorAnimationImage);
						flavorAnimationImages.push(flavorAnimationImage);

						// SUPER HACK - Fix later
						if (flavorIds[i] == "strawberry") flavorAnimationImage.rotation = -45 * MathUtils.DEG2RAD;

						flavorAnimationImage.playAnimation(flavor.design.animationIntro, false, true);
					} else {
						// Caption only
						textRectangle = new Rectangle();
						flavorTextImageId = "FlavorMixViewTextCaption_" + flavor.id + "_" + fontName + "_" + fontSize;
						flavorTextImageRectangleId = "FlavorMixViewTextCaptionRect_" + flavorTextImageId;
						if (!FountainFamily.objectRecycler.has(flavorTextImageId)) {
							FountainFamily.objectRecycler.putNew(flavorTextImageId, new Image(TextBitmap.createTexture(flavor.name, fontName, null, fontSize, NaN, flavor.design.colorText & 0xffffff, -1, 1, 1, -25, -25, TextSpriteAlign.CENTER, false, NaN, 0, textRectangle)));
							FountainFamily.objectRecycler.putNew(flavorTextImageRectangleId, textRectangle);
						}
						flavorTextImage = FountainFamily.objectRecycler.get(flavorTextImageId);
						textRectangle = FountainFamily.objectRecycler.get(flavorTextImageRectangleId);
						container.addChild(flavorTextImage);
						flavorTextImages.push(flavorTextImage);
						flavorTextImagesRectangles.push(textRectangle);

					}

					prevFlavor = flavor;
				} else {
					warn("Could not create flavor view for [" + flavorIds[i] + "], not in valid flavor list! Skipping...");
				}
			}
		}

		private function redrawElements():void {
			// Redraws all elements depending on sizes and orientation, and finds the size of the element (sets _width and _height)

			_width = 0;
			_height = 0;

			// Logo
			logoImage.x = 0;
			logoImage.y = 0;
			_width += logoRectangle.width * logoImage.scaleX;
			_height += logoRectangle.height * logoImage.scaleY;

			var flavorTextImage:Image;
			var flavorTextImageRectangle:Rectangle;
			var flavorTextGlueImage:Image;
			var flavorTextGlueImageRectangle:Rectangle;
			var flavorAnimationImage:AnimationPlayer;
			var spaceW:Number = _orientation == BrandViewOptions.ORIENTATION_HORIZONTAL ? itemSpacing : 0;
			var spaceH:Number = _orientation == BrandViewOptions.ORIENTATION_HORIZONTAL ? 0 : itemSpacing;
			var i:int;
			var isFirstItem:Boolean, isLastItem:Boolean;
			var isGlueTextNextToCaption:Boolean;

			for (i = 0; i < flavorTextGlueImages.length; i++) {

				isFirstItem = i == 0;
				isGlueTextNextToCaption = !isFirstItem && _itemType == BrandViewOptions.FLAVOR_MIX_ITEM_TYPE_CAPTION && _orientation == BrandViewOptions.ORIENTATION_VERTICAL;
				isLastItem = i == flavorTextGlueImages.length - 1;

				// Spacing after image, kerning style, for uneven logos (e.g. dew)
				if (i == 0) {
					if (_orientation == BrandViewOptions.ORIENTATION_HORIZONTAL) {
						_width -= (logoRectangle.width - logoRectangleUsed.right) * logoImage.scaleX;
					} else {
						_height -= (logoRectangle.height - logoRectangleUsed.bottom) * logoImage.scaleY;
					}
				}

				if (isGlueTextNextToCaption) {
					// Captions are stacked without spacing
					spaceW = 0;
					spaceH = 0;
				}


				// Spacing
				_width += spaceW;
				_height += spaceH;

				// Glue text
				if (flavorTextGlueImages.length > i) {
					flavorTextGlueImage = flavorTextGlueImages[i];
					flavorTextGlueImageRectangle = flavorTextGlueImagesRectangles[i];

					if (_orientation == BrandViewOptions.ORIENTATION_HORIZONTAL) {
						flavorTextGlueImage.x = _width - flavorTextGlueImageRectangle.x;
						flavorTextGlueImage.y = _height * 0.5 - flavorTextGlueImageRectangle.height * 0.5 - flavorTextGlueImageRectangle.y;
						_width += flavorTextGlueImageRectangle.width;
					} else {
						if (!isGlueTextNextToCaption) {
							flavorTextGlueImage.x = _width * 0.5 - flavorTextGlueImageRectangle.width * 0.5 - flavorTextGlueImageRectangle.x;
							flavorTextGlueImage.y = _height - flavorTextGlueImageRectangle.y;
							_height += flavorTextGlueImageRectangle.height;
						}
					}
				}

				// Spacing
				_width += spaceW;
				_height += spaceH;

				// Fruit image
				if (flavorAnimationImages.length > i) {
					flavorAnimationImage = flavorAnimationImages[i];
					if (_orientation == BrandViewOptions.ORIENTATION_HORIZONTAL) {
						flavorAnimationImage.x = _width + widthFruit * 0.5;
						flavorAnimationImage.y = _height * 0.5;
						_width += widthFruit;
					} else {
						flavorAnimationImage.x = _width * 0.5;
						flavorAnimationImage.y = _height + widthFruit * 0.5;
						_height += widthFruit;
					}
				}

				// Fruit name
				if (flavorTextImages.length > i) {
					flavorTextImage = flavorTextImages[i];
					flavorTextImageRectangle = flavorTextImagesRectangles[i];
					if (_orientation == BrandViewOptions.ORIENTATION_HORIZONTAL) {
						flavorTextImage.x = _width - flavorTextImageRectangle.x;
						//flavorTextImage.y = _height * 0.5 - flavorTextImageRectangle.height * 0.5 - flavorTextImageRectangle.y;
						flavorTextImage.y = _height * 0.5 - flavorTextImage.height * 0.5;
						_width += flavorTextImageRectangle.width;
					} else {
						flavorTextImage.x = _width * 0.5 - flavorTextImageRectangle.width * 0.5 - flavorTextImageRectangle.x;
						flavorTextImage.y = _height - flavorTextImageRectangle.y;
						_height += flavorTextImageRectangle.height;
					}
				}

				// Glue again, if applicable, readjusting it horizontally (and moving the previous line)
				if (isGlueTextNextToCaption) {
					var flavorTextImagePrev:Image = flavorTextImages[i-1];
					var flavorTextImageRectanglePrev:Rectangle = flavorTextImagesRectangles[i-1];
					var fullLineWidth:Number = flavorTextImageRectanglePrev.width + flavorTextGlueImageRectangle.width;

					flavorTextGlueImage.y = _height - flavorTextImageRectangle.height - flavorTextGlueImageRectangle.y - flavorTextGlueImageRectangle.height * 0.9;

					if (_itemAlignment == BrandViewOptions.FLAVOR_MIX_ITEM_ALIGNMENT_LEFT) {
						// Left aligned - ugh for magic numbers
						flavorTextImagePrev.x = _width * 0.5 - 40 - flavorTextImageRectanglePrev.x;
						flavorTextGlueImage.x = _width * 0.5 - 40 + flavorTextImageRectanglePrev.width - flavorTextGlueImageRectangle.x;

						if (isLastItem) {
							// Also aligns this line
							flavorTextImage.x = _width * 0.5 - 40 - flavorTextImageRectangle.x;
						}
					} else {
						// Center aligned
						flavorTextImagePrev.x = _width * 0.5 - fullLineWidth * 0.5 - flavorTextImageRectanglePrev.x;
						flavorTextGlueImage.x = _width * 0.5 - fullLineWidth * 0.5 + flavorTextImageRectanglePrev.width - flavorTextGlueImageRectangle.x;
					}
				} else if (isFirstItem && _itemAlignment == BrandViewOptions.FLAVOR_MIX_ITEM_ALIGNMENT_LEFT && _itemType == BrandViewOptions.FLAVOR_MIX_ITEM_TYPE_CAPTION && _orientation == BrandViewOptions.ORIENTATION_VERTICAL) {
					// Aligns first line
					flavorTextImage.x = _width * 0.5 - 40 - flavorTextImageRectangle.x;
				}
			}
		}

		private function redrawVisibility():void {
			// Animate in sequence
			var f:Number = 0.8; // Slice of the total animation dedicated to each item
			var offset:Number;

			var i:int;

			// Find all items that need to show
			var itemsToAnimate:Vector.<DisplayObject> = new Vector.<DisplayObject>();
			itemsToAnimate.push(logoImage);

			var flavorIds:Vector.<String> = mixBeverage.mixFlavorIds;

			for (i = 0; i < flavorIds.length; i++) {
				if (flavorTextImages.length > i) itemsToAnimate.push(itemsToAnimate[i]);
				if (flavorTextGlueImages.length > i) itemsToAnimate.push(flavorTextGlueImages[i]);
				if (flavorAnimationImages.length > i) itemsToAnimate.push(flavorAnimationImages[i]);
			}

			// Actual animation
			for (i = 0; i < itemsToAnimate.length; i++) {
				offset = itemsToAnimate.length > 1 ? (1-f) * (i/(itemsToAnimate.length-1)) : 0;
				itemsToAnimate[i].alpha = Equations.expoOut(MathUtils.map(_visibility, 0+offset, 0+offset+f, 0, 1, true));
				itemsToAnimate[i].visible = itemsToAnimate[i].alpha > 0;
			}

			visible = _visibility > 0;
		}

		private function redrawScaleAndAlignment():void {
			// Redraws the internal scale and alignment
			container.scaleX = container.scaleY = _scale;
			container.x = MathUtils.map(_alignX, -1, 1, 0, -_width * _scale);
			container.y = MathUtils.map(_alignY, -1, 1, 0, -_height * _scale);
		}


		// ================================================================================================================
		// PUBLIC INTERFACE ---------------------------------------------------------------------------------------------

		override public function dispose():void {
			container.removeChild(logoImage);
			FountainFamily.objectRecycler.putBack(logoImage);
			logoImage = null;

			for each (var flavorTextImage:Image in flavorTextImages) {
				container.removeChild(flavorTextImage);
				FountainFamily.objectRecycler.putBack(flavorTextImage);
			}
			flavorTextImages = null;

			for each (var flavorTextImageRectangle:Rectangle in flavorTextImagesRectangles) {
				FountainFamily.objectRecycler.putBack(flavorTextImageRectangle);
			}
			flavorTextImagesRectangles = null;

			for each (var flavorTextGlueImage:Image in flavorTextGlueImages) {
				container.removeChild(flavorTextGlueImage);
				FountainFamily.objectRecycler.putBack(flavorTextGlueImage);
			}
			flavorTextGlueImages = null;

			for each (var flavorTextGlueImageRectangle:Rectangle in flavorTextGlueImagesRectangles) {
				FountainFamily.objectRecycler.putBack(flavorTextGlueImageRectangle);
			}
			flavorTextGlueImagesRectangles = null;

			for each (var flavorAnimationImage:AnimationPlayer in flavorAnimationImages) {
				container.removeChild(flavorAnimationImage, true);
			}
			flavorAnimationImages = null;

			removeChild(container, true);
			container = null;

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

		override public function get width():Number {
			return _width;
		}

		override public function get height():Number {
			return _height;
		}

		public function get alignX():Number {
			return _alignX;
		}

		public function get alignY():Number {
			return _alignY;
		}
	}
}
