module ApplicationHelper

  ##
  ## TODO: Add RDFa to these HTML outputs
  ##

  def collect_values(options, field)
    options[:value].map { |val| val[field] }.compact
  end

  def render_contribution(options = {})
    agents = collect_values(options, 'bf:agent')
    agent_links = agents.map do |agent|
                    id = agent['@id']
                    label = agent['rdfs:label']
                    links = []
                    links << link_to('LOC', id) if id =~ /loc.gov/i
                    identities = [agent['bf:identifiedBy']].flatten
                    identities.each do |i|
                      value = i['rdf:value']
                      links << link_to('ISNI', value) if value =~ /isni.org/i
                      links << link_to('VIAF', value) if value =~ /viaf.org/i
                    end
                    links = safe_join(links, ', '.html_safe)
                    "#{label} (#{links})".html_safe
                  end.compact
    safe_join(agent_links, '<br />'.html_safe)
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
