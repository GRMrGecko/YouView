//
//  YouView.js
//  YouView
//
//  Created by Mr. Gecko on 12/25/09.
//  Copyright 2012 Mr. Gecko's Media. All rights reserved.
//

if (window.location.pathname!="/watch") {
	var id = window.location.pathname.replace(/\//, "");
	window.stop();
	window.location = "youview://?id="+id;
} else {
	var query = window.location.search;
	query = query.substr(1, query.length-1);
	query = query.split("&");
	for (i=0; i<query.length; i++) {
		var pram = query[i].split("=");
		if (pram[0]=="v") {
			var id = pram[1];
			window.stop();
			window.location = "youview://?id="+id;
		}
	}
}