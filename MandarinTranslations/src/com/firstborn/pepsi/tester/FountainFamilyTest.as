package com.firstborn.pepsi.tester {
	import asunit.textui.TestRunner;

	import com.firstborn.pepsi.tester.tests.suites.AllTests;
	import com.zehfernando.display.templates.application.SimpleApplication;

	import flash.system.Security;
	/**
	 * @author zeh fernando
	 */
	public class FountainFamilyTest extends SimpleApplication {

		// Properties

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function FountainFamilyTest() {
			super();

			// Do not add anything else here
			Security.allowDomain("*");
			Security.allowInsecureDomain("*");
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		override protected function addDynamicAssetsFirstPass():void {
		}

		override protected function addDynamicAssetsSecondPass():void {
		}

		override protected function getDynamicAssetSecondPassPhaseSize():Number {
			return super.getDynamicAssetSecondPassPhaseSize();
		}

		override protected function createVisualAssets():void {
			// Disable tab interface
			stage.stageFocusRect = false;
			focusRect = false;
			tabEnabled = false;
			visible = true;

			// Runs all tests
			var unittests:TestRunner = new TestRunner();
			stage.addChild(unittests);
			unittests.start(AllTests, null, false);
		}
	}
}