--[[
  ** Build config for demopkg using l3build **
--]]

-- Identification
module     = "demopkg"
pkgversion = "1.1"
pkgdate    = "2020-02-19"

-- Configuration of files for build and installation
maindir       = "."
sourcefiledir = "./sources"
textfiledir   = "./sources"
textfiles     = {textfiledir.."/CTANREADME.md"}
sourcefiles   = {"demopkg.dtx", "demopkg.ins"}
installfiles  = {"demopkg.pdf", "demopkg.sty", "example.tex", "example.pdf"}
tdslocations  = {
  "source/latex/demopkg/demopkg.dtx",
  "source/latex/demopkg/demopkg.ins",
  "doc/latex/demopkg/example/example.tex",
  "doc/latex/demopkg/example/example.pdf",
  "doc/latex/demopkg/demopkg.pdf",
  "tex/latex/demopkg/demopkg.sty"
}

-- Unpacking files from .dtx file
unpackfiles = {"demopkg.ins"}
unpackopts  = "--interaction=batchmode"
unpackexe   = "luatex"

-- Generating documentation
typesetfiles  = {"demopkg.dtx", "example.tex"}
typesetexe    = "lualatex"
typesetopts   = "--interaction=batchmode"
typesetruns   = 3
makeindexopts = "-q"

-- Build example.tex using pdflatex (one run)
local function type_example()
  local file = jobname(unpackdir.."/example.tex")
  errorlevel = run(unpackdir, "pdflatex --interaction=batchmode "..file..".tex > "..os_null)
  if errorlevel ~= 0 then
    error("** Error!!: pdflatex --interaction=batchmode "..file..".tex")
    return errorlevel
  else
    print("** Running: pdflatex --interaction=batchmode "..file..".tex")
  end
  return 0
end

specialtypesetting = { }
specialtypesetting["example.tex"]= {func = type_example}

-- Update package date and version
tagfiles = {"demopkg.dtx", "CTANREADME.md"}
local mydate = os.date("!%Y-%m-%d")

function update_tag(file, content, tagname, tagdate)
  if not tagname and tagdate == mydate then
    tagname = pkgversion
    tagdate = pkgdate
    print("** "..file.." have been tagged with the version and date of build.lua")
  else
    local v_maj, v_min = string.match(tagname, "^v?(%d+)(%S*)$")
    if not v_maj or not v_min then
      print("Error!!: Invalid tag '"..tagname.."', none of the files have been tagged")
      os.exit(0)
    else
      tagname = string.format("%i%s", v_maj, v_min)
      tagdate = mydate
    end
    print("** "..file.." have been tagged with the version "..tagname.." and date "..mydate)
  end

  if string.match(file, "demopkg.dtx") then
    tagdate = string.gsub(tagdate, "-", "/")
    content = string.gsub(content,
                          "%[%d%d%d%d%/%d%d%/%d%d%s+v%S+",
                          "["..tagdate.." v"..tagname)
  end

  if string.match(file, "CTANREADME.md") then
    tagdate = string.gsub(tagdate, "/", "-")
    content = string.gsub(content,
                          "Version: (%d+)(%S+)",
                          "Version: "..tagname)
    content = string.gsub(content,
                          "Date: %d%d%d%d%-%d%d%-%d%d",
                          "Date: "..tagdate)
  end
  return content
end

-- Configuration for ctan
ctanreadme = "CTANREADME.md"
ctanpkg    = "demopkg"
ctanzip    = ctanpkg.."-"..pkgversion
packtdszip = false

-- Load personal data for ctan upload
local ok, mydata = pcall(require, "mypersonaldata.lua")
if not ok then
  mydata = { email="XXX", uploader="YYY", }
end

uploadconfig = {
  author      = "Your name",
  uploader    = mydata.uploader,
  email       = mydata.email,
  pkg         = ctanpkg,
  version     = pkgversion,
  license     = "lppl1.3c",
  summary     = "A demo package",
  description = [[An example of the use of l3build]],
  topic       = { "Some topic A", "Some topic B" },
  ctanPath    = "/macros/latex/contrib/" .. ctanpkg,
  repository  = "https://github.com/yourrepo/demopkg-jw",
  bugtracker  = "https://github.com/yourrepo/demopkg-jw/issues",
  support     = "https://github.com/yourrepo/demopkg-jw/issues",
  announcement_file="ctan.ann",
  note_file   = "ctan.note",
  update      = true,
}

-- Clean files
cleanfiles = {
  ctanzip..".curlopt",
  ctanzip..".zip",
  "example.log",
  "example.pdf",
  "demopkg.pdf",
}

-- Create check_marked_tags() function
local function check_marked_tags()
  local f = assert(io.open("sources/demopkg.dtx", "r"))
  marked_tags = f:read("*all")
  f:close()

  local m_pkgd, m_pkgv = string.match(marked_tags, "%[(%d%d%d%d%/%d%d%/%d%d)%s+v(%S+)")
  pkgdate = string.gsub(pkgdate, "-", "/")
  if pkgversion == m_pkgv and pkgdate == m_pkgd then
    print("** The version and date marked in demopkg.dtx and build.lua are the same")
  else
    print("** The version and date marked in demopkg.dtx and build.lua are different")
    print("** Check build.lua and run l3build tag again")
  end
end

-- Config tag_hook
function tag_hook(tagname)
  check_marked_tags()
end

-- Add "tagged" target to l3build CLI
if options["target"] == "tagged" then
  check_marked_tags()
  os.exit()
end

-- Create make_temp_dir() function
local function make_temp_dir()
  local tmpname = os.tmpname()
  tempdir = basename(tmpname)
  errorlevel = mkdir(tempdir)
  if errorlevel ~= 0 then
    error("** Error!!: The ./"..tempdir.." directory could not be created")
    return errorlevel
  else
    print("** The ./"..tempdir.." directory has been successfully created")
  end
end

-- Add "testpkg" target to l3build CLI
if options["target"] == "testpkg" then
  make_temp_dir()
  errorlevel = cp("*.*", sourcefiledir, tempdir)
  if errorlevel ~= 0 then
    error("** Error!!: Can't copy files from "..sourcefiledir.." to /"..tempdir)
    return errorlevel
  else
    print("** Copying files from "..sourcefiledir.." to /"..tempdir)
  end
  -- Unpack files
  local file = jobname(tempdir.."/demopkg.ins")
  errorlevel = run(tempdir, "pdftex -interaction=batchmode "..file..".ins > "..os_null)
  if errorlevel ~= 0 then
    error("** Error!!: pdftex -interaction=batchmode "..file..".ins")
    return errorlevel
  else
    print("** Running: pdftex -interaction=batchmode "..file..".ins")
  end
  -- pdflatex
  local file = jobname(tempdir.."/example.tex")
  errorlevel = run(tempdir, "pdflatex -interaction=nonstopmode "..file.." > "..os_null)
  if errorlevel ~= 0 then
    error("** Error!!: pdflatex -interaction=nonstopmode "..file".tex")
    return errorlevel
  else
    print("** Running: pdflatex -interaction=nonstopmode "..file..".tex")
  end
  -- Copying
  print("** Copying "..file..".log and "..file..".pdf files to "..maindir)
  cp("example.log", tempdir, maindir)
  cp("example.pdf", tempdir, maindir)
  -- Clean
  print("** Remove the temporary directory ./"..tempdir)
  cleandir(tempdir)
  lfs.rmdir(tempdir)
  print("** The test has been successfully completed")
  os.exit()
end
