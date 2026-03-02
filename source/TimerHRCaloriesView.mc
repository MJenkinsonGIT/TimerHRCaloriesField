// TimerHRCaloriesView.mc  v9
//
// Layout (Top Slot -- HR near watch centre = bottom of slot):
//
//   [Act Cals lbl]        [Active Min lbl]  [Avg Hr lbl]
//   [Act Cals val]        [Active Min val]  [Avg Hr val]
//         [Total Cal lbl] [Timer lbl] [Max Hr lbl]
//         [Total Cal val] [Timer val] [Max Hr val]
//                         [Heart Rate lbl]
//                         [HR val LARGE]
//
// Layout (Bottom Slot -- HR near watch centre = top of slot):
//
//                         [HR val LARGE]
//   [Total Cal val]       [Heart Rate lbl]       [Max Hr val]
//   [Total Cal lbl]                              [Max Hr lbl]
//                         [Timer val]
//   [Act Cals val]                               [Avg Hr val]
//                         [Timer lbl]
//   [Act Cals lbl]                               [Avg Hr lbl]
//                         [Active Min val]
//                         [Active Min lbl]
//
// Key design decisions:
//   - Outer side cols (Act Cals / Avg Hr) at x=27%/73%.
//   - Inner side cols (Total Cal / Max Hr) at x=18%/82% (wider).
//   - HR rendered with FONT_NUMBER_MILD (shorter than MEDIUM) to fit bottom slot.
//   - Active Min displayed without 'm' unit -- label makes it clear.
//   - No member variables used as branch conditions (avoids analyser warnings).
//   - _dailyActMins is Number or Null so analyser cannot inline 0 into fmtMins.

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.UserProfile;
import Toybox.WatchUi;

class TimerHRCaloriesView extends WatchUi.DataField {

    // HR zone thresholds: [minZ1, maxZ1, maxZ2, maxZ3, maxZ4, maxZ5]
    // Loaded each compute() cycle via UserProfile.getHeartRateZones().
    private var _hrZones as Array<Number> or Null;

    // Cached display values
    private var _currentHR    as Number or Null;
    private var _avgHR        as Number or Null;
    private var _maxHR        as Number or Null;
    private var _sessionCals  as Number or Null;
    private var _dailyCals    as Number or Null;
    private var _timerMs      as Number or Long or Null;
    private var _dailyActMins as Number or Null;

    // Layout positions (set once in onLayout)
    private var _xCenter     as Number;
    private var _xLeft       as Number;   // Act Cals / Avg Hr  -- 27%/73%
    private var _xRight      as Number;
    private var _xInnerLeft  as Number;   // Total Cal / Max Hr -- 18%/82%
    private var _xInnerRight as Number;

    private var _yHRVal      as Number;
    private var _yHRLabel    as Number;
    private var _yTimerVal   as Number;
    private var _yTimerLabel as Number;
    private var _yDlyMinsVal as Number;
    private var _yDlyMinsLbl as Number;

    private var _ySideOuterVal as Number;   // Act Cals / Avg Hr values
    private var _ySideOuterLbl as Number;   // Act Cals / Avg Hr labels
    private var _ySideInnerVal as Number;   // Total Cal / Max Hr values
    private var _ySideInnerLbl as Number;   // Total Cal / Max Hr labels

    public function initialize() {
        DataField.initialize();
        _hrZones      = null;
        _currentHR    = null;
        _avgHR        = null;
        _maxHR        = null;
        _sessionCals  = null;
        _dailyCals    = null;
        _timerMs      = null;
        _dailyActMins = null;

        _xCenter     = 0;
        _xLeft       = 0;
        _xRight      = 0;
        _xInnerLeft  = 0;
        _xInnerRight = 0;

        _yHRVal      = 0;
        _yHRLabel    = 0;
        _yTimerVal   = 0;
        _yTimerLabel = 0;
        _yDlyMinsVal = 0;
        _yDlyMinsLbl = 0;

        _ySideOuterVal = 0;
        _ySideOuterLbl = 0;
        _ySideInnerVal = 0;
        _ySideInnerLbl = 0;
    }

