package com.firstborn.pepsi.display.gpu.brand.view {
import com.firstborn.pepsi.application.FountainFamily;
import com.firstborn.pepsi.application.FountainFamily;
import com.firstborn.pepsi.application.FountainFamily;
import com.firstborn.pepsi.application.FountainFamily;
import com.firstborn.pepsi.data.Calories;

import starling.display.BlendMode;
	import starling.display.Image;
	import starling.display.Sprite;

	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.assets.FontLibrary;
	import com.firstborn.pepsi.assets.ImageLibrary;
	import com.firstborn.pepsi.common.backend.BackendModel;
	import com.firstborn.pepsi.data.inventory.Beverage;
	import com.firstborn.pepsi.data.inventory.BeverageDesign;
	import com.firstborn.pepsi.data.inventory.Flavor;
	import com.firstborn.pepsi.display.flash.TestingOverlay;
	import com.firstborn.pepsi.display.gpu.brand.flavors.FlavorSelector;
	import com.firstborn.pepsi.display.gpu.brand.flavors.FlavorSelectorItem;
	import com.firstborn.pepsi.display.gpu.brand.flavors.mixes.FlavorMixView;
	import com.firstborn.pepsi.display.gpu.brand.flavors.vertical.FlavorSelectorVertical;
	import com.firstborn.pepsi.display.gpu.brand.liquid.LiquidView;
	import com.firstborn.pepsi.display.gpu.brand.particles.ParticleCreator;
	import com.firstborn.pepsi.display.gpu.brand.particles.ParticleCreatorFactoryCircle;
	import com.firstborn.pepsi.display.gpu.brand.particles.ParticleCreatorFactoryLine;
	import com.firstborn.pepsi.display.gpu.common.AnimationPlayer;
	import com.firstborn.pepsi.display.gpu.common.BlobButtonStyle;
	import com.firstborn.pepsi.display.gpu.common.TextBitmap;
	import com.firstborn.pepsi.display.gpu.common.components.BlobButton;
	import com.firstborn.pepsi.display.gpu.common.components.BlobButtonLayer;
	import com.firstborn.pepsi.display.gpu.home.view.HomeView;
	import com.zehfernando.data.types.Color;
	import com.zehfernando.display.components.text.TextSpriteAlign;
	import com.zehfernando.localization.StringList;
	import com.zehfernando.signals.SimpleSignal;
	import com.zehfernando.transitions.Equations;
	import com.zehfernando.utils.DelayedCalls;
	import com.zehfernando.utils.MathUtils;
	import com.zehfernando.utils.RandomGenerator;
	import com.zehfernando.utils.console.warn;

	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	/**
	 * @author zeh fernando
	 */
	public class BrandView extends Sprite {

		private static var currentLanguage : uint = 0;

		// Properties
		private var _visibility:Number;
		private var isPouringBeverage:Boolean;
		private var _isHiding:Boolean;

		private var alphaText:Number;

		// Instances
		private var _onTappedBack:SimpleSignal;
		private var _beverage:Beverage;

		private var logoImage:Image;
		private var logoRectangle:Rectangle;
		private var buttonPour:BlobButton;
		private var buttonBack:BlobButton;
		private var liquidView:LiquidView;
		private var flavorSelector:FlavorSelector;
		private var flavorMixView:FlavorMixView;
		private var animation:AnimationPlayer;
		private var sponsorLogoImage:Image;
		private var sponsorLogoRectangle:Rectangle;
		private var sponsorTextImage:Image;

		private var particleCreator:ParticleCreator;

		private var options:BrandViewOptions;							// Visual options

		//These vectors contains the titles for all the languages
		private var imageTextTitleLine1: Vector.<Image> = new Vector.<Image>(10);
		private var imageTextTitleLine2: Vector.<Image> = new Vector.<Image>(10);

        //These vectors contains the calories
        private var imageTextCalories1 : Vector.<Image> = new Vector.<Image>(10);
        private var imageTextCalories2 : Vector.<Image> = new Vector.<Image>(10);

        //Hack to place the text of the flavors.
        private var flavorsCaloriesCopy : Image;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function BrandView(__options:BrandViewOptions, __beverageId:String, __language: uint = 0) {

			currentLanguage = __language;

			_beverage = FountainFamily.inventory.getBeverageById(__beverageId);

			_visibility = 0;
			options = __options;

			_onTappedBack = new SimpleSignal();

			// Create all assets

			var i:uint;

			var blobButton:BlobButton;
			var beverageDesign:BeverageDesign = _beverage.getDesign(options.isADA);
			var mixLayout:String = beverageDesign.mixLayout;

			// Liquid
			if (options.liquidLayout != BrandViewOptions.LIQUID_LAYOUT_NONE && !FountainFamily.DEBUG_DO_NOT_CREATE_LIQUID_VIEWS) {
				liquidView = new LiquidView(options.liquidLayout, _beverage, _beverage.getDesign().colorStrokeBrand, options.width, options.height, options.liquidOffsetX, options.liquidOffsetY, options.liquidPouredOffsetY);
				addChild(liquidView);
			}

			// Animation
			if (beverageDesign.animationId != null && beverageDesign.animationId.length > 0) {
				//var animationDef:AnimationDefinition = AnimationDefinition.getAnimationDefinition(beverageDesign.animationId, FountainFamily.animationDefinitions);
				animation = new AnimationPlayer();
				animation.scale = beverageDesign.animationScale;
				animation.blendMode = BlendMode.MULTIPLY;
				animation.x = width + beverageDesign.animationOffsetX;
				animation.alignX = 1;
				animation.alignY = options.animationPivotY;
				animation.y = Math.round(options.animationY + beverageDesign.animationOffsetY);
				animation.touchable = false;
				animation.cropMargin = 0.5; // Some animations are bleeding
				addChild(animation);
				animation.playAnimation(beverageDesign.animationId, true);
			}

			// Particles
			if (beverageDesign.particlesPerSecond > 0 && options.liquidParticles) {
				if (liquidView != null) {
					// Particles start from liquid view
					particleCreator = new ParticleCreator(new ParticleCreatorFactoryCircle(globalToLocal(FountainFamily.platform.getScaledPoint(liquidView.getMaskCenter())), liquidView.getMaskRadius()), beverageDesign.particlesPerSecond, beverageDesign.particlesSizeScale, beverageDesign.particlesSpeedScale, beverageDesign);
				} else {
					// Particles in a line starting from the center, aligned with the middle of the screen (logo)
					particleCreator = new ParticleCreator(new ParticleCreatorFactoryLine(new Point(0, height * 0.5), new Point(width, height * 0.5), height * 0.5), beverageDesign.particlesPerSecond, beverageDesign.particlesSizeScale, beverageDesign.particlesSpeedScale, beverageDesign);
				}
				addChild(particleCreator);
			}

			// Logo
			logoRectangle = FountainFamily.textureLibrary.getBlobLogoRectangle(beverageDesign.imageLogoBrand);

			var logoAlignY:Number = options.logoAlignY.getValue(beverageDesign.mixLayout);
			var logoImageId:String = "BrandViewLogoImage_" + beverageDesign.imageLogoBrand;
			if (!FountainFamily.objectRecycler.has(logoImageId)) FountainFamily.objectRecycler.putNew(logoImageId, new Image(FountainFamily.textureLibrary.getBlobLogoTexture(beverageDesign.imageLogoBrand)));

			logoImage = FountainFamily.objectRecycler.get(logoImageId);
			logoImage.scaleX = logoImage.scaleY = 1;
			logoImage.pivotX = logoRectangle.x;
			logoImage.pivotY = logoRectangle.y + MathUtils.map(logoAlignY, -1, 1, 0, logoRectangle.height);
			logoImage.scaleX = logoImage.scaleY = beverageDesign.scaleLogoBrand;
			addChild(logoImage);

			// Resize logo if it doesn't seem to really fit the screen - this is needed because the design values sometimes are way off
			var logoTop:Number = getTargetLogoY() - MathUtils.map(logoAlignY, -1, 1, 0, logoRectangle.height) * beverageDesign.scaleLogoBrand;
			if (logoTop < 0 && logoAlignY > -1) {
				logoImage.scaleX = logoImage.scaleY = getTargetLogoY() / MathUtils.map(logoAlignY, -1, 1, 0, logoRectangle.height);
				warn("Logo top less than 0! Resizing to scale: original scale was " + beverageDesign.scaleLogoBrand + ", using " + logoImage.scaleY + " instead.");
			}

			// Text
            // Don't like that the second conditional is hardcoded.
            var bobcatMode : Boolean = FountainFamily.platform.id == "bobcat";

			if (!beverage.isMix || bobcatMode) {
				var colorTextNormal:uint = beverageDesign.colorTextNormalBrand;
				var colorTextStrong:uint = beverageDesign.colorTextStrongBrand;
				alphaText = Color.fromAARRGGBB(colorTextNormal).a;

				var hiddenSelectedFlavors:int = getNumberOfHiddenSelectedFlavors();
				var numMaxFlavors:int = Math.min(_beverage.maxFlavors - hiddenSelectedFlavors, FountainFamily.inventory.getFlavorsById(_beverage.flavorIds).length - hiddenSelectedFlavors);

				if (options.titleInTwoLines) {

					var logoImageTextTitle1:String = "";
					var logoImageTextTitle2:String = "";
					var titleText1 : String = "";
					var titleText2 : String = "";

					for(i = 0; i < FountainFamily.LOCALE_ISO.length; i ++) {
						logoImageTextTitle1 = "BrandViewImageTitle_" + numMaxFlavors + "_" + colorTextNormal + "_" + options.fontSizeTitle + FountainFamily.LOCALE_ISO[i];
						titleText1 = StringList.getList(FountainFamily.LOCALE_ISO[i]).getString("brand/title-top-1");
						if (!FountainFamily.objectRecycler.has(logoImageTextTitle1)) FountainFamily.objectRecycler.putNew(logoImageTextTitle1, new Image(TextBitmap.createTexture(titleText1.split("[[flavors]]").join(numMaxFlavors), FontLibrary.BOOSTER_FY_REGULAR, null, options.fontSizeTitle, NaN, colorTextNormal & 0xffffff, -1, 1, 1, -25, -25, TextSpriteAlign.CENTER, false)));
						imageTextTitleLine1[i] = FountainFamily.objectRecycler.get(logoImageTextTitle1);
						if(numMaxFlavors > 0) addChild(imageTextTitleLine1[i]);
						imageTextTitleLine1[i].visible = false;

						logoImageTextTitle2 = "BrandViewImageTitle_" + numMaxFlavors + "_" + colorTextStrong + "_" + options.fontSizeTitleEmphasis + FountainFamily.LOCALE_ISO[i];
						titleText2 = StringList.getList(FountainFamily.LOCALE_ISO[i]).getString("brand/title-top-2");
						if (!FountainFamily.objectRecycler.has(logoImageTextTitle2)) FountainFamily.objectRecycler.putNew(logoImageTextTitle2, new Image(TextBitmap.createTexture(titleText2.split("[[flavors]]").join(numMaxFlavors), FontLibrary.BOOSTER_FY_REGULAR, null, options.fontSizeTitleEmphasis, NaN, colorTextStrong & 0xffffff, -1, 1, 1, -25, -25, TextSpriteAlign.CENTER, false)));
						imageTextTitleLine2[i] = FountainFamily.objectRecycler.get(logoImageTextTitle2);
                        if(numMaxFlavors > 0) addChild(imageTextTitleLine2[i]);
						imageTextTitleLine2[i].visible = false;
					}

					imageTextTitleLine1[currentLanguage].visible = true;
					imageTextTitleLine2[currentLanguage].visible = true;

				} else {

					var logoImageTextTitle : String = "";
					var titleText : String = "";
                    alphaText = 1;

                    //For the Bobcat prototype there's only one flavor expected (the first one will be the one used);
                    var bobcatFlavor : Boolean = (beverage.mixFlavorIds.length > 0 && bobcatMode);

					for(i = 0; i < FountainFamily.LOCALE_ISO.length; i ++) {

                        var beverageFlavor : String = "";

                        if(bobcatFlavor) for(var s :int = 0; s < beverage.mixFlavorIds.length; s ++) {
                            beverageFlavor += FountainFamily.inventory.getFlavorById(beverage.mixFlavorIds[s]).names[i].toLowerCase();
                            if(s < beverage.mixFlavorIds.length - 1) beverageFlavor += " ";
                        }

                        var beverageFlavorCopy : String = bobcatMode ? beverageFlavor : String(numMaxFlavors);

                        var fontType : String = FontLibrary.BOOSTER_FY_REGULAR;
                        switch(options.fontTypeFlavorCopy) {
                            case BrandViewOptions.FONT_TYPE_BOLD:
                                fontType = FontLibrary.BOOSTER_NEXT_FY_BOLD;
                                break;
                            case BrandViewOptions.FONT_TYPE_LIGHT:
                                fontType = FontLibrary.BOOSTER_NEXT_FY_LIGHT;
                                break;
                        }

						logoImageTextTitle = "BrandViewImageTitle_" + numMaxFlavors + "_" + colorTextNormal + "_" + colorTextStrong + "_" + options.fontSizeTitle + "_" + options.fontSizeTitleEmphasis + "_" + options.titleInTwoLines + FountainFamily.LOCALE_ISO[i];
						titleText = StringList.getList(FountainFamily.LOCALE_ISO[i]).getString("brand/title-top-1") + " " + StringList.getList(FountainFamily.LOCALE_ISO[i]).getString("brand/title-top-2");

                        var tracking : Number = FountainFamily.platform.id == "bobcat" ? 20 : -25;
						if (!FountainFamily.objectRecycler.has(logoImageTextTitle)) FountainFamily.objectRecycler.putNew(logoImageTextTitle, new Image(TextBitmap.createTexture(titleText.split("[[flavors]]").join(beverageFlavorCopy), fontType, null, options.fontSizeTitle, NaN, colorTextNormal & 0xffffff, colorTextStrong & 0xffffff, 1, 1, tracking, tracking, TextSpriteAlign.CENTER, false, NaN, 0, null, 5)));
						imageTextTitleLine1[i] = FountainFamily.objectRecycler.get(logoImageTextTitle);
                        if(numMaxFlavors > 0 || (bobcatMode && beverageFlavor != "")) addChild(imageTextTitleLine1[i]);
						imageTextTitleLine1[i].visible = false;
					}

					imageTextTitleLine1[currentLanguage].visible = true;
				}
			}

            //Calories text ...The static variables should be defined in the FountainFamily class?
            if(Calories.CALORIES_ACTIVE) {

                var caloriesAsset:String = "";
                var caloriesText:String = "";
                var caloriesFontSizes : Array = String(options.fontSizeCalories).split(",");
                var caloriesFontSize : uint = caloriesFontSizes[Calories.CUPS.length - 1];
                var caloriesColor :uint = __options.isADA ? colorTextNormal & 0xffffff : beverageDesign.caloriesColor;

                for(i = 0; i < Calories.CUPS.length; i ++) {
                    caloriesText = String(Calories.CUPS[i].id).toUpperCase() + " " + Calories.CUPS[i].size + " " + String(Calories.CUPS_MEASUREMENT).toUpperCase();
                    caloriesAsset = "CaloriesImageTitle_#ffffff_" + String(Calories.CUPS[i].id).toUpperCase() + "_" + Calories.CUPS[i].size + "_" + String(Calories.CUPS_MEASUREMENT).toUpperCase() + "_" + caloriesColor;
                    if (!FountainFamily.objectRecycler.has(caloriesAsset)) FountainFamily.objectRecycler.putNew(caloriesAsset, new Image(TextBitmap.createTexture(caloriesText, FontLibrary.BOOSTER_NEXT_FY_BOLD, null, caloriesFontSize, NaN, caloriesColor, caloriesColor, 1, 1, -25, -25, TextSpriteAlign.RIGHT)));
                    imageTextCalories1[i] = FountainFamily.objectRecycler.get(caloriesAsset);
                    addChild(imageTextCalories1[i]);

                    var caloriesValue : Number = _beverage.calories * Calories.CUPS[i].size * Calories.MEASUREMENT_CONVERSION;
                    //caloriesValue = Math.floor(caloriesValue * 1000) / 1000;
                    //Based on the new FDA regulations
                    //if calories are below 5 the machine should display 0.
                    //if calories are between 5 to 50 the machine should round to nearest 5
                    //if calories are over 50 the machine should round to nearest 10.
                    trace("the calories are: " + caloriesValue);
                    var partialCalories : Number= caloriesValue;
                    if(caloriesValue < 5) caloriesValue = 0;
                    else {
                        var units : Number = caloriesValue % 10;
                        caloriesValue -= units;

                        //Rounding to the nearest 10 for calories over 50
                        if(partialCalories > 50 && units >= 5) caloriesValue += 10;

                        //Rounding to nearest 5 for calories between 5 and 50
                        if(partialCalories >= 5 && partialCalories <= 50) {
                            if(units > 2.5 && units <= 7.5 )  caloriesValue += 5;
                            if(units > 7.5) caloriesValue += 10;
                        }

                    }

                    caloriesText = String(caloriesValue) + " CAL";
                    caloriesAsset = "CaloriesImageTitle_#ffffff_" + String(partialCalories) + "_CAL" + "_" + caloriesColor;
                    if (!FountainFamily.objectRecycler.has(caloriesAsset)) FountainFamily.objectRecycler.putNew(caloriesAsset, new Image(TextBitmap.createTexture(caloriesText, FontLibrary.BOOSTER_NEXT_FY_BOLD, null, caloriesFontSize, NaN, caloriesColor, caloriesColor, 1, 1, -25, -25, TextSpriteAlign.RIGHT)));
                    imageTextCalories2[i] = FountainFamily.objectRecycler.get(caloriesAsset);
                    addChild(imageTextCalories2[i]);

                    imageTextCalories1[i].alpha = 0;
                    imageTextCalories2[i].alpha = 0;

                }

                //For the flavor calories copy
                logoImageTextTitle = "FLAVOR_SHOTS_HAVE_ZERO_CALORIES";
                titleText = StringList.getList(FountainFamily.LOCALE_ISO[0]).getString("brand/calories-flavors");
                if (!FountainFamily.objectRecycler.has(logoImageTextTitle)) FountainFamily.objectRecycler.putNew(logoImageTextTitle, new Image(TextBitmap.createTexture(titleText, FontLibrary.BOOSTER_FY_REGULAR, null, options.fontSizeFlavorCalories, NaN, colorTextNormal & 0xffffff, colorTextStrong & 0xffffff, 1, 1, -25, -25, TextSpriteAlign.CENTER, false, NaN, 0, null, 5)));
                flavorsCaloriesCopy = FountainFamily.objectRecycler.get(logoImageTextTitle);
                if(numMaxFlavors > 0) addChild(flavorsCaloriesCopy);
            }



			// Sponsor logo
			if (beverageDesign.imageLogoFlavorSponsor.length > 0) {
				sponsorLogoRectangle = FountainFamily.textureLibrary.getBlobLogoRectangle(beverageDesign.imageLogoFlavorSponsor);

				var sponsorLogoImageId:String = "BrandViewSponsorLogoImage_" + beverageDesign.imageLogoFlavorSponsor;
				if (!FountainFamily.objectRecycler.has(sponsorLogoImageId)) FountainFamily.objectRecycler.putNew(sponsorLogoImageId, new Image(FountainFamily.textureLibrary.getBlobLogoTexture(beverageDesign.imageLogoFlavorSponsor)));

				sponsorLogoImage = FountainFamily.objectRecycler.get(sponsorLogoImageId);
				sponsorLogoImage.scaleX = sponsorLogoImage.scaleY = 1;
				sponsorLogoImage.pivotX = sponsorLogoRectangle.x;
				sponsorLogoImage.pivotY = sponsorLogoRectangle.y;
				addChild(sponsorLogoImage);

				// Resize to fit
				var sponsorAreaRect:Rectangle = getTargetSponsorLogoRect();
				var sar:Number = sponsorAreaRect.width / sponsorAreaRect.height;
				var lar:Number = sponsorLogoRectangle.width / sponsorLogoRectangle.height;
				if (sar > lar) {
					// Available rect is wider, fit by height
					sponsorLogoImage.scaleX = sponsorLogoImage.scaleY = sponsorAreaRect.height / sponsorLogoImage.texture.height;
				} else {
					// Available rect is taller, fit by width
					sponsorLogoImage.scaleX = sponsorLogoImage.scaleY = sponsorAreaRect.width / sponsorLogoImage.texture.width;
				}

				if (beverage.isMix) {
					// Also need the text
					var sponsorTextColor:uint = beverageDesign.colorTextNormalBrand;
					var sponsorTextAlpha:Number = Color.fromAARRGGBB(sponsorTextColor).a;
					var sponsorFontSizeMix:Number = options.fontSizeSponsorMix.getValue(mixLayout);
					var sponsorTextImageId:String = "SponsorText_" + sponsorTextColor + "_" + sponsorFontSizeMix;
					var sponsorText:String = StringList.getList(FountainFamily.LOCALE_ISO[0]).getString("brand/sponsors-prefix");
					if (!FountainFamily.objectRecycler.has(sponsorTextImageId)) FountainFamily.objectRecycler.putNew(sponsorTextImageId, new Image(TextBitmap.createTexture(sponsorText, FontLibrary.BOOSTER_NEXT_FY_BOLD, null, sponsorFontSizeMix, NaN, sponsorTextColor, -1, sponsorTextAlpha, 1, -25, -25, TextSpriteAlign.CENTER, false)));
					sponsorTextImage = FountainFamily.objectRecycler.get(sponsorTextImageId);
					addChild(sponsorTextImage);
				}
			}

			// Flavor list
			if (!beverage.isMix) {

				flavorSelector = new FlavorSelectorVertical(currentLanguage, _beverage.flavorIds, _beverage.hiddenFlavorIds, _beverage.maxFlavors, options.marginFlavorLeft, options.assumedWidthFruits, options.marginFlavorIcon, options.marginFlavorRight, options.width, options.numColsFlavor, options.fontSizeFlavor, options.fontTrackingFlavor, options.scaleFruits, options.invisibleFruitsRedistributesButtons, options.heightFlavorItem, options.marginFlavorItem, options.allowKeyboardFocus);
				flavorSelector.x = 0;
				flavorSelector.y = options.marginTitleFromTop + imageTextTitleLine1[0].height + (imageTextTitleLine2[0] == null ? 0 : imageTextTitleLine2[0].height) + options.marginFlavorsFromTitle;
				//flavorSelector.y = imageTextTitle.y + imageTextTitle.height + MARGIN_FLAVORS_FROM_TITLE * ds;
				flavorSelector.onChangedSelection.add(onChangedFlavorSelection);
				addChild(flavorSelector);

				// Pre-select flavors
				flavorSelector.selectItemsById(_beverage.preselectedFlavorIds, true);

				// Lock flavors
				flavorSelector.lockItemsById(_beverage.lockedFlavorIds, true);

				if (options.allowKeyboardFocus) {
					var orderedFlavorItems:Vector.<FlavorSelectorItem> = flavorSelector.getOrderedItems();
					for (i = 0; i < orderedFlavorItems.length; i++) {
						FountainFamily.focusController.addElement(orderedFlavorItems[i]);
					}
				}
			} else {
				flavorMixView = new FlavorMixView(_beverage, options.fontTypeMix.getValue(mixLayout), options.flavorMixItemType.getValue(mixLayout), options.flavorMixItemAlignment.getValue(mixLayout), options.flavorMixOrientation.getValue(mixLayout), 0, options.flavorMixAlignY.getValue(mixLayout), options.flavorMixScale.getValue(mixLayout), options.flavorMixScaleLogo.getValue(mixLayout), options.fontSizeFlavorMix.getValue(mixLayout), options.fontSizeFlavorGlueTopMix.getValue(mixLayout), options.fontSizeFlavorGlueMidMix.getValue(mixLayout), options.assumedWidthFruits / options.scaleFruits * options.flavorMixScaleFruit.getValue(mixLayout), options.flavorMixScaleFruit.getValue(mixLayout), options.flavorMixItemSpacing.getValue(mixLayout), options.isADA);
				addChild(flavorMixView);
			}

			// Pour button
			var languagesStrings : Vector.<String> = new Vector.<String>();
			var j : uint = 0;
			for(j = 0; j < FountainFamily.LOCALE_ISO.length; j ++) languagesStrings.push(StringList.getList(FountainFamily.LOCALE_ISO[j]).getString("brand/button-pour"));
			var pourButtonStyle:BlobButtonStyle = options.buttonPourStyle;
			var buttonPourId:String = "BrandViewTower_buttonPour_" + beverageDesign.colorPourFill + "_" + beverageDesign.colorPourStroke;
			if (!FountainFamily.objectRecycler.has(buttonPourId)) {
				if (options.isADA) {
					// Colors come from ADA pour button colors
					blobButton = new BlobButton(
						pourButtonStyle.radius,
						languagesStrings,
						BlobButtonLayer.getSolidStrokeBlobsFromColors(beverageDesign.colorPourFill, beverageDesign.colorPourStroke, pourButtonStyle.strokeWidths, beverageDesign.scalePour),
						0xffffff, 0xffffff,
						pourButtonStyle.fontSize,
						pourButtonStyle.fontEmphasisSize,
						pourButtonStyle.fontBold,
						pourButtonStyle.fontEmphasisBold,
						pourButtonStyle.fontAlpha,
						pourButtonStyle.fontEmphasisAlpha,
						pourButtonStyle.fontTracking,
						pourButtonStyle.fontEmphasisTracking,
						pourButtonStyle.fontLeading,
						false,
						TextSpriteAlign.CENTER,
						new ImageLibrary.ICON_POUR(),
						0xffffff,
						pourButtonStyle.iconScale,
						options.allowKeyboardFocus
					);
				} else {
					// Colors come from specific pour button colors

                    //change the color of the pour copy if it's bobcat
                    var pourFontColor : int = FountainFamily.platform.id == "bobcat" ? FountainFamily.platform.mainColorInterface : 0xffffff;

					blobButton = new BlobButton(
						pourButtonStyle.radius,
						languagesStrings,
						BlobButtonLayer.getSolidStrokeBlobsFromColors(beverageDesign.colorPourFill, beverageDesign.colorPourStroke, pourButtonStyle.strokeWidths, beverageDesign.scalePour),
                        pourFontColor, pourFontColor,
						pourButtonStyle.fontSize,
						pourButtonStyle.fontEmphasisSize,
						pourButtonStyle.fontBold,
						pourButtonStyle.fontEmphasisBold,
						pourButtonStyle.fontAlpha,
						pourButtonStyle.fontEmphasisAlpha,
						pourButtonStyle.fontTracking,
						pourButtonStyle.fontEmphasisTracking,
						pourButtonStyle.fontLeading,
						false,
						TextSpriteAlign.CENTER,
						new ImageLibrary.ICON_POUR(),
						FountainFamily.platform.id == "bobcat" ? 0xff5859 : 0xffffff,
						pourButtonStyle.iconScale,
						options.allowKeyboardFocus
					);
				}
				FountainFamily.objectRecycler.putNew(buttonPourId, blobButton);
				blobButton = null;
			}

			buttonPour = FountainFamily.objectRecycler.get(buttonPourId);
			buttonPour.recycle();
			buttonPour.start();
			buttonPour.x = options.width * 0.5;
			buttonPour.y = options.height - pourButtonStyle.margin - buttonPour.radius;
			buttonPour.onPressed.add(onButtonPourPressed);
			buttonPour.onReleased.add(onButtonPourReleased);
			buttonPour.onPressCanceled.add(onButtonPourReleased);
			addChild(buttonPour);

			if (options.allowKeyboardFocus) FountainFamily.focusController.addElement(buttonPour);

			var buttonStyle:BlobButtonStyle = options.buttonBackStyle;

			// Back button
			languagesStrings.length = 0;
			for(j = 0; j < FountainFamily.LOCALE_ISO.length; j ++) languagesStrings.push(StringList.getList(FountainFamily.LOCALE_ISO[j]).getString("brand/button-back"));
			var buttonBackId:String = "BrandViewTower_buttonBack_" + (options.buttonBackColorsNeutral ? "_neutral" : beverageDesign.colorButtonsFill + "_" + beverageDesign.colorButtonsStroke) + "_" + options.allowKeyboardFocus;
			if (!FountainFamily.objectRecycler.has(buttonBackId)) {
				if (options.buttonBackColorsNeutral) {
					// Neutral colors (ADA)
					blobButton = new BlobButton(
						buttonStyle.radius,
						languagesStrings,
						[
							BlobButtonLayer.getStrokeBlob(HomeView.COLOR_BUTTON_STROKES_NEUTRAL, 0.8, BlobButton.STROKE_WIDTH_SMALL_THIN),
							BlobButtonLayer.getSolidStrokeBlob(HomeView.COLOR_BUTTON_FILL_COLOR, 1, FountainFamily.platform.mainColorInterface, 1, buttonStyle.strokeWidths[0])
						],
						BlobButton.COLOR_TEXT_NEUTRAL,
						FountainFamily.platform.mainColorInterface,
						buttonStyle.fontSize,
						buttonStyle.fontEmphasisSize,
						buttonStyle.fontBold,
						buttonStyle.fontEmphasisBold,
						buttonStyle.fontAlpha,
						buttonStyle.fontEmphasisAlpha,
						buttonStyle.fontTracking,
						buttonStyle.fontEmphasisTracking,
						buttonStyle.fontLeading,
						false,
						TextSpriteAlign.CENTER,
						new ImageLibrary.ICON_ARROW(),
						BlobButton.COLOR_ICON_NEUTRAL,
						1,
						options.allowKeyboardFocus
					);
				} else {
					// Normal colors (individual brand colors)
					blobButton = new BlobButton(
						buttonStyle.radius,
						languagesStrings,
						[
							BlobButtonLayer.getStrokeBlob(beverageDesign.colorButtonsStroke, Color.fromAARRGGBB(beverageDesign.colorButtonsStroke).a * 0.4, BlobButton.STROKE_WIDTH_SMALL_THIN),
							BlobButtonLayer.getSolidStrokeBlob(beverageDesign.colorButtonsFill, Color.fromAARRGGBB(beverageDesign.colorButtonsFill).a, beverageDesign.colorButtonsStroke, Color.fromAARRGGBB(beverageDesign.colorButtonsStroke).a, buttonStyle.strokeWidths[0])
						],
						beverageDesign.colorButtonsText,
						beverageDesign.colorButtonsText,
						buttonStyle.fontSize,
						buttonStyle.fontEmphasisSize,
						buttonStyle.fontBold,
						buttonStyle.fontEmphasisBold,
						buttonStyle.fontAlpha,
						buttonStyle.fontEmphasisAlpha,
						buttonStyle.fontTracking,
						buttonStyle.fontEmphasisTracking,
						buttonStyle.fontLeading,
						false,
						TextSpriteAlign.CENTER,
						new ImageLibrary.ICON_ARROW(),
						FountainFamily.platform.id == "bobcat"? FountainFamily.platform.mainColorInterface : 0xffffff,
						1,
						options.allowKeyboardFocus
					);
				}
				FountainFamily.objectRecycler.putNew(buttonBackId, blobButton);
				blobButton = null;
			}

			buttonBack = FountainFamily.objectRecycler.get(buttonBackId);
			buttonBack.recycle();
			buttonBack.start();
			buttonBack.x = buttonStyle.margin + buttonBack.radius;
			buttonBack.y = options.height - buttonStyle.margin - buttonBack.bottomHeight;
			buttonBack.onTapped.add(onButtonBackTapped);
			buttonBack.imgCaption.pivotY = buttonBack.imgCaption.texture.height * 0.60; // Lee: moved text up
			buttonBack.imgIcon.pivotY = buttonBack.imgIcon.texture.height * 0.35;  // Lee: moved icon down due to adjusted radius
			addChild(buttonBack);

			if (options.allowKeyboardFocus) FountainFamily.focusController.addElement(buttonBack);

			// End

			redrawVisibility();

			FountainFamily.backendModel.addEventListener(BackendModel.EVENT_RECIPE_AVAILABILITY_CHANGED, onRecipeAvailabilityChanged);
			updateFlavorAvailability();
			updateBeverageRecipes();

		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function getTargetSponsorLogoRect():Rectangle {
			// Returns a target rectangle size for the "sponsor" logo, depending on the layout

			if (_beverage.isMix) {
				// Mix: rectangle is at the bottom of the flavor list, to the right of the flavor sponsor message
				var sponsorFontSize:Number = options.fontSizeSponsorMix.getValue(_beverage.getDesign(options.isADA).mixLayout);
				return new Rectangle(0, 0, sponsorFontSize * 4, sponsorFontSize * 4);
			} else {
				// Normal brand
				if (options.titleInTwoLines) {
					// Title in two lines: rectangle is to the left of the second line
					return new Rectangle(0, 0, options.marginTitleSecondLine * 0.9, options.marginTitleSecondLine * 0.9);
				} else {
					// Title in one line: rectangle is to the left of the first line
					return new Rectangle(0, 0, options.marginTitleLeft * 0.48, options.marginTitleLeft * 0.48);
				}
			}
		}

		private function getTargetLogoY():Number {
			// Returns the desired Y of the logo: this can be the bottom or other vertical pos of the logo, depending on options.logoAlignY
			return beverage.isMix ? options.marginLogoFromTopMix.getValue(beverage.getDesign(options.isADA).mixLayout) : options.marginTitleFromTop - options.marginLogoFromTitle;
		}

		private function getTargetLogoBottom():Number {
			// Returns the bottom of the logo
			return MathUtils.map(options.logoAlignY.getValue(beverage.getDesign(options.isADA).mixLayout), -1, 1, getTargetLogoY() + logoRectangle.height * logoImage.scaleY, getTargetLogoY());
		}

		private function getNumberOfHiddenSelectedFlavors():int {
			// Returns the number of valid flavors that are hidden and preselected, so it can update the title max count accordingly
			var allFlavors:Vector.<Flavor> = FountainFamily.inventory.getFlavorsById(_beverage.flavorIds);
			var hiddenFlavors:Vector.<Flavor> = FountainFamily.inventory.getFlavorsById(_beverage.hiddenFlavorIds);
			var preselectedFlavors:Vector.<Flavor> = FountainFamily.inventory.getFlavorsById(_beverage.preselectedFlavorIds);

			var totalHiddenFlavors:int = 0;

			for (var i:int = 0; i < hiddenFlavors.length; i++) {
				if (allFlavors.indexOf(hiddenFlavors[i]) >= 0 && preselectedFlavors.indexOf(hiddenFlavors[i]) >= 0) {
					totalHiddenFlavors++;
				}
			}

			return totalHiddenFlavors;
		}

		private function redrawVisibility():void {
			var uiPhase:Number = MathUtils.map(_visibility, 1, 0.7, 1, 0, true);

			if (options.logoLayout == BrandViewOptions.LOGO_LAYOUT_LEFT) {
				// Left
				logoImage.x = MathUtils.map(Equations.expoOut(uiPhase), 0, 1, -logoRectangle.width * 0.5 * logoImage.scaleX, options.marginFlavorLeft * 0.77);
				logoImage.y = getTargetLogoY();

				for(var i : uint = 0; i < FountainFamily.LOCALE_ISO.length; i ++) {
					if (imageTextTitleLine1[i] != null) {
						imageTextTitleLine1[i].y = options.marginTitleFromTop;
						imageTextTitleLine1[i].x = MathUtils.map(Equations.expoOut(uiPhase), 0, 1, -imageTextTitleLine1[i].width, options.marginTitleLeft);

                        if(FountainFamily.platform.id == "bobcat") imageTextTitleLine1[i].x = 0.5 * (width - imageTextTitleLine1[i].width);

						if (imageTextTitleLine2[i] != null) {
							imageTextTitleLine2[i].x = MathUtils.map(Equations.expoOut(uiPhase), 0, 1, -imageTextTitleLine2[i].width, options.marginTitleLeft + options.marginTitleSecondLine);
							imageTextTitleLine2[i].y = imageTextTitleLine1[i].y + imageTextTitleLine1[i].height;
						}
					}

				}

				if (flavorMixView != null) {
					flavorMixView.x = MathUtils.map(Equations.expoOut(uiPhase), 0, 1, 0, options.flavorMixX.getValue(_beverage.getDesign(options.isADA).mixLayout));
					flavorMixView.y = getTargetLogoBottom() + options.marginFlavorMixFromLogo.getValue(_beverage.getDesign(options.isADA).mixLayout);
				}
			} else {
				// Center
				logoImage.x = options.width * 0.5 - logoRectangle.width * logoImage.scaleX * 0.5;
				logoImage.y = getTargetLogoY() - MathUtils.map(Equations.expoOut(uiPhase), 0, 1, logoRectangle.height * logoImage.scaleY, 0);

				for(var j : uint = 0; j < FountainFamily.LOCALE_ISO.length; j ++) {
					if (imageTextTitleLine1[j] != null) {
						imageTextTitleLine1[j].y = options.marginTitleFromTop - MathUtils.map(Equations.expoOut(uiPhase), 0, 1, imageTextTitleLine1[j].height * 6, 0);
						imageTextTitleLine1[j].x = options.marginTitleLeft;

                        if(FountainFamily.platform.id == "bobcat") imageTextTitleLine1[j].x = 0.5 * (width - imageTextTitleLine1[j].width);

						if (imageTextTitleLine2[j] != null) {
							imageTextTitleLine2[j].x = options.marginTitleLeft + options.marginTitleSecondLine;
							imageTextTitleLine2[j].y = imageTextTitleLine1[j].y + imageTextTitleLine1[j].height;
						}
					}
				}
				
				if (flavorMixView != null) {
					flavorMixView.x = options.flavorMixX.getValue(_beverage.getDesign(options.isADA).mixLayout);
					flavorMixView.y = getTargetLogoBottom() - MathUtils.map(Equations.expoOut(uiPhase), 0, 1, logoRectangle.height * logoImage.scaleY * 0.5, 0) + options.marginFlavorMixFromLogo.getValue(_beverage.getDesign(options.isADA).mixLayout);
				}
			}

			logoImage.alpha = Equations.quadOut(uiPhase);
			logoImage.visible = uiPhase > 0;
			for(i = 0; i < FountainFamily.LOCALE_ISO.length; i ++) {
				if (imageTextTitleLine1[i] != null) {
					imageTextTitleLine1[i].alpha = Equations.expoOut(uiPhase) * alphaText;
					if (imageTextTitleLine2[i] != null) imageTextTitleLine2[i].alpha = imageTextTitleLine1[i].alpha;
				}
			}


            if(Calories.CALORIES_ACTIVE) {
                var caloriesHeight :uint = height - options.marginCaloriesBottom;
                var separation : int = 0;
                var u : int = 0;
                for(i = 0; i < Calories.CUPS.length; i ++) {

                    imageTextCalories1[i].alpha = Equations.expoOut(uiPhase);
                    imageTextCalories2[i].alpha = Equations.expoOut(uiPhase);

                    imageTextCalories1[i].x = width - imageTextCalories1[i].width - options.marginCaloriesRight;
                    imageTextCalories1[i].y = caloriesHeight + imageTextCalories1[i].height * (u + 1) + separation;

                    imageTextCalories2[i].x = width - imageTextCalories2[i].width - options.marginCaloriesRight;
                    imageTextCalories2[i].y = caloriesHeight + imageTextCalories2[i].height * u + separation;
                    u += 2;
                    separation += 15;
                }

                flavorsCaloriesCopy.alpha = Equations.expoOut(uiPhase) * alphaText;
                try {
                    flavorsCaloriesCopy.y = options.marginTitleFromTop + (imageTextTitleLine2[0] != null ? imageTextTitleLine2[0].height : imageTextTitleLine1[0].height) - 10;
                    flavorsCaloriesCopy.x = MathUtils.map(Equations.expoOut(uiPhase), 0, 1, -imageTextTitleLine1[0].width, options.marginTitleLeft);
                } catch(e : Error) {
                    //Quick fix for the mixes.
                    flavorsCaloriesCopy.y = -1000;
                    flavorsCaloriesCopy.x = -1000;
                }
            }


			if (flavorSelector != null) flavorSelector.visibility = uiPhase;
			if (flavorMixView != null) flavorMixView.visibility = uiPhase;

			if (sponsorLogoImage != null) {
				sponsorLogoImage.alpha = Equations.expoOut(uiPhase);
				sponsorLogoImage.visible = uiPhase > 0;

				if (imageTextTitleLine2[currentLanguage] != null) {
					// Normal brand view, to the left of line 2
					sponsorLogoImage.x = imageTextTitleLine2[currentLanguage].x - options.marginTitleSecondLine;
					sponsorLogoImage.y = imageTextTitleLine2[currentLanguage].y + imageTextTitleLine2[currentLanguage].height * 0.5 - sponsorLogoRectangle.height * sponsorLogoImage.scaleY * 0.5;
				} else {
					// Normal brand view, to the left of line 1
					if (imageTextTitleLine1[currentLanguage] != null) {
						sponsorLogoImage.x = imageTextTitleLine1[currentLanguage].x - sponsorLogoRectangle.width * sponsorLogoImage.scaleX - 10;
						sponsorLogoImage.y = imageTextTitleLine1[currentLanguage].y + imageTextTitleLine1[currentLanguage].height * 0.5 - sponsorLogoRectangle.height * sponsorLogoImage.scaleY * 0.5;
					} else {
						// Mix
						if(beverage.isMix) {
							sponsorTextImage.alpha = Equations.expoOut(uiPhase);
							sponsorTextImage.visible = uiPhase > 0;

							var totalWidth:Number = sponsorTextImage.width + 10 + sponsorLogoRectangle.width * sponsorLogoImage.scaleX;
							var totalHeight:Number = Math.max(sponsorTextImage.height, sponsorLogoRectangle.height * sponsorLogoImage.scaleY);

							var flavorBottom:Number = flavorMixView.y + flavorMixView.height * MathUtils.map(flavorMixView.alignY, -1, 1, 1, 0);

							if (options.flavorMixItemAlignment.getValue(beverage.getDesign(options.isADA).mixLayout) == BrandViewOptions.FLAVOR_MIX_ITEM_ALIGNMENT_CENTER) {
								// Centered under the flavor mix
								sponsorTextImage.x = options.width * 0.5 - totalWidth * 0.5;
								sponsorTextImage.y = flavorBottom + totalHeight * 0.5 - sponsorTextImage.height * 0.5;
								sponsorLogoImage.x = sponsorTextImage.x + sponsorTextImage.width + 6;
								sponsorLogoImage.y = flavorBottom + totalHeight * 0.5 - sponsorLogoRectangle.height * sponsorLogoImage.scaleY * 0.5;
							} else {
								// Left-aligned under the flavor mix
								sponsorTextImage.x = flavorMixView.x - 40;
								sponsorTextImage.y = flavorBottom + totalHeight * 0.5 + totalHeight * 0.5 - sponsorTextImage.height * 0.5;
								sponsorLogoImage.x = flavorMixView.x - 40 + sponsorTextImage.width + 6;
								sponsorLogoImage.y = flavorBottom + totalHeight * 0.5 + totalHeight * 0.5 - sponsorLogoRectangle.height * sponsorLogoImage.scaleY * 0.5;
							}
						}
					}
				}
			}

			buttonPour.visibility = uiPhase;

			if (liquidView != null) liquidView.visibility = MathUtils.map(_visibility, 0, 1, 0, 1, true);

			if (animation != null) {
				animation.alpha = uiPhase * beverage.getDesign(options.isADA).animationAlpha;
				animation.visible = uiPhase > 0;
			}

			if (particleCreator != null) {
				particleCreator.alpha = uiPhase;
				particleCreator.visible = uiPhase > 0;
			}

			buttonBack.visibility = uiPhase;

		}

		private function updateBeverageRecipes():void {
			// Updates the backend beverage with the currently selected recipes
			FountainFamily.backendModel.selectBeverage(_beverage.recipeId, getSelectedFlavorRecipeIds());
		}

		private function getSelectedFlavorRecipeIds():Vector.<String> {
			// Returns the flavors that should be selected: either the user-selected ones, or the default ones if no flavor selector exists (should probably never happen; this was used before, when mixes used pre-selected flavors, but after 3.6.0 mixes are their own beverages)
			return flavorSelector == null ? FountainFamily.inventory.getFlavorRecipeIds(beverage.getValidPreselectedFlavorIds()) : flavorSelector.getSelectedFlavorRecipeIds();
		}

		private function updateFlavorAvailability():void {
			// Updates the current flavors with an indication of its availability
			if (flavorSelector != null) flavorSelector.updateFlavorAvailability(FountainFamily.backendModel);
		}

		private function startPouringBeverage():void {
			if (!isPouringBeverage) {
				isPouringBeverage = true;
				FountainFamily.backendModel.startPour();
				if (liquidView != null) liquidView.startPour();
			}
		}

		private function stopPouringBeverage():void {
			if (isPouringBeverage) {
				isPouringBeverage = false;
				FountainFamily.backendModel.stopPour();
				if (liquidView != null) liquidView.stopPour();
			}
		}

		private function executeButtonBackTappedAction():void {
			_onTappedBack.dispatch();
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		private function onRecipeAvailabilityChanged(__e:Event):void {
			// Update the availability of all blobs
			updateFlavorAvailability();
			if (options.allowKeyboardFocus) FountainFamily.focusController.checkValidityOfCurrentElement();
		}

		private function onChangedFlavorSelection():void {
			// Run this after changing flavors
			updateBeverageRecipes();
			if (options.allowKeyboardFocus) FountainFamily.focusController.checkValidityOfCurrentElement();
		}

		private function onButtonBackTapped(__button:BlobButton):void {
			FountainFamily.backendModel.trackButtonPressed(StringList.getList(FountainFamily.current_language).getString("tracking/brand-button-back"));
			executeButtonBackTappedAction();
		}

		private function onButtonPourPressed(__button:BlobButton):void {
			startPouringBeverage();
			FountainFamily.backendModel.trackButtonPressed(StringList.getList(FountainFamily.current_language).getString("tracking/brand-button-pour-beverage"));
		}

		private function onButtonPourReleased(__button:BlobButton):void {
			stopPouringBeverage();
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function performAutoTestActions(__testingOverlay:TestingOverlay):void {
			// Do everything required by the auto tests

			var ts:Number = 1/FountainFamily.timeScale;

			var pourTime:Number = FountainFamily.configList.getNumber("debug/auto-test/beverage-pour-time");
			if (isNaN(pourTime) || pourTime <= 0) pourTime = 0.1;
			pourTime *= RandomGenerator.getInRange(100, 1000) * ts;

			var waitTime:Number = FountainFamily.configList.getNumber("debug/auto-test/wait-time");
			if (isNaN(waitTime) || waitTime <= 0) waitTime = 0.1;
			waitTime *= RandomGenerator.getInRange(100, 1000) * ts;

			var ttime:Number = 0;

			// Initial wait
			ttime += RandomGenerator.getInRange(600, 3000) * ts;

			if (flavorSelector != null && FountainFamily.configList.getBoolean("debug/auto-test/random-flavors-enabled") && !FountainFamily.DEBUG_DISABLE_TESTING_POURING) {
				if (flavorSelector.getNumItems() > 0 && (flavorSelector.getNumItems() > 1 || Math.random() > 0.5)) {
					DelayedCalls.add(ttime - 500 * ts, flavorSelector.simulatePickButton);

					DelayedCalls.add(ttime, flavorSelector.simulateEnterDown);
					DelayedCalls.add(ttime - 400 * ts, __testingOverlay.animateHandDynamic, [true, flavorSelector.getSimulatedButtonX, flavorSelector.getSimulatedButtonY, x, y]);

					ttime += RandomGenerator.getInRange(100, 500) * ts;
					DelayedCalls.add(ttime, flavorSelector.simulateEnterUp);
					DelayedCalls.add(ttime - 400 * ts, __testingOverlay.animateHand, [false]);
					ttime += RandomGenerator.getInRange(510, 600) * ts;
				}
				if (flavorSelector.getNumItems() > 1) {
					ttime += waitTime * 0.25;

					DelayedCalls.add(ttime - 500 * ts, flavorSelector.simulatePickButton);

					DelayedCalls.add(ttime, flavorSelector.simulateEnterDown);
					DelayedCalls.add(ttime - 400 * ts, __testingOverlay.animateHandDynamic, [true, flavorSelector.getSimulatedButtonX, flavorSelector.getSimulatedButtonY, x, y]);

					ttime += RandomGenerator.getInRange(100, 500) * ts;
					DelayedCalls.add(ttime, flavorSelector.simulateEnterUp);
					DelayedCalls.add(ttime - 400 * ts, __testingOverlay.animateHand, [false]);
					ttime += RandomGenerator.getInRange(510, 600) * ts;
				}
				if (flavorSelector.getNumItems() > 2) {
					ttime += waitTime * 0.25;

					DelayedCalls.add(ttime - 500 * ts, flavorSelector.simulatePickButton);

					DelayedCalls.add(ttime, flavorSelector.simulateEnterDown);
					DelayedCalls.add(ttime - 400 * ts, __testingOverlay.animateHandDynamic, [true, flavorSelector.getSimulatedButtonX, flavorSelector.getSimulatedButtonY, x, y]);

					ttime += RandomGenerator.getInRange(100, 500) * ts;
					DelayedCalls.add(ttime, flavorSelector.simulateEnterUp);
					DelayedCalls.add(ttime - 400 * ts, __testingOverlay.animateHand, [false]);
					ttime += RandomGenerator.getInRange(510, 600) * ts;
				}
			}

			if (FountainFamily.configList.getBoolean("debug/auto-test/beverage-pour-enabled") && !FountainFamily.DEBUG_DISABLE_TESTING_POURING) {
				ttime += waitTime;
				DelayedCalls.add(ttime, buttonPour.simulateEnterDown);
				DelayedCalls.add(ttime - 400 * ts, __testingOverlay.animateHand, [true, buttonPour.x + x, buttonPour.y + y]);
				ttime += pourTime;
				DelayedCalls.add(ttime, buttonPour.simulateEnterUp);
				DelayedCalls.add(ttime - 400 * ts, __testingOverlay.animateHand, [false]);
				ttime += waitTime;
			}

			ttime += waitTime;
			DelayedCalls.add(ttime, buttonBack.simulateEnterDown);
			DelayedCalls.add(ttime - 400 * ts, __testingOverlay.animateHand, [true, buttonBack.x + x, buttonBack.y + y]);

			ttime += RandomGenerator.getInRange(100, 500) * ts;
			DelayedCalls.add(ttime, buttonBack.simulateEnterUp);
			DelayedCalls.add(ttime - 400 * ts, __testingOverlay.animateHand, [false]);
		}

		public function executeHardwareADACommand(__command:String):void {
			switch(__command) {
				case FountainFamily.HARDWARE_COMMAND_POUR_BEVERAGE_START:
					if (!FountainFamily.backendModel.isPouringAnything()) startPouringBeverage();
					break;
				case FountainFamily.HARDWARE_COMMAND_POUR_BEVERAGE_STOP:
					stopPouringBeverage();
					break;
				case FountainFamily.HARDWARE_COMMAND_POUR_WATER_START:
					if (!FountainFamily.backendModel.isPouringAnything()) FountainFamily.backendModel.startPourWater();
					break;
				case FountainFamily.HARDWARE_COMMAND_POUR_WATER_STOP:
					FountainFamily.backendModel.stopPourWater();
					break;
				case FountainFamily.HARDWARE_COMMAND_NAVIGATE_BACK:
					_onTappedBack.dispatch();
					break;
			}
		}

		public function onPreShow():void {
			isHiding = false;

			if (FountainFamily.platform.supportsLightsAPI) {
				FountainFamily.backendModel.setLightColorARGB(beverage.getDesign().colorLight, FountainFamily.lightingInfo.timeColorChange * 1000, FountainFamily.lightingInfo.brightnessScale);
			}
		}

		public function onPostShow():void {
			// Track
			FountainFamily.backendModel.trackScreenChanged(StringList.getList(FountainFamily.current_language).getString(options.trackId), beverage.id);
		}

		public function onPreHide():void {
			isHiding = true;
		}

		public function onPostHide():void {

		}

		override public function dispose():void {
			var i:int;

			if (animation != null) {
				removeChild(animation, true);
				animation = null;
			}

			if (particleCreator != null) {
				removeChild(particleCreator, true);
				particleCreator = null;
			}

			for(var j : uint = 0; j < FountainFamily.LOCALE_ISO.length; j ++) {
				if (imageTextTitleLine1[j] != null) {
					removeChild(imageTextTitleLine1[j]);
					FountainFamily.objectRecycler.putBack(imageTextTitleLine1[j]);
					imageTextTitleLine1[j] = null;

					if (imageTextTitleLine2[j] != null) {
						removeChild(imageTextTitleLine2[j]);
						FountainFamily.objectRecycler.putBack(imageTextTitleLine2[j]);
						imageTextTitleLine2[j] = null;
					}
				}
			}

            //Removing the copy for the calories
            if(Calories.CALORIES_ACTIVE) {

                //Calories copy for each cup
                for(var s : uint = 0; s < Calories.CUPS.length; s ++) {
                        removeChild(imageTextCalories1[s]);
                        FountainFamily.objectRecycler.putBack(imageTextCalories1[s]);
                        imageTextCalories1[s] = null;

                        removeChild(imageTextCalories2[j]);
                        FountainFamily.objectRecycler.putBack(imageTextCalories2[s]);
                        imageTextCalories2[s] = null;
                }

                //Calories copy for the flavors.
                if (flavorsCaloriesCopy != null) {
                    removeChild(flavorsCaloriesCopy);
                    FountainFamily.objectRecycler.putBack(flavorsCaloriesCopy);
                    flavorsCaloriesCopy = null;
                }

            }

			if (sponsorTextImage != null) {
				removeChild(sponsorTextImage);
				FountainFamily.objectRecycler.putBack(sponsorTextImage);
				sponsorTextImage = null;
			}

			removeChild(logoImage);
			FountainFamily.objectRecycler.putBack(logoImage);
			logoImage = null;

			if (liquidView != null) {
				removeChild(liquidView, true);
				liquidView = null;
			}

			if (sponsorLogoImage != null) {
				removeChild(sponsorLogoImage);
				FountainFamily.objectRecycler.putBack(sponsorLogoImage);
				sponsorLogoImage = null;
			}

			FountainFamily.focusController.removeElement(buttonPour);
			removeChild(buttonPour);
			buttonPour.onPressed.remove(onButtonPourPressed);
			buttonPour.onReleased.remove(onButtonPourReleased);
			buttonPour.onPressCanceled.remove(onButtonPourReleased);
			buttonPour.stop();
			FountainFamily.objectRecycler.putBack(buttonPour);
			buttonPour = null;

			FountainFamily.focusController.removeElement(buttonBack);
			removeChild(buttonBack);
			buttonBack.onTapped.remove(onButtonBackTapped);
			buttonBack.stop();
			FountainFamily.objectRecycler.putBack(buttonBack);
			buttonBack = null;

			if (flavorSelector != null) {
				if (options.allowKeyboardFocus) {
					var orderedFlavorItems:Vector.<FlavorSelectorItem> = flavorSelector.getOrderedItems();
					for (i = 0; i < orderedFlavorItems.length; i++) {
						FountainFamily.focusController.removeElement(orderedFlavorItems[i]);
					}
				}

				removeChild(flavorSelector, true);
				flavorSelector = null;
			}

			if (flavorMixView != null) {
				removeChild(flavorMixView, true);
				flavorMixView = null;
			}

			FountainFamily.backendModel.removeEventListener(BackendModel.EVENT_RECIPE_AVAILABILITY_CHANGED, onRecipeAvailabilityChanged);

			_onTappedBack.removeAll();
			_onTappedBack = null;

			super.dispose();
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function set language(value : uint) : void {

			currentLanguage = value;
			var i : uint = 0;
			if (options.titleInTwoLines) {

				for(i = 0; i < FountainFamily.LOCALE_ISO.length; i ++) {
					if(imageTextTitleLine1[i] != null) imageTextTitleLine1[i].visible = false;
					if(imageTextTitleLine2[i] != null) imageTextTitleLine2[i].visible = false;
				}

				if(imageTextTitleLine1[value] != null) imageTextTitleLine1[value].visible = true;
				if(imageTextTitleLine2[value] != null) imageTextTitleLine2[value].visible = true;

			} else {


				trace("modificando idioma en brand: " + value);
				trace(imageTextTitleLine1[value]);
				for(i = 0; i < FountainFamily.LOCALE_ISO.length; i ++) if(imageTextTitleLine1[i] != null) imageTextTitleLine1[i].visible = false;
				if(imageTextTitleLine1[value] != null) imageTextTitleLine1[value].visible = true;

			}

			if(flavorSelector != null) flavorSelector.language = value;
		}

		public function setLiquidClipRect(__rectangle:Rectangle):void {
			// Set the rectangle that the liquid videos have to be clipped at
			if (liquidView != null) liquidView.setLiquidClipRect(__rectangle);
		}

		public function getLiquidCenterLocation():Point {
			return liquidView == null ? null : liquidView.getMaskCenter();
		}

		public function getLiquidRadius():Number {
			return liquidView == null ? 0 : liquidView.getMaskRadius();
		}

		public function getLogoTop():Number {
			return logoImage.y - (logoImage.pivotY - logoRectangle.y) * logoImage.scaleY;
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

		public function get onTappedBack():SimpleSignal {
			return _onTappedBack;
		}

		public function get isHiding():Boolean {
			return _isHiding;
		}

		public function set isHiding(__value:Boolean):void {
			_isHiding = __value;
		}

		public function get beverage():Beverage {
			return _beverage;
		}

		override public function get width():Number {
			return options.width;
		}

		override public function get height():Number {
			return options.height;
		}
	}
}
