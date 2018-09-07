# name: discourse-yearly-review
# about: creates a yearly review post
# version: 0.1
# Authors Simon Cossar

enabled_site_setting :yearly_review_enabled

PLUGIN_NAME = 'yearly-review'.freeze

# add_admin_route 'yearly_review.title', 'yearly-review'

after_initialize do
  # require_dependency 'admin_constraint'

  # module ::YearlyReview
  #   class Engine < ::Rails::Engine
  #     engine_name PLUGIN_NAME
  #     isolate_namespace YearlyReview
  #   end
  # end

  [
    '../../discourse-yearly-review/app/jobs/yearly_review.rb'
  ].each { |path| load File.expand_path(path, __FILE__) }

  # require_dependency 'admin/admin_controller'
  # class YearlyReview::YearlyReviewController < ::Admin::AdminController
  #   def index
  #
  #   end
  # end

  # YearlyReview::Engine.routes.draw do
  #   root to: "yearly_review#index"
  #   post 'review', to: 'yearly_review#create_review', constraints: AdminConstraint.new
  # end
  #
  # Discourse::Application.routes.append do
  #   mount ::YearlyReview::Engine, at: '/admin/plugins/yearly-review', constraints: AdminConstraint.new
  # end
end
