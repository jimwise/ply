#!/usr/local/bin/ruby

#       6---------7
#      /:        /|
#     / :       / |
#    /  :      /  |
#   2---------3   |
#   |   4.....|...5
#   |  '      |  /
#   | '       | /
#   |'        |/
#   0---------1
#
#  Y Z
#  |/
#  *-X

Cube_vertices = [
  [0.0, 0.0, 0.0],
  [0.0, 1.0, 0.0],
  [1.0, 0.0, 0.0],
  [1.0, 1.0, 0.0],
  [0.0, 0.0, 1.0],
  [0.0, 1.0, 1.0],
  [1.0, 0.0, 1.0],
  [1.0, 1.0, 1.0]
]

Cube_faces = [
  [0, 1, 3],
  [1, 3, 2],

  [0, 1, 5],
  [0, 5, 4],

  [4, 0, 2],
  [4, 2, 6],

  [2, 3, 7],
  [2, 7, 6],

  [4, 5, 7],
  [4, 7, 6],

  [1, 5, 7],
  [1, 7, 3]
]

def header f, format
  f.puts "ply"
  f.puts "format #{format} 1.0"
  f.puts "comment simple triangulated cube example"
  f.puts "element vertex 8"
  f.puts "property float32 x"
  f.puts "property float32 y"
  f.puts "property float32 z"
  f.puts "element face 12"
  f.puts "property list uint8 uint32 vertex_indices"
  f.puts "end_header"
end

def ascii_cube fname
  f = File.new(fname, "w")
  header f, "ascii"
  Cube_vertices.each do |vert|
    f.puts vert.map{|p| p.to_s}.join(" ")
  end
  Cube_faces.each do |face|
    f.print "#{face.size} "
    f.puts face.map{|p| p.to_s}.join(" ")
  end
end

def bin_be_cube fname
  f = File.new(fname, "w")
  header f, "binary_big_endian"
  Cube_vertices.each do |vert|
    f.write vert.pack("g*")
  end
  Cube_faces.each do |face|
    f.write [ face.size ].pack("C")
    f.write face.pack("L>*")
  end
end

def bin_le_cube fname
  f = File.new(fname, "w")
  header f, "binary_little_endian"
  Cube_vertices.each do |vert|
    f.write vert.pack("e*")
  end
  Cube_faces.each do |face|
    f.write [ face.size ].pack("C")
    f.write face.pack("L<*")
  end
end

ascii_cube "cube_ascii.ply"
bin_be_cube "cube_binary_big_endian.ply"
bin_le_cube "cube_binary_little_endian.ply"
