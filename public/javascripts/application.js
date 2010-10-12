// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults


function showDialog(title, msg, type) {
	$("#dialog").empty();

	$("#dialog").append("<p>" + msg + "</p>");


	$("#dialog").dialog({
		modal: true,
		title: title,
		dialogClass: type,
		buttons: {
			"Close": function() {
				$(this).dialog("close");
			}
		}
	});
}

$(document).ready(function(){
	jQuery(function ($) {
		$('#basic-modal .modal').click(function (e) {
			$('#basic-modal-content').modal();
			return false;
		});
	});


	$("#menu-hide").click(function() {
		$('#left').hide("slow", function(){
			$('#right').css("margin-left", 0);
			$('#menu-show').css("display", "block");
		});		
	});

	$("#menu-show").click(function() {
		$('#right').css("margin-left", 300);
		$('#left').show("slow");
		$('#menu-show').css("display", "none");
	});


});
