#!/usr/bin/env lua5.3

local STDLua = require("stdlua")
-- github.com/mrplough/scripts/blob/master/Lua/stdlua.lua
local JSON = require("json")
-- github.com/rxi/json.lua/blob/master/json.lua

local Version = "0.1.0"

local FactorioPath

if STDLua.OS == "Windows" then
	FactorioPath = STDLua.Home.."Factorio/"
elseif STDLua.OS == "UNIX" then
	FactorioPath = STDLua.Home..".factorio/"
else
	FactorioPath = "/tmp/"
end

local Args = { ... }

local Commands = {}
Commands.version = {
	["Help"] = "gives version of FMM and STDLua",
	["HelpExtended"] = "Usage: fmm version\n",
	["Function"] = function()
		print("FactorioModManager "..Version)
		print("  STDLua "..STDLua.Version)
	end
}

Commands.help = {
	["Help"] = "gives info on a command or FMM itself",
	["HelpExtended"] =
[[
Usage: fmm help [command]
Returns info on FMM and lists all commands along with a short description.
]],
	["Function"] = function(Args)
		local Command = ""
		if Args then
			Command = Args[1]
		end
		if Commands[Command] == nil then
			Commands.version.Function()
			print("")
			print("Usage: fmm command [options]")
			print("FactorioModManagger is a commandline mod manager and provides commands for searching and managing as well as querying information about mods for Factorio.")
			print("It provides similar functionality to apt.")
			print("Commands:")
			for Name, Command in pairs(Commands) do
				print("  "..Name.." - "..Command.Help)
			end
		else
			print(Commands[Command].HelpExtended:sub(1,-2)) -- End it with a newline.
		end
	end
}

local function GetModUrl(Portal, ModName)
	local Data = STDLua.Download(Portal.."api/mods/"..ModName)
	if Data == nil then
		return nil, "Failed to get mod portal data."
	end
	local Table = JSON.decode(Data)
	if Table == {} then
		return nil, "No JSON returned."
	end
	local Releases = Table.releases
	if Releases then
		local Version = Releases[#Releases]
		local Dependencies = Version.info_json.dependencies
		local Urls = {}
		Urls[Version.download_url] = ModName.."_"..Version.version
		if Dependencies then
			for Dependency in pairs(Dependencies) do
				local Operator = Dependency:match("[<=>]+")	--IGNORED FOR NOW
				local Name = Dependency:sub(1, Dependency:find("[<=>]") - 1)
				if Name:sub(1, -1) == " " then
					Name = Name:gsub("^%s*(.-)%s*$", "%1")
				end
				if Name ~= "base" then
					local DepVersion = Dependency:sub(Dependency:find("[<=>]") + Operatior:len())
					local Url, Error = GetModUrl(Portal, Name)
					table.merge(Urls, Url)
				end
			end
		end
		return Urls
	else
		return nil, "No releases for mod found."
	end
end

Commands.download = {
	["Help"] = "downloads a mod from the factorio mod portal",
	["HelpExtended"] =
[[
Usage: fmm download mod-name [path] [custom-portal-repo]
Downloads a mod from the Factorio Mod Portal or a custom one, provided it returns the same format.
Downloads the mod to your Factorio mods folder by default.
]],
	["Function"] = function(Args)
		if #Args == 0 then
			print(Commands.download.HelpExtended)
			return nil, "No arguments passed."
		end
		local ModName = Args[1]
		local SavePath = Args[2]
		if not STDLua.Exists(SavePath) then
			SavePath = FactorioPath.."mods/"
			print("Provided path does not exist, using: "..SavePath..".")
		end
		local Portal = Args[3] or "https://mods.factorio.com/"
		
		local Ret, Error = STDLua.Download(Portal.."api/mods")
		if not Ret then
			print("Error while connecting to Mod Portal: "..Error:sub(31))
			error(Error)
			return nil, Error
		end
		
		local Urls = GetModUrl(Portal, ModName)
		
		local Username = ""
		local Token = ""
		
		local Data = STDLua.Read(FactorioPath.."player-data.json")
		if Data == nil then
			return nil, "Failed to get Player Data."
		end
		
		local Table = JSON.decode(Data)
		Username = Table["service-username"]
		Token = Table["service-token"]
		
		for Url, Name in pairs(Urls or {}) do
			local FileName = SavePath..Name..".zip"
			if STDLua.Exists(FileName) then
				print(Name.." already downloaded, skipping.")
			else
				print("Downloading "..Name..".")
				Url = Portal..Url.."?username="..Username.."&token="..Token
				local Return, Error = STDLua.Download(Url, FileName)
				print(Return, Error)
			end
		end
	end
}

if #Args == 0 then
	Commands.help.Function()
	return nil, "No arguments passed."
end

local Command = Args[1]
if Commands[Command] == nil then
	Commands.help.Function()
	return nil, "Command not found."
end

table.remove(Args, 1)

return Commands[Command].Function(Args)
