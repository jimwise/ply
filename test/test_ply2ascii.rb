require "test/unit"
require "ply"

class TestPly2Ascii < Test::Unit::TestCase
  def test_ply2ascii
    assert system("env RUBYOPT=-I./lib bin/ply2ascii examples/cube_binary_big_endian.ply")
    verts = File.new "vertices_cube_binary_big_endian.ascii"
    tris = File.new "triangles_cube_binary_big_endian.ascii"
    nv, nt = 0, 0
    verts.lines {|l| nv = nv + 1}
    tris.lines {|l| nt = nt + 1}
    assert nv == 9
    assert nt == 13
  ensure
    File.unlink "vertices_cube_binary_big_endian.ascii"
    File.unlink "triangles_cube_binary_big_endian.ascii"
  end

  def test_help
    out = `env RUBYOPT=-I./lib bin/ply2ascii`
    assert out.match(/^This utility/)
  end
end
