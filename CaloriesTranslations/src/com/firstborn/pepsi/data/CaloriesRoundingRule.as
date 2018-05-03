/**
 * Created by hectorarellano on 1/23/18.
 */
package com.firstborn.pepsi.data {

public class CaloriesRoundingRule {

    private var lowerLimit:Number;
    private var higherLimit:Number;
    private var roundingValue:Number;

    //Constructor
    public function CaloriesRoundingRule(_lowerLimit:Number, _higherLimit:Number, _roundingValue:Number) {
        this.lowerLimit = _lowerLimit;
        this.higherLimit = _higherLimit;
        this.roundingValue = _roundingValue;
    }

    //Function used to round the calories depending on the rules
    public function roundTo(value:Number):Number {

        var caloriesValue : Number = value;
        if(caloriesValue >= this.lowerLimit && caloriesValue < this.higherLimit) {

            if(this.roundingValue == 0) return 0;
            if(this.roundingValue == 1) return Math.round(caloriesValue);

            var units : Number = caloriesValue % 10;
            caloriesValue -= units;

            if(this.roundingValue == 5) {
                if(units > 2.5 && units <= 7.5 )  return (caloriesValue + 5);
                if(units > 7.5) return (caloriesValue + 10);
            }

            if(this.roundingValue == 10 && units >= 5) return (caloriesValue + 10);

            return caloriesValue;

        } else return caloriesValue;
    }
}
}
