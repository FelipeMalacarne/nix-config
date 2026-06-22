local dir = debug.getinfo(1, "S").source:match("^@?(.*)/")
package.path = dir .. "/?.lua;" .. dir .. "/?/init.lua;" .. package.path

require("config.options")
