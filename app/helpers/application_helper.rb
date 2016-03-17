module ApplicationHelper
  
  def link_m(string)
    string.gsub(/#M_(\d+)/) do
      material=Material.find_by_id($1)
      "[#{material.name}]("+ material_path($1)+')' if material!=nil
    end
  end

end
