# frozen_string_literal: true

module Ui
  class BadgeComponent < ViewComponent::Base
    VARIANTS = {
      default: "bg-[var(--color-primary)] text-[var(--color-primary-foreground)]",
      secondary: "bg-[var(--color-secondary)] text-[var(--color-secondary-foreground)]",
      destructive: "bg-[var(--color-destructive)] text-[var(--color-destructive-foreground)]",
      success: "bg-[var(--color-success)] text-[var(--color-success-foreground)]",
      warning: "bg-[var(--color-warning)] text-[var(--color-warning-foreground)]",
      outline: "border border-[var(--color-border)] text-[var(--color-foreground)]"
    }.freeze

    def initialize(text: nil, variant: :default)
      @text = text
      @variant = variant.to_sym
    end

    def call
      css = class_names(
        "inline-flex items-center rounded-[var(--radius-full)] px-2.5 py-0.5 text-xs font-medium transition-colors",
        VARIANTS[@variant]
      )
      content_tag :span, @text || content, class: css
    end
  end
end
