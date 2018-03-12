//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Application as App;

class HrvDisplayApp extends App.AppBase
{
    var mSensor;

    function initialize() {
        App.AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
        //Create the sensor object and open it
        mSensor = new HrvSensor();
        mSensor.open();
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
        // Release the sensor
        mSensor.closeSensor();
        mSensor.release();
    }

    // Return the initial view of your application here
    function getInitialView() {
        //The initial view is located at index 0
        var index = 0;
        return [new MainView(mSensor, index), new HrvDelegate(mSensor, index)];
    }
}
