package com.firstborn.pepsi.application.wrapper {
	import com.firstborn.pepsi.application.FountainFamily;
	import com.zehfernando.display.templates.application.ApplicationFrame2Abstract;
	import com.zehfernando.display.templates.application.events.ApplicationFrame2Event;
	import com.zehfernando.utils.console.info;
	/**
	 * @author zeh fernando
	 */
	public class ApplicationFrame2 extends ApplicationFrame2Abstract {

		// Instances
		protected var app:FountainFamily;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function ApplicationFrame2() {
			super();
		}

		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		override public function init():void {
			info("Initializing");

			dispatchEvent(new ApplicationFrame2Event(ApplicationFrame2Event.INIT_PROGRESS));
			dispatchEvent(new ApplicationFrame2Event(ApplicationFrame2Event.INIT_COMPLETE));
		}

		override public function show():void {
			super.show();
			visible = false;

			// Creates visual assets
			app = new FountainFamily();
			stage.addChild(app);
		}
	}
}
