package com.firstborn.pepsi.common.display.pad {
import com.firstborn.pepsi.application.FountainFamily;
import com.firstborn.pepsi.common.backend.BackendModel;
	import com.firstborn.pepsi.common.backend.BackendPinAction;
import com.firstborn.pepsi.tester.FountainFamilyTest;
import com.zehfernando.display.abstracts.ResizableSprite;
	import com.zehfernando.display.components.text.TextSprite;
	import com.zehfernando.display.components.text.TextSpriteAlign;
	import com.zehfernando.display.shapes.Box;
	import com.zehfernando.localization.StringList;
	import com.zehfernando.transitions.ZTween;
	import com.zehfernando.utils.DelayedCalls;
	import com.zehfernando.utils.MathUtils;
	import com.zehfernando.utils.console.warn;

	import flash.display.BlendMode;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;

	/**
	 * @author zeh fernando
	 */
	public class PadOverlay extends ResizableSprite {

		// Event enums
		public static const EVENT_SHOWN:String = "onShown";
		public static const EVENT_HIDDEN:String = "onHidden";

		// Constants
		private static const LINE_HEIGHT:Number = 1;
		private static const BUTTON_WIDTH:Number = 122;
		private static const BUTTON_HEIGHT:Number = 74;
		private static const BUTTON_MARGIN:Number = 12;
		private static const PAD_MARGIN:Number = 30;		// For close hit area
		private static const DIGITS:int = 4;

		// Properties
		private var padWidth:Number;
		private var padHeight:Number;
		private var _visibility:Number;
		private var _actionsVisibility:Number;
		private var currentEntry:String;
		private var densityScale:Number;
		private var fontScale:Number;
		private var fontBold:String;
		private var fontMedium:String;

		private var _isVisible:Boolean;

		// Instances
		private var cover:Box;
		private var errorMessage:TextSprite;

		private var padContainer:Sprite;
		private var buttonsContainer:Sprite;
		private var actionButtonsContainer:Sprite;
		private var digitBoxes:Vector.<DigitBox>;
		private var numberButtons:Vector.<NumberButton>;
		private var actionButtons:Vector.<ActionButton>;

		private var backendModel:BackendModel;

		private var topMessage : TextSprite;
		private var bottomMessage : TextSprite

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function PadOverlay(__backendModel:BackendModel, __densityScale:Number, __fontScale:Number, __fontBold:String, __fontMedium:String) {
			super();

			densityScale = __densityScale;
			fontScale = __fontScale;
			backendModel = __backendModel;
			fontBold = __fontBold;
			fontMedium = __fontMedium;

			_visibility = 0;
			_actionsVisibility = 0;
			padWidth = Math.round(BUTTON_WIDTH * densityScale) * 3 + getButtonMargin() * 2;
			padHeight = 0;
			currentEntry = "";
			_isVisible = false;

			// Create assets
			var i:int;

			// Cover
			cover = new Box(100, 100, 0x000000);
			cover.alpha = 0.9;
			cover.addEventListener(MouseEvent.CLICK, onClickCover);
			addChild(cover);

			// Container
			padContainer = new Sprite();
			addChild(padContainer);

			// Background
			var background:Box = new Box(padWidth + getPadMargin() * 2, 100);
			background.x = -getPadMargin();
			background.y = -getPadMargin();
			background.alpha = 0;
			padContainer.addChild(background);

			// Buttons
			buttonsContainer = new Sprite();
			padContainer.addChild(buttonsContainer);

			actionButtonsContainer = new Sprite();
			padContainer.addChild(actionButtonsContainer);

			// Message
			errorMessage = new TextSprite(fontBold, 16 * fontScale, 0xcc0000);
			errorMessage.width = padWidth;
			errorMessage.align = TextSpriteAlign.LEFT;
			errorMessage.blockAlignHorizontal = TextSpriteAlign.LEFT;
			errorMessage.blockAlignVertical = TextSpriteAlign.MIDDLE;
			errorMessage.y = padHeight + 27 * fontScale;
			padContainer.addChild(errorMessage);

			padHeight += 54 * fontScale;

			// Line
			var line:Box = new Box(padWidth, getLineHeight(), 0x4b4b4b);
			line.y = padHeight;
			line.alpha = 0.95;
			padContainer.addChild(line);

			padHeight += line.height;

			// Title
			padHeight += 22 * fontScale;

			topMessage = new TextSprite(fontBold, 28 * fontScale, 0xffffff);
			topMessage.text = StringList.getList(FountainFamily.current_language).getString("services/pad/title");
			topMessage.width = padWidth;
			topMessage.align = TextSpriteAlign.LEFT;
			topMessage.blockAlignHorizontal = TextSpriteAlign.LEFT;
			topMessage.blockAlignVertical = TextSpriteAlign.TOP;
			topMessage.y = padHeight;
			buttonsContainer.addChild(topMessage);

			padHeight += topMessage.height;
			padHeight += 22 * fontScale;

			// Digit boxes
			var boxSize:Number = Math.round((padWidth - ((DIGITS-1) * getButtonMargin())) / DIGITS);
			var db:DigitBox;
			digitBoxes = new Vector.<DigitBox>();
			for (i = 0; i < DIGITS; i++) {
				db = new DigitBox(densityScale, fontScale);
				db.width = db.height = boxSize;
				db.x = Math.round(MathUtils.map(i, 0, DIGITS-1, 0, padWidth - boxSize));
				db.y = Math.round(padHeight);
				digitBoxes.push(db);
				buttonsContainer.addChild(db);
			}
			padHeight += boxSize;
			padHeight += getButtonMargin();

			// Number buttons
			numberButtons = new Vector.<NumberButton>();
			createButtons(padHeight, "1", "2", "3");
			padHeight += getButtonHeight() + getButtonMargin();
			createButtons(padHeight, "4", "5", "6");
			padHeight += getButtonHeight() + getButtonMargin();
			createButtons(padHeight, "7", "8", "9");
			padHeight += getButtonHeight() + getButtonMargin();
			createButtons(padHeight, null, "0", NumberButton.CHARACTER_BACKSPACE);
			padHeight += getButtonHeight() + getButtonMargin();

			// Additional message
			padHeight += 22 * fontScale;

			bottomMessage = new TextSprite(fontMedium, 14 * fontScale, 0x949391);
			bottomMessage.alpha = 0.9;
			bottomMessage.text = StringList.getList(FountainFamily.current_language).getString("services/pad/message-bottom");
			bottomMessage.width = padWidth;
			bottomMessage.align = TextSpriteAlign.CENTER;
			bottomMessage.blockAlignHorizontal = TextSpriteAlign.LEFT;
			bottomMessage.blockAlignVertical = TextSpriteAlign.TOP;
			bottomMessage.y = padHeight;
			padContainer.addChild(bottomMessage);

			padHeight += bottomMessage.height;
			padHeight += 22 * fontScale;

			// Line
			line = new Box(padWidth, getLineHeight(), 0x4b4b4b);
			line.y = padHeight;
			line.alpha = 0.95;
			padContainer.addChild(line);

			padHeight += line.height;

			// End
			background.height = padHeight + getPadMargin() * 2;

			redrawVisibility();
			redrawActionsVisibility();
			redrawDigitBoxes();
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		override protected function redrawWidth():void {
			cover.width = _width;
			padContainer.x = Math.round(0.5 * (_width - padWidth));
		}

		override protected function redrawHeight():void {
			cover.height = _height;

			padContainer.y = Math.round(0.7 * (_height - padHeight));
		}

		private function redrawVisibility():void {
			blendMode = _visibility < 1 ? BlendMode.LAYER : BlendMode.NORMAL;
			alpha = _visibility;
			visible = _visibility > 0;
		}

		private function redrawActionsVisibility():void {
			var blackTint:Number = MathUtils.map(_actionsVisibility, 0, 1, 0, 0.85);
			buttonsContainer.transform.colorTransform = new ColorTransform(1-blackTint, 1-blackTint, 1-blackTint, 1);
			buttonsContainer.mouseEnabled = buttonsContainer.mouseChildren = _actionsVisibility == 0;
			actionButtonsContainer.alpha = _actionsVisibility;
			actionButtonsContainer.blendMode = _actionsVisibility < 1 ? BlendMode.LAYER : BlendMode.NORMAL;
			actionButtonsContainer.visible = _actionsVisibility > 0;
		}

		private function redrawDigitBoxes():void {
			// Redraws digit boxes based on the characters typed
			for (var i:int = 0; i < digitBoxes.length; i++) {
				digitBoxes[i].isChecked = currentEntry.length > i;
			}
		}

		private function createButtons(__y:Number, __b0:String, __b1:String, __b2:String):void {
			if (__b0 != null) createButton(__y, 0, __b0);
			if (__b1 != null) createButton(__y, 1, __b1);
			if (__b2 != null) createButton(__y, 2, __b2);
		}

		private function createButton(__y:Number, __col:int, __caption:String):void {
			var nb:NumberButton;
			var cols:int = 3;
			var bw:Number = Math.round((padWidth - ((cols-1) * getButtonMargin())) / cols);

			nb = new NumberButton(__caption, densityScale, fontScale, fontBold);
			nb.x = Math.round(MathUtils.map(__col, 0, cols-1, 0, padWidth - bw));
			nb.y = __y;
			nb.width = bw;
			nb.height = getButtonHeight();
			nb.addEventListener(MouseEvent.CLICK, onClickNumberButton);
			buttonsContainer.addChild(nb);

			numberButtons.push(nb);
		}

		private function showErrorMessage(__message:String):void {
			errorMessage.text = __message;
		}

		private function sendToBackend():void {
			// Send the data to the backend
			var actions:Vector.<BackendPinAction> = backendModel.validatePin(currentEntry);

			if (actions == null) {
				// Nothing returned: incorrect entry
				showErrorMessage(StringList.getList(FountainFamily.current_language).getString("services/pad/message-wrong"));
				currentEntry = "";
			} else {
				// Actions returned: correct entry, shows buttons
				showErrorMessage("");

				// Create buttons
				createActionButtons(actions);

				// Show buttons
				showActions();
			}
		}

		private function createActionButtons(__actions:Vector.<BackendPinAction>):void {
			removeActionButtons();
			actionButtons = new Vector.<ActionButton>();

			var actionButton:ActionButton;
			for (var i:int = 0; i < __actions.length; i++) {
				actionButton = new ActionButton(__actions[i].id, __actions[i].label.toUpperCase(), __actions[i].relatedService, __actions[i].type, densityScale, fontScale, fontBold);
				actionButton.width = padWidth;
				actionButton.height = getButtonHeight();
				actionButton.y = (-(__actions.length) + i) * (getButtonHeight() + getButtonMargin());
				actionButton.addEventListener(MouseEvent.CLICK, onClickActionButton);
				actionButtons.push(actionButton);
				actionButtonsContainer.addChild(actionButton);
			}
		}

		private function getLineHeight():Number {
			return Math.max(1, LINE_HEIGHT * densityScale);
		}

		private function getButtonHeight():Number {
			return Math.round(BUTTON_HEIGHT * densityScale);
		}

		private function getButtonMargin():Number {
			return Math.round(BUTTON_MARGIN * densityScale);
		}

		private function getPadMargin():Number {
			return Math.round(PAD_MARGIN * densityScale);
		}

		private function removeActionButtons():void {
			if (actionButtons != null) {
				while (actionButtons.length > 0) {
					actionButtons[0].removeEventListener(MouseEvent.CLICK, onClickActionButton);
					actionButtons[0].dispose();
					actionButtonsContainer.removeChild(actionButtons[0]);
					actionButtons.splice(0, 1);
				}
				actionButtons = null;
			}
		}

		private function showActions():void {
			ZTween.remove(this, "actionsVisibility");
			ZTween.add(this, {actionsVisibility:1}, {time:0.4});
		}

//		private function hideActions():void {
//			ZTween.remove(this, "actionsVisibility");
//			ZTween.add(this, {actionsVisibility:0}, {time:0.4});
//		}

		private function clear():void {
			// Resets the layout
			currentEntry = "";
			redrawDigitBoxes();
			showErrorMessage("");
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		private function onClickCover(__e:MouseEvent):void {
			hide();
		}

		private function onClickNumberButton(__e:MouseEvent):void {
			var char:String = (__e.currentTarget as NumberButton).character;

			if (char == NumberButton.CHARACTER_BACKSPACE) {
				if (currentEntry.length > 0) {
					currentEntry = currentEntry.substr(0, currentEntry.length - 1);
				}

				redrawDigitBoxes();
			} else if (currentEntry.length < DIGITS) {
				currentEntry += char;

				redrawDigitBoxes();

				if (currentEntry.length == DIGITS) {
					sendToBackend();
				}
			}
		}

		private function onClickActionButton(__e:MouseEvent):void {
			warn("Clicked on action button: " + __e.currentTarget);
			backendModel.executePinAction((__e.currentTarget as ActionButton).id);

			// Refresh buttons
			DelayedCalls.add(110, sendToBackend);
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function updateLanguage() : void {
			topMessage.text = StringList.getList(FountainFamily.current_language).getString("services/pad/title");
			bottomMessage.text = StringList.getList(FountainFamily.current_language).getString("services/pad/message-bottom");
		}

		public function show():void {
			if (!_isVisible) {
				backendModel.trackPinPrompt();
				_isVisible = true;
				actionsVisibility = 0;
				removeActionButtons();
				ZTween.remove(this);
				ZTween.add(this, {visibility:1}, {time:0.5, onComplete:function():void { dispatchEvent(new Event(EVENT_SHOWN)); }});
				clear();
			}
		}

		public function hide():void {
			if (_isVisible) {
				_isVisible = false;
				ZTween.remove(this);
				ZTween.add(this, {visibility:0}, {time:0.5, onComplete:function():void { dispatchEvent(new Event(EVENT_HIDDEN)); }});
			}
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function get visibility():Number {
			return _visibility;
		}

		public function set visibility(__value:Number):void {
			if (_visibility != __value) {
				_visibility = __value;
				redrawVisibility();
			}
		}

		public function get actionsVisibility():Number {
			return _actionsVisibility;
		}
		public function set actionsVisibility(__value:Number):void {
			if (_actionsVisibility != __value) {
				_actionsVisibility = __value;
				redrawActionsVisibility();
			}
		}
	}
}
