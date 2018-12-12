module ::Jobs
  class YearlyReview < ::Jobs::Base

    # sidekiq_options retry: false, queue: 'critical'

    def execute(args = {})
      # Code to create review from controller.
    end
  end
end