    public function onLayout(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        _xCenter     = w / 2;
        _xLeft       = (w * 27) / 100;
        _xRight      = (w * 73) / 100;
        _xInnerLeft  = (w * 18) / 100;
        _xInnerRight = (w * 82) / 100;

        // Bezel geometry for inner cols at x=18%/82% (145px from centre):
        //   Safe when distance from watch centre <= 175px = 77% of slot h.
        //   All inner col y values kept <= 75% to maintain safe margin.

        var flags        = getObscurityFlags();
        var isBottomSlot = (flags & OBSCURE_BOTTOM) != 0;

        if (!isBottomSlot) {
            // TOP SLOT (v9)
            // h~227px. XTINY~13px, SMALL~22px, NUMBER_MILD~45px.
            //
            // CENTRE COLUMN (bottom-up):
            //   5% ActMin lbl    11px
            //  15% ActMin val    34px  (+22=56px)
            //  34% Timer lbl     77px  (21px gap from ActMin val bottom)
            //  46% Timer val    104px  (+22=126px, 14px gap from Timer lbl)
            //  60% HR lbl       136px  (tight gap -- user preference)
            //  65% HR val       148px  (+45=193px, 27px margin to centre line)
            //
            // SIDE OUTER (Act Cals / Avg Hr) at x=27%/73%:
            //  36% lbl   82px
            //  46% val  104px  (+22=126px)
            //
            // SIDE INNER (Total Cal / Max Hr) at x=18%/82%:
            //  Moved down to clear Act Cals val bottom (126px).
            //  69% lbl  157px  (31px clear gap from outer val bottom)
            //  75% val  170px  (+22=192px)  -- at bezel safety limit for x=18%

            _yDlyMinsLbl   = (h *  5) / 100;
            _yDlyMinsVal   = (h * 15) / 100;
            _yTimerLabel   = (h * 34) / 100;
            _yTimerVal     = (h * 46) / 100;
            _yHRLabel      = (h * 61) / 100;   // +3px
            _yHRVal        = (h * 68) / 100;   // +6px

            _ySideOuterLbl = (h * 36) / 100;
            _ySideOuterVal = (h * 47) / 100;   // +3px

            _ySideInnerLbl = (h * 68) / 100;
            _ySideInnerVal = (h * 80) / 100;   // +6px

        } else {
            // BOTTOM SLOT (v9)
            // h~227px. HR font switched to NUMBER_MILD (~45px) to fit.
            //
            // CENTRE COLUMN (top-down):
            //   0% HR val       0px   (+45=45px, NUMBER_MILD)
            //  27% HR lbl      61px   (16px gap from HR val bottom)
            //  40% Timer val   91px   (+22=113px)
            //  58% Timer lbl  132px   (19px gap from Timer val bottom)
            //  68% ActMin val 154px   (+22=176px)
            //  83% ActMin lbl 188px   (12px gap from ActMin val bottom)
            //
            // SIDE INNER (Total Cal / Max Hr) at x=18%/82%:
            //   8% val  18px  (+22=40px) -- data HIGHER
            //  30% lbl  68px  (28px gap from inner val bottom) -- label LOWER
            //
            // SIDE OUTER (Act Cals / Avg Hr) at x=27%/73%:
            //  39% val  88px  (+22=110px) -- data UNCHANGED
            //  54% lbl 123px  (13px gap from outer val bottom) -- label LOWER

            // Entire cluster shifted UP 20px (~9% of 227px slot).
            // HR val and inner val were already at/near 0% -- clamped there.
            // Full uniform 20px (~9%) upward shift applied to all elements.
            // HR val and inner val go negative to strip font ascent padding.
            _yHRVal        = (h * -9) / 100;   // -20px into negative
            _yHRLabel      = (h * 18) / 100;
            _yTimerVal     = (h * 31) / 100;
            _yTimerLabel   = (h * 49) / 100;
            _yDlyMinsVal   = (h * 59) / 100;
            _yDlyMinsLbl   = (h * 74) / 100;

            _ySideInnerVal = (h * -2) / 100;   // -5px, 15px below HR val
            _ySideInnerLbl = (h * 21) / 100;

            _ySideOuterVal = (h * 31) / 100;
            _ySideOuterLbl = (h * 48) / 100;
        }
    }

    public function compute(info as Activity.Info) as Void {
        _currentHR   = info.currentHeartRate;
        _avgHR       = info.averageHeartRate;
        _maxHR       = info.maxHeartRate;
        _timerMs     = info.timerTime;
        _sessionCals = info.calories;

        var amInfo  = ActivityMonitor.getInfo();
        _dailyCals  = amInfo.calories;

        var amv = amInfo.activeMinutesDay;
        if (amv != null) {
            _dailyActMins = amv.moderate + amv.vigorous;
        }

        // Refresh zone thresholds each cycle; getCurrentSport() picks
        // the sport-specific set automatically (or GENERIC as fallback).
        _hrZones = UserProfile.getHeartRateZones(UserProfile.getCurrentSport());
    }

    // Return zone colour for a given HR value.
    // Array layout: [minZ1, maxZ1, maxZ2, maxZ3, maxZ4, maxZ5]
    // Colours match Garmin Connect: 1=LtGray 2=Blue 3=Green 4=Orange 5=Red
    private function getZoneColor(hr as Number or Null, defaultColor as Number) as Number {
        if (hr == null) { return defaultColor; }
        var zones = _hrZones;
        if (zones == null) { return defaultColor; }
        if (hr < zones[0])  { return defaultColor; }           // below zone 1
        if (hr <= zones[1]) { return Graphics.COLOR_LT_GRAY; } // zone 1
        if (hr <= zones[2]) { return Graphics.COLOR_BLUE; }    // zone 2
        if (hr <= zones[3]) { return Graphics.COLOR_GREEN; }   // zone 3
        if (hr <= zones[4]) { return Graphics.COLOR_ORANGE; }  // zone 4
        return Graphics.COLOR_RED;                              // zone 5
    }

