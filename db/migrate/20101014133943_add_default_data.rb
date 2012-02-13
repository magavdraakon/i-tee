class AddDefaultData < ActiveRecord::Migration
  def self.up
    Material.create(:name=> 'Veebiserveri labor', :source=>'https://wiki.itcollege.ee/index.php/Veebiserveri_labor_v.2')
    Lab.create(:name=>'Veebiserveri labor', 
    :description=>'Firmale on vaja luua kaks veebilehte: 
    www.firma.ee 
    sales.firma.ee 
    M6lemal lehel saab kasutada phpd
    Lisaks tuleb konfigureerida mysql ja phpMyAdmin andmebaaside seadistamiseks ')
    
    Host.create(:name=>'elab.itcollege.ee', :ip=>'192.168.13.13', 
    :publickey=>'95cPcqlup5jNLhxtY6NxzIkzcthow5ZpA6xNBg', 
    :privatekey=>'8NPspBnqoCQM4kKhQ98TAsd2rLZ8R0lZzdnm7g', 
    :ram=>'2', :cpu_cores=>'2', 
    :hdd=>'100', :priority=>'1')
  end

  def self.down
    
  end
end
