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

    return inputs[0].form;
  }

  async fillFieldsAndSubmit() {
     try {
      const form = await this.fillFields();

      if (form) {
        form.requestSubmit();
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
