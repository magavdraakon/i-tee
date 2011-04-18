module ApplicationHelper
  
  def link_M(string)
  string.gsub(/#M_(\d+)/) do
    link_to "#{Material.find_by_id($1).name}", material_path($1)
  end
end

end
