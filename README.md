# ruby-dxf-reader

Reads an ASCII DXF file and returns it as a Ruby `Hash` object. The Sections and Entities are converted into the basic Ruby objects of `Hash`, `Array`, `Float`, `Fixnum`, and `String`. This library is meant to be a building-block for more advanced DXF processing using Ruby.
 
The top-level data structure is a `Hash` of containers representing SECTIONS of the .dxf file.  Currently supported sections are the `HEADER`, `BLOCKS`, and `ENTITIES` sections. The top-level Hash looks as follows:

    {"HEADER"=>{...}, "BLOCKS"=>[...], "ENTITIES"=>[...]}


### The HEADER Section

The HEADER section is a Ruby `Hash` object. Reading the HEADER variables can be done as follows:
```ruby

require 'dxf2ruby'
dxf = JF::Dxf2Ruby.parse("file.dxf")
header = dxf['HEADER']
acad_version = header['$ACADVER'][1] # ==> "AC1015"
```

###The BLOCKS Section

The BLOCKS section is a Ruby `Array` of `Hash` objects where each `Hash` object represents a DXF Entity.

### The ENTITIES Section

The ENTITIES section is a Ruby `Array` of `Hash` Objects. Each Hash object represents a DXF Entity.

### Entities

Acad Entities are returned as Ruby `Hash` objects.  A typical entity may look similar to the following Hash, which represents an Acad LINE:

    {0=>"LINE", 5=>"25", 100=>["AcDbEntity", "AcDbLine"], 8=>"0",
    6=>"CONTINUOUS", 62=>7, 10=>-4.672884, 20=>-0.816414, 30=>0.0,
    11=>-4.672884, 21=>-0.27178, 31=>0.0}

The Hash keys correspond to the 'group code' of the Entity.

### Example Use

    require 'dxf2ruby'
    dxf = JF::Dxf2Ruby.parse("file.dxf")
    acad_version =  dxf['HEADER']['$ACADVER']
    dxf['ENTITIES'].each do |entity|
      draw(entity)
    end
    
    def draw(entity)
     case entity[0]
     when "POINT"
      draw_point(entity)
     when "LINE"
      draw_line(entity)
      end
     end

 Dxf2RUby may also be used on a command line to inspect a DXF file:

       $ dxf2ruby file.dxf


 
----

 About DXF (Notes from AutoCAD)

 DXF _Objects_ have no graphical representation. (aka nongraphical objects)

 DXF _Entities_ are graphical objects.

 Accommodating DXF files from future releases of AutoCAD® will be easier
 if you write your DXF processing program in a table-driven way, ignore
 undefined group codes, and make no assumptions about the order of group codes
 in an entity. With each new AutoCAD release, new group codes will be added to
 entities to accommodate additional features.

