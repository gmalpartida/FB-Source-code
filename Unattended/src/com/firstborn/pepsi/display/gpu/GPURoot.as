package com.firstborn.pepsi.display.gpu {
import com.firstborn.pepsi.common.backend.BackendModel;
import com.firstborn.pepsi.display.gpu.common.components.UnlockTimer;
import com.firstborn.pepsi.display.gpu.home.view.HomeView;
import com.firstborn.pepsi.tester.FountainFamilyTest;

import flash.utils.clearTimeout;

import flash.utils.setTimeout;

import starling.display.Quad;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;

	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.assets.ImageLibrary;
	import com.firstborn.pepsi.data.PlatformProfile;
	import com.firstborn.pepsi.data.home.MenuItemDefinition;
	import com.firstborn.pepsi.data.inventory.Beverage;
	import com.firstborn.pepsi.display.flash.TestingOverlay;
	import com.firstborn.pepsi.display.gpu.ada.SoftwareADARoot;
	import com.firstborn.pepsi.display.gpu.brand.view.BrandView;
	import com.firstborn.pepsi.display.gpu.common.BlobButtonStyle;
	import com.firstborn.pepsi.display.gpu.common.components.BlobButton;
	import com.firstborn.pepsi.display.gpu.common.components.BlobButtonLayer;
	import com.firstborn.pepsi.display.gpu.home.view.HomeView;
	import com.firstborn.pepsi.display.gpu.home.view.HomeViewOptions;
	import com.firstborn.pepsi.events.TouchHandler;
	import com.zehfernando.controllers.focus.FocusController;
	import com.zehfernando.localization.StringList;
	import com.zehfernando.signals.SimpleSignal;
	import com.zehfernando.transitions.Equations;
	import com.zehfernando.transitions.ZTween;
	import com.zehfernando.utils.DelayedCalls;
	import com.zehfernando.utils.MathUtils;
	import com.zehfernando.utils.RandomGenerator;
	import com.zehfernando.utils.console.log;

	import com.firstborn.pepsi.assets.FontLibrary;
	import com.firstborn.pepsi.display.gpu.common.TextBitmap;
	import com.firstborn.pepsi.display.gpu.common.TextureLibrary;
	import com.zehfernando.display.components.text.TextSpriteAlign;


	import flash.system.System;

	/**
	 * @author zeh fernando
	 */
	public class GPURoot extends Sprite {

		// Constants
		private static const SOFTWARE_ADA_COVER_ALPHA:Number = 0.015;			// Opacity of the normal UI when the software ADA is visible
		public static const TIME_BRAND_SHOW:Number = 1.3 * (FountainFamily.DEBUG_MAKE_BRAND_VIEW_TRANSITION_SLOW ? 6 : 1);
		public static const TIME_BRAND_HIDE:Number = 1.1 * (FountainFamily.DEBUG_MAKE_BRAND_VIEW_TRANSITION_SLOW ? 6 : 1);
		private static const TIME_SOFTWARE_ADA_SHOW:Number = 0.3;
		private static const TIME_SOFTWARE_ADA_HIDE:Number = 0.3;

		// Properties
		private var isAnimating:Boolean;
		private var _brandViewVisibility:Number;
		private var _visibility:Number;
		private var _softwareADAVisibility:Number;
		private var canActivateADA:Boolean;

		// Instances
		private var flashBox:Quad;
		private var homeView:HomeView;
		private var brandView:BrandView;
		private var standardUIContainer:Sprite;
		private var softwareADARoot:SoftwareADARoot;
		private var softwareADAContainer:Sprite;
		private var testingOverlay:TestingOverlay;

		private var buttonSoftwareADA:BlobButton;

		private var _onChangedView:SimpleSignal;
		private var logTouchHandler:TouchHandler;

		//For the language
		private var currentLanguage : uint = FountainFamily.DEFAULT_LANGUAGE;
		private var language_timeout : uint;

        //Quick hack to move the ADA button.
        private var leftAdaPosition : Number;
        private var rightAdaPosition : Number;

        //Countdown for the unlock status.
        private var unlockCountdown : UnlockTimer;

        private var paymentThanksCopy : Vector.<Image> = new Vector.<Image>(10);

        // ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function GPURoot() {
			_onChangedView = new SimpleSignal();
			scaleX = FountainFamily.platform.scaleX;
			scaleY = FountainFamily.platform.scaleY;

			if (FountainFamily.configList.getBoolean("debug/log-pointer-events") || FountainFamily.DEBUG_LOG_POINTER_EVENTS) {
				addEventListener(TouchEvent.TOUCH, onDebugTouch);

				logTouchHandler = new TouchHandler();
				logTouchHandler.onTapped.add(onDebugTouchTapped);
				logTouchHandler.onPressed.add(onDebugTouchPressed);
				logTouchHandler.onReleased.add(onDebugTouchReleased);
				logTouchHandler.onPressCanceled.add(onDebugTouchCanceled);
				logTouchHandler.attachTo(this);
			}

			//This sets all the buttons to change the language needed.
			BlobButton.language = currentLanguage;
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function showBrand(__beverageId:String):void {
			isAnimating = true;
			FountainFamily.attractorController.delayTime = 0;
			FountainFamily.focusController.enabled = false;

			brandViewVisibility = 0;

			brandView = new BrandView(FountainFamily.platform.getBrandViewOptions(PlatformProfile.VIEW_PROFILE_BRAND), __beverageId, currentLanguage);
			brandView.y = FountainFamily.platform.heightMinusMasthead - brandView.height;
			brandView.onTappedBack.add(onTappedBrandViewBack);
			standardUIContainer.addChildAt(brandView, 0);

			if (FountainFamily.backendModel.isPouringAnything()) FountainFamily.backendModel.stopPourEverything();

			homeView.onPreHide();
			homeView.setFocusedBeverageInfo(__beverageId, brandView.getLiquidCenterLocation(), brandView.getLiquidRadius());

			brandView.onPreShow();

			FountainFamily.focusController.checkValidityOfCurrentElement();

			clearGarbageCanQueue();

			ZTween.updateTime();

			ZTween.remove(this, "brandViewVisibility");
			ZTween.add(this, {brandViewVisibility:1}, {time:TIME_BRAND_SHOW, onComplete:onShownBrand});
		}

		private function hideBrand(__skipHomeView:Boolean = false):void {
			isAnimating = true;
			FountainFamily.focusController.enabled = false;

            if(buttonSoftwareADA != null && buttonSoftwareADA.x == leftAdaPosition) {
                buttonSoftwareADA.visibility = 0;
                buttonSoftwareADA.x = rightAdaPosition;
                ZTween.add(buttonSoftwareADA, {visibility:1}, {time:TIME_SOFTWARE_ADA_SHOW});
            }

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

		private function showSoftwareADAHome():void {
			// Switches to the "short" version of the interface (the "ADA" phase II, not to be confused with the previous ADA provided by FocusController)
			isAnimating = true;
			FountainFamily.attractorController.delayTime = 0;

			FountainFamily.focusController.enabled = false;

			homeView.setButtonsEnabled(false);
			//homeView.pause();
			homeView.touchable = false;
			if (buttonSoftwareADA != null) buttonSoftwareADA.setSelected(true);

			softwareADAVisibility = 0;

			softwareADARoot = new SoftwareADARoot(testingOverlay, currentLanguage);
            softwareADARoot.languageSignal.add(this.language);
			softwareADARoot.onChangedView.add(onSoftwareADAChangeView);
			softwareADARoot.onRequestedClose.add(onSoftwareADARequestedClose);
			softwareADARoot.touchable = false;
			softwareADAContainer.addChild(softwareADARoot);
			redrawSoftwareADAVisibility();

            softwareADARoot.adaButtonSignal.add(function(status) : void {

                ZTween.add(buttonSoftwareADA, {visibility:0}, {time:TIME_SOFTWARE_ADA_SHOW, onComplete: function() : void{
                    buttonSoftwareADA.x = status ? leftAdaPosition : rightAdaPosition;
                    ZTween.add(buttonSoftwareADA, {visibility:1}, {time:TIME_SOFTWARE_ADA_SHOW});
                }});

            });

			//if (FountainFamily.backendModel.isPouringAnything()) FountainFamily.backendModel.stopPourEverything();
            FountainFamily.backendModel.stopPourEverything();

			clearGarbageCanQueue();

			ZTween.updateTime();

			ZTween.remove(this, "softwareADAVisibility");
			ZTween.add(this, {softwareADAVisibility:1}, {time:TIME_SOFTWARE_ADA_SHOW, onComplete:onShownSoftwareADA});
		}

		private function hideSoftwareADAHome(__immediate:Boolean = false):void {

            if(buttonSoftwareADA.x == leftAdaPosition) {
                ZTween.add(buttonSoftwareADA, {visibility:0}, {time:TIME_SOFTWARE_ADA_SHOW, onComplete: function() : void{
                    buttonSoftwareADA.x = rightAdaPosition;
                    ZTween.add(buttonSoftwareADA, {visibility:1}, {time:TIME_SOFTWARE_ADA_SHOW});
                }});
            }

			isAnimating = true;
			FountainFamily.focusController.enabled = false;

			FountainFamily.attractorController.delayTime = 0;

			if (buttonSoftwareADA != null) buttonSoftwareADA.setSelected(false);

			//if (FountainFamily.backendModel.isPouringAnything()) FountainFamily.backendModel.stopPourEverything();
            FountainFamily.backendModel.stopPourEverything();

			if (!__immediate && FountainFamily.platform.supportsLightsAPI) {
				FountainFamily.backendModel.setLightColorARGB(FountainFamily.lightingInfo.colorStandby, TIME_SOFTWARE_ADA_HIDE * 1000, FountainFamily.lightingInfo.brightnessScale * FountainFamily.lightingInfo.brightnessAttractorMenu);
			}

			ZTween.updateTime();

			ZTween.remove(this, "softwareADAVisibility");

			if (__immediate) {
				softwareADAVisibility = 0;
				onHiddenSoftwareADA();
			} else {
				ZTween.add(this, {softwareADAVisibility:0}, {time:TIME_SOFTWARE_ADA_HIDE, onComplete:onHiddenSoftwareADA});
			}
		}

		private function redrawBrandViewVisibility():void {
			homeView.brandTransitionPhase = _brandViewVisibility;
			if (buttonSoftwareADA != null) {
                buttonSoftwareADA.visibility = homeView.uiVisibility;
            }

			if (brandView != null) {
                brandView.visibility = _brandViewVisibility;
				brandView.setLiquidClipRect(homeView.getFocusedBlobRect());
			}
		}

		private function redrawSoftwareADAVisibility():void {
			if (softwareADARoot != null) {
				softwareADARoot.visibility = _softwareADAVisibility;
			}
			standardUIContainer.alpha = MathUtils.map(_softwareADAVisibility, 0, 1, 1, SOFTWARE_ADA_COVER_ALPHA);
		}

		private function redrawVisibility():void {
			alpha = Equations.quadOut(_visibility) * 0.5 + _visibility * 0.5;
			visible = _visibility > 0;

			homeView.hiddenTransitionPhase = 1-_visibility;
		}

		private function queueClearGarbageCanIfNeeded():void {
			// Remove an item from the garbage can if needed

			// Force clear a lot if necessary (only possible when running tests probably)
			if (FountainFamily.garbageCan.numItems > 30) {
				while (FountainFamily.garbageCan.numItems > 30) FountainFamily.garbageCan.clearOne();
				System.pauseForGCIfCollectionImminent(0.25);
				System.gc();
			}

			if (FountainFamily.garbageCan.numItems > 20) {
				// More aggressive cleanup if there's too many items
				DelayedCalls.add(100 / FountainFamily.timeScale, clearGarbageCan);
			} else if (FountainFamily.garbageCan.numItems > 10) {
				// Kinda agressive if there's a good number of items
				DelayedCalls.add(250 / FountainFamily.timeScale, clearGarbageCan);
			} else if (FountainFamily.garbageCan.numItems > 1) {
				// Not agressive at all if there's not too many items
				DelayedCalls.add(500 / FountainFamily.timeScale, clearGarbageCan);
			} else {
				// All done, final call
				DelayedCalls.add(500 / FountainFamily.timeScale, clearGarbageCan);
			}
		}

		private function clearGarbageCanQueue():void {
			DelayedCalls.remove(clearGarbageCan);
		}

		private function clearGarbageCan():void {
			// Remove an item from the garbage can if needed
			if (FountainFamily.garbageCan.numItems > 0) {
				// Something left
				FountainFamily.garbageCan.clearOne();
				queueClearGarbageCanIfNeeded();
			} else {
				// All done
				System.pauseForGCIfCollectionImminent(0.25);
				System.gc();
			}
		}

		private function performStartAutoTesting():void {
			// Initiate tests
			if ((Math.random() > FountainFamily.configList.getNumber("debug/auto-test/ada-activate-chance") || !canActivateADA || FountainFamily.DEBUG_DISABLE_TESTING_ADA) && !FountainFamily.DEBUG_TESTING_ALWAYS_SHOW_ADA) {
				// Normal: show home
				homeView.performAutoTestActions(testingOverlay);
			} else {
				// Show ADA instead

				var ts:Number = 1/FountainFamily.timeScale;
				var waitTime:Number = FountainFamily.configList.getNumber("debug/auto-test/wait-time") * 1000 * ts;

				var ttime:Number = 0;

				// Initial wait
				ttime += waitTime;
				ttime += RandomGenerator.getInRange(401, 800) * ts;

				DelayedCalls.add(ttime, buttonSoftwareADA.simulateEnterDown);
				DelayedCalls.add(ttime - 400 * ts, testingOverlay.animateHand, [true, buttonSoftwareADA.x, buttonSoftwareADA.y]);
				ttime += RandomGenerator.getInRange(100, 500) * ts;
				DelayedCalls.add(ttime, buttonSoftwareADA.simulateEnterUp);
				DelayedCalls.add(ttime - 400 * ts, testingOverlay.animateHand, [false]);

				ttime += waitTime * 2;

				DelayedCalls.add(ttime, performAutoTestActionsForSoftwareADARoot);
			}
		}

		private function performAutoTestActionsForSoftwareADARoot():void {
			// Proxy function; we can't reference the function from softwareADARoot since it doesn't exist yet
			softwareADARoot.performAutoTestActions(testingOverlay, true);
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		private function onHomeViewRequestedBrandView(__beverageId:String):void {
			if (!isAnimating && brandView == null) showBrand(__beverageId);
		}

		private function onSoftwareADAChangeView():void {
			_onChangedView.dispatch();
		}

		private function onSoftwareADARequestedClose():void {
			if (!isAnimating) hideSoftwareADAHome();
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

			FountainFamily.focusController.checkValidityOfCurrentElement();

			if (!__skipHomeView) homeView.onPostShow();
			brandView.onPostHide();

			standardUIContainer.removeChild(brandView);
			brandView.dispose();
			brandView = null;

			System.pauseForGCIfCollectionImminent(0.5);
			//System.gc();

			_onChangedView.dispatch();

			if (FountainFamily.isAutoTesting) performStartAutoTesting();

			//if (FountainFamily.garbageCan.numItems > 10) warn("Items in garbage can: " + FountainFamily.garbageCan.numItems);

			queueClearGarbageCanIfNeeded();
		}

		private function onShownSoftwareADA():void {
			homeView.pause();
			isAnimating = false;
			softwareADARoot.touchable = true;
			FountainFamily.focusController.enabled = FountainFamily.adaInfo.hardwareEnabled;
			FountainFamily.attractorController.delayTime = FountainFamily.attractorInfo.delayHomeADA;

            FountainFamily.backendModel.stopPourEverything();

            unlockCountdown.y = 50 + 800;

            _onChangedView.dispatch();

			// If the brand view exists (because the ADA was shown on top of it), remove it
			if (brandView != null) hideBrand(true);

			//if (FountainFamily.isAutoTesting) brandView.performAutoTestActions(testingOverlay);
		}

		private function onHiddenSoftwareADA():void {

			isAnimating = false;
			FountainFamily.focusController.enabled = FountainFamily.adaInfo.hardwareEnabled;
			FountainFamily.attractorController.delayTime = FountainFamily.attractorInfo.delayHome;

            FountainFamily.backendModel.stopPourEverything();

			softwareADAContainer.removeChild(softwareADARoot);
			softwareADARoot.onChangedView.remove(onSoftwareADAChangeView);
			softwareADARoot.onRequestedClose.remove(onSoftwareADARequestedClose);
			softwareADARoot.dispose();
			softwareADARoot = null;

            FountainFamily.focusController.checkValidityOfCurrentElement();

			if (FountainFamily.focusController.isActivated) FountainFamily.focusController.executeCommand(FocusController.COMMAND_DEACTIVATE);

			_onChangedView.dispatch();

            homeView.setButtonsEnabled(true);
            homeView.resume();
            homeView.touchable = true;
            homeView.trackScreenChanged();

			if (FountainFamily.isAutoTesting) performStartAutoTesting();

			//if (FountainFamily.garbageCan.numItems > 10) warn("Items in garbage can: " + FountainFamily.garbageCan.numItems);

            unlockCountdown.y = 50;

			queueClearGarbageCanIfNeeded();
		}

		private function onFlashedHideBox():void {
			flashBox.visible = false;
		}

		private function onTappedSoftwareADAButton(__button:BlobButton):void {
			if (!isAnimating) {
				if (isSoftwareADAActivated()) {
					FountainFamily.backendModel.trackButtonPressed(StringList.getList(FountainFamily.current_language).getString("tracking/home-button-tap-ada-off"));
				} else {
					FountainFamily.backendModel.trackButtonPressed(StringList.getList(FountainFamily.current_language).getString("tracking/home-button-tap-ada-on"));
				}
				toggleSoftwareADA();
			}
		}

		private function onFocusControllerActivationChanged():void {
			if (FountainFamily.focusController.isActivated && softwareADARoot == null && canActivateADA) {
				if (brandView == null) {
					// Hardware ADA activated: show software ADA too
					activateSoftwareADA();
					FountainFamily.focusController.resetCurrentElement(true);
				} else {
					/*
					// Invalid activation
					// This is hacky... do something else
					//FountainFamily.focusController.executeCommand(FocusController.COMMAND_DEACTIVATE_SILENT);
					*/
					// Also activate the software ADA when on a brand page; the brand page will close after that
					activateSoftwareADA();
					FountainFamily.focusController.resetCurrentElement(true);
				}

				// Activating: reset current element
				// FountainFamily.focusController.unsetCurrentElement(true);

				// Finally, toggle
				// FountainFamily.focusController.executeCommand(FocusController.COMMAND_ACTIVATION_TOGGLE);
			}
		}

		public function onComeBackFromIdleState(__doNotTrack:Boolean = false):void {

			homeView.onPreShow();
			homeView.onPostShow(__doNotTrack);
		}

		public function onGoToIdleState():void {

			if (brandView != null) {
				hideBrand(true);
			} else if (softwareADARoot != null) {
				hideSoftwareADAHome(true);
			} else {
				homeView.onPreHide();
				homeView.onPostHide();
			}

            unlockCountdown.alpha = 0;

			clearLanguageTimeout();
			language_timeout = setTimeout(function() : void {
				language(FountainFamily.DEFAULT_LANGUAGE);},
				FountainFamily.waitTimeForDefaultLanguage * 1000);

		}

		private function onDebugTouch(__e:TouchEvent):void {
			//var target:DisplayObject = __e.currentTarget as DisplayObject;

			for (var i:int = 0; i < __e.touches.length; i++) {
				switch (__e.touches[i].phase) {
					case TouchPhase.HOVER:
						log("[TOUCH x " + i + "] :: HOVER @ " + __e.touches[i].globalX + "," + __e.touches[i].globalY);
						break;
					case TouchPhase.BEGAN:
						log("[TOUCH x " + i + "] :: BEGAN @ " + __e.touches[i].globalX + "," + __e.touches[i].globalY);
						break;
					case TouchPhase.MOVED:
						log("[TOUCH x " + i + "] :: MOVED @ " + __e.touches[i].globalX + "," + __e.touches[i].globalY);
						break;
					case TouchPhase.ENDED:
						log("[TOUCH x " + i + "] :: ENDED @ " + __e.touches[i].globalX + "," + __e.touches[i].globalY);
						break;
					case TouchPhase.STATIONARY:
						log("[TOUCH x " + i + "] :: STATIONARY @ " + __e.touches[i].globalX + "," + __e.touches[i].globalY);
						break;
				}
			}
		}

		private function onDebugTouchTapped():void {
			log("==> TOUCH TAPPED ROOT");
		}

		private function onDebugTouchPressed():void {
			log("==> TOUCH PRESSED ROOT");
		}

		private function onDebugTouchReleased():void {
			log("==> TOUCH RELEASED ROOT");
		}

		private function onDebugTouchCanceled():void {
			log("==> TOUCH CANCELED ROOT");
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function clearLanguageTimeout() : void {
			clearTimeout(language_timeout);
		}

		public function init(__testingOverlay:TestingOverlay):void {
			// Creates all assets
			testingOverlay = __testingOverlay;

			var w:Number = FountainFamily.platform.width;
			var h:Number = FountainFamily.platform.heightMinusMasthead;

			// Duplicated from homeview
			var options:HomeViewOptions = FountainFamily.platform.getHomeViewOptions(PlatformProfile.VIEW_PROFILE_HOME);
			var buttonStyle:BlobButtonStyle = options.buttonStyle;

			isAnimating = false;
			_brandViewVisibility = 0;
			_softwareADAVisibility = 0;
			_visibility = 1;
			canActivateADA = MenuItemDefinition.getMenuItems().length > 0; // If the menu doesn't contain any items, ADA is not available

			standardUIContainer = new Sprite();
			addChild(standardUIContainer);

			homeView = new HomeView(FountainFamily.platform.getHomeViewOptions(PlatformProfile.VIEW_PROFILE_HOME), !canActivateADA);

			homeView.languageSignal.add(this.language);

			homeView.y = h - homeView.height;
			homeView.onRequestedBrandView.add(onHomeViewRequestedBrandView);
			standardUIContainer.addChild(homeView);

			softwareADAContainer = new Sprite();
			addChild(softwareADAContainer);

			if (canActivateADA) {
				// If the menu doesn't contain any items, ADA is not available
				buttonSoftwareADA = new BlobButton(
						buttonStyle.radius,
						new Vector.<String>(),
						[
							BlobButtonLayer.getStrokeBlob(HomeView.COLOR_BUTTON_STROKES_NEUTRAL, 0.8, BlobButton.STROKE_WIDTH_SMALL_THIN),
							BlobButtonLayer.getSolidStrokeBlob(HomeView.COLOR_BUTTON_FILL_COLOR, 1, HomeView.COLOR_BUTTON_STROKES_COLOR, 1, buttonStyle.strokeWidths[0])
						],
						0x000000, 0x000000,
						20, 20,
						false, false,
						1, 1,
						20, 20,
						buttonStyle.fontLeading,
						false, null, new ImageLibrary.ICON_ADA(), BlobButton.COLOR_ICON_BLUE, buttonStyle.iconScale);
				buttonSoftwareADA.x = w - buttonStyle.margin - buttonSoftwareADA.radius;

                rightAdaPosition = buttonSoftwareADA.x;
                leftAdaPosition = options.marginADAButtonLeft;

				buttonSoftwareADA.y = h - buttonStyle.margin - buttonSoftwareADA.radius;
				buttonSoftwareADA.onTapped.add(onTappedSoftwareADAButton);
				addChild(buttonSoftwareADA);
			}

			FountainFamily.focusController.enabled = FountainFamily.adaInfo.hardwareEnabled;

			flashBox = new Quad(FountainFamily.platform.width, FountainFamily.platform.height, 0xffffff);
			flashBox.visible = false;
			addChild(flashBox);

			FountainFamily.attractorController.delayTime = FountainFamily.attractorInfo.delayHome;

			FountainFamily.focusController.onActivationChanged.add(onFocusControllerActivationChanged);

			redrawBrandViewVisibility();
			redrawVisibility();

			homeView.onPreShow();
			homeView.onPostShow();

            //Create the thanks copy
            var paymentThanksId:String = "";
            var paymentThanksText : String = "";

            for(var i :uint = 0; i < FountainFamily.LOCALE_ISO.length; i ++) {
                paymentThanksId = "BrandViewPaymentThanks"  + "_" + 50 + FountainFamily.LOCALE_ISO[i];
                paymentThanksText = StringList.getList(FountainFamily.LOCALE_ISO[i]).getString("unlock/thanks");
                if (!FountainFamily.objectRecycler.has(paymentThanksId)) FountainFamily.objectRecycler.putNew(paymentThanksId, new Image(TextBitmap.createTexture(paymentThanksText, FontLibrary.BOOSTER_NEXT_FY_BOLD, null, 90, NaN, 0x33a2d1, -1, 1, 1, 0, 0, TextSpriteAlign.CENTER, false)));
                paymentThanksCopy[i] = FountainFamily.objectRecycler.get(paymentThanksId);
                addChild(paymentThanksCopy[i]);
                paymentThanksCopy[i].x = 0.5 * (1080 - paymentThanksCopy[i].width);
                paymentThanksCopy[i].y = 0.5 * 1920 - 0.5 * paymentThanksCopy[i].height;
                paymentThanksCopy[i].alpha = 0;
            }

            unlockCountdown = new UnlockTimer();
            unlockCountdown.x = 150;
            unlockCountdown.y = 50;
            addChild(unlockCountdown);

            FountainFamily.backendModel.addEventListener(BackendModel.EVENT_UPDATE_UNLOCK_COUNTDOWN, function() : void {
                unlockCountdown.update(BackendModel.UNLOCKED_TIME);
            });

            FountainFamily.backendModel.addEventListener(BackendModel.EVENT_UNLOCKED_SESSION_FINISH, function() : void {
                unlockCountdown.alpha = 0;
            })

			_onChangedView.dispatch();
		}

        public function showUnlockThanks(): void {
            ZTween.add(standardUIContainer, {alpha: 0}, {time: 0.8});
            ZTween.add(softwareADAContainer, {alpha: 0}, {time: 0.8});
            ZTween.add(paymentThanksCopy[0], {alpha: 1}, {time: 0.8, delay: 0.8});
            if (buttonSoftwareADA != null) ZTween.add(buttonSoftwareADA, {visibility: 0}, {time: 0.8});
        }

        public function hideUnlockThanks() : void {
            standardUIContainer.alpha = 1;
            softwareADAContainer.alpha = 1;
            buttonSoftwareADA.visibility = 1;
            paymentThanksCopy[0].alpha = 0;
        }

		public function startAutoTesting():void {
			// Start doing auto tests
			if (isAnimating) return;

			if (softwareADARoot != null) {
				// Continue from software ADA
				softwareADARoot.performAutoTestActions(testingOverlay, true);
			} else if (brandView != null) {
				// Continue from brand view
				brandView.performAutoTestActions(testingOverlay);
			} else {
				// Normal start
				performStartAutoTesting();
			}

			// Show hand
			testingOverlay.show();
		}

		public function stopAutoTesting():void {
			testingOverlay.hide();
		}

		public function flash():void {
			// Flashes the screen
			flashBox.visible = true;
			flashBox.alpha = 1;
			ZTween.remove(flashBox);
			ZTween.add(flashBox, {alpha:0}, {time:0.3, onComplete:onFlashedHideBox});
		}

		override public function dispose():void {
			homeView.disposeWithoutRecycler = true;
			standardUIContainer.removeChild(homeView, true);
			homeView = null;

			removeChild(softwareADAContainer, true);
			softwareADAContainer = null;

			removeChild(buttonSoftwareADA, true);
			buttonSoftwareADA = null;

			removeChild(flashBox, true);
			flashBox = null;

			removeChild(standardUIContainer);
			standardUIContainer = null;

			FountainFamily.focusController.onActivationChanged.remove(onFocusControllerActivationChanged);

			_onChangedView.removeAll();
			_onChangedView = null;

			testingOverlay = null;

			ZTween.remove(this);

			if (logTouchHandler != null) {
				removeEventListener(TouchEvent.TOUCH, onDebugTouch);
				logTouchHandler.dettachFrom(this);
			}

			super.dispose();
		}

		public function executeHardwareADACommand(__command:String):void {
			if (!isAnimating) {
				if (brandView != null) {
					brandView.executeHardwareADACommand(__command);
				} else {
					if (softwareADARoot != null) {
						softwareADARoot.executeHardwareADACommand(__command);
					} else {
						homeView.executeHardwareADACommand(__command);
					}
				}
			}
		}

		public function trackSceneAttractor():void {
			FountainFamily.backendModel.trackScreenChanged(StringList.getList(FountainFamily.current_language).getString("tracking/scene-attractor"));
		}

		public function trackHomeViewScreenChanged():void {
			homeView.trackScreenChanged();
		}

		public function activateSoftwareADA():void {
			if (!isAnimating && !isSoftwareADAActivated()) {
				showSoftwareADAHome();
				if (FountainFamily.platform.softwareADAAlwaysShowsFocus) {
					FountainFamily.focusController.resetCurrentElement(true);
					FountainFamily.focusController.executeCommand(FocusController.COMMAND_ACTIVATE);
				}
			}
		}

		public function deactivateSoftwareADA():void {
			if (!isAnimating && isSoftwareADAActivated()) {
				hideSoftwareADAHome();
			}
		}

		public function toggleSoftwareADA():void {
			if (!isAnimating) {
				if (isSoftwareADAActivated()) {
					deactivateSoftwareADA();
				} else {
					activateSoftwareADA();
				}
			}
		}

		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function language(value : int = -1) : void {
			//currentLanguage ++;
			//if(currentLanguage > 2) currentLanguage = 0;
			currentLanguage = (currentLanguage == 1) ? 0 : 1;
			if(value != -1) currentLanguage = value;
			homeView.language = currentLanguage;
			if(brandView != null) brandView.language = currentLanguage;
			if(softwareADARoot != null) softwareADARoot.language = currentLanguage;
			BlobButton.language = currentLanguage;
			FountainFamily.current_language = FountainFamily.LOCALE_ISO[currentLanguage];

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

		public function get softwareADAVisibility():Number {
			return _softwareADAVisibility;
		}
		public function set softwareADAVisibility(__value:Number):void {
			if (_softwareADAVisibility != __value) {
				_softwareADAVisibility = __value;
				redrawSoftwareADAVisibility();
			}
		}

		public function debug_getCurrentBeverage():Beverage {
			return brandView != null ? brandView.beverage : null;
		}

		public function debug_pauseHome():void {
			homeView.pause();
		}

		public function debug_resumeHome():void {
			homeView.resume();
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

		public function isSoftwareADAActivated():Boolean {
			return _softwareADAVisibility > 0.5;
		}

		public function getUniqueNavigationId():String {
			// Create a unique string id based on the current navigation
			// E.g.: "00_home", "01_brand-pepsi", "03_ada_brand-pepsi"

			const separatorMajor:String = "_";
			const separatorMinor:String = "-";
			var id:String = "";
			var currentBrandView:BrandView = brandView != null ? brandView : (softwareADARoot != null && softwareADARoot.getBrandView() != null ? softwareADARoot.getBrandView() : null);
			var hasBrand:Boolean = currentBrandView != null;

			// Number (0 = home, 1+ = brand)
			id += ("00" + (hasBrand ? (MenuItemDefinition.getMenuItemIndexByBeverageId(currentBrandView.beverage.id) + 1) : 0).toString(10)).substr(-2, 2);

			// ADA or not
			if (softwareADAVisibility == 1) id += separatorMinor + "ada";

			id += separatorMajor;

			// Section id
			id += hasBrand ? "brand" + separatorMinor + currentBrandView.beverage.id : "home";

			return id;
		}

		public function get onChangedView():SimpleSignal {
			return _onChangedView;
		}
	}
}
