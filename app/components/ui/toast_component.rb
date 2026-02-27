# frozen_string_literal: true

module Ui
  class ToastComponent < ViewComponent::Base
    VARIANTS = {
      notice: "bg-[var(--color-background)] border-[var(--color-border)]",
      alert: "bg-red-50 border-[var(--color-destructive)]/30",
      success: "bg-green-50 border-green-200"
    }.freeze

    def initialize(message:, variant: :notice)
      @message = message
      @variant = variant.to_sym
    end
  end
end
