// Achtergrondtaak: haalt de stand op via de Garmin Connect-app op je telefoon.
using Toybox.Background;
using Toybox.Communications as Comm;
using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Lang;

(:background)
class VerkennerSync extends Sys.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() {
        var url = App.Properties.getValue("ServerUrl");
        var key = App.Properties.getValue("SyncKey");
        if (url == null || key == null || key.length() < 16) {
            Background.exit(-1);
            return;
        }
        Comm.makeWebRequest(
            url + "/v/" + key,
            null,
            {
                :method => Comm.HTTP_REQUEST_METHOD_GET,
                :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onReceive)
        );
    }

    function onReceive(code, data) {
        if (code == 200 && data != null && data instanceof Lang.Dictionary) {
            Background.exit(data);
        } else {
            Background.exit(code);
        }
    }
}
