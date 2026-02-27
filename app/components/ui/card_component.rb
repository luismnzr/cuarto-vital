# frozen_string_literal: true

module Ui
  class CardComponent < ViewComponent::Base
    renders_one :header
    renders_one :footer

    def initialize(padding: true, border: true, **extra_attrs)
      @padding = padding
      @border = border
      @extra_attrs = extra_attrs
    end

    private

    def css_classes
      class_names(
        "rounded-[var(--radius-lg)] bg-[var(--color-background)] shadow-[var(--shadow-sm)]",
        "border border-[var(--color-border)]" => @border
      )
    end
  end
end
