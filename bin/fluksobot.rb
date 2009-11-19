#!/usr/bin/env ruby
# This file is part of fluksobot
# (c) 2009 Mathias Dalheimer, md@gonium.net
#
# FluksoBot is free software; you can 
# redistribute it and/or modify it under the terms of the GNU General Public 
# License as published by the Free Software Foundation; either version 2 of 
# the License, or any later version.
#
# FluksoBot is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with FluksoBot; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

# Read the fluksobot location 
libpath=File.join(File.dirname(__FILE__), '..', 'lib')
confpath=File.join(File.dirname(__FILE__), '..', 'etc')
$:.unshift << libpath << confpath
#puts "Using libraty path #{$:.join(":")}" 

require 'config.rb'     # Our configuration file.
require 'rubygems'
require 'optparse'
require 'ostruct'
require 'database'
require 'twitter_interface'
require 'brain'
require 'quotes'

###
## Commandline parser
#
class Optparser
  CODES = %w[iso-2022-jp shift_jis euc-jp utf8 binary]
  CODE_ALIASES = { "jis" => "iso-2022-jp", "sjis" => "shift_jis" }
  #
  # Return a structure describing the options.
  #
  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = OpenStruct.new
    options.inplace = false
    options.encoding = "utf8"
    options.verbose = false
    opts = OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"
      opts.separator ""
      opts.separator "Specific options:"
    # Boolean switch.
    opts.on("-f", "--force", "Ignore warnings") do |f|
      options.force = f 
    end
    opts.on("-d", "--debug", "Run in debug mode") do |d|
      options.debug = d 
    end
    opts.on("-v", "--verbose", "Run verbosely") do |v|
      options.verbose = v
    end
    opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  end
  opts.parse!(args)
  options
end
end

###
## Script startup
#
options = Optparser.parse(ARGV)
$verbose = options.verbose
$force = options.force
$debug = options.debug
dbfile=$CONFIG[:DB_FILE]
puts "Using database #{dbfile}" if $verbose
# check and expand paths.
if not File.exists?(dbfile)
  puts "Database is missing. Aborting."
  exit(-2);
end

# initialize twitter interface. Config file is evaluated there.
twitter=TwitterInterface.new();
#twitter.tweet("PAIN. I hate surgeries.");

brain=FluksoBotBrain.load($CONFIG[:BRAIN_FILE]);
puts "Brain loaded: #{brain.to_s}" if $verbose

begin
  db=FluksoBotDB.open(dbfile);
  last_readings=db.find_reading_last_five();
  if $verbose 
    last_readings.each{|reading|
      puts reading
    }
  end
  begin
    puts "Processing readings" if $verbose
    message=brain.processReadings(last_readings)+ " #flukso"
    if not $debug
      twitter.tweet(message);
    else
      puts "Would submit tweet: #{message}"
    end
  rescue NoQuoteException => e
    puts "No quote found: #{e}" if $verbose
  end
rescue Exception => e
  puts "Unexpected exception occured: #{e}"
end

brain.store()
puts "Dumped brain." if $verbose
db.close();
puts "Closed database." if $verbose
