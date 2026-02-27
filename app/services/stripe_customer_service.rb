class StripeCustomerService
  def self.find_or_create(user)
    return user.stripe_customer_id if user.stripe_customer_id.present?

    customer = Stripe::Customer.create(
      email: user.email,
      name: user.full_name,
      metadata: { user_id: user.id }
    )

    user.update!(stripe_customer_id: customer.id)
    customer.id
  end
end
