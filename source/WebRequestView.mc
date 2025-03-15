//
// Copyright 2015-2021 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;

const OUTER_TIME_SIZE = 2;
const FONT_SMALL_HEIGHT = 27;
const FONT_TINY_HEIGHT = 30;
const FONT_TINY_LETTER_WIDTH = 15; // Approx bcs MAJ are larger than regular.
const FONT_XTINY_HEIGHT = 5;

function minToString(min as Number) as String {
    if(min < 10){
        return "0" + min.toString();
    } else {
        return min.toString();
    }
}

class CustomRoundedRectangle 
{
    var pos_x;
    var pos_y;
    var mWidth;
    var mHeight;
    var mRadius;
    var mColor;

    function initialize(x, y, width, height, radius, color) {
        pos_x = x;
        pos_y = y;
        mHeight = height;
        mWidth = width;
        mRadius = radius;
        mColor = color;
    }

    public function print(dc as Dc) as Void {
        dc.setColor(mColor, Graphics.COLOR_BLACK);
        dc.fillRoundedRectangle(pos_x, pos_y, mWidth, mHeight, mRadius);
    }
}

class IncomingTrain
{
    var mName;
    var mDelay;
    var mArrivalTime;
    var mDestination;
    var mDestinationCurrentPosX;
    var mRowNb;
    var mRowHeight;
    var mRowBgColor;
    var mBackground;

    function initialize(rowNb, rowHeight, rowWidth, rowBgColor) {
        mDestinationCurrentPosX = 0;
        mRowNb = rowNb;
        mRowHeight = rowHeight;
        mRowBgColor = rowBgColor;
        mBackground = new CustomRoundedRectangle(0, rowWidth / 6 + OUTER_TIME_SIZE + mRowHeight * mRowNb, rowWidth, rowHeight, 0, rowBgColor);
    }

    public function updateInfo(name, delay, arrivalTime, destination) as Void {
        mName = name;
        mDelay = delay;
        mArrivalTime = arrivalTime;
        mDestination = destination;
    }

    public function print(dc as Dc) as Void {
        mBackground.print(dc);
        var boundaryTrainNameArrivalTime = dc.getWidth() / 4 + OUTER_TIME_SIZE * 8;
        dc.setColor(0xffff44, mRowBgColor);
        // Print time 
        dc.drawText(boundaryTrainNameArrivalTime + OUTER_TIME_SIZE, dc.getWidth() / 6 + mRowHeight * (mRowNb + 0.25), Graphics.FONT_SMALL, mArrivalTime, Graphics.TEXT_JUSTIFY_LEFT);

        dc.setColor(Graphics.COLOR_WHITE, mRowBgColor);
        // Print Train Name
        dc.drawText(boundaryTrainNameArrivalTime - OUTER_TIME_SIZE, dc.getWidth() / 6 + OUTER_TIME_SIZE*2 + mRowHeight * mRowNb, Graphics.FONT_SMALL, mName, Graphics.TEXT_JUSTIFY_RIGHT);
        // Print Train delay
        dc.drawText(boundaryTrainNameArrivalTime - OUTER_TIME_SIZE, dc.getWidth() / 6 + OUTER_TIME_SIZE*2 + FONT_SMALL_HEIGHT + mRowHeight * mRowNb, Graphics.FONT_XTINY, mDelay, Graphics.TEXT_JUSTIFY_RIGHT);
        // Print Train 
        var base_positionX = (dc.getWidth() / 4) * 2.3;
        dc.setClip(base_positionX, dc.getWidth() / 6 + 5 + mRowHeight * mRowNb, dc.getWidth(), FONT_TINY_HEIGHT);
        dc.drawText(base_positionX - mDestinationCurrentPosX, dc.getWidth() / 6 + 5 + mRowHeight * mRowNb, Graphics.FONT_TINY, mDestination, Graphics.TEXT_JUSTIFY_LEFT);
        dc.clearClip();
        if(mDestinationCurrentPosX > FONT_TINY_LETTER_WIDTH * mDestination.length() - dc.getWidth()/2 - 10) {
            mDestinationCurrentPosX = 0;
        } else {
            mDestinationCurrentPosX += 1;
        }
        //dc.drawRectangle(base_positionX - mDestinationCurrentPosX, dc.getWidth() / 6 + 5 + mRowHeight * mRowNb, FONT_TINY_LETTER_WIDTH * mDestination.length() , FONT_TINY_HEIGHT);
    }
}

//! Shows the web request result
class WebRequestView extends WatchUi.View {
    private var _message as String = "Press menu or\nselect button";
    private var innerTime;
    private var outerTime;
    private var innerStation;
    private var outerStation;
    private var trains = new[3];
    private var updateTimer;
    private var appState;

    //! Constructor
    public function initialize() {
        WatchUi.View.initialize();
        updateTimer = new Timer.Timer();
        appState = ChoosingModeOfTransport;
    }

