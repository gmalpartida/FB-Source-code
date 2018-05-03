package com.firstborn.pepsi.common.display.pad {
	import com.zehfernando.display.abstracts.ResizableButton;
	import com.zehfernando.display.components.text.TextSprite;
	import com.zehfernando.display.components.text.TextSpriteAlign;
	import com.zehfernando.display.containers.DynamicDisplayAssetContainer;
	import com.zehfernando.display.shapes.RoundedGradientBox;
	import com.zehfernando.transitions.ZTween;
	import com.zehfernando.utils.MathUtils;

	import flash.display.Bitmap;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.filters.DropShadowFilter;
	/**
	 * @author zeh fernando
	 */
	public class ActionButton extends ResizableButton {

		// Embeds
		[Embed(source="/../embed/icons/services/icon_actions_cartridge.png")]
		public static const ICON_ACTIONS_CARTRIDGE:Class;

		[Embed(source="/../embed/icons/services/icon_actions_ice.png")]
		public static const ICON_ACTIONS_ICE:Class;

		[Embed(source="/../embed/icons/services/icon_actions_lock.png")]
		public static const ICON_ACTIONS_LOCK:Class;

		[Embed(source="/../embed/icons/services/icon_actions_technician.png")]
		public static const ICON_ACTIONS_TECHNICIAN:Class;

		// Constants
		private static const CORNER_RADIUS:Number = 6;

		// Properties
		private var _id:String;
		private var _label:String;
		private var _relatedService:String;
		private var _type:String;
		private var densityScale:Number;

		// Instances
		private var caption:TextSprite;
		private var background:RoundedGradientBox;
		private var imageIcon:DynamicDisplayAssetContainer;
		private var imageLock:DynamicDisplayAssetContainer;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function ActionButton(__id:String, __label:String, __relatedService:String, __type:String, __densityScale:Number, __fontScale:Number, __fontBold:String) {
			super();

			_id = __id;
			_label = __label;
			_relatedService = __relatedService;
			_type = __type;
			densityScale = __densityScale;

			background = new RoundedGradientBox(_width, _height, 90, [0xf2f2f2, 0xe6e6e6], CORNER_RADIUS * __densityScale, [1, 1], [119, 135]);
			addChild(background);

			caption = new TextSprite(__fontBold, 24 * __fontScale, 0xb4b4b4);
			caption.text = __label;
			caption.align = TextSpriteAlign.LEFT;
			caption.blockAlignHorizontal = TextSpriteAlign.LEFT;
			caption.blockAlignVertical = TextSpriteAlign.MIDDLE;
			caption.filters = [new DropShadowFilter(2 * __densityScale, 45, 0x000000, 0.4, 2 * __densityScale, 2 * __densityScale, 1, 2, true), new DropShadowFilter(2 * __densityScale, 45, 0xffffff, 0.4, 2 * __densityScale, 2 * __densityScale, 1, 2, false)];
			addChild(caption);

			var iconBitmap:Bitmap = null;
			switch (__relatedService.toLowerCase()) {
				case "ice":
					iconBitmap = new ICON_ACTIONS_ICE();
					break;
				case "cartridge":
					iconBitmap = new ICON_ACTIONS_CARTRIDGE();
					break;
				default:
					iconBitmap = new ICON_ACTIONS_TECHNICIAN();
					break;
			}

			if (iconBitmap != null) {
				imageIcon = new DynamicDisplayAssetContainer();
				imageIcon.smoothing = true;
				imageIcon.backgroundAlpha = 0;
				imageIcon.scaleMode = StageScaleMode.NO_SCALE;
				imageIcon.contentScale = __densityScale * 1.25;
				imageIcon.setAsset(iconBitmap);
				addChild(imageIcon);
			}

			if (__type.toLowerCase() == "lock") {
				imageLock = new DynamicDisplayAssetContainer();
				imageLock.alpha = 0.8;
				imageLock.smoothing = true;
				imageLock.backgroundAlpha = 0;
				imageLock.scaleMode = StageScaleMode.NO_SCALE;
				imageLock.contentScale = __densityScale;
				imageLock.setAsset(new ICON_ACTIONS_LOCK());
				addChild(imageLock);
			}
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		override protected function redrawWidth():void {
			redraw();
		}

		override protected function redrawHeight():void {
			redraw();
		}

		private function redraw():void {
			background.width = _width;
			background.height = _height;
			caption.x = height * 0.8 + 5 * densityScale;
			caption.y = _height * 0.5;
			caption.width = _width - height * 1.6 - (10 * densityScale);

			if (imageIcon != null) {
				imageIcon.width = height * 0.8;
				imageIcon.height = height;
			}
			if (imageLock != null) {
				imageLock.width = height * 0.8;
				imageLock.x = _width - imageLock.width;
				imageLock.height = height;
			}
		}

		override protected function redrawState():void {
			caption.alpha = MathUtils.map(_pressed, 0, 1, 0.5, 1);
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		override protected function onButtonDownInternal():void {
			if (_enabled) {
				ZTween.remove(this, "pressed");
				ZTween.add(this, {pressed:1}, {time:0.1});
				dispatchEvent(new Event(EVENT_MOUSE_DOWN));
			}
		}

		override protected function onButtonUpInternal(__canceled:Boolean = false):void {
			ZTween.remove(this, "pressed");
			ZTween.add(this, {pressed:0}, {time:0.1});
			if (_enabled) {
				if (!__canceled) dispatchEvent(new Event(EVENT_CLICK));
				dispatchEvent(new Event(EVENT_MOUSE_UP));
			}
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function dispose():void {
			if (imageIcon != null) imageIcon.dispose();
			if (imageLock != null) imageLock.dispose();
		}

		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function get id():String {
			return _id;
		}
	}
}
