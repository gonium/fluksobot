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

require 'rubygems'
require 'time'

# Aggregates pulses and consolidates them
class PulseIntegrator
  def initialize(durationInMinutes)
    @durationInMinutes=durationInMinutes;
    reset();
  end
  def addPulse()
    if (@firstSampleTime == nil)
      @firstSampleTime=Time.now
    end
    @lastSampleTime=Time.now
    @pulses+=1;
  end
  def getPulses()
    return @pulses
  end
  def isElapsed?
    return Time.now > @endTime
  end
  def getFluksoReading()
    # seconds betweeen this and the last timestamp
    interval=@lastSampleTime - @firstSampleTime;
    puts "Interval is #{interval}";
    watts=(@pulses.to_f/(interval/3600))
    return FluksoReading.new(watts, @lastSampleTime, interval);
  end
  def reset
    @startTime=Time.now;
    @endTime=@startTime + (@durationInMinutes * 60)
    @pulses=0;
    @firstSampleTime=nil; #@startTime; # was: nil
    @lastSampleTime=nil;
  end
  def to_s
    return "Start=#{@startTime}, End=#{@endTime}, Pulses={#{@pulses}}"
  end
end


class FluksoReading
  include Comparable
  attr_accessor :watts, :time, :interval
  def initialize(watts, timestamp, interval_duration)
    @watts=watts;
    @time=timestamp;
    @interval=interval_duration;
  end 
  def to_s
    return "#{@time} - #{@watts} W (#{@interval} s)"
  end
  def epochtime
    return @time.to_i
  end
  def <=>(other)
    return @watts <=> other.watts
  end
end

