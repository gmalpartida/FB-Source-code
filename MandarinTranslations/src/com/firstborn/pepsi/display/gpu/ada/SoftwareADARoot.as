package com.firstborn.pepsi.display.gpu.ada {
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;

	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.assets.FontLibrary;
	import com.firstborn.pepsi.data.PlatformProfile;
	import com.firstborn.pepsi.data.inventory.Beverage;
	import com.firstborn.pepsi.display.flash.TestingOverlay;
	import com.firstborn.pepsi.display.gpu.brand.view.BrandView;
	import com.firstborn.pepsi.display.gpu.common.TextBitmap;
	import com.firstborn.pepsi.display.gpu.common.TextureLibrary;
	import com.firstborn.pepsi.display.gpu.home.view.HomeView;
	import com.firstborn.pepsi.events.TouchHandler;
	import com.zehfernando.display.components.text.TextSpriteAlign;
	import com.zehfernando.localization.StringList;
	import com.zehfernando.signals.SimpleSignal;
	import com.zehfernando.transitions.ZTween;

	import flash.system.System;
	/**
	 * @author zeh fernando
	 */
	public class SoftwareADARoot extends Sprite {

		// Constants
		private static const TIME_BRAND_SHOW:Number = 1.3 * 0.5;		// 0.5 of GPURoot's time
		private static const TIME_BRAND_HIDE:Number = 1.1 * 0.5;		// 0.5 of GPURoot's time

        //This accounts the min height for the water buttons to be accounted on the non clickable
        //Area for the ADA mode. Used for the Spire 5.0 when the assets are too few to make a grid
        //space big enough to have the water buttons accounted on its space.
        private static const MIN_HEIGHT_FOR_WATER_BUTTONS : Number = 700;

		//Static value for the languages
		private static var currentLanguage : uint = 0;

		// Properties
		private var _visibility:Number;

		private var isAnimating:Boolean;
		private var _brandViewVisibility:Number;

		private var cover:Quad;
		private var clickableCover:Quad;
		private var menuHitArea:Quad; // Temp

		private var homeView:HomeView;

		private var clickableCoverTouchHandler:TouchHandler;

		// Instances
		private var testingOverlay:TestingOverlay;
		private var brandView:BrandView;

		private var _onChangedView:SimpleSignal;
		private var _onRequestedClose:SimpleSignal;

		//Vector containing all the images for the titles of the different languages
		private var imageMessage : Vector.<Image> = new Vector.<Image>(10);

        //Signal to activate the language of the parent.
        public var languageSignal : SimpleSignal;

        //Signal for the movement of the button
        public var adaButtonSignal : SimpleSignal;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function SoftwareADARoot(__testingOverlay:TestingOverlay, __language: uint = 0) {

			_visibility = 1;
			_brandViewVisibility = 0;
			testingOverlay = __testingOverlay;
			currentLanguage = __language;

			var w:Number = FountainFamily.platform.width;
			var h:Number = FountainFamily.platform.heightMinusMasthead;

			// Creates all assets

			// Cover
			cover = new Quad(w, h, 0xffffff);
			cover.alpha = 0;
			addChild(cover);

			// Menu
			homeView = new HomeView(FountainFamily.platform.getHomeViewOptions(PlatformProfile.VIEW_PROFILE_HOME_ADA));
			homeView.y = h - homeView.height;
			homeView.onRequestedBrandView.add(onHomeViewRequestedBrandView);
			addChild(homeView);

            //To change the language from the ADA view, it contains the homeView that will hear the change from the button
            languageSignal = new SimpleSignal();
            homeView.languageSignal.add(function() : void {
                languageSignal.dispatch();
            });

            adaButtonSignal = new SimpleSignal();

//			var mQuad:Quad = new Quad(homeView.width, homeView.height, 0x0000ff);
//			mQuad.y = homeView.y;
//			mQuad.alpha = 0.1;
//			addChild(mQuad);

			// Cover for closing
			clickableCover = new Quad(w, homeView.y, 0xff0000); // The height is changed later, once a new section is opened
			clickableCover.alpha = 0;
			addChild(clickableCover);

			if (FountainFamily.DEBUG_SHOW_CLICKABLE_ADA_COVER) {
				clickableCover.alpha = 0.4;

				menuHitArea = new Quad(100, 100, 0xffff00);
				menuHitArea.alpha = 0.4;
				addChild(menuHitArea);
			}

			clickableCoverTouchHandler = new TouchHandler();
			clickableCoverTouchHandler.onReleased.add(onTappedClickableCover);
			clickableCoverTouchHandler.attachTo(clickableCover);

			// Message for multiple languages
			var j : uint = 0;
			var messageString : String = "";
			var messageId : String = "";
			for(j = 0; j < FountainFamily.LOCALE_ISO.length; j ++) {
				messageId = "SoftwareADA_textMessage" + FountainFamily.LOCALE_ISO[j];
				if (!FountainFamily.objectRecycler.has(messageId)) FountainFamily.objectRecycler.putNew((messageId), new Image(TextBitmap.createTextures(new <TextBitmap>[new TextBitmap(StringList.getList(FountainFamily.LOCALE_ISO[j]).getString("ada/home/return-1"), FountainFamily.LANGUAGES_FONTS[j] ? FontLibrary.EXTERNAL_REGULAR : FontLibrary.BOOSTER_FY_REGULAR, null, 21, NaN, 0x3da5e7, -1, 1, 1, 50, 50, TextSpriteAlign.CENTER, w * 0.7), new TextBitmap(StringList.getList(FountainFamily.LOCALE_ISO[j]).getString("ada/home/return-2"), FountainFamily.LANGUAGES_FONTS[j] ? FontLibrary.EXTERNAL_REGULAR : FontLibrary.BOOSTER_FY_REGULAR, null, 26, NaN, 0x3da5e7, -1, 1, 1, 150, 150, TextSpriteAlign.CENTER, w * 0.7, 0, 10)], 4, false, true)));
				imageMessage[j] = FountainFamily.objectRecycler.get(messageId);
				imageMessage[j].touchable = false;
				imageMessage[j].pivotX = imageMessage[j].texture.nativeWidth * 0.5;
				imageMessage[j].pivotY = imageMessage[j].texture.nativeHeight * 0.445;
				imageMessage[j].x = Math.round(w * 0.5);
				imageMessage[j].y = Math.max(Math.round(imageMessage[j].height * 0.5), Math.round(FountainFamily.platform.height * FountainFamily.platform.softwareADAMessageY - FountainFamily.platform.mastheadHeight));
				imageMessage[j].smoothing = FountainFamily.platform.getTextureProfile(TextureLibrary.TEXTURE_ID_GENERIC_TEXT).smoothing;
				addChild(imageMessage[j]);
				imageMessage[j].visible = false;
			}

			imageMessage[currentLanguage].visible = true;

			_onChangedView = new SimpleSignal();
			_onRequestedClose = new SimpleSignal();

			redrawBrandViewVisibility();
			redrawVisibility();

			trackSceneHome();

			this.language = __language;
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function showBrand(__beverageId:String):void {

            adaButtonSignal.dispatch(true);

            isAnimating = true;
			FountainFamily.attractorController.delayTime = 0;
			FountainFamily.focusController.enabled = false;

			brandViewVisibility = 0;

			brandView = new BrandView(FountainFamily.platform.getBrandViewOptions(PlatformProfile.VIEW_PROFILE_BRAND_ADA), __beverageId, currentLanguage);
			brandView.y = FountainFamily.platform.heightMinusMasthead - brandView.height;
			brandView.onTappedBack.add(onTappedBrandViewBack);
			addChild(brandView);

			if (FountainFamily.backendModel.isPouringAnything()) FountainFamily.backendModel.stopPourEverything();

			homeView.onPreHide();
			homeView.setFocusedBeverageInfo(__beverageId, brandView.getLiquidCenterLocation(), brandView.getLiquidRadius());

			brandView.onPreShow();

			FountainFamily.focusController.checkValidityOfCurrentElement();

			//clearGarbageCanQueue();

			ZTween.updateTime();

			ZTween.remove(this, "brandViewVisibility");
			ZTween.add(this, {brandViewVisibility:1}, {time:TIME_BRAND_SHOW, onComplete:onShownBrand});
		}

		private function hideBrand(__skipHomeView:Boolean = false):void {

            adaButtonSignal.dispatch(false);

            isAnimating = true;
			FountainFamily.focusController.enabled = false;

			brandView.onPreHide();

            if(!__skipHomeView) homeView.onPreShow();
			FountainFamily.attractorController.delayTime = 0;

			if (FountainFamily.backendModel.isPouringAnything()) FountainFamily.backendModel.stopPourEverything();

			ZTween.updateTime();

			ZTween.remove(this, "brandViewVisibility");

			if (__skipHomeView) {
				brandViewVisibility = 0;
				onHiddenBrand(true);
			} else {
				ZTween.add(this, {brandViewVisibility:0}, {time:TIME_BRAND_HIDE, onComplete:onHiddenBrand});
			}
		}

		private function redrawVisibility():void {
			visible = _visibility > 0;
			alpha = _visibility;
		}

		private function redrawBrandViewVisibility():void {
			homeView.brandTransitionPhase = _brandViewVisibility;

			// Change the height of the cover based on which section is visible
			if (_brandViewVisibility < 0.5 || brandView == null) {

				// Home: set the bottom of the hit area to the top of the menu area
				//clickableCover.height = Math.min(MIN_HEIGHT_FOR_WATER_BUTTONS, homeView.y + homeView.getMenuRect().y);

                //Testing with the height of the tap water button.
				clickableCover.height = Math.min( homeView.waterButtonHeight, homeView.y + homeView.getMenuRect().y);

				if (menuHitArea != null) {
					menuHitArea.visible = true;
					menuHitArea.x = homeView.x + homeView.getMenuRect().x;
					menuHitArea.y = homeView.y + homeView.getMenuRect().y;
					menuHitArea.width = homeView.getMenuRect().width;
					menuHitArea.height = homeView.getMenuRect().height;
				}
			} else {
				// Brand view: set the bottom of the hit area to just above the logo
				clickableCover.height = brandView.y + brandView.getLogoTop();

				if (menuHitArea != null) menuHitArea.visible = false;
			}

			if (brandView != null) {
				brandView.visibility = _brandViewVisibility;
				brandView.setLiquidClipRect(homeView.getFocusedBlobRect());
			}
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		private function onTappedClickableCover():void {
			touchable = false;
			_onRequestedClose.dispatch();
		}

		private function onHomeViewRequestedBrandView(__beverageId:String):void {
			if (!isAnimating && brandView == null) showBrand(__beverageId);
		}

		private function onTappedBrandViewBack():void {
			if (!isAnimating) hideBrand();
		}

		private function onShownBrand():void {
			isAnimating = false;
			FountainFamily.focusController.enabled = FountainFamily.adaInfo.hardwareEnabled;
			FountainFamily.attractorController.delayTime = FountainFamily.attractorInfo.delayBrand;

			homeView.onPostHide();
			brandView.onPostShow();

			_onChangedView.dispatch();

			if (FountainFamily.isAutoTesting) brandView.performAutoTestActions(testingOverlay);
		}

		private function onHiddenBrand(__skipHomeView:Boolean = false):void {
			isAnimating = false;
			FountainFamily.focusController.enabled = FountainFamily.adaInfo.hardwareEnabled;
			FountainFamily.attractorController.delayTime = FountainFamily.attractorInfo.delayHome;

			var oldBeverage:Beverage = brandView.beverage;

			FountainFamily.focusController.checkValidityOfCurrentElement();

			if (!__skipHomeView) homeView.onPostShow();
			brandView.onPostHide();

			removeChild(brandView);
			brandView.dispose();
			brandView = null;

			System.pauseForGCIfCollectionImminent(0.5);
			//System.gc();

			_onChangedView.dispatch();

			if (FountainFamily.isAutoTesting) performAutoTestActions(testingOverlay);

			if (FountainFamily.focusController.isActivated && oldBeverage != null) {
				// Re-select the desired element
				FountainFamily.focusController.setCurrentElement(homeView.getBlobSpriteInfoFromBeverageId(oldBeverage.id));
			}

			//if (FountainFamily.garbageCan.numItems > 10) warn("Items in garbage can: " + FountainFamily.garbageCan.numItems);
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function performAutoTestActions(__testingOverlay:TestingOverlay, __firstTime:Boolean = false):void {
			// Do everything required by the auto tests

			if (!__firstTime && Math.random() <= FountainFamily.configList.getNumber("debug/auto-test/ada-deactivate-chance")) {
				// Deactivate
				_onRequestedClose.dispatch();
			} else {
				// Does its own actions
				homeView.performAutoTestActions(__testingOverlay);
			}
		}

		public function executeHardwareADACommand(__command:String):void {
			if (!isAnimating) {
				if (brandView != null) {
					brandView.executeHardwareADACommand(__command);
				} else {
					homeView.executeHardwareADACommand(__command);
				}
			}
		}

		public function trackSceneHome():void {
			FountainFamily.backendModel.trackScreenChanged(StringList.getList(FountainFamily.current_language).getString("tracking/scene-home-ada"));
		}

		override public function dispose():void {
			removeChild(homeView, true);
			homeView = null;

			removeChild(cover, true);
			cover = null;

			if (brandView != null) {
				removeChild(brandView);
				brandView.dispose();
				brandView = null;
			}

			clickableCoverTouchHandler.dettachFrom(this);
			clickableCoverTouchHandler.onReleased.remove(onTappedClickableCover);
			clickableCoverTouchHandler.dispose();
			clickableCoverTouchHandler = null;

			removeChild(clickableCover, true);
			clickableCover = null;

			for(var j : uint = 0; j < FountainFamily.LOCALE_ISO.length; j ++) {
				removeChild(imageMessage[j]);
				FountainFamily.objectRecycler.putBack(imageMessage[j]);
				imageMessage[j] = null;
			}


			testingOverlay = null;

			_onChangedView.removeAll();
			_onChangedView = null;

			_onRequestedClose.removeAll();
			_onRequestedClose = null;

			ZTween.remove(this);

			super.dispose();
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function set language(value : uint) : void {
			currentLanguage = value;
			for(var j : uint = 0; j < FountainFamily.LOCALE_ISO.length; j ++) if(imageMessage[j] != null) imageMessage[j].visible = false;
			if(imageMessage[value] != null) imageMessage[value].visible = true;
			if(homeView != null) homeView.language = value;
		}

		public function getBrandView():BrandView {
			// Used to get the unique id
			return brandView;
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

		public function get brandViewVisibility():Number {
			return _brandViewVisibility;
		}
		public function set brandViewVisibility(__value:Number):void {
			if (_brandViewVisibility != __value) {
				_brandViewVisibility = __value;
				redrawBrandViewVisibility();
			}
		}

		public function get onChangedView():SimpleSignal {
			return _onChangedView;
		}

		public function get onRequestedClose():SimpleSignal {
			return _onRequestedClose;
		}
	}
}
