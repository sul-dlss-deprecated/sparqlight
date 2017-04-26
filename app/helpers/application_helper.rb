module ApplicationHelper
  def render_subject(options = {})
    options[:value].map { |val| val["bf:subject"] }.join(', ')
  end
end
