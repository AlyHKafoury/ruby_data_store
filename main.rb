MAX_SIZE = (2**32) - 1
ITEMS_IN_PAGE = 1019
PAGE_SIZE = 4096

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
  # prints all keys in order
  def traverse
    keys = []
    load_page 0
    while @current_page.next_page != 0
      @current_page.data.each do |j|
        next if j == 0 
        keys << j
      end
      load_page @current_page.next_page
    end
    @current_page.data.each do |j|
      next if j == 0 
      keys << j
    end
    # keys.each do |key|
    #   sleep 0.005
    #   puts key
    # end
    puts keys.join(",")
    keys
  end
  # read page from file
  def load_page(id)
    @file.sysseek id * PAGE_SIZE, IO::SEEK_SET
    binary = @file.sysread(PAGE_SIZE)
    @page_raw = binary.unpack('L*')
    load_page_from_raw
  end

  # read last page from file
  def load_last_page
    @file.sysseek -PAGE_SIZE, IO::SEEK_END
    binary = @file.sysread(PAGE_SIZE)
    @page_raw = binary.unpack('L*')
    load_page_from_raw
  end

  # Inserts the item in the correct page
  def insert(item)
    loop do
      #sleep 0.005
      puts "trying to insert item: #{item}"
      puts "current id #{@current_page.id}"
      puts "current max #{@current_page.max}"
      puts "current min #{@current_page.min}"
      puts "current data_size #{@current_page.data_size}"
      puts "current is last #{current_is_last_page?}"
      if (item <= @current_page.max && item > @current_page.min) ||
         current_is_last_page? ||
         (current_is_first_page? && item < @current_page.min)
        if @current_page.data_size < ITEMS_IN_PAGE
          @current_page.insert(item)
          save_current_page
          break
        end
      end
      if @current_page.data_size == ITEMS_IN_PAGE && current_is_last_page? && item >= @current_page.max
        prev_page = @current_page
        @current_page = Page.new
        last_page_id = @file.size / PAGE_SIZE
        @current_page.id = last_page_id
        @current_page.insert(item)
        save_current_page
        prev_page.next_page = @current_page.id
        prev_page.save @file
        puts "creating new end #{item}"
        break
      end
      if @current_page.data_size == ITEMS_IN_PAGE && current_is_first_page? && item <= @current_page.min
        next_page = @current_page
        last_page_id = @file.size / PAGE_SIZE
        next_page.id = last_page_id
        @current_page = Page.new
        @current_page.next_page = next_page.id
        @current_page.insert(item)
        puts "creating new start #{item}"
        next_page.save @file
        save_current_page
        break
      end
      if item > @current_page.max
        load_page @current_page.next_page
        puts "loading next page #{@current_page.next_page}"
      end
      if item < @current_page.min && !current_is_first_page?
        load_page 0 
        puts "loading first page"
      end
    end
  end

  # Initilaizes the db file on disk
  def init_db
    @file.syswrite @current_page.to_bytes
  end

  # Saves the current page
  def save_current_page
    @file.sysseek @current_page.id * PAGE_SIZE, IO::SEEK_SET
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
    @current_page.next_page =  @page_raw[1]
    @current_page.max = @page_raw[2]
    @current_page.min = @page_raw[3]
    @current_page.id = @page_raw[4]
    @current_page.data = @page_raw[5..-1]
  end

  # find if the current page is the last one
  def current_is_last_page?
    @current_page.next_page == 0
  end

  def current_is_first_page?
    @current_page.id = 0
  end
end

class Page
  attr_accessor :data, :next_page, :max, :min, :data_size, :id
  def initialize
    @data = Array.new(ITEMS_IN_PAGE, 0)
    @next_page = 0
    @max = 0
    @min = MAX_SIZE-1
    @data_size = 0
    @id = 0
  end

  # saves current page
  def save(file)
    file.sysseek @id * PAGE_SIZE, IO::SEEK_SET
    file.syswrite to_bytes
  end

  def debug
    puts @data
  end

  # seralize the page data to a bytes array
  def to_bytes
    all_data = [@data_size, @next_page, @max, @min, @id] + @data
    all_data.pack('L*')
  end

  # Insert value in the correct place in the data array
  def insert(value)
    temp = 0
    push_index = 0
    # Yes I can use binary search here alot faster
    @data.each_index do |i| 
      if @data[i] <= value && i < @data_size
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

# pp = PagesAllocator.new "db5"
# pp.load_page 3
# puts "data_size:", pp.debug.data_size
# puts "next_page:", pp.debug.next_page
# puts "max:", pp.debug.max
# puts "min:", pp.debug.min
# puts "id:", pp.debug.id
# pp.traverse
# puts (1..8000).to_a.join(",")