package com.firstborn.pepsi.tester.tests.suites {
	import asunit.framework.TestSuite;

	import com.firstborn.pepsi.tester.tests.cases.TestBackend;

	/**
	 * @author zeh fernando
	 */
	public class AllTests extends TestSuite {

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function AllTests() {
			super();

			addTest(new TestBackend());
		}
	}
}
