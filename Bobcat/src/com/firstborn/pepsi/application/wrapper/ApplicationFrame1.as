package com.firstborn.pepsi.application.wrapper {
	import com.zehfernando.display.templates.application.ApplicationFrame1Abstract;
	import com.zehfernando.utils.DelayedCalls;
	import com.zehfernando.utils.console.Console;
	/**
	 * @author zeh fernando
	 */
	public class ApplicationFrame1 extends ApplicationFrame1Abstract {

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function ApplicationFrame1() {
			super();
		}

		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		override protected function initialize():void {
			super.initialize();
			Console.useJS = false;
		}

		override protected function setDefaultProperties():void {
			super.setDefaultProperties();
			frame2ClassName = "com.firstborn.pepsi.application.wrapper.ApplicationFrame2";
		}

		override protected function showFrame2():void {
			DelayedCalls.add(100, super.showFrame2);
		}
	}
}
