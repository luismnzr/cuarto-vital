# frozen_string_literal: true

module Ui
  class TabsComponent < ViewComponent::Base
    renders_many :tabs, ->(label:, id:, active: false, **opts) {
      TabPanel.new(label: label, id: id, active: active, **opts)
    }

    def initialize(id: "tabs")
      @id = id
    end

    class TabPanel < ViewComponent::Base
      attr_reader :label, :tab_id, :active

      def initialize(label:, id:, active: false, **_opts)
        @label = label
        @tab_id = id
        @active = active
      end

      def call
        content_tag :div, content,
          id: "panel-#{@tab_id}",
          class: class_names("tab-panel", hidden: !@active),
          data: { tabs_target: "panel" },
          role: "tabpanel"
      end
    end
  end
end
