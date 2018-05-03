package com.firstborn.pepsi.data {
import com.firstborn.pepsi.application.FountainFamily;
import com.firstborn.pepsi.data.inventory.Cup;
import com.zehfernando.localization.StringList;
import com.zehfernando.utils.XMLUtils;

public class Calories {

        public static var CALORIES_ACTIVE : Boolean = false;                //Defines if the calories will be displayed
        public static var CUPS : Vector.<Cup>                               //Contains the different cup sizes.
        public static var CUPS_MEASUREMENT : String = "fl oz";              //Defines the cup measurement (oz, lts, cm3)/ OZ is defined as default.
        public static var MEASUREMENT_CONVERSION : Number = 1;              //Defines the conversion type for the cup sizes from oz to the defined cup measurement.

        private static var CUPS_GROUP_NAME : String = "cups";               //name of the group that has the cups names

        public function Calories(caloriesData : XML) {

            var cup_types : XMLList = XMLUtils.getNode(caloriesData, "cup_types").children();

            CALORIES_ACTIVE	= XMLUtils.getNodeAsBoolean(caloriesData, "calories_visible");
            CUPS_MEASUREMENT = XMLUtils.getNodeAsString(caloriesData, "measure_type", CUPS_MEASUREMENT);
            MEASUREMENT_CONVERSION = XMLUtils.getNodeAsFloat(caloriesData, "measure_conversion", MEASUREMENT_CONVERSION);

            CUPS = new Vector.<Cup>();
            for(var i : int = 0; i < cup_types.length(); i ++)  {
                var idString : String = CUPS_GROUP_NAME + '/' + XMLUtils.getNodeAsString(cup_types[i], "cup_id_string");
                trace(idString);
                CUPS.push(new Cup(StringList.getList(FountainFamily.LOCALE_ISO[0]).getString(idString), XMLUtils.getNodeAsFloat(cup_types[i], "volume")));
            }

        }
    }
}