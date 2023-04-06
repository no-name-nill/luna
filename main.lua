

        local SDL = require "SDL"
        local image = require "SDL.image"
        --local ttf = require "SDL.ttf"
         
         
        local Window = {
                WIDTH = 640,
                HEIGHT = 360,
                is_running = true,
                Editor = nil,
                font = nil,
                ctrl = false,
                shift = false,
                is_commanding = false,
                command = {},
                Directory = nil
        }
         
         
        --Window.
        local Editor = {
                                        x = 150,
                                        y = 0,
                                        WIDTH = nil,
                                        HEIGHT = nil,
                                        CHARS = nil,
                                        LINES = nil,
                                        number_offset = nil,
                                        scroll_v = 0,
                                        scroll_h = 0,
                                        is_Focused = true,
                                        cursor = nil,
                                        filename = nil
        }
         
        Editor.WIDTH = Window.WIDTH-Editor.x
        Editor.HEIGHT = Window.HEIGHT-Editor.y
        Editor.number_offset = 3
         
        --Editor.background = 0xFF1B1B1D
        Editor.background_color = {r=27, g=27, b=29}
         
         
        local function trySDL(func, ...)
                local t = {func(...)}
                if not t[1] then
                        error(t[#t])
                end
         
                return unpack(t)
        end
         
         
        local function init_ttp(font_sheet, renderer)
         
                local CHARs = 95 --94
                local MAX_ROW = 27
         
                local rect = {}
         
                local chars = {n=94}
         
                rect.w = 18.5
                rect.h = 21
                rect.x = 0
                rect.y = 0
               
                local cur_row = 1
         
                for i=1, CHARs, 1
                do
                        if i==1 then
                                rect.w = 5
                        else
                                rect.w = 18.5
                        end
         
                        chars[i] = renderer:createTexture(SDL.pixelFormat.RGBA8888, SDL.textureAccess.Target, rect.w, rect.h)
                        chars[i]:setBlendMode(SDL.blendMode.Blend)
         
                        renderer:setTarget(chars[i])
                        renderer:copy(font_sheet, rect, nil)
                        renderer:setTarget(nil)
               
                        rect.x = rect.x + rect.w
         
                        if math.floor((i-1)/MAX_ROW)+1 ~= cur_row then
                                cur_row = cur_row+1
                                rect.y = rect.y + rect.h
                                rect.x = 0
                        end
         
                end
               
                return {w = 18.5, h = 21, chars = chars, size = 1}
         
        end
         
         
         
        local function get_text_size(text, font)
               
                local text_size = 0
               
                for i=1, #text, 1 do
               
                        if text:sub(i, i) == "\t" then
                       
                                text_size = text_size+(4*font.w*font.size)
                       
                        else
                               
                                text_size = text_size+(font.w*font.size)
                        end
                end
               
                return text_size
         
        end
         
        local function get_text_size_in_chars(text, font)
               
                local text_size = 0
               
                for i=1, #text, 1 do
               
                        if text:sub(i, i) == "\t" then
                       
                                text_size = text_size+4
                       
                        else
                               
                                text_size = text_size+1
                        end
                end
               
                return text_size
         
        end
         
         
         
         
        local function render_text(renderer, font, text, pos, color)
         
                if not renderer then
                        return -1
                end
         
                if not font then
                        return -1
                end
         
                if not text then
                        return -1
                end
         
                if not color then
                        color = 0xFFFFFFFF
                end
         
                if not pos then
                        pos = {x = 0, y = 0}
                end
               
                line = ""
               
                for i=1, #text, 1 do
                        if text:sub(i, i) == "\t" then
                                line = line .. "    "
                        else
                                line = line .. text:sub(i, i)
                        end
                       
                end
               
                for i=1, #line, 1  
                do             
                       
                        char = (string.byte(line, i)-32)
         
                        rect = {
                                w = font.w*font.size,
                                h = font.h*font.size,
                                x = pos.x+(i-1)*font.w*font.size,
                                y = pos.y
                        }
                       
                        font.chars[char+1]:setColorMod(color)
                        renderer:copy(font.chars[char+1], nil, rect)
                        font.chars[char+1]:setColorMod(0xFFFFFFFF)
                       
                end
         
        end
         
        local function render_cursor(renderer, x, y, w, h, color, fill)
               
                renderer:setDrawColor(color)
               
                if fill then
                        renderer:fillRect({w = w, h = h, x = x, y = y})
                else
                        renderer:drawRect({w = w, h = h, x = x, y = y})
                end
        end
         
        local function render_data(renderer, font, Editor)
         
                local size_till_cursor = get_text_size_in_chars(Editor.data[Editor.cursor.line+1]:sub(1, Editor.cursor.char+1), font)
                if size_till_cursor > Editor.CHARS+Editor.scroll_h then
                        Editor.scroll_h = Editor.scroll_h+1
                elseif size_till_cursor < Editor.scroll_h+1 and size_till_cursor~=0 then
                        Editor.scroll_h = Editor.scroll_h-1
                end
               
                if Editor.cursor.line+1 > Editor.LINES+Editor.scroll_v then
                        Editor.scroll_v = Editor.scroll_v+1
                elseif Editor.cursor.line < Editor.scroll_v then
                        Editor.scroll_v = Editor.scroll_v-1
                end
         
                local cursor_x = Editor.x+ get_text_size(Editor.data[Editor.cursor.line+1]:sub(Editor.scroll_h+1, Editor.cursor.char) ,font)+(font.w*font.size*Editor.number_offset)--(cursor.char-Editor.scroll_h)*font.w*font.size
                local cursor_y = (Editor.y+Editor.cursor.line-Editor.scroll_v)*font.h
               
                render_cursor(renderer, cursor_x, cursor_y, Editor.cursor.w, Editor.cursor.h, Editor.cursor.color, Editor.is_Focused)
         
                for i = 1, #Editor.data do
                       
                        if i > Editor.scroll_v then
                               
                                if i == Editor.cursor.line+1 then
                                                font.size = 0.8
                                        render_text(renderer, font, tostring(i), {x=Editor.x, y=(i-1-Editor.scroll_v)*font.h}, 0xFFFFFF00)
                                else
                                        font.size = 0.7
                                        render_text(renderer, font, tostring(i), {x=Editor.x, y=(i-1-Editor.scroll_v)*font.h}, 0xFFFFFFFF)
                                end
                                font.size = 1
                       
                       
                               
                                if (get_text_size(Editor.data[i], font)/font.w)>Editor.CHARS then
                                        render_text(renderer, font, Editor.data[i]:sub(Editor.scroll_h+1, Editor.scroll_h+1+Editor.CHARS),
                                        {x=Editor.x+(Editor.number_offset*font.w), y=(i-1-Editor.scroll_v)*font.h})
                                else
                                        render_text(renderer, font, Editor.data[i]:sub(Editor.scroll_h+1, -1), {x=Editor.x+(Editor.number_offset*font.w), y=(i-1-Editor.scroll_v)*font.h})
                                end
                        end
                        --::continue::
                end
               
               
                --[[render_text(renderer, font,
                --Editor.data[cursor.line+1]:sub(cursor.char+1, cursor.char+1),
                --{x = Editor.x+get_text_size(Editor.data[cursor.line+1]:sub(1, cursor.char-Editor.scroll_h), font)+(Editor.number_offset*font.w*font.size), y = Editor.y+cursor.line*font.h*font.size }
                --,{r=background.r*5, g=background.g*5, b=background.b*5}
                )]]
               
        end
         
        local function render_command(renderer, Window, font)
                renderer:setDrawColor({r=36, g=36, b=38})
                local command_box = {w=Window.WIDTH, h=Window.HEIGHT, x=0,y=Window.HEIGHT-(font.h*font.size*2)}
                renderer:fillRect(command_box)
               
                local max_chars = math.floor(Window.WIDTH/font.w*font.size)
                local cursor_x = Window.command.cursor.char*font.w*font.size
                local scroll = 0
                if Window.command.cursor.char+1 > max_chars then
                        cursor_x = (max_chars-1)*font.w*font.size
                        scroll = Window.command.cursor.char+1-max_chars
                end
                render_cursor(renderer, cursor_x, command_box.y+(font.h/2),
                Window.command.cursor.w, Window.command.cursor.h, Window.command.cursor.color, true)
                if #Window.command.data > Window.WIDTH/font.w then
                        render_text(renderer, font, Window.command.data:sub(1+scroll, max_chars+scroll), {x=command_box.x, y=command_box.y+(font.h/2)})
                else
                        render_text(renderer, font, Window.command.data, {x=command_box.x, y=command_box.y+(font.h/2)})
                end
               
        end
         
         
        local function loadFile(filepath, Editor)
               
                if not filepath then
                        return
                end
               
                file, err = io.open(filepath, "r")
               
                if not file then
                        return err
                end
               
                local data = {}
                for line in file:lines() do
                        table.insert(Editor.data, line)
                end
               
                io.close(file)
               
                return data
               
        end
         
         
        local function saveFile(filepath, data)
         
                file, err = io.open(filepath, "w")
               
                if not file then
                        return err
                end
               
                for i=1, #Editor.data, 1 do
                        file:write(Editor.data[i])
                        file:write("\n")
                end
               
                io.close(file)
         
        end
         
         
        local function run_command(input, Editor)
               
                words = {}
                for w in input:gmatch("%S+") do
                        table.insert(words, w)
                end
               
                if words[1] == "open" then
                        if not words[2] then
                                --error, provide a file name!!
                        else
                        loadFile(words[2], Editor)
                        Editor.filename = words[2]
                        end
                elseif words[1] == "save" then
                        if not words[2] then
                                if not Editor.filename then
                                        --error
                                else
                                        saveFile(Editor.filename, Editor.data)
                                end
                        else
                                saveFile(words[2], Editor.data)
                        end
                        --find
                elseif words[1] == "change_dir" thrn
                        if not words[2] then
                         --error
                        else
                                Window.Directory = words[2]
                        end
                else
                        --return error message
                end
               
         
        end
         
         
         
        --local function handle_resize()
        --end
         
         
        local function handle_event(event, Window, Editor)
         
                if event.type == SDL.event.Quit then
                        Window.is_running = false
                end
                --handle resizing
               
                if Editor.is_Focused then
                        if event.type == SDL.event.TextInput then
                                Editor.data[Editor.cursor.line+1] = Editor.data[Editor.cursor.line+1]:sub(1, Editor.cursor.char)
                                .. event.text ..
                                Editor.data[Editor.cursor.line+1]:sub(Editor.cursor.char+1, -1)
                       
                                Editor.cursor.char = Editor.cursor.char + 1
                       
                        elseif event.type == SDL.event.KeyDown then
                                --
                                if event.keysym.sym == SDL.key.Backspace then
                                        if Editor.cursor.char ~=0 then
                                                Editor.data[Editor.cursor.line+1] =
                                                        Editor.data[Editor.cursor.line+1]:sub(1, Editor.cursor.char-1) ..
                                                        Editor.data[Editor.cursor.line+1]:sub(Editor.cursor.char+1, -1)
                                               
                                                        Editor.cursor.char = Editor.cursor.char-1
                               
                                        elseif Editor.cursor.line~=0 then
                                                Editor.cursor.char = #Editor.data[Editor.cursor.line]
                                                Editor.data[Editor.cursor.line] = Editor.data[Editor.cursor.line]..Editor.data[Editor.cursor.line+1]
                                                table.remove(Editor.data, Editor.cursor.line+1)
                                                Editor.cursor.line = Editor.cursor.line-1
                               
                                        end
                               
                                elseif event.keysym.sym == SDL.key.Return then
                                        table.insert(Editor.data, Editor.cursor.line+1+1,
                                        Editor.data[Editor.cursor.line+1]:sub(Editor.cursor.char+1, -1))
                                       
                                        Editor.data[Editor.cursor.line+1] = Editor.data[Editor.cursor.line+1]:sub(1, Editor.cursor.char)
                               
                                        Editor.cursor.line = Editor.cursor.line+1
                                        Editor.cursor.char = 0
                       
                                elseif event.keysym.sym==SDL.key.Left then
                                                               
                                        if Editor.cursor.char>0 then
                                                Editor.cursor.char = Editor.cursor.char-1
                                       
                                        elseif Editor.cursor.char<=0 and
                                        Editor.cursor.line > 0 then
                                                Editor.cursor.char = #Editor.data[Editor.cursor.line]
                                                Editor.cursor.line = Editor.cursor.line-1
                                        end
                               
                                elseif event.keysym.sym==SDL.key.Right then
                       
                                        if Editor.cursor.char < #Editor.data[Editor.cursor.line+1] then
                                                Editor.cursor.char = Editor.cursor.char+1
                                       
                                        elseif Editor.cursor.char >= #Editor.data[Editor.cursor.line+1] and
                                        Editor.cursor.line+1 < #Editor.data then
                                                Editor.cursor.char = 0
                                                Editor.cursor.line = Editor.cursor.line+1
                                        end
               
                       
                                elseif event.keysym.sym == SDL.key.Up then
                                        if Editor.cursor.line ~=0 then
                                                Editor.cursor.line = Editor.cursor.line-1
                                               
                                                if #Editor.data[Editor.cursor.line+1]<=Editor.cursor.char then
                                                        Editor.cursor.char = #Editor.data[Editor.cursor.line+1]
                                                       
                                                end
                                        end    
                       
                                elseif event.keysym.sym == SDL.key.Down then
                                        if Editor.cursor.line+1 ~= #Editor.data then
                                                Editor.cursor.line = Editor.cursor.line+1
                                                if #Editor.data[Editor.cursor.line+1]<=Editor.cursor.char then
                                                        Editor.cursor.char = #Editor.data[Editor.cursor.line+1]
                                                       
                                                end
                                        end
                                       
                                elseif event.keysym.sym == SDL.key.Tab then
                                        Editor.data[Editor.cursor.line+1] = Editor.data[Editor.cursor.line+1]:sub(1, Editor.cursor.char)
                                        .. "\t" .. Editor.data[Editor.cursor.line+1]:sub(Editor.cursor.char+1, -1)
                                       
                                        Editor.cursor.char = Editor.cursor.char+1
                                                       
                                end
                        end
                       
                        elseif Window.is_commanding then
                               
                                if event.type == SDL.event.TextInput then
                                        Window.command.data =
                                        Window.command.data:sub(1, Window.command.cursor.char)
                                        .. event.text ..
                                        Window.command.data:sub(Window.command.cursor.char+1, -1)
                       
                                        Window.command.cursor.char = Window.command.cursor.char + 1
                               
                                elseif event.type == SDL.event.KeyDown then
                                        if event.keysym.sym == SDL.key.Left then
                                                if Window.command.cursor.char ~=0 then
                                                        Window.command.cursor.char = Window.command.cursor.char-1
                                                end
                                        elseif event.keysym.sym == SDL.key.Right then
                                                if Window.command.cursor.char+1 ~= #Window.command.data then
                                                        Window.command.cursor.char = Window.command.cursor.char+1
                                                end
                                        elseif event.keysym.sym == SDL.key.Backspace then
                                                if Window.command.cursor.char ~= 0 then
                                                        Window.command.data = Window.command.data:sub(1, Window.command.cursor.char-1)
                                                        .. Window.command.data:sub( Window.command.cursor.char+1,-1)
                                                        Window.command.cursor.char = Window.command.cursor.char-1
                                                end
                                        elseif event.keysym.sym == SDL.key.Return then
                                                Window.is_commanding = false
                                                Editor.is_Focused = true
                                                local output_msg = run_command(Window.command.data, Editor)
                                                Window.command.data = nil
                                                Window.command.cursor.char = 0
                                        end
                                end
                end
                       
                if event.type == SDL.event.KeyDown then
                               
                        if event.keysym.sym == SDL.key.LeftControl then
                                Window.ctrl = true
                               
                        elseif event.keysym.sym == SDL.key.s and Window.ctrl then
                                saveFile(Editor.filename, Editor.data)
                               
                        elseif event.keysym.sym == SDL.key.n and Window.ctrl then
                                Editor.data = {""}
                                Editor.cursor.line = 0
                                Editor.cursor.char = 0
                               
                        elseif event.keysym.sym == SDL.key.r and Window.ctrl then
                                if not Window.is_commanding then
                                        Editor.is_Focused = false
                                        Window.is_commanding = true
                                        Window.command.data = ""
                                        Window.command.cursor.char = 0
                                else
                                        Editor.is_Focused = true
                                        Window.is_commanding = false
                                        Window.command.data = nil
                                end
                        --find
                        --elseif event.keysym.sym == SDL.key.esc and ctrl then Window.is_running = false
                               
                       
                        end
                               
                elseif event.type == SDL.event.KeyUp and
                event.keysym.sym == SDL.key.LeftControl then
                        Window.ctrl = false
                end
         
        end
         
         
        trySDL(SDL.init, {SDL.flags.Video})
         
         
        local win = trySDL(SDL.createWindow, {
                title = "Luna",
                width  = Window.WIDTH,
                height = Window.HEIGHT,
                flags = {SDL.window.Resizable}
        })
         
         
        local renderer = trySDL(SDL.createRenderer, win, -1)
         
         
        local font_surface = trySDL(image.load, "res/ttp3.png")
        local font_sheet  = trySDL(renderer.createTextureFromSurface, renderer, font_surface)
        local font = init_ttp(font_sheet, renderer)
        font.w = font.w*0.75
        font.h = font.h*0.75
        font.size = 1
         
        Editor.CHARS = math.floor(Editor.WIDTH/font.w*font.size)-Editor.number_offset
        Editor.LINES = math.floor(Editor.HEIGHT/font.h*font.size)
         
        Editor.cursor = {char = 0, line = 0, w = 10, h = font.h, color = 0xFFFFFF00}
        Window.command.cursor = {char = 0, w = 10, h = font.h, color = 0xFFFFFF00}
         
        Editor.data = {""}
        --data can be a rope or an array of lines
         
        while (Window.is_running) do
         
                for e in SDL.pollEvent() do
                       
                        handle_event(e, Window, Editor)
                       
                end
         
                renderer:setDrawColor(Editor.background_color)
                renderer:clear()
                render_data(renderer, font, Editor)
                renderer:setDrawColor({r=34, g=34, b=36})       -- for now, the file manager
                renderer:fillRect({w=150, h=360, x=0,y=0})      -- is just an empty rect
                if Window.is_commanding then render_command(renderer, Window, font) end
                renderer:present()
         
        end
         
        SDL.quit()
         

