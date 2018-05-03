package com.firstborn.pepsi.tester.tests.cases {
	import asunit.framework.TestCase;

	import com.firstborn.pepsi.common.backend.BackendModel;
	import com.firstborn.pepsi.common.backend.interfaces.SimulatedBackendInterface;

	import flash.events.Event;

	/**
	 * @author zeh fernando
	 */
	public class TestBackend extends TestCase {

		// Constants
		private static const RECIPE_ID_SPARKLING_WATER:String = "73fd5c76-b87d-4628-addd-6e7b35fe79c8";
		private static const RECIPE_ID_PEPSI:String = "7bf7f2ce-bb76-4c7a-a2ea-abae59354b1c";

		private static const RECIPE_ID_FLAVOR_1:String = "012000043222";
		private static const RECIPE_ID_FLAVOR_2:String = "012000427428";
		private static const RECIPE_ID_FLAVOR_3:String = "012000043284";

		// Aux vars
		private var calledOnPourStart:Boolean;
		private var calledOnPourStop:Boolean;
		private var calledOnOutOfOrder:Boolean;
		private var calledOnOutOfOrderUpdate:Boolean;
		private var calledOnInOrder:Boolean;
		private var calledOnRequestPinKeypad:Boolean;

		// Instances
		private var backend:BackendModel;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function TestBackend(testMethod:String = null) {
			super(testMethod);
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function testPourTapWater():void {
			// Test water pour off, on, and off
			assertFalse("Should not be  pouring tap water", backend.isPouringAnything());

			testResetEvents();
			backend.startPourWater();
			assertTrue("Should be pouring tap water", backend.isPouringWater() && !backend.isPouringCup && !backend.isPouringBeverage());
			assertFalse("Should not have called pour stop event", calledOnPourStop);
			assertTrue("Should have called pour start event", calledOnPourStart);

			testResetEvents();
			backend.stopPourWater();
			assertFalse("Should not be pouring tap water", backend.isPouringWater());
			assertTrue("Should have called pour stop event", calledOnPourStop);
			assertFalse("Should not have called pour start event", calledOnPourStart);

		}

		public function testPourBeverage():void {
			// Test beverage pour off, on, and off
			assertFalse("Should not be pouring beverage", backend.isPouringAnything());
			backend.selectBeverage(RECIPE_ID_SPARKLING_WATER);

			testResetEvents();
			backend.startPour();
			assertTrue("Should be pouring beverage", !backend.isPouringWater() && !backend.isPouringCup && backend.isPouringBeverage() && backend.getCurrentBeverageId() == RECIPE_ID_SPARKLING_WATER);
			assertFalse("Should not have called pour stop event", calledOnPourStop);
			assertTrue("Should have called pour start event", calledOnPourStart);

			testResetEvents();
			backend.stopPour();
			assertFalse("Should not be pouring beverage", backend.isPouringBeverage());
			assertTrue("Should have called pour stop event", calledOnPourStop);
			assertFalse("Should not have called pour start event", calledOnPourStart);
		}

		public function testBeverageSelection():void {
			backend.selectBeverage(RECIPE_ID_SPARKLING_WATER);
			assertEquals("Beverage should be sparkling water", backend.getCurrentBeverageId(), RECIPE_ID_SPARKLING_WATER);
			assertNotSame("Beverage should not be pepsi", backend.getCurrentBeverageId(), RECIPE_ID_PEPSI);

			backend.selectBeverage(RECIPE_ID_PEPSI);
			assertEquals("Beverage should be pepsi", backend.getCurrentBeverageId(), RECIPE_ID_PEPSI);
			assertNotSame("Beverage should not be sparkling water", backend.getCurrentBeverageId(), RECIPE_ID_SPARKLING_WATER);
			assertTrue("Beverage flavors should have 0 flavors", backend.getCurrentFlavorIds().length == 0);

			backend.selectBeverage(RECIPE_ID_SPARKLING_WATER, new <String>[RECIPE_ID_FLAVOR_1, RECIPE_ID_FLAVOR_2]);
			assertEquals("Beverage should be sparkling water", backend.getCurrentBeverageId(), RECIPE_ID_SPARKLING_WATER);
			assertTrue("Beverage flavors should have 2 flavors", backend.getCurrentFlavorIds().length == 2);
			assertTrue("Beverage flavors should have flavor 1", backend.getCurrentFlavorIds().indexOf(RECIPE_ID_FLAVOR_1) > -1);
			assertTrue("Beverage flavors should have flavor 2", backend.getCurrentFlavorIds().indexOf(RECIPE_ID_FLAVOR_2) > -1);
			assertTrue("Beverage flavors should not have flavor 3", backend.getCurrentFlavorIds().indexOf(RECIPE_ID_FLAVOR_3) == -1);

			backend.selectBeverage(RECIPE_ID_PEPSI, new <String>[RECIPE_ID_FLAVOR_3]);
			assertEquals("Beverage should be pepsi", backend.getCurrentBeverageId(), RECIPE_ID_PEPSI);
			assertTrue("Beverage flavors should have 1 flavor", backend.getCurrentFlavorIds().length == 1);
			assertTrue("Beverage flavors should have flavor 3", backend.getCurrentFlavorIds().indexOf(RECIPE_ID_FLAVOR_3) > -1);
		}

		public function testBeverageWaterSwap():void {
			// Test beverage pour started, water started (should override), beverage stopped, and then water stopped; and vice versa

			assertFalse("Should not be pouring anything", backend.isPouringAnything());

			backend.selectBeverage(RECIPE_ID_SPARKLING_WATER);

			testResetEvents();
			backend.startPour();
			assertTrue("Should be pouring beverage only", !backend.isPouringWater() && !backend.isPouringCup && backend.isPouringBeverage() && backend.getCurrentBeverageId() == RECIPE_ID_SPARKLING_WATER);
			assertFalse("Should not have called pour stop event", calledOnPourStop);
			assertTrue("Should have called pour start event", calledOnPourStart);

			testResetEvents();
			backend.startPourWater();
			assertTrue("Should be pouring tap water only", backend.isPouringWater() && !backend.isPouringCup && !backend.isPouringBeverage());
			assertTrue("Should have called pour stop event", calledOnPourStop);
			assertTrue("Should have called pour start event", calledOnPourStart);

			testResetEvents();
			backend.stopPour();
			assertTrue("Should still be pouring tap water", backend.isPouringWater() && !backend.isPouringCup && !backend.isPouringBeverage());
			assertFalse("Should not have called pour stop event", calledOnPourStop);
			assertFalse("Should not have called pour start event", calledOnPourStart);

			testResetEvents();
			backend.stopPourWater();
			assertFalse("Should not be pouring tap water", backend.isPouringWater());
			assertFalse("Should not be pouring anything", backend.isPouringAnything());
			assertTrue("Should have called pour stop event", calledOnPourStop);
			assertFalse("Should not have called pour start event", calledOnPourStart);

			testResetEvents();
			backend.startPourWater();
			assertTrue("Should be pouring tap water", backend.isPouringWater() && !backend.isPouringCup && !backend.isPouringBeverage());
			assertFalse("Should not have called pour stop event", calledOnPourStop);
			assertTrue("Should have called pour start event", calledOnPourStart);

			testResetEvents();
			backend.startPour();
			assertTrue("Should be pouring beverage instead", !backend.isPouringWater() && !backend.isPouringCup && backend.isPouringBeverage() && backend.getCurrentBeverageId() == RECIPE_ID_SPARKLING_WATER);
			assertTrue("Should have called pour stop event", calledOnPourStop);
			assertTrue("Should have called pour start event", calledOnPourStart);

			testResetEvents();
			backend.stopPourWater();
			assertTrue("Should still be pouring beverage", !backend.isPouringWater() && !backend.isPouringCup && backend.isPouringBeverage() && backend.getCurrentBeverageId() == RECIPE_ID_SPARKLING_WATER);
			assertFalse("Should not have called pour stop event", calledOnPourStop);
			assertFalse("Should not have called pour start event", calledOnPourStart);

			testResetEvents();
			backend.stopPour();
			assertFalse("Should not be pouring beverage", backend.isPouringBeverage());
			assertFalse("Should not be pouring anything", backend.isPouringAnything());
			assertTrue("Should have called pour stop event", calledOnPourStop);
			assertFalse("Should not have called pour start event", calledOnPourStart);
		}

		public function testBeverageWaterOverride():void {
			// Test beverage pour started, water started (should override), water stopped, and then beverage stopped; and vice versa

			assertFalse("Should not be pouring anything", backend.isPouringAnything());

			backend.selectBeverage(RECIPE_ID_SPARKLING_WATER);

			testResetEvents();
			backend.startPour();
			assertTrue("Should be pouring beverage", !backend.isPouringWater() && !backend.isPouringCup && backend.isPouringBeverage() && backend.getCurrentBeverageId() == RECIPE_ID_SPARKLING_WATER);
			assertFalse("Should not have called pour stop event", calledOnPourStop);
			assertTrue("Should have called pour start event", calledOnPourStart);

			testResetEvents();
			backend.startPourWater();
			assertTrue("Should be pouring tap water instead", backend.isPouringWater() && !backend.isPouringCup && !backend.isPouringBeverage());
			assertTrue("Should have called pour stop event", calledOnPourStop);
			assertTrue("Should have called pour start event", calledOnPourStart);

			testResetEvents();
			backend.stopPourWater();
			assertFalse("Should not be pouring anything", backend.isPouringAnything());
			assertTrue("Should have called pour stop event", calledOnPourStop);
			assertFalse("Should not have called pour start event", calledOnPourStart);

			testResetEvents();
			backend.stopPour();
			assertFalse("Should not be pouring anything", backend.isPouringAnything());
			assertFalse("Should not have called pour stop event", calledOnPourStop);
			assertFalse("Should not have called pour start event", calledOnPourStart);

			testResetEvents();
			backend.startPourWater();
			assertTrue("Should be pouring tap water only", backend.isPouringWater() && !backend.isPouringCup && !backend.isPouringBeverage());
			assertFalse("Should not have called pour stop event", calledOnPourStop);
			assertTrue("Should have called pour start event", calledOnPourStart);

			testResetEvents();
			backend.startPour();
			assertTrue("Should be pouring beverage only", !backend.isPouringWater() && !backend.isPouringCup && backend.isPouringBeverage() && backend.getCurrentBeverageId() == RECIPE_ID_SPARKLING_WATER);
			assertTrue("Should have called pour stop event", calledOnPourStop);
			assertTrue("Should have called pour start event", calledOnPourStart);

			testResetEvents();
			backend.stopPour();
			assertFalse("Should not be pouring anything", backend.isPouringAnything());
			assertTrue("Should have called pour stop event", calledOnPourStop);
			assertFalse("Should not have called pour start event", calledOnPourStart);

			testResetEvents();
			backend.stopPourWater();
			assertFalse("Should not be pouring anything", backend.isPouringAnything());
			assertFalse("Should not have called pour stop event", calledOnPourStop);
			assertFalse("Should not have called pour start event", calledOnPourStart);
		}

		public function testInOrder():void {
			// Test going in and out of order and event dispatching

			var outOfOrderMessage1:String = "OUT OF ORDER MESSAGE 1";
			var outOfOrderMessage2:String = "OUT OF ORDER MESSAGE 2";

			assertFalse("Is in order", backend.isOutOfOrder);

			testResetEvents();

			BackendModel.debug_injectOnOutOfOrder(outOfOrderMessage1);
			assertTrue("Is out of order", backend.isOutOfOrder);
			assertEquals("Out of order message", backend.outOfOrderMessage, outOfOrderMessage1);
			assertTrue("Dispatched out of order", calledOnOutOfOrder);
			assertFalse("Did not dispatch out of order update", calledOnOutOfOrderUpdate);
			assertFalse("Did not dispatch in order", calledOnInOrder);

			testResetEvents();

			BackendModel.debug_injectOnOutOfOrder(outOfOrderMessage2);
			assertTrue("Is out of order", backend.isOutOfOrder);
			assertEquals("Out of order message", backend.outOfOrderMessage, outOfOrderMessage2);
			assertFalse("Did not dispatch out of order", calledOnOutOfOrder);
			assertTrue("Dispatched out of order update", calledOnOutOfOrderUpdate);
			assertFalse("Did not dispatch in order", calledOnInOrder);

			testResetEvents();

			BackendModel.debug_injectOnInOrder();
			assertFalse("Is in order", backend.isOutOfOrder);
			assertFalse("Did not dispatch out of order", calledOnOutOfOrder);
			assertFalse("Did not dispatch out of order update", calledOnOutOfOrderUpdate);
			assertTrue("Dispatched in order", calledOnInOrder);

			testResetEvents();

			BackendModel.debug_injectOnInOrder();
			assertFalse("Is in order", backend.isOutOfOrder);
			assertFalse("Did not dispatch out of order", calledOnOutOfOrder);
			assertFalse("Did not dispatch out of order update", calledOnOutOfOrderUpdate);
			assertFalse("Did not dispatch in order", calledOnInOrder);
		}

		public function testRequestPinKeypad():void {
			testResetEvents();

			BackendModel.debug_injectOnRequestPinPad();
			assertTrue("Should have dispatched pin pad event", calledOnRequestPinKeypad);
		}

		// TODO: events to test
		/*
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
		public static const EVENT_CUP_POUR_COMPLETE							:String = "BackendModel.onCupPourComplete";
		public static const EVENT_LIGHT_COLOR_CHANGE						:String = "BackendModel.onLightColorChange";
		public static const EVENT_LIGHT_NOZZLE_BRIGHTNESS_CHANGE			:String = "BackendModel.onLightNozzleBrightnessChange";
		 */


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		override protected function setUp():void {
			super.setUp();

			BackendModel.init(new SimulatedBackendInterface(true));
			BackendModel.recipeAvailabilityDefault = true;
			BackendModel.immediateOnInOrderEvent = true;

			backend = new BackendModel();

			backend.addEventListener(BackendModel.EVENT_IS_OUT_OF_ORDER, testInOrderOnOutOfOrder);
			backend.addEventListener(BackendModel.EVENT_IS_OUT_OF_ORDER_UPDATE, testInOrderOnOutOfOrderUpdate);
			backend.addEventListener(BackendModel.EVENT_IS_IN_ORDER, testInOrderOnInOrder);
			backend.addEventListener(BackendModel.EVENT_STARTED_POURING, testPourOnPourStart);
			backend.addEventListener(BackendModel.EVENT_STOPPED_POURING, testPourOnPourStop);
			backend.addEventListener(BackendModel.EVENT_REQUEST_PIN_KEYPAD, testOnRequestPinKeypad);
		}

		override protected function tearDown():void {
			super.tearDown();

			backend.removeEventListener(BackendModel.EVENT_IS_OUT_OF_ORDER, testInOrderOnOutOfOrder);
			backend.removeEventListener(BackendModel.EVENT_IS_OUT_OF_ORDER_UPDATE, testInOrderOnOutOfOrderUpdate);
			backend.removeEventListener(BackendModel.EVENT_IS_IN_ORDER, testInOrderOnInOrder);
			backend.removeEventListener(BackendModel.EVENT_STARTED_POURING, testPourOnPourStart);
			backend.removeEventListener(BackendModel.EVENT_STOPPED_POURING, testPourOnPourStop);
			backend.removeEventListener(BackendModel.EVENT_REQUEST_PIN_KEYPAD, testOnRequestPinKeypad);

			backend = null;
		}

		// Event helpers

		private function testResetEvents():void {
			calledOnPourStart = false;
			calledOnPourStop = false;
			calledOnOutOfOrder = false;
			calledOnOutOfOrderUpdate = false;
			calledOnInOrder = false;
			calledOnRequestPinKeypad = false;
		}

		private function testPourOnPourStart(__e:Event):void {
			calledOnPourStart = true;
		}

		private function testPourOnPourStop(__e:Event):void {
			calledOnPourStop = true;
		}

		private function testInOrderOnOutOfOrder(__e:Event):void {
			calledOnOutOfOrder = true;
		}

		private function testInOrderOnOutOfOrderUpdate(__e:Event):void {
			calledOnOutOfOrderUpdate = true;
		}

		private function testInOrderOnInOrder(__e:Event):void {
			calledOnInOrder = true;
		}

		private function testOnRequestPinKeypad(__e:Event):void {
			calledOnRequestPinKeypad = true;
		}
	}
}
