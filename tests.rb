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
    arr = (1..30).to_a
    arr.each { |i| pp.insert i }
    assert_equal arr, pp.traverse
    File.delete("db3")
  end

  def test_inserting_decending
    pp = PagesAllocator.new "db4"
    arr = (1..30).to_a.reverse
    arr.each { |i| pp.insert i }
    assert_equal arr.reverse, pp.traverse
    File.delete("db4")
  end

  def test_inserting_mixed
    pp = PagesAllocator.new "db5"
    arr = (1..50).to_a.reverse
    arr += (51..80).to_a
    arr.each { |i| pp.insert i }
    assert_equal (1..80).to_a, pp.traverse
    File.delete("db5")
  end

  def test_insert_random
    pa = PagesAllocator.new "db6"
    items = []
    (1..40).each do |i|
      item = rand(1..2000)
      items << item
      pa.insert item
    end
    items.sort!
    #puts items.join(',')
    assert_equal items, pa.traverse
    File.delete("db6")
  end
end