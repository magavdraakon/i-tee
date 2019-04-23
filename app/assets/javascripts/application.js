// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery3
//= require jquery_ujs
//= require turbolinks
//= require marked
//= require prettify
// require_tree .

var remote_timeout = '';


function setCookie(cname, cvalue, exdays, path) {
	var d = new Date();
	d.setTime(d.getTime() + (exdays * 24 * 60 * 60 * 1000));
	var expires = "expires=" + d.toUTCString();
	document.cookie = cname + "=" + cvalue + "; " + expires + "; path=" + path;
}

function getCookie(cname) {
	var name = cname + "=";
	var ca = document.cookie.split(';');
	for(var i = 0; i < ca.length; i++) {
		var c = ca[i];
		while(c.charAt(0) == ' ') c = c.substring(1);
		if(c.indexOf(name) == 0) return c.substring(name.length, c.length);
	}
	return "";
}

function ready() {
	resolution = getCookie("resolution");
	console.log(resolution);
	if(resolution == "") {
		setCookie("resolution", screen.width + "x" + screen.height, 1, "/")
	}

	if(document.getElementById('search-form')) {
		// when there is a search form, load autocomplete with the default / refilled value
		load_form($("#search-form select").val());
	}

	$("#menu-hide").click(function() {
		$('#sidemenu').hide(0, function() {
			$('#content').animate({"margin-left": 0}, 500);
			$('#menu-show').css("display", "block");
		});
	});

	$("#menu-show").click(function() {
		$('#menu-show').css("display", "none");
		$('#content').animate({"margin-left": 300}, 500, function() {
			$('#sidemenu').show(0);
		});
	});

	$(".loader a").click(function() {
		$('#loading').show();
	});

	if($('#notice').text() == '') {
		$('#notice').hide();
	}

	if($('#alert').text() == '') {
		$('#alert').hide();
	}

	if($.trim($('#menu-head').text()) == '') {
		$('#sidemenu').hide();
		$('#content').css("margin-left", 0);
		$('#menu-show').hide();
		$('#content').removeClass('side_visible');
	}

	if($("#lab_short_description").length > 0) {
		// validate lab short description lenght only if there is such div
		var character_limit = 255;
		var description = $('#lab_short_description');
		var left = (character_limit - description.val().length);
		$('#charleft').text(left);
	}

// validate input lenght
	$('#lab_short_description').keydown(function() {
		var characters_left = (character_limit - description.val().length);
		if(characters_left >= 0) {
			$('#charleft').text(characters_left);
		} else {
			description.val(description.val().substring(0, 255));
			$('#charleft').css({color: "red"});
			clearTimeout(character_flash);
			var character_flash = setTimeout(function() {
				$('#charleft').css({color: "black"});
			}, 900);
			return false;
		}
	});

	marked.setOptions({
		gfm: true,
		tables: true,
		breaks: false,
		pedantic: false,
		sanitize: true,
		smartLists: true,
		langPrefix: 'language-',
		highlight: function(code, lang) {
			if(lang === 'js') {
				return highlighter.javascript(code);
			}
			return code;
		}
	});

// go over all marked class elements
	$(".marked").each(function() {
		//console.log($(this).text());
		$(this).html(marked($(this).text()).split('<a href="').join('<a target="_blank" href="'));

	});

// go over all the code examples, add classes depending on where it is situated at
	$(".marked code").each(function() {
		// all code should use the prettyprint lib
		$(this).addClass("prettyprint");
		//console.log($(this).parent()[0].tagName);
		// but only code with multiple lines should have line numbers
		if($(this).parent()[0].tagName != "P") {
			$(this).addClass("linenums");
		}
	});

	prettyPrint();
	hideOtherOsButtons();
}

function shownotice(html) {
// override the messages div content. all other notices will be removed
	$("#messages").html("<div escape=\"false\" id=\"flash_notice\"></div>");
	$("#flash_notice").html(html);
}

// search select all/none
function toggle_checked_all(el) {
	$('.found input[type=checkbox]').prop('checked', el.checked);
}
// search
function expandnext(el) {
	$(el).parents("tr").next("tr").toggle();
	if($(el).text() == "Expand")
		$(el).text("Collapse");
	else
		$(el).text("Expand");
}
// search token
function show_date(el) {
	if(el.checked) $("#expires").show();
	else  $("#expires").hide();
}
// search lower half
function manage_checkboxes(inactive) {
	$.each(inactive, function(index, id) {
		document.getElementById(id).checked = false;
	});
 
}

