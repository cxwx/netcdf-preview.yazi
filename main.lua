-- NetCDF 文件预览插件
-- 用于在 Yazi 中预览 NetCDF 科学数据文件
local M = {}

-- 检查 ncdump 是否可用
local function check_ncdump()
	local handle = io.popen("which ncdump 2>/dev/null && echo 'found' || echo 'not_found'")
	local result = handle:read("*a")
	handle:close()
	return result:match("found") ~= nil
end

-- 解析 ncdump -h 输出，格式化显示
local function parse_netcdf_header(header)
	local lines = {}
	local state = "start"

	for raw_line in header:gmatch("[^\r\n]+") do
		local line = raw_line:match("^%s*(.-)%s*$")

		if line:match("^netcdf%s+") then
			table.insert(lines, "\x1b[1;36mNetCDF File\x1b[0m")
			table.insert(lines, "")
		elseif line:match("^dimensions:") then
			state = "dimensions"
			table.insert(lines, "\x1b[1;33mDimensions:\x1b[0m")
		elseif line:match("^variables:") then
			state = "variables"
			table.insert(lines, "")
			table.insert(lines, "\x1b[1;32mVariables:\x1b[0m")
		elseif line:match("^// global attributes:") then
			state = "global"
			table.insert(lines, "")
			table.insert(lines, "\x1b[1;35mGlobal Attributes:\x1b[0m")
		elseif state == "dimensions" and line ~= "" then
			local dim_name, dim_size = line:match("(%S+)%s*=%s*(.+)")
			if dim_name and dim_size then
				table.insert(lines, string.format("  \x1b[36m%s\x1b[0m = %s", dim_name, dim_size))
			end
		elseif state == "variables" and line ~= "" then
			-- 检查是否为属性行 (var:attr = value)
			local attr_var, attr_name, attr_val = line:match("^(%S+):(%S+)%s*=%s*(.+)$")
			if attr_var and attr_name and attr_val then
				attr_val = attr_val:gsub(";%s*$", "")
				table.insert(lines, string.format("    \x1b[90m%s.%s\x1b[0m = %s", attr_var, attr_name, attr_val))
			else
				-- 变量声明 (type name 或 type name(dims))
				local vtype, rest = line:match("^(%S+)%s+(.+)$")
				if vtype and rest then
					local vname, vdims = rest:match("^(%S+)%s*(%b())")
					if vname then
						table.insert(lines, string.format("  \x1b[32m%s\x1b[0m: \x1b[33m%s\x1b[0m %s", vtype, vname, vdims))
					else
						vname = rest:match("^(%S+)%s*;$")
						if vname then
							table.insert(lines, string.format("  \x1b[32m%s\x1b[0m: \x1b[33m%s\x1b[0m", vtype, vname))
						end
					end
				end
			end
		elseif state == "global" and line ~= "" and not line:match("^}$") then
			local attr_name, attr_val = line:match(":%s*(%S+)%s*=%s*(.+)")
			if attr_name and attr_val then
				attr_val = attr_val:gsub(";%s*$", "")
				table.insert(lines, string.format("  \x1b[35m%s\x1b[0m = %s", attr_name, attr_val))
			end
		end
	end

	return table.concat(lines, "\n")
end

-- 预览 NetCDF 文件内容
function M:peek(job)
	-- 检查依赖
	if not check_ncdump() then
		ya.preview_widget(
			job,
			ui.Text.parse("Error: ncdump command not found.\nPlease install NetCDF tools.\n\nmacOS: brew install netcdf\nLinux: apt-get install netcdf-bin"):area(job.area)
		)
		return
	end

	local file = tostring(job.file.url)

	-- 执行 ncdump -h 获取文件头信息
	local output, err = Command("ncdump"):arg({ "-h", file }):output()
	if err then
		ya.err("NetCDF preview: failed to execute ncdump - " .. tostring(err))
		ya.preview_widget(
			job,
			ui.Text.parse("Failed to preview NetCDF file\n" .. tostring(err)):area(job.area):wrap(ui.Wrap.YES)
		)
		return
	end

	if output.status ~= 0 and #output.stdout == 0 then
		ya.preview_widget(
			job,
			ui.Text.parse("Error reading NetCDF file:\n" .. (output.stderr or "unknown error")):area(job.area)
		)
		return
	end

	-- 解析并格式化输出
	local formatted = parse_netcdf_header(output.stdout)

	-- 分行处理滚动
	local lines = {}
	for line in formatted:gmatch("[^\r\n]+") do
		table.insert(lines, line)
	end

	-- 处理分页
	local limit = job.area.h
	local start_line = (job.skip or 0) + 1
	local end_line = math.min(start_line + limit - 1, #lines)

	-- 提取当前页的行
	local page_lines = {}
	for i = start_line, end_line do
		table.insert(page_lines, lines[i])
	end

	-- 显示内容
	ya.preview_widget(job, ui.Text.parse(table.concat(page_lines, "\n")):area(job.area):wrap(ui.Wrap.NO))
end

-- 处理预览滚动
function M:seek(job)
	local h = cx.active.current.hovered
	if h and h.url == job.file.url then
		ya.emit("peek", {
			math.max(0, cx.active.preview.skip + job.units),
			only_if = job.file.url,
		})
	end
end

return M