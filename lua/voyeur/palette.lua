-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2010,  AVIQ Systems AG                         --
--                                                                   --
-- Project:       Voyeur                                             --
-- Filename:      palette.lua                                        --
-- Description:   Clustering palette GUI interface to libkinect      --
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

module ("voyeur.palette", oo.class)

local radios = {
	"NN",
	"B",
	"LUA",
	"LLA",
	"LP",
	"LL",
	"LR",
	"LM",
	"LI",
	"LT",
	"RUA",
	"RLA",
	"RP",
	"RL",
	"RR",
	"RM",
	"RI",
	"RT"
}

local bodynumber = 1

local labels = {
	NN   = "LABEL_NONE",
	B    = "LABEL_BODY_",
	LUA  = "LABEL_LEFT_UPPER_ARM",
	LLA	 = "LABEL_LEFT_LOWER_ARM",
	LP	 = "LABEL_LEFT_PALM",
	LL	 = "LABEL_LEFT_FINGER_LITTLE",
	LR	 = "LABEL_LEFT_FINGER_RING",
	LM	 = "LABEL_LEFT_FINGER_MIDDLE",
	LI	 = "LABEL_LEFT_FINGER_INDEX",
	LT	 = "LABEL_LEFT_FINGER_THUMB",
	RUA  = "LABEL_RIGHT_UPPER_ARM",
	RLA	 = "LABEL_RIGHT_LOWER_ARM",
	RP	 = "LABEL_RIGHT_PALM",
	RL	 = "LABEL_RIGHT_FINGER_LITTLE",
	RR	 = "LABEL_RIGHT_FINGER_RING",
	RM	 = "LABEL_RIGHT_FINGER_MIDDLE",
	RI	 = "LABEL_RIGHT_FINGER_INDEX",
	RT	 = "LABEL_RIGHT_FINGER_THUMB",
}

