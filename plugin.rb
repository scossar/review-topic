# name: discourse-yearly-review
# about: creates a yearly review post
# version: 0.1
# Authors Simon Cossar

enabled_site_setting :yearly_review_enabled

PLUGIN_NAME = 'yearly-review'.freeze

add_admin_route 'yearly_review.title', 'yearly-review'

after_initialize do
  require_dependency 'admin_constraint'
  ::ActionController::Base.prepend_view_path File.expand_path("../app/views/yearly-review", __FILE__)

  module ::YearlyReview
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace YearlyReview
    end
  end

  [
    '../../discourse-yearly-review/app/jobs/yearly_review.rb'
  ].each { |path| load File.expand_path(path, __FILE__) }

  require_dependency 'admin/admin_controller'
  class YearlyReview::YearlyReviewController < ::Admin::AdminController

    def create()
      user = current_user
      Jobs::YearlyReview.new.execute(title: params[:review_title],
                                     categories: params[:review_categories],
                                     review_featured_badge: params[:review_featured_badge],
                                     review_start: params[:review_start],
                                     review_end: params[:review_end],
                                     review_publish_category: params[:review_publish_category],
                                     review_user: user)

      # review = render_to_string :template =>  "../../discourse-yearly-review/app/views/yearly_review/yearly_review.html.erb", :layout => false
      review = render_to_string :template =>  "yearly_review", formats: :html, layout: false

      puts "YEARLYREVIEW #{review}"
      render json: { success: true }
    end
  end

  YearlyReview::Engine.routes.draw do
    root to: "yearly_review#index"
    post 'create', to: 'yearly_review#create', constraints: StaffConstraint.new
  end

  Discourse::Application.routes.append do
    mount ::YearlyReview::Engine, at: '/admin/plugins/yearly-review', constraints: AdminConstraint.new
  end
end
