# frozen_string_literal: true

require "csv"

module Admin
  class WellhubBookingsController < BaseController
    def index
      @bookings = policy_scope(WellhubBooking)
        .includes(studio_class: [:class_template, :teacher])
        .order(created_at: :desc)

      @bookings = @bookings.where(status: params[:status]) if params[:status].present?

      respond_to do |format|
        format.html do
          @pagy, @bookings = pagy(@bookings)
          @stats = {
            total: policy_scope(WellhubBooking).count,
            accepted: policy_scope(WellhubBooking).where(status: "accepted").count,
            checked_in: policy_scope(WellhubBooking).where(status: "checked_in").count,
            cancelled: policy_scope(WellhubBooking).where(status: "cancelled").count
          }
        end
        format.csv do
          send_data generate_csv(@bookings),
                    filename: "wellhub_bookings_#{Date.current.iso8601}.csv",
                    type: "text/csv"
        end
      end
    end

    def show
      @booking = WellhubBooking.find(params[:id])
      authorize @booking
    end

    private

    def generate_csv(bookings)
      CSV.generate(headers: true) do |csv|
        csv << [
          "Booking Number", "Gympass ID", "Status", "Class Name", "Date", "Time",
          "Teacher", "Booked At", "Responded At", "Checked In At", "Cancelled At"
        ]

        bookings.find_each do |b|
          sc = b.studio_class
          csv << [
            b.booking_number,
            b.gympass_id,
            b.status,
            sc.name,
            sc.date&.iso8601,
            sc.start_time&.strftime("%H:%M"),
            sc.teacher&.full_name,
            b.booked_at&.strftime("%Y-%m-%d %H:%M:%S"),
            b.responded_at&.strftime("%Y-%m-%d %H:%M:%S"),
            b.checked_in_at&.strftime("%Y-%m-%d %H:%M:%S"),
            b.cancelled_at&.strftime("%Y-%m-%d %H:%M:%S")
          ]
        end
      end
    end
  end
end
