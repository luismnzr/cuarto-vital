class WaitlistEntriesController < ApplicationController
  before_action :authenticate_user!

  def create
    @studio_class = StudioClass.find(params[:class_id])
    authorize @studio_class, :show?

    result = WaitlistService.join(user: current_user, studio_class: @studio_class)

    if result.success?
      flash[:notice] = "You've been added to the waitlist (position ##{result.entry.position})."
    else
      flash[:alert] = result.error
    end

    redirect_to class_path(@studio_class), status: :see_other
  end

  def destroy
    @entry = current_user.waitlist_entries.find(params[:id])
    authorize @entry

    result = WaitlistService.leave(entry: @entry)

    if result.success?
      flash[:notice] = "You've been removed from the waitlist."
    else
      flash[:alert] = result.error
    end

    redirect_to class_path(@entry.studio_class), status: :see_other
  end
end