    private function fmtTimer(ms as Number or Long) as String {
        var s  = (ms / 1000).toNumber();
        var hh = s / 3600;
        var m  = (s % 3600) / 60;
        var ss = s % 60;
        if (hh > 0) {
            return hh.format("%d") + ":" + m.format("%02d") + ":" + ss.format("%02d");
        }
        return m.format("%d") + ":" + ss.format("%02d");
    }

    // Active Min: no 'm' suffix -- label makes unit clear.
    // Shows "45" for 45 min, "1h30" for 1h30min.
    private function fmtMins(totalMinutes as Number) as String {
        var hh = totalMinutes / 60;
        var m  = totalMinutes % 60;
        if (hh > 0) {
            return hh.format("%d") + "h" + m.format("%02d");
        }
        return m.format("%d");
    }

    public function onUpdate(dc as Dc) as Void {
        var bgColor = getBackgroundColor();
        var fgColor = (bgColor == Graphics.COLOR_WHITE)
            ? Graphics.COLOR_BLACK
            : Graphics.COLOR_WHITE;

        dc.setColor(fgColor, bgColor);
        dc.clear();

        var C = Graphics.TEXT_JUSTIFY_CENTER;
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);

        // Zone colours for the three HR-based fields.
        // Non-HR fields (calories, timer, active min) stay fgColor.
        var hrColor  = getZoneColor(_currentHR, fgColor);
        var avgColor = getZoneColor(_avgHR,     fgColor);
        var maxColor = getZoneColor(_maxHR,     fgColor);

        // CENTRE COLUMN
        // Heart Rate -- coloured by current zone
        var hrStr = (_currentHR != null) ? _currentHR.format("%d") : "--";
        dc.setColor(hrColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_xCenter, _yHRVal,   Graphics.FONT_NUMBER_MILD, hrStr,        C);
        dc.drawText(_xCenter, _yHRLabel, Graphics.FONT_XTINY,       "Heart Rate", C);

        // Timer -- plain fgColor
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        var timerStr = (_timerMs != null) ? fmtTimer(_timerMs) : "0:00";
        dc.drawText(_xCenter, _yTimerVal,   Graphics.FONT_SMALL, timerStr,    C);
        dc.drawText(_xCenter, _yTimerLabel, Graphics.FONT_XTINY, "Timer",     C);

        // Active Min -- plain fgColor
        var dlyStr = (_dailyActMins != null) ? fmtMins(_dailyActMins) : "--";
        dc.drawText(_xCenter, _yDlyMinsVal, Graphics.FONT_SMALL, dlyStr,       C);
        dc.drawText(_xCenter, _yDlyMinsLbl, Graphics.FONT_XTINY, "Active Min", C);

        // LEFT OUTER -- Act Cals (plain fgColor)
        var sesCalStr = (_sessionCals != null) ? _sessionCals.format("%d") : "--";
        dc.drawText(_xLeft, _ySideOuterVal, Graphics.FONT_SMALL, sesCalStr,  C);
        dc.drawText(_xLeft, _ySideOuterLbl, Graphics.FONT_XTINY, "Act Cals", C);

        // LEFT INNER -- Total Cal (plain fgColor)
        var dlyCalStr = (_dailyCals != null) ? _dailyCals.format("%d") : "--";
        dc.drawText(_xInnerLeft, _ySideInnerVal, Graphics.FONT_SMALL, dlyCalStr,   C);
        dc.drawText(_xInnerLeft, _ySideInnerLbl, Graphics.FONT_XTINY, "Total Cal", C);

        // RIGHT OUTER -- Avg Hr (zone colour)
        dc.setColor(avgColor, Graphics.COLOR_TRANSPARENT);
        var avgHRStr = (_avgHR != null) ? _avgHR.format("%d") : "--";
        dc.drawText(_xRight, _ySideOuterVal, Graphics.FONT_SMALL, avgHRStr, C);
        dc.drawText(_xRight, _ySideOuterLbl, Graphics.FONT_XTINY, "Avg Hr",  C);

        // RIGHT INNER -- Max Hr (zone colour)
        dc.setColor(maxColor, Graphics.COLOR_TRANSPARENT);
        var maxHRStr = (_maxHR != null) ? _maxHR.format("%d") : "--";
        dc.drawText(_xInnerRight, _ySideInnerVal, Graphics.FONT_SMALL, maxHRStr, C);
        dc.drawText(_xInnerRight, _ySideInnerLbl, Graphics.FONT_XTINY, "Max Hr",  C);
    }

    public function onTimerStart()  as Void {}
    public function onTimerStop()   as Void {}
    public function onTimerPause()  as Void {}
    public function onTimerResume() as Void {}
    public function onTimerLap()    as Void {}
    public function onTimerReset()  as Void {}
}
