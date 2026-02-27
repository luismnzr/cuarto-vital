# frozen_string_literal: true

module Ui
  class InputComponent < ViewComponent::Base
    def initialize(name:, type: "text", label: nil, value: nil, placeholder: nil, required: false, disabled: false, error: nil, hint: nil, **extra_attrs)
      @name = name
      @type = type
      @label = label
      @value = value
      @placeholder = placeholder
      @required = required
      @disabled = disabled
      @error = error
      @hint = hint
      @extra_attrs = extra_attrs
    end
  end
end
