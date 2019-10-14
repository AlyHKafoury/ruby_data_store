class Logger
  def initialize
    @name = "db_log.txt"
    @file = File.open(@name, 'a+')
  end

  def logs(line)
    @file.puts line
  end
end