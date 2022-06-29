--Ingame Simbrief
--Marco Fasano Jun-2022
--08:26 mercoledì 29 giugno 2022
--Moduli
local xlm2lua = require ("xlm2lua")
local handler = require("xlmhandler.tree")

--Variabili
local socket = require "socket"
local http = require "socket.http"
local LIP=require ("LIP");

local SettingsFile = "ingame_simbrief.ini"
local SimbriefXMLFile = "simbrief.xml"
local sbUser = ""
local fontBig = false
local DataOFP = {}
local Settings = {}

local clickFetch = false

--Funzioni
if not SUPPORTS_FLOATING_WINDOWS then
	logMsg("Imgui not supported")
	return
end

function readSettings()
	Settings = LIP.load(SCRIPT_DIRECTORY..SettingsFile);
	if Settings.simbrief.username ~= nil then
		sbUser = Settings.simbrief.username
	end
end

function saveSettings(newSettings)
	LIP.save(SCRIPT_DIRECTORY..SettingsFile, newSettings);
end

function fetchData()
	if sbUser == nil then
		logMsg("No simbrief username")
		return false
	end
	
	local webResponse, webStatus = http.request("http://www.simbrief.com/api/xml.fetcher.php?username=" .. sbUser)
	
	if webStatus ~= 200 then
		logMsg("Simbrief API non responding")
		return false
	end
	
	local f = io.open(SCRIPT_DIRECTORY..SimbriefXMLFile, "w")
	f:write(webResponse)
	f:close()
	logMsg("Simbrief XML data downloaded")
	return true
end

function readXML()
	local xfile = xlm2lua.loadFile(SCRIPT_DIRECTORY..SimbriefXMLFile)
	local parser = xml2lua.parser(handler)
	parser:parse(xfile)
	
	DataOFP["Status"] = handler.root.OFP.fetch.status
	
	if DataOFP["Status"] ~= "Success" then
		logMsf("XML status is not success")
		return false
	end
	
	--Pilot Info
	
	DataOfp["Callsign"] = handler.root.OFP.atc.callsign
	DataOfp["Aircraft"] = handler.root.OFP.aircraft.name
	DataOfp["Cpt"] = handler.root.OFP.crew.cpt
	DataOfp["CostIndex"] = handler.root.OFP.general.costindex

	
	--Departure
	DataOfp["Origin"] = handler.root.OFP.origin.icao_code
	DataOfp["Origlevation"] = handler.root.OFP.origin.elevation
	DataOfp["OrigName"] = handler.root.OFP.origin.name
	DataOfp["OrigRwy"] = handler.root.OFP.origin.plan_rwy
	DataOfp["OrigMetar"] = handler.root.OFP.weather.orig_metar
	
	--Arrival
	DataOfp["Destination"] = handler.root.OFP.destination.icao_code
	DataOfp["DestElevation"] = handler.root.OFP.destination.elevation
	DataOfp["DestName"] = handler.root.OFP.destination.name
	DataOfp["DestRwy"] = handler.root.OFP.destination.plan_rwy
	DataOfp["DestMetar"] = handler.root.OFP.weather.dest_metar

	--Alternate
	DataOfp["Alternate"] = handler.root.OFP.alternate.icao_code
	DataOfp["AltnElevation"] = handler.root.OFP.alternate.elevation
	DataOfp["AltnName"] = handler.root.OFP.alternate.name
	DataOfp["AltnRwy"] = handler.root.OFP.alternate.plan_rwy
	DataOfp["AltnMetar"] = handler.root.OFP.weather.altn_metar
	
	--Route
	DataOfp["Units"] = handler.root.OFP.params.units
	DataOfp["Distance"] = handler.root.OFP.general.route_distance
	DataOfp["Ete"] = handler.root.OFP.times.est_time_enroute
	DataOfp["Route"] = handler.root.OFP.general.route
	DataOfp["Level"] = handler.root.OFP.general.initial_altitude

	--Payload Info
	DataOfp["RampFuel"] = (math.ceil(handler.root.OFP.fuel.plan_ramp/100) * 100)
	DataOfp["Cargo"] = handler.root.OFP.weights.cargo
	DataOfp["Pax"] = handler.root.OFP.weights.pax_count
	DataOfp["Payload"] = handler.root.OFP.weights.payload
	DataOfp["Zfw"] = (handler.root.OFP.weights.est_zfw / 1000)

	
	
	
	local iTOC = 1
	while handler.root.OFP.navlog.fix[iTOC].ident ~= "TOC" do
		iTOC = iTOC + 1
	end
	DataOfp["CrzWindDir"] = handler.root.OFP.navlog.fix[iTOC].wind_dir
	DataOfp["CrzWindSpd"] = handler.root.OFP.navlog.fix[iTOC].wind_spd
	DataOfp["CrzTemp"] = handler.root.OFP.navlog.fix[iTOC].oat
	DataOfp["CrzTempDev"] = handler.root.OFP.navlog.fix[iTOC].oat_isa_dev
	
	return true
end

function timeConvert(seconds)
	local seconds = tonumber(seconds)
	
	if seconds <= 0 then
		retunr "no data";
	else
		hours = string.format("%02.f", math.floor(seconds/3600));
		mins = string.format("%02.f", math.floot(seconds/60 - (hours*60)));
		return hours..":"..mins
	end
end

