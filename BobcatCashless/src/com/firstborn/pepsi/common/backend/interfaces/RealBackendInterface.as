package com.firstborn.pepsi.common.backend.interfaces {
	import flash.external.ExternalInterface;

	/**
	 * @author zeh fernando
	 */
	public class RealBackendInterface implements IBackendInterface {

		/**
		 * The real implementation of the BackendInterface: simply pass calls to ExternalInterface
		 */

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function RealBackendInterface() {
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function call(__functionName:String, ...__args:*):* {
			var params:Array = [__functionName];
			params = params.concat(__args);
			return ExternalInterface.call.apply(null, params);
		}

		public function addCallback(__functionName:String, __closure:Function):void {
			ExternalInterface.addCallback(__functionName, __closure);
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function get available():Boolean {
			return ExternalInterface.available;
		}

		public function get objectID():String {
			return ExternalInterface.objectID;
		}
	}
}
