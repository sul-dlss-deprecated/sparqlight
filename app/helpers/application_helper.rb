module ApplicationHelper
  def render_work(options = {})
    Array.wrap(options[:value]).map {|v| '"' + v["mo:performance_of"]["dc:title"] + '"'}.to_sentence
  end
  def render_performer(options = {})
    Array.wrap(options[:value]).map {|v| v["foaf:name"]}.to_sentence
  end
end
