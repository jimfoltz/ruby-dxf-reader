# dxf2ruby.rb - (C) 2011 jim.foltz@gmail.com

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

# About DXF (Nots from AutoCAD)
#
# DXF _Objects_ have no graphical representation. (aka nongraphical objects)
# DXF _Entities_ are graphical objects.

# Accommodating DXF files from future releases of AutoCAD® will be easier
# if you write your DXF processing program in a table-driven way, ignore
# undefined group codes, and make no assumptions about the order of group codes
# in an entity. With each new AutoCAD release, new group codes will be added to
# entities to accommodate additional features.

module JF
  module Dxf2Ruby

    def self.parse(filename)
      if RUBY_VERSION == '2.0.0'
        read_flag = 'r:Windows-1252:UTF-8'
      else
        read_flag = 'r'
      end
      fp = File.open(filename, read_flag)
      dxf = {'HEADER' => {}, 'BLOCKS' => [], 'ENTITIES' => []}

      #
      # main loop
      #

      while true
        c, v = read_codes(fp)
        break if v == "EOF"
        if v == "SECTION"
          c, v = read_codes(fp)

          if v == "HEADER"
            hdr = dxf['HEADER']
            while true
              c, v = read_codes(fp)
              break if v == "ENDSEC" # or v == "BLOCKS" or v == "ENTITIES" or v == "EOF"
              if c == 9
                key = v
                hdr[key] = {}
              else
                add_att(hdr[key], c, v)
              end
            end # while
          end # if HEADER

          if v == "BLOCKS"
            blks = dxf[v]
            parse_entities(blks, fp)
          end # if BLOCKS

          if v == "ENTITIES"
            ents = dxf[v]
            parse_entities(ents, fp)
          end #  ENTITIES section

        end # if in SECTION

      end # main loop

      fp.close
      return dxf
    end

    def self.parse_entities(section, fp)
      last_ent = nil
      last_code = nil
      while true
        c, v = read_codes(fp)
        break if v == "ENDSEC" or v == "EOF"
        next if c == 999
        # LWPOLYLINE seems to break the rule that we can ignore the order of codes.
        if last_ent == "LWPOLYLINE"
          if c == 10
            section[-1][42] ||= []
            # Create default 42
            add_att(section[-1], 42, 0.0)
          end
          if c == 42
            # update default
            section[-1][42][-1] = v
            next
          end
        end
        if c == 0
          last_ent = v
          section << {c => v}
        else
          add_att(section[-1], c, v)
        end
        last_code = c
      end # while
    end # def self.parse_entities

    def self.read_codes(fp)
      c = fp.gets
      return [0, "EOF"] if c.nil?
      v = fp.gets
      return [0, "EOF"] if v.nil?
      c = c.to_i
      v.strip!
      v.upcase! if c == 0
      case c
      when 10..59, 140..147, 210..239, 1010..1059
        v = v.to_f
      when 60..79, 90..99, 170..175,280..289, 370..379, 380..389,500..409, 1060..1079
        v = v.to_i
      end
      return( [c, v] )
    end

    def self.add_att(ent, code, value)
      # Initially, I thought each code mapped to a single value. Turns out
      # a code can be a list of values. 
      if ent.nil? and $JFDEBUG
        p caller
        p code
        p value
      end
      if ent[code].nil?
        ent[code] = value
      elsif ent[code].class == Array
        ent[code] << value
      else
        t = ent[code]
        ent[code] = []
        ent[code] << t
        ent[code] << value
      end
    end


  end # mod Dxf2Ruby
end # mod JF


if $0 == __FILE__
  t1 = Time.now
  pretty = ARGV.delete('-p')
  filename = ARGV.shift
  puts "Ruby Version: #{RUBY_VERSION}"
  puts "File: #{File.expand_path(filename)}"
  dxf = Dxf2Ruby.parse(filename)
  puts "Finished in #{Time.now - t1}"
  if pretty
    require 'pp'
    s = PP.pp(dxf, "")
  else
    s = ""
    dxf.each do |sec, list|
      s << sec.to_s << "\n"
      list.each { |line| s << line.to_s << "\n" }
    end
  end
  cmd = "less -S"
  IO.popen(cmd, 'w') { |f| f.puts(s) }
end
