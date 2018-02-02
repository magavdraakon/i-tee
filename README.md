# About i-tee
i-tee is a distance laboratory system, that is based on ruby on rails and uses VirtualBox headless virtualization.

i-tee is developed by the Estonian IT College.

More information about i-tee and one lab (we call them a learningspace) can be found from following article:
http://conferences.sigcomm.org/sigcomm/2015/pdf/papers/p113.pdf


    Margus Ernits, Johannes Tammekänd, and Olaf Maennel. 2015.
    i-tee: A fully automated Cyber Defense Competition for Students.
    In Proceedings of the 2015 ACM Conference on Special Interest Group on Data Communication (SIGCOMM '15).
    ACM, New York, NY, USA, 113-114. DOI=http://dx.doi.org/10.1145/2785956.2790033


i-tee contains three layers such as: Virtualisation, Web frontend (access control, lab control), Learningspace layer.


# Prerequirements

* Bare metal host for virtualization
* Working LDAP server and bind user
* Good knowledge of GNU/Linux

# Installation guide


* Create I-Tee base configuration file `/etc/i-tee/config.yaml`
  ```json
  {
	"ldap" : {
		"host" : "LDAP_SERVER",
		"port" : LDAP_PORT,
		"attribute" : "sAMAccountName",
		"base" : "dc=yoursearch,dc=base",
		"group_base" : "cn=Users,dc=zentyal-domain,dc=lan",
		"ssl" : true,
		"user" : "Replace_with_your_bind_user",
		"password" : "Replace_with_your_bind_user"
	},
	"skin" : "vequrity",
	"admins": [ "list","of","your","admins"]
}
```

* Ensure that your server name can be resolved Using
'''bash
hostname -f
'''

* Clone repo and start installation on ubuntu 16.04 64bit
'''bash
git clone https://github.com/magavdraakon/i-tee.git

cd i-tee
./install/install.sh
'''
# Authors
Tiia Tänav

Margus Ernits

Keijo Kapp

Carolyn Fischer (retired)

Aivar Guitar (retired)

Madis Toom (retired)