function load_form(For) {
	if(For == "User") {
		$('#u').show();
		$('#l').hide();
		$('#h').hide();
	} else if(For == "Lab") {
		$('#u').hide();
		$('#l').show();
		$('#h').show();
	} else {
		// lab user
		$('#u').show();
		$('#l').show();
		$('#h').hide();
	}
}

function get_vm_info(el, id) {
	var to = $(el).parents("tr").next("tr");
	if($(el).text() == "Expand") {
		$(el).text("Collapse");
		$.getJSON('/lab_users/' + id + ".json", function(data) {
			var html = "";
			$.each(data, function(index, cat) {

				html += "<div>";
				html += '<b class="upper">' + index + " machines</b><br/>";
				if(cat.length < 1) {
					html += "None<br/>";
				} else {
					$.each(cat, function(id, el) {
						var vm = el.vm;
						//console.log(vm);
						html += vm.name;
						if(index == "running")
							html += ' <b>RDP info:</b> elab.itcollege.ee:' + vm.port + ' <b>username:</b> ' + vm.username + ' <b>password:</b> ' + vm.password +
								' <a href="/pause_vm/' + vm.id + '" class="button pause-button">Pause</a>' +
								' <a href="/stop_vm/' + vm.id + '" class="button stop-button">Stop</a>' +
								' <a href="/rdp_reset/' + vm.id + '" class="button stop-button">Reset RDP</a>';
						else if(index == "paused") {
							html += ' <a href="/resume_vm/' + vm.id + '" class="button start-button">Resume</a>'
						} else { // stopped
							html += ' <a href="/start_vm/' + vm.id + '" class="button start-button">Start</a>';
						}
						html += "<br/>";

					});
				}
				html += "</div>";

			});
			to.children('td').html(html);
		});
	} else {
		$(el).text("Expand");
	}

	to.toggle();
}

// add users by lab
function manage_checked(status, message) {
	if(confirm(message)) {
		$('.user_li input[type=checkbox]').prop('checked', status);
	}
}

// show users
function show_names(event, letter) {
	event.preventDefault();
	if(letter == '*') { // show all
		$('.user_li').show();
	} else {
		$('.user_li').hide();
		if(letter == "checked") { // show only selected
			$('.user_li input:checked').parents('.user_li').show();
		} else { // show based on letter
			$('.letter_' + letter).show();
		}
	}

}

// add networks to vmt in edit / new lab
function add_network_to_vmt(el) {
	var n = $(el).parents('.vmt').find('.network').size();
	var p = $(".vmt").index($(el).parents('.vmt'));
	var options = $("#networks").html();
	var innerHtml = [ ];

	/* network id */
	innerHtml.push('<label for="lab_lab_vmts_attributes_' + p + '_lab_vmt_networks_attributes_' + n + '_network_id">Network</label> ' +
		'<select id="lab_lab_vmts_attributes_' + p + '_lab_vmt_networks_attributes_' + n + '_network_id" name="lab[lab_vmts_attributes][' + p + '][lab_vmt_networks_attributes][' + n + '][network_id]">' + options + '</select><br/>');

	/* slot */
	innerHtml.push('<label for="lab_lab_vmts_attributes_' + p + '_lab_vmt_networks_attributes_' + n + '_slot">Slot</label> ' +
		'<input type="number" id="lab_lab_vmts_attributes_' + p + '_lab_vmt_networks_attributes_' + n + '_slot" name="lab[lab_vmts_attributes][' + p + '][lab_vmt_networks_attributes][' + n + '][slot]" size="30" min="1" /><br/>');

	/* IP */
	innerHtml.push('<label for="lab_lab_vmts_attributes_' + p + '_lab_vmt_networks_attributes_' + n + '_ip">IP</label> ' +
		'<textarea id="lab_lab_vmts_attributes_' + p + '_lab_vmt_networks_attributes_' + n + '_ip" name="lab[lab_vmts_attributes][' + p + '][lab_vmt_networks_attributes][' + n + '][ip]"></textarea><br/>');

	/* promiscuous */
	innerHtml.push('<input type="hidden" name="lab[lab_vmts_attributes][' + p + '][lab_vmt_networks_attributes][' + n + '][promiscuous]" value="0" />' +
		'<input type="checkbox" id="lab_lab_vmts_attributes_' + p + '_lab_vmt_networks_attributes_' + n + '_promiscuous" name="lab[lab_vmts_attributes][' + p + '][lab_vmt_networks_attributes][' + n + '][promiscuous]" value="1" />' +
		' <label for="lab_lab_vmts_attributes_' + p + '_lab_vmt_networks_attributes_' + n + '_promiscuous">Promiscuous</label><br/>');

	/* reinit mac */
	innerHtml.push('<input type="hidden" name="lab[lab_vmts_attributes][' + p + '][lab_vmt_networks_attributes][' + n + '][reinit_mac]" value="0" />' +
		'<input type="checkbox" id="lab_lab_vmts_attributes_' + p + '_lab_vmt_networks_attributes_' + n + '_reinit_mac" name="lab[lab_vmts_attributes][' + p + '][lab_vmt_networks_attributes][' + n + '][reinit_mac]" value="1" />' +
		' <label for="lab_lab_vmts_attributes_' + p + '_lab_vmt_networks_attributes_' + n + '_reinit_mac">Reinit mac</label><br/><br/>');

	/* delete */
	innerHtml.push('<input type="hidden" name="lab[lab_vmts_attributes][' + p + '][lab_vmt_networks_attributes][' + n + '][_destroy]" value="0" />' +
		'<input type="checkbox" id="lab_lab_vmts_attributes_' + p + '_lab_vmt_networks_attributes_' + n + '__destroy" name="lab[lab_vmts_attributes][' + p + '][lab_vmt_networks_attributes][' + n + '][_destroy]" value="1" />' +
		' <label for="lab_lab_vmts_attributes_' + p + '_lab_vmt_networks_attributes_' + n + '__destroy">Remove</label><br/>');

	$(el).parents('.vmt').find('.networks').append('<div class="network">' + innerHtml.join('') + '</div>');
}

