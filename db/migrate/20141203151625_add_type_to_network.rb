class AddTypeToNetwork < ActiveRecord::Migration[5.2]
  def change
# bridgeadapter, hostonlyadapter, intnet, nat ?
    add_column :networks, :net_type, :string, :default=>'intnet'
  end
end
