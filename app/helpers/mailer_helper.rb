module MailerHelper
  def studio_name
    StudioSetting.get("studio_name")
  end

  def studio_email
    StudioSetting.get("studio_email")
  end

  def studio_phone
    StudioSetting.get("studio_phone")
  end

  def studio_address
    StudioSetting.get("studio_address")
  end

  def format_class_date(studio_class)
    studio_class.date.strftime("%A, %B %-d, %Y")
  end

  def format_class_time(studio_class)
    studio_class.start_time.strftime("%-I:%M %p")
  end

  def format_date(date)
    date.strftime("%B %-d, %Y")
  end

  def format_currency(amount)
    currency = StudioSetting.currency.upcase
    "$#{'%.2f' % amount} #{currency}"
  end

  def cancellation_window
    StudioSetting.cancellation_window_hours
  end

  def email_button(text, url, color: "#6F7C4E")
    content_tag(:table, role: "presentation", cellpadding: "0", cellspacing: "0", style: "margin: 24px 0;") do
      content_tag(:tr) do
        content_tag(:td, style: "border-radius: 8px; background-color: #{color};") do
          link_to text, url, style: "display: inline-block; padding: 12px 32px; font-size: 14px; font-weight: 600; color: #ffffff; text-decoration: none; border-radius: 8px;", target: "_blank"
        end
      end
    end
  end

  def email_detail_row(label, value)
    content_tag(:tr) do
      content_tag(:td, label, style: "padding: 8px 0; color: #64748b; font-size: 14px; width: 140px; vertical-align: top;") +
      content_tag(:td, value, style: "padding: 8px 0; color: #0f172a; font-size: 14px; font-weight: 500;")
    end
  end
end
