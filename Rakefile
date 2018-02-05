desc "Generates a properties file for each job based on properties.X.Y used in templates"
task :job_properties do
  require "fileutils"
  Dir["jobs/*"].each do |path|
    puts "Searching job #{File.basename(path)}..."
    FileUtils.chdir(path) do
      properties = []
      Dir["templates/*.erb"].each do |template_path|
        properties |= File.read(template_path).scan(/\bproperties\.[\w\.]*\b/)
        puts properties.join("\n")
        File.open("properties", "w") { |file| file << properties.join("\n") }
      end
    end
  end
end

desc "Update the ttar script used for cert management to the latest version available on GitHub"
task :update_ttar do
  require "open-uri"
  File.open("src/ttar/ttar", "w") do |f|
    IO.copy_stream(open("https://raw.githubusercontent.com/jhunt/ttar/master/ttar"), f)
  end
end