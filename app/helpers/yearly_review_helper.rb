module YearlyReviewHelper
  def avatar_image(username, uploaded_avatar_id)
    template = User.avatar_template(username, uploaded_avatar_id).gsub(/{size}/, '25')
    "<img src='#{template}'class='avatar'/>"
  end

  def user_link(username)
    "<a class='mention' href='/u/#{username}'>@#{username}</a>"
  end

  def category_link_title(slug, id, name)
    "<a class='hashtag' href='/c/#{slug}/#{id}'><h4>##{name}</h4></a> \r\r"
  end

  def topic_link(slug, topic_id, post_number = nil)
    url = "#{Discourse.base_url}/t/#{slug}/#{topic_id}"
    url += "/#{post_number}" if post_number
    "#{url} \r\r"
  end

end
