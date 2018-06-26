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
      process_object(temp, file, depth)
      if iv = temp["instance_vars"]?
        process_ivars iv, file, depth
      end
      walk temp["sub_types"], file, depth + 1
    end
  end

  def process_object(obj, file, depth)
    file.puts "*#{"*" * depth} #{obj["name"]}"
    obj.each do |x|
      case x[0]
      when "name", "sub_types", "instance_vars"
      else
        file.puts "#{" " * depth}  #{x[0]}: #{x[1]}"
      end
    end
  end

  def process_ivars(node, file, depth)
    file.puts " #{" " * depth} - instance_vars:"
    depth += 1
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
