module Development::ToolHelper
  def development_tool(resource_id:)
    return unless Rails.env.development?

    tag.div elements,
      data: {
        controller: "development--tool",
        development__tool_form_data_value: form_data,
        development__tool_resource_id_value: resource_id
      }
  end

  private

  BUTTONS_VALUES = [
    { label: "Fill Fields", action: "development--tool#fillFields", hotkey: "d f" },
    { label: "Fill Fields and Submit", action: "development--tool#fillFieldsAndSubmit", hotkey: "d s" },
    { label: "Toggle Console", action: "development--tool#toggleConsole", hotkey: "d c" },
    { label: "Highlight Turbo Frames", action: "development--tool#toggleHightlightTurboFrames", hotkey: "d t" },
    { label: "Highlight Stimulus Controllers", action: "development--tool#toggleHightlightControllers", hotkey: "d e" },
    { label: "Copy URL", action: "development--tool#copyUrl", hotkey: "d x" },
    { label: "Copy Resource ID", action: "development--tool#copyResourceID", hotkey: "d r" }
  ].freeze

  def elements = safe_join([buttons, console])

  def buttons
    safe_join(
      BUTTONS_VALUES.map do |button|
        tag.button(
          button[:label],
          data: { action: button[:action], hotkey: button[:hotkey] },
          hidden: true
        )
      end
    )
  end

  def form_data
    {
      email: ["support@railsdesigner.com", "support@spinalbuilder.com"],
      name: ["Rails Designer", "Spinal Builder"],
      password: ["password"]
      # etc.
    }
  end
end
