package com.firstborn.pepsi.display.gpu.brand.flavors {
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;

	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.data.inventory.Flavor;
	import com.firstborn.pepsi.events.TouchHandler;
	import com.zehfernando.controllers.focus.FocusController;
	import com.zehfernando.controllers.focus.IFocusable;
	import com.zehfernando.localization.StringList;
	import com.zehfernando.signals.SimpleSignal;
	import com.zehfernando.transitions.Equations;
	import com.zehfernando.transitions.ZTween;

	import flash.geom.Rectangle;

	/**
	 * @author zeh fernando
	 */
	public class FlavorSelectorItem extends Sprite implements IFocusable {

		// Constants
		protected static const TIME_STATE_ANIMATION:Number = 0.25;

		// Properties

		public static var currentLanguage : uint = 0;

		private var _isEnabled:Boolean;
		private var _isSelected:Boolean;
		private var _isLocked:Boolean;
		protected var _enabledPhase:Number;
		protected var _selectedPhase:Number;
		protected var _pressedPhase:Number;
		protected var _available:Number;
		protected var _visibility:Number;
		protected var _scale:Number;
		private var _keyboardFocused:Number;
		private var _wasClickSimulated:Boolean;

		// Instances
		protected var flavor:Flavor;
		private var _onChangedSelectedState:SimpleSignal;
		private var touchHandler:TouchHandler;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function FlavorSelectorItem(__flavor:Flavor) {
			_isEnabled = true;
			_isSelected = false;
			_isLocked = false;
			_available = 1;
			_enabledPhase = 1;
			_selectedPhase = 0;
			_pressedPhase = 0;
			_visibility = 0;
			_keyboardFocused = 0;
			_wasClickSimulated = false;
			_scale = 1;
			flavor = __flavor;
			_onChangedSelectedState = new SimpleSignal();

			touchHandler = new TouchHandler();
			touchHandler.attachTo(this);
			touchHandler.onPressed.add(onPressed);
			touchHandler.onReleased.add(onReleased);
			touchHandler.onPressCanceled.add(onPressCanceled);
			touchHandler.onTapped.add(onTapped);

			redrawFocused();

			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		protected function redrawAvailable():void {
			// Extend!
		}

		protected function redrawEnabledPhase():void {
			// Extend!
		}

		protected function redrawSelectedPhase():void {
			// Extend!
		}

		protected function redrawPressedPhase():void {
			// Extend!
		}

		protected function redrawVisibility():void {
			// Extend!
		}

//		protected function redrawScale():void {
//			// Extend!
//		}

		protected function redrawFocused():void {
			// Extend!
		}

		protected function animatedSelectedChanged():void {
			// Extend!
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		private function onAddedToStage(__e:Event):void {
			redrawEnabledPhase();
			redrawSelectedPhase();
			redrawVisibility();
//			redrawScale();
		}

		private function onTapped():void {
			if (!_isLocked && _isEnabled && _available == 1) {
				if (_isSelected) {
					FountainFamily.backendModel.trackButtonPressed(StringList.getList(FountainFamily.current_language).getString("tracking/brand-button-deselect-flavor").split("[[flavor]]").join(flavorId));
				} else {
					FountainFamily.backendModel.trackButtonPressed(StringList.getList(FountainFamily.current_language).getString("tracking/brand-button-select-flavor").split("[[flavor]]").join(flavorId));
				}
				setSelected(!_isSelected, false);
			}
		}

		private function onPressed():void {
			if (!_isLocked && _available == 1) {
				ZTween.remove(this, "pressedPhase");
				ZTween.add(this, {pressedPhase:1}, {time:TIME_STATE_ANIMATION, transition:Equations.quintOut});
				if (!_wasClickSimulated) FountainFamily.focusController.executeCommand(FocusController.COMMAND_DEACTIVATE);
			}
		}

		private function onReleased():void {
			if (!_isLocked) {
				ZTween.remove(this, "pressedPhase");
				ZTween.add(this, {pressedPhase:0}, {time:TIME_STATE_ANIMATION, transition:Equations.quintOut});
			}
		}

		private function onPressCanceled():void {
			if (!_isLocked) {
				ZTween.remove(this, "pressedPhase");
				ZTween.add(this, {pressedPhase:0}, {time:TIME_STATE_ANIMATION, transition:Equations.quintOut});
			}
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function setEnabled(__enabled:Boolean, __immediate:Boolean):void {
			if (_isEnabled != __enabled) {
				_isEnabled = __enabled;

				ZTween.remove(this, "enabledPhase");

				var targetEnabledPhase:Number = _isEnabled ? 1 : 0;
				if (__immediate) {
					enabledPhase = targetEnabledPhase;
				} else {
					ZTween.add(this, {enabledPhase:targetEnabledPhase}, {time:TIME_STATE_ANIMATION});
				}
			}
		}

		public function setSelected(__selected:Boolean, __immediate:Boolean):void {
			if (_isSelected != __selected) {
				_isSelected = __selected;

				animatedSelectedChanged();

				ZTween.remove(this, "selectedPhase");

				var targetSelectedPhase:Number = _isSelected ? 1 : 0;
				if (__immediate) {
					selectedPhase = targetSelectedPhase;
				} else {
					ZTween.add(this, {selectedPhase:targetSelectedPhase}, {time:TIME_STATE_ANIMATION * 2, transition:Equations.quartInOut});
				}

				_onChangedSelectedState.dispatch(this);
			}
		}

		public function setFocused(__isFocused:Boolean, __immediate:Boolean = false):void {
			ZTween.remove(this, "keyboardFocused");
			if (__immediate) {
				keyboardFocused = __isFocused ? 1 : 0;
			} else {
				ZTween.add(this, {keyboardFocused:__isFocused ? 1 : 0}, {time:FountainFamily.adaInfo.hardwareFocusTimeAnimate});
			}
		}

		public function getVisualBounds():Rectangle {
			return getBounds(Starling.current.stage);
		}

		public function canReceiveFocus():Boolean {
			return _enabledPhase == 1 && _available == 1;
		}

		public function simulateEnterDown():void {
			_wasClickSimulated = true;
			onPressed();
		}

		public function simulateEnterUp():void {
			onReleased();
			onTapped();
		}

		public function simulateEnterCancel():void {
			_wasClickSimulated = false;
			onReleased();
		}

		public function wasClickSimulated():Boolean {
			return _wasClickSimulated;
		}

		override public function dispose():void {
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			flavor = null;

			_onChangedSelectedState.removeAll();
			_onChangedSelectedState = null;

			ZTween.remove(this);

			touchHandler.dettachFrom(this);
			touchHandler.dispose();
			touchHandler = null;

			super.dispose();
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function set language(value : uint) : void {
			currentLanguage = value;
		}

		public function get available():Number {
			return _available;
		}
		public function set available(__value:Number):void {
			if (_available != __value) {
				_available = __value;
				redrawAvailable();
				if (_available != 1 && _isSelected) {
					// De-selected if it becomes unavailable while selected
					setSelected(false, false);
				}
			}
		}

		public function get enabledPhase():Number {
			return _enabledPhase;
		}
		public function set enabledPhase(__value:Number):void {
			if (_enabledPhase != __value) {
				_enabledPhase = __value;
				redrawEnabledPhase();
			}
		}

		public function get selectedPhase():Number {
			return _selectedPhase;
		}
		public function set selectedPhase(__value:Number):void {
			if (_selectedPhase != __value) {
				_selectedPhase = __value;
				redrawSelectedPhase();
			}
		}

		public function get pressedPhase():Number {
			return _pressedPhase;
		}
		public function set pressedPhase(__value:Number):void {
			if (_pressedPhase != __value) {
				_pressedPhase = __value;
				redrawPressedPhase();
			}
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

		public function get onChangedSelectedState():SimpleSignal {
			return _onChangedSelectedState;
		}

		public function get isSelected():Boolean {
			return _isSelected;
		}

		public function get flavorId():String {
			return flavor == null ? "?" : flavor.id; // Sometimes needed for auto testing
		}

		public function get flavorRecipeId():String {
			return flavor.recipeId;
		}

		public function get isEnabled():Boolean {
			return _isEnabled;
		}

		public function get isLocked():Boolean {
			return _isLocked;
		}

		public function set isLocked(__isLocked:Boolean):void {
			_isLocked = __isLocked;
		}

//		public function get scale():Number {
//			return _scale;
//		}
//		public function set scale(__value:Number):void {
//			if (_scale != __value) {
//				_scale = __value;
//				redrawScale();
//			}
//		}

		public function get keyboardFocused():Number {
			return _keyboardFocused;
		}
		public function set keyboardFocused(__value:Number):void {
			if (_keyboardFocused != __value) {
				_keyboardFocused = __value;
				redrawFocused();
			}
		}
	}
}
