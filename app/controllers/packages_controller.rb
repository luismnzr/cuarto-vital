class PackagesController < ApplicationController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def index
    @packages = Package.active.ordered
    @subscription_plans = SubscriptionPlan.active
  end
end
