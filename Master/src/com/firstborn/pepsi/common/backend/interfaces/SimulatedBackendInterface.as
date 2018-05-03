package com.firstborn.pepsi.common.backend.interfaces {
	import com.zehfernando.utils.AppUtils;
	import com.zehfernando.utils.DelayedCalls;
	import com.zehfernando.utils.console.error;
	import com.zehfernando.utils.console.log;
	import com.zehfernando.utils.getTimerUInt;
	/**
	 * @author zeh fernando
	 */
	public class SimulatedBackendInterface implements IBackendInterface {

		/**
		 * A mock implementation of the BackendInterface: simulates the ExternalInterface calls and responses
		 */

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
		private static const BACKEND_EVENT_PIN_ON_REQUEST_PIN_PAD			:String = "Pin.OnRequestPinKeypad";
		private static const BACKEND_EVENT_GET_VERSION						:String = "Get.Version";
		private static const BACKEND_EVENT_GET_BUILD_NUMBER					:String = "Get.BuildNumber";
		private static const BACKEND_EVENT_GET_BUILD_DATE					:String = "Get.BuildDate";

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

		// Constants
		private static const FLAG_SHOW_LOG									:Boolean = AppUtils.isDebugSWF() && false;

		// Properties
		private var simulateSlowCalls:Boolean;
		private var callbacks:Object;										// Arrays with functions


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function SimulatedBackendInterface(__simulateSlowCalls:Boolean) {
			simulateSlowCalls = __simulateSlowCalls;
			callbacks = {};
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function call(__functionName:String, ...__args:*):* {
			switch(__functionName) {
				case BACKEND_COMMAND_BEVERAGE_CUPS_SIZES:
					return simulateCommandBeverageCupSizes();
				case BACKEND_COMMAND_BEVERAGE_ICE_AMOUNTS:
					return simulateCommandBeverageIceAmounts();
				case BACKEND_COMMAND_INVENTORY_LIST:
					return simulateCommandInventoryList();
				case BACKEND_COMMAND_SYSTEM_STATUS_SERVICES_REQUIRED:
					return simulateCommandSystemStatusServicesRequired();
				case BACKEND_COMMAND_PIN_VALIDATE_PIN:
					return simulateCommandPinValidatePin();
				case BACKEND_COMMAND_BEVERAGE_POUR_CUP:
					queueCallback(BACKEND_EVENT_BEVERAGE_ON_CUP_POUR_COMPLETE, 1000);
					break;
				case BACKEND_COMMAND_BEVERAGE_SELECT:
					queueCallback(BACKEND_EVENT_INVENTORY_ON_INVENTORY_CHANGED, 1);
					break;
				case BACKEND_COMMAND_BEVERAGE_START:
				case BACKEND_COMMAND_BEVERAGE_STOP:
				case BACKEND_COMMAND_WATER_START:
				case BACKEND_COMMAND_WATER_STOP:
					break;
				default:
					error("Function [" + __functionName + "] not implemented by mock interface!");
			}

			return null;
		}

		public function addCallback(__functionName:String, __closure:Function):void {
			if (!callbacks.hasOwnProperty(__functionName)) callbacks[__functionName] = new Vector.<Function>();

			(callbacks[__functionName] as Vector.<Function>).push(__closure);
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function get available():Boolean {
			return true;
		}

		public function get objectID():String {
			return "simulated-backend-interface";
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function queueCallback(__callback:String, __timeMS:int):void {
			// Queues a callback command to be sent in __timeMS
			DelayedCalls.add(__timeMS, dispatchCallback, [__callback]);
		}

		private function dispatchCallback(__callback:String):void {
			// Dispatches a callback immediately

			if (callbacks.hasOwnProperty(__callback)) {
				var funcs:Vector.<Function> = callbacks[__callback] as Vector.<Function>;
				for (var i:int = 0; i < funcs.length; i++) funcs[i].apply(null, []);
			}
		}

		private function simulateCommandBeverageCupSizes():String {
			if (simulateSlowCalls) wait(100);

			return (
				<CupSizes>
					<CupSize Id="1" Name="Medium" Amount="16"/>
					<CupSize Id="2" Name="Large" Amount="20"/>
					<!--<CupSize Id="0" Name="Small" Amount="8"/>-->
					<CupSize Id="4" Name="Pitcher" Amount="48"/>
				</CupSizes>
			);
		}

		private function simulateCommandBeverageIceAmounts():String {
			if (simulateSlowCalls) wait(100);

			return (
				<IceAmounts>
					<IceAmount Id="0" Name="Minimal"/>
					<IceAmount Id="1" Name="Regular"/>
					<IceAmount Id="2" Name="Full"/>
				</IceAmounts>
			);
		}

		private function simulateCommandInventoryList():String {
			if (simulateSlowCalls) wait(1000);

			return (
				<Inventory>
					<Recipes>
						<Recipe Id="5cf869af-d91c-4a56-930a-1de427d13055" Available="true" />
						<Recipe Id="96e1f1d2-ce1b-47bc-ad3b-9bfcee8de8f9" Available="true" />
						<Recipe Id="d690b699-a9c9-449e-ac6a-38f5a5b3930e" Available="true" />
						<Recipe Id="ae7592bd-e4fd-4895-af8c-5ba17698bc7b" Available="true" />
						<Recipe Id="534a5a0f-a35d-47a1-9270-9fd8c233542b" Available="true" />
						<Recipe Id="f7b41789-80b9-41d5-a3c8-64b3a6346a90" Available="false" />
						<Recipe Id="5f4d8cb2-f9a0-4c7f-a649-e3f5ba5cc8ff" Available="false" />
						<Recipe Id="e431d94a-699e-44f2-be87-59e52b336b30" Available="false" />
						<Recipe Id="4eae68f5-92d6-48ee-90ce-486dc1a84878" Available="false" />
						<Recipe Id="8f76e30b-c82f-441b-90d9-1a57b7c903d7" Available="false" />
						<Recipe Id="69bd03e0-a656-4c02-b741-b94cb0bdd1b5" Available="false" />
						<Recipe Id="6b92485a-6f62-4f37-98f1-fe309c2acdc1" Available="false" />
						<Recipe Id="ee1aded4-5f43-4571-80d0-d6acdc57e857" Available="false" />
						<Recipe Id="5dd7cc18-afe9-4daf-8f54-c907069a85ad" Available="false" />
						<Recipe Id="69101a3c-f79c-4aae-bb9d-81209d121c53" Available="false" />
						<Recipe Id="5be91d4c-3d5e-4f95-bdfb-09e83ab4a196" Available="false" />
						<Recipe Id="bc331e6e-6315-48c7-a1f0-e140eadc7d10" Available="false" />
						<Recipe Id="79d8b159-bedd-4794-a2c7-373fafedf940" Available="false" />
						<Recipe Id="1768ee2d-493f-453f-aa82-3492773e7ed5" Available="false" />
						<Recipe Id="e6e133cb-6315-48c7-a1f0-01d7cdae041e" Available="false" />
						<Recipe Id="ad018d95-3cd2-4883-86bc-a70b7ba383aa" Available="false" />
						<Recipe Id="b9dfe2c0-0b4b-43da-a1d4-64e13ed9b7d8" Available="false" />
						<Recipe Id="6761903e-d5e0-4c12-a7fd-4a84252abab1" Available="false" />
						<Recipe Id="3edd71ae-47c4-4349-a5ff-953abd0b74c8" Available="false" />
						<Recipe Id="7bf7f2ce-bb76-4c7a-a2ea-abae59354b1c" Available="false" />
						<Recipe Id="d406b898-8e4d-4ee7-b04a-bc8a3c5f79ea" Available="false" />
						<Recipe Id="24d3fc13-5739-4388-a7cb-d6842c3e5efc" Available="false" />
						<Recipe Id="67130f75-2518-42d3-a47b-18cb2009d7a6" Available="false" />
						<Recipe Id="24db46b5-d0f6-4782-9734-03d031fd90c5" Available="false" />
						<Recipe Id="bda4ca4c-f0bf-4d0e-9c34-cc6bdbbf8d41" Available="false" />
						<Recipe Id="fcb44600-acd4-4686-8f28-6612b6def2f1" Available="false" />
						<Recipe Id="eb6bc44b-89f8-4fb8-8530-d2bb3486bcba" Available="false" />
						<Recipe Id="7b0bfe17-f003-4e60-8068-8ce4e332304c" Available="false" />
						<Recipe Id="b7eb0d79-1e2c-49fa-9a42-d9a998d36511" Available="false" />
						<Recipe Id="e46acfbc-77b1-4d46-9023-0eebd387de91" Available="false" />
						<Recipe Id="44c77fd9-90c0-4ed8-9b01-f202f0dda336" Available="false" />
						<Recipe Id="a5b6df91-5837-4d74-ae52-7077e5dcb255" Available="false" />
						<Recipe Id="16e3e80b-11c7-4c12-aab1-10cd5292264e" Available="false" />
						<Recipe Id="f329d9b2-94a2-4c9d-95a0-8e8b8ac00a5c" Available="false" />
						<Recipe Id="73fd5c76-b87d-4628-addd-6e7b35fe79c8" Available="false" />
						<Recipe Id="f094e81a-b006-410d-9d38-58246e08e51f" Available="false" />
						<Recipe Id="012000043222" Available="true" /> <!-- Cherry -->
						<Recipe Id="012000427428" Available="false" /> <!-- Cranberry -->
						<Recipe Id="012000043284" Available="false" /> <!-- Grape -->
						<Recipe Id="012000043246" Available="false" />
						<Recipe Id="012000043253" Available="false" />
						<Recipe Id="012000427411" Available="false" />
						<Recipe Id="012000043260" Available="false" />
						<Recipe Id="012000043277" Available="false" />
						<Recipe Id="012000043239" Available="false" />
						<Recipe Id="012000043215" Available="false" />
					</Recipes>
				</Inventory>
			);
		}

		private function simulateCommandSystemStatusServicesRequired():String {
			if (simulateSlowCalls) wait(1000);

			return (
				<Services>
					<Cartridge ServiceRequired="true" />
					<Ice ServiceRequired="true" />
					<Technician ServiceRequired="true" />

					<CO2Level ServiceRequired="true" />
					<StillWaterTemp ServiceRequired="true" />
					<CarbWaterTemp ServiceRequired="true" />
					<BrandSoldOut ServiceRequired="true" />
					<FlavorSoldOut ServiceRequired="true" />
				</Services>
			);
		}

		private function simulateCommandPinValidatePin():String {
			return (
				<root>
					<accessLabel>Manager</accessLabel>
					<actions>
						<action>
							<id>1</id>
							<label>Main</label>
							<relatedService />
							<type />
						</action>
						<action>
							<id>2</id>
							<label>Ice Door</label>
							<relatedService>ice</relatedService>
							<type>lock</type>
						</action>
						<action>
							<id>3</id>
							<label>Cartridge Door</label>
							<relatedService>cartridge</relatedService>
							<type>lock</type>
						</action>
					</actions>
				</root>
			);
		}

		private static function wait(__timeMS:int):void {
			// Waits for a certain amount of time, artificially freezing the interface
			if (FLAG_SHOW_LOG) log("Waiting " + __timeMS + "ms");
			var ti:uint = getTimerUInt();
			while (getTimerUInt() < ti + __timeMS) {}
		}

	}
}
