require 'test/unit'

class TestWriteRead < Test::Unit::TestCase
  def test_simple
    name = "play.db"
    if File.exist? name
      file = File.open(name, 'r+b')
    else
      file = File.open(name, 'w+b')
    end

    arr = Array.new 1024, 1
    data = arr.pack('L*')
    file.sysseek 0, IO::SEEK_SET
    file.syswrite data
    file.sysseek 0, IO::SEEK_SET
    binary = file.sysread(4096)
    arr2 = binary.unpack('L*')
    assert_equal arr[10], arr2[10]
    assert_equal arr.size, arr2.size

    arr = Array.new 1024, 2
    data = arr.pack('L*')
    file.sysseek 4096, IO::SEEK_SET
    file.syswrite data
    file.sysseek 4096, IO::SEEK_SET
    binary = file.sysread(4096)
    arr2 = binary.unpack('L*')
    assert_equal arr[10], arr2[10]
    assert_equal arr.size, arr2.size
  end
end