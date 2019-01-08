-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2010,  AVIQ Systems AG                         --
--                                                                   --
-- Project:       Voyeur                                             --
-- Filename:      clustering.lua                                     --
-- Description:   Clustering GUI interface to libkinect              --
--                                                                   --
-----------------------------------------------------------------------

local oo        = require "loop.simple"
local Designer  = require "lrun.gui.designer"
local math      = require "math"
local assert, type, unpack, setmetatable, ipairs =
	  assert, type, unpack, setmetatable, ipairs
local gl, lrun   = gl, lrun
local print, string = print, string

require "lrun.gui.widget.panel"
require "lrun.gui.widget.slider"
require "lrun.gui.widget.text"
require "lrun.gui.widget.groupbox"
require "lrun.gui.widget.radio"
require "lrun.gui.widget.button"

module ("voyeur.clustering", oo.class)

C_LAB = "LAB"
C_HSV = "HSV"
C_RGB = "RGB"

MIN_CLUSTERS = 2
MAX_CLUSTERS = 10
MIN_MEDIAN = 1
MAX_MEDIAN = 15
MIN_SMOOTH = 1
MAX_SMOOTH = 15

clusters = 6
median = 5
smooth = 7
colorspace = C_HSV
channel1 = true
channel2 = true
channel3 = true

