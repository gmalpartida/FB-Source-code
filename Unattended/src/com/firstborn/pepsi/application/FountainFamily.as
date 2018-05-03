package com.firstborn.pepsi.application {
	import com.firstborn.pepsi.common.backend.BackendModel;
	import com.firstborn.pepsi.common.backend.interfaces.RealBackendInterface;
	import com.firstborn.pepsi.common.backend.interfaces.SimulatedBackendInterface;
	import com.firstborn.pepsi.data.ADAInfo;
	import com.firstborn.pepsi.data.AnimationDefinition;
	import com.firstborn.pepsi.data.AttractorController;
	import com.firstborn.pepsi.data.AttractorInfo;
import com.firstborn.pepsi.data.Calories;
import com.firstborn.pepsi.data.LightingInfo;
	import com.firstborn.pepsi.data.MastheadInfo;
	import com.firstborn.pepsi.data.PlatformProfile;
	import com.firstborn.pepsi.data.XMLOverrider;
	import com.firstborn.pepsi.data.home.MenuItemDefinition;
	import com.firstborn.pepsi.data.inventory.Inventory;
	import com.firstborn.pepsi.display.Main;
	import com.firstborn.pepsi.display.gpu.common.TextureLibrary;
	import com.zehfernando.controllers.focus.FocusController;
	import com.zehfernando.data.GarbageCan;
	import com.zehfernando.data.ObjectRecycler;
	import com.zehfernando.display.templates.application.SimpleApplication;
	import com.zehfernando.input.KeyBinder;
	import com.zehfernando.localization.StringList;
	import com.zehfernando.models.GameLooper;
	import com.zehfernando.net.assets.AssetLibrary;
	import com.zehfernando.transitions.ZTween;
	import com.zehfernando.utils.AppUtils;
	import com.zehfernando.utils.StringUtils;
	import com.zehfernando.utils.VectorUtils;
	import com.zehfernando.utils.console.Console;
	import com.zehfernando.utils.console.debug;
	import com.zehfernando.utils.console.info;

	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.system.Security;
	import flash.system.fscommand;
	import flash.ui.Mouse;
	import flash.ui.Multitouch;
	/**
	 * @author zeh fernando
	 */
	public class FountainFamily extends SimpleApplication {

		// Constants
		public static const APP_VERSION:String = CONFIG::VERSION;
		public static const APP_BUILD_NUMBER:String = CONFIG::BUILD_NUMBER;
		public static const APP_BUILD_DATE:String = CONFIG::BUILD_DATE;

		// Unique names so the assets can be accessed from the library
		public static const NAME_XML_CONFIG:String = "config_xml";

		public static const FILTER_ATTRIBUTE_XML_PLATFORMS:String = "platforms";		// "Universal" attribute used to filter parameters from XMLs that use it (beverages.xml and flavors.xml so far)
		public static const FILTER_ATTRIBUTE_XML_ADA:String = "ada";
		public static const FILTER_ATTRIBUTE_XML_ADA_TRUE:String = "true";
		public static const FILTER_ATTRIBUTE_XML_ADA_FALSE:String = "false";

		public static const NAME_XML_ADA:String = "ada";
		public static const NAME_XML_ANIMATIONS:String = "animations";
		public static const NAME_XML_ATTRACTOR:String = "attractor";
		public static const NAME_XML_LIGHTING:String = "lighting";
		public static const NAME_XML_BEVERAGES:String = "beverages";
		public static const NAME_XML_FLAVORS:String = "flavors";
		public static const NAME_XML_HOME:String = "home";
		public static const NAME_XML_MASTHEAD:String = "masthead";
		public static const NAME_XML_PLATFORMS:String = "platforms";
		public static const NAME_XML_RECIPES:String = "recipes";
		public static const NAME_XML_OVERRIDES:String = "overrides";
		public static const NAME_XML_LOCALES : String = "localization";

        //To read the XML for the calories
		public static const NAME_XML_CALORIES : String = "calories";

		public static const HARDWARE_COMMAND_POUR_BEVERAGE_START:String = "commandPourBeverageStart";
		public static const HARDWARE_COMMAND_POUR_BEVERAGE_STOP:String = "commandPourBeverageStop";
		public static const HARDWARE_COMMAND_POUR_WATER_START:String = "commandPourWaterStart";
		public static const HARDWARE_COMMAND_POUR_WATER_STOP:String = "commandPourWaterStop";
		public static const HARDWARE_COMMAND_NAVIGATE_BACK:String = "commandNavigateBack";

		// Other flags
		public static const FLAG_PREVENT_LOST_CONTEXT							:Boolean = false;									// Whether it keeps bitmaps in memory for lost context or not

		// Debug constants (override options on config.xml with OR)
		public static const DEBUG_LOG_USES_TRACE								:Boolean = AppUtils.isDebugSWF() && true;
		public static const DEBUG_LOG_USES_FULL_METHOD_NAME						:Boolean = AppUtils.isDebugSWF() && true;
		public static const DEBUG_LOG_POINTER_EVENTS							:Boolean = AppUtils.isDebugSWF() && false;			// Log all pointer events to the console
		public static const DEBUG_TEST_INTERFACE_VISIBLE						:Boolean = AppUtils.isDebugSWF() && true;
		public static const DEBUG_STATS_VISIBLE									:Boolean = AppUtils.isDebugSWF() && false;
		public static const DEBUG_SIMULATE_MULTI_TOUCH							:Boolean = AppUtils.isDebugSWF() && true;			// Simulate multi touch input using starling when the Ctrl and Shift keys are pressed
		public static const DEBUG_GESTURES_ENABLED								:Boolean = AppUtils.isDebugSWF() && true;
		public static const DEBUG_MOUSE_VISIBLE									:Boolean = true; //AppUtils.isDebugSWF() && true;

        public static const DEBUG_BACKEND_INVENTORY_AVAILABLE_DEFAULT			:Boolean = AppUtils.isDebugSWF() && true;
		public static const DEBUG_BACKEND_SKIP_EXTERNAL_INTERFACE_CALLS			:Boolean = AppUtils.isDebugSWF() && false;
		public static const DEBUG_BACKEND_SKIP_EXTERNAL_INTERFACE_CALLS_VALVES	:Boolean = AppUtils.isDebugSWF() && false;

        public static const DEBUG_BACKEND_SERVICE_REQUIRED_DEFAULT				:Boolean = AppUtils.isDebugSWF() && false;
		public static const DEBUG_BACKEND_SERVICE_NEVER_REQUIRED				:Boolean = AppUtils.isDebugSWF() && false;
		public static const DEBUG_BACKEND_IGNORE_OUT_OF_ORDER					:Boolean = AppUtils.isDebugSWF() && false;
		public static const DEBUG_BACKEND_USE_PLACEHOLDER_DATA					:Boolean = AppUtils.isDebugSWF() && false;
		public static const DEBUG_BACKEND_SLOW_CALLS_WHEN_SIMULATING			:Boolean = AppUtils.isDebugSWF() && true;

		public static const DEBUG_CONSOLE_AVAILABLE								:Boolean = AppUtils.isDebugSWF() && true;
		public static const DEBUG_DRAW_POINTER_EVENTS							:Boolean = AppUtils.isDebugSWF() && false;
		public static const DEBUG_DRAW_MULTI_TOUCH_EVENTS						:Boolean = AppUtils.isDebugSWF() && false;
		public static const DEBUG_CONSOLE_STARTS_OPENED							:Boolean = AppUtils.isDebugSWF() && false;
		public static const DEBUG_CONSOLE_ALLOWS_TOUCH_EVENTS					:Boolean = AppUtils.isDebugSWF() && false;			// When the console is pulled, touch events are still allowed in the UI

		// Non-config related debug constants
		public static const DEBUG_REPORT_CLEANED_STRINGS						:Boolean = AppUtils.isDebugPlayer() && false;		// Indicates how much has been cleaned from strings
		public static const DEBUG_DISABLE_TESTING_POURING						:Boolean = AppUtils.isDebugSWF() && false;			// Doesn't do any pouring during auto-test
		public static const DEBUG_DISABLE_TESTING_ADA							:Boolean = AppUtils.isDebugSWF() && false;			// Doesn't test the ADA interface
		public static const DEBUG_TESTING_ALWAYS_SHOW_ADA						:Boolean = AppUtils.isDebugSWF() && false;			// ALWAYS show the ADA interface while testing (overrides DEBUG_DISABLE_TESTING_ADA)
		public static const DEBUG_PLAY_FAST										:Boolean = AppUtils.isDebugSWF() && false;			// Accelerates everything by 8 times by default
		public static const DEBUG_DISABLE_SEQUENCE								:Boolean = AppUtils.isDebugSWF() && false;			// Disables sequence layer for animations on main menu
		public static const DEBUG_FORCE_MENU_BEVERAGES_COUNT					:Boolean = AppUtils.isDebugSWF() && false;			// Injects or deletes data to force a certain number of beverages
		public static const DEBUG_FORCE_MENU_BEVERAGES_COUNT_VALUE				:int = 12;
		public static const DEBUG_DRAW_SEQUENCE_CURVE							:Boolean = AppUtils.isDebugSWF() && false;			// Draws curve used by sequence interpolation
		public static const DEBUG_DRAW_MENU_AXIS								:Boolean = AppUtils.isDebugSWF() && false;			// Draws menu-related lines
		public static const DEBUG_DRAW_HIT_AREAS								:Boolean = AppUtils.isDebugSWF() && false;			// Draws the invisible hit areas of certain buttons
		public static const DEBUG_ALWAYS_SHUFFLE_MENU							:Boolean = AppUtils.isDebugSWF() && false;			// Always re-shuffle the position of the main menu when going back
		public static const DEBUG_MAKE_IDLE_STATE_TRANSITION_SLOW				:Boolean = AppUtils.isDebugSWF() && false;			// Makes the idle state transition take 6 times as long
		public static const DEBUG_MAKE_BRAND_VIEW_TRANSITION_SLOW				:Boolean = AppUtils.isDebugSWF() && false;			// Makes the BrandView transition take 6 times as long
		public static const DEBUG_DO_NOT_CREATE_LIQUID_VIEWS					:Boolean = AppUtils.isDebugSWF() && false;			// Doesn't create the liquid views inside brand view
		public static const DEBUG_DO_NOT_PLAY_IDLE_STATE						:Boolean = AppUtils.isDebugSWF() && true;			// Ignores idle state
		public static const DEBUG_DO_NOT_PLAY_MASTHEAD							:Boolean = AppUtils.isDebugSWF() && false;			// Doesn't play masthead video during normal use
		public static const DEBUG_DO_NOT_PLAY_MASTHEAD_WHILE_CAPTURING			:Boolean = AppUtils.isDebugSWF() && false;			// Doesn't play masthead video while capturing screens
		public static const DEBUG_LIQUID_VIDEOS_ARE_UNMASKED					:Boolean = AppUtils.isDebugSWF() && false;			// The LiquidVideos view ignores the mask
		public static const DEBUG_IDLE_STATE_IGNORES_INPUT						:Boolean = AppUtils.isDebugSWF() && false;			// Idle state ignores user input, not going back
		public static const DEBUG_SHOW_PINPAD_ON_START							:Boolean = AppUtils.isDebugSWF() && false;			// Show the pinpad immediately
		public static const DEBUG_SHOW_CLICKABLE_ADA_COVER						:Boolean = AppUtils.isDebugSWF() && false;			// Shows the clickable ADA cover hitbox
		public static const DEBUG_SHOW_IMAGE_CAPTURE_ON_START					:Boolean = AppUtils.isDebugSWF() && false;			// Display image capture dialog by default
		public static const DEBUG_FULLSCREEN_WHEN_CLICKING_STAGE				:Boolean = AppUtils.isDebugSWF() && false;			// First click on stage makes it go fullscreen (needed to continue)
		public static const DEBUG_BEVERAGES_IGNORE_GROUPS						:Boolean = AppUtils.isDebugSWF() && false;			// Ignores all group relationships for beverages
		public static const DEBUG_BEVERAGES_IGNORE_PARENT						:Boolean = AppUtils.isDebugSWF() && false;			// Ignores all parent-child relationships for beverages
		public static const DEBUG_BEVERAGES_USE_GENERIC_DATA					:Boolean = AppUtils.isDebugSWF() && false;			// Uses generic data when building the menu: static colors, no logos or gradients
		public static const DEBUG_BEVERAGES_USE_EVEN_ODD_GROUPS					:Boolean = AppUtils.isDebugSWF() && false;			// Overrides the beverage data, injecting "odd" and "even" group pairings
		public static const DEBUG_BEVERAGES_USE_FAKE_PARENTS					:Boolean = AppUtils.isDebugSWF() && false;			// Overrides the parents data, creating 3 pairs
		public static const DEBUG_BEVERAGES_USE_XYZW_GROUPS						:Boolean = AppUtils.isDebugSWF() && false;			// Overrides the beverage data, injecting "x/y/z/w" group pairings
		public static const DEBUG_FLAVORS_IGNORE_ANIMATIONS						:Boolean = AppUtils.isDebugSWF() && false;			// Causes the animation flavors to be ignored, effectively not showing any fruits
		public static const DEBUG_PLATFORM_TOWER								:Boolean = AppUtils.isDebugSWF() && false;			// Force the platform to be "tower"
		public static const DEBUG_PLATFORM_SPIRE_3								:Boolean = AppUtils.isDebugSWF() && false;			// Force the platform to be "spire-3"
		public static const DEBUG_PLATFORM_BRIDGE								:Boolean = AppUtils.isDebugSWF() && false;			// Force the platform to be "bridge"
		public static const DEBUG_PLATFORM_TOWER_768_1366						:Boolean = AppUtils.isDebugSWF() && false;			// Force the platform to be "tower-768x1366"
		public static const DEBUG_PLATFORM_BRIDGE_768_1366						:Boolean = AppUtils.isDebugSWF() && false;			// Force the platform to be "bridge-768x1366"

		// Properties
		public static var isAutoTesting:Boolean;
		public static var isAutoImageCapturing:Boolean;

		private static var _timeScale:Number = 1;

		// Main singleton instances for the app (global stuff)
		public static var platform:PlatformProfile;
		public static var configList:StringList;									// List of configuration switches
		public static var inventory:Inventory;										// Inventory with brands and flavors
		public static var looper:GameLooper;										// Controlled looper
		public static var textureLibrary:TextureLibrary;							// Library that contains textures re-used everywhere
		public static var objectRecycler:ObjectRecycler;							// Pool for typical objects (images, textures, etc)
		public static var focusController:FocusController;							// Controls focus
		public static var keyBinder:KeyBinder;										// Key binder for focus actions
		public static var animationDefinitions:Vector.<AnimationDefinition>;		// Specifications for animations
		public static var garbageCan:GarbageCan;									// For later clearing
		public static var attractorInfo:AttractorInfo;								// Information about the idle state
		public static var lightingInfo:LightingInfo;								// Lighting information, for supported platforms
		public static var mastheadInfo:MastheadInfo;								// Information about the mathead that plays on top of the screen
		public static var adaInfo:ADAInfo;											// Hardware/software ADA configuration
		public static var homeXML:XML;												// Copy of home.xml

		public static var overrideURLs:Vector.<String>;								// All overrides (URL)
		public static var overrideXMLs:Vector.<XML>;								// All overrides (XML content)
		public static var attractorController:AttractorController;					// Controls idle state
		public static var backendModel:BackendModel;								// Talks to the backend


		//Constant names used to parse the config.xml file in the localization group.
		public static const NAME_LOCALIZATION : String = "localization";										//Attrib name in the config.xml to define the localization group
		public static const NAME_DEFAULT_LANGUAGE : String = "default-locale";									//Attrib name in the config.xml to define the default langauge
		public static const NAME_AVAILABLE_LOCALES : String = "available-locales";								//Attrib name in the config.xml to define the available locales
		public static const NAME_WAIT_TIME_TO_DEFAULT_LANGUAGE : String = "idle-state-locale-stickiness";		//Attrib name in the config.xml to define the wait time for going back to the default language.

		public static const NAME_ATTRIB_LABEL : String = "toggle-label";												//Attrib name in the config.xml to define the label for each language
		public static const NAME_ROOT_FOLDER : String = "config";												//Root folder for the locale files
		public static const NAME_STRINGS_FILE : String = "strings.xml";											//Name of the expected String file for each localization
		public static const NAME_LOCALE_OVERRIDE_FILE : String = "overrides.xml";								//Name of the expected override file for each localization

		public static const MAX_LANGUAGES : uint = 10;															//Max languages that can be saved inside a Vector of images.


		//Variables required for the localization.
		public static var DEFAULT_LANGUAGE : uint = 0;															//Default language used in the machine (the one that goes when IDLE)
		public static var current_language : String = "";														//Language selected by the user (it defines the LOCALE_ISO index to seach the current StringList to use)
		public static var waitTimeForDefaultLanguage : uint = 0;												//Waiting time to go back to the default language when IDLE
		public static var LANGUAGES_LABELS: Vector.<String> = new Vector.<String>();							//Vector of labels (names) for each language to use in the toggle button.
		public static var LOCALE_ISO : Vector.<String> = new Vector.<String>();									//Save the locale iso naming to be used in the StringList search
		public static var stringsURLs : Vector.<String> = new Vector.<String>();								//Save the URL for each String language
		public static var stringsXMLs : Vector.<XML>;															//Saves the different String XMls for each language
		public static var langOverridesURLs : Vector.<String> = new Vector.<String>();							//Save the URL for each overrides language
		public static var localeOverridesXMLs : Vector.<XML>;													//Saves the different override XMls for each language

        //For the calories
        public static var calories : Calories;                                                                  //Calories settings and cup sizes
        public static var caloriesXML:XML;                                                                      //Copy of the calories.xml;

        //For the locked version of the machine
        public static var LOCKED_MODE: Boolean = false;                                                         //Defines if the machine requires to be unlocked from the backend to reach the menu/brand views.
//        public static var UNLOCK_STATUS : Boolean = false;                                                      //Define if the machine is locked or unlocked by the backend.
        public static var SHOW_UNLOCK_THANKS_MESSAGE : Boolean = false;                                         //Used to show the thanks message in the unattended version if the user unlocks the machine

		private var main:Main;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function FountainFamily() {
			super();

			// Do not add anything else here
			Security.allowDomain("*");
			Security.allowInsecureDomain("*");
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		override protected function addDynamicAssetsFirstPass():void {
			addDynamicAsset("config.xml", NAME_XML_CONFIG);

		}

		override protected function addDynamicAssetsSecondPass():void {
			configList = StringList.getList("config_xml_internal");
			configList.setFromXML(getAssetLibrary().getXML(NAME_XML_CONFIG));

			addDynamicAsset(configList.getString("paths/xmls/" + NAME_XML_ADA), NAME_XML_ADA);
			addDynamicAsset(configList.getString("paths/xmls/" + NAME_XML_ANIMATIONS), NAME_XML_ANIMATIONS);
			addDynamicAsset(configList.getString("paths/xmls/" + NAME_XML_ATTRACTOR), NAME_XML_ATTRACTOR);
			addDynamicAsset(configList.getString("paths/xmls/" + NAME_XML_BEVERAGES), NAME_XML_BEVERAGES);
			addDynamicAsset(configList.getString("paths/xmls/" + NAME_XML_FLAVORS), NAME_XML_FLAVORS);
			addDynamicAsset(configList.getString("paths/xmls/" + NAME_XML_HOME), NAME_XML_HOME);
			addDynamicAsset(configList.getString("paths/xmls/" + NAME_XML_LIGHTING), NAME_XML_LIGHTING);
			addDynamicAsset(configList.getString("paths/xmls/" + NAME_XML_MASTHEAD), NAME_XML_MASTHEAD);
			addDynamicAsset(configList.getString("paths/xmls/" + NAME_XML_PLATFORMS), NAME_XML_PLATFORMS);
			addDynamicAsset(configList.getString("paths/xmls/" + NAME_XML_RECIPES), NAME_XML_RECIPES);
			addDynamicAsset(configList.getString("paths/xmls/" + NAME_XML_LOCALES), NAME_XML_LOCALES);
			addDynamicAsset(configList.getString("paths/xmls/" + NAME_XML_CALORIES), NAME_XML_CALORIES);

			//Read all the localizations folders.
			var i : uint = 0;
			var defaultLanguage : String = configList.getString(NAME_LOCALIZATION + "/" + NAME_DEFAULT_LANGUAGE);
			var locales : Vector.<String> = VectorUtils.stringToStringVector(configList.getString(NAME_LOCALIZATION + "/" + NAME_AVAILABLE_LOCALES), ",", true);

			for(i = 0; i < locales.length; i ++) {
				var locale : String = locales[i];
				stringsURLs.push(String(NAME_ROOT_FOLDER + "/" + locale + "/" + NAME_STRINGS_FILE));
				langOverridesURLs.push(String(NAME_ROOT_FOLDER + "/" + locale + "/" + NAME_LOCALE_OVERRIDE_FILE));
				LOCALE_ISO.push(locale);
				addDynamicAsset(stringsURLs[i], stringsURLs[i]);
				addDynamicAsset(langOverridesURLs[i], langOverridesURLs[i]);
				if(locale == defaultLanguage) {
					DEFAULT_LANGUAGE = i;
					current_language = locale;
				}
			}

			//If there's only one lanaguage activated
			if(locales.length == 1) {
				DEFAULT_LANGUAGE = 0;
				current_language = locales[0];
			}
			locales = null;

			overrideURLs = VectorUtils.stringToStringVector(configList.getString("paths/xmls/" + NAME_XML_OVERRIDES), ",", true);
			for (i = 0; i < overrideURLs.length; i++) addDynamicAsset(overrideURLs[i], overrideURLs[i]);

		}

		override protected function getDynamicAssetSecondPassPhaseSize():Number {
			return 0.8;
		}

		override protected function createVisualAssets():void {
			debug("Starting: version is [" + FountainFamily.APP_VERSION + "], build number is [" + FountainFamily.APP_BUILD_NUMBER + "], build date is [" + FountainFamily.APP_BUILD_DATE + "]");
			debug("MultiTouch: supports touch events = " + Multitouch.supportsTouchEvents + ", max touches = " + Multitouch.maxTouchPoints);

			StringUtils.reportCleanedStrings = DEBUG_REPORT_CLEANED_STRINGS;

			var i : uint = 0;

			//Set the labels and the wait time to change to the default language.

			var localeData : XML = getAssetLibrary().getXML(NAME_XML_LOCALES);
			waitTimeForDefaultLanguage = localeData[NAME_WAIT_TIME_TO_DEFAULT_LANGUAGE];

			for(i = 0; i < LOCALE_ISO.length; i ++) LANGUAGES_LABELS.push(localeData.locale.(@id==LOCALE_ISO[i])[NAME_ATTRIB_LABEL]);

			//Set the strings XML's in the library
			stringsXMLs = new Vector.<XML>();
			for (i = 0; i < stringsURLs.length; i++) {
				stringsXMLs.push(getAssetLibrary().getXML(stringsURLs[i]));
			}

			localeOverridesXMLs = new Vector.<XML>();
			for (i = 0; i < langOverridesURLs.length; i++) {
				localeOverridesXMLs.push(getAssetLibrary().getXML(langOverridesURLs[i]));
			}

			// Applies all overrides
			overrideXMLs = new Vector.<XML>();
			for (i = 0; i < overrideURLs.length; i++) {
				overrideXMLs.push(getAssetLibrary().getXML(overrideURLs[i]));
			}

			// Provides some properties for frequently used config parameters (all others are accessed directly)
			var platformXMLs:XMLList = XMLOverrider.getOverriddenXML(overrideXMLs, NAME_XML_PLATFORMS, getAssetLibrary().getXML(NAME_XML_PLATFORMS)).children();
			platform = PlatformProfile.fromXMLList(platformXMLs, configList.getString("generic/platform"));
			if (DEBUG_PLATFORM_TOWER) platform = PlatformProfile.fromXMLList(platformXMLs, "tower");
			if (DEBUG_PLATFORM_SPIRE_3) platform = PlatformProfile.fromXMLList(platformXMLs, "spire-3");
			if (DEBUG_PLATFORM_BRIDGE) platform = PlatformProfile.fromXMLList(platformXMLs, "bridge");
			if (DEBUG_PLATFORM_TOWER_768_1366) platform = PlatformProfile.fromXMLList(platformXMLs, "tower-768x1366");
			if (DEBUG_PLATFORM_BRIDGE_768_1366) platform = PlatformProfile.fromXMLList(platformXMLs, "bridge-768x1366");

			isAutoTesting = false;
			looper = new GameLooper();
			looper.timeScale = timeScale;
			objectRecycler = new ObjectRecycler();

            // Other (global) initializations

            //This is used in all the application to check if the machine requires to be unlocked by the backend
            LOCKED_MODE = configList.getBoolean("backend/unlock_required");
            trace("-----------------------------------------------------------------------------------------------------------");
            trace("UNLOCKED MODE ENABLED: " + LOCKED_MODE);
            trace("-----------------------------------------------------------------------------------------------------------");

            BackendModel.init((configList.getBoolean("backend/use-placeholder-data") || DEBUG_BACKEND_USE_PLACEHOLDER_DATA) ? new SimulatedBackendInterface(DEBUG_BACKEND_SLOW_CALLS_WHEN_SIMULATING) : new RealBackendInterface());
            BackendModel.ignoreOutOfOrderCalls				= configList.getBoolean("backend/ignore-out-of-order")							|| DEBUG_BACKEND_IGNORE_OUT_OF_ORDER;
            BackendModel.skipExternalInterfaceCalls			= configList.getBoolean("backend/skip-external-interface-calls")				|| DEBUG_BACKEND_SKIP_EXTERNAL_INTERFACE_CALLS;
            BackendModel.skipExternalInterfaceCallsValves	= configList.getBoolean("backend/skip-external-interface-calls-valves")			|| DEBUG_BACKEND_SKIP_EXTERNAL_INTERFACE_CALLS_VALVES;
            BackendModel.serviceRequiredStatusDefault		= configList.getBoolean("backend/service-required-default")						|| DEBUG_BACKEND_SERVICE_REQUIRED_DEFAULT;
            BackendModel.serviceNeverRequired				= configList.getBoolean("backend/service-never-required")						|| DEBUG_BACKEND_SERVICE_NEVER_REQUIRED;
            BackendModel.recipeAvailabilityDefault			= configList.getBoolean("backend/inventory-available-default")					|| DEBUG_BACKEND_INVENTORY_AVAILABLE_DEFAULT;
            BackendModel.skipInventoryListBeverageChange	= configList.getBoolean("backend/skip-inventory-list-after-beverage-change");
            BackendModel.skipInventoryListFlavorChange		= configList.getBoolean("backend/skip-inventory-list-after-flavor-change");
            BackendModel.skipInventoryListStartup			= configList.getBoolean("backend/skip-inventory-list-after-startup");
            BackendModel.logXMLResponses					= configList.getBoolean("debug/log-backend-responses");
            BackendModel.lightihgHardware                   = configList.getString("backend/lighting-hardware");


			animationDefinitions = AnimationDefinition.fromXMLList(XMLOverrider.getOverriddenXML(overrideXMLs, NAME_XML_ANIMATIONS, getAssetLibrary().getXML(NAME_XML_ANIMATIONS)).children());
			attractorInfo = new AttractorInfo(XMLOverrider.getOverriddenXML(overrideXMLs, NAME_XML_ATTRACTOR, getAssetLibrary().getXML(NAME_XML_ATTRACTOR)));
			lightingInfo = new LightingInfo(XMLOverrider.getOverriddenXML(overrideXMLs, NAME_XML_LIGHTING, getAssetLibrary().getXML(NAME_XML_LIGHTING)));
			mastheadInfo = new MastheadInfo(XMLOverrider.getOverriddenXML(overrideXMLs, NAME_XML_MASTHEAD, getAssetLibrary().getXML(NAME_XML_MASTHEAD)));
			adaInfo = new ADAInfo(XMLOverrider.getOverriddenXML(overrideXMLs, NAME_XML_ADA, getAssetLibrary().getXML(NAME_XML_ADA)));
			homeXML = XMLOverrider.getOverriddenXML(overrideXMLs, NAME_XML_HOME, (AssetLibrary.getLibrary().getXML(FountainFamily.NAME_XML_HOME)));

			garbageCan = new GarbageCan();

			Console.useJS = false;
			Console.useTrace = configList.getBoolean("debug/log-uses-trace") || DEBUG_LOG_USES_TRACE;
			Console.useFullMethodName = configList.getBoolean("debug/log-uses-full-method-name") || DEBUG_LOG_USES_FULL_METHOD_NAME;

			if (DEBUG_PLAY_FAST) timeScale = 10;
			if (FountainFamily.DEBUG_DO_NOT_PLAY_IDLE_STATE) {
				attractorInfo.delayBrand = 0;
				attractorInfo.delayBrandADA = 0;
				attractorInfo.delayHome = 0;
				attractorInfo.delayHomeADA = 0;
			}

			// Backend model instance
			backendModel = new BackendModel();

			// Creates key binder
			keyBinder = new KeyBinder();
			keyBinder.setFromXML(adaInfo.hardwareKeys);
			keyBinder.start(stage);

			// Creates focus controller
			FountainFamily.focusController = new FocusController(stage);
			FountainFamily.focusController.enabled = FountainFamily.adaInfo.hardwareEnabled;

			// Disable tab interface
			stage.stageFocusRect = false;
			focusRect = false;
			tabEnabled = false;

			stage.frameRate = platform.frameRate;
			fscommand("trapallkeys", "true");
			fscommand("fullscreen", "true");
			AppUtils.disableContextMenu();

			// Loads the inventory
			var flavorIdsAllowedString:String = configList.getString("backend/flavor-ids-allowed");
			var flavorIdsAllowed:Vector.<String> = (flavorIdsAllowedString != null && flavorIdsAllowedString.length > 0) ? Vector.<String>(flavorIdsAllowedString.split(",")) : new Vector.<String>();

			inventory = new Inventory(XMLOverrider.getOverriddenXML(overrideXMLs, NAME_XML_BEVERAGES, AssetLibrary.getLibrary().getXML(FountainFamily.NAME_XML_BEVERAGES)), XMLOverrider.getOverriddenXML(overrideXMLs, NAME_XML_FLAVORS, AssetLibrary.getLibrary().getXML(FountainFamily.NAME_XML_FLAVORS)), XMLOverrider.getOverriddenXML(overrideXMLs, NAME_XML_RECIPES, AssetLibrary.getLibrary().getXML(FountainFamily.NAME_XML_RECIPES)), platform.id, platform.idWithOverride, flavorIdsAllowed);
			info("Initialized inventory with " + inventory.getBeverages().length + " beverages and " + inventory.getFlavors().length + " flavors.");
			info("Beverage combinations possible for the complete inventory: " + inventory.getNumCombinations());
			info("Beverage combinations possible for the current inventory: " + MenuItemDefinition.getNumCombinations(inventory));

			//Generate the String lists for each language and save the names for the flavors (generating a proxy inventory to search for the name).
			for(i = 0; i < LOCALE_ISO.length; i ++) {
				StringList.getList(LOCALE_ISO[i]).setFromXML(stringsXMLs[i]);
				StringList.getList(LOCALE_ISO[i]).setCurrentLanguages(LOCALE_ISO[i]);

				overrideXMLs.push(localeOverridesXMLs[i]);
				var inventory_proxy : Inventory = new Inventory(XMLOverrider.getOverriddenXML(overrideXMLs, NAME_XML_BEVERAGES, AssetLibrary.getLibrary().getXML(FountainFamily.NAME_XML_BEVERAGES)), XMLOverrider.getOverriddenXML(overrideXMLs, NAME_XML_FLAVORS, AssetLibrary.getLibrary().getXML(FountainFamily.NAME_XML_FLAVORS)), XMLOverrider.getOverriddenXML(overrideXMLs, NAME_XML_RECIPES, AssetLibrary.getLibrary().getXML(FountainFamily.NAME_XML_RECIPES)), platform.id, platform.idWithOverride, flavorIdsAllowed);
				inventory.setFlavorsLocalization(inventory_proxy.getFlavors());
				inventory_proxy = null;
				overrideXMLs.pop();
			}

			// Visual configurations
			if (configList.getBoolean("debug/mouse-visible") || FountainFamily.DEBUG_MOUSE_VISIBLE) {
				Mouse.show();
			} else {
				Mouse.hide();
			}

            //To generate the calories settings and cup data.
            calories = new Calories(XMLOverrider.getOverriddenXML(overrideXMLs, NAME_XML_CALORIES, getAssetLibrary().getXML(NAME_XML_CALORIES)));


            // Ready to initialize everything

			// Create individual interface(s)
			main = new Main();
			stage.addChild(main);
			if (FountainFamily.DEBUG_FULLSCREEN_WHEN_CLICKING_STAGE) {
				// Wait for a click before initializing
				stage.addEventListener(MouseEvent.CLICK, function(__e:Event):void {
					if (stage.displayState != StageDisplayState.FULL_SCREEN_INTERACTIVE) {
						stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
						main.init();
					}
				});
			} else {
				// Normal initialization
				main.init();
			}

			visible = false;
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public static function get timeScale():Number {
			return _timeScale;
		}

		public static function set timeScale(__value:Number):void {
			if (_timeScale != __value) {
				_timeScale = __value;
				ZTween.timeScale = _timeScale;
				if (looper != null) looper.timeScale = _timeScale;
			}
		}
	}
}