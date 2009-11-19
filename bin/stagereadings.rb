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
      opts.on("-i", "--input FILE", "The named pipe where the rsyslog messages occur") do |inFile|
        options.inFile = inFile
      end
      # Boolean switch.
      opts.on("-f", "--force", "Ignore warnings") do |f|
        options.force = f 
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
dbfile=$CONFIG[:DB_FILE]
puts "FluksoBot reading stager script."
if $verbose
  puts " Using database #{dbfile}"
end
# check and expand paths.
if not File.exists?(dbfile)
  puts "Database is missing. Aborting."
  exit(-2);
else
  begin
    db=FluksoBotDB.open(dbfile);
    db.close();
  rescue Exception => e
    puts "Failed to open database: #{e}"
    puts "Aborting."
    exit(-4);
  end
end
inPath=File.expand_path(options.inFile) unless not options.inFile
if not File.readable_real?(inPath)
  puts "Input pipe file is not readable. Aborting."
  exit(-3);
end

#while true # master control loop
  # sometimes, the pipe is closed, so restart it
  begin
    db=FluksoBotDB.open(dbfile);
    last_timestamp=nil;
    measurementInterval=$CONFIG[:MEASUREMENT_INTERVAL]
    puts "Will integrate readings over #{measurementInterval} minutes" if $verbose
    pulseIntegrator=PulseIntegrator.new(measurementInterval);
    # Read values from named pipe continuously. 
    # See
    # http://www.pauldix.net/2009/07/using-named-pipes-in-ruby-for-interprocess-communication.html
    File.open(inPath,"a+") {|file| # r+ means we don't block here
      while line=file.gets
        if /flukso.*ADC0\D*(\d+)$/ =~ line
          # This is a debug line with low accuracy.
          adc0_value=$1.to_f
          # Estimated by Bart
          watts=adc0_value*12.35 
          puts "approx. consumption: #{watts} watt" if $verbose
        end
        if /\w\s(\d+:\d+:\d+).*flukso.*pulse.*:(\d+)$/ =~ line
          puts line if $verbose
          # This is a pulse line - high accuracy here if integrated.
          logtime=$1
          watthours=$2.to_f
          timestamp=Time.parse(logtime)
          if last_timestamp != nil
            # seconds betweeen this and the last timestamp
            interval=timestamp - last_timestamp
            watts=(1.0/(interval/3600))
          else
            interval="NaN"
            watts="NaN"
          end
          last_timestamp=timestamp
          #puts "Timestamp: #{timestamp}, interval: #{interval}, Wh counter: #{watthours}, watts: #{watts} " if $verbose
          pulseIntegrator.addPulse();
          puts pulseIntegrator
          if (pulseIntegrator.isElapsed?())
            fluksoReading=pulseIntegrator.getFluksoReading();
            puts pulseIntegrator
            pulseIntegrator.reset();
            puts pulseIntegrator
            puts "FluksoReading: #{fluksoReading}" if $verbose
            db.storeReading(fluksoReading);
          end
        end
      end
    }
    puts "Pipe closed."
    db.close();
    puts "Closed database."
  rescue Exception => e
    puts "Failed in main loop: #{e}"
  end
  #end
