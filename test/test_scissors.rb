# encoding: utf-8
# test_scissors.rb --- Testing the Scissors library.

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

require 'minitest/autorun'
require 'scissors'

class ScissorsTest < Minitest::Test
  def setup
    @s = Scissors::Builder.new({}, false, false)
    @ex_page_path = "doc/example-pages/example-page.textile"
    @ex_page_dir = File.dirname @ex_page_path
    @ex_page_cnts = File.read @ex_page_path
    @ex_templ_dir = "doc/example-templates"
  end

  def test_can_parse_front_matter
    assert_equal(@s.parse_front_matter([]), {})

    # At least one space after /KeyName :/
    begin
      @s.parse_front_matter(["x:y"])
    rescue RuntimeError => re
      assert_equal(re.to_s, "bad front matter line x:y")
    end

    assert_equal(@s.parse_front_matter(["x: y"]), {x: 'y'})
  end

  def test_page_collection
    assert_equal(@s.collect_pages(@ex_page_dir), [@ex_page_path])
    assert (@s.collect_pages(@ex_page_dir, recursive: false) ==
            [@ex_page_path])
    assert_equal(@s.collect_pages("doc", recursive: false), [])
    assert_equal(@s.collect_pages("doc"), [@ex_page_path])
  end

  def test_targets
    ps = @s.collect_pages(@ex_page_dir)

    # No ext subst
    ts = @s.find_targets(ps, "bob")
    assert_equal(ts[ps[0]].to_s, "bob/example-pages/example-page.textile")

    # Ext subst
    ts = @s.find_targets(ps, "bob", ext: "rose")
    assert_equal(ts[ps[0]].to_s, "bob/example-pages/example-page.rose")

    # Weird subst ext is used nevertheless
    ts = @s.find_targets(ps, "bob", ext: "..rose")
    assert_equal(ts[ps[0]].to_s, "bob/example-pages/example-page..rose")
  end

  # We should be able to detect up to date targets and skip wastefully
  # rebuilding them.  A target is stale if:
  #   - its path does not exist
  #   - it itself does not exist
  #   - source's mtime (per Pathname.new(<source>).stat.mtime) is
  #     greater than that of target
  def test_drop_up_to_date
    ps = @s.collect_pages(@ex_page_dir)
    ts = @s.find_targets(ps, "target")
    # Target directory absent, should be stale
    assert_equal(@s.drop_up_to_date(ts), ts)

    Dir.mktmpdir do |dir|
      # Dir exists, but no target
      ts = @s.find_targets(ps, dir)
      assert_equal(@s.drop_up_to_date(ts), ts)

      # Dir exists, has up-to-date target
      f = ts.values[0]
      # Create the subdirectory
      FileUtils.mkdir(Pathname.new(dir).join(Pathname.new(f).dirname))
      # Create an up-to-date target
      FileUtils.touch [ts.values[0]]
      assert_equal(@s.drop_up_to_date(ts), {})

      # Update source so that the target becomes staler
      sleep 0.1                  # make sure mtime will be greater
      FileUtils.touch [ts.keys[0]]
      assert_equal(@s.drop_up_to_date(ts), ts)
    end
  end

  def test_load_templates
    t = @s.load_templates(@ex_templ_dir)
    assert t.has_key?(:basic)
    assert t.has_key?(:rss_example)
    assert (t[:basic].filename ==
            Pathname.new(@ex_templ_dir).join("basic.html").to_s)
    assert (t[:rss_example].filename ==
            Pathname.new(@ex_templ_dir).join("rss_example.xml").to_s)

    # Empty hash if no templates
    Dir.mktmpdir do |dir|
      assert_equal(@s.load_templates(dir), {})
    end
  end

  def test_apply_templates
    ps = @s.collect_pages(@ex_page_dir).map do |p|
      @s.load_page p, @ex_page_dir
    end
    ts = @s.load_templates @ex_templ_dir

    # Raise if template missing
    orig = ps[0].template_name
    ps[0].data[:template] = :nonexistenttemplate
    begin
      @s.apply_templates ps, ts
    rescue RuntimeError => re
      assert (re.to_s =~ /^Missing template: /)
    end

    # Reset
    ps[0].data[:template] = orig
    applied = @s.apply_templates ps, ts
    assert (applied[ps[0].get_path] =~
            /^<!doctype html>\n<html lang="en">/)
  end

  def test_write_pages
    pages = {"a" => "x", "b" => "y"}
    mappings = {"a" => Pathname.new("xfil"),
                "b" => Pathname.new("yfil")}
    Dir.mktmpdir do |dir|
      FileUtils.chdir dir do
        @s.write_pages pages, mappings
        assert_equal(File.new("xfil").read, "x")
      end
    end

    # Empty mappings should produce nothing.
    mappings = {}
    Dir.mktmpdir do |dir|
      FileUtils.chdir dir do
        @s.write_pages pages, mappings
        assert_equal(Dir.new('.').entries.length, 2)
      end
    end
  end

  def test_can_parse_page
    page = @s.load_page @ex_page_path, @ex_page_dir

    assert page.data.has_key? :title
    assert page.data.has_key? :template
    assert page.data.has_key? :language
    assert (not (page.data.has_key? :description))
  end

  def test_ensure_required_front_matter
    begin
      Scissors::Page.new "", "", "", {}, {}
    rescue RuntimeError => re
      assert (re.to_s =~ /required entry/)
    end
  end

  def test_disallow_modifying_reserved_attributes
    begin
      Scissors::Page.new "", "", "", {date: 10},
                         {title: "", template: "", date: 20}
    rescue RuntimeError => re
      assert_equal(re.to_s, "tried to modify reserved attribute")
    end
  end

  # The link's extension should become HTML and its path should be
  # relative to sources_root.
  def test_ex_page_link
    page = @s.load_page @ex_page_path, @ex_page_dir
    assert_equal(page.data[:link].to_s, 'example-page.html')
  end

  def test_breadcrumbs_single_level
    dir = "doc"
    page = @s.load_page @ex_page_path, dir
    assert page.data.has_key? :section
    s = page.data[:section]
    assert_equal(s[:name], "example-pages")
  end

  def test_breadcrumbs_multiple_levels
    # TODO

    # Where will the middle level title come from?  Maybe look for an
    # index.textile there and use its title, if not the dir basename?
  end

  # XXX: So apparently the current directory needs to be
  # static_root/.. in order for @s.generate_pages to function
  # correctly.  That's not good, and needs be fixed when the test
  # suite is complete enough.
  def test_page_generation
    Dir.mktmpdir do |dir|
      templates = @s.load_templates @ex_templ_dir
      ps = @s.generate_pages @ex_page_dir, dir, templates, false
      assert_equal(ps.length, 1)
      assert_equal(ps[0].basename.to_s, "example-page.html")
      assert(Pathname.new(dir).join("example-page.html").exist?,
             "example-page.html does not exist at site root")
      assert_equal(Dir.new(dir).entries.length, 3)
    end

    Dir.mktmpdir do |dir|
      FileUtils.chdir "doc" do
        templates =
          @s.load_templates Pathname.new(@ex_templ_dir)
                                    .basename.to_s
        ps = @s.generate_pages(
          Pathname.new(@ex_page_dir).basename.to_s,
          dir, templates, false)
        assert_equal(ps.length, 1)
        assert_equal(ps[0].basename.to_s, "example-page.html")
        assert(Pathname.new(dir).join("example-page.html").exist?,
               "example-page.html does not exist at site root")
        assert_equal(Dir.new(dir).entries.length, 3)
      end
    end
  end

end
