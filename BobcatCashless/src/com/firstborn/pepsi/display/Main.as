package com.firstborn.pepsi.display {
import com.firstborn.pepsi.application.FountainFamily;

import starling.core.Starling;
	import starling.events.Event;

	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.assets.FontLibrary;
	import com.firstborn.pepsi.common.KeyIDConstants;
	import com.firstborn.pepsi.common.backend.BackendModel;
	import com.firstborn.pepsi.common.display.debug.ColorEditPanel;
	import com.firstborn.pepsi.common.display.debug.ImageCapturePanel;
	import com.firstborn.pepsi.common.display.pad.PadOverlay;
	import com.firstborn.pepsi.common.display.services.ServicesRequiredOverlay;
	import com.firstborn.pepsi.data.AttractorController;
	import com.firstborn.pepsi.display.flash.RichMessageOverlay;
	import com.firstborn.pepsi.display.flash.TestingOverlay;
	import com.firstborn.pepsi.display.gpu.GPURoot;
	import com.firstborn.pepsi.display.gpu.common.MastheadView;
	import com.firstborn.pepsi.display.gpu.common.TextureLibrary;
	import com.zehfernando.controllers.focus.FocusController;
	import com.zehfernando.data.BitmapDataPool;
	import com.zehfernando.data.types.Color;
	import com.zehfernando.display.containers.StageVideoSprite;
	import com.zehfernando.display.debug.ConsoleView;
	import com.zehfernando.display.debug.MouseHeatMap;
	import com.zehfernando.display.debug.MultiTouchHeatMap;
	import com.zehfernando.display.debug.QuickButtonPanel;
	import com.zehfernando.display.debug.statgraph.StatGraph;
	import com.zehfernando.display.progressbars.RectangleProgressBar;
	import com.zehfernando.display.shapes.Box;
	import com.zehfernando.input.GestureRecorder;
	import com.zehfernando.localization.StringList;
	import com.zehfernando.transitions.ZTween;
	import com.zehfernando.utils.AppUtils;
	import com.zehfernando.utils.DelayedCalls;
	import com.zehfernando.utils.console.debug;
	import com.zehfernando.utils.console.info;
	import com.zehfernando.utils.console.log;
	import com.zehfernando.utils.console.warn;

	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.display3D.Context3DRenderMode;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.geom.Rectangle;
	import flash.system.System;

	/**
	 * @author zeh fernando
	 */
	public class Main extends flash.display.Sprite {

		// Constants
		private static const TIME_FADE_TO_IDLE:Number = 0.8 * (FountainFamily.DEBUG_MAKE_IDLE_STATE_TRANSITION_SLOW ? 6 : 1);
		private static const TIME_FADE_FROM_IDLE:Number = 0.8 * (FountainFamily.DEBUG_MAKE_IDLE_STATE_TRANSITION_SLOW ? 6 : 1);

		// Properties
		private var isOutOfOrderShown:Boolean;
		private var needToTrackHomeWhenInteracted:Boolean;

		private var starlingRootCreated:Boolean;
		private var starlingContextCreated:Boolean;

		// Instances
		private var starling:Starling;
		private var gpuRoot:GPURoot;
		private var consoleView:ConsoleView;
		private var gestureRecorder:GestureRecorder;

		private var flashLayerContainer:Sprite;

		private var statGraph:StatGraph;
		private var colorEditPanel:ColorEditPanel;
		private var imageCapturePanel:ImageCapturePanel;
		private var gesturesPerformed:Vector.<String>;
		private var mouseHeatMap:MouseHeatMap;
		private var multiTouchHeatMap:MultiTouchHeatMap;
		private var coverOverlay:Sprite;
		private var padOverlay:PadOverlay;
		private var servicesRequired:ServicesRequiredOverlay;

		private var attractorVideo:StageVideoSprite;
		private var attractorVideoCover:Box;

		private var preloader:RectangleProgressBar;

		private var debugLightColorBox:Box;
		private var debugLightNozzleColorBox:Box;

		private var masthead:MastheadView;

		private var testingOverlay:TestingOverlay;
		private var messageOverlay:RichMessageOverlay;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function Main() {
			isOutOfOrderShown = false;
			scaleX = FountainFamily.platform.scaleX;
			scaleY = FountainFamily.platform.scaleY;
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function createPreloader():void {
			preloader = new RectangleProgressBar(0x000000, 0.7, 0x000000, 0.1);
			preloader.width = 100;
			preloader.height = 2;
			preloader.x = Math.round(FountainFamily.platform.width / 2 - preloader.width / 2);
			preloader.y = Math.round(FountainFamily.platform.height / 2 - preloader.height / 2);
			addChild(preloader);
		}

		private function updatePreloader():void {
			if (preloader != null) {
				var val:Number = 0;

				val += starlingContextCreated ? 10 : 0;
				val += starlingRootCreated ? 10 : 0;
				val += FountainFamily.textureLibrary == null ? 0 : FountainFamily.textureLibrary.getReadyPhase() * 79;
				val += gpuRoot != null ? 1 : 0;
				val /= 100;

				preloader.amount = val;
			}
		}

		private function hidePreloader():void {
			ZTween.add(preloader, {alpha:0}, {time:0.4, onComplete:destroyPreloader});
		}

		private function destroyPreloader():void {
			if (preloader != null) {
				removeChild(preloader);
				preloader = null;
			}
		}

		private function toggleColorPanel():void {
			// Toggle the color edit debug panel on and off
			if (colorEditPanel == null) {
				colorEditPanel = new ColorEditPanel(800, 700, gpuRoot);
				colorEditPanel.x = stage.width - colorEditPanel.width;
				colorEditPanel.y = 0;
				colorEditPanel.visible = false;
				addChild(colorEditPanel);
			}

			colorEditPanel.visible = !colorEditPanel.visible;
		}

		private function toggleImageCapturePanel():void {
			// Toggle the color edit debug panel on and off
			if (imageCapturePanel == null) {
				imageCapturePanel = new ImageCapturePanel(300, 300, starling, gpuRoot, masthead);
				imageCapturePanel.x = stage.width * 0.5 - imageCapturePanel.width * 0.5;
				imageCapturePanel.y = 30;
				imageCapturePanel.visible = false;
				addChild(imageCapturePanel);
			}

			imageCapturePanel.visible = !imageCapturePanel.visible;
			if (FountainFamily.DEBUG_DO_NOT_PLAY_MASTHEAD) {
				if (masthead != null) {
					if (imageCapturePanel.visible && !FountainFamily.DEBUG_DO_NOT_PLAY_MASTHEAD_WHILE_CAPTURING) {
						masthead.play();
					} else {
						masthead.pause();
					}
				}
			}
		}

		private function toggleStatGraph():void {
			// Turns the on-screen stats on and off
			if (starling.showStats) {
				// Hide stats
				starling.showStats = false;
				statGraph.visible = false;
			} else {
				// Show stats
				if (statGraph == null) createStatGraph();
				starling.showStats = true;
				statGraph.visible = true;
			}
		}

		private function toggleAutoImageCapturing():void {
			// Starts or stops the automatic capturing of all screens
			if (imageCapturePanel == null || !imageCapturePanel.visible) toggleImageCapturePanel();

			FountainFamily.isAutoImageCapturing = !FountainFamily.isAutoImageCapturing;

			warn("NOT ACTIVE YET");

			// TODO: finish this
			if (FountainFamily.isAutoImageCapturing) {
				//gpuRoot.startAutoImageCapturing();
			}
		}

		private function toggleAutoTest():void {
			// Starts or stops the automatic stress test
			(FountainFamily.isAutoTesting) ? stopAutoTest() : startAutoTest();
		}

		private function startAutoTest():void {
			if (!FountainFamily.isAutoTesting) {
				FountainFamily.isAutoTesting = true;
				gpuRoot.startAutoTesting();
			}
		}

		private function stopAutoTest():void {
			if (FountainFamily.isAutoTesting) {
				FountainFamily.isAutoTesting = false;
				gpuRoot.stopAutoTesting();
			}
		}

		private function toggleTimeScale(__speed:Number = 10):void {
			// Toggles timescale between normal and super fast
			if (FountainFamily.timeScale == 1) {
				FountainFamily.timeScale = __speed;
			} else {
				FountainFamily.timeScale = 1;
			}
		}

		private function createStatGraph():void {
			statGraph = new StatGraph(NaN, NaN, 1000);
			statGraph.x = stage.stageWidth - statGraph.width;
			flashLayerContainer.addChild(statGraph);
		}

		private function checkGesture(__params:String):Boolean {
			// Checks whether a gesture was performed or not
			if (__params != null) {
				var params:Array = __params.split(",");
				if (params.length == 2) {
					var gestureId:String = params[0];
					var gestureTimes:int = parseInt(params[1]);
					if (gestureTimes <= gesturesPerformed.length) {
						for (var i:int = 0; i < gestureTimes; i++) {
							if (gesturesPerformed[gesturesPerformed.length - gestureTimes + i] != gestureId) return false;
						}
						return true;
					}
				}
			}

			return false;
		}

		private function goToIdleState():void {
			if (!FountainFamily.isAutoTesting) {
				if (FountainFamily.focusController.isActivated) FountainFamily.focusController.executeCommand(FocusController.COMMAND_DEACTIVATE);
				hideGPURoot();
				//log("going idle, had user input = " + FountainFamily.attractorController.hasUserInteractedYet);
				if (FountainFamily.attractorController.hasUserInteractedYet) gpuRoot.trackSceneAttractor();
			}
		}

		private function comeBackFromIdleState(__userInitiated:Boolean = true):void {
			//log("Back from idle");
			if (attractorVideo != null) {
				// Assumes it's always going back to the main screen
				if (!__userInitiated) {
					// Going back because of the loop
					FountainFamily.attractorController.delayTime = FountainFamily.attractorInfo.delayHomeAfter;
					FountainFamily.attractorController.delayTimeAfterUserInput = FountainFamily.attractorInfo.delayHome;
				} else {
					// Normal going back
					FountainFamily.backendModel.trackButtonPressed(StringList.getList(FountainFamily.current_language).getString("tracking/attractor-interrupt"));
					FountainFamily.attractorController.delayTime = FountainFamily.attractorInfo.delayHome;
				}
				hideAttractorVideo();
				gpuRoot.onComeBackFromIdleState(!__userInitiated);
				needToTrackHomeWhenInteracted = !__userInitiated;
			}
		}

		private function registerUserInteraction():void {
			// User interacted
			if (!FountainFamily.attractorController.isInIdleState) {
				if (needToTrackHomeWhenInteracted) {
					needToTrackHomeWhenInteracted = false;
					gpuRoot.trackHomeViewScreenChanged();
				}
			}
		}

		private function hideGPURoot():void {
			// Creates a copy of the GPU Root

			gpuRoot.touchable = false;

			// Fades GPU
			ZTween.updateTime();
			ZTween.add(gpuRoot, {visibility:0}, {time:TIME_FADE_TO_IDLE, onComplete:onGPURootHidden});

			// Fades light color
			if (FountainFamily.platform.supportsLightsAPI) {
				FountainFamily.backendModel.setLightColorARGB(FountainFamily.attractorInfo.getColorAt(0), TIME_FADE_TO_IDLE * 1000, FountainFamily.lightingInfo.brightnessScale * FountainFamily.lightingInfo.brightnessAttractorMenu);
			}

			// Fades masthead
			if (masthead != null) {
				ZTween.add(masthead, {visibility:0}, {time:TIME_FADE_TO_IDLE});
			}
		}

		private function showGPURoot():void {
			gpuRoot.clearLanguageTimeout();
			if (!starling.stage3D.visible) {
				gpuRoot.visibility = 0;
				starling.render();
				starling.stage3D.visible = true;
				if(!FountainFamily.backendModel.isOutOfOrder) gpuRoot.touchable = true;
				FountainFamily.looper.resume();

				// Fades GPU copy
				ZTween.add(gpuRoot, {visibility:1}, {time:TIME_FADE_FROM_IDLE, onComplete:onGPURootShown});

				if (masthead != null) {
					if (!FountainFamily.DEBUG_DO_NOT_PLAY_MASTHEAD) masthead.play();
					ZTween.remove(masthead);
					masthead.visibility = 1;
				}
			}
		}

		private function showAttractorVideo():void {
			attractorVideo = new StageVideoSprite(FountainFamily.platform.widthScaled, FountainFamily.platform.heightScaled);
			attractorVideo.bufferTime = 0.1;
			attractorVideo.autoPlay = true;
			attractorVideo.load(FountainFamily.attractorInfo.file);
			if (FountainFamily.attractorInfo.loop) {
				attractorVideo.loop = true;
			} else {
				attractorVideo.loop = false;
				attractorVideo.addEventListener(StageVideoSprite.EVENT_PLAY_FINISH, onAttractorVideoFinish);
			}
			attractorVideo.playVideo();
			stage.addChild(attractorVideo);

			attractorVideoCover = new Box(FountainFamily.platform.width, FountainFamily.platform.height, 0xffffff);
			attractorVideoCover.alpha = 1;
			coverOverlay.addChild(attractorVideoCover);

			ZTween.updateTime();
			ZTween.add(attractorVideoCover, {alpha:0}, {time:TIME_FADE_TO_IDLE, delay:TIME_FADE_TO_IDLE * 0.2, onComplete:onAttractorVideoShown});

			// Change light colors
			if (FountainFamily.platform.supportsLightsAPI) {
				addEventListener(flash.events.Event.ENTER_FRAME, onEnterFrameUpdateAttractorLightColor);
			}
		}

		private function onEnterFrameUpdateAttractorLightColor(__e:flash.events.Event):void {
			var attractorColor:uint = FountainFamily.attractorInfo.getColorAt(attractorVideo.time);
			if (attractorVideoCover.alpha > 0) {
				// Transition from current color to attractor color
				FountainFamily.backendModel.setLightColorARGB(Color.interpolateAARRGGBB(FountainFamily.lightingInfo.colorStandby, attractorColor, attractorVideoCover.alpha), 0, FountainFamily.lightingInfo.brightnessScale * FountainFamily.lightingInfo.brightnessAttractorMenu);
			} else {
				// Attractor color
				FountainFamily.backendModel.setLightColorARGB(attractorColor, 0, FountainFamily.lightingInfo.brightnessScale * FountainFamily.lightingInfo.brightnessAttractorMenu);
			}
		}

		private function hideAttractorVideo():void {
			gpuRoot.clearLanguageTimeout();
			attractorVideoCover.visible = true;
			attractorVideoCover.alpha = 0;
			ZTween.add(attractorVideoCover, {alpha:1}, {time:TIME_FADE_FROM_IDLE, onComplete:onAttractorVideoHidden});
		}

		private function initFinal():void {
			// Everything initialized, start the application

			info("BitmapPool has " + BitmapDataPool.getPool().getNumUsedBitmaps() + " bitmaps being used, and " + BitmapDataPool.getPool().getNumAvailableBitmaps() + " bitmaps available");
			BitmapDataPool.getPool().clean(true);

			System.gc();
			System.pauseForGCIfCollectionImminent();

			// Initialize root
			gpuRoot = starling.root as GPURoot;
			gpuRoot.init(testingOverlay);

			// Init colors
			onStoppedPouring(null);

			// Play masthead
			if (masthead != null && !FountainFamily.DEBUG_DO_NOT_PLAY_MASTHEAD) masthead.play();

			// Wait for idle state
			FountainFamily.attractorController.startWaitingForInactiveState(true);

			// Other debug options
			if (FountainFamily.DEBUG_SHOW_PINPAD_ON_START) showPinPadOverlay();
			if (FountainFamily.DEBUG_SHOW_IMAGE_CAPTURE_ON_START && (imageCapturePanel == null || !imageCapturePanel.visible)) toggleImageCapturePanel();

			if (FountainFamily.backendModel.isOutOfOrder) onIsOutOfOrder(null);
		}

		private function showMessageOverlay(__message:String):void {
            if (gpuRoot != null) gpuRoot.touchable = false;
			messageOverlay.setText(__message);
            messageOverlay.updateLanguage();
			ZTween.remove(messageOverlay, "visibility");
			ZTween.add(messageOverlay, {visibility:1}, {time:0.3});
			isOutOfOrderShown = true;
		}

		private function hideMessageOverlay():void {
            if (gpuRoot != null) gpuRoot.touchable = true;
            ZTween.remove(messageOverlay, "visibility");
			ZTween.add(messageOverlay, {visibility:0}, {time:0.3});
			isOutOfOrderShown = false;
		}

		private function showPinPadOverlay():void {
            padOverlay.updateLanguage();
			padOverlay.show();
		}

		private function activateFocusControllerIfAllowedAutomatically():void {
			if (FountainFamily.platform.automaticADAActivation || (FountainFamily.platform.softwareADAAllowsKeyboardFocus && gpuRoot.isSoftwareADAActivated())) {
				FountainFamily.focusController.executeCommand(FocusController.COMMAND_ACTIVATE);
			}
		}

		private function initFlashLayer():void {
			// Initialize the flash standard interface (this is only done once, even if Main is deinit()ed/init()ed again)

			if (flashLayerContainer == null) {
				flashLayerContainer = new Sprite();
				flashLayerContainer.scaleX = FountainFamily.platform.scaleX;
				flashLayerContainer.scaleY = FountainFamily.platform.scaleY;
				stage.addChild(flashLayerContainer);

				if (FountainFamily.configList.getBoolean("debug/stats-visible") || FountainFamily.DEBUG_STATS_VISIBLE) {
					createStatGraph();
				}

				if (FountainFamily.configList.getBoolean("gestures/enabled") || FountainFamily.DEBUG_GESTURES_ENABLED) {
					gestureRecorder = new GestureRecorder(stage);
					gestureRecorder.addEventListener(GestureRecorder.EVENT_GESTURE_COMPLETED, onGestureRecorded);
				}

				// Cover for idle state
				coverOverlay = new Sprite();
				flashLayerContainer.addChild(coverOverlay);

				// Testing overlay
				testingOverlay = new TestingOverlay(0, FountainFamily.platform.mastheadHeight);
				testingOverlay.visibility = 0;
				flashLayerContainer.addChild(testingOverlay);

				// Message overlay for out-of-order message
				messageOverlay = new RichMessageOverlay();
				messageOverlay.visibility = 0;
				flashLayerContainer.addChild(messageOverlay);

				// Pin pad overlay
				padOverlay = new PadOverlay(FountainFamily.backendModel, FountainFamily.platform.serviceUIScale, FountainFamily.platform.serviceUIScale, FontLibrary.FUTURA_BOLD, FontLibrary.FUTURA_MEDIUM);
				padOverlay.addEventListener(PadOverlay.EVENT_SHOWN, onPinKeypadShown);
				padOverlay.addEventListener(PadOverlay.EVENT_HIDDEN, onPinKeypadHidden);
				padOverlay.width = FountainFamily.platform.width;
				padOverlay.height = FountainFamily.platform.height;
				flashLayerContainer.addChild(padOverlay);

				// List of services required
				servicesRequired = new ServicesRequiredOverlay(FountainFamily.backendModel, FountainFamily.platform.serviceUIScale);
				servicesRequired.x = FountainFamily.platform.width;
				flashLayerContainer.addChild(servicesRequired);

				// Debug interface
				if (FountainFamily.configList.getBoolean("debug/test-interface-visible") || FountainFamily.DEBUG_TEST_INTERFACE_VISIBLE) {
					initDebugInterface();
				}

				// Console overlay
				if (FountainFamily.configList.getBoolean("debug/console-available") || FountainFamily.DEBUG_CONSOLE_AVAILABLE) {
					consoleView = new ConsoleView("Version: " + FountainFamily.APP_VERSION + " build " + FountainFamily.APP_BUILD_NUMBER + " at " + FountainFamily.APP_BUILD_DATE);
					consoleView.width = FountainFamily.platform.width;
					consoleView.height = Math.round(0.25 * FountainFamily.platform.height);
					consoleView.addEventListener(ConsoleView.EVENT_OPENED, onConsoleOpened);
					consoleView.addEventListener(ConsoleView.EVENT_CLOSED, onConsoleClosed);
					consoleView.visibility = FountainFamily.configList.getBoolean("debug/console-starts-opened") || FountainFamily.DEBUG_CONSOLE_STARTS_OPENED ? 1 : 0;
					flashLayerContainer.addChild(consoleView);

					if (FountainFamily.configList.getBoolean("debug/draw-pointer-events") || FountainFamily.DEBUG_DRAW_POINTER_EVENTS) {
						mouseHeatMap = new MouseHeatMap();
						mouseHeatMap.width = FountainFamily.platform.width;
						mouseHeatMap.height = FountainFamily.platform.height;
						consoleView.addBackgroundChild(mouseHeatMap);
					}

					if (FountainFamily.configList.getBoolean("debug/draw-multi-touch-events") || FountainFamily.DEBUG_DRAW_MULTI_TOUCH_EVENTS) {
						multiTouchHeatMap = new MultiTouchHeatMap();
						multiTouchHeatMap.width = FountainFamily.platform.width;
						multiTouchHeatMap.height = FountainFamily.platform.height;
						consoleView.addBackgroundChild(multiTouchHeatMap);
					}

				}
			}
		}

		private function initDebugInterface():void {
			// Create test buttons
			var buttons:QuickButtonPanel = new QuickButtonPanel();
			buttons.x = 10;
			buttons.y = 100;
			flashLayerContainer.addChild(buttons);

			buttons.addButton("FULLSCREEN",			function(__e:flash.events.Event):void { stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE; Starling.current.context.dispose(); });

			buttons.addButton("TOGGLE AUTO TEST",	function(__e:flash.events.Event):void { toggleAutoTest(); });
			buttons.addButton("DE-INIT",			function(__e:flash.events.Event):void { deinit(); });
			buttons.addButton("RE-INIT",			function(__e:flash.events.Event):void { init(); });
			buttons.addButton("GO IDLE",			function(__e:flash.events.Event):void { FountainFamily.attractorController.goToIdleState(); });
			buttons.addButton("BACK FROM IDLE",		function(__e:flash.events.Event):void { FountainFamily.attractorController.leaveIdleState(); });
			buttons.addButton("GO IDLE & BACK",		function(__e:flash.events.Event):void { FountainFamily.attractorController.goToIdleState(); FountainFamily.attractorController.leaveIdleState(); });
			buttons.addButton("VIEWPORT",			function(__e:flash.events.Event):void { log(Starling.current.viewPort); });
			buttons.addButton("LOG #",				function(__e:flash.events.Event):void {
				var iis:*;
				var contextDataIds:Vector.<String> = new Vector.<String>();
				var bitmapFontIds:Vector.<String> = new Vector.<String>();
				var numPrograms:int = 0;
				if (Starling.current != null) {
					for (iis in Starling.current.contextData) {
						contextDataIds.push(iis);
					}
					for (iis in Starling.current.contextData["starling.display.TextField.BitmapFonts"]) {
						bitmapFontIds.push(iis);
					}
					for (iis in Starling.current.contextData["Starling.programs"]) {
						numPrograms++;
						//log("==> ", iis, Starling.current.contextData["Starling.programs"][iis]);
					}
				}
				log("---------------------------------------------");
				log("         GPU Programs: " + numPrograms);
				log("     GPU Bitmap fonts: " + bitmapFontIds.length); // + " (" + bitmapFontIds + ")");
				log("     GPU Context Data: " + contextDataIds.length); // + " (" + contextDataIds + ")");
				log("               Tweens: " + ZTween.getNumTweens());
				log("         DelayedCalls: " + DelayedCalls.getNumCalls());
				log("   GameLooper signals: " + FountainFamily.looper.onTicked.numItems + " + " + FountainFamily.looper.onTickedOncePerVisualFrame.numItems);
				log("  BackendModel events: " + FountainFamily.backendModel.getNumEventListeners());
				log("       BitmapDataPool: " + BitmapDataPool.getNumUsedBitmaps() + " used, " + BitmapDataPool.getNumAvailableBitmaps() +  " available at " + BitmapDataPool.getNumPools() + " pools");
				log("       ObjectRecycler: " + FountainFamily.objectRecycler.getNumObjects() + " exist, " + FountainFamily.objectRecycler.getNumObjectsFree() + " free");
				log("      FocusController: " + FountainFamily.focusController.numElements + " elements");
				log("---------------------------------------------");
			});
			buttons.addButton("LOG # POOLS",			function(__e:flash.events.Event):void {
				log("---------------------------------------------");
				log("ObjectRecycler: " + FountainFamily.objectRecycler.getNumObjects() + " exist, " + FountainFamily.objectRecycler.getNumObjectsFree() + " free");
				log(FountainFamily.objectRecycler.getObjectIds().join("\n"));
				log("---------------------------------------------");
			});
			buttons.addButton("CLEAR CONSOLE",			function(__e:flash.events.Event):void { consoleView.clear(); System.gc(); });
			buttons.addButton("TOGGLE COLOR PANEL",		function(__e:flash.events.Event):void { toggleColorPanel(); });
			buttons.addButton("TOGGLE IMAGE CAPTURE",	function(__e:flash.events.Event):void { toggleImageCapturePanel(); });
			buttons.addButton("CAPTURE ALL SCREENS", 	function(__e:flash.events.Event):void { toggleAutoImageCapturing(); });

			buttons.addNewColumn();
			buttons.addButton("OUT OF ORDER (A)",		function(__e:flash.events.Event):void { BackendModel.debug_injectOnOutOfOrder(); });
			buttons.addButton("OUT OF ORDER (B)",		function(__e:flash.events.Event):void { BackendModel.debug_injectOnOutOfOrder("OTHER MESSAGE"); });
			buttons.addButton("IN ORDER",				function(__e:flash.events.Event):void { BackendModel.debug_injectOnInOrder(); });
			buttons.addButton("CHANGE INVENTORY",		function(__e:flash.events.Event):void { BackendModel.debug_injectOnInventoryChanged(); });
			buttons.addButton("PAUSE HOME",				function(__e:flash.events.Event):void { gpuRoot.debug_pauseHome(); });
			buttons.addButton("RESUME HOME",			function(__e:flash.events.Event):void { gpuRoot.debug_resumeHome(); });
			buttons.addButton("TOGGLE TIME 10x",		function(__e:flash.events.Event):void { toggleTimeScale(); });
			buttons.addButton("TOGGLE TIME 20x",		function(__e:flash.events.Event):void { toggleTimeScale(20); });
			buttons.addButton("SHOW PIN PAD",			function(__e:flash.events.Event):void { showPinPadOverlay(); });
			buttons.addButton("GET: VERSION",			function(__e:flash.events.Event):void { log("==> " + ExternalInterface.call('function() { return document.getElementsByTagName("object")[0]["Get.Version"](); }')); });
			buttons.addButton("GET: BUILD NUMBER",		function(__e:flash.events.Event):void { log("==> " + ExternalInterface.call('function() { return document.getElementsByTagName("object")[0]["Get.BuildNumber"](); }')); });
			buttons.addButton("GET: BUILD DATE",		function(__e:flash.events.Event):void { log("==> " + ExternalInterface.call('function() { return document.getElementsByTagName("object")[0]["Get.BuildDate"](); }')); });
			buttons.addButton("SERVICE: ICE",			function(__e:flash.events.Event):void { BackendModel.debug_injectServiceChanged(["Ice"]); });
			buttons.addButton("SERVICE: TECHNICIAN",	function(__e:flash.events.Event):void { BackendModel.debug_injectServiceChanged(["Technician"]); });
			buttons.addButton("SERVICE: ALL OK",		function(__e:flash.events.Event):void { BackendModel.debug_injectServiceChanged([]); });
			buttons.addButton("SERVICE: ALL NOT OK",	function(__e:flash.events.Event):void { BackendModel.debug_injectServiceChanged([
				BackendModel.BACKEND_SERVICE_STATUS_ID_TECHNICIAN,
				BackendModel.BACKEND_SERVICE_STATUS_ID_CARTRIDGE,
				BackendModel.BACKEND_SERVICE_STATUS_ID_ICE,
				BackendModel.BACKEND_SERVICE_STATUS_ID_CO2_LEVEL,
				BackendModel.BACKEND_SERVICE_STATUS_ID_STILL_WATER_TEMP,
				BackendModel.BACKEND_SERVICE_STATUS_ID_CARB_WATER_TEMP,
				BackendModel.BACKEND_SERVICE_STATUS_ID_BRAND_SOLD_OUT,
				BackendModel.BACKEND_SERVICE_STATUS_ID_FLAVOR_SOLD_OUT
			]); });
			//buttons.addButton("TOGGLE STARLING VIS",	function(__e:flash.events.Event):void { starling.stage3D.visible = !starling.stage3D.visible; });
			//buttons.addButton("DESTROY CONTEXT",		function(__e:flash.events.Event):void { Starling.current.context.dispose(); });

			buttons.addNewColumn();
			buttons.addButton("HIDE MENU",				function(__e:flash.events.Event):void {
				// Similar to hideGPURoot()
				ZTween.updateTime();
				ZTween.add(gpuRoot, {visibility:0}, {time:TIME_FADE_TO_IDLE});
				if (masthead != null) ZTween.add(masthead, {visibility:0}, {time:TIME_FADE_TO_IDLE});
			});
			buttons.addButton("SHOW MENU",				function(__e:flash.events.Event):void {
				// Similar to showGPURoot()
				gpuRoot.visibility = 0;
				ZTween.add(gpuRoot, {visibility:1}, {time:TIME_FADE_FROM_IDLE});
				if (masthead != null) {
					if (!FountainFamily.DEBUG_DO_NOT_PLAY_MASTHEAD) masthead.play();
					ZTween.remove(masthead);
					masthead.visibility = 1;
				}
			});
			buttons.addButton("BACKEND: ADA ENTER",			function(__e:flash.events.Event):void { onBackendRequestedADAEnter(null); });
			buttons.addButton("BACKEND: ADA EXIT",			function(__e:flash.events.Event):void { onBackendRequestedADAExit(null); });
			buttons.addButton("BACKEND: AUTOTEST START",	function(__e:flash.events.Event):void { onBackendRequestedAutoTestStart(null); });
			buttons.addButton("BACKEND: AUTOTEST STOP",	    function(__e:flash.events.Event):void { onBackendRequestedAutoTestStop(null); });

			// Create light interface
			var bb:Box = new Box(100, 200, 0x666666);
			bb.x = FountainFamily.platform.width - bb.width;
			bb.y = 300;
			flashLayerContainer.addChild(bb);

			debugLightColorBox = new Box(90, 95, 0xffffff);
			debugLightColorBox.x = bb.x + 5;
			debugLightColorBox.y = bb.y + 5;
			debugLightColorBox.alpha = 0;
			flashLayerContainer.addChild(debugLightColorBox);

			debugLightNozzleColorBox = new Box(90, 95, 0xffffff);
			debugLightNozzleColorBox.x = bb.x + 5;
			debugLightNozzleColorBox.y = bb.y + 100;
			debugLightNozzleColorBox.alpha = 0;
			flashLayerContainer.addChild(debugLightNozzleColorBox);

			FountainFamily.backendModel.addEventListener(BackendModel.EVENT_LIGHT_COLOR_CHANGE, function(__e:flash.events.Event):void {
				// Light color has changed
				var tt:Number = FountainFamily.backendModel.getLightColorTransitionTime() / 1000;
				var nc:Color = FountainFamily.backendModel.getLightColor();
				ZTween.add(debugLightColorBox, {alpha:nc.a, colorR:nc.r, colorG:nc.g, colorB:nc.b}, {time:tt});
			});
			FountainFamily.backendModel.addEventListener(BackendModel.EVENT_LIGHT_NOZZLE_BRIGHTNESS_CHANGE, function(__e:flash.events.Event):void {
				// Nozzle light color has changed
				var tt:Number = FountainFamily.backendModel.getLightNozzleColorTransitionTime() / 1000;
				var nb:Number = FountainFamily.backendModel.getLightNozzleBrightness() / 255;
				ZTween.add(debugLightNozzleColorBox, {alpha:nb}, {time:tt});
			});
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		private function onStarlingContextCreated(__e:starling.events.Event):void {
			warn("Starling context created");

			starlingContextCreated = true;
			updatePreloader();
		}

		private function onStarlingRootCreated(__e:starling.events.Event):void {
			info("Starling " + Starling.VERSION + " root created; driver info: " + Starling.current.context.driverInfo);

			starlingRootCreated = true;
			updatePreloader();

			// Initialize global textures
			FountainFamily.textureLibrary = new TextureLibrary();
			FountainFamily.textureLibrary.addEventListener(TextureLibrary.EVENT_READY, onTextureLibraryReady);
			FountainFamily.textureLibrary.addEventListener(TextureLibrary.EVENT_PROGRESS, onTextureLibrarProgress);
			FountainFamily.textureLibrary.init();
		}

		private function onTextureLibrarProgress(__e:flash.events.Event):void {
			updatePreloader();
		}

		private function onTextureLibraryReady(__e:flash.events.Event):void {
			info("Textures created");

			FountainFamily.textureLibrary.removeEventListener(TextureLibrary.EVENT_READY, onTextureLibraryReady);

			updatePreloader();
			hidePreloader();

			initFinal();
		}

		private function onGestureRecorded(__e:flash.events.Event):void {
			// One gesture was recorded by the engine
			debug("Gesture recorded, id: " + gestureRecorder.getPreviousGestureId());

			if (gestureRecorder.getPreviousGestureId() != null) {
				gesturesPerformed.push(gestureRecorder.getPreviousGestureId());

				if (gpuRoot != null) gpuRoot.flash();

				// Checks all gestures
				if (checkGesture(FountainFamily.configList.getString("gestures/action-toggle-stats"))) {
					gesturesPerformed.length = 0;
					toggleStatGraph();
				} else if (checkGesture(FountainFamily.configList.getString("gestures/action-show-pinpad"))) {
					gesturesPerformed.length = 0;
					showPinPadOverlay();
				} else if (checkGesture(FountainFamily.configList.getString("gestures/action-toggle-auto-test"))) {
					gesturesPerformed.length = 0;
					toggleAutoTest();
				} else if (checkGesture(FountainFamily.configList.getString("gestures/action-toggle-time-scale-4"))) {
					gesturesPerformed.length = 0;
					toggleTimeScale(4);
				} else if (checkGesture(FountainFamily.configList.getString("gestures/action-toggle-time-scale-10"))) {
					gesturesPerformed.length = 0;
					toggleTimeScale(10);
				} else if (checkGesture(FountainFamily.configList.getString("gestures/action-toggle-time-scale-20"))) {
					gesturesPerformed.length = 0;
					toggleTimeScale(20);
				} else if (checkGesture(FountainFamily.configList.getString("gestures/action-toggle-time-scale-50"))) {
					gesturesPerformed.length = 0;
					toggleTimeScale(50);
				} else if (checkGesture(FountainFamily.configList.getString("gestures/action-toggle-color-panel"))) {
					gesturesPerformed.length = 0;
					toggleColorPanel();
				}
			}
		}

		private function onRequestPinKeypad(__e:flash.events.Event):void {
			showPinPadOverlay();
		}

		private function onPinKeypadShown(__e:flash.events.Event):void {
			if (gpuRoot != null) gpuRoot.touchable = false;
		}

		private function onPinKeypadHidden(__e:flash.events.Event):void {
			if (gpuRoot != null && !FountainFamily.backendModel.isOutOfOrder) gpuRoot.touchable = true;
		}

		private function onConsoleOpened(__e:flash.events.Event):void {
			if (!FountainFamily.DEBUG_CONSOLE_ALLOWS_TOUCH_EVENTS && gpuRoot != null) gpuRoot.touchable = false;
		}

		private function onConsoleClosed(__e:flash.events.Event):void {
			if (!FountainFamily.DEBUG_CONSOLE_ALLOWS_TOUCH_EVENTS && gpuRoot != null) gpuRoot.touchable = true;
		}

		private function onKeyCommandPressed(__command:String):void {
			if (FountainFamily.focusController.enabled && !FountainFamily.backendModel.isPouringAnything() && !isOutOfOrderShown && padOverlay.visibility == 0 && !FountainFamily.attractorController.isInIdleState) {
//				info(this + " key pressed: " + __command);
				if (FountainFamily.focusController.isActivated) {
					if (__command == KeyIDConstants.KEY_ID_FOCUS_ENTER)				FountainFamily.focusController.executeCommand(FocusController.COMMAND_ENTER_DOWN);
					if (__command == KeyIDConstants.KEY_ID_CUSTOM_POUR)				gpuRoot.executeHardwareADACommand(FountainFamily.HARDWARE_COMMAND_POUR_BEVERAGE_START);
					if (__command == KeyIDConstants.KEY_ID_CUSTOM_POUR_WATER)		gpuRoot.executeHardwareADACommand(FountainFamily.HARDWARE_COMMAND_POUR_WATER_START);
				} else {
					needToTrackHomeWhenInteracted = false;
					if (__command == KeyIDConstants.KEY_ID_FOCUS_ENTER)				activateFocusControllerIfAllowedAutomatically();
					if (__command == KeyIDConstants.KEY_ID_CUSTOM_POUR)				activateFocusControllerIfAllowedAutomatically();
					if (__command == KeyIDConstants.KEY_ID_CUSTOM_POUR_WATER)		activateFocusControllerIfAllowedAutomatically();
				}
//				_wasFocusControllerUsed = true;
//				onAnyUserInput();
//				_wasFocusControllerUsed = false;
			}
		}

		private function onKeyCommandReleased(__command:String):void {
			if (FountainFamily.focusController.enabled && !isOutOfOrderShown && padOverlay.visibility == 0 && !FountainFamily.attractorController.isInIdleState) {
//				info(this + "key released: " + __command);
				if (!FountainFamily.backendModel.isPouringAnything()) {
					if (__command == KeyIDConstants.KEY_ID_NAVIGATION_BACK)				gpuRoot.executeHardwareADACommand(FountainFamily.HARDWARE_COMMAND_NAVIGATE_BACK);
					if (__command == KeyIDConstants.KEY_ID_CUSTOM_ADA_ENTER)			FountainFamily.focusController.executeCommand(FocusController.COMMAND_ACTIVATE);
					if (__command == KeyIDConstants.KEY_ID_CUSTOM_ADA_EXIT)				FountainFamily.focusController.executeCommand(FocusController.COMMAND_DEACTIVATE);
					if (__command == KeyIDConstants.KEY_ID_CUSTOM_ADA_SOFTWARE_ENTER && gpuRoot != null)	gpuRoot.activateSoftwareADA();
					if (__command == KeyIDConstants.KEY_ID_CUSTOM_ADA_SOFTWARE_EXIT && gpuRoot != null)		gpuRoot.deactivateSoftwareADA();
					if (__command == KeyIDConstants.KEY_ID_CUSTOM_ADA_SOFTWARE_TOGGLE && gpuRoot != null)	gpuRoot.toggleSoftwareADA();
				}
				if (__command == KeyIDConstants.KEY_ID_FOCUS_ENTER)					FountainFamily.focusController.executeCommand(FocusController.COMMAND_ENTER_UP);
				if (__command == KeyIDConstants.KEY_ID_CUSTOM_POUR)					gpuRoot.executeHardwareADACommand(FountainFamily.HARDWARE_COMMAND_POUR_BEVERAGE_STOP);
				if (__command == KeyIDConstants.KEY_ID_CUSTOM_POUR_WATER)			gpuRoot.executeHardwareADACommand(FountainFamily.HARDWARE_COMMAND_POUR_WATER_STOP);
//				_wasFocusControllerUsed = true;
//				onAnyUserInput();
//				_wasFocusControllerUsed = false;
			}
		}

		private function onKeyCommandFired(__command:String):void {
			if (FountainFamily.focusController.enabled && !FountainFamily.backendModel.isPouringAnything() && !isOutOfOrderShown && padOverlay.visibility == 0 && !FountainFamily.attractorController.isInIdleState) {
				if (FountainFamily.focusController.isActivated) {
					if (__command == KeyIDConstants.KEY_ID_FOCUS_LEFT)				FountainFamily.focusController.executeCommand(FocusController.COMMAND_MOVE_LEFT);
					if (__command == KeyIDConstants.KEY_ID_FOCUS_RIGHT)				FountainFamily.focusController.executeCommand(FocusController.COMMAND_MOVE_RIGHT);
					if (__command == KeyIDConstants.KEY_ID_FOCUS_UP)				FountainFamily.focusController.executeCommand(FocusController.COMMAND_MOVE_UP);
					if (__command == KeyIDConstants.KEY_ID_FOCUS_DOWN)				FountainFamily.focusController.executeCommand(FocusController.COMMAND_MOVE_DOWN);
					if (__command == KeyIDConstants.KEY_ID_FOCUS_NEXT)				FountainFamily.focusController.executeCommand(FocusController.COMMAND_MOVE_NEXT);
					if (__command == KeyIDConstants.KEY_ID_FOCUS_PREV)				FountainFamily.focusController.executeCommand(FocusController.COMMAND_MOVE_PREVIOUS);
					if (__command == KeyIDConstants.KEY_ID_CUSTOM_ADA_TOGGLE)		FountainFamily.focusController.executeCommand(FocusController.COMMAND_ACTIVATION_TOGGLE);
				} else {
					if (__command == KeyIDConstants.KEY_ID_FOCUS_LEFT)				activateFocusControllerIfAllowedAutomatically();
					if (__command == KeyIDConstants.KEY_ID_FOCUS_RIGHT)				activateFocusControllerIfAllowedAutomatically();
					if (__command == KeyIDConstants.KEY_ID_FOCUS_UP)				activateFocusControllerIfAllowedAutomatically();
					if (__command == KeyIDConstants.KEY_ID_FOCUS_DOWN)				activateFocusControllerIfAllowedAutomatically();
					if (__command == KeyIDConstants.KEY_ID_FOCUS_NEXT)				activateFocusControllerIfAllowedAutomatically();
					if (__command == KeyIDConstants.KEY_ID_FOCUS_PREV)				activateFocusControllerIfAllowedAutomatically();
					if (__command == KeyIDConstants.KEY_ID_CUSTOM_ADA_TOGGLE)		activateFocusControllerIfAllowedAutomatically();
				}
				//onAnyUserInput();
			}
		}

		private function onGPURootHidden():void {
			starling.stage3D.visible = false;
			FountainFamily.looper.pause();
			gpuRoot.onGoToIdleState();
			if (masthead != null) masthead.stop();

			showAttractorVideo();
		}

		private function onGPURootShown():void {
			FountainFamily.attractorController.startWaitingForInactiveState();
		}

		private function onAttractorVideoShown():void {
			attractorVideo.playVideo();
			attractorVideoCover.visible = false;
			FountainFamily.attractorController.startWaitingForUserInteraction();
		}

		private function onAttractorVideoHidden():void {
			if (FountainFamily.platform.supportsLightsAPI) {
				removeEventListener(flash.events.Event.ENTER_FRAME, onEnterFrameUpdateAttractorLightColor);
			}

			stage.removeChild(attractorVideo);
			attractorVideo.dispose();
			attractorVideo.removeEventListener(StageVideoSprite.EVENT_PLAY_FINISH, onAttractorVideoFinish);
			attractorVideo = null;

			if (attractorVideoCover != null) {
				coverOverlay.removeChild(attractorVideoCover);
				attractorVideoCover = null;
			} else {
				warn("Tried removing attractorVideoCover when none existed!");
			}

			showGPURoot();
		}

		private function onAttractorVideoFinish(__e:flash.events.Event):void {
			// Hides attractor
			FountainFamily.attractorController.leaveIdleState();
		}

		private function onIsInOrder(__e:flash.events.Event):void {
			//manualPourAmountUnknown = true;
			//updatePouringState();
			hideMessageOverlay();
		}

		private function onIsOutOfOrder(__e:flash.events.Event):void {
			showMessageOverlay(FountainFamily.backendModel.outOfOrderMessage);
		}

		private function onIsOutOfOrderUpdate(__e:flash.events.Event):void {
			messageOverlay.setText(FountainFamily.backendModel.outOfOrderMessage);
		}

		private function onStartedPouring(__e:flash.events.Event):void {
			FountainFamily.backendModel.setLightNozzleBrightness(FountainFamily.lightingInfo.brightnessPour, FountainFamily.lightingInfo.timePourBrightnessChange * 1000, FountainFamily.lightingInfo.brightnessScale);
		}

		private function onStoppedPouring(__e:flash.events.Event):void {
			FountainFamily.backendModel.setLightNozzleBrightness(FountainFamily.lightingInfo.brightnessPrePour, FountainFamily.lightingInfo.timePourBrightnessChange * 1000, FountainFamily.lightingInfo.brightnessScale);
		}

		private function onBackendRequestedADAEnter(__e:flash.events.Event):void {
			//gpuRoot.activateSoftwareADA();
			FountainFamily.focusController.executeCommand(FocusController.COMMAND_ACTIVATE);
		}

		private function onBackendRequestedADAExit(__e:flash.events.Event):void {
			gpuRoot.deactivateSoftwareADA();
		}

		private function onBackendRequestedAutoTestStart(__e:flash.events.Event):void {
			startAutoTest();
		}

		private function onBackendRequestedAutoTestStop(__e:flash.events.Event):void {
			stopAutoTest();
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function init():void {
			// Initializations
			info("Main display object initialized. Using platform [" + FountainFamily.platform.id +"/" + FountainFamily.platform.idWithOverride +"] with dimensions " + FountainFamily.platform.width + "x" + FountainFamily.platform.height);

			initFlashLayer();

			createPreloader();

			FountainFamily.backendModel.addEventListener(BackendModel.EVENT_IS_IN_ORDER, onIsInOrder);
			FountainFamily.backendModel.addEventListener(BackendModel.EVENT_IS_OUT_OF_ORDER, onIsOutOfOrder);
			FountainFamily.backendModel.addEventListener(BackendModel.EVENT_IS_OUT_OF_ORDER_UPDATE, onIsOutOfOrderUpdate);
			FountainFamily.backendModel.addEventListener(BackendModel.EVENT_STARTED_POURING, onStartedPouring);
			FountainFamily.backendModel.addEventListener(BackendModel.EVENT_STOPPED_POURING, onStoppedPouring);
			FountainFamily.backendModel.addEventListener(BackendModel.EVENT_ADA_ENTER, onBackendRequestedADAEnter);
			FountainFamily.backendModel.addEventListener(BackendModel.EVENT_ADA_EXIT, onBackendRequestedADAExit);
			FountainFamily.backendModel.addEventListener(BackendModel.EVENT_AUTOTEST_START, onBackendRequestedAutoTestStart);
			FountainFamily.backendModel.addEventListener(BackendModel.EVENT_AUTOTEST_STOP, onBackendRequestedAutoTestStop);

			Starling.handleLostContext = FountainFamily.FLAG_PREVENT_LOST_CONTEXT;
			Starling.multitouchEnabled = true;
			starling = new Starling(GPURoot, AppUtils.getStage(), new Rectangle(0, FountainFamily.platform.mastheadHeightScaled, FountainFamily.platform.width, FountainFamily.platform.heightMinusMasthead), null, Context3DRenderMode.AUTO, FountainFamily.platform.gpuProfile);
			//starling = new Starling(GPURoot, AppUtils.getStage(), new Rectangle(0, 0, FountainFamily.platform.width, FountainFamily.platform.height), null, Context3DRenderMode.AUTO, FountainFamily.platform.gpuProfile);
			starling.antiAliasing = FountainFamily.platform.gpuAntiAliasing;
			starling.showStats = FountainFamily.configList.getBoolean("debug/stats-visible") || FountainFamily.DEBUG_STATS_VISIBLE;
			starling.addEventListener(starling.events.Event.ROOT_CREATED, onStarlingRootCreated);
			starling.addEventListener(starling.events.Event.CONTEXT3D_CREATE, onStarlingContextCreated);
			starling.enableErrorChecking = false;
			starling.supportHighResolutions = true;
			starling.simulateMultitouch = FountainFamily.DEBUG_SIMULATE_MULTI_TOUCH;

			if (FountainFamily.platform.mastheadHeight > 0) {
				// Need to create masthead
				masthead = new MastheadView(FountainFamily.platform.widthScaled, FountainFamily.platform.mastheadHeightScaled, FountainFamily.mastheadInfo);
				stage.addChild(masthead);

				// Force the flash content to be above the masthead
				if (flashLayerContainer != null) stage.addChild(flashLayerContainer);
			}

			//starling.shareContext = true;
			starling.start();

			gesturesPerformed = new Vector.<String>();

			FountainFamily.backendModel.addEventListener(BackendModel.EVENT_REQUEST_PIN_KEYPAD, onRequestPinKeypad);

			// Ugh, a weird mix of singletons and non singletons
			FountainFamily.attractorController = new AttractorController(FountainFamily.backendModel, stage);
			FountainFamily.attractorController.onIdleTimePassed.add(goToIdleState);
			FountainFamily.attractorController.onCameBackFromIdle.add(comeBackFromIdleState);
			FountainFamily.attractorController.onUserInteracted.add(registerUserInteraction);
			FountainFamily.attractorController.delayTime = FountainFamily.attractorInfo.delayHome;

			// Key binder actions
			FountainFamily.keyBinder.onCommandPressed.add(onKeyCommandPressed);
			FountainFamily.keyBinder.onCommandFired.add(onKeyCommandFired);
			FountainFamily.keyBinder.onCommandReleased.add(onKeyCommandReleased);
		}

		public function deinit():void {
			// Removes everything that has been initialized
			// This is only done because the interface may be recycled for testing

			destroyPreloader();

			FountainFamily.backendModel.removeEventListener(BackendModel.EVENT_IS_IN_ORDER, onIsInOrder);
			FountainFamily.backendModel.removeEventListener(BackendModel.EVENT_IS_OUT_OF_ORDER, onIsOutOfOrder);
			FountainFamily.backendModel.removeEventListener(BackendModel.EVENT_IS_OUT_OF_ORDER_UPDATE, onIsOutOfOrderUpdate);
			FountainFamily.backendModel.removeEventListener(BackendModel.EVENT_STARTED_POURING, onStartedPouring);
			FountainFamily.backendModel.removeEventListener(BackendModel.EVENT_STOPPED_POURING, onStoppedPouring);

			starling.stop();
			gpuRoot = null;

			if (masthead != null) {
				stage.removeChild(masthead);
				masthead.dispose();
			}

			FountainFamily.backendModel.removeEventListener(BackendModel.EVENT_REQUEST_PIN_KEYPAD, onRequestPinKeypad);

			FountainFamily.keyBinder.onCommandPressed.remove(onKeyCommandPressed);
			FountainFamily.keyBinder.onCommandFired.remove(onKeyCommandFired);
			FountainFamily.keyBinder.onCommandReleased.remove(onKeyCommandReleased);

			// Destroy textures
			FountainFamily.textureLibrary.getBlobBubblesTexture().dispose();

			FountainFamily.textureLibrary.removeEventListener(TextureLibrary.EVENT_READY, onTextureLibraryReady);
			FountainFamily.textureLibrary.removeEventListener(TextureLibrary.EVENT_PROGRESS, onTextureLibrarProgress);
			FountainFamily.textureLibrary.dispose();
			FountainFamily.textureLibrary = null;

			FountainFamily.garbageCan.clearAll();

			starling.dispose();
			starling = null;

			// Other cleanups
			if (consoleView != null) consoleView.clear();
			if (mouseHeatMap != null) mouseHeatMap.clear();
			if (multiTouchHeatMap != null) multiTouchHeatMap.clear();

			// Used by VideoImage
			BitmapDataPool.getPool("videoImage").clean(true);
			BitmapDataPool.getPool().clean(true);

			var obj:Object;
			while (FountainFamily.objectRecycler.getNumObjects() > 0) {
				// Try to dispose of all objects in the recycling list
				obj = FountainFamily.objectRecycler.getOjectAt(0);
				FountainFamily.objectRecycler.remove(obj);
				try {
					if (obj.hasOwnProperty("dispose")) obj["dispose"]();
				} catch(__e:Error) {
					warn("Could not dispose of " + obj + " directly: " + __e.message);
				}
			}
			FountainFamily.objectRecycler.clear();

			System.gc();
		}
	}
}
