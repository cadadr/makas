# coding: utf-8
# Gemspec for Scissors

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

Gem::Specification.new do |s|
  s.name        = 'scissors'
  s.version     = '0.0.0'
  s.date        = '2018-06-03'
  s.summary     = "Library for building websites from a tree of Textile files."
  s.description = <<EOT
Library for building websites from a tree of Textile files.

Cut your Textile into a nice website!

Scissors generates websites from a tree of Textile files.  It does not
try to deduce any meaning from the structure of that tree (i.e. where
files are in the directory hierarchy), but can generate a blog from a
directory of files named a certain way, if enabled.  See
doc/examples/singe-blog.rb for how that can be done.  Multiple blogs,
RSS feed generation and copying over static files are supported.
EOT
  s.authors     = ["Göktuğ Kayaalp"]
  s.email       = 'self@gkayaalp.com'
  s.files       = ["lib/scissors.rb", "Readme.org", "COPYING"]
  s.homepage    = 'https://www.gkayaalp.com/src.html#scissors'
  s.license     = 'GPL-3.0'
end
