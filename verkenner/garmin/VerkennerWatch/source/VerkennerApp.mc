// Verkenner – watchface voor Garmin Fenix 5S
// Haalt elke 5 minuten je Verkenner-stand op van je eigen server en toont die.
using Toybox.Application as App;
using Toybox.Background;
using Toybox.System as Sys;
using Toybox.Time;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

(:background)
class VerkennerApp extends App.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    // Het scherm van de watchface; registreert ook het ophalen op de achtergrond
    function getInitialView() {
        if (Toybox.System has :ServiceDelegate) {
            Background.registerForTemporalEvent(new Time.Duration(5 * 60));
        }
        return [ new VerkennerView() ];
    }

    function getServiceDelegate() {
        return [ new VerkennerSync() ];
    }

    // Komt binnen zodra de achtergrondtaak klaar is
    function onBackgroundData(data) {
        if (data != null && data instanceof Lang.Dictionary) {
            App.Storage.setValue("v", data);
            App.Storage.deleteValue("err");
        } else if (data != null) {
            App.Storage.setValue("err", data);
        }
        Ui.requestUpdate();
    }

    function onSettingsChanged() {
        Ui.requestUpdate();
    }
}
