require "luakinect"

kn = kinect.new()

function setlabel(x, y, label)
	kn:set_label(x, y, label)
end

function fixframe()
	for i=0,479 do
		for j=0,319 do
			local label = kn:get_label(j, i)

			if label == "LABEL_RIGHT_UPPER_ARM" then
				setlabel(j, i, "LABEL_LEFT_UPPER_ARM")
			elseif label == "LABEL_RIGHT_LOWER_ARM" then
				setlabel(j, i, "LABEL_LEFT_LOWER_ARM")
			elseif label == "LABEL_RIGHT_PALM" then
				setlabel(j, i, "LABEL_LEFT_PALM")
			end
		end
	end

	for i=0,479 do
		for j=320,639 do
			local label = kn:get_label(j, i)
			if label == "LABEL_LEFT_UPPER_ARM" then
				setlabel(j, i, "LABEL_RIGHT_UPPER_ARM")
			elseif label == "LABEL_LEFT_LOWER_ARM" then
				setlabel(j, i, "LABEL_RIGHT_LOWER_ARM")
			elseif label == "LABEL_LEFT_PALM" then
				setlabel(j, i, "LABEL_RIGHT_PALM")
			end
		end
	end
	kn:save_frame()
end

filename = assert(arg[1], "expected .knd filename")
kn:load_file_name(filename)
rc = kn:start_playing(true)
n = 1
while kn:play_frame() do
	print(n)
	fixframe()
	n = n + 1
end
