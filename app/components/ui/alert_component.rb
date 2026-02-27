# frozen_string_literal: true

module Ui
  class AlertComponent < ViewComponent::Base
    VARIANTS = {
      default: "bg-[var(--color-background)] text-[var(--color-foreground)] border-[var(--color-border)]",
      destructive: "bg-red-50 text-[var(--color-destructive)] border-[var(--color-destructive)]/30",
      success: "bg-green-50 text-green-800 border-green-200",
      warning: "bg-yellow-50 text-yellow-800 border-yellow-200",
      info: "bg-blue-50 text-blue-800 border-blue-200"
    }.freeze

    def initialize(title: nil, variant: :default, dismissible: false)
      @title = title
      @variant = variant.to_sym
      @dismissible = dismissible
    end
  end
end
