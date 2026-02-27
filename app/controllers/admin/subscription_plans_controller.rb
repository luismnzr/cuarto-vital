module Admin
  class SubscriptionPlansController < BaseController
    def index
      @subscription_plans = policy_scope(SubscriptionPlan)
    end

    def new
      @subscription_plan = SubscriptionPlan.new
      authorize @subscription_plan
    end

    def create
      @subscription_plan = SubscriptionPlan.new(subscription_plan_params)
      authorize @subscription_plan
      if @subscription_plan.save
        redirect_to admin_subscription_plans_path, notice: "Subscription plan created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @subscription_plan = SubscriptionPlan.find(params[:id])
      authorize @subscription_plan
    end

    def update
      @subscription_plan = SubscriptionPlan.find(params[:id])
      authorize @subscription_plan
      if @subscription_plan.update(subscription_plan_params)
        redirect_to admin_subscription_plans_path, notice: "Subscription plan updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @subscription_plan = SubscriptionPlan.find(params[:id])
      authorize @subscription_plan
      if @subscription_plan.user_subscriptions.exists?
        @subscription_plan.update!(active: false)
        redirect_to admin_subscription_plans_path, notice: "Plan deactivated."
      else
        @subscription_plan.destroy
        redirect_to admin_subscription_plans_path, notice: "Plan deleted."
      end
    end

    private

    def subscription_plan_params
      params.require(:subscription_plan).permit(:name, :price, :interval, :stripe_price_id, :description, :active)
    end
  end
end
