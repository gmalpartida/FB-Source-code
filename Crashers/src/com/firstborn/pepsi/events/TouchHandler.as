package com.firstborn.pepsi.events {
import com.firstborn.pepsi.display.gpu.brand.flavors.FlavorSelectorItem;
import com.firstborn.pepsi.display.gpu.brand.flavors.vertical.FlavorSelectorVerticalItem;
import com.firstborn.pepsi.display.gpu.common.components.BlobButton;
import com.firstborn.pepsi.display.gpu.home.menu.BlobSpritesInfo;
import com.zehfernando.display.starling.AnimatedImage;

import starling.display.DisplayObject;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;

	import com.zehfernando.signals.SimpleSignal;
	import com.zehfernando.utils.console.warn;

	import flash.geom.Point;
	/**
	 * @author zeh fernando
	 */
	public class TouchHandler {

		// Easy handler for touch events

		// Properties
		private var isPressed:Boolean;
		private var pressedId:int;							// Touch id that pressed

		// Instances
		private var _onTap:SimpleSignal;
		private var _onPress:SimpleSignal;
		private var _onRelease:SimpleSignal;
		private var _onPressCancel:SimpleSignal;			// Dragged out

		private var lastTouchPoint:Point;
		private var tempTouchPoint:Point;
		private var targets:Vector.<DisplayObject>;

		public var handleTouchIdShuffling:Boolean;			// If true, try to prevent touch id shuffling (when a second touch is added, and the first touch has its id changed)

        private static var _targets : Vector.<DisplayObject> = new Vector.<DisplayObject>();
        private static var signals : Array = new Array();


        //============================================== Hack to test the remote controlling of the machine
        public static function searchTouchObject(_x : Number, __y : Number, touchCase : String) : void {

            //For the Bridge case. The Masthead substract 740 pixels from the top.
            var _y : Number = __y - 740;

            switch(touchCase) {

                case "CLICK":
                    for(var i : uint = 0; i < _targets.length; i ++) {

                        if(_targets[i] is BlobButton && _targets[i].visible && _targets[i].hitTest(_targets[i].globalToLocal(new Point(_x, _y)))) {
                            BlobButton(_targets[i]).onReleased.dispatch(_targets[i]);
                            BlobButton(_targets[i]).onTapped.dispatch(_targets[i]);
                        }

                        if(_targets[i] is AnimatedImage && _targets[i].hitTest(_targets[i].globalToLocal(new Point(_x, _y))) && _targets[i].visible) BlobSpritesInfo(AnimatedImage(_targets[i]).uiContainer).onTapped.dispatch(BlobSpritesInfo(AnimatedImage(_targets[i]).uiContainer));

                        if(_targets[i] is FlavorSelectorItem && _targets[i].visible && _targets[i].hitTest(_targets[i].globalToLocal(new Point(_x, _y)))) FlavorSelectorItem(_targets[i]).onTapped();

                    }
                    break;


                case "DOWN":
                    for(i = 0; i < _targets.length; i ++) if(_targets[i] is BlobButton && _targets[i].visible && _targets[i].hitTest(_targets[i].globalToLocal(new Point(_x, _y)))) BlobButton(_targets[i]).onPressed.dispatch(_targets[i]);
                    break;
            }

        }


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function TouchHandler() {
			//handleTouchIdShuffling = true;
			_onTap = new SimpleSignal();
			_onPress = new SimpleSignal();
			_onRelease = new SimpleSignal();
			_onPressCancel = new SimpleSignal();
			targets = new Vector.<DisplayObject>();
			lastTouchPoint = new Point();
			tempTouchPoint = new Point();
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function processTouches(__touches:Vector.<Touch>, __target:DisplayObject):void {
			var i:int;
			if (handleTouchIdShuffling && isPressed && __touches.length > 1) {
				// Find the correct touch id that is pressing, by finding the point closest to the last touch
				// This is necessary because sometimes the touch seem to be swapped?
				var minDistance:Number = NaN;
				var minTouchId:int = -1;
				var distance:Number;
				for (i = 0; i < __touches.length; i++) {
					distance = Point.distance(lastTouchPoint, new Point(__touches[i].globalX, __touches[i].globalY));
					if (isNaN(minDistance) || distance < minDistance) {
						minDistance = distance;
						minTouchId = i;
					}
				}
				if (pressedId != minTouchId) warn("Switching pressed touch id from " + pressedId + " to " + minTouchId);
				pressedId = minTouchId;
			}
			for (i = 0; i < __touches.length; i++) {
				// Process all touches
				processTouch(__touches[i], __target);
			}
		}

		private function processTouch(__touch:Touch, __target:DisplayObject):void {
			switch (__touch.phase) {
				case TouchPhase.HOVER:
					break;
				case TouchPhase.BEGAN:
					// Pointer down
					if (!isPressed) {
						isPressed = true;
						pressedId = __touch.id;
						lastTouchPoint.setTo(__touch.globalX, __touch.globalY);
						_onPress.dispatch();
					}
					break;
				case TouchPhase.MOVED:
					// Pointer moved
					if (isPressed && __touch.id == pressedId) {
						lastTouchPoint.setTo(__touch.globalX, __touch.globalY);
						__target.globalToLocal(lastTouchPoint, tempTouchPoint);
						if (__target.hitTest(tempTouchPoint, true) == null) {
							// Pointer out
							isPressed = false;
							_onPressCancel.dispatch();
						}
					}
					break;
				case TouchPhase.ENDED:
					// Pointer up
					if (isPressed && __touch.id == pressedId) {
						lastTouchPoint.setTo(__touch.globalX, __touch.globalY);
						isPressed = false;
						_onRelease.dispatch();
						_onTap.dispatch();
					}
					break;
				case TouchPhase.STATIONARY:
					break;
			}
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		private function onTargetTouch(__e:TouchEvent):void {
			processTouches(__e.touches, __e.currentTarget as DisplayObject);
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function attachTo(__target:DisplayObject):void {
			// Start capturing all events from a display object
			__target.addEventListener(TouchEvent.TOUCH, onTargetTouch);
			targets.push(__target);

            //For all the targets controlled in this class
            _targets.push(__target);

            //Use the target as the corresponding key to get the signal
            signals[__target] = _onTap;
		}

		public function dettachFrom(__target:DisplayObject):void {
			// Stop capturing events from a display object
			__target.removeEventListener(TouchEvent.TOUCH, onTargetTouch);
			if (targets.indexOf(__target) > -1) targets.splice(targets.indexOf(__target), 1);

            //For all the targets controlled with this class
			if (_targets.indexOf(__target) > -1) _targets.splice(_targets.indexOf(__target), 1);

            signals[__target] = null;
		}

		public function dispose():void {
			while (targets.length > 0) dettachFrom(targets[0]);
			_onTap.removeAll();
			_onPress.removeAll();
			_onRelease.removeAll();
			_onPressCancel.removeAll();
		}

		public function getLastTouchPoint():Point {
			return lastTouchPoint.clone();
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function get onTapped():SimpleSignal {
			return _onTap;
		}

		public function get onPressed():SimpleSignal {
			return _onPress;
		}

		public function get onReleased():SimpleSignal {
			return _onRelease;
		}

		public function get onPressCanceled():SimpleSignal {
			return _onPressCancel;
		}
	}
}
