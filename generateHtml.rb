#!/usr/bin/ruby

def generateTree(root, node)
  # obtain a tree of names
  Dir.foreach(node[:dir]) do |entry|
    next if ignore entry
    next unless File::directory? node[:dir]+'/'+entry
    
    child = {}
    child[:dir] = node[:dir]+'/'+entry
    child[:path] = node[:path]+'/'+entry
    child[:title] = entry
    puts "What should the title for #{child[:path]} be? (leave blank for '#{child[:title]}')"
    t = gets
    child[:title] = t unless t == "\n"
    child[:children] = []
      
    generateTree(root,child)
      
    node[:children].push(child)
  end
end
def generateNav(node, parentNav)
  puts "[INFO] generating nav for #{node[:path]}"
  # look in parentNav for an li with this path and title
  needle = "<a href='#{node[:path]}.html'>#{node[:title]}</a>"
  i = parentNav.index(needle) + needle.length
  # add submenu
  node[:nav] = parentNav.slice(0,i)+"<ul>"
  node[:children].each do |child|
    node[:nav] += "<li><a href='#{child[:path]}.html'>#{child[:title]}</a></li>"
  end
  node[:nav] += "</ul>"+parentNav.slice(i,parentNav.length)
  node[:children].each do |child|
    generateNav(child, node[:nav])
  end
end
def generateFrame(node)
  puts "[INFO] generating frame for #{node[:path]}"
  c = ''
  first = true
  Dir.foreach(node[:dir]) do |entry|
    next if ignore entry
    ext = entry.split('.').last
    name = entry.slice(0,entry.length-ext.length-1)
    if ext == 'jpg' or ext == 'jpeg' or ext == 'png'
      # some are foo.jpg, some are foo_thumb.jpg
      next if entry.index '_thumb'
      if File::exists? node[:dir]+"/"+name+"_thumb."+ext
        thumbhref=node[:path]+'/'+name+'_thumb.'+ext
      else
        thumbhref=node[:path]+'/'+name+'.'+ext
      end
      c += "\n<div class='thumb'><img class='thumb' src='#{thumbhref}'><div id='#{name}' class='photo'"
      c += " style=\"display:block\" " if first
      c += "><img src='#{node[:path]}/#{name}.#{ext}'></div></div>"
      first = false
    end
  end
  node[:frame] = "<div id='thumbs'>#{c}</div>"
  node[:children].each do |child|
    generateFrame child
  end
end
def generate(root, node)
  node[:children].each do |child|
    generate root, child
  end
  puts "[INFO] generating html for #{node[:path]}"
  c = html(node[:title],headInclude(root),node[:nav],node[:frame])
  f = File::new "#{node[:dir]}.html", "w"
  f.write c
  f.close
end

def headInclude(root)
  # exit with error if required files do not exist
  missing = false
  unless File::exists? "#{root[:dir]}/javascripts/hashgallery.js"
    missing = true
    puts "/javascripts/hashgallery.js missing"
  end
  unless File::exists? "#{root[:dir]}/stylesheets/hashgallery.css"
    missing = true
    puts "/stylesheets/hashgallery.css missing"
  end
  raise RuntimeError if missing
  
  c = ""
  
  foundjQuery = false
  Dir.foreach("#{root[:dir]}/javascripts") do |child|
    if child.match /jquery(.min)?(.[0-9]+)*.js/i
      foundjQuery = child
      c += "\n<script type=\"text/javascript\" src=\"/javascripts/#{child}\"></script>" if child.split('.').last == 'js'
    end
  end
  c += "\n<script type=\"text/javascript\" src=\"http://ajax.googleapis.com/ajax/libs/jquery/1.4.1/jquery.min.js\"></script>" unless foundjQuery
  
  # include favicon
  c += "\n<link rel=\"shortcut icon\" href=\"/img/favicon.ico\" type=\"image/x-icon\" />" if File::exists? "#{root[:dir]}/img/favicon.ico"
  c += "\n<link rel=\"shortcut icon\" href=\"/favicon.ico\" type=\"image/x-icon\" />" if File::exists? "#{root[:dir]}/favicon.ico"
  
  # include javascripts and stylesheets
  Dir.foreach("#{root[:dir]}/javascripts") do |child|
    if !foundjQuery or child != foundjQuery
      c += "\n<script type=\"text/javascript\" src=\"/javascripts/#{child}\"></script>" if child.split('.').last == 'js'
    end
  end
  Dir.foreach("#{root[:dir]}/stylesheets") do |child|
    c += "\n<link rel=\"stylesheet\" type=\"text/css\" href=\"/stylesheets/#{child}\" />" if child.split('.').last == 'css'
  end
  
  c
end
def html(title, head, nav, frame)
  "<!DOCTYPE html>
  <html dir=\"ltr\" lang=\"en-US\">
  <head>
    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
    <title>#{title}</title>
    #{head}
  </head>
  <body>
    <div>
      <div id='nav'>#{nav}</div>
      <div id='frame'>#{frame}</div>
    </div>
  </body>
  </html>"
end
def ignore(entry)
  ignore = false
  ignore = true if entry == "javascripts" or entry == "stylesheets" or entry == "img"or entry[0] == 46
  ignore
end

root = {}
root[:dir] = Dir.pwd
root[:path] = ''
root[:title] = 'index'
puts "What should the title for the homepage be? (leave blank for 'index')"
t = gets
root[:title] = t unless t == "\n"
root[:children] = []

generateTree(root, root)

# we now have a tree representation of the entire website

# generate the nav for each node
root[:nav] = "<ul><li><a href='/'>#{root[:title]}</a></li>"
root[:children].each do |child|
  root[:nav] += "<li><a href='#{child[:path]}.html'>#{child[:title]}</a></li>"
end
root[:nav] += "</ul>"
#puts root[:nav]
root[:children].each do |child|
  generateNav child, root[:nav]
end

# generate the frame for each node
c = ''
Dir.foreach(root[:dir]) do |entry|
  next if ignore entry
  ext = entry.split('.').last
  name = entry.slice(0,entry.length-ext.length-1)
  if ext == 'jpg' or ext == 'jpeg' or ext == 'png'
    # some are foo.jpg, some are foo_thumb.jpg
    next if entry.index '_thumb'
    if File::exists? root[:dir]+"/"+name+"_thumb."+ext
      thumbhref='/'+name+'_thumb.'+ext
    else
      thumbhref='/'+name+'.'+ext
    end
    c += "\n<div class='thumb'><img class='thumb' src='#{thumbhref}'><div id='#{name}' class='photo'><img src='/#{name}.#{ext}'></div></div>"
  end
end
root[:frame] = "<div id='thumbs'>#{c}</div>"

root[:children].each do |child|
  generateFrame child
end

#puts root[:frame]

# generate html for each node
c = html(root[:title],headInclude(root),root[:nav],root[:frame])
f = File::new "#{root[:dir]}/index.html", "w"
f.write c
f.close

root[:children].each do |child|
  generate root, child
end
