# coding: utf-8
# scissors.rb --- Library for building websites from a tree of Textile files.

# Copyright (C) 2017-2018  Göktuğ Kayaalp <self@gkayaalp.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'date'
require 'erb'
require 'fileutils'
require 'pathname'
require 'redcloth'

module Scissors

  class Page
    RESERVED_ATTRIBUTES = [:date, :name]
    REQUIRED_FRONT_MATTER = [:title, :template]

    attr_accessor :data

    def initialize path, sources_root, content, attributes, front_matter
      @path = Pathname.new path
      @root = Pathname.new sources_root
      @link = @path.relative_path_from(@root).sub_ext ".html"
      @content = content
      @attributes = attributes
      @front_matter = front_matter

      REQUIRED_FRONT_MATTER.each do |m|
        unless @front_matter.include? m
          raise RuntimeError, "#{@path}: required entry `#{m}' missing in front matter"
        end
      end

      @data = @attributes.merge(front_matter) do |key, old, new|
        if RESERVED_ATTRIBUTES.include? key
          raise(RuntimeError, "tried to modify reserved attribute")
        else
          new
        end
      end

      @data[:content] = @content
      @data[:source_path] = @path
      @data[:link] = @link

      crumbs =  @link.each_filename.to_a
      if crumbs.length > 1
        section_name = crumbs[0]
        @data[:section] = {:name => section_name, :link => Pathname.new(section_name)}
      end
    end

    # Return the template name as a symbol.
    def template_name; @data[:template].to_sym end

    def get_binding; return binding; end
    def get_path; @path.to_s end
    def to_s; "#<Page:#{@path}>" end
    def inspect; to_s end
  end

  class BlogPage
    attr_accessor :data

    def initialize posts, opts
      @posts = posts.map do |p| p.data end
      @path = Pathname.new opts[:page]
      @root = Pathname.new opts[:sources_root]
      @link = @path.relative_path_from @root
      @blog = {:name => opts[:name], :language => opts[:language],
               :description => opts[:description]}
      @data = {:posts => @posts, :blog => @blog}
    end

    def get_binding; return binding; end
    def to_s; "#<Blog:#{@blog[:name]}>" end
    def inspect; to_s end
  end

  class Builder

    @verbose_p = false

    def initialize site_opts, force_regeneration, verbose
      @site_opts = site_opts
      @force_regeneration = force_regeneration
      @verbose_p = verbose
    end

    def annoy message
      puts message if @verbose_p
    end

    # Load a file, parsing the front matter.  Returns a list of page
    # instances.
    def load_page input_file, sources_root
      front_matter = []
      content = nil
      basename = File.basename input_file
      date = nil
      name = nil

      if basename.include? "_"
        a, b, c = basename.split /_/
        if c
          date, name, order_in_day = a, c, b.to_i
        else
          date, name, order_in_day = a, b, nil
        end
      else
        name = basename
      end

      File.open input_file do |f|
        loop do
          line = f.readline
          break if line =~ /^\f$/
          front_matter.push line
        end
        content = f.read
      end

      annoy "Loading page #{input_file}."

      attrs = {:date => (Date.parse date if date), :name => name,
               :order_in_day => order_in_day}
      Page.new(input_file, sources_root, RedCloth.new(content).to_html,
               attrs, parse_front_matter(front_matter))
    end

    # Parse the front matter lines into a hashmap.  Each entry is on a
    # line and has two components separated by a colon and some
    # whitespace: the name and the content.  Both fields are stripped of
    # excess whitespace.  The name is expected to be a word, its
    # lowercased and converted to a symbol.
    def parse_front_matter raw
      hash = {}

      raw.each do |line|
        name, content = line.split /:[[:blank:]]+/
        unless content
          raise(RuntimeError, "bad front matter line #{line}")
        end
        hash[name.strip.downcase.to_sym] = content.strip
      end

      hash
    end

    # Collect pages (recursively if RECURSIVE) from the tree under PATH,
    # returning a list of filenames, relative to it.
    def collect_pages path, recursive: true
      p = Pathname.new(path) + (recursive and '**/*.textile' or "*.textile")
      Dir.glob p
    end

    # Find the targets where the output files corresponding to each path
    # should be located.  OUTDIR is the root of the build tree.  If EXT
    # is provided, change the file name extension of the target to that.
    # EXT should have the initial dot in it.  If missing, a dot is
    # prepended to EXT.  If many dots preced EXT, they are _not_
    # removed.
    def find_targets paths, outdir, ext: nil
      hash = {}

      paths.each do |p|
        path = Pathname.new p
        parts = path.each_filename.to_a[1..-1]
        target = Pathname.new(outdir).join *parts
        if ext
          ext = "." + ext if !ext.start_with? "."
          hash[p] = target.sub_ext ext
        else
          hash[p] = target if path.file?
        end
      end

      hash
    end

    # Check MAPPINGS for up-to-dateness, like make(1).  Return a new hash,
    # including only the mappings where the source file is more recently
    # modified.
    def drop_up_to_date mappings
      hash = {}

      mappings.each do |s, target|
        source = Pathname.new s
        # if target is absent, keep
        # if target is newer, don't keep
        # else, keep
        if !target.exist? or source.stat.mtime > target.stat.mtime
          hash[s] = target
        end
      end

      hash
    end

    # Load all templates in TEMPLATE_DIR, return a hash map where template
    # name, a symbol, maps to the erb object initialised from the contents
    # of the said template file.
    def load_templates template_dir
      hash = {}
      tmpls = Dir.glob(Pathname.new(template_dir) + "*")

      tmpls.each do |tmpl|
        # sub_ext is used to remove the extension.
        name = Pathname.new(tmpl).basename.sub_ext("").to_s.to_sym
        erb = ERB.new(Pathname.new(tmpl).read)
        erb.filename = tmpl
        hash[name] = erb
      end

      annoy "Loaded #{tmpls.length} templates from #{template_dir}."

      hash
    end

    # Render PAGES, using the specified TEMPLATES.  Return a hash map,
    # from the page's source path to the generated html.
    def apply_templates pages, templates
      hash = {}

      pages.each do |page|
        t = templates[page.template_name]
        unless t
          raise(RuntimeError, "Missing template: #{page.template_name}")
        end
        hash[page.get_path] = t.result(page.get_binding)
      end

      hash
    end

    # Given a map of page source paths to html (in PAGES), and MAPPINGS
    # from page source paths to target files, write the html to target
    # files.
    def write_pages pages, mappings
      mappings.map do |source, target|
        html = pages[source]
        d = target.dirname
        Dir.mkdir d unless d.exist?
        File.open(target, "w+") do |file|
          file.write html
        end
        annoy "Wrote #{target}."
        target
      end
    end

    # Given the paths for SOURCES_ROOT (i), TARGET_ROOT (ii), and
    # TEMPLATE_DIR (iii), generate the HTML file tree under (ii),
    # resembling the (i) tree, using the templates from (iii).  returns an
    # array of paths to the pages produced.
    def generate_pages sources_root, target_root, templates, force_regeneration
      annoy "Generating pages from `#{sources_root}' under `#{target_root}'..."
      ret = nil
      FileUtils.chdir Pathname.new(sources_root).join("..") do
        sources_root = Pathname.new(sources_root).basename.to_s
        page_sources = collect_pages sources_root
        mappings = find_targets page_sources, target_root, ext: ".html"
        if !force_regeneration
          mappings = drop_up_to_date mappings
        end
        if mappings.empty?
          return []
        end
        pages = mappings.keys.map do |page| load_page page, sources_root end
        htmls = apply_templates(pages, templates)
        annoy "Going to write #{htmls.length} pages..."
        ret = write_pages htmls, mappings
      end
      ret
    end

    # Copy the tree under STATIC_ROOT over to TARGET_ROOT.  Return a list
    # of file names, of the files copied over.  Tries to avoid copying
    # up-to-date files.  Includes unix hidden files (.*).  Returns a list
    # of files copied over.
    def copy_static_files static_root, target_root
      static_files = Dir.glob(Pathname.new(static_root) + "**/*", File::FNM_DOTMATCH)
      mappings = find_targets static_files, target_root
      stale_mappings = drop_up_to_date mappings
      annoy "Going to copy #{stale_mappings.length} files..."
      stale_mappings.map do |source, target|
        target_dir = target.dirname
        Dir.mkdir target_dir if !target_dir.exist?
        target.delete if target.exist?
        FileUtils.cp source, target
        annoy "Copied `#{source}' -> `#{target}'."
        target
      end
    end

    # Copy RSS feeds from the under SOURCES_ROOT to under TARGET_ROOT.
    # Return an array of files copied.
    #
    # TODO: move common functionality with ‘copy_static_files’ into
    # another function, which responds to ‘force_regeneration’.
    def copy_feeds sources_root, target_root
      feeds = Dir.glob(Pathname.new(sources_root) + "**/*.rss.xml")
      annoy "Going to copy #{feeds.length} feeds..."
      mappings = find_targets feeds, target_root
      stale_mappings = drop_up_to_date mappings
      stale_mappings.map do |source, target|
        target_dir = target.dirname
        Dir.mkdir target_dir if !target_dir.exist?
        target.delete if target.exist?
        FileUtils.cp source, target
        annoy "Copied `#{source}' -> `#{target}'."
        target
      end
    end

    # Find the blog posts in BLOG_OPTS[:DIR].  Returns an array of
    # pathnames.
    def collect_blog_posts blog_opts
      post_files = collect_pages blog_opts[:dir], recursive: false
      posts = post_files.map do
        |post_file| load_page(post_file, blog_opts[:sources_root])
      end
      posts = posts.select do |post| post.data[:date] end
      annoy "Found #{posts.length} posts for blog `#{blog_opts[:name]}'."
      posts.sort do |px, py|
        if py.data[:date] > px.data[:date]
          +1
        elsif py.data[:date] < px.data[:date]
          -1
        else                        # same day.
          k = :order_in_day
          ox, oy = px.data[k], py.data[k]
          if !ox and !oy
            raise RuntimeError,
                  "\nNo two blog posts should result equal when sorting:\n(#{px},\n #{py})"
          elsif !ox
            +1
          elsif (ox and !oy) or (ox > oy)
            -1
          else
            +1
          end
        end
      end
    end

    # Write out the BLOG into TARGET_FILE, using the TEMPLATE.  Returns
    # the target file just written into.
    def write_blog blog, target_file, template
      blog_text = template.result(blog.get_binding)

      target = Pathname.new target_file
      d = target.dirname
      Dir.mkdir d unless d.exist?
      File.open(target, "w+") do |file|
        file.write blog_text
      end
      annoy "Wrote #{target}."

      target
    end

    # Generate a blog page according to BLOG_OPTS, finding an appropriate
    # template from TEMPLATES.  Returns the blog object.
    def generate_blog_page blog_opts, templates
      posts = collect_blog_posts blog_opts
      blog = BlogPage.new posts, blog_opts

      html_template = templates[blog_opts[:html_template]]
      blog_target = blog_opts[:page]
      annoy "Generating blog page for `#{blog_opts[:name]}' at: #{blog_target}..."
      write_blog blog, blog_target, html_template

      rss_template = templates[blog_opts[:rss_template]]
      rss_target = Pathname.new(blog_opts[:page]).sub_ext(".rss.xml")
      annoy "Generating blog feed for `#{blog_opts[:name]}' at #{rss_target}..."
      write_blog blog, rss_target, rss_template

      blog
    end

    # Run all phases of site generation according to site_OPTS.  When
    # optional argument FORCE_REGENERATION is true (false by default), do
    # not skip up-to-date targets.
    def build_site
      ret = {:blogs => {}}

      start_time = DateTime.now
      annoy "Started generating `#{@site_opts[:name]}' on #{start_time}..."

      template_dir = @site_opts[:template_dir]
      sources_root = @site_opts[:sources_root]
      output_directory = @site_opts[:output_directory]
      static_root = @site_opts[:static_root]
      blogs = @site_opts[:blogs]

      templates = load_templates template_dir

      blogs.each do |blog_opts|
        blog_name = blog_opts[:name]
        annoy "Processing for blog `#{blog_name}'."
        ret[:blogs][blog_name] = generate_blog_page(blog_opts, templates)
      end

      ret[:pages] = generate_pages sources_root, output_directory, templates,
                                   @force_regeneration
      ret[:static] = copy_static_files static_root, output_directory
      ret[:feeds] = copy_feeds sources_root, output_directory

      end_time = DateTime.now
      annoy "Done! (#{end_time})"

      ret
    end

  end

  def self.build_site site_opts, force_regeneration: false, verbose: false
    builder = Builder.new site_opts, force_regeneration, verbose
    builder.build_site
  end

end
