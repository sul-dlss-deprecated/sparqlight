module ApplicationHelper
  def render_numismatics(options = {})
    options[:value]['skos:prefLabel']
  end
end
