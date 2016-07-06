// donate-bitcoin Copyright (GPL) 2016  Nathan Robinson

var address = "15EQPm5BFGbxkqjqAoZKhapwShTtzap9aj"; // The bitcoin address to receive donations. Change to yours
var popup = false; // Set to true if you want a popup to pay bitcoin
var currency_code = "USD"; // Change to your default currency. Choose from https://api.bitcoinaverage.com/ticker/
var qrcode = true; // Set to false to disable qrcode
var link = true; // Set to false to disable generating hyperlink
var organization = "Nathan Robinson"; // Change to your organization name
var mbits = true; // Set to false to display bitcoin traditionally


var params = {};

if (location.search) {
    var parts = location.search.substring(1).split('&');
    for (var i = 0; i < parts.length; i++) {
        var nv = parts[i].split('=');
        if (!nv[0]) continue;
        params[nv[0]] = nv[1] || true;
    }
}

console.log(params.amount);
console.log(currency_code);

function turnName(data)
{
  var returnstring = "";
  for (i = 0; i < data.length; i++)
  {
    if (data[i] != "-")
    {
    returnstring = returnstring + data[i];
    }

    if (data[i] == "-")
    {
    returnstring = returnstring + " ";
    }
  }
  return returnstring
}

if (params.address){address = params.address;}
if (params.popup == "true"){popup = true};
if (params.popup == "false"){popup = false};
if (params.currency){currency_code = params.currency;}
if (params.qrcode == "true"){qrcode = true};
if (params.qrcode == "false"){qrcode = false};
if (params.link == "true"){link = true};
if (params.link == "false"){link = false};
if (params.name){organization = turnName(params.name);}

if (params.mbits == "true"){mbits = true};
if (params.mbits == "false"){mbits = false};


function httpGet(theUrl){var xmlHttp = new XMLHttpRequest();xmlHttp.open( "GET", theUrl, false );xmlHttp.send( null );return xmlHttp.responseText;}

function donate()
{
if (params.amount) {var currency_value = params.amount;}
else {var currency_value = parseFloat(document.getElementById("donatebox").value);}
if (isNaN(currency_value) == true){currency_value = 0;}
var json = httpGet("https://api.bitcoinaverage.com/ticker/"+currency_code+"/");  // Get bitcoin price
var obj = JSON.parse(json);
var bitcoin_price = obj.ask;
var finalexchange = (currency_value / bitcoin_price).toFixed(5);
var url = "bitcoin:"+ address +"?amount=" + finalexchange;
if (mbits == true){var mbitprice = (finalexchange * 1000).toFixed(2); var donatedisplay = mbitprice.toString() + " mBits to ";}
if (mbits == false){var donatedisplay = finalexchange.toString() + " Bitcoin to ";}
if (link == true){document.getElementById("donatetext").innerHTML ="<br><a href='"+ url + "'> Please send " + donatedisplay + address + "</a>";}
if (qrcode == true){document.getElementById("qrcode").innerHTML = "";}
if (qrcode == true){$('#qrcode').qrcode(url);}
if (popup == true){window.open(url);}
console.log(url);
}

function setCurrency(){document.getElementById("donationbutton").src = 'https://img.shields.io/badge/donate-' + currency_code + '-brightgreen.svg?style=flat-square';}

$(document).keyup(function (e) {
    if ($(".input1:focus") && (e.keyCode === 13)) {
       donate();
    }
 });
