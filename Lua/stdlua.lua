local https = require("ssl.https")

local STDLua = {}
STDLua.Version = "1.0.0"

local function Exists(Path)
	Path = tostring(Path)
	local File = io.open(Path, "r")
	if File then
		File:close()
	end
	return File ~= nil
end

local function IsDir(Path)
	Path = tostring(Path)
	if not Exists(Path) then
		return nil, "Directory does not exist."
	end
	local File, Error = io.open(Path, "r")
	if not File then
		return nil, Error
	end
	local Text, Error, Code = File:read()
	File:close()
	if Text ~= nil then
		return false
	end
	if Code ~= 21 then
		return nil, Error
	end
	return true
end

local function Read(Path)
	Path = tostring(Path)
	if not Exists(Path) then
		return nil, "File does not exist."
	end
	if IsDir(Path) then
		return nil, "File is a directory."
	end
	local File, Error = io.open(Path, "r")
	if File then
		local Data = File:read("*a")
		File:close()
		return Data
	end
	return nil, Error
end

local function Write(Path, Data)
	Path = tostring(Path)
	Data = tostring(Data)
	local File, Error = io.open(Path, "w")
	if not File then
		return nil, Error
	end
	File:write(Data)
	File:close()
	return true
end

local function Append(Path, Data)
	Path = tostring(Path)
	Data = tostring(Data)
	local File, Error = io.open(Path, "a")
	if not File then
		return nil, Error
	end
	File:write(Data)
	File:close()
	return true
end

local function Execute(Command)
	if type(Command) ~= "string" then
		return nil, "Bad argument #1 (Command) to 'Execute' (string expected, got "..type(Command)..")"
	end
	local File = io.popen(Command)
	local Output = File:read("*a")
	File:close()
	return Output or ""
end

local function List(Path)
	if not Exists(Path) then
		return nil, "File or directory not found."
	end
	if not IsDir(Path) then
		return nil, "Directory is a file."
	end
	Path = Path:escape()
	local Files = ""
	if STDLua.OS == "Windows" then
		Files = Execute("dir /b /d "..Path)
	elseif STDLua.OS == "UNIX" then
		Files = Execute("ls -A "..Path)
	end
	Files = Files:split("\n")
	return Files
end

local function MakeDir(Path)
	if type(Path) ~= "string" then
		return nil, "bad argument #1 (Url) to 'Download' (string expected, got "..type(Url)..")"
	end
	if Exists(Path) then
		return nil, "File or directory exists."
	end
	if IsDir(Path) then
		return nil, "Directory exists."
	end
	os.execute("mkdir -p '"..Path.."'")
end

local function Download(Url, Path)
	if type(Url) ~= "string" then
		return nil, "Bad argument #1 (Url) to 'Download' (string expected, got "..type(Url)..")"
	end
	if Url:sub(1,4) ~= "http" then
		Url = "https://"..Url
	end
	local Body, Error = https.request(Url)
	if not Body then
		return nil, "Error while downloading file: "..tostring(Error).."."
	end
	if Path == nil then
		return Body
	end
	return Write(Path, Body)
end

local OS = "Windows"

if package.config:sub(1, 1) == "/" then
	OS = "UNIX"
end

local Home
if OS == "Windows" then
	Home = os.getenv("APPDATA"):gsub("\\", "/").."/"
else
	Home = os.getenv("HOME").."/"
end

-- Global functions

local function Split(String, Seperator)
	local Table = {}
	Seperator = Seperator or " "
	String = tostring(String)
	for Text in string.gmatch(String, "[^%"..Seperator.."]+") do
		table.insert(Table, Text)
	end
	return Table
end

local function Merge(T1, T2)
	local Return = {}
	for i,v in pairs(T1) do
		if Return[i] == nil then
			Return[i] = v
		end
	end
	for i,v in pairs(T2) do
		if Return[i] == nil then
			Return[i] = v
		end
	end
	return Return
end

local function Reverse(Table)
	local Return = {}
	for i, v in ipairs(Table) do
		Return[v] = i
	end
	return Return
end

local function ToBoolean(value)
	if value == "true" then
		return true
	elseif value == "false" then
		return false
	end
end

local EscapeTypes = {
	["Bash"] = {
		["&"] = "\\&",
		[";"] = "\\;",
		["\""] = "\\\"",
		["'"] = "\\'",
		["%."] = "\\%.",
		[">"] = "\\>",
		["<"] = "\\<",
		["$("] = "\\$\\(",
		[")"] = "\\)",
		["%?"] = "\\%?",
		["|"] = "\\|",
		["\\"] = "\\\\",
		["{"] = "\\{",
		["}"] = "\\}",
		["`"] = "\\`"
	}
}

local function Escape(Text, Type)
	if EscapeTypes[Type] == nil then
		Type = "Bash"
	end
	for Pattern, Replacement in pairs(EscapeTypes[Type]) do
		if Text:find(Pattern) then
			Text = Text:gsub(Pattern, Replacement)
		end
	end
	return Text
end

-- Functions
STDLua.Exists = Exists
STDLua.IsDir = IsDir
STDLua.Read = Read
STDLua.Write = Write
STDLua.Append = Append
STDLua.Execute = Execute
STDLua.List = List
STDLua.MakeDir = MakeDir
STDLua.Download = Download

-- Variables
STDLua.OS = OS
STDLua.Home = Home

-- Global Functions
_G.string.split = Split
_G.string.escape = Escape
_G.table.merge = Merge
_G.table.reverse = Reverse
_G.toboolean = ToBoolean

return STDLua