function createoptionspanel(handlers)
	local optionspanel = lrun.gui.widget.groupbox{
		name = "pn_cluster_palette",
		radius = 10,
		color1 = { 0.8, 0.8, 0.8, },
		w = 278,
		h = 119,
		lrun.gui.widget.text{
			bordersize = 0,
			fontsize = 16,
			alignment = "ALIGN_CENTER",
			text = "L",
			x = 6,
			y = 30,
			w = 26,
			h = 23
		},
		lrun.gui.widget.text{
			bordersize = 0,
			fontsize = 16,
			alignment = "ALIGN_CENTER",
			text = "R",
			x = 6,
			y = 58,
			w = 26,
			h = 23
		},
		lrun.gui.widget.text{
			bordersize = 0,
			fontsize = 16,
			alignment = "ALIGN_CENTER",
			text = "UA",
			x = 35,
			y = 4,
			w = 26,
			h = 23
		},
		lrun.gui.widget.radio{
			radius = 10,
			name = "RUA",
			x = 35,
			y = 57,
			w = 26,
			h = 23,
			layout = lrun.gui.layout.anchor{ }
		},
		lrun.gui.widget.text{
			bordersize = 0,
			fontsize = 16,
			alignment = "ALIGN_CENTER",
			text = "LA",
			x = 65,
			y = 4,
			w = 26,
			h = 23
		},
		lrun.gui.widget.radio{
			radius = 10,
			name = "LLA",
			x = 66,
			y = 30,
			w = 26,
			h = 23,
			layout = lrun.gui.layout.anchor{ }
		},
		lrun.gui.widget.radio{
			radius = 10,
			name = "RLA",
			x = 65,
			y = 57,
			w = 26,
			h = 23,
			layout = lrun.gui.layout.anchor{ }
		},
		lrun.gui.widget.text{
			bordersize = 0,
			fontsize = 16,
			alignment = "ALIGN_CENTER",
			text = "P",
			x = 95,
			y = 4,
			w = 26,
			h = 23
		},
		lrun.gui.widget.radio{
			radius = 10,
			name = "LP",
			x = 95,
			y = 30,
			w = 26,
			h = 23,
			layout = lrun.gui.layout.anchor{ }
		},
		lrun.gui.widget.radio{
			radius = 10,
			name = "RP",
			x = 95,
			y = 57,
			w = 26,
			h = 23,
			layout = lrun.gui.layout.anchor{ }
		},
		lrun.gui.widget.text{
			bordersize = 0,
			fontsize = 16,
			alignment = "ALIGN_CENTER",
			text = "L",
			x = 125,
			y = 4,
			w = 26,
			h = 23
		},
		lrun.gui.widget.radio{
			radius = 10,
			name = "LL",
			x = 125,
			y = 30,
			w = 26,
			h = 23,
			layout = lrun.gui.layout.anchor{ }
		},
		lrun.gui.widget.radio{
			radius = 10,
			name = "RL",
			x = 125,
			y = 57,
			w = 26,
			h = 23,
			layout = lrun.gui.layout.anchor{ }
		},
		lrun.gui.widget.text{
			bordersize = 0,
			fontsize = 16,
			alignment = "ALIGN_CENTER",
			text = "R",
			x = 155,
			y = 4,
			w = 26,
			h = 23
		},
		lrun.gui.widget.radio{
			radius = 10,
			name = "LR",
			x = 155,
			y = 30,
			w = 26,
			h = 23,
			layout = lrun.gui.layout.anchor{ }
		},
		lrun.gui.widget.radio{
			radius = 10,
			name = "RR",
			x = 155,
			y = 57,
			w = 26,
			h = 23,
			layout = lrun.gui.layout.anchor{ }
		},
		lrun.gui.widget.text{
			bordersize = 0,
			fontsize = 16,
			alignment = "ALIGN_CENTER",
			text = "M",
			x = 185,
			y = 4,
			w = 26,
			h = 23
		},
		lrun.gui.widget.radio{
			radius = 10,
			name = "LM",
			x = 185,
			y = 30,
			w = 26,
			h = 23,
			layout = lrun.gui.layout.anchor{ }
		},
		lrun.gui.widget.radio{
			radius = 10,
			name = "RM",
			x = 185,
			y = 57,
			w = 26,
			h = 23,
			layout = lrun.gui.layout.anchor{ }
		},
		lrun.gui.widget.text{
			bordersize = 0,
			fontsize = 16,
			alignment = "ALIGN_CENTER",
			text = "I",
			x = 215,
			y = 4,
			w = 26,
			h = 23
		},
		lrun.gui.widget.radio{
			radius = 10,
			name = "LI",
			x = 215,
			y = 30,
			w = 26,
			h = 23,
			layout = lrun.gui.layout.anchor{ }
		},
		lrun.gui.widget.radio{
			radius = 10,
			name = "RI",
			x = 215,
			y = 57,
			w = 26,
			h = 23,
			layout = lrun.gui.layout.anchor{ }
		},
		lrun.gui.widget.text{
			bordersize = 0,
			fontsize = 16,
			alignment = "ALIGN_CENTER",
			text = "T",
			x = 245,
			y = 4,
			w = 26,
			h = 23
		},
		lrun.gui.widget.radio{
			radius = 10,
			name = "LT",
			x = 245,
			y = 30,
			w = 26,
			h = 23,
			layout = lrun.gui.layout.anchor{ }
		},
		lrun.gui.widget.radio{
			radius = 10,
			name = "RT",
			x = 245,
			y = 57,
			w = 26,
			h = 23,
			layout = lrun.gui.layout.anchor{ }
		},
		lrun.gui.widget.radio{
			radius = 10,
			name = "LUA",
			x = 35,
			y = 30,
			w = 26,
			h = 23,
			layout = lrun.gui.layout.anchor{ }
		},
		lrun.gui.widget.radio{
			checked = true,
			radius = 10,
			name = "NN",
			focus = true,
			x = 6,
			y = 5,
			w = 26,
			h = 23,
			layout = lrun.gui.layout.anchor{ }
		},
		lrun.gui.widget.radio{
			radius = 10,
			name = "B",
			x = 8,
			y = 86,
			w = 26,
			h = 23,
			layout = lrun.gui.layout.anchor{ }
		},
		lrun.gui.widget.slider{
			name = "sl_bodylabel",
			vertical = false,
			color1 = { 0.9, 0.9, 0.9, },
			color2 = { 0.9, 0.9, 0.9, },
			sliderradius = 4,
			x = 39,
			y = 87,
			w = 180,
			h = 22
		},
		lrun.gui.widget.text{
			name = "t_bodylabel",
			text = "1",
			alignment = "ALIGN_CENTER",
			fontsize = 16,
			bordersize = 0,
			x = 220,
			y = 87,
			w = 20,
			h = 20
		},
		lrun.gui.widget.checkbox{
			radius = 5,
			name = "cb_overdraw",
			x = 243,
			y = 86,
			w = 26,
			h = 23,
			layout = lrun.gui.layout.anchor{ }
		},
	}

	-- configure slider
	local slider = optionspanel:findrecurseone{name = "sl_bodylabel"}
	local text = optionspanel:findrecurseone{name = "t_bodylabel"}
	slider.eventmanager:listen(function (event)
		local newnumber = math.floor(1 + (15 - 1) * event.params[1])
		if newnumber ~= bodynumber then
			bodynumber = newnumber
			text:reshape{text = bodynumber}
			optionspanel:findrecurseone{name = "B"}:reshape{checked = true}

			if handlers.onpalettechanged then
				handlers.onpalettechanged(labels.B..bodynumber)
			end
		end
	end, "valuechanged")

	local handler = function (event)
		local name = event.source.name
		local label = labels[name]
		if name == "B" then
			label = label .. bodynumber
		end
		if handlers.onpalettechanged then
			handlers.onpalettechanged(label)
		end
	end

	for _, radioname in ipairs(radios) do
		local radio = optionspanel:findrecurseone{name = radioname}
		radio.eventmanager:listen(handler, "oncheck")
	end

	local cb_overdraw = optionspanel:findrecurseone{name = "cb_overdraw"}
	cb_overdraw.eventmanager:listen(function (event)
		if handlers.onoverdraw then
			handlers.onoverdraw(event.name == "oncheck")
		end
	end, {"oncheck", "onuncheck"})

	return optionspanel
end

createoptionspanel = createoptionspanel

return _M
