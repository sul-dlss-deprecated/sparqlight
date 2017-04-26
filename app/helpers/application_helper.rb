module ApplicationHelper
  def render_topics(options = {})

    # TODO: figure out how the SparqlConfig maps to this :value?
    # puts options[:value].inspect

    options[:value].map { |val| val['mads:authoritativeLabel'] }.join(', ')
  end
end
