package com.firstborn.pepsi.common.display.services {
	import com.firstborn.pepsi.common.backend.BackendModel;
	import com.zehfernando.display.containers.DynamicDisplayAssetContainer;
	import com.zehfernando.utils.console.log;

	import flash.display.Sprite;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	/**
	 * @author zeh fernando
	 */
	public class ServicesRequiredOverlay extends Sprite {

		// Embeds
		[Embed(source="/../embed/icons/services/icon_service_cartridge.png")]
		public static const ICON_SERVICE_CARTRIDGE:Class;

		[Embed(source="/../embed/icons/services/icon_service_ice.png")]
		public static const ICON_SERVICE_ICE:Class;

		[Embed(source="/../embed/icons/services/icon_service_technician.png")]
		public static const ICON_SERVICE_TECHNICIAN:Class;

		[Embed(source="/../embed/icons/services/icon_service_co2-level.png")]
		public static const ICON_SERVICE_CO2_LEVEL:Class;

		[Embed(source="/../embed/icons/services/icon_service_still-water-temp.png")]
		public static const ICON_SERVICE_STILL_WATER_TEMP:Class;

		[Embed(source="/../embed/icons/services/icon_service_carb-water-temp.png")]
		public static const ICON_SERVICE_CARB_WATER_TEMP:Class;

		[Embed(source="/../embed/icons/services/icon_service_brand-sold-out.png")]
		public static const ICON_SERVICE_BRAND_SOLD_OUT:Class;

		[Embed(source="/../embed/icons/services/icon_service_flavor-sold-out.png")]
		public static const ICON_SERVICE_FLAVOR_SOLD_OUT:Class;

		// Constants
		private var IMAGE_DIMENSIONS:Number = 25;
		private var MARGIN_TOP:Number = 20;
		private var MARGIN_RIGHT:Number = 20;
		private var MARGIN_BETWEEN_IMAGES:Number = 10;

		// Properties
		private var densityScale:Number;

		// Instances
		private var currentIcons:Vector.<DynamicDisplayAssetContainer>;
		private var backendModel:BackendModel;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function ServicesRequiredOverlay(__backendModel:BackendModel, __densityScale:Number) {
			backendModel = __backendModel;
			densityScale = __densityScale;

			cacheAsBitmap = true;
			backendModel.refreshServicesRequired();
			backendModel.addEventListener(BackendModel.EVENT_SERVICES_REQUIRED_CHANGED, onUpdateRequired);
			cacheAsBitmap = true;
			recreateIcons();
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		private function onUpdateRequired(__e:Event):void {
			recreateIcons();
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function removeIcons():void {
			if (currentIcons != null) {
				while (currentIcons.length > 0) {
					removeChild(currentIcons[0]);
					currentIcons[0].dispose();
					currentIcons.splice(0, 1);
				}
				currentIcons = null;
			}
		}

		private function recreateIcons():void {
			// Read services that are actually needed and update icons
			removeIcons();

			var types:Vector.<String> = new <String>[
				BackendModel.BACKEND_SERVICE_STATUS_ID_TECHNICIAN,
				BackendModel.BACKEND_SERVICE_STATUS_ID_CARTRIDGE,
				BackendModel.BACKEND_SERVICE_STATUS_ID_ICE,
				BackendModel.BACKEND_SERVICE_STATUS_ID_BRAND_SOLD_OUT,
				BackendModel.BACKEND_SERVICE_STATUS_ID_FLAVOR_SOLD_OUT,
				BackendModel.BACKEND_SERVICE_STATUS_ID_CO2_LEVEL,
				BackendModel.BACKEND_SERVICE_STATUS_ID_CARB_WATER_TEMP,
				BackendModel.BACKEND_SERVICE_STATUS_ID_STILL_WATER_TEMP
			];
			currentIcons = new Vector.<DynamicDisplayAssetContainer>();
			var images:Vector.<Class> = new <Class>[
				ICON_SERVICE_TECHNICIAN,
				ICON_SERVICE_CARTRIDGE,
				ICON_SERVICE_ICE,
				ICON_SERVICE_BRAND_SOLD_OUT,
				ICON_SERVICE_FLAVOR_SOLD_OUT,
				ICON_SERVICE_CO2_LEVEL,
				ICON_SERVICE_CARB_WATER_TEMP,
				ICON_SERVICE_STILL_WATER_TEMP
			];

			var im:DynamicDisplayAssetContainer;

			var icons:int = 0;

			log("Updating icons");

			for (var i:int = 0; i < types.length; i++) {
				if (backendModel.getServiceRequiredStatus(types[i])) {
					var dimensions:Number = Math.round(IMAGE_DIMENSIONS * densityScale);

					im = new DynamicDisplayAssetContainer();
					im.smoothing = true;
					im.width = dimensions;
					im.height = dimensions;
					im.backgroundAlpha = 0;
					im.scaleMode = StageScaleMode.SHOW_ALL;
					im.x = - MARGIN_RIGHT - (icons + 1) * dimensions - (MARGIN_BETWEEN_IMAGES * icons);
					im.y = MARGIN_TOP;
					im.setAsset(new images[i]());
					addChild(im);

					currentIcons.push(im);

					icons++;
				}
			}
		}
	}
}
