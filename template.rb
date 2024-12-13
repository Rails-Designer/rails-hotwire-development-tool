require "open-uri"

file "app/helpers/development/tool_helper.rb", read_file("https://raw.githubusercontent.com/Rails-Designer/rails-hotwire-development-tool/main/template/tool_helper.rb")
file "app/javascript/controllers/development/tool_controller.js", read_file("https://raw.githubusercontent.com/Rails-Designer/rails-hotwire-development-tool/main/template/tool_controller.js")

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

def read_file(url)
  URI.open(url).read
rescue OpenURI::HTTPError => error
  puts "[RHDT] Could not download file: `#{error.message}`"
  nil
rescue StandardError => error
  puts "[RHDT] Count not read file: `#{error.message}`"
  nil
end
