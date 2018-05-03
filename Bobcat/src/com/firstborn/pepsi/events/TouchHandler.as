package com.firstborn.pepsi.events {
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
		}

		public function dettachFrom(__target:DisplayObject):void {
			// Stop capturing events from a display object
			__target.removeEventListener(TouchEvent.TOUCH, onTargetTouch);
			if (targets.indexOf(__target) > -1) targets.splice(targets.indexOf(__target), 1);
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
