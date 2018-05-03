/**
 * Created by hectorarellano on 12/5/17.
 */

package com.firstborn.pepsi.display.gpu.common.components {

import com.firstborn.pepsi.application.FountainFamily;
import com.firstborn.pepsi.assets.FontLibrary;
import com.firstborn.pepsi.common.backend.BackendModel;
import com.firstborn.pepsi.display.gpu.common.TextBitmap;
import com.firstborn.pepsi.display.gpu.common.TextureLibrary;
import com.zehfernando.display.components.text.TextSpriteAlign;

import starling.display.Image;
    import starling.display.Sprite;

    public class UnlockTimer extends Sprite {

        private var upperText : Image;
        private var lowerText: Image;

        public function UnlockTimer() {

            update(0);

            var lowerTextId : String = "unlockTimer_lower"
            if (!FountainFamily.objectRecycler.has(lowerTextId)) FountainFamily.objectRecycler.putNew(lowerTextId, new Image(TextBitmap.createTexture("LEFT IN YOUR SESSION", FontLibrary.BOOSTER_FY_REGULAR, null, 15, NaN, 0xffffff, -1, 1, 1, 160, 160, TextSpriteAlign.CENTER, false)));
            lowerText = FountainFamily.objectRecycler.get(lowerTextId);
            lowerText.touchable = false;
            lowerText.color = 0x7e878c;
            lowerText.smoothing = FountainFamily.platform.getTextureProfile(TextureLibrary.TEXTURE_ID_GENERIC_TEXT).smoothing;
            lowerText.pivotX = lowerText.width * 0.5;
            addChild(lowerText);

            lowerText.y = upperText.height + 5;

            this.alpha = 0;

        }

//        TODO: this should be done using the animatedImage class from Zeh. This would require to implement a srpite sheet with the numbers from 0 to 120.
//        TODO: the update would modify the UV mapping to show the corresponding number.

        public function update(seconds : uint) : void {

            if(upperText != null) {
                removeChild(upperText);
                upperText = null;
            }

            var upperTextId : String = "unlockTimer_" + String(seconds);
            if (!FountainFamily.objectRecycler.has(upperTextId)) FountainFamily.objectRecycler.putNew(upperTextId, new Image(TextBitmap.createTexture(String(seconds) + " Sec", FontLibrary.BOOSTER_FY_REGULAR, null, 40, NaN, 0xffffff, -1, 1, 1, 160, 160, TextSpriteAlign.CENTER, false)));
            upperText = FountainFamily.objectRecycler.get(upperTextId);
            upperText.touchable = false;
            upperText.color = seconds <= BackendModel.UNLOCKED_REMAINING_TIME ? 0Xff0000 : 0x33a2d1;
            upperText.smoothing = FountainFamily.platform.getTextureProfile(TextureLibrary.TEXTURE_ID_GENERIC_TEXT).smoothing;
            upperText.pivotX = upperText.width * 0.5;
            addChild(upperText);

            this.alpha = 1;

        }
    }

}
