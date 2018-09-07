module ::Jobs
  class YearlyReview < ::Jobs::Scheduled
    def execute
      output = "<div data-review='review-topic'><h2>Top Users</h2>"
      output += most_topics start_date, end_date
      output += most_replies start_date, end_date
      output += most_likes_given start_date, end_date
      output += most_visits start_date, end_date
      output += '</div>'
      output += top_topics
      output += most_liked_topics
      output += most_replied_to_topics
      opts = {
        title: "The Year in Review - #{rand(100000)}",
        raw: output,
        category: 'Site Feedback',
      }
      PostCreator.create!(User.find(1), opts)
    end

    def start_date
      1.year.ago.beginning_of_day
    end

    def end_date
      Date.today.end_of_day
    end

    def most_topics(start_date, end_date)
      sql = <<~SQL
      SELECT
      t.user_id,
      COUNT(t.user_id) AS topic_count,
      u.username,
      u.uploaded_avatar_id
      FROM topics t
      JOIN users u
      ON u.id = t.user_id
      WHERE t.archetype = 'regular'
      AND t.user_id > 0
      AND t.created_at >= '#{start_date}'
      AND t.created_at <= '#{end_date}'
      GROUP BY t.user_id, u.username, u.uploaded_avatar_id
      ORDER BY topic_count DESC
      LIMIT 15
      SQL

      output = "<h3>Topics Created<h3><table><tr><th>User</th><th>Topics</th></tr>"

      DB.query(sql).each do |row|
        avatar_template = User.avatar_template(row.username, row.uploaded_avatar_id).gsub(/{size}/, '25')
        avatar_image = "<img src='#{avatar_template}'class='avatar'/>"
        userlink = "<a class='mention' href='/u/#{row.username}'>@#{row.username}</a>"
        output += "<tr><td>#{avatar_image} #{userlink}</td><td>#{row.topic_count}</td></tr>"
      end

      output += "</table>"
    end

    def most_replies(start_date, end_date)
      sql = <<~SQL
SELECT
p.user_id,
u.username,
u.uploaded_avatar_id,
COUNT(p.user_id) AS reply_count
FROM posts p
JOIN users u
ON u.id = p.user_id
JOIN topics t
ON t.id = p.topic_id
WHERE t.archetype = 'regular'
AND p.user_id > 0
AND p.post_number > 1
AND p.created_at >= '#{start_date}'
AND p.created_at <= '#{end_date}'
GROUP BY p.user_id, u.username, u.uploaded_avatar_id
ORDER BY reply_count DESC
LIMIT 15
      SQL

      output = "<h3>Replies Created<h3><table><tr><th>User</th><th>Replies</th></tr>"

      DB.query(sql).each do |row|
        avatar_template = User.avatar_template(row.username, row.uploaded_avatar_id).gsub(/{size}/, '25')
        avatar_image = "<img src='#{avatar_template}'class='avatar'/>"
        userlink = "<a class='mention' href='/u/#{row.username}'>@#{row.username}</a>"
        output += "<tr><td>#{avatar_image} #{userlink} </td><td>#{row.reply_count}</td></tr>"
      end

      output += "</table>"
    end

    def most_visits(start_date, end_date)
      sql = <<~SQL
SELECT
uv.user_id,
u.username,
u.uploaded_avatar_id,
COUNT(uv.user_id) AS visit_count
FROM user_visits uv
JOIN users u
ON u.id = uv.user_id
WHERE u.id > 0
AND uv.visited_at >= '#{start_date}'
AND uv.visited_at <= '#{end_date}'
GROUP BY uv.user_id, u.username, u.uploaded_avatar_id
ORDER BY visit_count DESC
LIMIT 15
      SQL

      output = "<h3>Most Visits<h3><table><tr><th>User</th><th>Visits</th></tr>"

      DB.query(sql).each do |row|
        avatar_template = User.avatar_template(row.username, row.uploaded_avatar_id).gsub(/{size}/, '25')
        avatar_image = "<img src='#{avatar_template}'class='avatar'/>"
        userlink = "<a class='mention' href='/u/#{row.username}'>@#{row.username}</a>"
        output += "<tr><td>#{avatar_image} #{userlink} </td><td>#{row.visit_count}</td></tr>"
      end

      output += "</table>"
    end

    def most_likes_given(start_date, end_date)
      sql = <<~SQL
SELECT
ua.user_id,
u.username,
u.uploaded_avatar_id,
COUNT(ua.user_id) AS likes_given_count
FROM user_actions ua
JOIN users u
ON u.id = ua.user_id
WHERE u.id > 0
AND ua.created_at >= '#{start_date}'
AND ua.created_at <= '#{end_date}'
AND ua.action_type = 2
GROUP BY ua.user_id, u.username, u.uploaded_avatar_id
ORDER BY likes_given_count DESC
LIMIT 15
      SQL

      output = "<h3>Most Likes Given<h3><table><tr><th>User</th><th>Likes Given</th></tr>"

      DB.query(sql).each do |row|
        avatar_template = User.avatar_template(row.username, row.uploaded_avatar_id).gsub(/{size}/, '25')
        avatar_image = "<img src='#{avatar_template}'class='avatar'/>"
        userlink = "<a class='mention' href='/u/#{row.username}'>@#{row.username}</a>"
        output += "<tr><td>#{avatar_image} #{userlink} </td><td>#{row.likes_given_count}</td></tr>"
      end

      output += "</table>"
    end

    def top_topics
      sql = <<~SQL
SELECT
t.id,
t.slug
FROM topics t
JOIN top_topics tt
ON tt.topic_id = t.id
JOIN categories c
ON c.id = t.category_id
WHERE c.read_restricted = 'false'
ORDER BY tt.yearly_score DESC
LIMIT 5
      SQL
      output = "<h3>Most Popular Topics</h3> \r\r"
      DB.query(sql).each do |row|
        url = "#{Discourse.base_url}/t/#{row.slug}/#{row.id}"
        output += "#{url} \r\r"
      end

      output
    end

    def most_liked_topics
      sql = <<~SQL
SELECT
t.id,
t.slug
FROM topics t
JOIN top_topics tt
ON tt.topic_id = t.id
JOIN categories c
ON c.id = t.category_id
WHERE c.read_restricted = 'false'
ORDER BY tt.yearly_likes_count DESC
LIMIT 5
      SQL
      output = "<h3>Most Liked Topics</h3> \r\r"
      DB.query(sql).each do |row|
        url = "#{Discourse.base_url}/t/#{row.slug}/#{row.id}"
        output += "#{url} \r\r"
      end

      output
    end

    def most_replied_to_topics
      sql = <<~SQL
SELECT
t.id,
t.slug
FROM topics t
JOIN top_topics tt
ON tt.topic_id = t.id
JOIN categories c
ON c.id = t.category_id
WHERE c.read_restricted = 'false'
ORDER BY tt.yearly_posts_count DESC
LIMIT 5
      SQL
      output = "<h3>Most Replied to Topics</h3> \r\r"
      DB.query(sql).each do |row|
        url = "#{Discourse.base_url}/t/#{row.slug}/#{row.id}"
        output += "#{url} \r\r"
      end

      output
    end
  end
end
