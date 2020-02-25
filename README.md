# demopkg-jw: How to use l3build and not die trying :)

This is a question that I have tried to answer for myself and it has taken
longer than I expected.

[l3build](https://ctan.org/pkg/l3build) is a powerful tool developed and
used by ["The LaTeX3 Project"](https://www.latex-project.org/latex3/) for
the automation and testing of the project packages and the kernel itself,
now available for public use and used by notable projects such as [fontspec](https://github.com/wspr/fontspec)
and [luaotfload](https://github.com/latex3/luaotfload) among others.

One of the advantages of `l3build` is its portability between operating
systems and the amount of _pre-defined_ functions to generate documentation
and regression testing. This tool is also very useful for package developers
or users who want to share and automate your LaTeX projects using GitHub for example.

After reading the documentation and reviewing the [_"illustrative examples"_](https://github.com/latex3/l3build/tree/master/examples)
I have managed to make `l3build` work with a LaTeX2e package (without using regression testing).

**I leave the idea here**

For the purposes of this example we will use and adapted version the now _classic_
["A model .dtx file"](https://www.texdev.net/2009/10/06/a-model-dtx-file/) by Joseph Wright.

---
# **Contents**

**[Part I: Basic Configuration](#heading--1)**

**[1. Create the directory structure for our project](#heading--1)**

  * [1.1 Development structure](#heading--1-1)
  * [1.2 Installation structure](#heading--1-2)
  * [1.3 Command line interface \(CLI\)](#heading--1-3)


**[2. Setting up the file build.lua](#heading--2)**

  * [2.1 Basic identification of our project](#heading--2-1)
  * [2.2 Configuration of files for build and installation](#heading--2-2)
  * [2.3 Unpacking files from .dtx file](#heading--2-3)
  * [2.4 Generating documentation and example](#heading--2-4)
  * [2.5 Update package date and version](#heading--2-5)
  * [2.6 Configuration for CTAN](#heading--2-6)
    * [2.6.1 Load personal data for CTAN upload](#heading--2-6-1)
    * [2.6.2 Config CTAN upload](#heading--2-6-2)
  * [2.7 Clean files](#heading--2-7)

**[Part II: Advanced Configuration](#heading--3)**

**[3. Adding extra features to l3build](#heading--3)**

  * [3.1 Checking version and date](#heading--3-1)
    * [3.1.1 Creating the check\_marked\_tags\(\) function](#heading--3-1-1)
    * [3.1.2 Configuring the tag\_hook\(tagname\) function](#heading--3-1-2)
    * [3.1.3 Adding the "tagged" target to l3build CLI](#heading--3-1-3)

  * [3.2 Create a old-style test for package](#heading--3-2)
    * [3.2.1 Creating the make\_temp\_dir\(\) function](#heading--3-2-1)
    * [3.2.2 Adding the "testpkg" target to l3build CLI](#heading--3-2-2)

**[4. Customizing the creation of documentation](#heading--4)**

  * [4.1 Compiling documentation step by step](#heading--4-1)
    * [4.1.1 Configuring typeset\(file\) function](#heading--4-1-1)
    * [4.1.2 Separate compilations by file in typeset\(file\)](#heading--4-1-2)
  * [4.2 Compiling documentation using latex>dvips>ps2pdf](#heading--4-2)
  * [4.3 Using latexmk to compile documentation](#heading--4-3)
  * [4.4 Using arara to compile documentation](#heading--4-4)

**[5. Setting up Releases and GitHub](#heading--5)**

  * [5.1 Creating the os\_capture\(cmd, raw\) function](#heading--5-1)
  * [5.2 Recording git command output](#heading--5-2)
  * [5.3 Adding the "release" target to l3build CLI](#heading--5-3)

---

<a name="heading--1"/>

# 1. Create the directory structure for our project

An important point to keep in mind is how we order our files and how we
expect them to be located.

<a name="heading--1-1"/>

## 1.1 Development structure

We will create the directory structure for our project. It should look
like this:

```
demopkg-jw/
├── build.lua
├── ctan.ann
├── ctan.note
├── mypersonaldata.lua
├── README.md
└── sources
    ├── CTANREADME.md
    └── demopkg.dtx
```

The `demopkg.dtx` file includes `demopkg.sty` and `example.tex` which
is extracted by using `luatex demopkg.dtx`.

<a name="heading--1-2"/>

## 1.2 Installation structure

For the installation structure you should try to follow the [TDS](https://ctan.org/pkg/tds)
model. The installation we expect in our TDS tree (`TEXMFHOME`) will be like this:

```
TDS:doc/latex/demopkg/demopkg.pdf
TDS:doc/latex/demopkg/example/example.pdf
TDS:doc/latex/demopkg/example/example.tex
TDS:doc/latex/demopkg/README.md
TDS:tex/latex/demopkg/demopkg.sty
TDS:source/latex/demopkg/demopkg.dtx
```

<a name="heading--1-3"/>

# 1.3 Command line interface \(CLI\)

The use of `l3build` from the command line is:

```
l3build <target> [<options>]
```

Some of the default targets:

```bash
l3build unpack
l3build unpack -q
l3build install
l3build install --full --dry-run -q
l3build install --full
l3build uninstall
l3build doc
l3build tag
l3build tag v1.2
l3build tag v1.2a-beta
l3build ctan
l3build upload --debug
l3build upload
l3build clean
```

Some of the _customised_ `targets`:

```bash
l3build testpkg
l3build tagged
```

<a name="heading--2"/>

# 2. Setting up the file build.lua

<a name="heading--2-1"/>

## 2.1 Basic identification of our project

The first thing we have to do is place the identification of our package.

```lua
module     = "demopkg"
pkgversion = "1.1"
pkgdate    = "2020-02-19"
```

> **NOTE:** The `pkgdate` variable must be in ISO format (`Y-M-D`), the `pkgversion`
> variable must NOT start with `v`, only integers followed by a period (usually) and then
> characters other than spaces (there is no standard for versioning a package).

<a name="heading--2-2"/>

## 2.2 Configuration of files for build and installation

Now we set the variables to find our source files and define the [TDS](https://ctan.org/pkg/tds)
structure of our package.

```lua
maindir       = "."
sourcefiledir = "./sources"
textfiledir   = "./sources"
textfiles     = {textfiledir.."/CTANREADME.md"}
sourcefiles   = {"demopkg.dtx"}
installfiles  = {"demopkg.pdf", "demopkg.sty", "example.tex", "example.pdf"}
tdslocations  = {
  "source/latex/demopkg/demopkg.dtx",
  "doc/latex/demopkg/example/example.tex",
  "doc/latex/demopkg/example/example.pdf",
  "doc/latex/demopkg/demopkg.pdf",
  "tex/latex/demopkg/demopkg.sty"
}
```

<a name="heading--2-3"/>

## 2.3 Unpacking files from .dtx file

Now we set the variables to unpack the files in our package.

```lua
unpackfiles = {"demopkg.dtx"}
unpackopts  = "--interaction=batchmode"
unpackexe   = "luatex"
```

When you run `l3build unpack -q` and check the `build/unpacked/` directory
you should see this:

```
build/unpacked/
├── demopkg.dtx
├── demopkg.log
├── demopkg.sty
└── example.tex
```

<a name="heading--2-4"/>

## 2.4 Generating documentation

Now we set the variables to _typeset_ the package documentation and
example file. The instructions for generating the main documentation `demopkg.pdf`
documentation are as follows:

```
lualatex --interaction=nonstopmode demopkg.dtx
makeindex -s gind.ist -o demopkg.ind demopkg.idx
makeindex -s gglo.ist -o demopkg.gls demopkg.glo
lualatex --interaction=nonstopmode demopkg.dtx
lualatex --interaction=nonstopmode demopkg.dtx
```

The instructions for generating the example file `example.pdf`
are as follows:

```
pdflatex --interaction=batchmode example.tex
```

That is, the documentation will be generated with `lualatex` and the
example with `pdflatex`.

Now we pass the instructions to `build.lua`, this will automatically detect
the necessary steps to generate a correct documentation.

```lua
typesetfiles  = {"demopkg.dtx", "example.tex"}
typesetexe    = "lualatex"
typesetopts   = "--interaction=batchmode"
typesetruns   = 3
makeindexopts = "-q"
```

The latest version of `l3build` provides `specialtypesetting` with which
we will compile our example.

```lua
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
```

When you run `l3build install --full --dry-run -q` you should see this:

```
For installation inside /home/yourname/texmf:
- source/latex/demopkg/demopkg.dtx
- doc/latex/demopkg/demopkg.pdf
- doc/latex/demopkg/example/example.pdf
- doc/latex/demopkg/CTANREADME.md
- tex/latex/demopkg/demopkg.sty
- doc/latex/demopkg/example/example.tex
```

> **NOTE:** Don't worry about the name of the file `CTANREADME.md`, it will
> be automatically renamed to `README.md` by `l3build`.

<a name="heading--2-5"/>

## 2.5 Update package date and version

One of the most important things in the minute of developing a package is to
have good control over the versions/dates in which it has been developed. We'll
set the `tagfiles` variable with the two files we'll track `demopkg.dtx` and
`CTANREADME.md`.

We should keep in mind the [patterns](https://www.lua.org/pil/20.2.html) that has
our a file, for example, the common line of identification of a LaTeX2e package
is like this:

```
\ProvidesPackage{pkgname}[2020/02/19 v1.1 Description]
```

and the identification in the `CTANREADME.md` file is like this:

```
- Date: 2020-02-19
- Version: 1.1
```

With this present we will create the [patterns](https://www.lua.org/pil/20.2.html)
for the capture, replacement and validation of the versions and dates.

```lua
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
    local tagdate = string.gsub(tagdate, "-", "/")
    content = string.gsub(content,
                          "%[%d%d%d%d%/%d%d%/%d%d%s+v%S+",
                          "["..tagdate.." v"..tagname)
  end

  if string.match(file, "CTANREADME.md") then
    local tagdate = string.gsub(tagdate, "/", "-")
    content = string.gsub(content,
                          "Version: (%d+)(%S+)",
                          "Version: "..tagname)
    content = string.gsub(content,
                          "Date: %d%d%d%d%-%d%d%-%d%d",
                          "Date: "..tagdate)
  end
  return content
end
```

> **NOTE:** In the configuration of function `update_tag` we have added
> some checks that are not configured by default in `l3build`. Using the
> `l3build tag` will take the variables defined in `build.lua`, using the
> `l3build tag v1.4` will set the version to `1.4` in the files, but will
> not modify the variables in `l3build.lua`. If any `tag` is invalid it
> will return an error.

<a name="heading--2-6"/>

## 2.6 Configuration for CTAN

We set the configuration variables for [CTAN](https://ctan.org/). The
`CTANREADME.md` file must be placed in the `textfiles` and `ctanreadme`
variables, when running `l3build ctan` it will be renamed to `README.md`.

```lua
ctanreadme = "CTANREADME.md"
ctanpkg    = "demopkg"
ctanzip    = ctanpkg.."-"..pkgversion
packtdszip = false
```

> **NOTE:** The support for markdown in [CTAN](https://ctan.org/) is not
> the same as in Github, it is advisable to check [Which markdown syntax is recognized for the readme files?](https://ctan.org/help/markdown)
> and test the file on [Markdown Tester](https://ctan.org/markdown).

<a name="heading--2-6-1"/>

### 2.6.1 Load personal data for CTAN upload

Some of the variables can be handled from an external file, for example
`mypersonaldata.lua` will have the following information:

```lua
return
  {
    ["uploader"] = "Your name",
    ["email"] = "you@your.domain"
  }
```

To load it into `build.lua` we use the following lines:

```lua
local ok, mydata = pcall(require, "mypersonaldata.lua")
if not ok then
  mydata = {email="XXX", uploader="YYY"}
end
```

> **NOTE:** The `email` variable can be passed from the command line
> using `l3build updload -e you@your.domain`.

<a name="heading--2-6-2"/>

### 2.6.2 Config CTAN upload <a name="heading--2-6-2"/>

The basic configuration for uploading our package to [CTAN](https://ctan.org/).
The variables `announcement_file` and `note_file` load the files that will
be sent to [CTAN](https://ctan.org/) when our package is uploaded. In this
example, the `ctan.ann` file will look like this:

```
- Fixed some bugs in previus version
```

And the `ctan.note` file will look like this:

```
Please add the file `example.tex` to:
doc/latex/demopkg/example/example.tex
Thanks
```

The lines we'll add to `build.lua` will be:

```lua
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
  update      = true
}
```

> **NOTE:** It is always recommended that you first use `l3build upload --debug`
> and check the `.curlopt` file. If you are uploading a package to [CTAN](https://ctan.org/)
> for the first time, you should change the `update = false` variable. The
> files generated from the `.dtx` file will not be included in the `.zip`
> file, if you want this to be possible you should add it as a note to
> the [CTAN](https://ctan.org/) maintainers.

<a name="heading--2-7"/>

## 2.7 Clean files

We add extra files that are _not_ automatically deleted by `l3buil clean` to
the `cleanfiles` variable.

```lua
cleanfiles = {
  ctanzip..".curlopt",
  ctanzip..".zip",
  "example.log",
  "example.pdf",
  "demopkg.pdf"
}
```

---

> At this point we have finished configuring our package for development
> using `l3build`, but ... you can always do a **"little"** more.

---

<a name="heading--3"/>

# 3. Adding extra features to l3build

One of the advantages of `l3build` is that it allows you to add [functions](https://www.lua.org/pil/5.html)
and `targets` in `build.lua`. It is true that it comes with many useful
functions, targets and options _pre-defined_, but, one can add one's own
that fits the needs.

<a name="heading--3-1"/>

## 3.1 Checking version and date

To check that the **version** and **dates** marked in our project files are the
same as those declared in `build.lua` we'll create the `check_marked_tags()`
function, set `tag_hook(tagname)` and add the `tagged` target.

First we will create a small function to display our messages in the terminal
set to 80 characters:

```lua
local function os_message(text)
  local mymax = 77-string.len(text)-string.len("done")
  local msg = text.." "..string.rep(".",mymax).." done"
  return print(msg)
end
```

<a name="heading--3-1-1"/>

### 3.1.1 Creating the check\_marked\_tags\(\) function

We added the function `check_marked_tags()` which will review and compare
the version and dates marked in `demopkg.dtx` and `build.lua`.

```lua
local function check_marked_tags()
  local f = assert(io.open("sources/demopkg.dtx", "r"))
  marked_tags = f:read("*all")
  f:close()

  local m_pkgd, m_pkgv = string.match(marked_tags, "%[(%d%d%d%d%/%d%d%/%d%d)%s+v(%S+)")
  local pkgdate = string.gsub(pkgdate, "-", "/")
  if pkgversion == m_pkgv and pkgdate == m_pkgd then
    os_message("** Checking version and date: OK")
  else
    print("** Warning: Version or date marked in files are different")
    print("** Check build.lua and run l3build tag again")
  end
end
```

<a name="heading--3-1-2"/>

### 3.1.2 Configuring the tag\_hook\(\) function

The `tag_hook()` function is automatically executed after the `update_tag()`
function, here we will add `check_marked_tags()` to be executed when using `l3build tag`.

```lua
function tag_hook(tagname)
  check_marked_tags()
end
```

<a name="heading--3-1-3"/>

### 3.1.3 Adding the "tagged" target to l3build CLI

We add the `tagged` target to `l3build` CLI. This target internally call
`check_marked_tags()` function.

```lua
if options["target"] == "tagged" then
  check_marked_tags()
  os.exit()
end
```

> **NOTE:** This target is quite useful if we want to keep the package
> files and `build.lua` updated and paired.

<a name="heading--3-2"/>

## 3.2 Create a old-fashioned test for package

We will create an _"old school style"_ test for our package using the `example.tex`
file and a temporary directory (not a regression test).

<a name="heading--3-2-1"/>

### 3.2.1 Creating the make\_temp\_dir\(\) function

We add the function `make_temp_dir()` which will create a temporary (randomly
named) directory in which we will run our _"old-fashioned test"_.

```lua
local function make_temp_dir()
  local tmpname = os.tmpname()
  tempdir = basename(tmpname)
  errorlevel = mkdir(tempdir)
  if errorlevel ~= 0 then
    error("** Error!!: The ./"..tempdir.." directory could not be created")
    return errorlevel
  else
    os_message("** Creating the temporary directory ./"..tempdir..": OK")
  end
end
```

<a name="heading--3-2-2"/>

### 3.2.2 Adding the "testpkg" target to l3build CLI

We added the target `testpkg` to `l3build` CLI. This target will internally
run the `make_temp_dir()`, run `pdflatex example.tex` and copy the
`example.log` and `example.pdf` files to the working directory.

```lua
if options["target"] == "testpkg" then
  make_temp_dir()
  errorlevel = cp("*.*", sourcefiledir, tempdir)
  if errorlevel ~= 0 then
    error("** Error!!: Can't copy files from "..sourcefiledir.." to /"..tempdir)
    return errorlevel
  else
    os_message("** Copying files from "..sourcefiledir.." to ./"..tempdir..": OK")
  end
  -- Unpack files
  local file = jobname(tempdir.."/demopkg.dtx")
  errorlevel = run(tempdir, "pdftex -interaction=batchmode "..file..".dtx > "..os_null)
  if errorlevel ~= 0 then
    error("** Error!!: pdftex -interaction=batchmode "..file..".dtx")
    return errorlevel
  else
    os_message("** Running: pdftex -interaction=batchmode "..file..".dtx")
  end
  -- pdflatex
  local file = jobname(tempdir.."/example.tex")
  errorlevel = run(tempdir, "pdflatex -interaction=nonstopmode "..file.." > "..os_null)
  if errorlevel ~= 0 then
    error("** Error!!: pdflatex -interaction=nonstopmode "..file..".tex")
    return errorlevel
  else
    os_message("** Running: pdflatex -interaction=nonstopmode "..file..".tex")
  end
  -- Copying
  os_message("** Copying "..file..".log and "..file..".pdf files to main dir: OK")
  cp("example.log", tempdir, maindir)
  cp("example.pdf", tempdir, maindir)
  -- Clean
  os_message("** Remove temporary directory ./"..tempdir..": OK")
  cleandir(tempdir)
  lfs.rmdir(tempdir)
  os.exit()
end
```

> **NOTE:** For the development of a simple LaTeX2e package we can
> still use the old _"create a file and use it as a test"_ approach, of
> course we have to write a "little" more code.

<a name="heading--4"/>

# 4. Customizing the creation of documentation

If you need to have more control about how the documentation is
generated, you can use two very useful functions defined in `l3build`:
`docinit_hook()` that is executed before you start compiling
the documentation and `typeset(file)` that gives you full control
over how you generate the documentation.

<a name="heading--4-1"/>

## 4.1 Compiling documentation step by step

The list of files declared in `typesetfiles` is automatically compiled using:

```lua
typesetexe    = "lualatex"
typesetopts   = "--interaction=batchmode"
typesetruns   = 3
makeindexopts = "-q"
```

With the exception of those declared using `specialtypesetting`.

But sometimes we need a more _"personalized"_ compilation of our documentation,
for this `l3build` has the `typeset(file)` function which gives us absolute
control over how the documentation and the rest of the files listed in
`typesetfiles` are generated.

<a name="heading--4-1-1"/>

### 4.1.1 Configuring typeset\(file\) function

The _step-by-step_ equivalent of the automatic compilation executed by `l3build`
can be written as follows:

```lua
function typeset(file)
  local file = jobname(sourcefiledir.."/demopkg.dtx")
  -- lualatex
  errorlevel = run(typesetdir, "lualatex --interaction=batchmode "..file..".dtx >"..os_null)
  if errorlevel ~= 0 then
    error("** Error!!: lualatex --interaction=batchmode "..file..".dtx")
    return errorlevel
  else
    print("** Running: lualatex --interaction=batchmode "..file..".dtx")
  end
  -- index
  errorlevel = makeindex(file, typesetdir, ".idx", ".ind", ".ilg", indexstyle)
  if errorlevel ~= 0 then
    error("** Error!!: makeindex -q -s gind.ist -o "..file..".ind "..file..".idx")
    return errorlevel
  else
    print("** Running: makeindex -q -s gind.ist -o "..file..".ind "..file..".idx")
  end
  -- glossary
  errorlevel = makeindex(file, typesetdir, ".glo", ".gls", ".glg", glossarystyle)
  if errorlevel ~= 0 then
    error("** Error!!: makeindex -q -s gglo.ist -o "..file..".gls "..file..".glo")
    return errorlevel
  else
  print("** Running: makeindex -q -s gglo.ist -o "..file..".gls "..file..".glo")
  end
  -- lualatex second run
  errorlevel = run(typesetdir, "lualatex --interaction=batchmode "..file..".dtx >"..os_null)
  if errorlevel ~= 0 then
    error("** Error!!: lualatex --interaction=batchmode "..file..".dtx")
    return errorlevel
  else
    print("** Running: lualatex --interaction=batchmode "..file..".dtx")
  end
  -- lualatex third run
  errorlevel = run(typesetdir, "lualatex --interaction=batchmode "..file..".dtx >"..os_null)
  if errorlevel ~= 0 then
    error("** Error!!: lualatex --interaction=batchmode "..file..".dtx")
    return errorlevel
  else
    print("** Running: lualatex --interaction=batchmode "..file..".dtx")
  end
  return 0
end
```

When you run `l3build doc` you should see something like this:

```
This is LuaTeX, Version 1.10.0 (TeX Live 2019)
 restricted system commands enabled.
Typesetting demopkg
** Running: lualatex --interaction=batchmode demopkg.dtx
** Running: makeindex -q -s gind.ist -o demopkg.ind demopkg.idx
** Running: makeindex -q -s gglo.ist -o demopkg.gls demopkg.glo
** Running: lualatex --interaction=batchmode demopkg.dtx
** Running: lualatex --interaction=batchmode demopkg.dtx
Typesetting example
** Running: pdflatex --interaction=batchmode example.tex
```

<a name="heading--4-1-2"/>

### 4.1.2 Separate compilations by file in typeset\(file\)

The list of files in `typesetfiles` (one, two or more files) is stored
in `(file)`, sometimes we want to give a different treatment to each of
these files, to see how it works, let's comment `specialtypesetting`:

```lua
-- specialtypesetting = { }
-- specialtypesetting["example.tex"]= {func = type_example}
```

Let's remember that in our example `typesetfiles = {...}` contains `demopkg.dtx`
and `example.tex`,  the configuration for `typeset(file)` would be:

```lua
function typeset(file)
  -- example
  if file == "example.tex" then
  local file = jobname(unpackdir.."/example.tex")
  errorlevel = run(unpackdir, "pdflatex --interaction=batchmode "..file..".tex >"..os_null)
    if errorlevel ~= 0 then
      error("** Error!!: pdflatex --interaction=batchmode "..file..".tex")
      return errorlevel
    else
      print("** Running: pdflatex --interaction=batchmode "..file..".tex")
    end
  return 0
  end
  -- demopkg
  local file = jobname(sourcefiledir.."/demopkg.dtx")
  -- lualatex
  errorlevel = run(typesetdir, "lualatex --interaction=batchmode "..file..".dtx >"..os_null)
  if errorlevel ~= 0 then
    error("** Error!!: lualatex --interaction=batchmode "..file..".dtx")
    return errorlevel
  else
    print("** Running: lualatex --interaction=batchmode "..file..".dtx")
  end
  -- index
  errorlevel = makeindex(file, typesetdir, ".idx", ".ind", ".ilg", indexstyle)
  if errorlevel ~= 0 then
    error("** Error!!: makeindex -q -s gind.ist -o "..file..".ind "..file..".idx")
    return errorlevel
  else
    print("** Running: makeindex -q -s gind.ist -o "..file..".ind "..file..".idx")
  end
  -- glossary
  errorlevel = makeindex(file, typesetdir, ".glo", ".gls", ".glg", glossarystyle)
  if errorlevel ~= 0 then
    error("** Error!!: makeindex -q -s gglo.ist -o "..file..".gls "..file..".glo")
    return errorlevel
  else
  print("** Running: makeindex -q -s gglo.ist -o "..file..".gls "..file..".glo")
  end
  -- lualatex second run
  errorlevel = run(typesetdir, "lualatex --interaction=batchmode "..file..".dtx >"..os_null)
  if errorlevel ~= 0 then
    error("** Error!!: lualatex --interaction=batchmode "..file..".dtx")
    return errorlevel
  else
    print("** Running: lualatex --interaction=batchmode "..file..".dtx")
  end
  -- lualatex third run
  errorlevel = run(typesetdir, "lualatex --interaction=batchmode "..file..".dtx >"..os_null)
  if errorlevel ~= 0 then
    error("** Error!!: lualatex --interaction=batchmode "..file..".dtx")
    return errorlevel
  else
    print("** Running: lualatex --interaction=batchmode "..file..".dtx")
  end
  return 0
end
```

If you have more files in `typesetfiles` you should add

```lua
if file == "filename" then
  -- code for compilation
return 0
end
```

for each file.

<a name="heading--4-2"/>

## 4.2 Compiling documentation using latex>dvips>ps2pdf

Suppose we are _old school users_, who still use `pstricks` for our
drawings and compile the documents using `latex>dvips>ps2pdf` and
we want to customize the compilation of our documentation, this is one way.

The instructions for compiling our document are:

```
latex --interaction=batchmode --draftmode demopkg.dtx
makeindex -s gind.ist -o demopkg.ind demopkg.idx
makeindex -s gglo.ist -o demopkg.gls demopkg.glo
latex --interaction=batchmode --draftmode demopkg.dtx
latex --interaction=batchmode demopkg.dtx
dvips -q -P pdf -o demopkg.ps demopkg.dvi
ps2pdf -dPDFSETTINGS=/screen demopkg.ps demopkg.pdf
```

We just need to pass these instructions on to `typeset(file)`:

```lua
function typeset(file)
  -- Compiling example.tex
  if file == "example.tex" then
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
  -- Compiling demopkg.dtx
  local file = jobname(sourcefiledir.."/demopkg.dtx")
  errorlevel = run(typesetdir, "latex --interaction=batchmode --draftmode "..file..".dtx > "..os_null)
  if errorlevel ~= 0 then
    error("** Error!!: latex --interaction=batchmode --draftmode "..file..".dtx")
    return errorlevel
  else
    print("** Running: latex --interaction=batchmode --draftmode "..file..".dtx")
  end
  -- index
  errorlevel = makeindex(file, typesetdir, ".idx", ".ind", ".ilg", indexstyle)
  if errorlevel ~= 0 then
    error("** Error!!: makeindex -q -s gind.ist -o "..file..".ind "..file..".idx")
    return errorlevel
  else
    print("** Running: makeindex -q -s gind.ist -o "..file..".ind "..file..".idx")
  end
  -- glossary
  errorlevel = makeindex(file, typesetdir, ".glo", ".gls", ".glg", glossarystyle)
  if errorlevel ~= 0 then
    error("** Error!!: makeindex -q -s gglo.ist -o "..file..".gls "..file..".glo")
    return errorlevel
  else
    print("** Running: makeindex -q -s gglo.ist -o "..file..".gls "..file..".glo")
  end
  -- latex second run
  errorlevel = run(typesetdir, "latex --interaction=batchmode --draftmode "..file..".dtx > "..os_null)
  if errorlevel ~= 0 then
    error("** Error!!: latex --interaction=batchmode --draftmode "..file..".dtx")
    return errorlevel
  else
    print("** Running: latex --interaction=batchmode --draftmode "..file..".dtx")
  end
  -- latex third run
  errorlevel = run(typesetdir, "latex --interaction=batchmode "..file..".dtx > "..os_null)
  if errorlevel ~= 0 then
    error("** Error!!: latex --interaction=batchmode "..file..".dtx")
    return errorlevel
  else
    print("** Running: latex --interaction=batchmode "..file..".dtx")
  end
  -- dvips
  errorlevel = run(typesetdir, "dvips -q "..file..".dvi -o "..file..".ps > "..os_null)
  if errorlevel ~= 0 then
    error("** Error!!: dvips -q "..file..".dvi -o "..file..".ps")
    return errorlevel
  else
    print("** Running: dvips -q "..file..".dvi -o "..file..".ps")
  end
  -- ps2pdf
  errorlevel = run(typesetdir, "ps2pdf -dPDFSETTINGS=/screen "..file..".ps "..file..".pdf > "..os_null)
  if errorlevel ~= 0 then
    error("** Error!!: ps2pdf -dPDFSETTINGS=/screen "..file..".ps "..file..".pdf")
    return errorlevel
  else
    print("** Running: ps2pdf -dPDFSETTINGS=/screen "..file..".ps "..file..".pdf")
  end
  return 0
end
```

<a name="heading--4-3"/>

## 4.3 Using latexmk to compile

You can use other tools to compile your files such as [arara](https://ctan.org/pkg/arara)
(I love arara) or [latexmk](https://www.ctan.org/pkg/latexmk).

When using `latexmk` it is usual that we have our own configurations in the `latexmkrc`
file which we will not distribute. The `latexmkrc` file will be:

```perl
$latex = "latex --interaction=nonstopmode %O %S";
$latex_silent_switch = "--interaction=batchmode -file-line-error";
$makeindex = "makeindex %O -s gind.ist -o %D %S";
add_cus_dep('glo','gls',0,'makeindex');
sub makeindex {
  if ( $silent ) {
    system( "makeindex -q -s gglo.ist -o \"$_[0].gls\" \"$_[0].glo\"" );
  }
  else {
    system( "makeindex -s gglo.ist -o \"$_[0].gls\" \"$_[0].glo\"" );
  };
}
$makeindex_silent_switch = "-q";
$dvips_pdf_switch = "-P pdf";
$dvips_silent_switch = "-q";
$ps2pdf = "ps2pdf %O -dPDFSETTINGS=/screen %S %D";
push @generated_exts, 'glo', 'gls', 'hd';
$clean_ext .= '%R.ps %R.dvi';
```

and will be located in  `sources/latexmkrc`, to be able to use it we need
it to be in the same directory in which the documentation will be compiled,
here comes `docinit_hook()` to copy `latexmkrc` before compiling the
documentation. We added the following lines to `build.lua`:

```lua
function docinit_hook()
  errorlevel = cp("latexmkrc", sourcefiledir, typesetdir)
  if errorlevel ~= 0 then
    error("** Error!!: Can't copy latexmkrc from "..sourcefiledir.." to "..typesetdir)
    return errorlevel
  else
    print("** Copying latexmkrc from "..sourcefiledir.." to "..typesetdir)
  end
  return 0
end

function typeset(file)
  if file == "example.tex" then return 0 end
  local file = jobname("sources/demopkg.dtx")
  errorlevel = run(typesetdir,"latexmk -pdfps -silent "..file..".dtx >"..os_null)
    if errorlevel ~= 0 then
      error("** Error!!: latexmk -pdfps -silent "..file..".dtx")
      return errorlevel
    else
      print("** Running: latexmk -pdfps -silent "..file..".dtx")
  end
  return 0
end
```

<a name="heading--4-4"/>

## 4.4 Using arara to compile documentation

In order to use `arara` to compile the documentation for our package, we
need to add the _rules_ to the start of `demopkg.dtx`:

```tex
% \iffalse meta-comment
% arara: latex: { interaction: batchmode, draft: yes }
% arara: makeindex: { style: gind.ist, input: idx, output: ind }
% arara: makeindex: { style: gglo.ist, input: glo, output: gls }
% arara: latex: { interaction: batchmode, draft: yes }
% arara: latex: { interaction: batchmode }
% arara: dvips: { options: ["-P", "pdf"] }
% arara: ps2pdf: { options: ["-dPDFSETTINGS=/screen"] }
```

And then add the following lines to `build.lua`:

```lua
function docinit_hook()
  errorlevel = cp("*.sty", sourcefiledir, typesetdir)
  if errorlevel ~= 0 then
    error("** Error!!: Can't copy .sty from "..unpackdir.." to "..typesetdir)
    return errorlevel
  else
    print("** Copying .sty from "..unpackdir.." to "..typesetdir)
  end
  return 0
end

function typeset(file)
  if file == "example.tex" then return 0 end
  local file = jobname("sources/demopkg.dtx")
  errorlevel = run(typesetdir,"arara "..file..".dtx >"..os_null)
    if errorlevel ~= 0 then
      error("** Error!!: arara "..file..".dtx")
      return errorlevel
    else
      print("** Running: arara "..file..".dtx")
  end
  return 0
end
```

<a name="heading--5"/>

# 5. Setting up Releases and GitHub

Nowadays it is very common that we store our projects in GitHub \(or other similar ones\),
the versatility of `l3build` allows us to automate some tasks. The following
lines are adapted to be able to do a (almost) automatic **Release** by registering it in GitHub.

\(Credits and thanks to Will Robertson for placing the [fontspec](https://github.com/wspr/fontspec)
code from which I adapted this.)

> **NOTE:** With the files `ctan.ann`, `ctan.note` and `mypersonaldata.lua`
> it's good to mark them with  `git update-index --assume-unchanged file`.
> Unlike adding them to `.gitignore`, they will not be removed by using `git clean -xdfq`.

<a name="heading--5-1"/>

## 5.1 Creating the os\_capture\(cmd, raw\) function

First we create a function to capture the outputs of the _calls to system_
and do our checks:

```lua
local function os_capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  if raw then return s end
    s = string.gsub(s, '^%s+', '')
    s = string.gsub(s, '%s+$', '')
    s = string.gsub(s, '[\n\r]+', ' ')
  return s
end
```

<a name="heading--5-2"/>

## 5.2 Recording git command output

We record in a local variable the outputs of the `git` commands and then
make our checks:

```lua
local gitbranch = os_capture("git symbolic-ref --short HEAD")
local gitstatus = os_capture("git status --porcelain")
local tagongit  = os_capture('git for-each-ref refs/tags --sort=-taggerdate --format="%(refname:short)" --count=1')
local gitpush   = os_capture("git log --branches --not --remotes")
```

<a name="heading--5-3"/>

## 5.3 Adding the "release" target to l3build CLI

Finally we added "release" target to `l3build`:

```lua
if options["target"] == "release" then
  if gitbranch == "master" then
    os_message("** Checking git branch '"..gitbranch.."': OK")
  else
    error("** Error!!: You must be on the 'master' branch")
  end
  if gitstatus == "" then
    os_message("** Checking status of the files: OK")
  else
    error("** Error!!: Files have been edited, please commit all changes")
  end
  if gitpush == "" then
    os_message("** Checking pending commits: OK")
  else
    error("** Error!!: There are pending commits, please run git push")
  end
  check_marked_tags()

  local pkgversion = "v"..pkgversion
  os_message("** Checking last tag marked in GitHub "..tagongit..": OK")
  errorlevel = os.execute("git tag -a "..pkgversion.." -m 'Release "..pkgversion.." "..pkgdate.."'")
  if errorlevel ~= 0 then
    error("** Error!!: tag "..tagongit.." already exists, run git tag -d "..pkgversion.." && git push --delete origin "..pkgversion)
    return errorlevel
  else
    os_message("** Running: git tag -a "..pkgversion.." -m 'Release "..pkgversion.." "..pkgdate.."'")
  end
  os_message("** Running: git push --tags --quiet")
  os.execute("git push --tags --quiet")
  if fileexists(ctanzip..".zip") then
    os_message("** Checking "..ctanzip..".zip file to send to CTAN: OK")
  else
    os_message("** Creating the file "..ctanzip..".zip to send to CTAN")
    os.execute("l3build ctan > "..os_null)
  end
  os_message("** Running: l3build upload -F ctan.ann --debug")
  os.execute("l3build upload -F ctan.ann --debug >"..os_null)
  print("** Now check "..ctanzip..".curlopt file and add changes to ctan.ann")
  print("** If everything is OK run (manually): l3build upload -F ctan.ann")
  os.exit()
end
```

It would look something like this when run `l3build release`:

```
** Checking git branch 'master': OK ...................................... done
** Checking status of the files: OK ...................................... done
** Checking pending commits: OK .......................................... done
** Checking version and date: OK ......................................... done
** Checking last tag marked in GitHub v1.0: OK ........................... done
** Running: git tag -a v1.1 -m 'Release v1.1 2020-02-19' ................. done
** Running: git push --tags --quiet ...................................... done
** Checking demopkg-1.1.zip file to send to CTAN: OK ..................... done
** Running: l3build upload -F ctan.ann --debug ........................... done
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  829k  100  473k  100  356k   157k   118k  0:00:03  0:00:03 --:--:--  275k
** Now check demopkg-1.1.curlopt file and add changes to ctan.ann
** If everything is OK run (manually): l3build upload -F ctan.ann
```
