class WaitlistMailer < ApplicationMailer
  def joined(waitlist_entry)
    @entry = waitlist_entry
    @user = waitlist_entry.user
    @studio_class = waitlist_entry.studio_class

    mail(to: @user.email, subject: "Waitlist Confirmed — #{@studio_class.name}")
  end

  def promoted(waitlist_entry)
    @entry = waitlist_entry
    @user = waitlist_entry.user
    @studio_class = waitlist_entry.studio_class

    mail(to: @user.email, subject: "You're In! — #{@studio_class.name}")
  end

  def expired(waitlist_entry)
    @entry = waitlist_entry
    @user = waitlist_entry.user
    @studio_class = waitlist_entry.studio_class

    mail(to: @user.email, subject: "Waitlist Expired — #{@studio_class.name}")
  end
end
