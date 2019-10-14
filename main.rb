require_relative 'logger'
MAX_SIZE = (2**32) - 1
ITEMS_IN_PAGE = 1019
PAGE_SIZE = 4096

$logger = Logger.new

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
    #   $logger.logs key
    # end
    #$logger.logs keys.join(",")
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

  # Peeks into the next page relative to the current
  def next_page
    @file.sysseek @current_page.next_page * PAGE_SIZE, IO::SEEK_SET
    binary = @file.sysread(PAGE_SIZE)
    @page_raw = binary.unpack('L*')
    page = Page.new
    load_specific_page_from_raw page
    page
  end

  # Inserts the item in the correct page
  def insert(item)
    loop do
      #sleep 0.005
      $logger.logs "trying to insert item: #{item}"
      $logger.logs "current id #{@current_page.id}"
      $logger.logs "current max #{@current_page.max}"
      $logger.logs "current min #{@current_page.min}"
      $logger.logs "current data_size #{@current_page.data_size}"
      $logger.logs "current is last #{current_is_last_page?}"
      if (item <= @current_page.max && item > @current_page.min) ||
         (current_is_last_page? && item >= @current_page.max) ||
         (current_is_first_page? && item <= @current_page.min) ||
         (item >= @current_page.max && item <= next_page.min)
        $logger.logs '(item <= @current_page.max && item > @current_page.min)' if (item <= @current_page.max && item > @current_page.min)
        $logger.logs '(current_is_last_page? && item >= @current_page.max)' if (current_is_last_page? && item >= @current_page.max)
        $logger.logs '(current_is_first_page? && item <= @current_page.min)' if (current_is_first_page? && item <= @current_page.min)
        $logger.logs '(item >= @current_page.max && item <= next_page.min)' if (item >= @current_page.max && item <= next_page.min)
        if @current_page.data_size < ITEMS_IN_PAGE
          @current_page.insert(item)
          # $logger.logs "THIS IS THE ERROR CURRENT PAGE ID: #{@current_page.id}"
          save_current_page
          break
        # Split current page
        elsif @current_page.data_size == ITEMS_IN_PAGE
          old_page = @current_page
          @current_page = Page.new
          last_page_id = @file.size / PAGE_SIZE
          @current_page.id = last_page_id
          @current_page.next_page = old_page.next_page
          old_page.next_page = last_page_id
          $logger.logs "==================================== #{old_page.next_page}"
          $logger.logs "==================================== #{@current_page.next_page}"
          old_page.split_data_with @current_page
          old_page.save @file
          save_current_page
          load_page 0
          $logger.logs "current id #{@current_page.id}"
          $logger.logs "current max #{@current_page.max}"
          $logger.logs "current min #{@current_page.min}"
          next
        end
      end
      if item > @current_page.max
        load_page @current_page.next_page
        $logger.logs "loading next page #{@current_page.id}"
        next
      end
      if item <= @current_page.min && !current_is_first_page?
        load_page 0 
        $logger.logs "loading first page"
        next
      end
    end
    $logger.logs "=========================================Finished Insert Operation this is the end of it good job ========================================="
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

  # Loads a specific page
  def load_specific_page_from_raw(page)
    page.data_size = @page_raw[0]
    page.next_page =  @page_raw[1]
    page.max = @page_raw[2]
    page.min = @page_raw[3]
    page.id = @page_raw[4]
    page.data = @page_raw[5..-1]
  end

  # find if the current page is the last one
  def current_is_last_page?
    @current_page.next_page == 0
  end

  def current_is_first_page?
    @current_page.id == 0
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
    $logger.logs @data
  end

  def split_data_with(other_page)
    new_page_counter = 0
    ((@data_size/2).floor..@data_size-1).each do |i|
      other_page.data[new_page_counter] = @data[i]
      @data[i] = 0
      new_page_counter += 1
    end
    other_page.data_size = (@data_size/2.0).ceil
    @data_size = (@data_size/2).floor
    other_page.max = other_page.data[new_page_counter-1]
    other_page.min = other_page.data[0]
    @max = @data[@data_size-1]
    @min = @data[0]
  end

  # seralize the page data to a bytes array
  def to_bytes
    all_data = [@data_size, @next_page, @max, @min, @id] + @data
    $logger.logs [:data_size, @data_size, :next_page , @next_page, :max, @max, :min, @min, :id, @id].join(",")
    $logger.logs "data: #{@data.join(",")}"
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
    (push_index..ITEMS_IN_PAGE-1).each do |i|
      local_temp = @data[i]
      @data[i] = temp
      temp = local_temp
    end
    @max = value if value > max
    @min = value if value < min
    @data_size += 1
    # $logger.logs "DEBUGGING THE OFF BY ONE BYTE ERROR OMG: #{@id}"
  end
end

if __FILE__ == $0
  pp = PagesAllocator.new "db6"
  pp.load_page 0
  $logger.logs "raw :" + pp.page_raw[0,5].join(",")
  $logger.logs pp.debug.data.join ","
  $logger.logs pp.debug.next_page
end

# $logger.logs "data_size:", pp.debug.data_size
# $logger.logs "next_page:", pp.debug.next_page
# $logger.logs "max:", pp.debug.max
# $logger.logs "min:", pp.debug.min
# $logger.logs "id:", pp.debug.id
# $logger.logs pp.debug.data_size
# pp.traverse
# $logger.logs "==================================================================="

# pp.traverse
# $logger.logs (1..8000).to_a.join(",")