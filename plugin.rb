# name: discourse-yearly-review
# about: creates a yearly review post
# version: 0.1
# Authors Simon Cossar

enabled_site_setting :yearly_review_enabled

PLUGIN_NAME = 'yearly-review'.freeze

add_admin_route 'yearly_review.title', 'yearly-review'

after_initialize do
  require_dependency 'admin_constraint'
  # Look at how this is done in the site_report plugin
  ::ActionController::Base.prepend_view_path File.expand_path("../app/views/yearly-review", __FILE__)

  module ::YearlyReview
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace YearlyReview
    end
  end

  # [
  #   '../../discourse-yearly-review/app/jobs/yearly_review.rb'
  # ].each { |path| load File.expand_path(path, __FILE__) }

  require_dependency 'admin/admin_controller'
  require_relative 'app/helpers/yearly_review_helper'
  class YearlyReview::YearlyReviewController < ::Admin::AdminController
    include YearlyReviewHelper
    add_template_helper YearlyReviewHelper
    def create

      review_title = params[:review_title]
      review_categories = params[:review_categories].split(',').map{ |x| x.to_i }
      review_featured_badge = params[:review_featured_badge]
      review_start = Date.parse(params[:review_start]).beginning_of_day
      # todo: remove the + 1.day
      review_end = (Date.parse(params[:review_end]) + 1.day).end_of_day
      review_publish_category = params[:review_publish_category]
      review_user = current_user

      @most_topics = most_topics review_categories, review_start, review_end
      @most_replies = most_replies review_categories, review_start, review_end
      @most_likes = most_likes_given review_start, review_end
      @most_visits = most_visits review_start, review_end
      @most_liked_topics = most_liked_topics review_categories, review_start, review_end
      @most_liked_posts = most_liked_posts review_categories, review_start, review_end
      puts "MOSTLIKED #{@most_liked_topics}"

      # output += most_liked_topics review_start, review_end, review_categories
      # output += most_liked_posts review_start, review_end, review_categories
      # output += most_replied_to_topics review_start, review_end, review_categories
      # output += featured_badge_users review_featured_badge, review_start, review_end

      output = render_to_string :template =>  "yearly_review", formats: :html, layout: false

      opts = {
        title: "#{review_title} - #{rand(100000)}",
        raw: output,
        category: review_publish_category,
        skip_validations: true
      }

      PostCreator.create!(review_user, opts)

      render json: {success: true}
    end

    def most_topics(categories, start_date, end_date)
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
        AND t.category_id IN (#{categories.join(',')})
        GROUP BY t.user_id, u.username, u.uploaded_avatar_id
        ORDER BY topic_count DESC
        LIMIT 15
      SQL

      DB.query(sql)
    end

    def most_replies(categories, start_date, end_date)
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
        AND t.category_id IN (#{categories.join(',')})
        GROUP BY p.user_id, u.username, u.uploaded_avatar_id
        ORDER BY reply_count DESC
        LIMIT 15
      SQL

      DB.query(sql)
    end

    def featured_badge_users(badge_name, start_date, end_date)
      sql = <<~SQL
              SELECT
        u.id AS user_id,
        username,
        uploaded_avatar_id
        FROM badges b
        JOIN user_badges ub
        ON ub.badge_id = b.id
        JOIN users u
        ON u.id = ub.user_id
        WHERE b.name = '#{badge_name}'
        AND ub.granted_at BETWEEN '#{start_date}' AND '#{end_date}'
      SQL

      badge = Badge.find_by(name: badge_name)
      img = badge && badge.image ? " <img src='#{badge.image}' height=20 width=20/>" : ''
      description = badge && badge.description ? badge.description : nil

      output = "<h3>Users Granted the #{badge_name} badge#{img}</h3>"
      output += "<p>#{description}</p>" if description

      DB.query(sql).each do |row|
        avatar_template = User.avatar_template(row.username, row.uploaded_avatar_id).gsub(/{size}/, '25')
        avatar_image = "<img src='#{avatar_template}'class='avatar'/>"
        userlink = "<a class='mention' href='/u/#{row.username}'>@#{row.username}</a>"
        output += "<div>#{avatar_image} #{userlink}</div>"
      end

      output
    end

    def most_visits(start_date, end_date)
      # todo: add category filter
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

      DB.query(sql)
    end

    def most_likes_given(start_date, end_date)
      # todo: filter by category
      sql = <<~SQL
        SELECT
        ua.acting_user_id,
        u.username,
        u.uploaded_avatar_id,
        COUNT(ua.user_id) AS likes_given_count
        FROM user_actions ua
        JOIN users u
        ON u.id = ua.acting_user_id
        WHERE u.id > 0
        AND ua.created_at >= '#{start_date}'
        AND ua.created_at <= '#{end_date}'
        AND ua.action_type = 2
        GROUP BY ua.acting_user_id, u.username, u.uploaded_avatar_id
        ORDER BY likes_given_count DESC
        LIMIT 15
      SQL

      DB.query(sql)
    end

    # todo: make sure the posts/topics being queried haven't been deleted
    def likes_in_topic_sql
      <<~SQL
        SELECT
        t.id,
        t.slug AS topic_slug,
        t.title,
        c.slug AS category_slug,
        c.name AS category_name,
        c.id AS category_id,
        COUNT(*) AS like_count
        FROM post_actions pa
        JOIN posts p
        ON p.id = pa.post_id
        JOIN topics t
        ON t.id = p.topic_id
        JOIN categories c
        ON c.id = t.category_id
        WHERE pa.created_at BETWEEN :start_date AND :end_date
        AND pa.post_action_type_id = 2
        AND c.id = :cat_id
        AND c.read_restricted = 'false'
        AND t.deleted_at IS NULL
        GROUP BY t.id, category_slug, category_name, c.id
        ORDER BY like_count DESC
        LIMIT 5
      SQL
    end

    def most_liked_posts_sql
      <<~SQL
        SELECT
        t.id,
        p.post_number,
        t.slug AS topic_slug,
        t.title,
        c.slug AS category_slug,
        c.name AS category_name,
        c.id AS category_id,
        COUNT(*) AS like_count
        FROM post_actions pa
        JOIN posts p
        ON p.id = pa.post_id
        JOIN topics t
        ON t.id = p.topic_id
        JOIN categories c
        ON c.id = t.category_id
        WHERE pa.created_at BETWEEN :start_date AND :end_date
        AND pa.post_action_type_id = 2
        AND c.id = :cat_id
        AND c.read_restricted = 'false'
        AND p.deleted_at IS NULL
        GROUP BY p.post_number, t.id, topic_slug, category_slug, category_name, c.id
        ORDER BY like_count DESC
        LIMIT 5
      SQL
    end


    def most_replied_to_topics_sql
      <<~SQL
        SELECT
        t.id,
        NULL AS post_number,
        t.slug AS topic_slug,
        c.slug AS category_slug,
        c.name AS category_name,
        COUNT(*) AS post_count
        FROM posts p
        JOIN topics t
        ON t.id = p.topic_id
        JOIN categories c
        ON c.id = t.category_id
        WHERE p.created_at BETWEEN :start_date AND :end_date
        AND c.id = :cat_id
        AND c.read_restricted = 'false'
        AND t.deleted_at IS NULL
        GROUP BY p.id, t.id, topic_slug, category_slug, category_name
        ORDER BY post_count DESC
        LIMIT 5
      SQL
    end

    def most_liked_topics cat_ids, start_date, end_date
      category_topics(start_date, end_date, cat_ids, likes_in_topic_sql)
    end

    def most_liked_posts cat_ids, start_date, end_date
      category_topics( start_date, end_date, cat_ids, most_liked_posts_sql)
    end

    def most_replied_to_topics cat_ids, start_date, end_date
      category_topics(start_date, end_date, cat_ids, most_replied_to_topics_sql)
    end


    def category_topics(start_date, end_date, category_ids, sql)
      data = []
      category_ids.each do |cat_id|
        cat_data = []
        DB.query(sql, start_date: start_date, end_date: end_date, cat_id: cat_id).each do |row|
          cat_data << row
        end

        data << cat_data unless cat_data.empty?
      end
      data
    end

  end

  YearlyReview::Engine.routes.draw do
    root to: "yearly_review#index"
    post 'create', to: 'yearly_review#create', constraints: StaffConstraint.new
  end

  Discourse::Application.routes.append do
    mount ::YearlyReview::Engine, at: '/admin/plugins/yearly-review', constraints: StaffConstraint.new
  end
end
