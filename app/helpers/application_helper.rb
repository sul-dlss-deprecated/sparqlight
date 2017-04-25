module ApplicationHelper
  def render_numismatics(options = {})
    options[:value].map { |val| val["skos:prefLabel"] }.join(', ')
  end
end
