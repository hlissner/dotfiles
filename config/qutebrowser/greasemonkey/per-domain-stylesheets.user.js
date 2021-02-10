// ==UserScript==
// @name        DomainStyles
// @namespace   https://github.com/hlissner
// @description Make it possible to use per-domain stylesheets.
// @include     *
// @run-at      document-start
// @version     1
// @author      Henrik Lissner
// ==/UserScript==

(function () {
	'use strict';

	document.addEventListener('readystatechange', function onReadyStateChange() {
		if (document.readyState == 'interactive') {
			const doc = document.documentElement;
			doc.setAttribute('qb-url', window.location.href);
			doc.setAttribute('qb-domain', window.location.host);
		}
	});
})();
