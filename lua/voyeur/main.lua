local lfs        = require "lrun.util.lfs"
local Canvas     = require "lrun.gui.canvas.gl.glut"
local WM         = require "lrun.gui.wm.wm"
local WMIO       = require "lrun.gui.wm.wmio"
local Designer   = require "lrun.gui.designer"
local Clustering = require "voyeur.clustering"
local Palette    = require "voyeur.palette"

-- load widgets
local Panel = require "lrun.gui.widget.panel"
local Kinect = require "lrun.gui.widget.kinect"
local Text = require "lrun.gui.widget.text"
require "lrun.gui.widget.image"
require "lrun.gui.widget.slider"
require "lrun.gui.widget.list"
require "lrun.gui.widget.progressbar"
require "lrun.gui.widget.tabcontrol"
require "lrun.gui.widget.button"
require "lrun.gui.widget.radio"
require "lrun.gui.widget.checkbox"
require "lrun.gui.widget.groupbox"
require "lrun.gui.widget.player.playpause"
require "lrun.gui.widget.player.record"
require "lrun.gui.widget.player.stop"

module ("voyeur.main", package.seeall)

function main(filesdir)
	filesdir = filesdir or "data"
	print("Current directory: `"..lfs.currentdir().."'")
	print("Data directory: `"..filesdir.."'")
	local canvas = Canvas{title = "Voyeur", x = 20, y = 20, w=800, h=600, timeout=1}
	local screen = WMIO.load("main.screen.lua")

	-- creates window manager
	local wm = WM(screen)

	Designer():setwm(wm)
	Designer():enable(false)

	-- redirect canvas events to the window manager
	canvas.eventmanager:pipe(wm.eventmanager,
		{"display", "keyboard", "motion", "mouse", "passivemouse"}, canvas)

	local kinectwidget = screen:findrecurseone{name = "kinect"}
	local kinect = kinectwidget.kinect

	kinect:set_render_type("RENDER_IMAGE_RGB")

	local statustext = screen:findrecurseone{name = "status"}
	statustext:reshape{text = "Capturing", fontcolor = {0, 0, 0}}

	local ispause = false
	local isrecording = false
	local canrecording = false
	local isplaying = false

	local playpause = screen:findrecurseone{name = "playpause"}
	local timerpipe = canvas.eventmanager:pipe(kinectwidget.eventmanager, {"timer"}, canvas)
	playpause.eventmanager:listen(function (event)
		if event.name == "onplay" then
			kinect:pause(false)
			--timerpipe = canvas.eventmanager:pipe(kinectwidget.eventmanager, {"timer"}, canvas)
			statustext:reshape{text = "Capturing", fontcolor = {0, 0, 0}}
			ispause = false
		else
			kinect:pause(true)
			--canvas.eventmanager:unlisten(timerpipe)
			statustext:reshape{text = "Paused", fontcolor = {0, 0, 0}}
			ispause = true
		end
	end, {"onpause", "onplay"}, playpause)

	local btnrecord = screen:findrecurseone{name = "record"}
	local btnstop = screen:findrecurseone{name = "stop"}
	btnrecord.eventmanager:listen(function (event)
		local _, button, isdown = unpack(event.params)
		if button == "left" and isdown then
			assert(kinectwidget:playlive())
			isplaying = false
			-- start recording
			if canrecording then
				statustext:reshape{text = "Recording", fontcolor={1, 0, 0}}
				assert(kinect:start_recording(true))
			else
				statustext:reshape{text = "Detecting", fontcolor={1, 1, 0}}
			end
			btnstop:reshape{hidden = false}
			btnrecord:reshape{hidden = true}
			isrecording = true
		end
	end, "mouse")

	btnstop.eventmanager:listen(function (event)
		local _, button, isdown = unpack(event.params)
		if button == "left" and isdown then
			-- stop recording
			if ispause then
				statustext:reshape{text = "Paused", fontcolor={0, 0, 0}}
			else
				statustext:reshape{text = "Capturing", fontcolor={0, 0, 0}}
			end
			btnstop:reshape{hidden = true}
			btnrecord:reshape{hidden = false}
			isrecording = false
			kinect:start_recording(false)
		end
	end, "mouse")

	kinectwidget.eventmanager:listen(function (event)
		local eventname, userid, posename = unpack(event.params)
		if eventname == "CALIBRATION_END_SUCCESS" then
			if isrecording then
				statustext:reshape{text = "Recording", fontcolor={1, 0, 0}}
				assert(kinect:start_recording(true))
			end
			canrecording = true
		elseif eventname == "LOST_USER" then
			if isrecording then
				statustext:reshape{text = "Detecting", fontcolor={1, 1, 0}}
				kinect:start_recording(false)
			end
			canrecording = false
		end
	end, "user")

	kinectwidget.eventmanager:listen(function (event)
		if isplaying then
			statustext:reshape{text = "Playing "..kinect:get_frame_index(), fontcolor = {0, 0, 0}}
		end
	end, "render")

	local usecolors = false
	local useimage = false

	local function setkinect()
		if useimage then
			kinect:set_render_type("RENDER_IMAGE_RGB")
		else
			if usecolors then
				kinect:set_render_type("RENDER_DEPTH_RGB")
			else
				kinect:set_render_type("RENDER_DEPTH_GRAYSCALE_HISTOGRAM")
			end
		end
		kinect:set_render_labels(1)
		kinect:clusters_set_count(6)
	end

	setkinect()

	kinect:save_file_name(filesdir.."/Recorded.knd")

	local clusteringoptions, paletteoptions

	local button3D = screen:findrecurseone{name = "button3D"}
	button3D:reshape{pressed=true}
	button3D.eventmanager:listen(function (event)
		useimage = event.name == "onreleased"
		setkinect()
	end, {"onpressed", "onreleased"})

	local buttonC = screen:findrecurseone{name = "buttonC"}
	buttonC.eventmanager:listen(function (event)
		usecolors = event.name == "onpressed"
		setkinect()
	end, {"onpressed", "onreleased"})

	local buttonS = screen:findrecurseone{name = "buttonS"}
	buttonS.eventmanager:listen(function (event)
		if event.name == "onpressed" then
			kinectwidget:saveframe(filesdir.."/snapshot_"..os.date("%y%m%d%H%M%S"))
		end
	end, {"onpressed"})

	local buttonT = screen:findrecurseone{name = "buttonT"}
	buttonT.eventmanager:listen(function (event)
		kinectwidget:training(event.name == "onpressed")
	end, {"onpressed", "onreleased"})

	local buttonN = screen:findrecurseone{name = "buttonN"}
	buttonN.eventmanager:listen(function (event)
		if event.name == "onpressed" then
			kinectwidget:processframe()
		end
	end, "onpressed")

	local buttonD = screen:findrecurseone{name = "buttonD"}
	buttonD.eventmanager:listen(function (event)
		if event.name == "onpressed" then
			kinectwidget:deleteframe()
		end
	end, "onpressed")

	local buttonM = screen:findrecurseone{name = "buttonM"}
	buttonM.eventmanager:listen(function (event)
		kinectwidget:marking(event.name == "onpressed")
	end, {"onpressed", "onreleased"})

	local buttonPrev = screen:findrecurseone{name = "buttonPrev"}
	buttonPrev.eventmanager:listen(function (event)
		if event.name == "onpressed" then
			kinectwidget:prevframe()
		end
	end, {"onpressed"})

	local buttonNext = screen:findrecurseone{name = "buttonNext"}
	buttonNext.eventmanager:listen(function (event)
		if event.name == "onpressed" then
			kinectwidget:nextframe()
		end
	end, {"onpressed"})

	local fileslist = screen:findrecurseone{name = "fileslist"}
	local items = {}
	local liveitem = Text{text = "Live", h = 20, bordersize = 0, fontsize=16, fontcolor = {0, 0, 0} }
	table.insert(items, liveitem)

	for filename in lfs.dir(filesdir) do
		if lfs.ext(filename) == ".knd" then
			local item = Text{text = filename, h = 20, bordersize = 0, fontsize=16, fontcolor = {0, 0, 0} }
			table.insert(items, item)
		end
	end

	for i, item in ipairs(items) do
		item.eventmanager:listen(function (event)
			if event.name == "mouseenter" then
				item:reshape{bordersize=1}
			elseif event.name == "mouseleave" then
				item:reshape{bordersize=0}
			elseif event.name == "mouse" then
				local canvas, button, state, mx, my = unpack(event.params)
				if button == "left" and state then
					if i == 1 then
						assert(kinectwidget:playlive())
						isplaying = false
						statustext:reshape{text = "Capturing", fontcolor = {0, 0, 0}}
					else
						assert(kinectwidget:playfile(filesdir.."/"..item.text))
						statustext:reshape{text = "Playing", fontcolor = {0, 0, 0}}
						isplaying = true
					end
				end
			end
			canvas:postredisplay()
		end, {"mouseenter", "mouseleave", "mouse"})
		fileslist:insert(item)
	end

	clusteringoptions = Clustering.createoptionspanel{
		oncolorschanged = function (colorspace)
			kinectwidget:setcolorspace(colorspace)
		end,
		onclusterchanged = function (cluster)
			kinectwidget:setcluster(cluster)
		end,
		onclustersreset = function ()
			kinectwidget:resetclusters()
		end,
		onchannelschanged = function (ch1, ch2, ch3)
			kinectwidget:setchannels(ch1, ch2, ch3)
		end,
		onstartclustering = function (ch1, ch2, ch3)
			kinectwidget:startclustering()
		end,
		onsmoothchanged = function (smooth)
			kinectwidget:setsmooth(smooth)
		end,
		onmedianchanged = function (median)
			kinectwidget:setmedian(median)
		end,
		onclusterschanged = function (clusters)
			kinectwidget:setclusterscount(clusters)
		end,
	}

	screen:addtop(clusteringoptions)
	clusteringoptions:reshape{x = 10, y = 481}

	paletteoptions = Palette.createoptionspanel{
		onpalettechanged = function (label)
			kinectwidget:setlabel(label)
		end,
		onoverdraw = function (isoverdraw)
			kinectwidget:setoverdraw(isoverdraw)
		end}
	screen:addtop(paletteoptions)
	paletteoptions:reshape{x = 800 - paletteoptions.w - 10, y = 481}

	canvas:loop()
end

return _M
