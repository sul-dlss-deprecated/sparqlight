module ApplicationHelper

  def render_genre(options = {})
    options[:value].map { |val| val['rdfs:label'] }.uniq.join(', ')
  end

  def render_subjects(options = {})
    options[:value].map { |val| val['mads:authoritativeLabel'] }.join(', ')
  end

end
