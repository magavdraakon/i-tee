class ChangeGTypeToString < ActiveRecord::Migration
  def up
    change_column :lab_vmts, :g_type, :string, :null => false, :default => 'none'
    LabVmt.where(g_type: '0').update_all(g_type: 'none')
    LabVmt.where(g_type: '1').update_all(g_type: 'rdp')
    LabVmt.where(g_type: '2').update_all(g_type: 'vnc')
    LabVmt.where(g_type: '3').update_all(g_type: 'ssh')
  end
end
