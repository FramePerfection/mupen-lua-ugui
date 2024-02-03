-- mupen-lua-ugui retained mode
-- Aurumaker72 2024

local ugui = {
    messages = {
        -- The control has been created
        create = 0,
        -- The control is being destroyed
        destroy = 1,
        -- The control needs to be painted
        paint = 2,
        -- The control is being queried for its dimensions
        measure = 3,
        -- The control is asked to provide a rectangle[] for its children, or an empty table if no transformations are performed
        position_children = 4,
    },
    alignments = {
        -- The object is aligned to the start of its container
        start = 0,
        -- The object is aligned to the center of its container
        center = 1,
        -- The object is aligned to the end of its container
        ['end'] = 2,
        -- The object fills its container
        fill = 3,
    },
    util = {
        ---Message helper for measuring size by first child
        ---@param ugui table A ugui instance
        ---@param node table A node
        ---@return table The dimensions
        measure_by_child = function(ugui, node)
            -- Control's size is dictated by first child's dimensions
            if #node.children > 0 then
                return ugui.send_message(node.children[1], {
                    type = ugui.messages.measure,
                })
            else
                return {x = 0, y = 0}
            end
        end,

        ---Reduces an array
        ---@param list any[] An array
        ---@param fn function The reduction predicate
        ---@param init any The initial accumulator value
        ---@return any The final value of the accumulator
        reduce = function(list, fn, init)
            local acc = init
            for k, v in ipairs(list) do
                if 1 == k and not init then
                    acc = v
                else
                    acc = fn(acc, v)
                end
            end
            return acc
        end,

        ---Transforms all items in the collection via the predicate
        ---@param collection table
        ---@param predicate function A function which takes a collection element as a parameter and returns the modified element. This function should be pure in regards to the parameter.
        ---@return table table A collection of the transformed items
        select = function(collection, predicate)
            local t = {}
            for i = 1, #collection, 1 do
                t[i] = predicate(collection[i])
            end
            return t
        end,
    },
}

-- The control tree
local root_node = {
    uid = -1,
    type = 'panel',
    h_align = ugui.alignments.fill,
    v_align = ugui.alignments.fill,
    bounds = {},
    children = {},
}

-- Map of control types to templates
local registry = {}

-- List of invalidated uids
-- All children of the controls will be repainted too
local layout_queue = {}

-- Window size upon script start
local start_size = nil

---Deep clones an object
---@param obj any The current object
---@param seen any|nil The previous object, or nil for the first (obj)
---@return any A deep clone of the object
local function deep_clone(obj, seen)
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do
        res[deep_clone(k, s)] = deep_clone(
            v, s)
    end
    return res
end

---Finds a control in the root_node by its uid
---@param uid number A unique control identifier
---@param node table The node to begin the search from
local function find(uid, node)
    if uid == node.uid then
        return node
    end
    for _, child in pairs(node.children) do
        if child.uid == uid then
            return child
        end
        local result = find(uid, child)
        if result then
            return result
        end
    end
    return nil
end

---Traverses all nodes under a node
---@param node table The node to begin the iteration from
---@param predicate function A function which accepts a node
local function iterate(node, predicate)
    predicate(node)
    for key, value in pairs(node.children) do
        iterate(value, predicate)
    end
end

---Returns the base layout bounds for a node
---@param node table The node
---@param parent_rect table The parent's rectangle
local function get_base_layout_bounds(node, parent_rect)
    local size = ugui.send_message(node, {type = ugui.messages.measure})

    local rect = {
        x = parent_rect.x,
        y = parent_rect.y,
        width = size.x,
        height = size.y,
    }
    if node.h_align == ugui.alignments.center then
        rect.x = parent_rect.x + parent_rect.width / 2 - size.x / 2
    end
    if node.h_align == ugui.alignments['end'] then
        rect.x = parent_rect.x + parent_rect.width - size.x
    end
    if node.h_align == ugui.alignments.fill then
        rect.width = parent_rect.width
    end

    if node.v_align == ugui.alignments.center then
        rect.y = parent_rect.y + parent_rect.height / 2 - size.y / 2
    end
    if node.v_align == ugui.alignments['end'] then
        rect.y = parent_rect.y + parent_rect.height - size.y
    end
    if node.v_align == ugui.alignments.fill then
        rect.height = parent_rect.height
    end
    return rect
