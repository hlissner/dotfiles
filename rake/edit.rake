desc "Open a task in your editor"
task :edit, :package do |t, args|
    p "No package specified!" unless args.package

    #prefix = __dir__
    #path = "#{prefix}/#{args.package.gsub(":", "/").strip}.rake"
    begin
        path = Rake.application[args.package].actions.map(&:source_location).first.first
        echo "Opening #{path}"
        sh "$EDITOR #{path}"
    rescue
        error "No task found"
    end
end
