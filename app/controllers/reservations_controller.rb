class ReservationsController < ApplicationController
  before_action :authenticate_user!

  def create
    @studio_class = StudioClass.find(params[:class_id])
    authorize @studio_class, :show?

    result = ReservationService.reserve(user: current_user, studio_class: @studio_class)

    if result.success?
      flash[:notice] = "Class reserved successfully!"
    else
      flash[:alert] = result.error
    end

    redirect_to class_path(@studio_class), status: :see_other
  end

  def destroy
    @reservation = current_user.reservations.find(params[:id])
    authorize @reservation

    result = ReservationService.cancel(reservation: @reservation)

    if result.success?
      if @reservation.late_cancel?
        flash[:notice] = "Reservation cancelled. Note: this was a late cancellation."
      else
        flash[:notice] = "Reservation cancelled. Your credit has been restored."
      end
    else
      flash[:alert] = result.error
    end

    redirect_to class_path(@reservation.studio_class), status: :see_other
  end
end
