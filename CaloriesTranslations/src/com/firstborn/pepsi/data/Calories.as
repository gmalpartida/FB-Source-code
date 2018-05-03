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
        public static var DISPLAY_NAME : Boolean = false;                   //Boolean used to define if the name of the beverage will be displayed above the calories information
        public static var DISPLAY_ORIGINAL_MEASUREMENT : Boolean = false;   //Boolean used to define if the original measurement in oz will be displayed when there's a second measurement type
        public static var ROUNDING_RULES : Vector.<CaloriesRoundingRule>;
        public static var CALORIES_ON_FLAVOR : Boolean = false;             //Render the flavor calories in the name of the flavor
        private static var CUPS_GROUP_NAME : String = "cups";               //name of the group that has the cups names

        public function Calories(caloriesData : XML) {

            var cup_types : XMLList = XMLUtils.getNode(caloriesData, "cup_types").children();

            CALORIES_ACTIVE	= XMLUtils.getNodeAsBoolean(caloriesData, "calories_visible");
            CUPS_MEASUREMENT = XMLUtils.getNodeAsString(caloriesData, "measure_type", CUPS_MEASUREMENT);
            MEASUREMENT_CONVERSION = XMLUtils.getNodeAsFloat(caloriesData, "measure_conversion", MEASUREMENT_CONVERSION);
            DISPLAY_NAME = XMLUtils.getNodeAsBoolean(caloriesData, "display_beverage_name", DISPLAY_NAME);
            DISPLAY_ORIGINAL_MEASUREMENT = XMLUtils.getNodeAsBoolean(caloriesData, "display_original_measurement", DISPLAY_ORIGINAL_MEASUREMENT);
            CALORIES_ON_FLAVOR = XMLUtils.getNodeAsBoolean(caloriesData, "flavor_calories_on_name", CALORIES_ON_FLAVOR);

            CUPS = new Vector.<Cup>();
            for(var i : int = 0; i < cup_types.length(); i ++)  {
                var idString : String = CUPS_GROUP_NAME + '/' + XMLUtils.getNodeAsString(cup_types[i], "cup_id_string");
                var names : Vector.<String> = new Vector.<String>();
                for(var j : int = 0; j < FountainFamily.LOCALE_ISO.length; j ++)  names[j] = StringList.getList(FountainFamily.LOCALE_ISO[j]).getString(idString);
                trace(names);
                CUPS.push(new Cup(names, XMLUtils.getNodeAsFloat(cup_types[i], "volume")));
            }

            ROUNDING_RULES = new Vector.<CaloriesRoundingRule>();
            var roundingRules : XMLList = XMLUtils.getNode(caloriesData, "rounding").children();
            for(i = 0; i < roundingRules.length(); i ++)  {
                var lowerLimit : Number = XMLUtils.getNodeAsFloat(roundingRules[i], "lowerLimit");
                var higherLimit : Number = XMLUtils.getNodeAsFloat(roundingRules[i], "higherLimit");
                var roundValue : Number = XMLUtils.getNodeAsFloat(roundingRules[i], "roundValue");
                ROUNDING_RULES.push(new CaloriesRoundingRule(lowerLimit, higherLimit, roundValue));
            }

        }
    }
}