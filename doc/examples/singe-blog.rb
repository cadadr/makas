# coding: utf-8
# single-blog.rb --- Scissors example website with a blog.

# Copyright (C) 2017-2018  Göktuğ Kayaalp <self@gkayaalp.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


require "scissors"

site_opts = {
  # The website's name.
  :name => "Example Website with a Blog",
  # Where ERB templates are located.
  :template_dir => "templates",
  # The root of the source tree (i.e. the Textile files).
  :sources_root => "pages",
  # Where to write the output.
  :output_directory => 'output',
  # Where static files to be copied to :output_directory are located.
  :static_root => "static",

  # Each hashmap in this array configures a blog.  You can have as
  # many as you want.
  :blogs =>
  [{
     # Blog's name.
     :name => "My Blog",
     # Blogs's description.
     :description => "Occasional ramblings on various topics.",
     # The above two are available in ERB templates as ‘@data[:blog]’
     # and ‘@data[:blog][:description]’.

     # Where to put the generated blog index.  This file is later
     # exported to the output directory as part of the normal export
     # procedure.
     :page => "pages/blog/index.textile",

     # We do not generate blog posts separately from the normal
     # content generation process.  Instead, before we output the
     # website, we locate the blog and collect information from the
     # directory hierarchy, the file names and the front matter, and
     # generate the blog index and the RSS feed in the source
     # directory.  Later, when the output is being generated, these
     # source files are used to generate final blog index and the blog
     # feed in the output directory.

     # Root of the source tree the blog is in.  Independent from
     # website's and other blogs' :sources_root.
     :sources_root => "pages",

     # The directory blog source files are in.  The files here are
     # named like this: YYYYMMDD_some-slug.textile
     :dir => "pages/blog",

     # Default language, used in :page.
     :language => "en",

     # The template used to generate :page.
     :html_template => :blog,

     # The template used to generate the RSS feed.  See
     # rss_example.xml for an example.
     :rss_template => :blog_rss,
   }]
}

# We can get options from environment variables like this, which is
# useful for example when running this configuration script from a
# Makefile or a shell script.
v = ENV["V"] == "yes"
f = ENV["F"] == "yes"

# The build_site function will generate the output files, the blog
# indexes and the RSS feeds.
Scissors.build_site site_opts, force_regeneration: f, verbose: v
