// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

//jQuery.noConflict()

var remote_timeout='';

jQuery(document).ready(function() {
  if (document.getElementById('search-form')){
    // when there is a search form, load autocomplete with the default / refilled value
    load_form($("#search-form select").val());
  }

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

if ($('#alert').text()==''){
$('#alert').hide();
}


if ($.trim($('#menu-head').text())==''){
$('#sidemenu').hide();
$('#content').css("margin-left", 0);
$('#menu-show').hide();
$('#content').removeClass('side_visible');
}

if ($("#lab_short_description").length > 0){
  // validate lab short description lenght only if there is such div
  var character_limit = 255;
  var description = $('#lab_short_description');
  var left = (character_limit-description.val().length);
  $('#charleft').text(left);
}

// validate input lenght
$('#lab_short_description').keydown(function(){
       
        var characters_left = (character_limit-description.val().length);
        if(characters_left >= 0){
            $('#charleft').text(characters_left);
        } else {
            description.val(description.val().substring(0,255));
            $('#charleft').css({ color: "red"});
            clearTimeout(character_flash);
            character_flash = setTimeout(function(){
                $('#charleft').css({ color: "black"});
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
    if (lang === 'js') {
      return highlighter.javascript(code);
    }
    return code;
  }
});
//console.log(marked('i am using __markdown__.'));




// go over all marked class elements
$(".marked").each(function(){
  //console.log($(this).text());
  $(this).html(marked($(this).text()));

});

// go over all the code examples, add classes depending on where it is situated at
$(".marked code").each(function(){
  // all code should use the prettyprint lib
  $(this).addClass("prettyprint");
  //console.log($(this).parent()[0].tagName);
  // but only code with multiple lines should have line numbers
  if ($(this).parent()[0].tagName!="P"){
    $(this).addClass("linenums");
  }
});

prettyPrint();
//document ready
});


function shownotice(html){
// override the messages div content. all other notices will be removed
  $("#messages").html("<div escape=\"false\" id=\"flash_notice\"></div>");
  $("#flash_notice").html(html);
}

function show_remote(el, html){
// override the messages div content. all other notices will be removed
    $(el).siblings('.remote').html(html);
   /* if (remote_timeout!='') {
        clearTimeout(remote_timeout);
        console.log('cleared');
    }
    remote_timeout= setTimeout(function() {
        $(el).siblings('.remote').html('Choose a remote connection type from above');
    }, 10000);*/
}

// search select all/none
function toggle_checked_all(el){
   $('.found input[type=checkbox]').prop('checked', el.checked);
}
// search
function expandnext(el){
  $(el).parents("tr").next("tr").toggle();
  if ( $(el).text()=="Expand") 
     $(el).text("Collapse")
  else 
     $(el).text("Expand")
}
// search token
function show_date(el){
  if (el.checked) $("#expires").show();
  else  $("#expires").hide();
}
// search lower half
function manage_checkboxes(inactive){
  $.each(inactive, function( index, id ) {
    document.getElementById(id).checked=false;
  });
 
}

function load_form(For){
  if (For=="User") {
    $('#u').show();
    $('#l').hide();
    $('#h').hide();
  } else if (For=="Lab") {
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

function get_vm_info(el, id){
    to=$(el).parents("tr").next("tr");
    if ( $(el).text()=="Expand"){
        $(el).text("Collapse");
        $.getJSON('/lab_users/'+id+".json", function(data) {
            html="";
            $.each(data, function(index, cat){

                html+="<div>";
                html+='<b class="upper">'+index+" machines</b><br/>";
                if (cat.length<1){
                    html+="None<br/>";
                } else {
                    $.each(cat, function(id, el){
                        vm=el.vm;
                        //console.log(vm);
                        html+= vm.name;
                        if (index=="running")
                         html+=' <b>RDP info:</b> elab.itcollege.ee:'+vm.port+' <b>username:</b> '+vm.username+' <b>password:</b> '+vm.password+
                                ' <a href="/pause_vm/'+vm.id+'" class="button pause-button">Pause</a>'+
                                ' <a href="/stop_vm/'+vm.id+'" class="button stop-button">Stop</a>';
                        else if (index=="paused"){
                            html+=' <a href="/resume_vm/'+vm.id+'" class="button start-button">Resume</a>'
                        } else { // stopped
                            html+=' <a href="/start_vm/'+vm.id+'" class="button start-button">Start</a>';
                        }
                        html+="<br/>";

                    });
                }
                html+="</div>";

            });
            to.children('td').html(html);
        });
    } else{
        $(el).text("Expand");
    }

    to.toggle();

}


// add users by lab
function manage_checked(status, message){
    if(confirm(message)){
        $('.user_li input[type=checkbox]').prop('checked', status);
    }
}

// show users
function show_names(letter){
    if (letter=='*') { // show all
        $('.user_li').show();
    } else {
        $('.user_li').hide();
        if (letter=="checked"){ // show only selected
            $('.user_li input:checked').parents('.user_li').show();
        } else { // show based on letter
            $('.letter_'+letter).show();
        }
    }

}


// add networks to vmt in edit / new lab
function add_network_to_vmt(el){
    var n= $(el).parents('.vmt').find('.network').size();
    var p= $(".vmt").index($(el).parents('.vmt'));
    var options=$("#networks").html();
    console.log("sellel on võrke hetkel", n, 'vanem:', p);
    $(el).parents('.vmt').find('.networks').append("<div class=\"network\"><label for=\"lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_network_id\">Network</label> <select id=\"lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_network_id\" name=\"lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][network_id]\">"+options+"</select> <br/><label for=\"lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_slot\">Slot</label> <input id=\"lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_slot\" name=\"lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][slot]\" size=\"30\" type=\"number\" /><br/> <input name=\"lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][promiscuous]\" type=\"hidden\" value=\"0\" /><input id=\"lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_promiscuous\" name=\"lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][promiscuous]\" type=\"checkbox\" value=\"1\" /> <label for=\"lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_promiscuous\">Promiscuous</label><br /> <input name=\"lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][reinit_mac]\" type=\"hidden\" value=\"0\" /><input id=\"lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_reinit_mac\" name=\"lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][reinit_mac]\" type=\"checkbox\" value=\"1\" /> <label for=\"lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_reinit_mac\">Reinit mac</label><br /> <br/>  <input name=\"lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][_destroy]\" type=\"hidden\" value=\"0\" /><input id=\"lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"__destroy\" name=\"lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][_destroy]\" type=\"checkbox\" value=\"1\" />  <label for=\"lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"__destroy\">Remove</label> </div>");
   // $("#images").append("<div class=\"image\"> <label for=\"item_images_attributes_"+n+"_layer_id\">Layer</label> <select id=\"item_images_attributes_"+n+"_layer_id\" name=\"item[images_attributes]["+n+"][layer_id]\">"+$("#item_layer_id").html()+"</select> <br> <label for=\"item_images_attributes_"+n+"_part\">Part</label> <input id=\"item_images_attributes_"+n+"_part\" name=\"item[images_attributes]["+n+"][part]\" type=\"number\" /> <br> <label for=\"item_images_attributes_"+n+"_partname\">Part name</label> <input id=\"item_images_attributes_"+n+"_partname\" name=\"item[images_attributes]["+n+"][partname]\" type=\"text\" /> <br> <input class=\"female\" id=\"item_images_attributes_"+n+"_f_img\" name=\"item[images_attributes]["+n+"][f_img]\" type=\"file\" /> <br> <input class=\"male\" id=\"item_images_attributes_"+n+"_m_img\" name=\"item[images_attributes]["+n+"][m_img]\" type=\"file\" /></div> ");
}

// add vmts to lab in edit/new lab
function add_vmt_to_lab(){
    var n= $("#lab_vmts").find('.vmt').size();
    console.log('on ', n);
    var options=$("#vm_templates").html();
    $("#lab_vmts").append("<div class=\"vmt\">  <div class=\"right\"> <input name=\"lab[lab_vmts_attributes]["+n+"][_destroy]\" type=\"hidden\" value=\"0\" /><input id=\"lab_lab_vmts_attributes_"+n+"__destroy\" name=\"lab[lab_vmts_attributes]["+n+"][_destroy]\" type=\"checkbox\" value=\"1\" />  <label for=\"lab_lab_vmts_attributes_"+n+"__destroy\">Remove</label></div><label for=\"lab_lab_vmts_attributes_"+n+"_name\">Name</label> <input id=\"lab_lab_vmts_attributes_"+n+"_name\" name=\"lab[lab_vmts_attributes]["+n+"][name]\" size=\"30\" title=\"Name for the template in this lab. Alphanumeric with no spaces.\" type=\"text\" /><br/><label for=\"lab_lab_vmts_attributes_"+n+"_vmt_id\">Vmt</label> <select id=\"lab_lab_vmts_attributes_"+n+"_vmt_id\" name=\"lab[lab_vmts_attributes]["+n+"][vmt_id]\">"+options+"</select><br/><br/><div class=\"networks\"></div></div>");
    s=document.createElement('span');
    s.innerHTML='Add more networks';
    s.setAttribute('class', 'button add-button');
    s.onclick=function(){
        add_network_to_vmt(this);
    };
    $(".vmt").last().append(s);
    s.click();
}
