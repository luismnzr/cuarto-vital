# frozen_string_literal: true

module Ui
  class DropdownComponent < ViewComponent::Base
    renders_one :trigger
    renders_many :items, types: {
      link: ->(label:, href:, method: nil, **opts) {
        link_to label, href, method: method, class: "block w-full px-3 py-2 text-sm text-left hover:bg-[var(--color-muted)] rounded-[var(--radius-sm)] transition-colors", **opts
      },
      button: ->(label:, **opts) {
        content_tag :button, label, type: "button", class: "block w-full px-3 py-2 text-sm text-left hover:bg-[var(--color-muted)] rounded-[var(--radius-sm)] transition-colors", **opts
      },
      divider: ->(**) {
        tag.hr(class: "my-1 border-[var(--color-border)]")
      }
    }

    def initialize(align: :right)
      @align = align
    end
  end
end
