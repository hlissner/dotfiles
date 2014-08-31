
class Project

    template_folder = "templates"

    def dirs(dirs=[])
        dirs.each do |d|
            mkdir_p d unless Dir.exists? d
        end
    end

    def template(template, dest="", vars={})
        template_file = "#{template_folder}/#{template}.erb"
        dest_file = "#{dest}/#{File.basename(template)}"

        raise "Template file doesn't exist" unless File.exists? template_file
        raise "Destination folder doesn't exist" unless Dir.exists? dest
        raise "Destination file already exists" unless File.exists? dest_file

        erb = ERB.new(File.read(template_file))
        File.open(dest_file) do |f|
            f.puts(erb.result(binding))
        end
    end

end
