package com.firstborn.pepsi.display.gpu.home.view {
import com.firstborn.pepsi.application.FountainFamily;
import com.firstborn.pepsi.common.backend.BackendModel;
import com.firstborn.pepsi.common.backend.BackendModel;
import com.firstborn.pepsi.common.backend.BackendModel;
import com.firstborn.pepsi.data.inventory.BeverageDesign;
import com.firstborn.pepsi.display.gpu.brand.particles.ParticleCreator;
import com.firstborn.pepsi.display.gpu.brand.particles.ParticleCreatorFactoryLine;
import com.firstborn.pepsi.tester.FountainFamilyTest;
import com.zehfernando.display.starling.AnimatedImage;
import com.zehfernando.transitions.ZTween;
import com.zehfernando.utils.console.error;
import com.zehfernando.utils.console.warn;

import flash.events.Event;

import starling.display.Image;
	import starling.display.Sprite;

	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.assets.FontLibrary;
	import com.firstborn.pepsi.assets.ImageLibrary;
	import com.firstborn.pepsi.data.inventory.Beverage;
	import com.firstborn.pepsi.display.flash.TestingOverlay;
	import com.firstborn.pepsi.display.gpu.common.BlobButtonStyle;
	import com.firstborn.pepsi.display.gpu.common.TextBitmap;
	import com.firstborn.pepsi.display.gpu.common.TextureLibrary;
	import com.firstborn.pepsi.display.gpu.common.components.BlobButton;
	import com.firstborn.pepsi.display.gpu.common.components.BlobButtonLayer;
	import com.firstborn.pepsi.display.gpu.home.ParticleArea;
	import com.firstborn.pepsi.display.gpu.home.menu.BlobSpritesInfo;
	import com.firstborn.pepsi.display.gpu.home.menu.MainMenu;
	import com.zehfernando.display.components.text.TextSpriteAlign;
	import com.zehfernando.localization.StringList;
	import com.zehfernando.signals.SimpleSignal;
	import com.zehfernando.transitions.Equations;
	import com.zehfernando.utils.DelayedCalls;
	import com.zehfernando.utils.MathUtils;
	import com.zehfernando.utils.RandomGenerator;


	import flash.geom.Point;
	import flash.geom.Rectangle;

import starling.textures.Texture;

/**
	 * @author zeh fernando
	 */
	public class HomeView extends Sprite {

		// Constants
		public static const COLOR_BUTTON_STROKES_NEUTRAL:uint = 0xb5bec4;
		public static const COLOR_BUTTON_STROKES_COLOR:uint = 0x3da5e7;
		public static const COLOR_BUTTON_FILL_COLOR:uint = 0xffffff;

		private static const COLOR_TITLE_TOP:uint = 0x33a2d1;
		private static const COLOR_TITLE_BOTTOM:uint = 0x7e878c;

		private static const MARGIN_MENU_TOP:Number = 30;
		private static const MARGIN_MENU_BOTTOM:Number = 0;

		private static var currentLanguage : uint = 0;

		// Properties
		private var _brandTransitionPhase:Number;							// Visibility when transitioning to a brand view: 1 = visible, 0 = hidden
		private var _brandTransitionIsHiding:Boolean;						// Whether it's currently hiding when _brandTransitionPhase is not 0/1 (if false, assumes it's showing)
		private var _hiddenTransitionPhase:Number;							// Visibility when hiding the menu (transitioning to attractor)
		private var _hiddenTransitionIsHiding:Boolean;						// Whether it's currently hiding when _hiddenPhase is not 0/1 (if false, assumes it's showing)

		private var _uiVisibility:Number;									// Temp for calculations
		private var buttonsEnabled:Boolean;
		private var isPaused:Boolean;

		// Instances
		private var mainMenuContainer:Sprite;
		private var mainMenu:MainMenu;
		private var particleArea:ParticleArea;
		private var _onRequestedBrandView:SimpleSignal;

		private var buttonPourTapWater:BlobButton;
		private var buttonPourSparklingWater:BlobButton;

		//Vector of images that contains the different required titles for each localization
		private var imageTitleTop : Vector.<Image> = new Vector.<Image>(FountainFamily.MAX_LANGUAGES);
		private var imageTitleBottom : Vector.<Image> = new Vector.<Image>(FountainFamily.MAX_LANGUAGES);

		private var options:HomeViewOptions;							// Visual options

		public var disposeWithoutRecycler:Boolean = false;

		//For the localization
		private var buttonLanguageSelector:BlobButton;

		//Signal to activate the language of the parent.
		public var languageSignal : SimpleSignal;

        //variable set for the visibility of the sparkling water depending on the availability from the backend menu
        private var sparklingAvailable : Boolean;

        //Variable used to display the unlocking view
        private var unlockRequestCopy : Vector.<Image> = new Vector.<Image>(10);
        private var unlockProcessingCopy : Vector.<Image> = new Vector.<Image>(10);
        private var unlockErrors : Vector.<UnlockError> = new Vector.<UnlockError>();
        private var unlockViewContainer : Sprite;
        private var animator : Object = {parameter: 0};
        private var errorDisplayed : Image;
        private var lockedParticles : ParticleCreator;
        private var unlockArrowImage : Image;

        //Spire logo animation
        private var spireLogo : AnimatedImage;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function HomeView(__options:HomeViewOptions, __forceDisallowKeyboardFocus:Boolean = false, __currentLanguage : uint = 0) {

            if(FountainFamily.LOCKED_MODE) {

                //Container for the copy and assets for the locked version of the menu.
                unlockViewContainer = new Sprite();
                unlockViewContainer.touchable = false;
                addChild(unlockViewContainer);

            }

			currentLanguage = __currentLanguage;
			_brandTransitionPhase = 0;
			_hiddenTransitionPhase = 0;
			buttonsEnabled = true;
			isPaused = false;
			options = __options;

			if (__forceDisallowKeyboardFocus) options.allowKeyboardFocus = false;

			var buttonStyle:BlobButtonStyle = options.buttonStyle;

			// Find margins and other sizes
			var marginMenuTop:Number; // set later
			var marginMenuBottom:Number = 0;
			if (options.buttonLayout == HomeViewOptions.BUTTON_LAYOUT_HORIZONTAL && options.menuLayout != HomeViewOptions.MENU_LAYOUT_CUSTOM) marginMenuBottom = buttonStyle.margin + buttonStyle.radius * 2 + MARGIN_MENU_BOTTOM;
			if (options.buttonLayout == HomeViewOptions.BUTTON_LAYOUT_HORIZONTAL && options.menuLayout == HomeViewOptions.MENU_LAYOUT_CUSTOM) marginMenuBottom = (buttonStyle.margin + buttonStyle.radius * 2 + MARGIN_MENU_BOTTOM) * 0.75; // Different alignment...
			var marginMenuLeft:Number = 0;
			var marginMenuRight:Number = (options.buttonLayout == HomeViewOptions.BUTTON_LAYOUT_VERTICAL_RIGHT && options.menuLayout != HomeViewOptions.MENU_LAYOUT_CUSTOM) ? buttonStyle.margin * 2 + buttonStyle.radius * 2 : 0;


			// Creates all assets
			if (options.hasTitle) {

				var i : uint = 0;
				var imageTitleTopId:String = "";
				var imageTitleBottomId:String = "";

				//Create the labels for all the languages
				for(i = 0; i < FountainFamily.LOCALE_ISO.length; i ++) {

					imageTitleTopId = "HomeView_imageTitleTop_" + options.id + FountainFamily.LOCALE_ISO[i];
					if (!FountainFamily.objectRecycler.has(imageTitleTopId)) FountainFamily.objectRecycler.putNew(imageTitleTopId, new Image(TextBitmap.createTexture(StringList.getList(FountainFamily.LOCALE_ISO[i]).getString("home/title-top"), FontLibrary.BOOSTER_FY_REGULAR, null, 22, NaN, COLOR_TITLE_TOP, -1, 1, 1, 160, 160, TextSpriteAlign.CENTER, false)));
					imageTitleTop[i] = FountainFamily.objectRecycler.get(imageTitleTopId);
					imageTitleTop[i].touchable = false;
					imageTitleTop[i].smoothing = FountainFamily.platform.getTextureProfile(TextureLibrary.TEXTURE_ID_GENERIC_TEXT).smoothing;
					imageTitleTop[i].pivotX = imageTitleTop[i].width * 0.5;
					imageTitleTop[i].x = options.width * 0.5;
					addChild(imageTitleTop[i]);
					imageTitleTop[i].visible = false;

					imageTitleBottomId = "HomeView_imageTitleBottom_" + options.id + FountainFamily.LOCALE_ISO[i];
					if (!FountainFamily.objectRecycler.has(imageTitleBottomId)) FountainFamily.objectRecycler.putNew(imageTitleBottomId, new Image(TextBitmap.createTexture(StringList.getList(FountainFamily.LOCALE_ISO[i]).getString("home/title-bottom"), FontLibrary.BOOSTER_FY_REGULAR, null, 82, NaN, COLOR_TITLE_BOTTOM, -1, 1, 1, 20, 20, TextSpriteAlign.CENTER, false, NaN, 0, null, 10)));
					imageTitleBottom[i] = FountainFamily.objectRecycler.get(imageTitleBottomId);
					imageTitleBottom[i].touchable = false;
					imageTitleBottom[i].smoothing = FountainFamily.platform.getTextureProfile(TextureLibrary.TEXTURE_ID_GENERIC_TEXT).smoothing;
					imageTitleBottom[i].pivotX = imageTitleBottom[i].width * 0.5;
					imageTitleBottom[i].x = options.width * 0.5;
					addChild(imageTitleBottom[i]);
					imageTitleBottom[i].visible = false;

				}

				imageTitleTop[FountainFamily.DEFAULT_LANGUAGE].visible = true;
				imageTitleBottom[FountainFamily.DEFAULT_LANGUAGE].visible = true;

				marginMenuTop = options.marginTitleTop + imageTitleBottom[0].height + MARGIN_MENU_TOP;
			} else {
				marginMenuTop = MARGIN_MENU_TOP;
			}

			var mainMenuId:String = "HomeView_mainMenu_" + options.id;
			if (!FountainFamily.objectRecycler.has(mainMenuId)) FountainFamily.objectRecycler.putNew(mainMenuId, new MainMenu(options.width - marginMenuLeft - marginMenuRight, options.height - marginMenuBottom - marginMenuTop, options.menuHasSequencePlayer, options.menuLayout, options.menuLayoutParams, options.allowKeyboardFocus, options.particleNumberScale, options.particleSizeScale, options.particleAlphaScale, options.particleClusterChance, options.particleClusterItemsMax, options.numColumnsDesired, options.menuAlignX, options.menuAlignY));

			mainMenuContainer = new Sprite();
			addChild(mainMenuContainer);

			mainMenu = FountainFamily.objectRecycler.get(mainMenuId);
			mainMenu.resume();
			mainMenu.setButtonsEnabled(true);
			mainMenu.onTappedBlob.add(onTappedMainMenuBlob);
			mainMenu.x = marginMenuLeft;
			mainMenu.y = marginMenuTop;
			mainMenu.language(FountainFamily.DEFAULT_LANGUAGE);
			mainMenuContainer.addChild(mainMenu);

			if (options.particleAreaDensity > 0) {
				// Creates area of particles on the top
				var menuRect:Rectangle = mainMenu.bounds;
				var pw:Number = options.width;
				var ph:Number = menuRect.y;
				if (pw * ph > 0) {
					particleArea = new ParticleArea(pw, ph, options.particleAreaDensity, options.particleAlphaScale, mainMenu);
					addChild(particleArea);
				}
			}

			var languagesStrings : Vector.<String> = new Vector.<String>();
			for(i = 0; i < FountainFamily.LOCALE_ISO.length; i ++) languagesStrings.push(StringList.getList(FountainFamily.LOCALE_ISO[i]).getString("home/button-pour-tap-water"));
			if (options.buttonLayout != HomeViewOptions.BUTTON_LAYOUT_NONE) {
				var blobButton:BlobButton;
				var buttonPourTapWaterId:String = "BrandViewLogoImage_buttonPourTapWater_" + options.id + "_" + options.allowKeyboardFocus;
				if (!FountainFamily.objectRecycler.has(buttonPourTapWaterId)) {
					blobButton = new BlobButton(
						buttonStyle.radius,
						languagesStrings,
						[
							BlobButtonLayer.getStrokeBlob(COLOR_BUTTON_STROKES_NEUTRAL, 0.8, BlobButton.STROKE_WIDTH_SMALL_THIN),
							BlobButtonLayer.getSolidStrokeBlob(COLOR_BUTTON_FILL_COLOR, 1, COLOR_BUTTON_STROKES_COLOR, 1, buttonStyle.strokeWidths[0])
						],
						BlobButton.COLOR_TEXT_NEUTRAL,
						BlobButton.COLOR_TEXT_EMPHASIS,
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
						new ImageLibrary.ICON_POUR_SMALL(),
						BlobButton.COLOR_ICON_NEUTRAL,
						1,
						options.allowKeyboardFocus
					);
					FountainFamily.objectRecycler.putNew(buttonPourTapWaterId, blobButton);
					blobButton = null;
				}
				buttonPourTapWater = FountainFamily.objectRecycler.get(buttonPourTapWaterId);
				buttonPourTapWater.recycle();
				buttonPourTapWater.start();
				buttonPourTapWater.onPressed.add(onTapWaterPressed);
				buttonPourTapWater.onReleased.add(onTapWaterReleased);
				buttonPourTapWater.onPressCanceled.add(onTapWaterReleased);
				addChild(buttonPourTapWater);

				var buttonPourSparklingWaterId:String = "BrandViewLogoImage_buttonPourSparklingWater_" + options.id + "_" + options.allowKeyboardFocus;
				languagesStrings.length = 0;
				for(i = 0; i < FountainFamily.LOCALE_ISO.length; i ++) languagesStrings.push(StringList.getList(FountainFamily.LOCALE_ISO[i]).getString("home/button-pour-sparkling-water"));
				if (!FountainFamily.objectRecycler.has(buttonPourSparklingWaterId)) {
					blobButton = new BlobButton(
						buttonStyle.radius,
						languagesStrings,
						[
							BlobButtonLayer.getStrokeBlob(COLOR_BUTTON_STROKES_NEUTRAL, 0.8, BlobButton.STROKE_WIDTH_SMALL_THIN),
							BlobButtonLayer.getSolidStrokeBlob(COLOR_BUTTON_FILL_COLOR, 1, COLOR_BUTTON_STROKES_COLOR, 1, buttonStyle.strokeWidths[0])
						],
						BlobButton.COLOR_TEXT_NEUTRAL,
						BlobButton.COLOR_TEXT_EMPHASIS,
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
						new ImageLibrary.ICON_POUR_SMALL(),
						BlobButton.COLOR_ICON_NEUTRAL,
						1,
						options.allowKeyboardFocus
					);
					FountainFamily.objectRecycler.putNew(buttonPourSparklingWaterId, blobButton);
					blobButton = null;
				}
				buttonPourSparklingWater = FountainFamily.objectRecycler.get(buttonPourSparklingWaterId);
				buttonPourSparklingWater.recycle();
				buttonPourSparklingWater.start();
				buttonPourSparklingWater.onPressed.add(onSparklingWaterPressed);
				buttonPourSparklingWater.onReleased.add(onSparklingWaterReleased);
				buttonPourSparklingWater.onPressCanceled.add(onSparklingWaterReleased);
				addChild(buttonPourSparklingWater);

                FountainFamily.backendModel.addEventListener(BackendModel.EVENT_RECIPE_AVAILABILITY_CHANGED, function() : void{

                    sparklingAvailable = FountainFamily.backendModel.getRecipeAvailability(FountainFamily.inventory.getBeverageSparklingWater().recipeId);

                    buttonPourSparklingWater.visibility = Number(sparklingAvailable);
                });


                if(FountainFamily.LOCALE_ISO.length > 1) {
					//GENERATE THE LANGUAGE BUTTON...THIS IS HARD CODED SINCE IT'S A TOGGLE FOR TWO LANGUAGES
					var buttonLanguageSelectorId:String = "BrandViewLogoImage_buttonLanguageSelector_" + options.id + "_" + options.allowKeyboardFocus;
					languagesStrings.length = 0;
					languagesStrings[0] = FountainFamily.LANGUAGES_LABELS[1];
					languagesStrings[1] = FountainFamily.LANGUAGES_LABELS[0];
					//for(i = 0; i < FountainFamily.LOCALE_ISO.length; i ++) languagesStrings[i] = FountainFamily.LANGUAGES_LABELS[i];

					if (!FountainFamily.objectRecycler.has(buttonLanguageSelectorId)) {
						blobButton = new BlobButton(
								buttonStyle.radius,
								languagesStrings,
								[
									BlobButtonLayer.getStrokeBlob(COLOR_BUTTON_STROKES_NEUTRAL, 0.8, BlobButton.STROKE_WIDTH_SMALL_THIN),
									BlobButtonLayer.getSolidStrokeBlob(COLOR_BUTTON_FILL_COLOR, 1, COLOR_BUTTON_STROKES_COLOR, 1, buttonStyle.strokeWidths[0])
								],
								BlobButton.COLOR_TEXT_NEUTRAL,
								BlobButton.COLOR_TEXT_EMPHASIS,
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
								null,
								BlobButton.COLOR_ICON_NEUTRAL,
								1,
								options.allowKeyboardFocus
						);
						FountainFamily.objectRecycler.putNew(buttonLanguageSelectorId, blobButton);
						blobButton = null;
					}
					buttonLanguageSelector = FountainFamily.objectRecycler.get(buttonLanguageSelectorId);
					buttonLanguageSelector.recycle();
					buttonLanguageSelector.start();
					buttonLanguageSelector.onReleased.add(onLanguageSelectorReleased);
					addChild(buttonLanguageSelector);
					buttonLanguageSelector.visible = false;
				}

				switch (options.buttonLayout) {
					case HomeViewOptions.BUTTON_LAYOUT_HORIZONTAL:
						// Left, horizontal: tap water, then sparkling water
						buttonPourTapWater.x = Math.round(buttonStyle.margin + buttonStyle.radius);
						buttonPourTapWater.y = Math.round(options.height - buttonStyle.margin - buttonStyle.radius);
						buttonPourSparklingWater.x = Math.round(buttonStyle.margin + buttonStyle.radius * 2 + buttonStyle.gutter + buttonStyle.radius);
						buttonPourSparklingWater.y = Math.round(options.height - buttonStyle.margin - buttonStyle.radius);

						if(FountainFamily.LOCALE_ISO.length > 1) {
							buttonLanguageSelector.x = Math.round(options.width - (buttonStyle.margin + buttonStyle.radius * 2 + buttonStyle.gutter + buttonStyle.radius));
							buttonLanguageSelector.y = Math.round(options.height - buttonStyle.margin - buttonStyle.radius);
							buttonLanguageSelector.visible = true;
						}


						if (options.allowKeyboardFocus) {
							FountainFamily.focusController.addElement(buttonPourTapWater);
							FountainFamily.focusController.addElement(buttonPourSparklingWater);
						}

						break;
					case HomeViewOptions.BUTTON_LAYOUT_VERTICAL:
						// Left, vertical: sparkling water, then tap water
						buttonPourTapWater.x = Math.round(buttonStyle.margin + buttonStyle.radius);
						buttonPourTapWater.y = Math.round(options.height - buttonStyle.margin - buttonStyle.radius);
						buttonPourSparklingWater.x = Math.round(buttonStyle.margin + buttonStyle.radius);
						buttonPourSparklingWater.y = Math.round(options.height - buttonStyle.margin - buttonStyle.radius * 2 - buttonStyle.gutter - buttonStyle.radius);

						if (options.allowKeyboardFocus) {
							FountainFamily.focusController.addElement(buttonPourSparklingWater);
							FountainFamily.focusController.addElement(buttonPourTapWater);
						}

						break;
					case HomeViewOptions.BUTTON_LAYOUT_VERTICAL_RIGHT:
						// Right, vertical: sparkling water, then tap water, then ADA
						buttonPourTapWater.x = options.width - buttonStyle.margin - buttonStyle.radius;
						buttonPourTapWater.y = options.height - buttonStyle.margin - buttonStyle.radius * 4 - buttonStyle.gutter * 2 - buttonStyle.radius;
						buttonPourSparklingWater.x = options.width - buttonStyle.margin - buttonStyle.radius;
						buttonPourSparklingWater.y = options.height - buttonStyle.margin - buttonStyle.radius * 6 - buttonStyle.gutter * 4 - buttonStyle.radius;

						if(FountainFamily.LOCALE_ISO.length > 1) {
							buttonLanguageSelector.x = options.width - buttonStyle.margin - buttonStyle.radius;
							buttonLanguageSelector.y = options.height - buttonStyle.margin - buttonStyle.radius * 2 - buttonStyle.gutter - buttonStyle.radius;
							buttonLanguageSelector.visible = true;
						}


						if (options.allowKeyboardFocus) {
							FountainFamily.focusController.addElement(buttonPourSparklingWater);
							FountainFamily.focusController.addElement(buttonPourTapWater);
						}

						break;
				}
			}

			if (options.allowKeyboardFocus) {
				FountainFamily.focusController.onMovedFocus.add(onFocusControllerChangedFocus);
			}

			_onRequestedBrandView = new SimpleSignal();

			languageSignal = new SimpleSignal();

			selectBeverageSparklingWater();

			redrawVisibility();


            //For the unattended case
            if(FountainFamily.LOCKED_MODE && !BackendModel.UNLOCK_SUCCESS_STATE) {

                //Particles background
                //Using the Pepsi definition por the particles
                var beverage : Beverage = FountainFamily.inventory.getBeverageByRecipeId("7bf7f2ce-bb76-4c7a-a2ea-abae59354b1c");
                lockedParticles = new ParticleCreator(new ParticleCreatorFactoryLine(new Point(0, height), new Point(width, height), height), 3, 4, 2, beverage.getDesign());
                unlockViewContainer.addChild(lockedParticles);

                //Spire animated logo image
                spireLogo = new AnimatedImage(FountainFamily.textureLibrary.getSpireLockedMenuViewTexture(), 490, 314, 74, 30, 0);
                spireLogo.pivotX = spireLogo.width * 0.5;
                spireLogo.pivotY = spireLogo.height * 0.5;
                spireLogo.scaleX = spireLogo.scaleY = 1.4;
                spireLogo.y = height * 0.5 - 470;
                spireLogo.x = width * 0.5 - spireLogo.width * 0.5 * 1.3;
                unlockViewContainer.addChild(spireLogo);
                spireLogo.loop = true;

                unlockArrowImage = new Image(Texture.fromAtfData(new ImageLibrary.ICON_ARROW_UNLOCK()));
                unlockArrowImage.pivotX = unlockArrowImage.width * 0.5;
                unlockArrowImage.pivotY = unlockArrowImage.height * 0.5;
                unlockArrowImage.scaleX = unlockArrowImage.scaleY = 0.5;
                unlockArrowImage.y = height * 0.5 + 100;
                unlockArrowImage.x = FountainFamily.platform.scanHardwarePosition * width - 0.5 * unlockArrowImage.width;
                unlockViewContainer.addChild(unlockArrowImage);
                unlockArrowImage.alpha = 0;
                ZTween.add(unlockArrowImage, {y : height * 0.5 + 120, alpha: 1}, {time: 0.5, delay: 0.5});


                var unlockId:String = "";
                var unlockCopy : String = "";

                //For the request to scan.
                for(i = 0; i < FountainFamily.LOCALE_ISO.length; i ++) {
                    unlockId = "HomeViewUnlockScanRequest"  + "_"  + FountainFamily.LOCALE_ISO[i];
                    unlockCopy = StringList.getList(FountainFamily.LOCALE_ISO[i]).getString("unlock/scan-required");
                    if (!FountainFamily.objectRecycler.has(unlockId)) FountainFamily.objectRecycler.putNew(unlockId, new Image(TextBitmap.createTexture(unlockCopy, FontLibrary.BOOSTER_NEXT_FY_BOLD, null, 60, NaN, COLOR_TITLE_TOP, -1, 1, 1, 0, 0, TextSpriteAlign.CENTER, false)));
                    unlockRequestCopy[i] = FountainFamily.objectRecycler.get(unlockId);
                    unlockViewContainer.addChild(unlockRequestCopy[i]);
                    unlockRequestCopy[i].visible = false;
                    unlockRequestCopy[i].x = 0.5 * (width - unlockRequestCopy[i].width);
                    unlockRequestCopy[i].y = 0.5 * (height - unlockRequestCopy[i].height);
                }

                unlockRequestCopy[currentLanguage].visible = true;
                unlockRequestCopy[currentLanguage].alpha = 1;


                //For the scan processing.
                for(i = 0; i < FountainFamily.LOCALE_ISO.length; i ++) {
                    unlockId = "HomeViewUnlockScanProcessing"  + "_"  + FountainFamily.LOCALE_ISO[i];
                    unlockCopy = StringList.getList(FountainFamily.LOCALE_ISO[i]).getString("unlock/scan-processing");
                    if (!FountainFamily.objectRecycler.has(unlockId)) FountainFamily.objectRecycler.putNew(unlockId, new Image(TextBitmap.createTexture(unlockCopy, FontLibrary.BOOSTER_NEXT_FY_BOLD, null, 60, NaN, COLOR_TITLE_TOP, -1, 1, 1, 0, 0, TextSpriteAlign.CENTER, false)));
                    unlockProcessingCopy[i] = FountainFamily.objectRecycler.get(unlockId);
                    unlockViewContainer.addChild(unlockProcessingCopy[i]);
                    unlockProcessingCopy[i].visible = false;
                    unlockProcessingCopy[i].x = 0.5 * (width - unlockProcessingCopy[i].width);
                    unlockProcessingCopy[i].y = 0.5 * (height - unlockProcessingCopy[i].height);
                }

                /*
                * Errors are a little tricky here
                * there's an open list that would have to be translated, this means that errors have to be saved inside an error object
                * There's a static function used to display the corresponding error using the language and the id from the backend.
                * */

                var errorData : XMLList = XMLList(StringList.getList(FountainFamily.LOCALE_ISO[0]).getString("unlock/scan-error-2"));
                var numErrors : uint = errorData.children().length();


                for(var j : uint = 0; j < numErrors; j ++) {

                    var errorImages : Vector.<Image> = new Vector.<Image>();
                    var errorId : uint = errorData.children()[j].@id;

                    for(i = 0; i < FountainFamily.LOCALE_ISO.length; i ++) {
                        var errors : XMLList = XMLList(StringList.getList(FountainFamily.LOCALE_ISO[i]).getString("unlock/scan-error-2"));
                        unlockId = "HomeViewUnlockError" + "_"  + FountainFamily.LOCALE_ISO[i] + "_" + errorId;
                        unlockCopy = errors.children()[j];

                        if (!FountainFamily.objectRecycler.has(unlockId)) FountainFamily.objectRecycler.putNew(unlockId, new Image(TextBitmap.createTexture(unlockCopy, FontLibrary.BOOSTER_NEXT_FY_BOLD, null, 60, NaN, COLOR_TITLE_TOP, -1, 1, 1, 0, 0, TextSpriteAlign.CENTER, false)));
                        var image : Image = FountainFamily.objectRecycler.get(unlockId);
                        unlockViewContainer.addChild(image);
                        image.x = 0.5 * (width - image.width);
                        image.y = 0.5 * (height - image.height);
                        errorImages.push(image);
                    }

                    unlockErrors.push(new UnlockError(errorId, errorImages));
                }

                if(BackendModel.UNLOCK_ERROR_STATE) {
                    errorDisplayed = null;

                    for(i = 0; i < unlockErrors.length; i ++) {
                        if(unlockErrors[i].id == BackendModel.UNLOCKED_ERROR) errorDisplayed = unlockErrors[i].showError(currentLanguage);
                        else unlockErrors[i].hideErrors();
                    }

                    if(errorDisplayed != null) {
                        errorDisplayed.alpha = 1;
                    }

                    unlockRequestCopy[currentLanguage].visible = false;
                    unlockRequestCopy[currentLanguage].alpha = 0;
                    unlockArrowImage.alpha = 0;
                    ZTween.remove(unlockArrowImage);
                }

                if (BackendModel.UNLOCK_PROCESSING_STATE) {
                    unlockProcessingCopy[currentLanguage].visible = true;
                    unlockProcessingCopy[currentLanguage].alpha = 1;
                    unlockRequestCopy[currentLanguage].visible = false;
                    unlockRequestCopy[currentLanguage].alpha = 0;
                    unlockArrowImage.alpha = 0;
                    spireLogo.play();
                    spireLogo.loop = true;
                    ZTween.remove(unlockArrowImage);
                }

                //When the machine is unlocked (success status from backend)
                FountainFamily.backendModel.addEventListener(BackendModel.EVENT_UNLOCKED_AUTHORIZE, onUnlockAuthorize);

                //When the machine is unlocked (success status from backend)
                FountainFamily.backendModel.addEventListener(BackendModel.EVENT_UNLOCKED_SUCCESS, onUnlockSuccess);

                //Launched when the backend emits an error from the scanning
                FountainFamily.backendModel.addEventListener(BackendModel.EVENT_UNLOCKED_ERROR, onUnlockError);

            }

		}

		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function redrawVisibility():void {

            visible = _brandTransitionPhase < 1;

            _uiVisibility = MathUtils.map(_brandTransitionPhase, 0, 0.3, 1, 0, true);

            if (buttonPourTapWater != null) buttonPourTapWater.visibility = _uiVisibility;
            if (buttonPourSparklingWater != null) buttonPourSparklingWater.visibility = sparklingAvailable ? _uiVisibility : 0;
            if (buttonLanguageSelector != null) buttonLanguageSelector.visibility = _uiVisibility;

            var unlockVisible : Number  = (FountainFamily.LOCKED_MODE && !BackendModel.UNLOCK_SUCCESS_STATE) ? 0 : uiVisibility;

            for(var i : uint = 0; i < FountainFamily.LOCALE_ISO.length; i ++) {
                if (imageTitleTop[i] != null) {
                    imageTitleTop[i].alpha = unlockVisible;
                    imageTitleTop[i].y = MathUtils.map(Equations.expoOut(unlockVisible), 0, 1, - imageTitleTop[i].height, options.marginTitleTop);
                }

                if (imageTitleBottom[i] != null) {
                    imageTitleBottom[i].alpha = unlockVisible;
                    imageTitleBottom[i].y = MathUtils.map(Equations.expoOut(unlockVisible), 0, 1, - imageTitleBottom[i].height, options.marginTitleTop + imageTitleTop[i].height + options.marginTitleBottom);
                }
            }

            mainMenu.brandTransitionPhase = _brandTransitionPhase;
            mainMenu.hiddenTransitionPhase = 1 - unlockVisible;

            var s:Number = MathUtils.map(Equations.quadOut(1 - unlockVisible), 1, 0, 1, 0.9);
            mainMenuContainer.scaleX = mainMenuContainer.scaleY = s;
            mainMenuContainer.x = FountainFamily.platform.width * (1-s) * 0.5;
            mainMenuContainer.y = FountainFamily.platform.height * (1-s) * 0.5;

		}

		private function selectBeverageSparklingWater():void {
			FountainFamily.backendModel.selectBeverage(FountainFamily.inventory.getBeverageSparklingWater().recipeId);
		}

		private function startPourSparklingWater():void {
			selectBeverageSparklingWater();
			FountainFamily.backendModel.startPour();
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

        private function onUnlockError(e : Event) : void {

            var animationTime : Number = 0.4;

            spireLogo.loop = false;

            if(BackendModel.UNLOCK_ERROR_STATE) {
                errorDisplayed = null;

                for(var i : uint = 0; i < unlockErrors.length; i ++) {
                    if(unlockErrors[i].id == BackendModel.UNLOCKED_ERROR) errorDisplayed = unlockErrors[i].showError(currentLanguage);
                    else unlockErrors[i].hideErrors();
                }

                ZTween.remove(unlockProcessingCopy[currentLanguage]);
                ZTween.remove(unlockArrowImage);

                ZTween.add(unlockProcessingCopy[currentLanguage], {alpha:0}, {time:animationTime});
                ZTween.add(unlockArrowImage, {alpha:0}, {time:animationTime});

                if(errorDisplayed != null) {
                    ZTween.remove(errorDisplayed);
                    ZTween.add(errorDisplayed, {alpha:1}, {time:animationTime, delay:animationTime});
                }
            }
        }

        private function onUnlockAuthorize(e : Event) : void {
            var animationTime : Number = 0.4;
            if(BackendModel.UNLOCK_PROCESSING_STATE) {
                spireLogo.play();
                spireLogo.loop = true;
                unlockProcessingCopy[currentLanguage].alpha = 0;
                unlockProcessingCopy[currentLanguage].visible = true;

                ZTween.remove(unlockProcessingCopy[currentLanguage]);
                ZTween.remove(unlockRequestCopy[currentLanguage]);
                ZTween.remove(unlockArrowImage);

                ZTween.add(unlockRequestCopy[currentLanguage], {alpha:0}, {time:animationTime});
                ZTween.add(unlockArrowImage, {alpha:0}, {time:animationTime});

                if(errorDisplayed != null && errorDisplayed.alpha > 0) {
                    ZTween.remove(errorDisplayed);
                    ZTween.add(errorDisplayed, {alpha:0}, {time:animationTime});
                }

                ZTween.add(unlockProcessingCopy[currentLanguage], {alpha:1}, {time:animationTime, delay:animationTime});
            }
        }

        private function onUnlockSuccess(e : Event) : void {
            var animationTime : Number = 0.4;
            if(BackendModel.UNLOCK_SUCCESS_STATE) {
                unlockViewContainer.alpha = 0;
                animator.parameter = 0;
                spireLogo.stop();

                ZTween.remove(unlockViewContainer);
                ZTween.add(unlockViewContainer, {alpha:0}, {time:animationTime, onComplete:function(): void {

                    ZTween.remove(animator);
                    ZTween.add(animator, {parameter:1}, {time: 0.9, onUpdate:function(): void {

                        for(var i : uint = 0; i < FountainFamily.LOCALE_ISO.length; i ++) {
                            if (imageTitleTop[i] != null) {
                                imageTitleTop[i].alpha = animator.parameter;
                                imageTitleTop[i].y = MathUtils.map(Equations.expoOut(animator.parameter), 0, 1, - imageTitleTop[i].height, options.marginTitleTop);
                            }

                            if (imageTitleBottom[i] != null) {
                                imageTitleBottom[i].alpha = animator.parameter;
                                imageTitleBottom[i].y = MathUtils.map(Equations.expoOut(animator.parameter), 0, 1, - imageTitleBottom[i].height, options.marginTitleTop + imageTitleTop[i].height + options.marginTitleBottom);
                            }
                        }

                        mainMenu.brandTransitionPhase = 0;
                        mainMenu.hiddenTransitionPhase = 1 - animator.parameter;

                        var s:Number = MathUtils.map(Equations.quadOut(1-animator.parameter), 1, 0, 1, 0.9);
                        mainMenuContainer.scaleX = mainMenuContainer.scaleY = s;
                        mainMenuContainer.x = FountainFamily.platform.width * (1-s) * 0.5;
                        mainMenuContainer.y = FountainFamily.platform.height * (1-s) * 0.5;

                    }});
                }
                });
            }
        }

        private function onLanguageSelectorReleased(__button:BlobButton): void {
			languageSignal.dispatch();
		}

		private function onTappedMainMenuBlob(__beverageId:String):void {
			FountainFamily.backendModel.trackButtonPressed(StringList.getList(FountainFamily.current_language).getString("tracking/home-button-tap-brand").split("[[brand]]").join(__beverageId));
			_onRequestedBrandView.dispatch(__beverageId);
		}

		private function onTapWaterPressed(__button:BlobButton):void {
			FountainFamily.backendModel.startPourWater();
			FountainFamily.backendModel.trackButtonPressed(StringList.getList(FountainFamily.current_language).getString("tracking/home-button-pour-tap-water"));
		}

		private function onTapWaterReleased(__button:BlobButton):void {
			FountainFamily.backendModel.stopPourWater();
		}

		private function onSparklingWaterPressed(__button:BlobButton):void {
			startPourSparklingWater();
			FountainFamily.backendModel.trackButtonPressed(StringList.getList(FountainFamily.current_language).getString("tracking/home-button-pour-sparkling-water"));
		}

		private function onSparklingWaterReleased(__button:BlobButton):void {
			FountainFamily.backendModel.stopPour();
		}

		private function onFocusControllerChangedFocus():void {
			// The focus changed, so select the beverage if it's a BrandBeverageButton (so a press on the pour button can be quicker)
			if (buttonsEnabled && !FountainFamily.backendModel.isPouringAnything()) {
				//log ("Focus on ==> " + FountainFamily.focusController.currentFocusedElement);
				if (FountainFamily.focusController.currentFocusedElement is BlobSpritesInfo) {
					var beverage:Beverage = (FountainFamily.focusController.currentFocusedElement as BlobSpritesInfo).beverage;
					FountainFamily.backendModel.selectBeverage(beverage.recipeId, FountainFamily.inventory.getFlavorRecipeIds(beverage.getValidPreselectedFlavorIds()));
				}
			}
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function setFocusedBeverageInfo(__beverageId:String, __centerPoint:Point, __centerRadius):void {
			mainMenu.setFocusedBeverageId(__beverageId);
			mainMenu.setFocusedBeverageCenter(__centerPoint, __centerRadius);
		}

//		private function update(__currentTimeSeconds:Number, __tickDeltaTimeSeconds:Number, __currentTick:int):void {
//		}

		public function executeHardwareADACommand(__command:String):void {
			switch(__command) {
				case FountainFamily.HARDWARE_COMMAND_POUR_BEVERAGE_START:
					if (FountainFamily.focusController.currentFocusedElement is BlobSpritesInfo && !FountainFamily.backendModel.isPouringAnything()) {
						// Pour current beverage
						FountainFamily.backendModel.startPour();
					} else if (buttonPourTapWater != null && FountainFamily.focusController.currentFocusedElement == buttonPourTapWater && !FountainFamily.backendModel.isPouringAnything()) {
						// Pour water
						FountainFamily.backendModel.startPourWater();
					} else if (buttonPourSparklingWater != null && FountainFamily.focusController.currentFocusedElement == buttonPourSparklingWater && !FountainFamily.backendModel.isPouringAnything()) {
						// Pour sparkling water
						startPourSparklingWater();
					}
					break;
				case FountainFamily.HARDWARE_COMMAND_POUR_BEVERAGE_STOP:
					FountainFamily.backendModel.stopPour();
					FountainFamily.backendModel.stopPourWater();
					break;
				case FountainFamily.HARDWARE_COMMAND_POUR_WATER_START:
					if (!FountainFamily.backendModel.isPouringAnything()) FountainFamily.backendModel.startPourWater();
					break;
				case FountainFamily.HARDWARE_COMMAND_POUR_WATER_STOP:
					FountainFamily.backendModel.stopPourWater();
					break;
				case FountainFamily.HARDWARE_COMMAND_NAVIGATE_BACK:
					// Nothing?
					break;
			}
		}

		public function setButtonsEnabled(__enabled:Boolean):void {
			// Updates whether the buttons are focusable or not

			buttonsEnabled = __enabled;
			if (buttonPourTapWater != null) buttonPourTapWater.enabled = __enabled ? 1 : 0;
			if (buttonPourSparklingWater != null) buttonPourSparklingWater.enabled = __enabled ? 1 : 0;
			mainMenu.setButtonsEnabled(__enabled);
		}

		public function performAutoTestActions(__testingOverlay:TestingOverlay):void {
			// Do everything required by the auto tests

			var ts:Number = 1/FountainFamily.timeScale;

			var waterTime:Number = FountainFamily.configList.getNumber("debug/auto-test/water-pour-time");
			if (isNaN(waterTime) || waterTime <= 0) waterTime = 0.1;
			waterTime *= RandomGenerator.getInRange(100, 1000) * ts;

			var waitTime:Number = FountainFamily.configList.getNumber("debug/auto-test/wait-time");
			if (isNaN(waitTime) || waitTime <= 0) waitTime = 0.1;
			waitTime *= RandomGenerator.getInRange(100, 1000) * ts;

			var ttime:Number = 0;

			// Initial wait
			ttime += RandomGenerator.getInRange(401, 5000) * ts;

			if (FountainFamily.configList.getBoolean("debug/auto-test/water-pour-enabled") && !FountainFamily.DEBUG_DISABLE_TESTING_POURING) {
				if (buttonPourTapWater != null) {
					DelayedCalls.add(ttime, buttonPourTapWater.simulateEnterDown);
					DelayedCalls.add(ttime - 400 * ts, __testingOverlay.animateHand, [true, buttonPourTapWater.x + x, buttonPourTapWater.y + y]);
					ttime += waterTime;
					DelayedCalls.add(ttime, buttonPourTapWater.simulateEnterUp);
					DelayedCalls.add(ttime - 400 * ts, __testingOverlay.animateHand, [false]);
				}

				ttime += waitTime;

				if (buttonPourSparklingWater != null) {
					DelayedCalls.add(ttime, buttonPourSparklingWater.simulateEnterDown);
					DelayedCalls.add(ttime - 400 * ts, __testingOverlay.animateHand, [true, buttonPourSparklingWater.x + x, buttonPourSparklingWater.y + y]);
					ttime += waterTime;
					DelayedCalls.add(ttime, buttonPourSparklingWater.simulateEnterUp);
					DelayedCalls.add(ttime - 400 * ts, __testingOverlay.animateHand, [false]);
				}

				ttime += waitTime;

				if (buttonLanguageSelector != null) {
					DelayedCalls.add(ttime, buttonLanguageSelector.simulateEnterDown);
					DelayedCalls.add(ttime - 400 * ts, __testingOverlay.animateHand, [true, buttonLanguageSelector.x + x, buttonLanguageSelector.y + y]);
					ttime += waterTime;
					DelayedCalls.add(ttime, buttonLanguageSelector.simulateEnterUp);
					DelayedCalls.add(ttime - 400 * ts, __testingOverlay.animateHand, [false]);
				}
			}

			DelayedCalls.add(ttime, mainMenu.simulatePickButton);
			ttime += waitTime;
			ttime += 10 * ts;
			DelayedCalls.add(ttime, mainMenu.simulateEnterDown);
			DelayedCalls.add(ttime - 400 * ts, __testingOverlay.animateHandDynamic, [true, mainMenu.getSimulatedButtonX, mainMenu.getSimulatedButtonY, x, y]);
			ttime += RandomGenerator.getInRange(100, 500) * ts;
			DelayedCalls.add(ttime, mainMenu.simulateEnterUp);
			DelayedCalls.add(ttime - 400 * ts, __testingOverlay.animateHand, [false]);
		}

		public function recreateRandomElements():void {
			mainMenu.recreateRandomElements();
		}

		public function pause():void {
			// Pauses all looper-based animation
			if (!isPaused) {
				mainMenu.pause();
				isPaused = true;
			}
		}

		public function resume():void {
			// Resumes all looper-based animation
			if (isPaused) {
				mainMenu.resume();
				isPaused = false;
			}
		}

		public function onPreShow():void {
			brandTransitionIsHiding = false;
			recreateRandomElements();

            if(FountainFamily.LOCKED_MODE && !BackendModel.UNLOCK_SUCCESS_STATE) {
                unlockViewContainer.alpha = 1;
                unlockRequestCopy[currentLanguage].alpha = 1;
                unlockProcessingCopy[currentLanguage].alpha = 0;
                unlockArrowImage.alpha = 0;
                unlockArrowImage.y = height * 0.5 + 100;
                spireLogo.frame = 0;
                if(errorDisplayed != null) errorDisplayed.alpha = 0;
            }

			if (FountainFamily.platform.supportsLightsAPI) {
				FountainFamily.backendModel.setLightColorARGB(FountainFamily.lightingInfo.colorStandby, FountainFamily.lightingInfo.timeColorChange * 1000, FountainFamily.lightingInfo.brightnessScale * FountainFamily.lightingInfo.brightnessAttractorMenu);
			}
		}

		public function onPostShow(__doNotTrack:Boolean = false):void {
			// Track
			if (!__doNotTrack) trackScreenChanged();
			setButtonsEnabled(true);
            if(FountainFamily.LOCKED_MODE && !BackendModel.UNLOCK_SUCCESS_STATE) ZTween.add(unlockArrowImage, {y : height * 0.5 + 120, alpha: 1}, {time: 0.5, delay: 1.5});
        }

		public function trackScreenChanged():void {
			FountainFamily.backendModel.trackScreenChanged(StringList.getList(FountainFamily.current_language).getString("tracking/scene-home"));
		}

		public function onPreHide():void {
			setButtonsEnabled(false);
			brandTransitionIsHiding = true;
		}

		public function onPostHide():void {

		}

		override public function dispose():void {
			
			for(var i : uint = 0; i < FountainFamily.LOCALE_ISO.length; i ++) {
				if (imageTitleTop[i] != null) {
					removeChild(imageTitleTop[i]);
					if (disposeWithoutRecycler) {
						imageTitleTop[i].dispose();
						imageTitleTop[i].texture.dispose();
					} else {
						FountainFamily.objectRecycler.putBack(imageTitleTop[i]);
					}
					imageTitleTop[i] = null;
				}

				if (imageTitleBottom[i] != null) {
					removeChild(imageTitleBottom[i]);
					if (disposeWithoutRecycler) {
						imageTitleBottom[i].dispose();
						imageTitleBottom[i].texture.dispose();
					} else {
						FountainFamily.objectRecycler.putBack(imageTitleBottom[i]);
					}
					imageTitleBottom[i] = null;
				}

                if (unlockRequestCopy[i] != null) {
                    unlockViewContainer.removeChild(unlockRequestCopy[i]);
                    if (disposeWithoutRecycler) {
                        unlockRequestCopy[i].dispose();
                        unlockRequestCopy[i].texture.dispose();
                    } else {
                        FountainFamily.objectRecycler.putBack(unlockRequestCopy[i]);
                    }
                    unlockRequestCopy[i] = null;
                }

                if (unlockProcessingCopy[i] != null) {
                    unlockViewContainer.removeChild(unlockProcessingCopy[i]);
                    if (disposeWithoutRecycler) {
                        unlockProcessingCopy[i].dispose();
                        unlockProcessingCopy[i].texture.dispose();
                    } else {
                        FountainFamily.objectRecycler.putBack(unlockProcessingCopy[i]);
                    }
                    unlockProcessingCopy[i] = null;
                }
			}

            if(FountainFamily.LOCKED_MODE) {
                removeChild(unlockViewContainer);
                unlockViewContainer = null;
                FountainFamily.backendModel.removeEventListener(BackendModel.EVENT_UNLOCKED_AUTHORIZE, onUnlockAuthorize);
                FountainFamily.backendModel.removeEventListener(BackendModel.EVENT_UNLOCKED_SUCCESS, onUnlockSuccess);
                FountainFamily.backendModel.removeEventListener(BackendModel.EVENT_UNLOCKED_ERROR, onUnlockError);

                if(unlockErrors != null) for(var j: uint = 0; j < unlockErrors.length; j ++) unlockErrors[j].dispose();

                unlockViewContainer.removeChild(lockedParticles);
                lockedParticles.dispose();
                lockedParticles = null;

                unlockViewContainer.removeChild(spireLogo);
                spireLogo.dispose();
                spireLogo = null;

                unlockViewContainer.removeChild(unlockArrowImage);
                unlockArrowImage.dispose();
                unlockArrowImage = null;
            }


			mainMenu.pause();
			mainMenu.setButtonsEnabled(false);
			mainMenu.onTappedBlob.remove(onTappedMainMenuBlob);
			mainMenuContainer.removeChild(mainMenu);
			if (disposeWithoutRecycler) {
				mainMenu.dispose();
			} else {
				FountainFamily.objectRecycler.putBack(mainMenu);
			}
			mainMenu = null;

			removeChild(mainMenuContainer);
			mainMenuContainer.dispose();
			mainMenuContainer = null;

			if (particleArea != null) {
				removeChild(particleArea, true);
				particleArea = null;
			}

			if (options.allowKeyboardFocus) {
				if (buttonPourTapWater != null) FountainFamily.focusController.removeElement(buttonPourTapWater);
				if (buttonPourSparklingWater != null) FountainFamily.focusController.removeElement(buttonPourSparklingWater);
				FountainFamily.focusController.onMovedFocus.remove(onFocusControllerChangedFocus);
			}

			if (buttonPourTapWater != null) {
				removeChild(buttonPourTapWater);
				buttonPourTapWater.stop();
				buttonPourTapWater.onPressed.remove(onTapWaterPressed);
				buttonPourTapWater.onReleased.remove(onTapWaterReleased);
				buttonPourTapWater.onPressCanceled.remove(onTapWaterReleased);
				if (disposeWithoutRecycler) {
					buttonPourTapWater.dispose();
				} else {
					FountainFamily.objectRecycler.putBack(buttonPourTapWater);
				}
				buttonPourTapWater = null;
			}

			if (buttonPourSparklingWater != null) {
				removeChild(buttonPourSparklingWater);
				buttonPourSparklingWater.stop();
				buttonPourSparklingWater.onPressed.remove(onSparklingWaterPressed);
				buttonPourSparklingWater.onReleased.remove(onSparklingWaterReleased);
				buttonPourSparklingWater.onPressCanceled.remove(onSparklingWaterReleased);
				if (disposeWithoutRecycler) {
					buttonPourSparklingWater.dispose();
				} else {
					FountainFamily.objectRecycler.putBack(buttonPourSparklingWater);
				}
				buttonPourSparklingWater = null;
			}


			if (buttonLanguageSelector != null) {
				removeChild(buttonLanguageSelector);
				buttonLanguageSelector.stop();
				buttonLanguageSelector.onReleased.remove(onLanguageSelectorReleased);
				if (disposeWithoutRecycler) {
					buttonLanguageSelector.dispose();
				} else {
					FountainFamily.objectRecycler.putBack(buttonLanguageSelector);
				}
				buttonLanguageSelector = null;
			}

			_onRequestedBrandView.removeAll();
			_onRequestedBrandView = null;

			super.dispose();
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function set language(value : uint) : void {
			for(var i: uint = 0; i < FountainFamily.LOCALE_ISO.length; i ++) {
				if(imageTitleTop[i] != null) 		imageTitleTop[i].visible = false;
				if(imageTitleBottom[i] != null) 	imageTitleBottom[i].visible = false;
			}
			if(imageTitleTop[value] != null) 		imageTitleTop[value].visible = true;
			if(imageTitleBottom[value] != null) 	imageTitleBottom[value].visible = true;
			if(mainMenu != null)					mainMenu.language(value);
			currentLanguage = value;
		}

        //This function is used to test the minimal height for the softwareAdaRoot to evaluate
        //the clickable area to return to the regular view.
        public function get waterButtonHeight() : Number {
            return buttonPourSparklingWater.y;
        }

		public function get brandTransitionPhase():Number {
			return _brandTransitionPhase;
		}
		public function set brandTransitionPhase(__value:Number):void {
			if (_brandTransitionPhase != __value) {
				_brandTransitionPhase = __value;
				redrawVisibility();
			}
		}

		public function get brandTransitionIsHiding():Boolean {
			return _brandTransitionIsHiding;
		}
		public function set brandTransitionIsHiding(__value:Boolean):void {
			_brandTransitionIsHiding = __value;
			mainMenu.brandTransitionIsHiding = __value;
		}

		public function get hiddenTransitionPhase():Number {
			return _hiddenTransitionPhase;
		}
		public function set hiddenTransitionPhase(__value:Number):void {
			if (_hiddenTransitionPhase != __value) {
				_hiddenTransitionPhase = __value;
				redrawVisibility();
			}
		}

		public function get hiddenTransitionIsHiding():Boolean {
			return _hiddenTransitionIsHiding;
		}
		public function set hiddenTransitionIsHiding(__value:Boolean):void {
			_hiddenTransitionIsHiding = __value;
			mainMenu.hiddenTransitionIsHiding = __value;
		}

		public function get onRequestedBrandView():SimpleSignal {
			return _onRequestedBrandView;
		}

		public function getFocusedBlobRect():Rectangle {
			// Finds the rectangle that the focused item is ocupying
			return mainMenu.getFocusedBlobRect();
		}

		public function getBlobSpriteInfoFromBeverageId(__beverageId:String):BlobSpritesInfo {
			return mainMenu.getBlobSpriteInfoFromBeverageId(__beverageId);
		}

		public function getMenuRect():Rectangle {
			var rect:Rectangle = mainMenu.getRealBounds().clone();
			rect.x += mainMenu.x;
			rect.y += mainMenu.y;
			return rect;
		}

		public function get uiVisibility():Number {
			return _uiVisibility;
		}

		override public function get width():Number {
			return options.width;
		}

		override public function get height():Number {
			return options.height;
		}

		// These setters are kind of dumb, but they're only set once and are here to force MainMenu to redraw the menu path's debugShape if it's on
		override public function set x(__value:Number):void {
			super.x = __value;
			if (mainMenu != null) mainMenu.x = mainMenu.x;
		}

		override public function set y(__value:Number):void {
			super.y = __value;
			if (mainMenu != null) mainMenu.x = mainMenu.x;
		}

		override public function set scaleX(__value:Number):void {
			super.scaleX = __value;
			if (mainMenu != null) mainMenu.x = mainMenu.x;
		}

		override public function set scaleY(__value:Number):void {
			super.scaleY = __value;
			if (mainMenu != null) mainMenu.x = mainMenu.x;
		}
	}
}
