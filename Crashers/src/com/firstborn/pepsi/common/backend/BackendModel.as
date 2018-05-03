package com.firstborn.pepsi.common.backend {
	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.common.backend.interfaces.IBackendInterface;
	import com.zehfernando.data.types.Color;
	import com.zehfernando.utils.AppUtils;
	import com.zehfernando.utils.DelayedCalls;
	import com.zehfernando.utils.MathUtils;
	import com.zehfernando.utils.XMLUtils;
	import com.zehfernando.utils.console.debug;
	import com.zehfernando.utils.console.error;
	import com.zehfernando.utils.console.info;
	import com.zehfernando.utils.console.log;
	import com.zehfernando.utils.console.warn;
	import com.zehfernando.utils.getTimerUInt;

	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.system.System;
	/**
	 * @author zeh fernando
	 */
	public class BackendModel extends EventDispatcher {

//		private static const _CALL_ICE_DISPENSER_AVAILABLE : String = "IceDispenser.OnAvailable";
//		private static const _CALL_ICE_DISPENSER_UNAVAILABLE : String = "IceDispenser.OnUnavailable";
//		private static const _CALL_SYSTEM_STATUS_REQUEST_VERSION : String = "SystemStatus.OnRequestVersion";

		// Actual event callbacks, do not change
		private static const BACKEND_EVENT_ADA_ENTER						:String = "Ada.OnEnter";
		private static const BACKEND_EVENT_ADA_EXIT							:String = "Ada.OnExit";
		private static const BACKEND_EVENT_ADA_BUTTON_PRESSED				:String = "Ada.OnButtonPressed";
		private static const BACKEND_EVENT_ADA_BUTTON_DOWN					:String = "Ada.OnButtonDown";
		private static const BACKEND_EVENT_ADA_BUTTON_UP					:String = "Ada.OnButtonUp";
		private static const BACKEND_EVENT_INVENTORY_ON_INVENTORY_CHANGED	:String = "Inventory.OnInventoryChanged";
		private static const BACKEND_EVENT_SYSTEM_STATUS_ON_SERVICE_CHANGED	:String = "SystemStatus.OnServiceChanged";
		private static const BACKEND_EVENT_SYSTEM_STATUS_ON_IN_ORDER		:String = "SystemStatus.OnInOrder";
		private static const BACKEND_EVENT_SYSTEM_STATUS_ON_OUT_OF_ORDER	:String = "SystemStatus.OnOutOfOrder";
		private static const BACKEND_EVENT_BEVERAGE_ON_CUP_POUR_COMPLETE	:String = "Beverage.OnCupPourComplete";
		private static const BACKEND_EVENT_BEVERAGE_ON_MUST_SELECT			:String = "Beverage.OnMustSelect";
		private static const BACKEND_EVENT_PIN_ON_REQUEST_PIN_PAD			:String = "Pin.OnRequestPinKeypad";
		private static const BACKEND_EVENT_GET_VERSION						:String = "Get.Version";
		private static const BACKEND_EVENT_GET_BUILD_NUMBER					:String = "Get.BuildNumber";
		private static const BACKEND_EVENT_GET_BUILD_DATE					:String = "Get.BuildDate";
		private static const BACKEND_EVENT_AUTOTEST_START					:String = "AutoTest.Start";
		private static const BACKEND_EVENT_AUTOTEST_STOP					:String = "AutoTest.Stop";

		// Actual button ids, do not change
		private static const BACKEND_BUTTON_UP								:String = "up";
		private static const BACKEND_BUTTON_DOWN							:String = "down";
		private static const BACKEND_BUTTON_LEFT							:String = "left";
		private static const BACKEND_BUTTON_RIGHT							:String = "right";
		private static const BACKEND_BUTTON_BACK							:String = "back";
		private static const BACKEND_BUTTON_SELECT							:String = "select";
		private static const BACKEND_BUTTON_ICE								:String = "ice";
		private static const BACKEND_BUTTON_POUR							:String = "pour";
		private static const BACKEND_BUTTON_WATER							:String = "water";

		// Actual commands, do not change
		private static const BACKEND_COMMAND_WATER_START					:String = "Water.Start";
		private static const BACKEND_COMMAND_WATER_STOP						:String = "Water.Stop";
		private static const BACKEND_COMMAND_BEVERAGE_POUR_CUP				:String = "Beverage.PourCup";
		private static const BACKEND_COMMAND_BEVERAGE_START					:String = "Beverage.Start";
		private static const BACKEND_COMMAND_BEVERAGE_SELECT				:String = "Beverage.Select";
		private static const BACKEND_COMMAND_BEVERAGE_STOP					:String = "Beverage.Stop";
		private static const BACKEND_COMMAND_BEVERAGE_CUPS_SIZES			:String = "Beverage.CupSizes";
		private static const BACKEND_COMMAND_BEVERAGE_ICE_AMOUNTS			:String = "Beverage.IceAmounts";
		private static const BACKEND_COMMAND_INVENTORY_LIST					:String = "Inventory.List";
		private static const BACKEND_COMMAND_SYSTEM_STATUS_SERVICES_REQUIRED:String = "SystemStatus.ServicesRequired";
		private static const BACKEND_COMMAND_ANALYTICS_SCREEN_CHANGED		:String = "ScreenChanged";
		private static const BACKEND_COMMAND_ANALYTICS_BUTTON_PRESSED		:String = "ButtonPressed";
		private static const BACKEND_COMMAND_PIN_VALIDATE_PIN				:String = "Pin.ValidatePIN";
		private static const BACKEND_COMMAND_PIN_EXECUTE_PIN_ACTION			:String = "Pin.ExecutePinAction";
		private static const BACKEND_COMMAND_PIN_PROMPT						:String = "Pin.Prompt";
		private static const BACKEND_COMMAND_LIGHTNING						:String = "Lighting";
		private static const BACKEND_COMMAND_LIGHTNING_NOZZLE				:String = "Lighting.Nozzle";

		// Actual service ids, do not change
		public static const BACKEND_SERVICE_STATUS_ID_CARTRIDGE				:String = "Cartridge";
		public static const BACKEND_SERVICE_STATUS_ID_ICE					:String = "Ice";
		public static const BACKEND_SERVICE_STATUS_ID_TECHNICIAN			:String = "Technician";

		public static const BACKEND_SERVICE_STATUS_ID_BRAND_SOLD_OUT		:String = "BrandSoldOut";
		public static const BACKEND_SERVICE_STATUS_ID_FLAVOR_SOLD_OUT		:String = "FlavorSoldOut";
		public static const BACKEND_SERVICE_STATUS_ID_CO2_LEVEL				:String = "CO2Level";
		public static const BACKEND_SERVICE_STATUS_ID_CARB_WATER_TEMP		:String = "CarbWaterTemp";
		public static const BACKEND_SERVICE_STATUS_ID_STILL_WATER_TEMP		:String = "StillWaterTemp";

		// Event enums for the class itself
		public static const EVENT_ADA_ENTER									:String = "BackendModel.onEnterAda";
		public static const EVENT_ADA_EXIT									:String = "BackendModel.onExitAda";
		public static const EVENT_BUTTON_ANY								:String = "BackendModel.onButtonAny";
		public static const EVENT_BUTTON_UP									:String = "BackendModel.onButtonUp";
		public static const EVENT_BUTTON_DOWN								:String = "BackendModel.onButtonDown";
		public static const EVENT_BUTTON_LEFT								:String = "BackendModel.onButtonLeft";
		public static const EVENT_BUTTON_RIGHT								:String = "BackendModel.onButtonRight";
		public static const EVENT_BUTTON_BACK								:String = "BackendModel.onButtonBack";
		public static const EVENT_BUTTON_SELECT_PRESS						:String = "BackendModel.onButtonSelectPress";
		public static const EVENT_BUTTON_SELECT_RELEASE						:String = "BackendModel.onButtonSelectRelease";
		public static const EVENT_BUTTON_ICE_PRESS							:String = "BackendModel.onButtonIcePress";
		public static const EVENT_BUTTON_ICE_RELEASE						:String = "BackendModel.onButtonIceRelease";
		public static const EVENT_BUTTON_POUR_PRESS							:String = "BackendModel.onButtonPourPress";
		public static const EVENT_BUTTON_POUR_RELEASE						:String = "BackendModel.onButtonPourRelease";
		public static const EVENT_BUTTON_WATER_PRESS						:String = "BackendModel.onButtonWaterPress";
		public static const EVENT_BUTTON_WATER_RELEASE						:String = "BackendModel.onButtonWaterRelease";
		public static const EVENT_RECIPE_AVAILABILITY_CHANGED				:String = "BackendModel.onRecipeAvailabilityChanged";
		public static const EVENT_SERVICES_REQUIRED_CHANGED					:String = "BackendModel.onServicesRequiredChanged";
		public static const EVENT_IS_OUT_OF_ORDER							:String = "BackendModel.onOutOfOrder";
		public static const EVENT_IS_OUT_OF_ORDER_UPDATE					:String = "BackendModel.onOutOfOrderUpdate";
		public static const EVENT_IS_IN_ORDER								:String = "BackendModel.onInOrder";
		public static const EVENT_REQUEST_PIN_KEYPAD						:String = "BackendModel.onRequestPinKeypad";
		public static const EVENT_CUP_POUR_COMPLETE							:String = "BackendModel.onCupPourComplete";
		public static const EVENT_MUST_SELECT_BEVERAGE						:String = "BackendModel.onMustSelectBeverage";
		public static const EVENT_LIGHT_COLOR_CHANGE						:String = "BackendModel.onLightColorChange";
		public static const EVENT_LIGHT_NOZZLE_BRIGHTNESS_CHANGE			:String = "BackendModel.onLightNozzleBrightnessChange";
		public static const EVENT_STARTED_POURING							:String = "BackendModel.onStartedPouring";
		public static const EVENT_STOPPED_POURING							:String = "BackendModel.onStoppedPouring";
		public static const EVENT_AUTOTEST_START							:String = "BackendModel.onAutoTestStart";
		public static const EVENT_AUTOTEST_STOP						    	:String = "BackendModel.onAutoTestStop";

		// Debug constants
		private static const DEBUG_LOG_XML_RESPONSES						:Boolean = AppUtils.isDebugSWF() && false;		// Logs all backend XML responses (if true, ignores the "log-backend-responses" option from the XML)
		private static const DEBUG_START_ON_OUT_OF_ORDER					:Boolean = AppUtils.isDebugSWF() && false;		// Start already being out of order
		private static const DEBUG_SEND_ON_OUT_OF_ORDER						:Boolean = AppUtils.isDebugSWF() && false;		// Injects a "out of order" event 2 seconds after starting
		private static const DEBUG_SEND_ON_IN_ORDER							:Boolean = AppUtils.isDebugSWF() && false;		// Injects a "in order" event 4 seconds after starting
		private static const DEBUG_SEND_ON_INVENTORY_CHANGED				:Boolean = AppUtils.isDebugSWF() && false;		// Injects a "inventory changed" event 3 seconds after starting
		private static const DEBUG_SIMULATE_ZERO_LENGTH_ICE_AMOUNTS			:Boolean = AppUtils.isDebugSWF() && false;		// Pretends the machine has no ice amounts listed
		private static const DEBUG_RANDOM_INVENTORY_AVAILABILITY			:Boolean = AppUtils.isDebugSWF() && false;		// Inventory refresh reads availability as random
		private static const DEBUG_TURN_OFF_LOGS							:Boolean = AppUtils.isDebugSWF() && false;		// If true, doesn't log anything

		// Other constants
		private static const VALVE_RELATED_COMMANDS:Vector.<String> = new <String>[BACKEND_COMMAND_WATER_START, BACKEND_COMMAND_WATER_STOP, BACKEND_COMMAND_BEVERAGE_POUR_CUP, BACKEND_COMMAND_BEVERAGE_START, BACKEND_COMMAND_BEVERAGE_SELECT, BACKEND_COMMAND_BEVERAGE_STOP];
		private static const MACHINE_IDS_SEPARATOR:String = ",";

		private static const INVENTORY_RELATED_COMMAND_BEVERAGE_CHANGE		:String = "inventoryBeverageChange";
		private static const INVENTORY_RELATED_COMMAND_FLAVOR_CHANGE		:String = "inventoryFlavorChange";
		private static const INVENTORY_RELATED_COMMAND_STARTUP				:String = "inventoryStartup";
		private static const INVENTORY_RELATED_COMMAND_UNKNOWN				:String = "inventoryUnknown";

		// Static properties
		private static var modelInstances:Vector.<BackendModel>;
		private static var currentMachineIds:String;
		private static var machineIdsForLastAvailability:String;	// What were the machine recipe ids when the availability was last refreshed

		private static var recipeAvailability:Object;				// key(recipe id):String, value:true|false (if it doesn't exist, backend/inventory-available-default from config)

		private static var servicesRequired:Object;					// key(type):String, value:true|false (if it doesn't exist, backend/service-required-default from config)

		private static var _isOutOfOrder:Boolean;
		private static var _outOfOrderMessage:String;
		private static var _mustSelectBeverageId:String;
		private static var _mustSelectFlavorIds:Vector.<String>;
		private static var _isOutOfOrderStateKnown:Boolean;
		private static var _isPouringCup:Boolean;							// Performing an auto-pour
		private static var _isPouringBeverage:Boolean;						// Helper
		private static var _isPouringWater:Boolean;							// Helper

		public static var ignoreOutOfOrderCalls:Boolean;					// If true, ignores out-of-order calls
		public static var skipExternalInterfaceCalls:Boolean;				// If true, doesn't do any actual external interface call
		public static var skipExternalInterfaceCallsValves:Boolean;			// If true, doesn't do any actual external interface call to valve uses
		public static var serviceRequiredStatusDefault:Boolean;				// If true, requires service by default
		public static var serviceNeverRequired:Boolean;						// If true, services are never required (overrides serviceRequiredStatusDefault)
		public static var recipeAvailabilityDefault:Boolean;				// If true, available by default
		public static var logXMLResponses:Boolean;							// If true, logs all backend responses as XML
		public static var skipInventoryListBeverageChange:Boolean;			// Skip calling the inventory.list command when the inventory list changes after selecting a different brand
		public static var skipInventoryListFlavorChange:Boolean;			// Skip calling the inventory.list command when the inventory list changes after selecting a different flavor shot for the current brand
		public static var skipInventoryListStartup:Boolean;					// Skip calling the inventory.list command when the inventory list changes after startup
		public static var immediateOnInOrderEvent:Boolean;					// Goes back to InOrder immediately (otherwise, wait one second)

		private static var cupSizes:Vector.<CupSizeInfo>;
		private static var iceAmounts:Vector.<IceAmountInfo>;

		private static var hasRecipeAvailabilityChanged:Boolean;
		private static var lastInventoryRelatedCommand:String;

		private static var lightningColorR:uint;
		private static var lightningColorG:uint;
		private static var lightningColorB:uint;
		private static var lightningColorBrightness:uint;
		private static var lightningColorTransitionTime:uint;
		private static var lightningNozzleColorBrightness:uint;
		private static var lightningNozzleColorTransitionTime:uint;

		private static var backendInterface:IBackendInterface;

		// Properties
		private var currentIds:String;
		private var numEventListeners:uint;


		// ================================================================================================================
		// STATIC CONSTRUCTOR ---------------------------------------------------------------------------------------------

		public static function init(__backendInterface:IBackendInterface):void {
			modelInstances = new Vector.<BackendModel>();
			cupSizes = new Vector.<CupSizeInfo>();
			iceAmounts = new Vector.<IceAmountInfo>();
			lastInventoryRelatedCommand = INVENTORY_RELATED_COMMAND_STARTUP;

			backendInterface = __backendInterface;

			currentMachineIds = "";
			lightningColorR = 0;
			lightningColorG = 0;
			lightningColorB = 0;
			lightningColorBrightness = 0;
			lightningNozzleColorBrightness = 0;

			immediateOnInOrderEvent = false;

			_isPouringCup = false;
			_isPouringBeverage = false;
			_isPouringWater = false;

			_isOutOfOrder = false;
			_isOutOfOrderStateKnown = false;

			//serviceRequiredStatusDefault = false;
			//recipeAvailabilityDefault = false;

			info("External interface is available: " + backendInterface.available);
			info("External interface objectID: " + backendInterface.objectID);

			refreshRecipeAvailabilityInternal(true);
			refreshServicesRequiredInternal();

			DelayedCalls.add(1, refreshRecipeAvailabilityInternal, [true]);

			if (backendInterface.available) {
				backendInterface.addCallback(BACKEND_EVENT_ADA_ENTER,							onAdaEnter);
				backendInterface.addCallback(BACKEND_EVENT_ADA_EXIT,							onAdaExit);
				backendInterface.addCallback(BACKEND_EVENT_ADA_BUTTON_PRESSED,					onAdaButtonPressed);
				backendInterface.addCallback(BACKEND_EVENT_ADA_BUTTON_DOWN,						onAdaButtonDown);
				backendInterface.addCallback(BACKEND_EVENT_ADA_BUTTON_UP,						onAdaButtonUp);
				backendInterface.addCallback(BACKEND_EVENT_INVENTORY_ON_INVENTORY_CHANGED,		onInventoryChanged);
				backendInterface.addCallback(BACKEND_EVENT_SYSTEM_STATUS_ON_SERVICE_CHANGED,	onServiceChanged);
				backendInterface.addCallback(BACKEND_EVENT_SYSTEM_STATUS_ON_IN_ORDER,			onInOrder);
				backendInterface.addCallback(BACKEND_EVENT_SYSTEM_STATUS_ON_OUT_OF_ORDER,		onOutOfOrder);
				backendInterface.addCallback(BACKEND_EVENT_BEVERAGE_ON_CUP_POUR_COMPLETE,		onCupPourComplete);
				backendInterface.addCallback(BACKEND_EVENT_BEVERAGE_ON_MUST_SELECT,				onMustSelect);
				backendInterface.addCallback(BACKEND_EVENT_PIN_ON_REQUEST_PIN_PAD,				onRequestPinPad);
				backendInterface.addCallback(BACKEND_EVENT_GET_VERSION,							onGetVersion);
				backendInterface.addCallback(BACKEND_EVENT_GET_BUILD_NUMBER,					onGetBuildNumber);
				backendInterface.addCallback(BACKEND_EVENT_GET_BUILD_DATE,						onGetBuildDate);
				backendInterface.addCallback(BACKEND_EVENT_AUTOTEST_START,						onAutoTestStart);
				backendInterface.addCallback(BACKEND_EVENT_AUTOTEST_STOP,						onAutoTestStop);
			}

			if (DEBUG_START_ON_OUT_OF_ORDER) debug_injectOnOutOfOrder();
			if (DEBUG_SEND_ON_INVENTORY_CHANGED)	DelayedCalls.add(3000, debug_injectOnInventoryChanged);
			if (DEBUG_SEND_ON_INVENTORY_CHANGED)	DelayedCalls.add(6000, debug_injectOnInventoryChanged);
			if (DEBUG_SEND_ON_OUT_OF_ORDER)			DelayedCalls.add(2000, debug_injectOnOutOfOrder);
			if (DEBUG_SEND_ON_IN_ORDER)				DelayedCalls.add(4000, debug_injectOnInOrder);
			if (DEBUG_SEND_ON_OUT_OF_ORDER && DEBUG_SEND_ON_IN_ORDER)	{
				DelayedCalls.add(6000, debug_injectOnOutOfOrder);
				DelayedCalls.add(8000, debug_injectOnInOrder);
			}
		}


		// ================================================================================================================
		// STATIC INTERNAL INTERFACE --------------------------------------------------------------------------------------

		private static function sendCommand(...__commands):* {
			if (__commands.length == 0) return null;

			var params:Array = __commands.concat();
			if (!DEBUG_TURN_OFF_LOGS) debug("External interface call: ["+params.join("] [")+"]");

			var response:String = null;

			var ti:int = getTimerUInt();

			if (!skipExternalInterfaceCalls && (!skipExternalInterfaceCallsValves || VALVE_RELATED_COMMANDS.indexOf(__commands[0]) == -1)) {
				try {
					response = backendInterface.call.apply(null, params);
				} catch (__e:SecurityError) {
					error("  A SecurityError occurred: " + __e.message + "\n");
				} catch (__e:Error) {
					error("  An Error occurred: " + __e.message + "\n");
				}

				if (!DEBUG_TURN_OFF_LOGS) debug("External interface call executed in " + (getTimerUInt() - ti) + "ms.");
			} else {
				response = null;

				if (!DEBUG_TURN_OFF_LOGS) debug("External interface call skipped");
			}

			if (DEBUG_LOG_XML_RESPONSES || logXMLResponses) {
				if (!DEBUG_TURN_OFF_LOGS) debug("Backend response: [" + response + "]");
			}

			return response;
		}

		private static function selectBeverage(__recipeIds:String):void {

			//Sparkling water always needs to select, no matter what
			var isSparklingWater:Boolean = (FountainFamily.inventory.getBeverageSparklingWater().recipeId == __recipeIds);

			if (currentMachineIds != __recipeIds || isSparklingWater) {

				// Check what kind of change it is, so it can be registered
				if (currentMachineIds != null && currentMachineIds.split(BackendModel.MACHINE_IDS_SEPARATOR)[0] == __recipeIds.split(BackendModel.MACHINE_IDS_SEPARATOR)[0]) {
					// Same beverage
					lastInventoryRelatedCommand = INVENTORY_RELATED_COMMAND_FLAVOR_CHANGE;
				} else {
					// Different beverage
					lastInventoryRelatedCommand = INVENTORY_RELATED_COMMAND_BEVERAGE_CHANGE;
				}

				currentMachineIds = __recipeIds;
				sendCommand(BACKEND_COMMAND_BEVERAGE_SELECT, currentMachineIds);
			}
		}

		private static function setLightColor(__red:uint, __green:uint, __blue:uint, __brightness:uint, __transitionMS:uint):void {
			__red = MathUtils.clamp(__red, 0, 255);
			__green = MathUtils.clamp(__green, 0, 255);
			__blue = MathUtils.clamp(__blue, 0, 255);
			__brightness = MathUtils.clamp(__brightness, 0, 255);

			if (__red != lightningColorR || __green != lightningColorG || __blue != lightningColorB || __brightness != lightningColorBrightness) {
				// Actual change
				lightningColorR = __red;
				lightningColorG = __green;
				lightningColorB = __blue;
				lightningColorBrightness = __brightness;
				lightningColorTransitionTime = __transitionMS;

				sendCommand(BACKEND_COMMAND_LIGHTNING, lightningColorR, lightningColorG, lightningColorB, lightningColorBrightness, lightningColorTransitionTime);

				dispatchEvents(new Event(EVENT_LIGHT_COLOR_CHANGE));
			}
		}

		private static function setLightNozzleBrightness(__brightness:uint, __transitionMS:uint):void {
			__brightness = MathUtils.clamp(__brightness, 0, 255);
			if (__brightness != lightningNozzleColorBrightness) {
				// Actual change
				lightningNozzleColorBrightness = __brightness;
				lightningNozzleColorTransitionTime = __transitionMS;

				BackendModel.sendCommand(BACKEND_COMMAND_LIGHTNING_NOZZLE, lightningNozzleColorBrightness, lightningNozzleColorTransitionTime);

				dispatchEvents(new Event(EVENT_LIGHT_NOZZLE_BRIGHTNESS_CHANGE));
			}
		}

		private static function dispatchEvents(__event:Event):void {
			// Causes all BackendModel instances to dispatch the desired events
			for (var i:int = 0; i < modelInstances.length; i++) {
				modelInstances[i].dispatchEvent(__event);
			}
		}

		private static function refreshCupSizesInternal():void {
			// Queries the machine about the list of available cup sizes
			if (!DEBUG_TURN_OFF_LOGS) log("Refreshing cup sizes:");

			var responseString:String = sendCommand(BACKEND_COMMAND_BEVERAGE_CUPS_SIZES);

			if (responseString != null && responseString.length > 0) {
				var responseXML:XML = new XML(responseString);
				var cupData:XMLList = responseXML.child("CupSize");
				cupSizes.length = 0;
				var cupSizeInfo:CupSizeInfo;
				for (var i:int = 0; i < cupData.length(); i++) {
					cupSizeInfo = new CupSizeInfo();
					cupSizeInfo.id			= XMLUtils.getAttributeAsString(cupData[i], "Id", "");
					cupSizeInfo.name		= XMLUtils.getAttributeAsString(cupData[i], "Name", "");
					cupSizeInfo.amount		= XMLUtils.getAttributeAsFloat(cupData[i], "Amount", 0);
					cupSizeInfo.isDefault	= XMLUtils.getAttributeAsBoolean(cupData[i], "Default", false);
					cupSizes.push(cupSizeInfo);
				}

				System.disposeXML(responseXML);
				responseXML = null;

				// Sort
				cupSizes.sort(CupSizeInfo.sort);
			}
		}

		private static function refreshIceAmountsInternal():void {
			// Queries the machine about the list of available cup sizes
			if (!DEBUG_TURN_OFF_LOGS) log("Refreshing ice amounts:");

			var responseString:String = sendCommand(BACKEND_COMMAND_BEVERAGE_ICE_AMOUNTS);

			if (responseString != null && responseString.length > 0) {
				var responseXML:XML = new XML(responseString);
				var iceData:XMLList = responseXML.child("IceAmount");
				iceAmounts.length = 0;
				var iceAmountInfo:IceAmountInfo;
				for (var i:int = 0; i < iceData.length(); i++) {
					iceAmountInfo = new IceAmountInfo();
					iceAmountInfo.id		= XMLUtils.getAttributeAsString(iceData[i], "Id", "");
					iceAmountInfo.name		= XMLUtils.getAttributeAsString(iceData[i], "Name", "");
					iceAmountInfo.isDefault	= XMLUtils.getAttributeAsBoolean(iceData[i], "Default", false);
					iceAmounts.push(iceAmountInfo);
				}

				System.disposeXML(responseXML);
				responseXML = null;

				if (DEBUG_SIMULATE_ZERO_LENGTH_ICE_AMOUNTS) iceAmounts.length = 0;
			}
		}

		private static function refreshRecipeAvailabilityInternal(__forceRefresh:Boolean):void {
			// Queries the machine to know which recipes are available or not
			if (!DEBUG_TURN_OFF_LOGS) log("Refreshing inventory list:");

			hasRecipeAvailabilityChanged = false;

			if (__forceRefresh || machineIdsForLastAvailability != currentMachineIds) {
				machineIdsForLastAvailability = currentMachineIds;

				var responseString:String = sendCommand(BACKEND_COMMAND_INVENTORY_LIST);
				var i:int;
				var iis:String;

				var oldRecipeAvailability:Object = recipeAvailability;
				recipeAvailability = {};

				if (responseString != null && responseString.length > 0) {
					var responseXML:XML = new XML(responseString);
					var recipeData:XMLList = (responseXML.child("Recipes")[0] as XML).child("Recipe");
					for (i = 0; i < recipeData.length(); i++) {
						recipeAvailability[XMLUtils.getAttributeAsString(recipeData[i], "Id")] = XMLUtils.getAttributeAsBoolean(recipeData[i], "Available");
					}

					System.disposeXML(responseXML);
					responseXML = null;
				}

				if (oldRecipeAvailability == null) {
					// It has changed because none existed
					hasRecipeAvailabilityChanged = true;
				} else {
					// Compare two objects to see if anything actually changed
					for (iis in oldRecipeAvailability) {
						if ((!recipeAvailability.hasOwnProperty(iis) && oldRecipeAvailability[iis] != recipeAvailabilityDefault) || oldRecipeAvailability[iis] != recipeAvailability[iis]) {
							// Old data doesn't exist in new (and the old was not the default), or is different in the new
							hasRecipeAvailabilityChanged = true;
							break;
						}
					}

					if (!hasRecipeAvailabilityChanged) {
						for (iis in recipeAvailability) {
							if (!oldRecipeAvailability.hasOwnProperty(iis) && recipeAvailability[iis] != recipeAvailabilityDefault) {
								// New data doesn't exist in old data, and the new one is not the default
								hasRecipeAvailabilityChanged = true;
								break;
							}
						}
					}
				}
			}
		}

		private static function refreshServicesRequiredInternal():void {
			// Queries the machine to know which services require attention
			if (!DEBUG_TURN_OFF_LOGS) log("Refreshing services required:");
			var responseString:String = sendCommand(BACKEND_COMMAND_SYSTEM_STATUS_SERVICES_REQUIRED);

			servicesRequired = {};

			if (responseString != null && responseString.length > 0) {
				var responseXML:XML = new XML(responseString);
				var servicesData:XMLList = responseXML.children();
				for (var i:int = 0; i < servicesData.length(); i++) {
					servicesRequired[String((servicesData[i] as XML).name()).toLowerCase()] = XMLUtils.getAttributeAsBoolean(servicesData[i], "ServiceRequired");
				}
				System.disposeXML(responseXML);
				responseXML = null;
			}
		}


		// ================================================================================================================
		// STATIC EVENT INTERFACE -----------------------------------------------------------------------------------------

		private static function onAdaEnter(...__args):void {
			dispatchEvents(new Event(EVENT_ADA_ENTER));
			dispatchEvents(new Event(EVENT_BUTTON_ANY));
		}

		private static function onAdaExit(...__args):void {
			dispatchEvents(new Event(EVENT_ADA_EXIT));
			dispatchEvents(new Event(EVENT_BUTTON_ANY));
		}

		private static function onAdaButtonPressed(...__args):void {
			var buttonId:String = String(__args[0]);
			switch (buttonId) {
				case BACKEND_BUTTON_BACK:
					dispatchEvents(new Event(EVENT_BUTTON_BACK));
					dispatchEvents(new Event(EVENT_BUTTON_ANY));
					break;
				case BACKEND_BUTTON_UP:
					dispatchEvents(new Event(EVENT_BUTTON_UP));
					dispatchEvents(new Event(EVENT_BUTTON_ANY));
					break;
				case BACKEND_BUTTON_DOWN:
					dispatchEvents(new Event(EVENT_BUTTON_DOWN));
					dispatchEvents(new Event(EVENT_BUTTON_ANY));
					break;
				case BACKEND_BUTTON_LEFT:
					dispatchEvents(new Event(EVENT_BUTTON_LEFT));
					dispatchEvents(new Event(EVENT_BUTTON_ANY));
					break;
				case BACKEND_BUTTON_RIGHT:
					dispatchEvents(new Event(EVENT_BUTTON_RIGHT));
					dispatchEvents(new Event(EVENT_BUTTON_ANY));
					break;
			}

			dispatchEvents(new Event(EVENT_BUTTON_ANY));
		}

		private static function onAdaButtonDown(...__args):void {
			var buttonId:String = String(__args[0]);
			switch (buttonId) {
				case BACKEND_BUTTON_SELECT:
					dispatchEvents(new Event(EVENT_BUTTON_SELECT_PRESS));
					dispatchEvents(new Event(EVENT_BUTTON_ANY));
					break;
				case BACKEND_BUTTON_ICE:
					dispatchEvents(new Event(EVENT_BUTTON_ICE_PRESS));
					dispatchEvents(new Event(EVENT_BUTTON_ANY));
					break;
				case BACKEND_BUTTON_POUR:
					dispatchEvents(new Event(EVENT_BUTTON_POUR_PRESS));
					dispatchEvents(new Event(EVENT_BUTTON_ANY));
					break;
				case BACKEND_BUTTON_WATER:
					dispatchEvents(new Event(EVENT_BUTTON_WATER_PRESS));
					dispatchEvents(new Event(EVENT_BUTTON_ANY));
					break;
			}
		}

		private static function onAdaButtonUp(...__args):void {
			var buttonId:String = String(__args[0]);
			switch (buttonId) {
				case BACKEND_BUTTON_SELECT:
					dispatchEvents(new Event(EVENT_BUTTON_SELECT_RELEASE));
					dispatchEvents(new Event(EVENT_BUTTON_ANY));
					break;
				case BACKEND_BUTTON_ICE:
					dispatchEvents(new Event(EVENT_BUTTON_ICE_RELEASE));
					dispatchEvents(new Event(EVENT_BUTTON_ANY));
					break;
				case BACKEND_BUTTON_POUR:
					dispatchEvents(new Event(EVENT_BUTTON_POUR_RELEASE));
					dispatchEvents(new Event(EVENT_BUTTON_ANY));
					break;
				case BACKEND_BUTTON_WATER:
					dispatchEvents(new Event(EVENT_BUTTON_WATER_RELEASE));
					dispatchEvents(new Event(EVENT_BUTTON_ANY));
					break;
			}
		}

		public static function debug_injectOnInventoryChanged():void {
			lastInventoryRelatedCommand = BackendModel.INVENTORY_RELATED_COMMAND_UNKNOWN;
			onInventoryChanged(null);
		}

		public static function debug_injectOnRequestPinPad():void {
			onRequestPinPad(null);
		}

		public static function debug_injectOnOutOfOrder(__message:String = "INSERT MESSAGE HERE"):void {
			onOutOfOrder(__message);
		}

		public static function debug_injectOnInOrder():void {
			onInOrder(null);
		}

		public static function debug_injectOnCupPourComplete():void {
			onCupPourComplete(null);
		}

		public static function debug_injectServiceChanged(__serviceIds:Array):void {
			servicesRequired = {};
			for each (var iis:String in __serviceIds) {
				servicesRequired[iis.toLowerCase()] = true;
			}
			dispatchEvents(new Event(EVENT_SERVICES_REQUIRED_CHANGED));
		}

		private static function onInventoryChanged(...__args):void {
			if (!DEBUG_TURN_OFF_LOGS) info("Command received from backend: inventory has changed");

			var mustRefreshRecipes:Boolean = false;

			if (lastInventoryRelatedCommand == INVENTORY_RELATED_COMMAND_BEVERAGE_CHANGE) {
				mustRefreshRecipes = !skipInventoryListBeverageChange;
			} else if (lastInventoryRelatedCommand == INVENTORY_RELATED_COMMAND_FLAVOR_CHANGE) {
				mustRefreshRecipes = !skipInventoryListFlavorChange;
			} else if (lastInventoryRelatedCommand == INVENTORY_RELATED_COMMAND_STARTUP) {
				mustRefreshRecipes = !skipInventoryListStartup;
			} else {
				mustRefreshRecipes = true;
			}

			if (mustRefreshRecipes) {
				refreshRecipeAvailabilityInternal(true);
				if (hasRecipeAvailabilityChanged || DEBUG_RANDOM_INVENTORY_AVAILABILITY) {
					dispatchEvents(new Event(EVENT_RECIPE_AVAILABILITY_CHANGED));
				} else {
					if (!DEBUG_TURN_OFF_LOGS) warn("Inventory change dispatch skipped: no change!");
				}
			} else {
				if (!DEBUG_TURN_OFF_LOGS) warn("Inventory change dispatch skipped: ignored after command [" + lastInventoryRelatedCommand + "]");
			}

			// Post-command refresh consumed, allow additional refreshes in the future
			lastInventoryRelatedCommand = BackendModel.INVENTORY_RELATED_COMMAND_UNKNOWN;
		}

		private static function onServiceChanged(...__args):void {
			if (!DEBUG_TURN_OFF_LOGS) info("Command received from backend: services required have changed");
			refreshServicesRequiredInternal();
			dispatchEvents(new Event(EVENT_SERVICES_REQUIRED_CHANGED));
		}

		private static function onInOrder(...__args):void {
			if (!DEBUG_TURN_OFF_LOGS) info("Command received from backend: on in order");
			if (_isOutOfOrder || !_isOutOfOrderStateKnown) {
				var message:String = __args.length > 0 ? String(__args[0]) : "";
				if (!DEBUG_TURN_OFF_LOGS) info("OnInOrder called with message: [" + message + "]"); // e.g. "Touch screen not responding"

				if (immediateOnInOrderEvent) {
					dispatchLateIsInOrderEvent();
				} else {
					DelayedCalls.remove(dispatchLateIsInOrderEvent);
					DelayedCalls.add(100, dispatchLateIsInOrderEvent);
				}
			}
		}

		private static function dispatchLateIsInOrderEvent():void {
			currentMachineIds = null;
			_isOutOfOrder = false;
			_isOutOfOrderStateKnown = true;
			dispatchEvents(new Event(EVENT_IS_IN_ORDER));
		}

		private static function onOutOfOrder(...__args):void {
			if (!DEBUG_TURN_OFF_LOGS) info("Command received from backend: on out of order");
			if (!ignoreOutOfOrderCalls) {
				var message:String = __args.length > 0 && __args[0] != null ? String(__args[0]) : "";
				if (!DEBUG_TURN_OFF_LOGS) info("OnOutOfOrder called with message: [" + message + "]"); // e.g. "Touch screen not responding"
				_outOfOrderMessage = message;

				if (!_isOutOfOrder || !_isOutOfOrderStateKnown) {
					_isOutOfOrder = true;
					_isOutOfOrderStateKnown = true;

					// Stop auto-pour (if it is pouring)
					onCupPourComplete();

					if (_isPouringWater || _isPouringBeverage) dispatchEvents(new Event(EVENT_STOPPED_POURING));

					_isPouringCup = false;
					_isPouringWater = false;
					_isPouringBeverage = false;

					dispatchEvents(new Event(EVENT_IS_OUT_OF_ORDER));
				} else {
					dispatchEvents(new Event(EVENT_IS_OUT_OF_ORDER_UPDATE));
				}
			}
		}

		private static function onCupPourComplete(...__args):void {
			if (!DEBUG_TURN_OFF_LOGS) info("Command received from backend: cup pour complete");
			if (_isPouringCup) {
				_isPouringCup = false;
				dispatchEvents(new Event(EVENT_CUP_POUR_COMPLETE));
			}
		}

		private static function onMustSelect(...__args):void {
			if (!DEBUG_TURN_OFF_LOGS) info("Command received from backend: select beverages [" + __args + "]");

			var idList:String = __args.length > 0 && __args[0] != null ? String(__args[0]) : "";
			if (idList.length > 0) {
				var ids:Array = idList.split(",");
				_mustSelectBeverageId = ids[0];
				_mustSelectFlavorIds = new Vector.<String>();
				for (var i:int = 1; i < ids.length; i++) _mustSelectFlavorIds.push(ids[i]);
				dispatchEvents(new Event(EVENT_MUST_SELECT_BEVERAGE));
			}
		}

		private static function onRequestPinPad(...__args):void {
			if (!DEBUG_TURN_OFF_LOGS) info("Command received from backend: pin pad requested");
			dispatchEvents(new Event(EVENT_REQUEST_PIN_KEYPAD));
		}

		private static function onGetVersion(...___args):String {
			return FountainFamily.APP_VERSION;
		}

		private static function onGetBuildNumber(...___args):String {
			return FountainFamily.APP_BUILD_NUMBER;
		}

		private static function onGetBuildDate(...___args):String {
			return FountainFamily.APP_BUILD_DATE;
		}

		private static function onAutoTestStart(...___args):void {
			if (!DEBUG_TURN_OFF_LOGS) info("Command received from backend: autotest start");

			dispatchEvents(new Event(EVENT_AUTOTEST_START));
		}

		private static function onAutoTestStop(...___args):void {
			if (!DEBUG_TURN_OFF_LOGS) info("Command received from backend: autotest stop");

			dispatchEvents(new Event(EVENT_AUTOTEST_STOP));
		}


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function BackendModel() {
			modelInstances.push(this);
			numEventListeners = 0;
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function selectBeverageInternal(__brandId:String, __flavorIds:Vector.<String> = null):void {
			if (!DEBUG_TURN_OFF_LOGS) debug("Selected drink [" + __brandId + "] with flavor ids [" + __flavorIds + "]");
			var recipeIds:Vector.<String> = new Vector.<String>();
			recipeIds.push(__brandId);
			if (__flavorIds != null) {
				for (var i:int = 0; i < __flavorIds.length; i++) {
					recipeIds.push(__flavorIds[i]);
				}
			}
			var newIds:String = recipeIds.join(MACHINE_IDS_SEPARATOR);
			if (currentIds != newIds) {
				// Changed selection
				currentIds = newIds;
			}

			// Always changes the machine recipe ids
			BackendModel.selectBeverage(currentIds);
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		override public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			numEventListeners++;
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}

		override public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			if (hasEventListener(type)) numEventListeners--;
			super.removeEventListener(type, listener, useCapture);
		}

		public function selectBeverage(__brandId:String, __flavorIds:Vector.<String> = null):void {
			selectBeverageInternal(__brandId, __flavorIds);
		}

		public function startCupPour(__cupSizeId:String, __iceAmountId:String):void {
			_isPouringCup = true;
			BackendModel.selectBeverage(currentIds);
			sendCommand(BACKEND_COMMAND_BEVERAGE_POUR_CUP, __cupSizeId, __iceAmountId);
		}

		public function startPour():void {
			// Make sure the current recipe ids haven't changed
			stopPourEverything();

			_isPouringBeverage = true;
			BackendModel.selectBeverage(currentIds);
			sendCommand(BACKEND_COMMAND_BEVERAGE_START);
			BackendModel.dispatchEvents(new Event(EVENT_STARTED_POURING));
		}

		public function stopPour():void {
			if (_isPouringBeverage) {
				_isPouringBeverage = false;
				sendCommand(BACKEND_COMMAND_BEVERAGE_STOP);
				if (_isPouringCup) {
					BackendModel.onCupPourComplete();
				} else {
					BackendModel.dispatchEvents(new Event(EVENT_STOPPED_POURING));
				}
			}
		}

		public function startPourWater():void {
			stopPourEverything();

			// Water.Pour needs to invalidate the current beverage selection apparently.
			// Lots of code in UI contradicts this need, we may need a refactor to simplify a few things
			currentMachineIds = null;

			_isPouringWater = true;
			sendCommand(BACKEND_COMMAND_WATER_START);
			BackendModel.dispatchEvents(new Event(EVENT_STARTED_POURING));
		}

		public function stopPourWater():void {
			if (_isPouringWater) {
				_isPouringWater = false;
				sendCommand(BACKEND_COMMAND_WATER_STOP);
				BackendModel.dispatchEvents(new Event(EVENT_STOPPED_POURING));
			}
		}

		public function stopPourEverything():void {
			stopPour();
			stopPourWater();
		}

		// Analytics API
		public function trackScreenChanged(__screenId:String, __context:String = ""):void {
			//log("Screen [" + __screenId + "], context [" + __context + "]");
			sendCommand(BACKEND_COMMAND_ANALYTICS_SCREEN_CHANGED, __screenId, __context);
		}

		public function trackButtonPressed(__buttonId:String):void {
			//log("Button [" + __buttonId + "]");
			sendCommand(BACKEND_COMMAND_ANALYTICS_BUTTON_PRESSED, __buttonId);
		}

		// Pin API
		public function trackPinPrompt():void {
			// Tell the backend the Pin screen is being shown; merely informative
			sendCommand(BACKEND_COMMAND_PIN_PROMPT);
		}

		public function validatePin(__code:String):Vector.<BackendPinAction> {
			if (!DEBUG_TURN_OFF_LOGS) log("Sending PIN code: [" + __code + "]");
			var responseString:String = sendCommand(BACKEND_COMMAND_PIN_VALIDATE_PIN, __code);

			if (responseString == null || responseString.length == 0) return null;

			var actions:Vector.<BackendPinAction> = new Vector.<BackendPinAction>();

			var responseXML:XML = new XML(responseString);
			var actionData:XMLList = (responseXML.child("actions")[0] as XML).child("action");
			var action:BackendPinAction;
			for (var i:int = 0; i < actionData.length(); i++) {
				action = new BackendPinAction();
				action.id = XMLUtils.getNodeAsString(actionData[i], "id");
				action.label = XMLUtils.getNodeAsString(actionData[i], "label");
				action.relatedService = XMLUtils.getNodeAsString(actionData[i], "relatedService");
				action.type = XMLUtils.getNodeAsString(actionData[i], "type");
				actions.push(action);
			}
			System.disposeXML(responseXML);
			responseXML = null;

			return actions;
		}

		public function executePinAction(__id:String):void {
			sendCommand(BACKEND_COMMAND_PIN_EXECUTE_PIN_ACTION, __id);
		}

		// Lightning API
		public function setLightColorARGB(__colorAARRGGBB:uint, __transitionMS:uint = 0, __brightnessScale:Number = 1):void {
			setLightColor((__colorAARRGGBB >> 16) & 0xff, (__colorAARRGGBB >> 8) & 0xff, __colorAARRGGBB & 0xff, (__colorAARRGGBB >> 24) & 0xff, __transitionMS, __brightnessScale);
		}

		public function setLightColorRGB(__colorRRGGBB:uint, __brightness:uint, __transitionMS:uint = 0, __brightnessScale:Number = 1):void {
			setLightColor((__colorRRGGBB >> 16) & 0xff, (__colorRRGGBB >> 8) & 0xff, __colorRRGGBB & 0xff, __brightness, __transitionMS, __brightnessScale);
		}

		public function setLightColor(__red:uint, __green:uint, __blue:uint, __brightness:uint, __transitionMS:uint = 0, __brightnessScale:Number = 1):void {
			BackendModel.setLightColor(__red, __green, __blue, Math.round(__brightness * __brightnessScale), __transitionMS);
		}

		public function setLightNozzleBrightness(__brightness:uint, __transitionMS:uint = 0, __brightnessScale:Number = 1):void {
			BackendModel.setLightNozzleBrightness(Math.round(__brightness * __brightnessScale), __transitionMS);
		}

		// Other
		public function refreshRecipeAvailability(__forceRefresh:Boolean = false):void {
			refreshRecipeAvailabilityInternal(__forceRefresh);
		}

		public function refreshServicesRequired():void {
			refreshServicesRequiredInternal();
		}

		public function refreshCupSizes():void {
			refreshCupSizesInternal();
		}

		public function refreshIceAmounts():void {
			refreshIceAmountsInternal();
		}

		public function getServiceRequiredStatus(__serviceId:String):Boolean {
			/*
			 * Possible ids:
			 * Cartridge      : ?
			 * Ice            : ?
			 * Technician     : ?
			 *
			 * CO2Level       : CO2 low
			 * StillWaterTemp : Tap water temp too high
			 * CarbWaterTemp  : Carbonated water temp too high
			 * BrandSoldOut   : Sold out flavor shot(s)
			 * FlavorSoldOut  : Sold out brand(s)
			 */
			__serviceId = __serviceId.toLowerCase();
			if (serviceNeverRequired) return false;
			if (servicesRequired != null && servicesRequired.hasOwnProperty(__serviceId)) return Boolean(servicesRequired[__serviceId]);
			return serviceRequiredStatusDefault;
		}

		public function getRecipeAvailability(__recipeId:String):Boolean {
			// Responds whether a recipe is available in this machine, as reported by the backend
			if (DEBUG_RANDOM_INVENTORY_AVAILABILITY) return Math.random() > 0.5;
			if (recipeAvailability != null && recipeAvailability.hasOwnProperty(__recipeId)) return Boolean(recipeAvailability[__recipeId]);
			return recipeAvailabilityDefault;
		}

		public function getCupSizes():Vector.<CupSizeInfo> {
			return cupSizes;
		}

		public function getIceAmounts():Vector.<IceAmountInfo> {
			return iceAmounts;
		}

		public function getNumEventListeners():uint {
			return numEventListeners;
		}

		public function getLightColor():Color {
			return Color.fromRGB(lightningColorR/255, lightningColorG/255, lightningColorB/255, lightningColorBrightness/255);
		}

		public function getLightColorTransitionTime():uint {
			return lightningColorTransitionTime;
		}

		public function getLightNozzleBrightness():Number {
			return BackendModel.lightningNozzleColorBrightness;
		}

		public function getLightNozzleColorTransitionTime():uint {
			return lightningNozzleColorTransitionTime;
		}

		public function getCurrentBeverageId():String {
			if (BackendModel.currentMachineIds != null && BackendModel.currentMachineIds.length > 0) {
				return currentMachineIds.split(BackendModel.MACHINE_IDS_SEPARATOR)[0];
			} else {
				return null;
			}
		}

		public function getCurrentFlavorIds():Vector.<String> {
			if (BackendModel.currentMachineIds != null && BackendModel.currentMachineIds.length > 0) {
				var str:Array = currentMachineIds.split(BackendModel.MACHINE_IDS_SEPARATOR);
				var allFlavors:Vector.<String> = new Vector.<String>();
				for (var i:int = 1; i < str.length; i++) {
					allFlavors.push(str[i]);
				}
				return allFlavors;
			} else {
				return null;
			}
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function get isOutOfOrder():Boolean {
			return _isOutOfOrder;
		}

		public function get outOfOrderMessage():String {
			return _outOfOrderMessage;
		}

		public function get isPouringCup():Boolean {
			return _isPouringCup;
		}

		public function isPouringAnything():Boolean {
			return _isPouringCup || _isPouringBeverage || _isPouringWater;
		}

		public function isPouringBeverage():Boolean {
			return _isPouringBeverage;
		}

		public function isPouringWater():Boolean {
			return _isPouringWater;
		}
	}
}