# This file is part of FluksoBot
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
# along with CGWG; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

require 'statemachine'
require 'quotes'

class FluksoBotBrain
  attr_accessor :fsm
  # Attempts to restore brain from disk. If no marshalled version
  # of the brain is found, creates a new one.
  def self.load(inPath)
    if not File.exists?(inPath)
      return FluksoBotBrain.new(inPath);
    else
      return Marshal.load(File.open(inPath, "r"))
    end
  end
  def initialize(storePath)
    @storePath=storePath
    @lastReadingTimestamp=Time.now
    @brainContext=FluksoBotBrainContext.new(self)
    # three signals, three states -> nine transitions
    @fsm=Statemachine.build do
      state :low do
#        if $debug
#          event :low_reading, :low, :emit_low
#        else
          event :low_reading, :low # No action, ignore this
#        end
        event :medium_reading, :med , :emit_medium
        event :high_reading, :high, :emit_high
      end
      state :med do
        event :low_reading, :low, :emit_low
#        if $debug
#          event :medium_reading, :med , :emit_medium
#        else
          event :medium_reading, :med # No action, ignore this
#        end
        event :high_reading, :high, :emit_high
      end
      state :high do
        event :low_reading, :low, :emit_low
        event :medium_reading, :med, :emit_medium
#        if $debug
#          event :high_reading, :high, :emit_high
#        else
          event :high_reading, :high # No action, ignore this
#        end
      end
      context @brainContext; # does not work for some reason.
    end
    @fsm.context=@brainContext;
  end
  # Classifies a reading and triggers the appropriate actions
  def evaluateReading(reading)
    if reading.class != FluksoReading
      raise "Must provide a FluksoReading instance."
    end
    if reading.watts < $CONFIG[:LOW_MEDIUM_BARRIER]
      @fsm.low_reading;
    elsif reading.watts < $CONFIG[:MEDIUM_HIGH_BARRIER]
      @fsm.medium_reading;
    else
      @fsm.high_reading;
    end
    @lastReadingTimestamp=reading.time
  end
  def processReadings(readings)
    if readings.class != Array
      raise "Must provide an Array of FluksoReading instances."
    end
    if not $debug
      readings=readings.find_all{|reading|
        reading.time >= @lastReadingTimestamp
      }
    end
    #puts "Filtered: #{readings}"
    # sort the array according to the timestamps - oldest first.
    readings.sort!{|a,b|
      a.time <=> b.time
    }
    puts "Evaluating readings: #{readings}" if $verbose
    readings.each{|reading|
      evaluateReading(reading)
    }
    return @brainContext.getLastQuote();
  end
  # Marshal the brain.
  def store()
    File.open(@storePath, "w") { |f|
      Marshal.dump(self, f)
    }
  end
  def to_s
    retval="Brain: State=#{@fsm.state}, last timestamp: #{@lastReadingTimestamp}\n"
    retval += @fsm.to_s
    return retval
  end
end

class FluksoBotBrainContext
  def initialize(brain)
    @brain=brain
    @quote=nil;
    @quotes=QuoteDB.new()
  end
  def emit_low
    @quote=@quotes.getLowQuote()
    puts "Emiting low quote: #{@quote}" if $verbose
  end
  def emit_medium
    @quote=@quotes.getMediumQuote()
    puts "Emiting medium quote: #{@quote}" if $verbose
  end
  def emit_high
    @quote=@quotes.getHighQuote()
    puts "Emiting high quote: #{@quote}" if $verbose
  end
  def getLastQuote()
    if @quote != nil
      retval=@quote
      @quote=nil;
      return retval
    else
      raise NoQuoteException;
    end
  end
end