end

---Lays out a node and its children
---@param node table The node
---@param parent_rect table The parent's rectangle
local function layout_node(node, parent_rect)
    -- Compute layout bounds and apply them
    node.bounds = get_base_layout_bounds(node, parent_rect)

    -- Do child layout pass
    for _, child in pairs(node.children) do
        layout_node(child, node.bounds)
    end


    -- Layout node pass: let them reposition childrens' bounds after layout is finished
    local new_child_bounds = ugui.send_message(node, {type = ugui.messages.position_children})
    if new_child_bounds then
        for i = 1, #new_child_bounds, 1 do
            node.children[i].bounds = get_base_layout_bounds(node.children[i], new_child_bounds[i])
            layout_node(node.children[i], new_child_bounds[i])
        end
    end
end

---Invalidates a control's layout along with its children
---@param uid number A unique control identifier
local function invalidate_layout(uid)
    layout_queue[#layout_queue + 1] = uid
end

---Registers a control template, adding its type to the global registry
---@param control table A control
ugui.register_control = function(control)
    registry[control.type] = control
end

---Gets the userdata of a control
---@param uid number A unique control identifier
---@return any
ugui.get_udata = function(uid)
    return find(uid, root_node).udata
end

---Sets the userdata of a control
---@param uid number A unique control identifier
---@param data any The user data
ugui.set_udata = function(uid, data)
    find(uid, root_node).udata = data
end

---Appends a child to a control
---The control will be clobbered
---@param parent_uid number A unique control identifier of the parent
---@param control table A control
ugui.add_child = function(parent_uid, control)
    print('Adding ' .. control.type .. ' (' .. control.uid .. ') to ' .. parent_uid)

    -- Initialize default properties
    control.children = {}
    control.bounds = nil

    -- We add the child to its parent's children array
    local parent = find(parent_uid, root_node)
    if not parent then
        print('Control ' .. control.type .. ' has no parent with uid ' .. parent_uid)
        return
    end
    parent.children[#parent.children + 1] = control

    -- Notify it about existing
    ugui.send_message(control, {type = ugui.messages.create})

    -- We also need to invalidate the parent's layout
    invalidate_layout(parent_uid)
end

---Sends a message to a node
---@param node table A node
---@param msg table A message
ugui.send_message = function(node, msg)
    -- TODO: If user-provided one exists, it takes priority and user must invoke lower one manually
    -- if node.message then
    --     node.message(ugui, msg)
    --     return
    -- end

    return registry[node.type].message(ugui, node, msg)
end

---Hooks emulator functions and begins operating
---@param start function The function to be called upon starting
ugui.start = function(start)
    local last_input = nil
    local curr_input = nil

    start_size = wgui.info()
    wgui.resize(start_size.width + 200, start_size.height)

    -- Fill out root node bounds
    root_node.bounds = {x = start_size.width, y = 0, width = 200, height = start_size.height}

    start()

    emu.atupdatescreen(function()
        last_input = curr_input and deep_clone(curr_input) or input.get()
        curr_input = input.get()

        -- Relayout all invalidated controls
        for _, uid in pairs(layout_queue) do
            layout_node(find(uid, root_node), root_node.bounds)
        end
        layout_queue = {}

        -- Paint bounding boxes of all controls (debug)
        iterate(root_node, function(node)
            BreitbandGraphics.draw_rectangle(BreitbandGraphics.inflate_rectangle(node.bounds, -1), BreitbandGraphics.colors.red, 1)
        end)
    end)

    emu.atstop(function()
        wgui.resize(wgui.info().width - 200, wgui.info().height)
    end)
end

return ugui
