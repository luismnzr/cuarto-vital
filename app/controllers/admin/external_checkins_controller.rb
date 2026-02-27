# frozen_string_literal: true

module Admin
  class ExternalCheckinsController < BaseController
    def index
      @checkins = policy_scope(ExternalCheckin)
                    .includes(:studio_class)
                    .order(checked_in_at: :desc)
      @checkins = @checkins.by_platform(params[:platform]) if params[:platform].present?
      authorize ExternalCheckin
    end

    def new
      @checkin = ExternalCheckin.new(checked_in_at: Time.current)
      authorize @checkin
      @classes = StudioClass.scheduled.where("date >= ?", Date.current).order(:date, :start_time)
    end

    def create
      @checkin = ExternalCheckin.new(checkin_params)
      authorize @checkin
      if @checkin.save
        redirect_to admin_external_checkins_path, notice: "Check-in recorded."
      else
        @classes = StudioClass.scheduled.where("date >= ?", Date.current).order(:date, :start_time)
        render :new, status: :unprocessable_entity
      end
    end

    def validate
      @checkin = ExternalCheckin.find(params[:id])
      authorize @checkin, :update?
      @checkin.update!(validated: true)
      redirect_to admin_external_checkins_path, notice: "Check-in validated."
    end

    private

    def checkin_params
      params.require(:external_checkin).permit(:user_identifier, :platform, :studio_class_id, :checked_in_at, :external_reference_id)
    end
  end
end
