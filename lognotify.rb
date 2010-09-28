#!/usr/bin/env ruby
#
# lognotify.rb
# http://github.com/omp/lognotify
#
# Copyright 2010 David Vazgenovich Shakaryan <dvshakaryan@gmail.com>
# Distributed under the terms of the GNU General Public License v3.
# See http://www.gnu.org/licenses/gpl.txt for the full license text.

CONFIG_DIR="~/.config/lognotify"

# Configuration file parser.
def parse identifier
  conf = Hash.new
  file = File.expand_path(CONFIG_DIR + '/' + identifier + '.conf')

  File.open(file) do |contents|
    contents.each_line do |line|
      # Remove whitespace from beginning of line, allowing for indentation.
      line.lstrip!

      # Ignore empty lines and comments.
      unless line.empty? or line[0,1] == '#'
        key, val = line.split('=', 2)

        # Raise an error if line does not contain a key/value pair.
        if val.nil?
          raise 'Check line ' + contents.lineno.to_s + ' for errors.'
        end

        conf[key.strip.to_sym] = val.strip
      end
    end
  end

  return conf
end

# Test code...
ARGV.each do |identifier|
  puts parse(identifier).inspect
end
