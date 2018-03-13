//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Ant as Ant;
using Toybox.WatchUi as Ui;
using Toybox.Time as Time;
using Toybox.ActivityRecording as Recording;
using Toybox.FitContributor as Fit;

class HrvSensor extends Ant.GenericChannel {
    const DEVICE_TYPE = 120;
    const PERIOD = 8070;
    const MO2_FIELD_ID = 0;

    hidden var chanAssign;
    hidden var fitField;
    hidden var session;

    var data;
    var searching;
    var pastEventCount;
    var deviceCfg;
	var messageState;
	var messageState2;       
	 
    class HrData {
        var currentHeartRate;

        function initialize() {
            currentHeartRate = 0;
        }
    }
    
	class HeartRateDataPage {
        static const INVALID_HR = 0x00;

        function parse(payload, data) {
            data.currentHeartRate = parseCurrentHR(payload);
        }

        hidden function parseCurrentHR(payload) {
            return payload[7];
        }
    }

    class CommandDataPage {
        static const PAGE_NUMBER = 0x10;
        static const CMD_SET_TIME = 0x00;

        static function setTime(payload) {
        }

    }

    function initialize() {
        // Get the channel
        chanAssign = new Ant.ChannelAssignment(Ant.CHANNEL_TYPE_RX_NOT_TX, Ant.NETWORK_PLUS);
        GenericChannel.initialize(method(:onMessage), chanAssign);
        fitField = null;
		// Set the configuration
        deviceCfg = new Ant.DeviceConfig( {
            :deviceNumber => 0,                 // Wildcard our search
            :deviceType => DEVICE_TYPE,
            :transmissionType => 0,
            :messagePeriod => PERIOD,
            :radioFrequency => 57,              // Ant+ Frequency
            :searchTimeoutLowPriority => 10,    // Timeout in 25s
            :searchThreshold => 0} );           // Pair to all transmitting sensors
        GenericChannel.setDeviceConfig(deviceCfg);
        data = new HrData();
        searching = true;
    }
		
	private function reconfig() {
		
	}
		
    function open() {
        // Open the channel
        GenericChannel.open();

        data = new HrData();
        pastEventCount = 0;
        searching = true;
    }

    function closeSensor() {
        GenericChannel.close();
    }

    function setTime() {
        if (!searching && (data.utcTimeSet)) {
            // Create and populat the data payload
            var payload = new [8];
            payload[0] = 0x10;  // Command data page
            payload[1] = 0x00;  // Set time command
            payload[2] = 0xFF;  // Reserved
            payload[3] = 0;     // Signed 2's complement value indicating local time offset in 15m intervals

            // Set the current time
            var moment = Time.now();
            for (var i = 0; i < 4; i++) {
                payload[i + 4] = ((moment.value() >> i) & 0x000000FF);
            }

            // Form and send the message
            var message = new Ant.Message();
            message.setPayload(payload);
            GenericChannel.sendAcknowledge(message);
        }
    }
	
    function onMessage(msg) {
        // Parse the payload
        var payload = msg.getPayload();

        if (Ant.MSG_ID_BROADCAST_DATA == msg.messageId) {
        	me.messageState = "Broadcast data";
        	Ui.requestUpdate();
            // Were we searching?
            if (searching) {
                searching = false;
                // Update our device configuration primarily to see the device number of the sensor we paired to
                deviceCfg = GenericChannel.getDeviceConfig();
            }
            var dp = new HeartRateDataPage();
            dp.parse(msg.getPayload(), data);
        } else if (Ant.MSG_ID_CHANNEL_RESPONSE_EVENT == msg.messageId) {
            if (Ant.MSG_ID_RF_EVENT == (payload[0] & 0xFF)) {
                if (Ant.MSG_CODE_EVENT_CHANNEL_CLOSED == (payload[1] & 0xFF)) {
                	me.messageState = "Chan cl, re-open";
                    // Channel closed, re-open
                    open();
                } else if (Ant.MSG_CODE_EVENT_RX_FAIL_GO_TO_SEARCH  == (payload[1] & 0xFF)) {
                	me.messageState = "Searching";
                    searching = true;
                    Ui.requestUpdate();
                }
            } else {
            	//75,0,255,31
            	me.messageState = payload[0] + ", " + payload[1] + ", " + payload[2] + ", " + payload[3];
            	//0,0,0,0
            	me.messageState2 = payload[4] + ", " + payload[5] + ", " + payload[6] + ", " + payload[7]; 
                //It is a channel response.
            }
        }
        else {
        	me.messageState = "Unknown: " + msg.messageId;
        }
        Ui.requestUpdate();
    }
}