    //! Load your resources here
    //! @param dc Device context
    public function onLayout(dc as Dc) as Void {
        var width_div6 = dc.getWidth() / 6;
        var width_div4 = dc.getWidth() / 4;
        var trainHeight =  (width_div4 - OUTER_TIME_SIZE * 2);
        outerTime = new CustomRoundedRectangle(width_div4, 0, width_div6 * 3 + OUTER_TIME_SIZE * 2, width_div6, 20, Graphics.COLOR_WHITE);
        innerTime = new CustomRoundedRectangle(width_div4 + OUTER_TIME_SIZE, 0, width_div6 * 3, width_div6 - OUTER_TIME_SIZE , 20, 0x000080);
        //dc.getWidth() / 2, dc.getHeight() - FONT_TINY_HEIGHT
        // x, y, width, height, radius, color
        outerStation = new CustomRoundedRectangle(width_div4,  dc.getHeight() - FONT_TINY_HEIGHT - OUTER_TIME_SIZE, width_div6 * 3 + OUTER_TIME_SIZE * 2, width_div6, 20, Graphics.COLOR_WHITE);
        innerStation = new CustomRoundedRectangle(width_div4 + OUTER_TIME_SIZE,  dc.getHeight() - FONT_TINY_HEIGHT, width_div6 * 3, width_div6 - OUTER_TIME_SIZE , 20, 0x000080);
        trains[0] = new IncomingTrain(0, trainHeight, dc.getWidth(), 0x0c5da5);
        trains[1] = new IncomingTrain(1, trainHeight, dc.getWidth(), 0x001b33);
        trains[2] = new IncomingTrain(2, trainHeight, dc.getWidth(), 0x0c5da5);
    }

    //! Restore the state of the app and prepare the view to be shown
    public function onShow() as Void {
    }

    function triggerUpdate() {
        WatchUi.requestUpdate();
    }

    //! Update the view
    //! @param dc Device Context
    public function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        outerTime.print(dc);
        innerTime.print(dc);

        dc.setColor(Graphics.COLOR_WHITE, 0x000080);
        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var displayedTime = today.hour.toString() + ":" + minToString(today.min);
        dc.drawText(dc.getWidth() / 2, 5, Graphics.FONT_SMALL, displayedTime, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        outerStation.print(dc);
        innerStation.print(dc);
        dc.setColor(Graphics.COLOR_WHITE, 0x000080);
        // Draw station
        dc.drawText(dc.getWidth() / 2, dc.getHeight() - FONT_TINY_HEIGHT, Graphics.FONT_TINY, "ARK", Graphics.TEXT_JUSTIFY_CENTER);
        for(var i = 0; i < 3; i++){
            trains[i].print(dc);
        }
        updateTimer.start(method(:triggerUpdate), 50, false);
    }

    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    public function onHide() as Void {
    }

    private function compute_waiting_time(hour as Number, min as Number) as Number {
        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        if(hour == 23) {
            hour = -1;
        }
        return ((hour+1) - today.hour) * 60 + (min - today.min);
    }

    private function compute_delay(expectedArrivalTime as String, aimedArrivalTime as String) {
        var expectedHour = expectedArrivalTime.substring(11, 13).toNumber();
        var expectedMin = expectedArrivalTime.substring(14, 16).toNumber();
        var expectedSec = expectedArrivalTime.substring(17, 19).toNumber();
        var aimedHour = aimedArrivalTime.substring(11, 13).toNumber();
        var aimedMin = aimedArrivalTime.substring(14, 16).toNumber();
        var aimedSec = aimedArrivalTime.substring(17, 19).toNumber();
        var delay = (expectedHour * 3600 + expectedMin * 60 + expectedSec) - (aimedHour * 3600 + aimedMin * 60 + aimedSec);
        if(delay < 60){
            return "on time";
        } else {
            return "+" + (delay / 60).toString() + " mins";
        }
    }

    //! Show the result or status of the web request
    //! @param args Data from the web request, or error message
    public function onReceive(args as Dictionary or String or Null) as Void {
        System.println(args);
        _message = "";
        if (args instanceof String) {
            updateStateAndMenu(args);
        } else if (args instanceof Dictionary) {
            var incoming_trains = args["Siri"]["ServiceDelivery"]["StopMonitoringDelivery"][0]["MonitoredStopVisit"];
            var len_array = incoming_trains.size();
            if(len_array > 3) {
                len_array = 3;
            }
            var hour = 0;
            var min = 0;
            var name;
            var delay;
            var arrivalTime;
            var destination;
            for (var i = 0; i < len_array; i++) {
                hour = incoming_trains[i]["MonitoredVehicleJourney"]["MonitoredCall"]["ExpectedArrivalTime"].toString().substring(11, 13).toNumber();
                min = incoming_trains[i]["MonitoredVehicleJourney"]["MonitoredCall"]["ExpectedArrivalTime"].toString().substring(14, 16).toNumber();
                name = incoming_trains[i]["MonitoredVehicleJourney"]["JourneyNote"][0]["value"];
                delay = compute_delay(incoming_trains[i]["MonitoredVehicleJourney"]["MonitoredCall"]["ExpectedArrivalTime"].toString(), incoming_trains[i]["MonitoredVehicleJourney"]["MonitoredCall"]["AimedArrivalTime"].toString());
                //delay = "+120 mins";
                min = minToString(min);
                arrivalTime = (hour + 1).toString() + ":" + min;
                destination = incoming_trains[i]["MonitoredVehicleJourney"]["DestinationName"][0]["value"].toString();
                trains[i].updateInfo(name, delay, arrivalTime, destination);
            }
        }
        WatchUi.requestUpdate();
    }
}