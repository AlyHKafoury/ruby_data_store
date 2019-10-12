require_relative 'main'
require 'test/unit'
require 'set'

class TestWriteRead < Test::Unit::TestCase
  def test_simple
    pp = PagesAllocator.new "db1"
    (1..10).each { |i| pp.insert i }
    p2 = PagesAllocator.new "db1"
    assert_equal (1..10).to_a, p2.debug.data[0,10]
    File.delete("db1")
  end
end

class TestInsert < Test::Unit::TestCase

  def test_simple
    pp = PagesAllocator.new "db2"
    pp.insert 5
    pp.insert 4
    pp.insert 6
    pp.insert 1
    pp.insert 2
    pp.insert 10
    assert_equal [1,2,4,5,6,10], pp.debug.data[0,6]
    File.delete("db2")
  end

  def test_new_page_allocation_at_end
    pp = PagesAllocator.new "db3"
    arr = (1..3058).to_a
    arr.each { |i| pp.insert i }
    assert_equal [3058,0,0], pp.debug.data[0,3]
    File.delete("db3")
  end
end