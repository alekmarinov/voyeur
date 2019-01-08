@echo off
SET LUA_CPATH=%LUA_CPATH%;?.dll;?/core.dll;%LRUN_HOME%/lib/lua/5.1/?.dll;%LRUN_HOME%/lib/lua/5.1/?/core.dll;%LRUN_HOME%/?.dll;%LRUN_HOME%/?/core.dll
SET MOD_LUA=%LRUN_SRC_HOME%/modules/lua
SET LUA_PATH=%LUA_PATH%;?.lua;?/init.lua;%MOD_LUA%/?.lua;%MOD_LUA%/logging/?.lua;%MOD_LUA%/socket/?.lua;lua/?.lua
lua ..\..\modules\lua\lrun\start.lua voyeur.main D:\Media\Kinect
