--[[
Copyright (C) 2016 John M. Harris, Jr.

This program is free software: you can redistribute it and/or modify  
it under the terms of the GNU Lesser General Public License as   
published by the Free Software Foundation, version 3.

This program is distributed in the hope that it will be useful, but 
WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
Lesser General Lesser Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
]]

package.path = package.path .. ";./TerraGTK/?.t"

local ffi = require("ffi");
local uenc = require("urlencode");

local GTK = require("TerraGTK/gtk");
GTK.loadlib();
GTK.init();

local DEFAULT_BROWSER = "firefox";
if ffi.os == "OSX" then
	DEFAULT_BROWSER = "open -a Firefox";
end

--Boilerplate
function exists(name)
    if type(name) ~= "string" then return false; end
	
    return os.rename(name, name) and true or false;
end

function isFile(name)
    if type(name) ~= "string" then return false; end
    if not exists(name) then return false; end
    local f = io.open(name);
    if f then
        f:close();
        return true;
    end
    return false;
end

function isDir(name)
    return (exists(name) and not isFile(name));
end

--CONFIG
function getEnvDir()
	return os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config"
end

local useTorOpt = false;
local torStartOpt = "firefox";
local searxServerOpt = "searx.ch";

local CONFIG_FILE = getEnvDir() .. "/goosegoose"
if exists(CONFIG_FILE) and isFile(CONFIG_FILE) then
	local cfile = io.open(CONFIG_FILE);

	useTorOpt = cfile:read("*l") == "true";
	torStartOpt = cfile:read("*l");
	searxServerOpt = cfile:read("*l");

	cfile:close();
end

local win, box, menubar, file_item, filemenu, quit_item;
local winSettings, useTorBox, saveButton;

local builder = GTK.Builder.new_from_file("main_window.glade");
local builderSettings = GTK.Builder.new_from_file("settings.glade");

local winSettingsWidget = builderSettings:get_object("MainWindow");
if winSettingsWidget == nil then
	os.exit(-1);
end

winSettings = GTK.Window(winSettingsWidget._cobj);
winSettings:set_title("Preferences");

local useTorBoxWidget = builderSettings:get_object("UseTorBox");
if useTorBoxWidget == nil then
	os.exit(-1);
end

useTorBox = GTK.CheckButton(useTorBoxWidget._cobj);
useTorBox:set_active(useTorOpt);

local torPathWidget = builderSettings:get_object("PathToTor");
if torPathWidget == nil then
	os.exit(-1);
end

local torPath = GTK.GtkFileChooserButton(torPathWidget._cobj);
if isFile(torStartOpt) then
	torPath:set_file(torStartOpt);
end

local searxWidget = builderSettings:get_object("SearxDomain");
if searxWidget == nil then
	os.exit(-1);
end

local searx = GTK.GtkEntry(searxWidget._cobj);
searx:set_text(searxServerOpt);

local saveButtonWidget = builderSettings:get_object("SaveButton");
if saveButtonWidget == nil then
	os.exit(-1);
end

saveButton = GTK.Button(saveButtonWidget._cobj);

saveButton:connect("clicked", function()
	useTorOpt = useTorBox:get_active();
	--if torPath:get_file() ~= nil then
	--	print("Path not nil")
	--torStartOpt = ffi.string(torPath:get_file());
	--end
	searxServerOpt = ffi.string(searx:get_text());
	
	local cfile = io.open(CONFIG_FILE, "w");
	cfile:write(tostring(useTorOpt) .. "\n");
	--cfile:write(torStartOpt .. "\n");
	cfile:write("/home/johnmh/laptop_backup/Downloads/tor-browser_en-US/Browser/start-tor-browser\n");
	cfile:write(searxServerOpt);
	cfile:flush();
	cfile:close();

	winSettings:hide();
end);

local winWidget = builder:get_object("MainWindow");
if winWidget == nil then
	os.exit(-1);
end

win = GTK.Window(winWidget._cobj);
win:set_title("GooseGooseSearch");

winSettings:set_transient_for(win);

terra window_delete() : GTK.C.gboolean
	GTK.C.gtk_main_quit();
	return 0;
end

win:connect("delete-event", window_delete:getpointer());

local quitWidget = builder:get_object("QuitOption");
if quitWidget == nil then
	os.exit(-1);
end
quitWidget:connect("activate", window_delete:getpointer());

function showSettings()	
	winSettings:show_all();
end

local prefsWidget = builder:get_object("PreferencesOption");
if prefsWidget == nil then
	os.exit(-1);
end
prefsWidget:connect("activate", showSettings);

local winSettingsWidget = builderSettings:get_object("MainWindow");
if winSettingsWidget == nil then
	os.exit(-1);
end

winSettings = GTK.Window(winSettingsWidget._cobj);
winSettings:set_title("Preferences");

local searchBarWidget = builder:get_object("MainSearchBar");
if searchBarWidget == nil then
	os.exit(-1);
end

local searchBar = GTK.Entry(searchBarWidget._cobj);
searchBar:connect("activate", function()
	local txt = searchBar:get_text();
	local txtStr = ffi.string(txt);
	win:hide();
	winSettings:hide();
	if useTorOpt then
		os.execute(torStartOpt .. " --detach 'https://" .. searxServerOpt .. "/?q=" .. uenc.string(txtStr) .. "'");
	else
		os.execute(DEFAULT_BROWSER .. " --detach 'https://" .. searxServerOpt .. "/?q=" .. uenc.string(txtStr) .. "'");
	end
	GTK.main_quit();
end);

builder:unref();
win:show_all();

GTK.main();
