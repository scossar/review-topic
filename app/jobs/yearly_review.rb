module ::Jobs
  class YearlyReview < ::Jobs::Scheduled
    every 1.day
    sidekiq_options retry: true, queue: 'critical'

    def execute
      output = "<div data-review='review-topic'><h2>Top Users</h2>"
      output += most_topics start_date, end_date
      output += most_replies start_date, end_date
      output += most_likes_given start_date, end_date
      output += most_visits start_date, end_date
      output += '</div>'
      output += most_popular_topics
      output += most_liked_topics
      output += most_replied_topics
      opts = {
        title: "#{yearly_review_title} - #{rand(100000)}",
        raw: output,
        category: publish_category_name,
      }
      PostCreator.create!(User.find(1), opts)
    end

    def publish_category_name
      Category.find(SiteSetting.yearly_review_publish_category).name
    end

    def yearly_review_title
      # todo: if the title isn't set, create it from the start and end dates
      SiteSetting.yearly_review_title
    end

    # todo: only fetch this once!
    def yearly_review_categories
      SiteSetting.yearly_review_categories.split('|').map{ |x| x.to_i }
    end

    def start_date
      period = SiteSetting.yearly_review_period

      return 1.year.ago.beginning_of_day if 'year' == period
      return 3.months.ago.beginning_of_day if 'quarter' == period
      return 1.month.ago.beginning_of_day if 'month' == period
      return 1.week.ago.beginning_of_day if 'week' == period
      return post.first.created_at
    end

    def end_date
      Date.today.end_of_day
    end

    def topics_order(query_property)
      period = SiteSetting.yearly_review_period
      period = period + 'ly' unless 'all' == period
      period + query_property
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
        AND t.category_id IN (#{yearly_review_categories.join(',')})
        GROUP BY t.user_id, u.username, u.uploaded_avatar_id
        ORDER BY topic_count DESC
        LIMIT 15
      SQL

      output = "<h3>#{I18n.t('yearly_review.topics_created')}<h3><table><tr><th>#{I18n.t('yearly_review.user')}</th><th>#{I18n.t('yearly_review.topics')}</th></tr>"

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

      output = "<h3>#{I18n.t('yearly_review.replies_created')}<h3><table><tr><th>#{I18n.t('yearly_review.user')}</th><th>#{I18n.t('yearly_review.replies')}</th></tr>"

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

      output = "<h3>#{I18n.t('yearly_review.most_visits')}<h3><table><tr><th>#{I18n.t('yearly_review.user')}</th><th>#{I18n.t('yearly_review.visits')}</th></tr>"

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

      output = "<h3>#{I18n.t('yearly_review.most_likes_given')}<h3><table><tr><th>#{I18n.t('yearly_review.user')}</th><th>#{I18n.t('yearly_review.likes_given')}</th></tr>"

      DB.query(sql).each do |row|
        avatar_template = User.avatar_template(row.username, row.uploaded_avatar_id).gsub(/{size}/, '25')
        avatar_image = "<img src='#{avatar_template}'class='avatar'/>"
        userlink = "<a class='mention' href='/u/#{row.username}'>@#{row.username}</a>"
        output += "<tr><td>#{avatar_image} #{userlink} </td><td>#{row.likes_given_count}</td></tr>"
      end

      output += "</table>"
    end

    def top_topics
      output = "<h3>#{I18n.t('yearly_review.most_popular_topics')}</h3> \r\r"
      yearly_review_categories.each do |cat_id|
        sql = <<~SQL
          SELECT
          t.id,
          t.slug AS topic_slug,
          c.slug AS category_slug,
          c.name AS category_name
          FROM topics t
          JOIN top_topics tt
          ON tt.topic_id = t.id
          JOIN categories c
          ON c.id = t.category_id
          WHERE c.read_restricted = 'false'
          AND c.id = #{cat_id}
          ORDER BY #{topics_order '_score'} DESC
          LIMIT 5
        SQL

        DB.query(sql).each_with_index do |row, i|
          output += "<a class='hashtag' href='/c/#{row.category_slug}'><h4>##{row.category_name}</h4></a>\r\r" if i == 0
          url = "#{Discourse.base_url}/t/#{row.topic_slug}/#{row.id}"
          output += "#{url} \r\r"
        end
      end

      output
    end

    def most_popular_topics_sql
      <<~SQL
          SELECT
          t.id,
          t.slug AS topic_slug,
          c.slug AS category_slug,
          c.name AS category_name
          FROM topics t
          JOIN top_topics tt
          ON tt.topic_id = t.id
          JOIN categories c
          ON c.id = t.category_id
          WHERE c.read_restricted = 'false'
          AND c.id = :cat_id
          ORDER BY #{topics_order '_score'} DESC
          LIMIT 5
      SQL
    end

    def most_liked_topics_bak
      output = "<h3>#{I18n.t('yearly_review.most_liked_topics')}</h3>\r\r"
      yearly_review_categories.each do |cat_id|
        sql = <<~SQL
          SELECT
          t.id,
          t.slug AS topic_slug,
          c.slug AS category_slug,
          c.name AS category_name
          FROM topics t
          JOIN top_topics tt
          ON tt.topic_id = t.id
          JOIN categories c
          ON c.id = t.category_id
          WHERE c.read_restricted = 'false'
          AND c.id = #{cat_id}
          ORDER BY tt.yearly_likes_count DESC
          LIMIT 5
        SQL

        DB.query(sql).each_with_index do |row, i|
          output += "<a class='hashtag' href='/c/#{row.category_slug}'><h4>##{row.category_name}</h4></a>\r\r" if i == 0
          url = "#{Discourse.base_url}/t/#{row.topic_slug}/#{row.id}"
          output += "#{url} \r\r"
        end
      end

      output
    end

    def most_liked_sql
      <<~SQL
          SELECT
          t.id,
          t.slug AS topic_slug,
          c.slug AS category_slug,
          c.name AS category_name
          FROM topics t
          JOIN top_topics tt
          ON tt.topic_id = t.id
          JOIN categories c
          ON c.id = t.category_id
          WHERE c.read_restricted = 'false'
          AND c.id = :cat_id
          ORDER BY tt.yearly_likes_count DESC
          LIMIT 5
      SQL
    end

    # def most_replied_to_topics
    #   output = "<h3>#{I18n.t('yearly_review.most_replied_to_topics')}</h3>\r\r"
    #   yearly_review_categories.each do |cat_id|
    #     sql = <<~SQL
    #     SELECT
    #     t.id,
    #     t.slug AS topic_slug,
    #     c.slug AS category_slug,
    #     c.name AS category_name
    #     FROM topics t
    #     JOIN top_topics tt
    #     ON tt.topic_id = t.id
    #     JOIN categories c
    #     ON c.id = t.category_id
    #     WHERE c.read_restricted = 'false'
    #     AND c.id = #{cat_id}
    #     ORDER BY tt.yearly_posts_count DESC
    #     LIMIT 5
    #     SQL
    #
    #     DB.query(sql).each_with_index do |row, i|
    #       output += "<a class='hashtag' href='/c/#{row.category_slug}'><h4>##{row.category_name}</h4></a>\r\r" if i == 0
    #       url = "#{Discourse.base_url}/t/#{row.topic_slug}/#{row.id}"
    #       output += "#{url} \r\r"
    #     end
    #   end
    #
    #   output
    # end

    def most_replied_sql
      <<~SQL
        SELECT
        t.id,
        t.slug AS topic_slug,
        c.slug AS category_slug,
        c.name AS category_name
        FROM topics t
        JOIN top_topics tt
        ON tt.topic_id = t.id
        JOIN categories c
        ON c.id = t.category_id
        WHERE c.read_restricted = 'false'
        AND c.id = :cat_id
        ORDER BY tt.yearly_posts_count DESC
        LIMIT 5
      SQL
    end

    def most_popular_topics
      category_topics('most_popular_topics', most_popular_topics_sql)
    end

    def most_replied_topics
      category_topics('most_replied_to_topics', most_replied_sql)
    end

    def most_liked_topics
      category_topics('most_liked_topics', most_liked_sql)
    end


    def category_topics(title_key, sql)
      output = "<h3>#{I18n.t('yearly_review.' + title_key)}</h3>\r\r"
      yearly_review_categories.each do |cat_id|
        DB.query(sql, cat_id: cat_id).each_with_index do |row, i|
          output += "<a class='hashtag' href='/c/#{row.category_slug}'><h4>##{row.category_name}</h4></a>\r\r" if i == 0
          url = "#{Discourse.base_url}/t/#{row.topic_slug}/#{row.id}"
          output += "#{url} \r\r"
        end
      end

      output
    end
  end
end
