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

  def render_identifier(options = {})
    collect_values(options, 'rdf:value').join('; ')
  end

  def render_rdfs_label(options = {})
    collect_values(options, 'rdfs:label').join('; ')
  end

  def render_subject(options = {})
    subjects = options[:value].map do |val|
                 id = val['@id']
                 labels = [val['mads:authoritativeLabel']].flatten
                 labels.map { |label| link_to label, id }
               end.flatten.uniq.compact
    safe_join(subjects, '<br />'.html_safe)
  end

end
