module YearlyReviewHelper
  def avatar_image(username, uploaded_avatar_id)
    template = User.avatar_template(username, uploaded_avatar_id).gsub(/{size}/, '25')
    "<img src='#{template}'class='avatar'/>"
  end

  def user_link(username)
    "<a class='mention' href='/u/#{username}'>@#{username}</a>"
  end

  # todo: remove if not used
  def category_link_title(slug, id, name)
    "<a class='hashtag' href='/c/#{slug}/#{id}'><h4>##{name}</h4></a> \r\r"
  end

  def topic_link(slug, title, topic_id, post_number = nil)
    url = " #{Discourse.base_url}/t/#{slug}/#{topic_id}"
    url += "/#{post_number}" if post_number
    title += "(#{post_number})" if post_number
    "<a href='#{url}' class='inline-onebox'>#{title}</a>"
  end

  def badge_title_link(badge_id, badge_name, badge_icon, badge_image)
    url = "#{Discourse.base_url}/badges/#{badge_id}/#{badge_name}"
    title = I18n.t('yearly_review.featured_badge.title', badge_name: badge_name)
    "<a href='#{url}'>#{title}</a>"
  end
end
