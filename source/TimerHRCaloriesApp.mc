// Timer Heart Rate Calories - Data Field for Garmin Venu 3
// Designed for 2-field (top/bottom) screen layout
// Displays: Current HR (large), Session Timer, Daily Active Minutes,
//           Session Active Calories, Daily Total Calories,
//           Average HR, Max HR

import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class TimerHRCaloriesApp extends Application.AppBase {

    public function initialize() {
        AppBase.initialize();
    }

    public function getInitialView() as [ WatchUi.Views ] or [ WatchUi.Views, WatchUi.InputDelegates ] {
        return [ new TimerHRCaloriesView() ];
    }
}

function getApp() as TimerHRCaloriesApp {
    return Application.getApp() as TimerHRCaloriesApp;
}
