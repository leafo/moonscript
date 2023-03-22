-- this script is used to convert a source input file into a C header to embed
-- that file as a string. Works the same as xxd -i

local input = ...

local function read_file(file_path)
  local file = assert(io.open(file_path, "rb"))
  local content = file:read("*a")
  file:close()
  return content
end

local function generate_c_header(input_file)
    local function byte_to_hex(byte)
      return string.format("0x%02x", byte:byte())
    end

    local function sanitize_name(name)
      return (name:gsub("[^%w_]", "_"))
    end

    local data = read_file(input_file)
    local name = sanitize_name(input_file)
    local header = {}

    table.insert(header, string.format("unsigned char %s[] = {", name))
    for i = 1, #data do
        if i % 16 == 1 then
            table.insert(header, "\n  ")
        end
        table.insert(header, byte_to_hex(data:sub(i, i)))
        if i ~= #data then
            table.insert(header, ", ")
        end
    end
    table.insert(header, "\n};\n")
    table.insert(header, string.format("unsigned int %s_len = %d;\n", name, #data))

    return table.concat(header)
end

print(generate_c_header(input))