function add_drive_to_vmt(el){
	var n = $(el).parents('.vmt').find('.drive').size();
	var p = $(".vmt").index($(el).parents('.vmt'));
	var s_options = $("#storages").html();
	var c_options = $("#controllers").html();
	var innerHtml = [ ];

	/* storage id */
	innerHtml.push('<label for="lab_lab_vmts_attributes_' + p + '_lab_vmt_storages_attributes_' + n + '_storage_id">Storage</label> ' +
		'<select id="lab_lab_vmts_attributes_' + p + '_lab_vmt_storages_attributes_' + n + '_storage_id" name="lab[lab_vmts_attributes][' + p + '][lab_vmt_storages_attributes][' + n + '][storage_id]">' + s_options + '</select><br/>');

	/* controller */
	innerHtml.push('<label for="lab_lab_vmts_attributes_' + p + '_lab_vmt_storages_attributes_' + n + '_controller">Controller</label> ' +
		'<select id="lab_lab_vmts_attributes_' + p + '_lab_vmt_storages_attributes_' + n + '_controller" name="lab[lab_vmts_attributes][' + p + '][lab_vmt_storages_attributes][' + n + '][controller]">' + c_options + '</select><br/>');

	/* port */
	innerHtml.push('<label for="lab_lab_vmts_attributes_' + p + '_lab_vmt_storages_attributes_' + n + '_port">Port</label> ' +
		'<input type="number" id="lab_lab_vmts_attributes_' + p + '_lab_vmt_storages_attributes_' + n + '_port" name="lab[lab_vmts_attributes][' + p + '][lab_vmt_storages_attributes][' + n + '][port]" size="30" min="0" /><br/>');

	/* device */
	innerHtml.push('<label for="lab_lab_vmts_attributes_' + p + '_lab_vmt_storages_attributes_' + n + '_device">Device</label> ' +
		'<input type="number" id="lab_lab_vmts_attributes_' + p + '_lab_vmt_storages_attributes_' + n + '_device" name="lab[lab_vmts_attributes][' + p + '][lab_vmt_storages_attributes][' + n + '][device]" size="30" min="0" /><br/>');

	/* mount */
	innerHtml.push('<label for="lab_lab_vmts_attributes_' + p + '_lab_vmt_storages_attributes_' + n + '_mount">Mount</label> ' +
		'<textarea id="lab_lab_vmts_attributes_' + p + '_lab_vmt_storages_attributes_' + n + '_mount" name="lab[lab_vmts_attributes][' + p + '][lab_vmt_storages_attributes][' + n + '][mount]" ></textarea><br/><br/>');


	/* delete */
	innerHtml.push('<input type="hidden" name="lab[lab_vmts_attributes][' + p + '][lab_vmt_storages_attributes][' + n + '][_destroy]" value="0" />' +
		'<input type="checkbox" id="lab_lab_vmts_attributes_' + p + '_lab_vmt_storages_attributes_' + n + '__destroy" name="lab[lab_vmts_attributes][' + p + '][lab_vmt_storages_attributes][' + n + '][_destroy]" value="1" />' +
		' <label for="lab_lab_vmts_attributes_' + p + '_lab_vmt_storages_attributes_' + n + '__destroy">Remove</label><br/>');

	$(el).parents('.vmt').find('.drives').append('<div class="drive">' + innerHtml.join('') + '</div>');
}

