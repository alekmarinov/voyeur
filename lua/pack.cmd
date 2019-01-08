@echo off
SET OLUA_PATH=%LUA_PATH%
SET LUA_PATH=%LUA_PATH%;lua/?.lua
lua ..\..\..\modules\lua\lrun\start.lua lrun.tool.luadep voyeur voyeur ..\dist 1.0
SET LUA_PATH=%OLUA_PATH%
