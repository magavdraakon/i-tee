// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

//jQuery.noConflict()

var remote_timeout='';

jQuery(document).ready(function() {
  if (document.getElementById('search-form')){
    // when there is a search form, load autocomplete with the default / refilled value
    load_form($("#search-form select").val());
  }

	$("#menu-hide").click(function() {
		$('#sidemenu').hide(0,function(){
            $('#content').animate({"margin-left": 0}, 500);
			$('#menu-show').css("display", "block");
		});		
	});

	$("#menu-show").click(function() {
        $('#menu-show').css("display", "none");
		$('#content').animate({"margin-left": 300}, 500, function(){
            $('#sidemenu').show(0);

        });

    
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
            var character_flash = setTimeout(function(){
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
  $(this).html(marked($(this).text()).split('<a href="').join('<a target="_blank" href="'));

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
/* added 6. sept 2015*/
   //makeCopy(); // make elements clickable
    hideOtherOsButtons();

});


function shownotice(html){
// override the messages div content. all other notices will be removed
  $("#messages").html("<div escape=\"false\" id=\"flash_notice\"></div>");
  $("#flash_notice").html(html);
}



// search select all/none
function toggle_checked_all(el){
   $('.found input[type=checkbox]').prop('checked', el.checked);
}
// search
function expandnext(el){
  $(el).parents("tr").next("tr").toggle();
  if ( $(el).text()=="Expand") 
     $(el).text("Collapse");
  else 
     $(el).text("Expand");
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
    var to=$(el).parents("tr").next("tr");
    if ( $(el).text()=="Expand"){
        $(el).text("Collapse");
        $.getJSON('/lab_users/'+id+".json", function(data) {
           var html="";
            $.each(data, function(index, cat){

                html+="<div>";
                html+='<b class="upper">'+index+" machines</b><br/>";
                if (cat.length<1){
                    html+="None<br/>";
                } else {
                    $.each(cat, function(id, el){
                        var vm=el.vm;
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
    //console.log("sellel on võrke hetkel", n, 'vanem:', p);

    var net_holder=document.createElement('div');
    net_holder.setAttribute("class", "network");

    /* network id */
    var netL=document.createElement("label");
    netL.setAttribute("for", "lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_network_id");
    netL.innerHTML="Network";

    var net=document.createElement("select");
    net.setAttribute("id", "lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_network_id");
    net.setAttribute("name", "lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][network_id]");
    net.innerHTML=options;

    net_holder.appendChild(netL);
    net_holder.appendChild(document.createTextNode(" "));
    net_holder.appendChild(net);
    net_holder.appendChild( document.createElement("br") );
    /* slot */
    var slotL=document.createElement("label");
    slotL.setAttribute("for", "lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_slot");
    slotL.innerHTML="Slot";

    var slot=document.createElement("input");
    slot.setAttribute("id", "lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_slot");
    slot.setAttribute("name", "lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][slot]");
    slot.setAttribute("type", "number");
    slot.setAttribute("size", 30);
   
    net_holder.appendChild(slotL);
    net_holder.appendChild(document.createTextNode(" "));
    net_holder.appendChild(slot);
    net_holder.appendChild( document.createElement("br") );
    /* promiscous */
    var promL=document.createElement("label");
    promL.setAttribute("for", "lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_promiscuous");
    promL.innerHTML="Promiscuous";

    var promH=document.createElement("input");
    promH.setAttribute("name", "lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][promiscuous]");
    promH.setAttribute("type", "hidden");
    promH.setAttribute("value", 0);

    var promV=document.createElement("input");
    promV.setAttribute("id", "lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_promiscuous");
    promV.setAttribute("name", "lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][promiscuous]");
    promV.setAttribute("type", "checkbox");
    promV.setAttribute("value", 1);

    net_holder.appendChild(promH);
    net_holder.appendChild(document.createTextNode(" "));
    net_holder.appendChild(promV);
    net_holder.appendChild(document.createTextNode(" "));
    net_holder.appendChild(promL);
    net_holder.appendChild( document.createElement("br") );
    /* reinit mac */
    var macL=document.createElement("label");
    macL.setAttribute("for", "lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_reinit_mac");
    macL.innerHTML="Reinit mac";

    var macH=document.createElement("input");
    macH.setAttribute("name", "lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][reinit_mac]");
    macH.setAttribute("type", "hidden");
    macH.setAttribute("value", 0);

    var macV=document.createElement("input");
    macV.setAttribute("id", "lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_reinit_mac");
    macV.setAttribute("name", "lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][reinit_mac]");
    macV.setAttribute("type", "checkbox");
    macV.setAttribute("value", 1);

    net_holder.appendChild(macH);
    net_holder.appendChild(document.createTextNode(" "));
    net_holder.appendChild(macV);
    net_holder.appendChild(document.createTextNode(" "));
    net_holder.appendChild(macL);
    net_holder.appendChild( document.createElement("br") );
    net_holder.appendChild( document.createElement("br") );
    /* delete */
    var delH=document.createElement("input");
    delH.setAttribute("name", "lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][_destroy]");
    delH.setAttribute("type", "hidden");
    delH.setAttribute("value", 0);

    var delV=document.createElement("input");
    delV.setAttribute("id", "lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"__destroy");
    delV.setAttribute("name", "lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][_destroy]");
    delV.setAttribute("type", "checkbox");
    delV.setAttribute("value", 1);

    var delL=document.createElement("label");
    delL.setAttribute("for", "lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"__destroy");
    delL.innerHTML="Remove";

    net_holder.appendChild(delH);
    net_holder.appendChild(document.createTextNode(" "));
    net_holder.appendChild(delV);
    net_holder.appendChild(document.createTextNode(" "));
    net_holder.appendChild(delL);
    /* EOF delete */
    $(el).parents('.vmt').find('.networks').append(net_holder);
    /*
    $(el).parents('.vmt').find('.networks').append("<div class=\"network\"><label for=\"lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_network_id\">Network</label> <select id=\"lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_network_id\" name=\"lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][network_id]\">"+options+"</select> <br/><label for=\"lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_slot\">Slot</label> <input id=\"lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_slot\" name=\"lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][slot]\" size=\"30\" type=\"number\" /><br/> <input name=\"lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][promiscuous]\" type=\"hidden\" value=\"0\" /><input id=\"lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_promiscuous\" name=\"lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][promiscuous]\" type=\"checkbox\" value=\"1\" /> <label for=\"lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_promiscuous\">Promiscuous</label><br /> <input name=\"lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][reinit_mac]\" type=\"hidden\" value=\"0\" /><input id=\"lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_reinit_mac\" name=\"lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][reinit_mac]\" type=\"checkbox\" value=\"1\" /> <label for=\"lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"_reinit_mac\">Reinit mac</label><br /> <br/>  <input name=\"lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][_destroy]\" type=\"hidden\" value=\"0\" /><input id=\"lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"__destroy\" name=\"lab[lab_vmts_attributes]["+p+"][lab_vmt_networks_attributes]["+n+"][_destroy]\" type=\"checkbox\" value=\"1\" />  <label for=\"lab_lab_vmts_attributes_"+p+"_lab_vmt_networks_attributes_"+n+"__destroy\">Remove</label> </div>");
    */
  
}

// add vmts to lab in edit/new lab
function add_vmt_to_lab(){
    var n= $("#lab_vmts").find('.vmt').size();
    console.log('on ', n);
    var options=$("#vm_templates").html();

    var vmt_holder=document.createElement('div');
    vmt_holder.setAttribute("class", "vmt");
    /* DELETE */
    var right=document.createElement("div");
    right.setAttribute("class", "right");

    var delH=document.createElement("input");
    delH.setAttribute("name", "lab[lab_vmts_attributes]["+n+"][_destroy]");
    delH.setAttribute("type", "hidden");
    delH.setAttribute("value", 0);

    var delV=document.createElement("input");
    delV.setAttribute("id", "lab_lab_vmts_attributes_"+n+"__destroy");
    delV.setAttribute("name", "lab[lab_vmts_attributes]["+n+"][_destroy]");
    delV.setAttribute("type", "checkbox");
    delV.setAttribute("value", 1);

    var delL=document.createElement("label");
    delL.setAttribute("for", "lab_lab_vmts_attributes_"+n+"__destroy");
    delL.innerHTML="Remove";

    right.appendChild(delH);
    right.appendChild(document.createTextNode(" "));
    right.appendChild(delV);
    right.appendChild(document.createTextNode(" "));
    right.appendChild(delL);
    /* EOF DELETE*/
    vmt_holder.appendChild(right);
    /* name*/
    var nameL=document.createElement("label");
    nameL.setAttribute("for", "lab_lab_vmts_attributes_"+n+"_name");
    nameL.innerHTML="Name";

    var name=document.createElement("input");
    name.setAttribute("id", "lab_lab_vmts_attributes_"+n+"_name");
    name.setAttribute("name", "lab[lab_vmts_attributes]["+n+"][name]");
    name.setAttribute("type", "text");
    name.setAttribute("size", 30);
    name.setAttribute("placeholder", "Unique, alphanumeric with no spaces.");

    vmt_holder.appendChild(nameL);
    vmt_holder.appendChild(document.createTextNode(" "));
    vmt_holder.appendChild(name);
    vmt_holder.appendChild( document.createElement("br") );
    /* nickname */
    var nicknameL=document.createElement("label");
    nicknameL.setAttribute("for", "lab_lab_vmts_attributes_"+n+"_nickname");
    nicknameL.innerHTML="Nickname";

    var nickname=document.createElement("input");
    nickname.setAttribute("id", "lab_lab_vmts_attributes_"+n+"_nickname");
    nickname.setAttribute("name", "lab[lab_vmts_attributes]["+n+"][nickname]");
    nickname.setAttribute("type", "text");
    nickname.setAttribute("size", 30);
    nickname.setAttribute("placeholder", "Name shown to user.");

    vmt_holder.appendChild(nicknameL);
    vmt_holder.appendChild(document.createTextNode(" "));
    vmt_holder.appendChild(nickname);
    vmt_holder.appendChild( document.createElement("br") );
    /* vmt template */
    var vmtL=document.createElement("label");
    vmtL.setAttribute("for", "lab_lab_vmts_attributes_"+n+"_vmt_id");
    vmtL.innerHTML="Vmt";

    var vmt=document.createElement("select");
    vmt.setAttribute("id", "lab_lab_vmts_attributes_"+n+"_vmt_id");
    vmt.setAttribute("name", "lab[lab_vmts_attributes]["+n+"][vmt_id]");
    vmt.innerHTML=options;

    vmt_holder.appendChild(vmtL);
    vmt_holder.appendChild(document.createTextNode(" "));
    vmt_holder.appendChild(vmt);
    vmt_holder.appendChild( document.createElement("br") );
    /*ALLOW REMOTE*/
    var allowL=document.createElement("label");
    allowL.setAttribute("for", "lab_lab_vmts_attributes_"+n+"_allow_remote");
    allowL.innerHTML="Allow remote";

    var allowH=document.createElement("input");
    allowH.setAttribute("name", "lab[lab_vmts_attributes]["+n+"][allow_remote]");
    allowH.setAttribute("type", "hidden");
    allowH.setAttribute("value", 0);

    var allowV=document.createElement("input");
    allowV.setAttribute("id", "lab_lab_vmts_attributes_"+n+"_allow_remote");
    allowV.setAttribute("name", "lab[lab_vmts_attributes]["+n+"][allow_remote]");
    allowV.setAttribute("type", "checkbox");
    allowV.setAttribute("checked", "checked");
    allowV.setAttribute("value", 1);

    vmt_holder.appendChild(allowL);
    vmt_holder.appendChild(document.createTextNode(" "));
    vmt_holder.appendChild(allowH);
    vmt_holder.appendChild(document.createTextNode(" "));
    vmt_holder.appendChild(allowV);
    vmt_holder.appendChild( document.createElement("br") );
    /* order */
    var orderL=document.createElement("label");
    orderL.setAttribute("for", "lab_lab_vmts_attributes_"+n+"_position");
    orderL.innerHTML="Position";

    var order=document.createElement("input");
    order.setAttribute("id", "lab_lab_vmts_attributes_"+n+"_position");
    order.setAttribute("name", "lab[lab_vmts_attributes]["+n+"][position]");
    order.setAttribute("type", "number");
    order.setAttribute("size", 30);
    order.setAttribute("value", 0);

    vmt_holder.appendChild(orderL);
    vmt_holder.appendChild(document.createTextNode(" "));
    vmt_holder.appendChild(order);
    /* networks holder*/
    var networks=document.createElement("div");
    networks.setAttribute("class", "networks");
    vmt_holder.appendChild(networks);

    console.log(vmt_holder);
/*
$("#lab_vmts").append("<div class=\"vmt\">  <div class=\"right\"> <input name=\"lab[lab_vmts_attributes]["+n+"][_destroy]\" type=\"hidden\" value=\"0\" /><input id=\"lab_lab_vmts_attributes_"+n+"__destroy\" name=\"lab[lab_vmts_attributes]["+n+"][_destroy]\" type=\"checkbox\" value=\"1\" />  <label for=\"lab_lab_vmts_attributes_"+n+"__destroy\">Remove</label></div>      <label for=\"lab_lab_vmts_attributes_"+n+"_name\">Name</label>       <input id=\"lab_lab_vmts_attributes_"+n+"_name\" name=\"lab[lab_vmts_attributes]["+n+"][name]\" size=\"30\" placeholder=\"Unique, alphanumeric with no spaces.\" type=\"text\" />      <br/>       <label for=\"lab_lab_vmts_attributes_"+n+"_nickname\">Nickname</label>       <input id=\"lab_lab_vmts_attributes_"+n+"_nickname\" name=\"lab[lab_vmts_attributes]["+n+"][nickname]\" placeholder=\"Name shown to user.\" size=\"30\" type=\"text\" />      <br/>      <label for=\"lab_lab_vmts_attributes_"+n+"_vmt_id\">Vmt</label>       <select id=\"lab_lab_vmts_attributes_"+n+"_vmt_id\" name=\"lab[lab_vmts_attributes]["+n+"][vmt_id]\">"+options+"</select>      <br/>      <label for=\"lab_lab_vmts_attributes_"+n+"_allow_remote\">Allow remote</label>       <input name=\"lab[lab_vmts_attributes]["+n+"][allow_remote]\" type=\"hidden\" value=\"0\" />      <input checked=\"checked\" id=\"lab_lab_vmts_attributes_"+n+"_allow_remote\" name=\"lab[lab_vmts_attributes]["+n+"][allow_remote]\" type=\"checkbox\" value=\"1\" />      <div class=\"networks\"></div>      </div>")
*/
    $("#lab_vmts").append(vmt_holder);
    
    var s=document.createElement('span');
    s.innerHTML='Add more networks';
    s.setAttribute('class', 'button add-button');
    s.onclick=function(){
        add_network_to_vmt(this);
    };
    $(".vmt").last().append(s);
    s.click();
}


function show_remote(el, html){
// override the messages div content. all other notices will be removed
    $(el).siblings('.remote').find(".commands").html(html);
    $(el).siblings('.remote').find(".hidden").show();
    makeCopy($(el).siblings('.remote').get(0)); // make it selectable
}


/* added 6. sept 2015 */

// return operating system name
function getOs(){
    var OSName="Unknown OS";
    if (navigator.platform.indexOf("Win")!=-1) OSName="Windows";
    if (navigator.platform.indexOf("Mac")!=-1) OSName="MacOS";
    if (navigator.platform.indexOf("X11")!=-1) OSName="UNIX";
    if (navigator.platform.indexOf("Linux")!=-1) OSName="Linux";
    return OSName;
}

// highlight text in an element
function SelectText(element) {
    var doc = document , range, selection;
    if (doc.body.createTextRange) {
        range = document.body.createTextRange();
        range.moveToElementText(element);
        range.select();
    } else if (window.getSelection) {
        selection = window.getSelection();
        range = document.createRange();
        range.selectNodeContents(element);
        selection.removeAllRanges();
        selection.addRange(range);
    }
}

// change text in an element for a period of time
function changeFor(el, newtext, time){
    var old=el.innerHTML;
    el.innerHTML=newtext;
    var oldclass=el.getAttribute("class");
    el.setAttribute("class", oldclass+" important");
    setTimeout(function(){
        el.innerHTML=old;
        el.setAttribute("class", oldclass);
    }, time);
}

// generate eventlisteners for text copying
function makeCopy(el){
        el.addEventListener('click', function(event) {
            var help = this.getElementsByClassName("helptext")[0];
            var copy= this.getElementsByClassName("copy")[0];
            SelectText(copy); // use the other fn to select the first span
            try {
                var successful = document.execCommand('copy');
                // works in:  chrome 42+, ff 41+, ie 9.0+, opera 29.0+, not supported in safari
                if (successful) { // change text in the second span
                    changeFor(help, "Copied", 5000);
                } else {
                    changeFor(help, (getOs()=="MacOS" ? "Press ⌘ + c" : "Press Ctrl + c"), 5000);
                }
                console.log('Copying text command was ' + (successful ? 'successful' : 'unsuccessful'));
            } catch (err) {
                console.log('Oops, unable to copy');
                // if you cant copy, then show the notice to ctrl+c
                changeFor(help, (getOs()=="MacOS" ? "Press ⌘ + c" : "Press Ctrl + c"), 5000);
            }
        });
}

function hideOtherOsButtons(){
    // hide remote desktop buttons for other os-s
    if (getOs()!="Unknown OS"){
        $(".remote_connections .button").hide();
        $(".remote_connections ."+getOs()).show();
    } else {
        $(".showtoggle").hide();
    }

}
function toggleOtherOsButtons(el){
    // hide remote desktop buttons for other os-s
    if (getOs()!="Unknown OS"){
        $(el).parent(".remote_connections").find(".button").toggle();
        $(".remote_connections ."+getOs()).show();
        if (el.innerHTML=="&lt; more")
            el.innerHTML="less &gt;";
        else
            el.innerHTML="&lt; more";
    }
}

/* EOF added 6. sept 2015 */