// add vmts to lab in edit/new lab
function add_vmt_to_lab() {
	var n = $("#lab_vmts").find('.vmt').size();
	var vmt_template_options = $("#vm_templates").html();
	var g_type_options = $("#g_types").html();
	var innerHtml = [ ];

	/* delete */
	innerHtml.push('<div class="right">' +
		'<input type="hidden" name="lab[lab_vmts_attributes][' + n + '][_destroy]" value="0"/>' +
		'<input type="checkbox" id="lab_lab_vmts_attributes_' + n + '__destroy" name="lab[lab_vmts_attributes][' + n + '][_destroy]" value="1" /> ' +
		'<label for="lab_lab_vmts_attributes_' + n + '__destroy">Remove</label>' +
		'</div>');

	/* name */
	innerHtml.push('<label for="lab_lab_vmts_attributes_' + n + '_name">Name</label> ' +
		'<input type="text" id="lab_lab_vmts_attributes_' + n + '_name" name="lab[lab_vmts_attributes][' + n + '][name]" size="30" placeholder="Unique, alphanumeric with no spaces" /><br/>');

	/* nickname */
	innerHtml.push('<label for="lab_lab_vmts_attributes_' + n + '_nickname">Nickname</label> ' +
		'<input type="text" id="lab_lab_vmts_attributes_' + n + '_nickname" name="lab[lab_vmts_attributes][' + n + '][nickname]" size="30" placeholder="Name shown to user" /><br/>');

	/* vmt template */
	innerHtml.push('<label for="lab_lab_vmts_attributes_' + n + '_vmt_id">Vmt</label> ' +
		'<select id="lab_lab_vmts_attributes_' + n + '_vmt_id" name="lab[lab_vmts_attributes][' + n + '][vmt_id]">' + vmt_template_options + '</select><br/>');

	/* expose uuid */
	innerHtml.push('<label for="lab_lab_vmts_attributes_' + n + '_expose_uuid">Expose uuid</label> ' +
		'<input type="hidden" name="lab[lab_vmts_attributes][' + n + '][expose_uuid]" value="0" />' +
		'<input type="checkbox" id="lab_lab_vmts_attributes_' + n + '_expose_uuid" name="lab[lab_vmts_attributes][' + n + '][expose_uuid]" value="1" /><br/>');

	/* allow remote */
	innerHtml.push('<label for="lab_lab_vmts_attributes_' + n + '_allow_remote">Allow remote</label> ' +
		'<input type="hidden" name="lab[lab_vmts_attributes][' + n + '][allow_remote]" value="0" />' +
		'<input type="checkbox" id="lab_lab_vmts_attributes_' + n + '_allow_remote" name="lab[lab_vmts_attributes][' + n + '][allow_remote]" checked="checked" value="1" /><br/>');

	/* allow restart */
	innerHtml.push('<label for="lab_lab_vmts_attributes_' + n + '_allow_restart">Allow restart</label> ' +
		'<input type="hidden" name="lab[lab_vmts_attributes][' + n + '][allow_restart]" value="0" />' +
		'<input type="checkbox" id="lab_lab_vmts_attributes_' + n + '_allow_restart" name="lab[lab_vmts_attributes][' + n + '][allow_restart]" checked="checked" value="1" /><br/>');

	/* primary */
	innerHtml.push('<label for="lab_lab_vmts_attributes_' + n + '_primary">Primary</label> ' +
		'<input type="hidden" name="lab[lab_vmts_attributes][' + n + '][primary]" value="0" />' +
		'<input type="checkbox" id="lab_lab_vmts_attributes_' + n + '_primary" name="lab[lab_vmts_attributes][' + n + '][primary]" value="1" /><br/>');

	/* guacamole connection type */
	innerHtml.push('<label for="lab_lab_vmts_attributes_' + n + '_g_type">Guacamole connection</label> ' +
		'<select id="lab_lab_vmts_attributes_' + n + '_g_type" name="lab[lab_vmts_attributes][' + n + '][g_type]">' + g_type_options + '</select><br/>');

	/* order */
	innerHtml.push('<label for="lab_lab_vmts_attributes_' + n + '_position">Position</label> '
		+ '<input type="number" id="lab_lab_vmts_attributes_' + n + '_position" name="lab[lab_vmts_attributes][' + n + '][position]" size="30" value="0" /><br/>');

	/* networks holder */
	innerHtml.push('<div class="networks" />');

	$("#lab_vmts").append('<div class="vmt">' + innerHtml.join('') + '</div>');

	var s = document.createElement('span');
	s.innerHTML = 'Add more networks';
	s.setAttribute('class', 'button add-button');
	s.onclick = function() {
		add_network_to_vmt(this);
	};
	$(".vmt").last().append(s);
	s.click();

	$(".vmt").last().append('<div class="drives" />');
	var d = document.createElement('span');
	d.innerHTML = 'Add more drives';
	d.setAttribute('class', 'button add-button');
	d.onclick = function() {
		add_drive_to_vmt(this);
	};
	$(".vmt").last().append(d);
	d.click();
}

