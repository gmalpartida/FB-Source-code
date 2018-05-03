package com.firstborn.pepsi.data {
	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.common.backend.BackendModel;
	import com.zehfernando.signals.SimpleSignal;
	import com.zehfernando.utils.getTimerUInt;

	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	/**
	 * @author zeh fernando
	 */
	public class AttractorController {

		// Properties
		private var _lastInteractionTime:Number;								// In seconds
		private var _currentMaximumIdleTime:Number;								// In seconds
		private var _currentMaximumIdleTimeAfterUserInput:Number;				// In seconds
		private var _hadFirstUserInput:Boolean;									// Had any user input since last changing the delay tine?
		private var _hasUserInteractedYet:Boolean;								// Has the user interacted since coming out of idle state?
		private var _hasUserBrokenIdleState:Boolean;
		private var _isPaused:Boolean;
		private var _isInIdleState:Boolean;

		// Instances
		private var _onIdleTimePassed:SimpleSignal;
		private var _onCameBackFromIdle:SimpleSignal;
		private var _onUserInteracted:SimpleSignal;

		private var backendModel:BackendModel;
		private var stage:Stage;

		private var _canGoBackFromIdleState:Boolean;
		private var _canGoToIdleState:Boolean;

        private var _holdForPayment : Boolean = false;
        private var _thanksStatus : Boolean = false;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function AttractorController(__backendModel:BackendModel, __stage:Stage) {
			backendModel = __backendModel;
			stage = __stage;

			resetLastInteractionTime();
			_currentMaximumIdleTime = 0;
			_isPaused = false;
			_isInIdleState = false;
			_hadFirstUserInput = false;
			_hasUserInteractedYet = false;
			_hasUserBrokenIdleState = false;

			_canGoBackFromIdleState = false;
			_canGoToIdleState = false;

			_onIdleTimePassed = new SimpleSignal();
			_onCameBackFromIdle = new SimpleSignal();
			_onUserInteracted = new SimpleSignal();

            _thanksStatus = false;

			if (!FountainFamily.DEBUG_IDLE_STATE_IGNORES_INPUT) {
				stage.addEventListener(MouseEvent.MOUSE_DOWN, onAnyUserInteraction);
				stage.addEventListener(MouseEvent.MOUSE_UP, onAnyUserInteraction);
				stage.addEventListener(MouseEvent.MOUSE_MOVE, onAnyUserInteraction);
				stage.addEventListener(MouseEvent.MOUSE_WHEEL, onAnyUserInteraction);
				stage.addEventListener(KeyboardEvent.KEY_DOWN, onAnyUserInteraction);
				stage.addEventListener(KeyboardEvent.KEY_UP, onAnyUserInteraction);
			}

            if(FountainFamily.PAYMENT_ENABLED) {
                backendModel.addEventListener(BackendModel.EVENT_PAYMENT_AUTHORIZE, onPaymentAuthorize);
                backendModel.addEventListener(BackendModel.EVENT_PAYMENT_POUR_COMPLETE, onPaymentPourComplete);
            }

			stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function resetLastInteractionTime():void {
			_lastInteractionTime = getTimerUInt() / 1000;
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

        private function onPaymentAuthorize(__e:Event) :  void {
            _holdForPayment = true;
            onAnyUserInteraction(null);
        }

        private function onPaymentPourComplete(__e:Event) :  void {
            _holdForPayment = false;
            _thanksStatus = true;
            resetLastInteractionTime();
            onAnyUserInteraction(null);
        }

		private function onEnterFrame(__e:Event):void {
			//log ("checking...",_isInIdleState,_currentMaximumIdleTime, __currentTimeSeconds, _lastInteractionTime);
			if (!_isInIdleState && _canGoToIdleState && !backendModel.isOutOfOrder && !backendModel.isPouringAnything() && !_holdForPayment) {
				var timeDelay:Number = _hadFirstUserInput ? _currentMaximumIdleTimeAfterUserInput : _currentMaximumIdleTime;
				if (timeDelay > 0 && (getTimerUInt()/1000) > _lastInteractionTime + timeDelay) {
					// Dispatch
					//info("Maximum idle time passed, should start attractor loop");
					goToIdleState();
				}
			}

			if (backendModel.isOutOfOrder) {
				onAnyUserInteraction(null);
			}
		}

		private function onAnyUserInteraction(__e:Event):void {


            //log("User interacted ", _isInIdleState, _canGoBackFromIdleState);
            _onUserInteracted.dispatch();
            if(!_thanksStatus) resetLastInteractionTime();
            if (_isInIdleState) {
                if (_canGoBackFromIdleState) {
                    //info("User interacted, should go back from attractor loop");
                    _isInIdleState = false;
                    _thanksStatus = false;
                    _hasUserBrokenIdleState = true;
                    _onCameBackFromIdle.dispatch(true);
                }
            } else {
                if (!_hadFirstUserInput) _hadFirstUserInput = true;
                if (!_hasUserInteractedYet) _hasUserInteractedYet = true;
            }
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function goToIdleState():void {
			// Forces idle state
			if (!_isInIdleState && _canGoToIdleState) {
				_onIdleTimePassed.dispatch();
				_isInIdleState = true;
				_hadFirstUserInput = false;
				_hasUserInteractedYet = false;
				_hasUserBrokenIdleState = false;
				_canGoBackFromIdleState = false;
                _thanksStatus = false;
			}
		}

		public function leaveIdleState():void {
			// Forces closing idle state
			if (_isInIdleState && _canGoBackFromIdleState) {
				_isInIdleState = false;
                _thanksStatus = false;
				_canGoToIdleState = false;
				_onCameBackFromIdle.dispatch(false);
			}
		}

		public function startWaitingForUserInteraction():void {
			if(!_thanksStatus) resetLastInteractionTime();
			_canGoBackFromIdleState = true;
		}

		public function startWaitingForInactiveState(__firstTime:Boolean = false):void {
            if(!_thanksStatus) resetLastInteractionTime();
			if (__firstTime) {
				_hadFirstUserInput = true;
				_hasUserInteractedYet = true;
			}
			_canGoToIdleState = true;
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function get onIdleTimePassed():SimpleSignal {
			return _onIdleTimePassed;
		}

		public function get onCameBackFromIdle():SimpleSignal {
			return _onCameBackFromIdle;
		}

		public function get onUserInteracted():SimpleSignal {
			return _onUserInteracted;
		}

		public function set delayTime(__value:Number):void {
			//warn("delay =>>>>>>>>>>>>>>>>>" + __value);
			_hadFirstUserInput = false;
			_currentMaximumIdleTime = __value;
			delayTimeAfterUserInput = __value;
			//looper.updateOnce(update);
		}

		public function set delayTimeAfterUserInput(__value:Number):void {
			//warn("delay AFTER =>>>>>>>>>>>>>>>>>" + __value);
			_currentMaximumIdleTimeAfterUserInput = __value;
		}

		/*
		public function get hasUserBrokenIdleState():Boolean {
			return _hasUserBrokenIdleState;
		}
		*/

		public function get hasUserInteractedYet():Boolean {
			return _hasUserInteractedYet;
		}

		public function get isInIdleState():Boolean {
			return _isInIdleState;
		}
	}
}
