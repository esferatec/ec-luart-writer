local ui = require("ui")
require "webview"
local sys = require("sys")

local EDITORFILE = embed and embed.File('main.html') or sys.File(sys.File(arg[1]).path .. "/main.html")

local editorAction = nil

local function topercent(value)
    return tostring(value * 100) .. "%"
end

local windowmain = ui.Window("ecWriter", "dialog", 800, 500)
local menumain = ui.Menu("|||", "File", "Edit", "Zoom")
local menufile = ui.Menu("New", "Open", "Save")
local menuedit = ui.Menu("Undo", "Redo", "", "Cut", "Copy", "Paste", "", "Delete")
local menuzoom = ui.Menu("Increase", "Decrease", "Reset")
local webvieweditor = ui.Webview(windowmain, EDITORFILE.fullpath)

local function statusUpdate()
    windowmain:status("  zoom: " .. topercent(webvieweditor.zoom))
end

local function editorNew()
    editorAction = "new"
    webvieweditor:eval("quill.setContents([{ insert: '\\n' }]);")
end

local function editorOpen()
    editorAction = "open"

    local content = ""
    local file = ui.opendialog("", false, "quill file (*.ecquill)|*.ecquill")

    if file ~= nil then
        file:open("read")
        content = file:read()
        file:close()

        webvieweditor:eval("quill.setContents(" .. content .. ");")
    end
end

local function editorSave()
    editorAction = "save"
    webvieweditor:eval("quill.getContents();")
end

local function editorUndo()
    editorAction = "undo"
    webvieweditor:eval("quill.history.undo();")
end

local function editorRedo()
    editorAction = "redo"
    webvieweditor:eval("quill.history.redo();")
end

local function editorCut()
    editorAction = "cut"
    webvieweditor:eval(
        "var range = quill.getSelection(); quill.getText(range.index, range.length); quill.deleteText(range.index, range.length);")
end

local function editorCopy()
    editorAction = "copy"
    webvieweditor:eval("var range = quill.getSelection(); quill.getText(range.index, range.length);")
end

local function editorPaste()
    editorAction = "paste"
    webvieweditor:eval("var range = quill.getSelection(); quill.insertText(range.index, '" .. sys.clipboard .. "');")
end

local function editorDelete()
    editorAction = "delete"
    webvieweditor:eval("var range = quill.getSelection(); quill.deleteText(range.index, range.length);")
end

local function editorIncrease()
    editorAction = "increase"
    webvieweditor.zoom = webvieweditor.zoom + 0.1
    statusUpdate()
end

local function editorDecrease()
    editorAction = "decrease"
    webvieweditor.zoom = webvieweditor.zoom - 0.1
    statusUpdate()
end

local function editorReset()
    editorAction = "reset"
    webvieweditor.zoom = 1
    statusUpdate()
end

function webvieweditor:onResult(result)
    if editorAction == "copy" then
        sys.clipboard = result
    end

    if editorAction == "save" then
        local file = ui.savedialog("", false, "quill file (*.ecquill)|*.ecquill")

        if file == nil then
            return
        end

        if file.exists then
            if ui.confirm("File already exists. Do you want to overrwrite?") ~= "yes" then
                return
            end
        end

        file:open("write")
        file:write(result)
        file:flush()
        file:close()
    end
end

function  windowmain:onClose()
    if ui.confirm("Do you want to save the content?") == "yes" then
        editorSave()
    end
end

function windowmain:onCreate()
    self.bgcolor = 0xFFFFFF

    self.menu = menumain
    self.menu.items[2].submenu = menufile
    self.menu.items[3].submenu = menuedit
    self.menu.items[4].submenu = menuzoom

    menufile.items[1].onClick = editorNew
    menufile.items[2].onClick = editorOpen
    menufile.items[3].onClick = editorSave

    menuedit.items[1].onClick = editorUndo
    menuedit.items[2].onClick = editorRedo
    menuedit.items[4].onClick = editorCut
    menuedit.items[5].onClick = editorCopy
    menuedit.items[6].onClick = editorPaste
    menuedit.items[8].onClick = editorDelete

    menuzoom.items[1].onClick = editorIncrease
    menuzoom.items[2].onClick = editorDecrease
    menuzoom.items[3].onClick = editorReset

    for item in each(menuzoom.items) do
        item:loadicon("./icons/" .. item.text .. ".ico")
    end

    self:status()
    self:loadicon("main.ico")
    self:center()
end

function webvieweditor:onCreate()
    self.align = "all"
end

function webvieweditor:onReady()
    self.devtools = false
    self.statusbar = false
    self.contextmenu = false
end

function windowmain:onKey(key)
    windowmain:status("Pressed Key : " .. key)
end

statusUpdate()

ui.run(windowmain):wait()
