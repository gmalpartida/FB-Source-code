package com.firstborn.pepsi.display.gpu.home.view {
    import starling.display.Image;
    import starling.display.Sprite;

    public class UnlockError extends Sprite {

        private static var errors : Vector.<UnlockError> = new Vector.<UnlockError>();

        //Id of the error
        public var id : uint;

        //List of images from the error (for the copy)
        private var errorData: Vector.<Image>;

        //The information is build in the homeView,
        public function UnlockError(_id, _errorData) {
            id = _id;
            errorData = _errorData;
            UnlockError.errors.push(this);
            hideErrors();
        }

        //Function used to show the locale error required
        public function showError(language : uint) : Image {
            hideErrors();
            errorData[language].visible = true;
            return errorData[language];
        }

        //Function used to hide all the locales from the error
        public function hideErrors() : void {
            for(var i:uint = 0; i < errorData.length; i ++) {
                errorData[i].visible = false;
                errorData[i].alpha = 0;
            }
        }

        //Function used to clear the images.
        public override function dispose() : void {
            for(var i:uint = 0; i < errorData.length; i ++) errorData[i].dispose();
            super.dispose();
        }
    }
}
