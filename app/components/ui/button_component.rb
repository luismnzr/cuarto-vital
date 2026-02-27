# frozen_string_literal: true

module Ui
  class ButtonComponent < ViewComponent::Base
    VARIANTS = {
      primary: "bg-[var(--color-primary)] text-[var(--color-primary-foreground)] hover:opacity-90",
      secondary: "bg-[var(--color-secondary)] text-[var(--color-secondary-foreground)] hover:bg-[var(--color-border)]",
      destructive: "bg-[var(--color-destructive)] text-[var(--color-destructive-foreground)] hover:opacity-90",
      outline: "border border-[var(--color-border)] bg-transparent hover:bg-[var(--color-secondary)]",
      ghost: "hover:bg-[var(--color-secondary)]",
      link: "text-[var(--color-primary)] underline-offset-4 hover:underline"
    }.freeze

    SIZES = {
      sm: "h-8 px-3 text-xs",
      md: "h-10 px-4 text-sm",
      lg: "h-12 px-6 text-base"
    }.freeze

    def initialize(variant: :primary, size: :md, full_width: false, disabled: false, type: "button", href: nil, method: nil, data: {}, **extra_attrs)
      @variant = variant.to_sym
      @size = size.to_sym
      @full_width = full_width
      @disabled = disabled
      @type = type
      @href = href
      @method = method
      @data = data
      @extra_attrs = extra_attrs
    end

    def call
      css = class_names(
        "inline-flex items-center justify-center font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)] focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
        "rounded-[var(--radius-md)]",
        VARIANTS[@variant],
        SIZES[@size],
        "w-full" => @full_width
      )

      if @href
        link_to @href, class: css, method: @method, data: @data, **@extra_attrs do
          content
        end
      else
        content_tag :button, content, type: @type, class: css, disabled: @disabled, data: @data, **@extra_attrs
      end
    end
  end
end
