module Ply
  VERSION = '0.9'

  # module for working with ply file format -- see
  #    http://en.wikipedia.org/wiki/PLY_(file_format)
  # right now, this supports reading, but not writing ply files

  class PlyFile
    attr_accessor :format, :version, :data

    # versions of the ply file format we know how to parse (this is the only defined version as of the time of writing)
    Versions = %w{1.0}
    # formats of the ply file format we know about (we don't yet implement ascii)
    Formats = %w{binary_big_endian binary_little_endian ascii}
    # property types defined by the ply format;  we assume ILP32 meaning of types without explicit widths
    Types = %w{char uchar short ushort int uint float double int8 uint8 int16 uint16 int32 uint32 float32 float64 list}

    # parse a ply file takes a file name or an IO stream as argument
    def initialize f
      unless f.instance_of? IO
        f = File.new(f)
      end
      @source = f
      @elements = []
      parse_header f
      parse_body f
    end

    private

    def parse_header f
      raise BadFile.new("missing magic") unless f.gets.chomp == "ply"

      raise BadFile.new("malformed format line") unless md =
        f.gets.chomp.match(/^format\s+(?<format>[^\s]+)\s+(?<version>[\d.]+)$/)
      @format = md[:format]
      @version = md[:version]

      raise BadFile.new("unknown version: #{version}") unless Versions.find(version)
      raise BadFile.new("unknown format: #{format}") unless Formats.find(version)

      current_element = false
      f.each do |s|
        cmd = s.chomp.split
        case cmd[0]
        when "comment"
        when "obj_info"
        when "end_header"
          # stash last element
          @elements << current_element if current_element
          break
        when "element"
          # stash previous element
          @elements << current_element if current_element
          # puts "new element #{cmd[1]}"
          current_element = { name: cmd[1], count: cmd[2].to_i, properties: [] }
        when "property"
          type = cmd[1]
          raise BadFile.new("unknown element type: #{type}") unless Types.find(type)

          current_element[:properties] << if type == "list"
                                            # puts "new property #{cmd[4]} of element #{current_element[:name]} has type list indexed by #{cmd[2]} of #{cmd[3]}"
                                            { name: cmd[4], type: "list", index_type: cmd[2], element_type: cmd[3]}
                                          else
                                            # puts "new property #{cmd[2]} of element #{current_element[:name]} has type #{type}"
                                            { name: cmd[2], type: type}
                                          end
        else
          raise BadFile.new("unknown ply command #{cmd[0]}")
        end
      end
    end

    # parse the body of a ply file, using the structures already parsed out of the header
    # for each element type foo defined in the header, fills in @data[foo] with an array of hashes keyed on the property names
    def parse_body f
      @elements.each do |elt|
        elt[:count].times do
          element_callback elt, read_element(f, elt)
        end
      end
    end

    # by default, we accumulate all elements of a given type e, in-memory, into an array @data[e]
    # this is non-ideal for big files, of course -- to change this behavior, subclass PlyFile, and provide your own
    # element callback -- it will be called once for each read element, and passed the element definition (in elt), and
    # the actual values just read (in val)
    def element_callback elt, val
      @data ||= {}
      @data[elt[:name]] ||= []
      @data[elt[:name]] << val
    end

    def read_element f, elt
      current_element = {}
      if @format == "ascii"
        fields = f.gets.chomp.split
        elt[:properties].each do |prop|
          current_element[prop[:name]] = read_property_ascii(fields, prop[:type], prop[:index_type], prop[:element_type])
        end
      else
        elt[:properties].each do |prop|
          # last two will be nil for non-list
          current_element[prop[:name]] = read_property_binary(f, prop[:type], prop[:index_type], prop[:element_type])
        end
      end
      current_element
    end

    def read_property_ascii fields, type, index_type=false, element_type=false
      #print "reading one #{type}: "
      case type
      when "char", "int8", "uchar", "uint8", "short", "int16", "ushort", "uint16", "int", "int32", "uint", "uint32"
        # integer types
        fields.shift.to_i
      when "float", "float32", "double", "float64"
        # floating point types
        fields.shift.to_f
      when "list"
        count = read_property_ascii(fields, index_type)
        count.times.collect { read_property_ascii(fields, element_type) }
      end
    end

    # read one property from an IO stream in ply binary format, assuming ILP32 widths for generic types
    def read_property_binary f, type, index_type=false, element_type=false
      # print "reading one #{type}: "
      # pick String#unpack specifiers based on our endian-ness
      case @format
      when "binary_big_endian"
        e, f32, f64 = ">", "g", "G"
      when "binary_little_endian"
        e, f32, f64 = "<", "e", "E"
      end
      case type
      when "char", "int8"
        f.read(1).unpack("c").first
      when "uchar", "uint8"
        f.read(1).unpack("C").first
      when "short", "int16"
        f.read(2).unpack("s#{e}").first
      when "ushort", "uint16"
        f.read(2).unpack("S#{e}").first
      when "int", "int32"
        f.read(4).unpack("l#{e}").first
      when "uint", "uint32"
        f.read(4).unpack("L#{e}").first
      when "float", "float32"
        f.read(4).unpack(f32).first
      when "double", "float64"
        f.read(8).unpack(f64).first
      when "list"
        count = read_property_binary(f, index_type)
        count.times.collect { read_property_binary(f, element_type) }
      end
    end
  end

  class BadFile < Exception
  end
end
