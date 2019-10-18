require_relative 'main'
require 'test/unit'
require 'set'

class TestWriteRead < Test::Unit::TestCase
  def test_simple
    pp = PagesAllocator.new "db1"
    (1..10).each { |i| pp.insert Item.new i,i }
    p2 = PagesAllocator.new "db1"
    assert_equal (1..10).to_a, p2.debug.keys[0,10]
    #File.delete("db1")
  end
end

class TestInsert < Test::Unit::TestCase

  def test_simple
    pp = PagesAllocator.new "db2"
    pp.insert Item.new 5,50
    pp.insert Item.new 4,40
    pp.insert Item.new 6,60
    pp.insert Item.new 1,10
    pp.insert Item.new 2,20
    pp.insert Item.new 10,100
    assert_equal [1, 2, 4, 5, 6, 10], pp.debug.keys[0..5]
    #File.delete("db2")
  end

  def test_new_page_allocation_at_end
    pp = PagesAllocator.new "db3"
    arr = (1..3000).to_a
    arr.each { |i| pp.insert Item.new i,i }
    assert_equal arr, pp.traverse
    File.delete("db3")
  end

  def test_inserting_decending
    pp = PagesAllocator.new "db4"
    arr = (1..3000).to_a.reverse
    arr.each { |i| pp.insert Item.new i,i }
    assert_equal arr.reverse, pp.traverse
    File.delete("db4")
  end

  def test_inserting_mixed
    pp = PagesAllocator.new "db5"
    arr = (1..5000).to_a.reverse
    arr += (5001..8000).to_a
    arr.each { |i| pp.insert Item.new i,i }
    assert_equal (1..8000).to_a, pp.traverse
    File.delete("db5")
  end

  def test_insert_random
    pa = PagesAllocator.new "db6"
    items = []
    (1..4000).each do |i|
      key = rand(1..2000)
      items << key
      pa.insert Item. new key, 0
    end
    items.sort!
    #puts items.join(',')
    assert_equal items, pa.traverse
    #File.delete("db6")
  end
end