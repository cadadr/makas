# Makefile --- example makefile for makas

# N.B.: THIS CONFIGURATION IS AN EXAMPLE AND MAY NOT WORK AS IS.  COPY
# OVER AND EDIT THESE FILES AS YOU NEED TO MAKE THEM USEFUL / USABLE !

# This is an example Makefile for a website using Makas.  This
# includes a setup for controlling some aspects of Makas using
# environment variables, and a couple convenience scripts.  This
# makefile is the entry point to all of this.  This file is
# _extensively_ documented in comments, so make sure you read them,
# especially if you are new to shell scripting and make(1).

# These variables are used to control whether or not Makas prints
# debugging information, and whether or not up-to-date files are
# skipped when building.  The syntax to set these variables are as
# follows:

#   $ make V=yes build server

# The variables can be combined or left out, the rule is that, if they
# appear, they appear just after the command name itself (i.e. "make")
# and the list of build targets.

# The variables are documented below.  They both default to "no".

# In the above command we use two build targets in combination; in
# fact any number can be combined.  The default, if none are provided,
# is to run the first target in the Makefile, which is "all" in this
# one.  All "all" does is to call "build".  Above, we combine "build"
# and "server" to first (re)build the website, and then run the server
# script so that we can preview the website using a local HTTP server
# process, on http://localhost:8000 (by default, edit
# "scripts/server.sh" to change this behaviour).

#                                *
#                              *   *

# The "V" make variable determines whether or not debug messages are
# printed.  Setting it to "yes" will cause the messages to be printed.
# It defaults to "no", i.e. not printing anything except errors.
# Might be useful when debugging or patching Makas.
export V:=no			# verbose?

# The "F" variable, when set to "yes" forces a complete page
# regeneration, i.e. unmodified pages are not skipped.  It defaults to
# "no".  This is most useful when a template file is edited, because
# template files are not checked when determining whether or not a
# page is "stale" (i.e. the source is newer than the generated
# target), in order for the template changes to apply to all generated
# pages, complete regeneration should be forced once.
export F:=no			# force regeneration?

# For both variables, the "export" command means that the subprocesses
# started in this Makefile can see these variables.  This is how we
# communicate these settings to the Makas library itself, see the
# "build" rule below for more details.

#                                *
#                              *   *

# This is the Ruby command.  If you installed Makas as a gem,
# remove the "-I..." part.  If you downloaded Makas manually,
# update the argument to the "-I" option to point to the "lib"
# subdirectory of your copy of Makas.  Another option is to modify
# Ruby's search path itself, but that's rather tedious, and not
# recommended.  If you can, download using gem or bundler, as it will
# automatically install the dependencies.  Otherwise, make sure you
# run "bundle" in the repository root.
RUBY:=ruby -I $(HOME)/path/to/makas/lib

# This declaration tells make(1) that these targets do not generate
# files themselves.  These are indeed essentially shortcuts to other
# scripts or commands.  For more information, see make(1) docs.
.PHONY: all build server post page

# This is the first make rule in this Makefile. "all" is the target,
# "build" is the dependency.  This means that "all" is the default
# target, and it's essentially an alias to "build".
all: build

# This rule is what runs the Makas library, or more precisely, the
# configuration script that uses it.  Check out the script, it is
# extensively commented, each configuration option is documented with
# due detail.
#
# Makas is a library.  We write a small script where we define a
# hashmap that constitutes the configuration that the Makas library
# uses in order to generate the website.  The environment of this
# script will include the V and F variables we set above.
build:
	$(RUBY) ./scripts/single-blog.rb

# This is the server script.  It will start a HTTP server process
# using the Python 2.x SimpleHTTPServer module (part of it's standart
# library) to run an HTTP server at http://localhost:8000 where you
# can preview the website.  A common way I use my Makefile is as
# follows:
#
#   $ make build server
#
# With this, I update the changed pages and run a preview server.
# When I make some edits, I terminate this process using Ctrl + C
# (SIGINT) from my shell and re-running this command.  An alternative
# approach would be to use a filesystem watcher to run "make build"
# automatically and keep "make server" running in the mean time, but
# that' left as an excercise to the reader as of writing this
# documentation (I may update this section with relevant information
# in future).
server:
	sh ./scripts/server.sh

# The following two scripts are interactive utilities to help create
# posts and pages.  They let you fill out some information like
# page/post title, language, &c; then create a page/post with an
# appropriate name (especially for blog posts Makas utilises a
# certain file name structure); and finally opens it in your $EDITOR.
post:
	sh ./scripts/post.sh

page:
	sh ./scripts/page.sh

#                                *
#                              *   *

# All of the scripts and configurations above are concise, simple and
# straightforward, so you’re encouraged to mold them to your needs.
# Makas started as out a script that was part of my own blog, so it
# is a bit too opininated maybe, but it's also meant to be very
# flexible and intuitive.  The basic idea is that we transform Textile
# to HTML, copy over static files, and optionally can use certain
# configuration combined with certain convention in order to generate
# more complex things.  That is, for example, our approach to
# blogging: blog posts are just normal pages in an arbitrary
# directory, but with file names that follow a convention.  Then, in
# the configuration script, we tell Makas to treat that directory
# as a blog.  All it does then is to inject an "index.textile" file
# and an "index.rss.xml" file right before processing page sources,
# using templates we configured.  Then these generated files go
# through the normal page generation process.

#                                *
#                              *   *

# Makas is one of many static site generators.  It takes
# inspiration from XMonad in that the configuration is done via
# writing a "main" function, it's distinguishing feature is to be a
# library by default.  It's not meant to take over your process, but
# to become a part of it.  Indeed, here we see it play its role in a
# system that is controlled by make rules, and implemented using a
# Ruby script and a few POSIX Shell scripts.  There is no "makas"
# command, though if someone felt like it, they can make one.  There
# might even exist many such frontends.

# Another feature is declarative configuration using a proper
# programming language, and here the source of inspiration is the Guix
# project.  We want our configuration to be simple, but when we need
# complexity, the whole range of possibilites the Ruby language and
# the ecosystem brings to the table is at our fingertips.  I plan to
# develop Makas with genericity and extensibility in mind, so
# that'll only become easier in the future.

# If you made it to here in this Makefile, that's great, you did not
# only learn how to use this Makefile and what's what here, but also
# how the various parts of this file and Makas in general work
# together.  If you decide to use Makas for your website, that's
# great!  I always welcome bug reports, suggestions for improvements,
# and patches; see:

#   https://www.gkayaalp.com/src.html#makas

# Happy hacking!
