module ApplicationHelper

  def collect_values(options, field)
    options[:value].map { |val| val[field] }.compact
  end

  def render_contribution(options = {})
    agents = collect_values(options, 'bf:agent')
    agents.map {|agent| agent['rdfs:label'] }.join('; ')
  end

  def render_genre(options = {})
    collect_values(options, 'rdfs:label').uniq.join('; ')
  end

  def render_rdfs_label(options = {})
    collect_values(options, 'rdfs:label').join('; ')
  end

  def render_subject(options = {})
    collect_values(options, 'mads:authoritativeLabel').join('; ')
  end

end
