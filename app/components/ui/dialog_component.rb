# frozen_string_literal: true

module Ui
  class DialogComponent < ViewComponent::Base
    renders_one :trigger
    renders_one :title
    renders_one :footer

    def initialize(id: nil, size: :md)
      @id = id || "dialog-#{SecureRandom.hex(4)}"
      @size = size.to_sym
    end

    private

    def size_class
      case @size
      when :sm then "max-w-sm"
      when :md then "max-w-lg"
      when :lg then "max-w-2xl"
      when :xl then "max-w-4xl"
      else "max-w-lg"
      end
    end
  end
end
