# frozen_string_literal: true

module Ui
  class AvatarComponent < ViewComponent::Base
    SIZES = {
      sm: "h-8 w-8 text-xs",
      md: "h-10 w-10 text-sm",
      lg: "h-14 w-14 text-lg",
      xl: "h-20 w-20 text-xl"
    }.freeze

    def initialize(name: "", src: nil, size: :md)
      @name = name
      @src = src
      @size = size.to_sym
    end

    def call
      css = class_names(
        "inline-flex items-center justify-center rounded-full bg-[var(--color-muted)] font-medium text-[var(--color-muted-foreground)] overflow-hidden",
        SIZES[@size]
      )

      if @src
        content_tag :div, class: css do
          tag.img(src: @src, alt: @name, class: "h-full w-full object-cover")
        end
      else
        content_tag :div, initials, class: css
      end
    end

    private

    def initials
      @name.split.map { |n| n[0] }.join.upcase.first(2)
    end
  end
end
