// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

//jQuery.noConflict()

jQuery(document).ready(function() {

jQuery(function ($) {
		$('#basic-modal .modal').click(function (e) {
			$('#basic-modal-content').modal();
			return false;
		});
    });
	$("#menu-hide").click(function() {
		$('#sidemenu').hide("slow", function(){
			$('#content').css("margin-left", 0);
			$('#menu-show').css("display", "block");
		});		
	});

	$("#menu-show").click(function() {
		$('#content').css("margin-left", 300);
		$('#sidemenu').show("slow");
		$('#menu-show').css("display", "none");
    
});

$(".loader a").click(function() {
  $('#loading').show();
});


//$('#notice').click(function(){
//$('#notice').slideToggle('slow');
//})

if ($('#notice').text()==''){
$('#notice').hide();
}

//new lay



$('.hb').click(function(){
//$('.s_menu').hide(); 
$('.course').hide();
$('.admin').hide();
$('.vms').hide();
$('.home').show();
$('.b_menu').removeClass('current_tab');
$('.hb').addClass('current_tab');
})

$('.cb').click(function(){
//$('.s_menu').hide();  
$('.course').show();
$('.admin').hide();
$('.vms').hide();
$('.home').hide();
//$('.course').slideToggle('slow');
$('.b_menu').removeClass('current_tab');
$('.cb').addClass('current_tab');
})

$('.vb').click(function(){
//$('.s_menu').hide();  
//$('.vm').slideToggle('slow');
$('.course').hide();
$('.admin').hide();
$('.vms').show();
$('.home').hide();
$('.b_menu').removeClass('current_tab');
$('.vb').addClass('current_tab');
})

$('.ab').click(function(){
//$('.s_menu').hide();  
//$('.admin').slideToggle('slow');
$('.course').hide();
$('.admin').show();
$('.vms').hide();
$('.home').hide();
$('.b_menu').removeClass('current_tab');
$('.ab').addClass('current_tab');
})

if ($.trim($('#menu-head').text())==''){
$('#sidemenu').hide();
$('#content').css("margin-left", 0);
$('#menu-show').hide();
$('#content').removeClass('side_visible');
}
//document ready
});
