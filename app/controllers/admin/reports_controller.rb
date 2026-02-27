module Admin
  class ReportsController < BaseController
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped

    def index
      respond_to do |format|
        format.html
        format.csv { send_csv_export }
      end
    end

    private

    def send_csv_export
      case params[:export]
      when "revenue"
        send_data revenue_csv, filename: "revenue-#{Date.current}.csv", type: "text/csv"
      when "attendance"
        send_data attendance_csv, filename: "attendance-#{Date.current}.csv", type: "text/csv"
      when "students"
        send_data students_csv, filename: "students-#{Date.current}.csv", type: "text/csv"
      when "teachers"
        send_data teachers_csv, filename: "teachers-#{Date.current}.csv", type: "text/csv"
      when "shop"
        send_data shop_csv, filename: "shop-orders-#{Date.current}.csv", type: "text/csv"
      else
        redirect_to admin_reports_path, alert: "Unknown export type."
      end
    end

    def revenue_csv
      require "csv"
      CSV.generate(headers: true) do |csv|
        csv << ["Date", "Student", "Email", "Package", "Price", "Credits"]
        UserPackage.includes(:user, :package).order(created_at: :desc).find_each do |up|
          csv << [
            up.created_at.strftime("%Y-%m-%d"),
            up.user.full_name,
            up.user.email,
            up.package.name,
            up.package.price,
            up.package.credit_count
          ]
        end
      end
    end

    def attendance_csv
      require "csv"
      CSV.generate(headers: true) do |csv|
        csv << ["Date", "Class", "Teacher", "Student", "Email", "Status", "Booked At", "Late Cancel"]
        Reservation.includes(:user, studio_class: [:class_template, :teacher]).order(created_at: :desc).find_each do |r|
          csv << [
            r.studio_class.date.strftime("%Y-%m-%d"),
            r.studio_class.name,
            r.studio_class.teacher.full_name,
            r.user.full_name,
            r.user.email,
            r.status,
            r.created_at.strftime("%Y-%m-%d %H:%M"),
            r.late_cancel? ? "Yes" : "No"
          ]
        end
      end
    end

    def students_csv
      require "csv"
      CSV.generate(headers: true) do |csv|
        csv << ["Name", "Email", "Phone", "Joined", "Reservations", "Active Package", "Subscription"]
        User.students.order(:last_name).find_each do |u|
          csv << [
            u.full_name,
            u.email,
            u.phone,
            u.created_at.strftime("%Y-%m-%d"),
            u.reservations.confirmed.count,
            u.active_package&.package&.name || "None",
            u.has_active_subscription? ? "Active" : "None"
          ]
        end
      end
    end

    def teachers_csv
      require "csv"
      CSV.generate(headers: true) do |csv|
        csv << ["Name", "Email", "Phone", "Joined", "Total Classes", "Classes This Month"]
        User.teachers.order(:last_name).find_each do |u|
          csv << [
            u.full_name,
            u.email,
            u.phone,
            u.created_at.strftime("%Y-%m-%d"),
            u.teaching_classes.count,
            u.teaching_classes.where("date >= ? AND date <= ?", Date.current.beginning_of_month, Date.current.end_of_month).count
          ]
        end
      end
    end

    def shop_csv
      require "csv"
      CSV.generate(headers: true) do |csv|
        csv << ["Order #", "Date", "Customer", "Product", "Qty", "Unit Price", "Subtotal", "Payment Method", "Status"]
        Order.includes(:user, order_items: :product).order(created_at: :desc).find_each do |order|
          order.order_items.each do |item|
            csv << [
              order.id,
              order.created_at.strftime("%Y-%m-%d %H:%M"),
              order.user&.full_name || "Walk-in",
              item.product.name,
              item.quantity,
              item.unit_price,
              item.quantity * item.unit_price,
              order.payment_method,
              order.status
            ]
          end
        end
      end
    end
  end
end
