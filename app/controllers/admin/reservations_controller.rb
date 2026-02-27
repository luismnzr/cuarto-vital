module Admin
  class ReservationsController < BaseController
    def index
      @reservations = policy_scope(Reservation)
        .includes(:user, studio_class: [:class_template, :teacher])
        .order(created_at: :desc)
      @reservations = @reservations.where(status: params[:status]) if params[:status].present?
      @pagy, @reservations = pagy(@reservations)
    end

    private

    def reservation_params
      params.require(:reservation).permit(:user_id, :studio_class_id, :status)
    end
  end
end
