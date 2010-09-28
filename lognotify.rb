#!/usr/bin/env ruby
#
# lognotify.rb
# http://github.com/omp/lognotify
# Retrieve new lines from remote log files over SSH.
#
# Copyright 2010 David Vazgenovich Shakaryan <dvshakaryan@gmail.com>
# Distributed under the terms of the GNU General Public License v3.
# See http://www.gnu.org/licenses/gpl.txt for the full license text.
#
# To use, create a configuration file, such as identifier.conf, in the
# configuration directory, which defaults to ~/.config/lognotify/. The
# following settings are required:
#
#   ssh_hostname = ...  Hostname of SSH server.
#   log_path     = ...  Path of log file on server.
#
# Afterwards, simply run the script with the identifier as an arugment:
#
#   lognotify.rb identifier
#
# During the initial run, a cache file will be created and all lines will be
# retrieved. On any subsequent runs, only new lines will be retrieved and
# outputted, as well as appended to the cache file, which should be identical
# to the log file on the server.

require 'ftools'

CACHE_DIR="~/.cache/lognotify"
CONFIG_DIR="~/.config/lognotify"

# Configuration file parser.
def parse identifier
  conf = Hash.new
  path = File.expand_path(CONFIG_DIR + '/' + identifier + '.conf')

  File.open(path) do |file|
    file.each_line do |line|
      # Remove whitespace from beginning of line, allowing for indentation.
      line.lstrip!

      # Ignore empty lines and comments.
      unless line.empty? or line[0,1] == '#'
        key, value = line.split('=', 2)

        # Raise an error if line does not contain a key/value pair.
        raise 'Error reading line ' + file.lineno.to_s + '.' if value.nil?

        conf[key.strip.to_sym] = value.strip
      end
    end
  end

  return conf
end

# Count lines in cached log.
def count_lines identifier
  path = File.expand_path(CACHE_DIR + '/' + identifier + '.log')
  return File.open(path).readlines.length
end

# Retrieve new lines via SSH.
def retrieve_lines path, lines, hostname
  command = "cat #{path}"
  command << " | sed '1,#{lines}d'" if lines > 0

  return %x[ssh #{hostname} "#{command}"]
end

# Append new lines to cached log.
def append_lines identifier, lines
  path = File.expand_path(CACHE_DIR + '/' + identifier + '.log')
  file = File.open(path, 'a')

  file.print lines
  file.close
end

# Output all messages immediately, as opposed to buffering.
STDOUT.sync = true

# Create cache directory, if nonexistent.
path = File.expand_path(CACHE_DIR)
File.makedirs(path) unless File.directory?(path)

# Treat each argument as a log identifier.
ARGV.each do |identifier|
  conf = parse(identifier)

  # Create cache file, if nonexistent.
  path = File.expand_path(CACHE_DIR + '/' + identifier + '.log')
  File.open(path, 'w').close unless File.exist?(path)

  print '* Counting lines in cached log... '
  lines = count_lines(identifier)
  puts lines

  print '* Retrieving new lines via SSH... '
  newlines = retrieve_lines(conf[:log_path], lines, conf[:ssh_hostname])
  puts 'Done'

  puts '* Number of new lines: ' + newlines.lines.count.to_s

  unless newlines.lines.count.zero?
    print '* Appending new lines to cached log... '
    append_lines(identifier, newlines)
    puts 'Done'

    puts newlines
  end
end
