file "app/helpers/development/tool_helper.rb", <<~RUBY
  module Development::ToolHelper
    def development_tool(resource_id:)
      return unless Rails.env.development?

      tag.div elements,
        data: {
          controller: "development--tool",
          development__tool_form_data_value: formData,
          development__tool_resource_id_value: resource_id
        }
    end

    private

    def elements = safe_join([buttons, console])

    def buttons
      # You can change the hotkey values to whatever you want
      safe_join([
        tag.button("Fill Fields", data: {action: "development--tool#fillFields", hotkey: "d f"}, hidden: true),
        tag.button("Fill Fields and Submit", data: {action: "development--tool#fillFieldsAndSubmit", hotkey: "d s"}, hidden: true),
        tag.button("Toggle Console", data: {action: "development--tool#toggleConsole", hotkey: "d c"}, hidden: true),
        tag.button("Highlight Turbo Frames", data: {action: "development--tool#toggleHightlightTurboFrames", hotkey: "d t"}, hidden: true),
        tag.button("Highlight Stimulus Controllers", data: {action: "development--tool#toggleHightlightControllers", hotkey: "d e"}, hidden: true),
        tag.button("Copy URL", data: {action: "development--tool#copyUrl", hotkey: "d x"}, hidden: true),
        tag.button("Copy Resource ID", data: {action: "development--tool#copyResourceID", hotkey: "d r"}, hidden: true)
      ])
    end

    def formData
      {
        email: ["support@railsdesigner.com", "support@spinalbuilder.com"],
        name: ["Rails Designer", "Spinal Builder"],
        password: ["password"]
        # etc.
      }
    end
  end
RUBY

file "app/javascript/controllers/development/tool_controller.js", <<~JS
import { Controller } from "@hotwired/stimulus";
import { install, uninstall } from "@github/hotkey";

export default class extends Controller {
  static values = { formData: Object, resourceId: String };

  connect() {
    this.#consoleSetup();

    for (const element of this.#elements) { install(element); }
  }

  disconnect() {
    for (const element of this.#elements) { uninstall(element); }
  }

  async fillFields() {
    const inputs = document.querySelectorAll("input");
    const filledFields = Array.from(inputs).map(input => this.#fillField(input));

    await Promise.all(filledFields);

    // Return the first form object
    return inputs[0].form;
  }

  async fillFieldsAndSubmit() {
     try {
      const form = await this.fillFields();

      if (form) {
        form.submit();
      } else {
        console.error("Form not found");
      }
    } catch (error) {
      console.error("Error filling fields or submitting form:", error);
    }
  }

  toggleConsole() {
    if (!this.#console) { return; }

    this.#console.hidden = !this.#console.hasAttribute("hidden");
  }

  toggleHightlightTurboFrames() {
    this.#toggleElements("turbo-frame", "rgb(239, 68, 68)")
  }

  toggleHightlightControllers() {
    this.#toggleElements("[data-controller]", "rgb(99, 102, 241)", "controller")
  }

  copyUrl() {
    this.#copyToClipboard(window.location.href);
  }

  copyResourceID() {
    if (!this.hasResourceIdValue) { return; }

    this.#copyToClipboard(this.resourceIdValue);
  }

  // private

  #consoleSetup() {
    if (!this.#console) { return; }

    this.#console.hidden = true;
  }

  async #fillField(input) {
    const { name } = input;
    const key = name.split("[").pop().split("]")[0];

    if (input.hidden) return;
    if (!this.formDataValue.hasOwnProperty(key)) return;

    const typeValues = this.formDataValue[key];
    if (!typeValues || typeValues.length === 0) return;

    // Pick a random value from the given type's values
    const randomValue = typeValues[Math.floor(Math.random() * typeValues.length)];

    // Try to fill elements based on tag name first…
    try {
      document.getElementsByName(name).forEach((element) => { element.value = randomValue; });
    } catch (error) {
      console.error(`Error filling field ${input.name}:`, error);
    }
    // … then check input fields by their autocomplete attribute…
    document.querySelectorAll(`input[autocomplete="${key}"]`).forEach((element) => {
      // … but only if the value is blank
      if (element.value.trim() !== "") { return; }

      try {
        element.value = randomValue;
      } catch (error) {
        console.error(`Error filling field ${input.name}:`, error);
      }
    });
  }

  async #copyToClipboard(content) {
    try {
      await navigator.clipboard.writeText(content);
    } catch (error) {
      console.error("Failed to copy content:", error);
    }
  }

  #toggleElements(selector, color, property) {
    const elements = document.querySelectorAll(selector);
    const isHighlighted = [...elements].some(frame => frame.style.outline !== "");

    elements.forEach(frame => {
      frame.style.outline = isHighlighted ? '' : `1px dashed ${color}`

      frame.querySelectorAll(".element-highlight-label").forEach(label => label.remove());

      if (!isHighlighted) { frame.appendChild(this.#elementLabel(frame, color, property)); }
    });
  }

  get #elements() {
    return document.querySelectorAll("[data-hotkey]");
  }

  get #console() {
    return document.getElementById("console")
  }

  #elementLabel(element, color, property = "id") {
    const label = document.createElement("div");

    element.style.position = "relative";

    label.className = "element-highlight-label";
    label.style.cssText = `position: absolute;bottom: 0; left: 0;display:block;padding: 0.125rem 0.25rem;font-size: 0.75rem;font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;background: ${color};color: white;white-space: nowrap;border-radius: 0.25rem;`;
    label.textContent = property === "controller" ? element.dataset[property] : element[property] || "N/A";

    return label;
  }
}
JS

if File.exist?("config/importmap.rb")
  run "./bin/importmap pin @github/hotkey"
else
  if File.exist?("yarn.lock")
    run "yarn add @github/hotkey"
  elsif File.exist?("package-lock.json")
    run "npm add @github/hotkey"
  elsif File.exist?("bun.lockb")
    run "bun add @github/hotkey"
  else
    say "Unable to detect package manager. Please add `@github/hotkey` manually.", :red
  end
end

run "./bin/rails stimulus:manifest:update"

gsub_file "app/views/layouts/application.html.erb", %r{</body>}, <<~ERB
    <%= development_tool(resource_id: yield(:resource_id)) %>
  </body>
ERB

say "Rails and Hotwire Development Tool added successfully! 🎉", :green
say "❤️ Do not forget to check out Rails Designer at https://railsdesigner.com/ ❤️", :green
