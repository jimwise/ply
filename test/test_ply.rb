require "test/unit"
require "ply"

Cube_files = %w{
  cube_ascii.ply
  cube_binary_big_endian.ply
  cube_binary_little_endian.ply
}

class TestPly < Test::Unit::TestCase
  def test_ascii
    verify_cube_file "examples/cube_ascii.ply"
  end

  def test_binary_big_endian
    verify_cube_file "examples/cube_binary_big_endian.ply"
  end

  def test_binary_little_endian
    verify_cube_file "examples/cube_binary_little_endian.ply"
  end

  def test_ascii_callback
    verify_cube_callback "examples/cube_ascii.ply"
  end

  def test_binary_big_endian_callback
    verify_cube_callback "examples/cube_binary_big_endian.ply"
  end

  def test_binary_little_endian_callback
    verify_cube_callback "examples/cube_binary_little_endian.ply"
  end

  def verify_cube_file c
    p = Ply::PlyFile.new c
    assert p.data["vertex"].size == 8
    assert p.data["face"].size == 12
    assert p.data["vertex"][7]["x"] == 1.0
    assert p.data["face"][11]["vertex_indices"][2] == 3
  end

  class PlyCBTest < Ply::PlyFile
    attr_accessor :counts

    def initialize f
      @counts = {}
      super f
    end

    def element_callback e, v
      @counts[e[:name]] ||= 0
      @counts[e[:name]] = @counts[e[:name]] + 1
    end
  end

  def verify_cube_callback c
    p = PlyCBTest.new c
    assert p.counts["vertex"] == 8
    assert p.counts["face"] == 12
  end
end
