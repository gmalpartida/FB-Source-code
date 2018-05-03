package com.firstborn.pepsi.display.gpu.brand.flavors {
	import starling.display.Sprite;

	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.common.backend.BackendModel;
	import com.firstborn.pepsi.data.inventory.Flavor;
	import com.zehfernando.signals.SimpleSignal;
	import com.zehfernando.transitions.Equations;
	import com.zehfernando.utils.MathUtils;
	import com.zehfernando.utils.RandomGenerator;

	import flash.geom.Point;

	/**
	 * @author zeh fernando
	 */
	public class FlavorSelector extends Sprite {

		// Constants
		public static const FOLLOW_FLAVOR_DEFINITIONS_ORDER:Boolean = true;									// If true, follow the orders imposed by flavors.xml; if false, follow the orders of each beverage's individual ids
		public static var currentLanguage : uint = 0;

		// Properties
		private var flavorIds:Vector.<String>;
		private var hiddenFlavorIds:Vector.<String>;
		private var selectedFlavorIds:Vector.<String>;
		private var selectedFlavorRecipeIds:Vector.<String>;
		private var maxFlavorsSelected:uint;
		private var _visibility:Number;
		protected var allowKeyboardFocus:Boolean;

		// Instances
		private var _onChangedSelection:SimpleSignal;
		private var simulatedButton:FlavorSelectorItem;
		protected var flavorItems:Vector.<FlavorSelectorItem>;
		private var orderedFlavorItems:Vector.<FlavorSelectorItem>;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function FlavorSelector(__flavorIds:Vector.<String>, __hiddenFlavorIds:Vector.<String>, __maxFlavorsSelected:uint, __allowKeyboardFocus:Boolean) {
			super();

			flavorIds = __flavorIds;
			hiddenFlavorIds = __hiddenFlavorIds;
			selectedFlavorIds = new Vector.<String>();
			selectedFlavorRecipeIds = new Vector.<String>();
			maxFlavorsSelected = __maxFlavorsSelected;
			allowKeyboardFocus = __allowKeyboardFocus;

			flavorItems = new Vector.<FlavorSelectorItem>();
			orderedFlavorItems = new Vector.<FlavorSelectorItem>();
			_onChangedSelection = new SimpleSignal();

			// Add all items
			var i:int;

			// Decides which order to use: the flavors.xml (definitions) order, or the brand's order
			// Only one should be used at any time, but since this is a requirement that kept changed twice already through the development,
			// it's easier to have it as a constant so it's easy to change it back the next time people change their minds or realize they
			// need something that they said they'd never need
			if (FOLLOW_FLAVOR_DEFINITIONS_ORDER) {
				// Add the flavors using the flavor definitions (flavors.xml) order
				var globalFlavors:Vector.<Flavor> = FountainFamily.inventory.getFlavors();
				for (i = 0; i < globalFlavors.length; i++) {
					if (flavorIds.indexOf(globalFlavors[i].id) > -1) {
						// This flavor definition was found on the list of flavors the beverage supports
						addItem(globalFlavors[i]);
					}
				}
			} else {
				// Add the flavors using the order inside the beverage data
				var validFlavors:Vector.<Flavor> = FountainFamily.inventory.getFlavorsById(flavorIds);
				for (i = 0; i < validFlavors.length; i++) {
					addItem(validFlavors[i]);
				}
			}

			updateSelectability(true);
			redraw();
			createOrderedList();
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function addItem(__flavor:Flavor):void {
			if (hiddenFlavorIds.indexOf(__flavor.id) < 0) {
				var item:FlavorSelectorItem = getFlavorSelectorItem(__flavor);
				addChild(item);
				item.onChangedSelectedState.add(onFlavorItemChangedSelectedState);
				flavorItems.push(item);
				orderedFlavorItems.push(item);
			}
		}

		private function removeItem(__flavorSelectorItem:FlavorSelectorItem):void {
			var idx:int = flavorItems.indexOf(__flavorSelectorItem);
			if (idx > -1) {
				flavorItems.splice(idx, 1);
				orderedFlavorItems.splice(orderedFlavorItems.indexOf(__flavorSelectorItem), 1);
				removeChild(__flavorSelectorItem);
				//__flavorSelectorItem.onChangedSelectedState.remove(onFlavorItemChangedSelectedState);
				__flavorSelectorItem.dispose(); // implies onChangedSelectedState.removeAll()
			}
		}

		private function updateSelectability(__immediate:Boolean = false):void {
			// Based on the number of items selected, enable or disable other items

			var targetSelectability:Boolean = selectedFlavorIds.length < maxFlavorsSelected;
			for (var i:int = 0; i < flavorItems.length; i++) {
				if (!flavorItems[i].isSelected && flavorItems[i].isEnabled != targetSelectability) {
					flavorItems[i].setEnabled(targetSelectability, __immediate);
				}
			}
		}

		private function setInternalFlavorIdSelectionState(__flavorId:String, __selected:Boolean):void {
			// Update the list of selected ids
			if (__selected) {
				// Selected
				if (selectedFlavorIds.indexOf(__flavorId) == -1) {
					// Not marked as selected yet, add
					selectedFlavorIds.push(__flavorId);
					selectedFlavorRecipeIds.push(FountainFamily.inventory.getFlavorById(__flavorId).recipeId);
					_onChangedSelection.dispatch();
					updateSelectability();
				}
			} else {
				// Not selected
				var idx:int = selectedFlavorIds.indexOf(__flavorId);
				if (idx > -1) {
					// Marked as selected, remove
					selectedFlavorIds.splice(idx, 1);
					selectedFlavorRecipeIds.splice(idx, 1);
					_onChangedSelection.dispatch();
					updateSelectability();
				}
			}
		}
		private function createOrderedList():void {
			// Create a list of ordered items for ADA control by re-shuffling the ordered list
			orderedFlavorItems.sort(flavorItemSortFunction);
		}

		private function flavorItemSortFunction(__item1:FlavorSelectorItem, __item2:FlavorSelectorItem):int {
			// Test row first
			if (__item1.y < __item2.y) return -1;
			if (__item1.y > __item2.y) return 1;
			// Same y, test column
			if (__item1.x < __item2.x) return -1;
			if (__item1.x > __item2.x) return 1;
			// Same position
			return 0;
		}

		protected function getFlavorSelectorItem(__flavor:Flavor):FlavorSelectorItem {
			// Extend
			return null;
		}

		protected function redraw():void {
			// Extend!
		}

		protected function redrawVisibility():void {
			// Animate in sequence
			var f:Number = 0.8; // Slice of the total animation dedicated to each item
			var offset:Number;

			for (var i:int = 0; i < flavorItems.length; i++) {
				offset = flavorItems.length > 1 ? (1-f) * (i/(flavorItems.length-1)) : 0;
				flavorItems[i].visibility = Equations.expoOut(MathUtils.map(_visibility, 0+offset, 0+offset+f, 0, 1, true));
			}
		}

//		public function show(__delay:Number, __time:Number):void {
//			var dtime:Number = 0.1;
//			var ttime:Number = __time - (dtime * flavorItems.length);
//
//			var stime:Number = __delay;
//			for (var i:int = 0; i < flavorItems.length; i++) {
//				ZTween.remove(flavorItems[i], "visibility");
//				ZTween.add(flavorItems[i], {visibility:1}, {delay:stime, time:ttime});
//				stime += dtime;
//			}
//		}
//
//		public function hide(__delay:Number, __time:Number):void {
//			var dtime:Number = 0.1;
//			var ttime:Number = __time - (dtime * flavorItems.length);
//
//			var stime:Number = __delay;
//			for (var i:int = flavorItems.length-1; i >= 0; i--) {
//				ZTween.remove(flavorItems[i], "visibility");
//				ZTween.add(flavorItems[i], {visibility:0}, {delay:stime, time:ttime});
//				stime += dtime;
//			}
//		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		private function onFlavorItemChangedSelectedState(__flavorItem:FlavorSelectorItem):void {
			setInternalFlavorIdSelectionState(__flavorItem.flavorId, __flavorItem.isSelected);
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function updateFlavorAvailability(__backendModel:BackendModel):void {
			// Update the vailability of flavor buttons based on its recipe availability
			for (var i:int = 0; i < flavorItems.length; i++) {
				flavorItems[i].available = __backendModel.getRecipeAvailability(flavorItems[i].flavorRecipeId) ? 1 : 0;
			}
		}

		public function selectItemsById(__ids:Vector.<String>, __immediate:Boolean = false):void {
			// Set the currently selected items, deselecting items if necessary

			var i:int;

			// Select/deselect all items depending on whether they're in the list or not
			for (i = 0; i < flavorItems.length; i++) {
				flavorItems[i].setSelected(__ids.indexOf(flavorItems[i].flavorId) >= 0, __immediate);
			}

			// Select hidden flavors
			for (i = 0; i < hiddenFlavorIds.length; i++) {
				setInternalFlavorIdSelectionState(hiddenFlavorIds[i], __ids.indexOf(hiddenFlavorIds[i]) >= 0);
			}
		}

		public function lockItemsById(__ids:Vector.<String>, __immediate:Boolean = false):void {
			// Lock items automatically
			// "immediate" is not applied, but is present in case there's animation for locking/unlocking in the future
			for (var i:int = 0; i < flavorItems.length; i++) {
				flavorItems[i].isLocked = __ids.indexOf(flavorItems[i].flavorId) >= 0;
			}
		}

		public function simulatePickButton():void {
			// Decide a button to pick for simulated events
			simulatedButton = flavorItems[RandomGenerator.getInIntegerRange(0, flavorItems.length-1)];
		}

		public function simulateEnterDown():void {
			if (simulatedButton != null) simulatedButton.simulateEnterDown();
		}

		public function simulateEnterUp():void {
			if (simulatedButton != null) simulatedButton.simulateEnterUp();
		}

		public function getSimulatedButtonX():Number {
			if (simulatedButton == null) return 0;
			return x + simulatedButton.x + simulatedButton.width * 0.5;
		}

		public function getSimulatedButtonY():Number {
			if (simulatedButton == null) return 0;
			return y + simulatedButton.y + simulatedButton.height * 0.5;
		}

		override public function dispose():void {
			_onChangedSelection.removeAll();
			_onChangedSelection = null;

			while (flavorItems.length > 0) removeItem(flavorItems[0]);

			flavorIds = null;
			selectedFlavorIds = null;
			selectedFlavorRecipeIds = null;
			orderedFlavorItems = null;
			simulatedButton = null;

			super.dispose();
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		//External Interface
		public function set language(value : uint) : void {
			currentLanguage = value;
			for(var i: uint = 0; i < flavorItems.length; i ++) {
				flavorItems[i].language = value;
			}
		}

		public function getSelectedFlavors():Vector.<String> {
			return selectedFlavorIds.concat();
		}

		public function getSelectedFlavorRecipeIds():Vector.<String> {
			return selectedFlavorRecipeIds.concat();
		}

		public function getOrderedItems():Vector.<FlavorSelectorItem> {
			return orderedFlavorItems.concat();
		}

		public function get onChangedSelection():SimpleSignal {
			return _onChangedSelection;
		}

		public function getPositionOfItem(__item:int):Point {
			return new Point(flavorItems[__item].x + 100, flavorItems[__item].y + flavorItems[__item].height * 0.5 + y);
		}

		public function getNumItems():int {
			return flavorItems.length;
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
	}
}
