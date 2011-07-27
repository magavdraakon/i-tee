module ApplicationHelper
  
  def link_M(string)
    string.gsub(/#M_(\d+)/) do
      material=Material.find_by_id($1)
      link_to "#{material.name}", material_path($1), :target => '_blank' if material!=nil
    end
  end

end
