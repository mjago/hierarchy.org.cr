require "json"

class EmacsHierarchy
  def initialize(filename : String)
    @filename = filename
  end

  def run
    str = `crystal tool hierarchy --format json #{@filename}`
    json = JSON.parse str
    File.open("hierarchy.org", "w") do |f|
      walk json, f
    end
  end

  def walk(node, file, depth = 0)
    if temp = node.as_a?
      temp.each do |x|
        walk(x, file, depth)
      end
    elsif temp = node.as_h?
      file.puts "*#{"*" * depth} #{temp["name"]}"
      temp.each do |x|
        unless(x[0] == "name" || x[0] == "sub_types" || x[0] == "instance_vars")
          file.puts "#{" " * depth}  #{x[0]}: #{x[1]}"
        end
      end
      if iv = temp["instance_vars"]?
        file.puts " #{" " * depth} - instance_vars:"
        process_ivars iv, file, depth + 1
      end
      walk temp["sub_types"], file, depth + 1
    end
  end

  def process_ivars(node, file, depth)
    if ivs = node.as_a?
      ivs.each do |iv|
        if properties = iv.as_h?
          print_ivar properties, file, depth
        end
      end
    end
  end

  def print_ivar(var, file, depth)
    name, typ, size = "", "", ""
    name, typ = var["name"], var["type"]
    size = var["size_in_bytes"] if var.size == 3
    st = size == "" ? "" : " (#{size} bytes)"
    file.puts "   #{" " * depth}#{name} : #{typ}#{st}"
  end
end

if ARGV.size > 0
  EmacsHierarchy.new(ARGV[0]).run
else
  puts "Usage: hierarchy source.cr #=> hierarchy.org"
end
