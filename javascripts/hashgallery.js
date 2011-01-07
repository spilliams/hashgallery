var debug = false
$(document).ready(function(){
  relinkNav()
  if ($(location).attr('hash')) loadH($(location).attr('hash'))
})
function relinkNav() {
  if (debug) console.log('vvv relinking nav vvv')
  $("#nav a").each(function(){
    if ($(this).attr('href')[0]=='/') {
      if (debug) console.log($(this).attr('href').split('.')[0])
      $(this).attr('href','#'+$(this).attr('href').split('.')[0])
      if (debug) console.log($(this).attr('href'))
      $(this).click(function(){loadH($(this).attr('href'))})
    }
    else $(this).attr('target','_blank')
  })
}
function loadH(h) {
  if (debug) console.log('vvv loading hash vvv')
  if (debug) console.log(h)
  if (h=='#/') displayHome()
  else {
    try {
      reloadNav(h)
      reloadFrame(h)
    } catch (err) {
      hl = h.split('/').slice(-1)
      h = '#/'+h.split("/").slice(1,-1).join('/')
      if (debug) console.log('caught error, trying again with '+h)
      loadH(h)
      if (hl != '') {
        if (debug) console.log('trying to highlight '+hl+' now')
        highlight(hl)
      }
    }
  }
}
function reloadFrame(h) {
  if (debug) console.log('vvv reload frame vvv')
  error = false
  $.ajax({async: false, url: h.slice(1)+'.html', success: function(data){
    if (debug) console.log('ajax call succeeded')
    if (!$(data).find("#frame").html()) error = "DIR"
    $("#frame").html($(data).find("#frame").html())
    $("img.thumb").mouseenter(function(){
      highlight($(this).siblings().last().attr('id'))
    })
  }, error: function(){
    if (debug) console.log('ajax call (frame) failed')
    error = "AJAX FRAME"
  }})
  if (error) throw error
}
function reloadNav(h) {
  if (debug) console.log('vvv reload nav vvv')
  $("ul ul").hide('fast')
  error = false
  array = h.split('/')
  array.shift()
  url = ''
  error = false
  linkUnlinkedNav()
  // walk down the tags in the hash
  for (i in array) {
    tag = array[i]
    if (debug) console.log('examining tag '+tag)
    url = url+'/'+tag
    navAElement = $("#nav a[href='#"+url+"']")
    if (debug) console.log('nav a: '+$(navAElement))
    navLiElement = navAElement.parent()
    // unlink it
    if (i == array.length-1)
      navLiElement.html("<span class='unlink'><span class='hidden'>"+navAElement.attr('href')+"</span><span>"+navAElement.html()+"</span></span>") // unlink navAElement
    if (debug) console.log('nav li (after): '+$(navLiElement))
    
    // get the children from Apache
    children = getChildren(url)
    if (debug) console.log(children)
    if (children.length == 0)
      return
    // segregate them into files and directories
    fileChildren = []
    dirChildren = []
    for (i in children) {
      child = children[i]
      if (child[0].slice(-1) != '/')
        fileChildren.push(child)
      else
        dirChildren.push(child)
    }
    // now pull out only the ones that exist in both arrays
    listChildren = []
    for (i in fileChildren) {
      child = fileChildren[i]
      name = child[0].slice(0,child[0].length-5)
      format = child[0].slice(child[0].length-4)
      if (format == 'html') {
        for (j in dirChildren) {
          dir = dirChildren[j]
          dirName = dir[1].slice(0,dir[1].length-1)
          if (name == dirName)
            listChildren.push([name,'#'+url+'/'+name])
        }
      }
      // format into a ul and append
      list = "<ul>"
      for (i in listChildren) {
        child = listChildren[i]
        list += "<li><a href='"+child[1]+"' onclick=\"loadH('"+child[1]+"')\">"+child[0]+"</a></li>"
      }
      list = list+"</ul>"
    }
    $(list).hide().appendTo(navLiElement).show('fast')
    
    if (error) throw error
  }
}
/* HELPER FUNCTIONS */
function displayHome() {
  // reset the nav and the frame to index.html
  $.ajax({async: false, url: '/', success: function(data){
    $("#frame").html($(data).find("#frame").html())
    $("#nav").html($(data).find("#nav").html())
  }, error: function(){
    $("#frame").html("There was a server error. You shouldn't be seeing this message. Anyway, you clearly are, so contact the system administrator.")
  }})
  relinkNav()
}
function getChildren(url, type) {
/* This function goes to a url (directory within root),
 * returns a list of all children of that directory
 * current types implemented are 'file' and 'dir'
 * return format: [[href, name],[href, name],...]
 */
 if (debug) console.log('getting children at '+url)
  children = []
  $.ajax({async: false, url: url, success: function(data) {
    $(data).find("a").slice(1).each(function(){
      child = [$(this).attr('href'),this.innerHTML]
      if ((type=='dir' && $(this).attr('href').slice(-1)=='/') ||
        (type == "file" && $(this).attr('href').slice(-1)!='/') ||
        (type != 'dir' && type != 'file'))
        children.push(child)
    })
  }})
  return children
}
function highlight(s) {
  if ($("#"+s) != undefined) {
    if (debug) console.log('highlighting '+s)
    $("#thumbs .photo:not('#"+s+"')").css('display','none')
    $("#"+s).css('display','block')
  }
}
function linkUnlinkedNav() {
  $(".unlink").each(function(){
    link = $(this).children().first().html()
    name = $(this).children().last().html()
    $(this).replaceWith("<a href='"+link+"' onclick='loadH(\""+link+"\")'>"+name+"</a>")
  })
}