function show_remote(el, html) {
// override the messages div content. all other notices will be removed
	$(el).siblings('.remote').find(".commands").html(html);
	$(el).siblings('.remote').find(".hidden").show();
	makeCopy($(el).siblings('.remote').get(0)); // make it selectable
}

// return operating system name
function getOs() {
	var OSName = "Unknown OS";
	if(navigator.platform.indexOf("Win") != -1) OSName = "Windows";
	if(navigator.platform.indexOf("Mac") != -1) OSName = "MacOS";
	if(navigator.platform.indexOf("X11") != -1) OSName = "UNIX";
	if(navigator.platform.indexOf("Linux") != -1) OSName = "Linux";
	return OSName;
}

// highlight text in an element
function SelectText(element) {
	var doc = document, range, selection;
	if(doc.body.createTextRange) {
		range = document.body.createTextRange();
		range.moveToElementText(element);
		range.select();
	} else if(window.getSelection) {
		selection = window.getSelection();
		range = document.createRange();
		range.selectNodeContents(element);
		selection.removeAllRanges();
		selection.addRange(range);
	}
}

// change text in an element for a period of time
function changeFor(el, newtext, time) {
	var old = el.innerHTML;
	el.innerHTML = newtext;
	var oldclass = el.getAttribute("class");
	el.setAttribute("class", oldclass + " important");
	setTimeout(function() {
		el.innerHTML = old;
		el.setAttribute("class", oldclass);
	}, time);
}

// generate eventlisteners for text copying
function makeCopy(el) {
	el.addEventListener('click', function(event) {
		var help = this.getElementsByClassName("helptext")[0];
		var copy = this.getElementsByClassName("copy")[0];
		SelectText(copy); // use the other fn to select the first span
		try {
			var successful = document.execCommand('copy');
			// works in:  chrome 42+, ff 41+, ie 9.0+, opera 29.0+, not supported in safari
			if(successful) { // change text in the second span
				changeFor(help, "Copied", 5000);
			} else {
				changeFor(help, (getOs() == "MacOS" ? "Press ⌘ + c" : "Press Ctrl + c"), 5000);
			}
			console.log('Copying text command was ' + (successful ? 'successful' : 'unsuccessful'));
		} catch(err) {
			console.log('Oops, unable to copy');
			// if you cant copy, then show the notice to ctrl+c
			changeFor(help, (getOs() == "MacOS" ? "Press ⌘ + c" : "Press Ctrl + c"), 5000);
		}
	});
}

function hideOtherOsButtons() {
	// hide remote desktop buttons for other os-s
	if(getOs() != "Unknown OS") {
		$(".remote_connections .button").hide();
		$(".remote_connections ." + getOs()).show();
	} else {
		$(".showtoggle").hide();
	}
}

function toggleOtherOsButtons(el) {
	// hide remote desktop buttons for other os-s
	if(getOs() != "Unknown OS") {
		$(el).parent(".remote_connections").find(".button").toggle();
		$(".remote_connections ." + getOs()).show();
		if(el.innerHTML == "&lt; more")
			el.innerHTML = "less &gt;";
		else
			el.innerHTML = "&lt; more";
	}
}



//$(document).ready(ready)
//$(document).on('page:load', function(){ready(); console.log('page:load')})
$(document).on('turbolinks:load',function(){ready();})
