// Het scherm: Skyrim-achtige wijzerplaat met niveau-ring, tijd, gebied en reeks.
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Time;
using Toybox.Time.Gregorian as Greg;
using Toybox.Lang;

class VerkennerView extends Ui.WatchFace {

    // kleuren die het MIP-scherm van de Fenix goed kan tonen
    var GOLD = 0xFFAA00;
    var BONE = 0xFFFFAA;
    var DIM = 0xAAAAAA;
    var DARK = 0x555555;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
    }

    function num(v, d) {
        if (v != null && (v instanceof Lang.Number || v instanceof Lang.Float || v instanceof Lang.Long || v instanceof Lang.Double)) {
            return v.toFloat();
        }
        return d;
    }

    function str(v) {
        if (v != null && v instanceof Lang.String) {
            return v;
        }
        return "";
    }

    function diamond(dc, x, y, s) {
        dc.fillPolygon([[x, y - s], [x + s, y], [x, y + s], [x - s, y]]);
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        // ---- stand ophalen uit het geheugen ----
        var v = App.Storage.getValue("v");
        var has = v != null && v instanceof Lang.Dictionary;
        var lvl = 1;
        var frac = 0.0;
        var rank = "";
        var reg = "";
        var pct = 0;
        var km = 0.0;
        var streak = 0;
        var badges = 0;
        var btot = 0;
        var stale = true;
        if (has) {
            lvl = num(v["l"], 1.0).toNumber();
            frac = num(v["f"], 0.0);
            rank = str(v["r"]);
            reg = str(v["g"]);
            pct = num(v["p"], 0.0).toNumber();
            km = num(v["k"], 0.0);
            streak = num(v["s"], 0.0).toNumber();
            badges = num(v["b"], 0.0).toNumber();
            btot = num(v["bt"], 0.0).toNumber();
            var t = num(v["t"], 0.0).toNumber();
            stale = Time.now().value() - t > 3 * 3600;
        }

        // ---- XP-ring langs de rand ----
        var r = (w < h ? w : h) / 2 - 4;
        dc.setPenWidth(5);
        dc.setColor(DARK, Gfx.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, r);
        if (frac > 0.005) {
            dc.setColor(GOLD, Gfx.COLOR_TRANSPARENT);
            if (frac >= 0.995) {
                dc.drawCircle(cx, cy, r);
            } else {
                var e = 90 - (frac * 360).toNumber();
                if (e < 0) { e += 360; }
                dc.drawArc(cx, cy, r, Gfx.ARC_CLOCKWISE, 90, e);
            }
        }
        dc.setPenWidth(1);
        // windstreken als kleine ruitjes op de ring
        dc.setColor(BONE, Gfx.COLOR_TRANSPARENT);
        diamond(dc, cx, cy - r, 4);
        diamond(dc, cx + r, cy, 3);
        diamond(dc, cx, cy + r, 3);
        diamond(dc, cx - r, cy, 3);

        // ---- niveau bovenin, met sierlijnen ----
        var yL = (h * 0.16).toNumber();
        dc.setColor(GOLD, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx, yL, Gfx.FONT_XTINY, "NIVEAU " + lvl, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        dc.setColor(DIM, Gfx.COLOR_TRANSPARENT);
        var yR = (h * 0.235).toNumber();
        dc.drawLine(cx - (w * 0.30).toNumber(), yR, cx - 6, yR);
        dc.drawLine(cx + 6, yR, cx + (w * 0.30).toNumber(), yR);
        dc.setColor(BONE, Gfx.COLOR_TRANSPARENT);
        diamond(dc, cx, yR, 3);

        // ---- tijd ----
        var clock = Sys.getClockTime();
        var hr = clock.hour;
        if (!Sys.getDeviceSettings().is24Hour) {
            hr = hr % 12;
            if (hr == 0) { hr = 12; }
        }
        var timeStr = hr.format("%02d") + ":" + clock.min.format("%02d");
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.42).toNumber(), Gfx.FONT_NUMBER_HOT, timeStr, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        // ---- datum en rang ----
        var days = ["ZO", "MA", "DI", "WO", "DO", "VR", "ZA"];
        var months = ["JAN", "FEB", "MRT", "APR", "MEI", "JUN", "JUL", "AUG", "SEP", "OKT", "NOV", "DEC"];
        var info = Greg.info(Time.now(), Time.FORMAT_SHORT);
        var dateStr = days[info.day_of_week - 1] + " " + info.day + " " + months[info.month - 1];
        dc.setColor(DIM, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.585).toNumber(), Gfx.FONT_XTINY, dateStr, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        if (!has) {
            dc.setColor(DIM, Gfx.COLOR_TRANSPARENT);
            dc.drawText(cx, (h * 0.70).toNumber(), Gfx.FONT_XTINY, "Koppel in Verkenner", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
            return;
        }

        if (rank.length() > 0) {
            dc.setColor(GOLD, Gfx.COLOR_TRANSPARENT);
            dc.drawText(cx, (h * 0.665).toNumber(), Gfx.FONT_XTINY, rank.toUpper(), Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        }

        // ---- huidig gebied met voortgangsbalkje ----
        if (reg.length() > 0) {
            var name = reg.toUpper();
            if (name.length() > 13) { name = name.substring(0, 12) + "."; }
            dc.setColor(stale ? DIM : BONE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(cx, (h * 0.745).toNumber(), Gfx.FONT_XTINY, name + " " + pct + "%", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
            var bw = (w * 0.42).toNumber();
            var bx = cx - bw / 2;
            var by = (h * 0.80).toNumber();
            dc.setColor(DARK, Gfx.COLOR_TRANSPARENT);
            dc.fillRectangle(bx, by, bw, 3);
            dc.setColor(GOLD, Gfx.COLOR_TRANSPARENT);
            var p = pct > 100 ? 100 : pct;
            dc.fillRectangle(bx, by, (bw * p / 100), 3);
        }

        // ---- onderste regel: reeks (vlammetje), badges (medaille), km vandaag ----
        var yB = (h * 0.875).toNumber();
        dc.setColor(GOLD, Gfx.COLOR_TRANSPARENT);
        var fx = cx - (w * 0.20).toNumber();
        dc.fillPolygon([[fx, yB - 7], [fx + 5, yB], [fx + 3, yB + 5], [fx - 3, yB + 5], [fx - 5, yB]]);
        dc.setColor(BONE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(fx + 8, yB, Gfx.FONT_XTINY, "" + streak, Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);

        var mx = cx + (w * 0.06).toNumber();
        dc.setColor(GOLD, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(mx, yB + 1, 4);
        dc.drawLine(mx - 3, yB - 7, mx, yB - 2);
        dc.drawLine(mx + 3, yB - 7, mx, yB - 2);
        dc.setColor(BONE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(mx + 7, yB, Gfx.FONT_XTINY, "" + badges, Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);

        if (km > 0.05) {
            dc.setColor(DIM, Gfx.COLOR_TRANSPARENT);
            dc.drawText(cx, (h * 0.94).toNumber(), Gfx.FONT_XTINY, km.format("%.1f") + " km", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        }
    }

    function onExitSleep() {
        Ui.requestUpdate();
    }

    function onEnterSleep() {
        Ui.requestUpdate();
    }
}