function sb_on_build(sb_wnd, x, y)
	if fontBig == true then
		imgui.SetWindowFontScale(1.2)
	else
		imgui.SetWindowFontScale(1)
	end
	
	if DataOFP["Cpt"] == nil then
		imgui.TextUnformatted(string.format("Enter your Simbrief Username"))
	else
		imgui.TextUnformatted(string.format("Welcome, %s (%s)", DataOfp["Cpt"], DataOfp["Callsign"]))
	end

	if imgui.TreeNode("Settings") then
	local changed, userNew = imgui.InputText("Simbrief Username", sbUser, 255)
	
		if changed than
			sbUser = userNew
			local newSettings =
			{
				simbrief =
				{
					username = userNew,
				},
			},
			
			saveSettings(newSettings)
		end
		
		local fontChanged, fontNewVal = imgui.Checkbox("Use bigger font", fontBig)
		if fontChanged then
			fontBig = fontNewVal
		end
		imgui.TreePop()
	end
	
	if imgui.Button("Fetch data") then
		if fetchData() then
			readXML()
			clickFetch = true
		end
	end
	
	if clickFetch then
	imgui.SameLine()
	imgui.TextUnformatted(DataOFP["Status"])
    imgui.TextUnformatted("Created by Alexander Garzo, Modified by CptHeike - V1.0")
    imgui.TextUnformatted("                                                  ")
    imgui.TextUnformatted(string.format("Aircraft:         %s", DataOfp["Aircraft"]))
    imgui.TextUnformatted(string.format("Departure:        %s - %s", DataOfp["Origin"], DataOfp["OrigName"]))
    imgui.TextUnformatted(string.format("Arrival:          %s - %s", DataOfp["Destination"], DataOfp["DestName"]))
    imgui.TextUnformatted(string.format("Alternate:        %s - %s", DataOfp["Alternate"], DataOfp["AltnName"]))
    imgui.TextUnformatted(string.format("Route:            %s/%s %s %s/%s %s/%s", DataOfp["Origin"], DataOfp["OrigRwy"], DataOfp["Route"], DataOfp["Destination"], DataOfp["DestRwy"]))
    imgui.TextUnformatted(string.format("Distance:         %d nm", DataOfp["Distance"]))
    imgui.TextUnformatted(string.format("ETE: %s", timeConvert(DataOfp["Ete"])))
    imgui.TextUnformatted(string.format("Initial Altitude:  %d ft", DataOfp["Level"]))
    imgui.TextUnformatted(string.format("Elevations:       %s (%d ft) - %s (%d ft) - %s (%d ft)", DataOfp["Origin"], DataOfp["Origlevation"], DataOfp["Destination"], DataOfp["DestElevation"], DataOfp["Alternate"], DataOfp["AltnElevation"]))
	imgui.TextUnformatted(string.format("Cost Index:       %d", DataOfp["CostIndex"]))
		
    imgui.TextUnformatted("                                                  ")
    imgui.PushStyleColor(imgui.constant.Col.Text, 0xFFFFFF00)
    imgui.TextUnformatted(string.format("Block Fuel:       %d %s", DataOfp["RampFuel"], DataOfp["Units"]))
    imgui.PopStyleColor()
    imgui.TextUnformatted(string.format("Cargo:            %d %s", DataOfp["Cargo"], DataOfp["Units"]))
    imgui.TextUnformatted(string.format("Pax:              %d", DataOfp["Pax"]))
    imgui.TextUnformatted(string.format("Payload:          %d %s", DataOfp["Payload"], DataOfp["Units"]))
    imgui.TextUnformatted(string.format("ZFW:              %02.1f", DataOfp["Zfw"]))

    imgui.TextUnformatted("                                                  ")
    imgui.PushStyleColor(imgui.constant.Col.Text, 0xFF00FF00)
    imgui.TextUnformatted(string.format("TOC Wind:        %03d/%03d", DataOfp["CrzWindDir"], DataOfp["CrzWindSpd"]))
    imgui.TextUnformatted(string.format("TOC Temp:        %03d C", DataOfp["CrzTemp"]))
    imgui.TextUnformatted(string.format("TOC ISA Dev:     %03d C", DataOfp["CrzTempDev"]))
    imgui.PopStyleColor()

    imgui.TextUnformatted("                                                  ")
    imgui.PushStyleColor(imgui.constant.Col.Text, 0xFF00BFFF)
    imgui.TextUnformatted(string.format("%s", DataOfp["OrigMetar"]))
    imgui.TextUnformatted(string.format("%s", DataOfp["DestMetar"]))
    imgui.TextUnformatted(string.format("%s", DataOfp["AltnMetar"]))
    imgui.PopStyleColor()
	end
end

sb_wnd = nil

function sb_show_wnd()
	readSettings()
	sb_wnd = float_wnd_create(650, 550, 1, true)
	float_wnd_set_title(sb_wnd, "Ingame Simbrief")
	float_wnd_set_imgui_builder(sb_wnd, "sb_on_build")
	float_wnd_set_onclose(sb_wnd, "sb_hide_wnd")
end

function sb_hide_wnd()
	if sb_wnd then
		float_wnd_destroy(sb_wnd)
	end
end

sb_show_only_once = 0
sb_hide_only_once = 0

function toggle_simbrief_helper_interface()
  sb_show_window = not sb_show_window
  if sb_show_window then
    if sb_show_only_once == 0 then
      sb_show_wnd()
      sb_show_only_once = 1
      sb_hide_only_once = 0
    end
  else
    if sb_hide_only_once == 0 then
      sb_hide_wnd()
      sb_hide_only_once = 1
      sb_show_only_once = 0
    end
  end
end

add_macro("Simbrief Helper", "sb_show_wnd()", "sb_hide_wnd()", "deactivate")
create_command("FlyWithLua/SimbriefHelper/show_toggle", "open/close Simbrief Helper", "toggle_simbrief_helper_interface()", "", "")
