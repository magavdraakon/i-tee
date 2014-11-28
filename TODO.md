RDP
===

Today Linux clients are well supported because it is easy to install rdesktop or other RDP software. 
Rdesktop can be executed via copy/paste from web interface.

* In Linux install rdesktop or xfreerdp and use instructions from i-tee web.

* In Windows or MacOS X RDP client mstsc can be used. Sadly we can not execute it with one sipmle command line

Possible solutions:

1. Guacamole RDP client
  1. Pros
    * You need only web browser
    * Easey to use
  1. Cons
    * Needs one separate server/VM with tomcat and Java app
    * Needs development for integration i-tee and gauacamole
1. RDP+  [http://www.donkz.nl/] 
  * Wrapper for mstsc
  1. Pros
    * Can be executed as rdp /v:hostname:porn_no  /u:uername /p:passwd /max like rdesktop|xfreerdp
    * Easy to use
  1. Cons
    * Closed software
    * Separate software that needs some .dll-s



Guacamole RDP
--------------

http://www.powershellmagazine.com/2014/04/18/automatic-remote-desktop-connection/


RDP+
-------------
http://www.donkz.nl/

Custom PS script
----------------
https://gallery.technet.microsoft.com/scriptcenter/Connect-Mstsc-Open-RDP-2064b10b

a'a
cmdkey /add:hostname /user:username /pass:password
mstsc.exe /v hostname:portname /f