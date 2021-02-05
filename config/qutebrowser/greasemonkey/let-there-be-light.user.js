// ==UserScript==
// @name        Let there be Light
// @description Change page background to white.
// @version     0.1
// @author      Ingvix
// @include     *
// ==/UserScript==

// Needed to counterbalance my colors.webpage.bg hack to prevent the blinding
// flash of white between page loads.
var sheet = window.document.styleSheets[0];
sheet.insertRule('body { background-color: white; }', sheet.cssRules.length);
