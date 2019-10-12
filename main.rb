MAX_SIZE = 2**32

class PagesAllocator
  def initialize
    @file = File.open("test", "a+")
    @current_page = Page.new
    binary = @file.read(4096)
    @page_raw = binary.unpack('L*')
    load_page_from_raw
  end
  def insert(item)
    if @current_page.data_size < 1019
      @current_page.insert(item)
    end
  end
  def fill
    puts @current_page.get_data.size
    @file.write @current_page.get_data
  end
  def debug
    puts @current_page.data[0,10]
  end
  private
  def load_page_from_raw
    @current_page.data_size = @page_raw[0]
    @current_page.prev_page_end = @page_raw[1]
    @current_page.next_page_start =  @page_raw[2]
    @current_page.max = @page_raw[3]
    @current_page.min = @page_raw[4]
    @current_page.data = @page_raw[5..-1]
  end
end

class Page
  attr_accessor :data, :prev_page_end, :next_page_start, :max, :min, :data_size
  def initialize
    @data = Array.new(1019, 0)
    @prev_page_end = 0
    @next_page_start = 4096
    @max = 0
    @min = 9999999
    @data_size = 0
  end
  def print_data
    puts @data[0]
  end
  def get_data
    all_data = [@data_size, @prev_page_end, @next_page_start, @max, @min] + @data
    all_data.pack('L*')
  end
  def insert(value)
    temp = 0
    push_index = 0
    # Yes I can use binary search here alot faster
    @data.each_index do |i| 
      if @data[i] <= value and i < @data_size
        next
      end
      temp = @data[i]
      @data[i] = value
      push_index = i+1
      break
    end
    (push_index..@data.size).each do |i|
      local_temp = @data[i]
      @data[i] = temp
      temp = local_temp
    end
    @data_size += 1
  end
end

pp = PagesAllocator.new
#pp.debug  
pp.insert 5
pp.insert 4
pp.insert 6
pp.insert 1
pp.insert 2
pp.insert 10
pp.debug