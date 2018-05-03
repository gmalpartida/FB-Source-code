package com.firstborn.pepsi.common.backend.interfaces {
	/**
	 * @author zeh fernando
	 */
	public interface IBackendInterface {

		/**
		 * This is the interface that sends data to the backend.
		 * Normally it would just be ExternalInterface, but all calls are passed through this so they
		 * can be intercepted by a mock implementation.
		 */

		function call(__functionName:String, ...args:*):*;
		function addCallback(__functionName:String, __closure:Function):void;
		function get available():Boolean;
		function get objectID():String;
	}
}
