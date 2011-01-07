#!/usr/bin/ruby
def destroy(dir)
  Dir.foreach(dir) do |entry|
    if entry.split('.').last and entry.split('.').last == 'html'
      puts "[INFO] destroying #{dir}/#{entry}"
      File.delete "#{dir}/#{entry}"
    end
  end
  Dir.foreach(dir) do |entry|
    next if entry[0] == 46
    destroy("#{dir}/#{entry}") if File::directory? "#{dir}/#{entry}"
  end
end
destroy(Dir.pwd)
