MAX_SIZE = (2**32) - 1

class PagesAllocator
  attr_reader :page_raw
  def initialize(name)
    @name = name
    if File.exist? @name
      @file = File.open(@name, 'r+b')
    else
      @file = File.open(@name, 'w+b')
    end
    @current_page = Page.new
    if @file.size > 0 
      load_page 0
    else
      init_db
    end
  end
  # read page from file
  def load_page(id)
    @file.sysseek id * 4096, IO::SEEK_SET
    binary = @file.sysread(4096)
    @page_raw = binary.unpack('L*')
    load_page_from_raw
  end
  # read last page from file
  def load_last_page
    @file.sysseek -4100, IO::SEEK_END
    binary = @file.sysread(4096)
    @page_raw = binary.unpack('L*')
    load_page_from_raw
  end
  # Inserts the item in the correct page
  def insert(item)
    loop do
      if (item <= @current_page.max and item > @current_page.min) or current_is_last_page?
        if @current_page.data_size < 1019
          @current_page.insert(item)
          save_current_page
          break
        end
        if @current_page.data_size == 1019 and current_is_last_page?
          prev_page = @current_page
          prev_page.next_page = prev_page.id + 1
          @current_page = Page.new
          @current_page.id = prev_page.id + 1
          @current_page.prev_page = prev_page.id
          next
        end
      end
      load_page @current_page.next_page if item > @current_page.max
      load_page @current_page.prev_page if item < @current_page.min
    end
  end
  # Initilaizes the db file on disk
  def init_db
    @file.syswrite @current_page.to_bytes
  end
  # Saves the current page
  def save_current_page
    @file.sysseek @current_page.id * 4096,IO::SEEK_SET
    @file.syswrite @current_page.to_bytes
  end
  # Get the current page data
  def debug
    @current_page
  end
  private
  # load the page object from the array of items
  def load_page_from_raw
    @current_page.data_size = @page_raw[0]
    @current_page.prev_page = @page_raw[1]
    @current_page.next_page =  @page_raw[2]
    @current_page.max = @page_raw[3]
    @current_page.min = @page_raw[4]
    @current_page.id = @page_raw[5]
    @current_page.data = @page_raw[6..-1]
  end
  # find if the current page is the last one
  def current_is_last_page?
    @current_page.next_page == 0
  end
end

class Page
  attr_accessor :data, :prev_page, :next_page, :max, :min, :data_size, :id
  def initialize
    @data = Array.new(1019, 0)
    @prev_page = 0
    @next_page = 0
    @max = 0
    @min = MAX_SIZE-1
    @data_size = 0
    @id = 0
  end
  def debug
    puts @data
  end
  # seralize the page data to a bytes array
  def to_bytes
    all_data = [@data_size, @prev_page, @next_page, @max, @min, @id] + @data
    all_data.pack('L*')
  end
  # Insert value in the correct place in the data array
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
    (push_index..1018).each do |i|
      local_temp = @data[i]
      @data[i] = temp
      temp = local_temp
    end
    @max = value if value > max
    @min = value if value < min
    @data_size += 1
  end
end

pp = PagesAllocator.new "db3"
pp.load_last_page
puts pp.debug.data_size
puts pp.debug.prev_page
puts pp.debug.next_page
puts pp.debug.max
puts pp.debug.min
puts pp.debug.id
puts pp.debug.data[0]
# puts pp.page_raw