function createoptionspanel(handlers)
	local optionspanel = lrun.gui.widget.panel{
		name = "pn_cluster_options",
		radius = 10,
		color1 = {0.8, 0.8, 0.8},
		w = 480,
		h = 119,
		-- slider for number of clusters
		lrun.gui.widget.text{
			fontsize = 14,
			text = "Clusters",
			bordersize = 0,
			x = 7,
			y = 5,
			w = 78,
			h = 19
		},
		lrun.gui.widget.slider{
			name = "sl_clusters",
			vertical = false,
			color1 = { 0.9, 0.9, 0.9, },
			color2 = { 0.9, 0.9, 0.9, },
			sliderradius = 4,
			x = 73,
			y = 6,
			w = 137,
			h = 22,
			value = (clusters - MIN_CLUSTERS) / (MAX_CLUSTERS - MIN_CLUSTERS)
		},
		lrun.gui.widget.text{
			name = "t_clusters",
			fontsize = 14,
			text = clusters,
			bordersize = 0,
			x = 221,
			y = 8,
			w = 36,
			h = 23
		},

		-- slider for median filter size
		lrun.gui.widget.text{
			fontsize = 14,
			text = "Median",
			bordersize = 0,
			x = 9,
			y = 30,
			w = 78,
			h = 20
		},
		lrun.gui.widget.slider{
			name = "sl_median",
			vertical = false,
			sliderradius = 4,
			color1 = { 0.9, 0.9, 0.9, },
			color2 = { 0.9, 0.9, 0.9, },
			x = 73,
			y = 33,
			w = 138,
			h = 22,
			value = (median - MIN_MEDIAN) / (MAX_MEDIAN - MIN_MEDIAN)
		},
		lrun.gui.widget.text{
			name = "t_median",
			fontsize = 14,
			text = median,
			bordersize = 0,
			x = 221,
			y = 36,
			w = 36,
			h = 19
		},

		-- slider for smoothing filter size
		lrun.gui.widget.text{
			fontsize = 14,
			text = "Smooth",
			bordersize = 0,
			x = 2,
			y = 58,
			w = 79,
			h = 20
		},
		lrun.gui.widget.slider{
			vertical = false,
			sliderradius = 4,
			color1 = { 0.9, 0.9, 0.9, },
			color2 = { 0.9, 0.9, 0.9, },
			name = "sl_smooth",
			x = 73,
			y = 62,
			w = 138,
			h = 22,
			value = (smooth - MIN_SMOOTH) / (MAX_SMOOTH - MIN_SMOOTH)
		},
		lrun.gui.widget.text{
			name = "t_smooth",
			fontsize = 14,
			text = smooth,
			bordersize = 0,
			x = 222,
			y = 63,
			w = 36,
			h = 21
		},

		lrun.gui.widget.groupbox{
			radius = 10,
			color1 = { 0, 0, 0, 0.005, },
			name = "grp_colors",
			x = 3,
			y = 87,
			w = 253,
			h = 30,
			lrun.gui.widget.text{
				fontsize = 14,
				text = "CIELab",
				bordersize = 0,
				x = 28,
				y = 7,
				w = 58,
				h = 18
			},
			lrun.gui.widget.text{
				fontsize = 14,
				text = "HSV",
				bordersize = 0,
				x = 117,
				y = 8,
				w = 58,
				h = 18
			},
			lrun.gui.widget.text{
				fontsize = 14,
				text = "RGB",
				bordersize = 0,
				x = 195,
				y = 8,
				w = 65,
				h = 21
			},
			lrun.gui.widget.radio{
				checked = colorspace == C_RGB,
				name = C_RGB,
				x = 169,
				y = 8,
				w = 21,
				h = 18,
				layout = lrun.gui.layout.anchor{ }
			},
			lrun.gui.widget.radio{
				checked = colorspace == C_HSV,
				name = C_HSV,
				x = 94,
				y = 6,
				w = 21,
				h = 18,
				layout = lrun.gui.layout.anchor{ }
			},
			lrun.gui.widget.radio{
				checked = colorspace == C_LAB,
				name = C_LAB,
				x = 4,
				y = 7,
				w = 21,
				h = 18,
				layout = lrun.gui.layout.anchor{ }
			}
		},
		lrun.gui.widget.panel{
			x = 260,
			y = 5,
			h = 118,
			w = 210,
			bordersize = 0,
			color1 = {0.8, 0.8, 0.8},
			lrun.gui.widget.text{
				name = "t_clustername",
				fontsize = 14,
				text = "Cluster 1",
				bordersize = 0,
				w = 72,
				h = 21
			},
			lrun.gui.widget.slider{
				name = "sl_currentcluster",
				vertical = false,
				color1 = { 0.9, 0.9, 0.9, },
				color2 = { 0.9, 0.9, 0.9, },
				sliderradius = 4,
				x = 73,
				w = 135,
				h = 22
			},
			lrun.gui.widget.button{
				name = "btn_resetclusters",
				alignment = "ALIGN_CENTER",
				fontsize = 14,
				text = "R",
				y = 23,
				w = 18,
				h = 19
			},
			lrun.gui.widget.button{
				name = "btn_startclustering",
				alignment = "ALIGN_CENTER",
				fontsize = 14,
				text = "CLUSTER",
				x = 20,
				y = 23,
				w = 70,
				h = 19
			},
			lrun.gui.widget.panel{
				x = 73,
				y = 44,
				h = 65,
				w = 210,
				bordersize = 0,
				color1 = {0.8, 0.8, 0.8},
				lrun.gui.widget.text{
					fontsize = 14,
					text = "Channel 1",
					bordersize = 0,
					w = 72,
					h = 21
				},
				lrun.gui.widget.checkbox{
					name = "cb_channel1",
					checked = channel1,
					x = 73,
					w = 21,
					h = 21
				},
				lrun.gui.widget.text{
					fontsize = 14,
					text = "Channel 2",
					bordersize = 0,
					y = 22,
					w = 72,
					h = 21
				},
				lrun.gui.widget.checkbox{
					name = "cb_channel2",
					checked = channel2,
					x = 73,
					y = 22,
					w = 21,
					h = 21
				},
				lrun.gui.widget.text{
					fontsize = 14,
					text = "Channel 3",
					bordersize = 0,
					y = 44,
					w = 72,
					h = 21
				},
				lrun.gui.widget.checkbox{
					name = "cb_channel3",
					checked = channel3,
					x = 73,
					y = 44,
					w = 21,
					h = 21
				},
			}
		}
	}

	-- configure sliders
	local slidercluster = optionspanel:findrecurseone{name = "sl_currentcluster"}
	local text = optionspanel:findrecurseone{name = "t_clustername"}
	slidercluster.eventmanager:listen(function (event)
		local value = math.floor(1 + (clusters - 1) * event.params[1])
		text:reshape{text = "Cluster "..value}
		if handlers.onclusterchanged then
			handlers.onclusterchanged(value)
		end
	end, "valuechanged")

	-- clustering slider
	local slider = optionspanel:findrecurseone{name = "sl_clusters"}
	local text = optionspanel:findrecurseone{name = "t_clusters"}
	slider.eventmanager:listen(function (event)
		local value = math.floor(MIN_CLUSTERS + (MAX_CLUSTERS - MIN_CLUSTERS) * event.params[1])
		clusters = value
		text:reshape{text = value}
		slidercluster:reshape{value = 0}

		if handlers.onclusterschanged then
			handlers.onclusterschanged(clusters)
		end
	end, "valuechanged")

	-- median slider
	local slider = optionspanel:findrecurseone{name = "sl_median"}
	local text = optionspanel:findrecurseone{name = "t_median"}
	slider.eventmanager:listen(function (event)
		local value = math.floor(MIN_MEDIAN + (MAX_MEDIAN - MIN_MEDIAN) * event.params[1])
		median = value
		text:reshape{text = value}
		if handlers.onmedianchanged then
			handlers.onmedianchanged(median)
		end
	end, "valuechanged")

	-- smooth slider
	local slider = optionspanel:findrecurseone{name = "sl_smooth"}
	local text = optionspanel:findrecurseone{name = "t_smooth"}
	slider.eventmanager:listen(function (event)
		local value = math.floor(MIN_SMOOTH + (MAX_SMOOTH - MIN_SMOOTH) * event.params[1])
		smooth = value
		text:reshape{text = value}
		if handlers.onsmoothchanged then
			handlers.onsmoothchanged(smooth)
		end
	end, "valuechanged")

	local button = optionspanel:findrecurseone{name = "btn_resetclusters"}
	button.eventmanager:listen(function (event)
		if handlers.onclustersreset then
			handlers.onclustersreset()
			slidercluster:reshape{value = 0}
		end
	end, "onpressed")

	button = optionspanel:findrecurseone{name = "btn_startclustering"}
	button.eventmanager:listen(function (event)
		if handlers.onstartclustering then
			handlers.onstartclustering()
		end
	end, "onpressed")

	local function ntrues(...)
		local c = 0
		for _, b in ipairs{...} do
			if b then c = c + 1 end
		end
		return c
	end
	-- configure checkboxes
	local checkbox = optionspanel:findrecurseone{name = "cb_channel1"}
	checkbox.eventmanager:listen(function (event)
		channel1 = event.name == "oncheck"
		if ntrues(channel1, channel2, channel3) == 0 then
			event.source:reshape{checked = true}
		else
			if handlers.onchannelschanged then
				handlers.onchannelschanged(channel1, channel2, channel3)
			end
		end
	end, {"oncheck", "onuncheck"})

	checkbox = optionspanel:findrecurseone{name = "cb_channel2"}
	checkbox.eventmanager:listen(function (event)
		channel2 = event.name == "oncheck"
		if ntrues(channel1, channel2, channel3) == 0 then
			event.source:reshape{checked = true}
		else
			if handlers.onchannelschanged then
				handlers.onchannelschanged(channel1, channel2, channel3)
			end
		end
	end, {"oncheck", "onuncheck"})

	checkbox = optionspanel:findrecurseone{name = "cb_channel3"}
	checkbox.eventmanager:listen(function (event)
		channel3 = event.name == "oncheck"
		if ntrues(channel1, channel2, channel3) == 0 then
			event.source:reshape{checked = true}
		else
			if handlers.onchannelschanged then
				handlers.onchannelschanged(channel1, channel2, channel3)
			end
		end
	end, {"oncheck", "onuncheck"})

	-- configure colors group
	local colorsgroup = optionspanel:findrecurseone{name = "grp_colors"}
	colorsgroup.eventmanager:listen(function (event)
		local radio = event.params[1]
		colorspace = radio.name
		if handlers.oncolorschanged then
			handlers.oncolorschanged(colorspace)
		end
	end, "statechanged")

	return optionspanel
end

createoptionspanel = createoptionspanel

return _M
