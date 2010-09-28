#!/usr/bin/env ruby
#
# lognotify.rb
# http://github.com/omp/lognotify
#
# Copyright 2010 David Vazgenovich Shakaryan <dvshakaryan@gmail.com>
# Distributed under the terms of the GNU General Public License v3.
# See http://www.gnu.org/licenses/gpl.txt for the full license text.

CACHE_DIR="~/.cache/lognotify"
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
        key, value = line.split('=', 2)

        # Raise an error if line does not contain a key/value pair.
        raise 'Error reading line ' + contents.lineno.to_s + '.' if value.nil?

        conf[key.strip.to_sym] = value.strip
      end
    end
  end

  return conf
end

def determine_size identifier
  file = File.expand_path(CACHE_DIR + '/' + identifier + '.log')
  return File.open(file).readlines.length
end

def acquire_new_lines conf, lines
  command = 'cat ' + conf[:log_path]
  command << " | sed '1," + lines.to_s + "d'" if lines > 0
  return %x[ssh #{conf[:ssh_hostname]} "#{command}"]
end

# Output all messages immediately, as opposed to buffering.
STDOUT.sync = true

# Test code...
ARGV.each do |identifier|
  conf = parse(identifier)

  print '* Determining number of lines in cached log... '
  lines = determine_size(identifier)
  puts lines

  print '* Acquiring new lines via SSH... '
  logappend = acquire_new_lines(conf, lines)
  puts 'Done'
  puts
  puts logappend
end
