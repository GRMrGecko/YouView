window.addEventListener("load", yvInit, false);
var menuitem;
function yvInit() {
	window.addEventListener("unload", yvUnload, false);
	menuitem = document.getElementById("yv-menuitem");
	var prefManager = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefBranch);
	var disabled = prefManager.getBoolPref("extensions.youview.disabled");
	if (disabled) {
		menuitem.label = "Enable YouView";
	} else {
		menuitem.label = "Disable YouView";
	}
}

function yvUnload() {
	observerService.removeObserver(YouViewObserver, "http-on-modify-request");
}

function able() {
	var prefManager = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefBranch);
	var disabled = prefManager.getBoolPref("extensions.youview.disabled");
	if (disabled) {
		menuitem.label = "Disable YouView";
		prefManager.setBoolPref("extensions.youview.disabled", false);
	} else {
		menuitem.label = "Enable YouView";
		prefManager.setBoolPref("extensions.youview.disabled", true);
	}
}
function hasPrefix(prefix, string) {
	var checkString = string.substr(0, prefix.length);
	if (checkString==prefix)
		return true;
	else
		return false;
}
// Observer for HTTP requests to block the sites we don't want
var YouViewObserver = {
	observe: function(aSubject, aTopic, aData) {
		if (aTopic != 'http-on-modify-request')
			return;

		aSubject.QueryInterface(Components.interfaces.nsIHttpChannel);
		
		var prefManager = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefBranch);
		var disabled = prefManager.getBoolPref("extensions.youview.disabled");
		if(!disabled) {
			var url = aSubject.URI.spec;
			if (url.match(/youtube.com\/watch/i)) {
				var query = url.split("?")[1];
				query = query.split("&");
				for (i=0; i<query.length; i++) {
					var pram = query[i].split("=");
					if (pram[0]=="v") {
						var id = pram[1];
						aSubject.loadFlags = Components.interfaces.nsICachingChannel.LOAD_ONLY_FROM_CACHE;
						aSubject.cancel(Components.results.NS_ERROR_FAILURE);
						window.location = "youview://?id="+id;
					}
				}
			} else if (url.match(/youtu.be\//i)) {
				var id = url.split("youtu.be")[1];
				id = id.split("/")[1];
				aSubject.loadFlags = Components.interfaces.nsICachingChannel.LOAD_ONLY_FROM_CACHE;
				aSubject.cancel(Components.results.NS_ERROR_FAILURE);
				window.location = "youview://?id="+id;
			}
		}
	},

	QueryInterface: function(iid) {
		if (!iid.equals(Components.interfaces.nsISupports) && !iid.equals(Components.interfaces.nsIObserver))
			throw Components.results.NS_ERROR_NO_INTERFACE;

		return this;
	}
};
var observerService = Components.classes["@mozilla.org/observer-service;1"].getService(Components.interfaces.nsIObserverService);
observerService.addObserver(YouViewObserver, "http-on-modify-request", false);