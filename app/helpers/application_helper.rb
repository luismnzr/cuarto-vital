module ApplicationHelper
  def page_title(title)
    content_for(:title) { title }
    content_for(:page_title) { title }
  end

  def pagy_nav_tag(pagy)
    pagy.series_nav.html_safe
  end
end
