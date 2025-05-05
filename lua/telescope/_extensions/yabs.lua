local telescope = require('telescope')
local actions = require('telescope.actions')
local actionstate = require('telescope.actions.state')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
-- local sorters = require('telescope.sorters')
local themes = require('telescope.themes')
local Yabs = require('yabs')
local scopes = require('yabs.task').scopes

if not Yabs.did_conf then
    Yabs:load_config_file()
end

local function select_task(opts, scope)
    opts = themes.get_dropdown(opts)

    local tasks = Yabs:get_tasks(scope)
    tasks = vim.tbl_filter(function(task)
        return not task.disabled
    end, tasks)

    pickers.new(opts, {
        prompt_title = 'Select a task',
        finder = finders.new_table({
            results = tasks,
            entry_maker = function(entry)
                local display = entry.name
                local ordinal = entry.name
                local d = string.format('%s', entry.name)
                local entry_desc = nil
                local total_length = 72
                local padding = 20

                if entry.desc then
                    entry_desc = entry.desc

                    padding = total_length - #entry_desc - #entry.name
                    if type(entry.command) == 'string' then
                        padding = total_length - #entry_desc - #entry.name - #entry.command
                    end

                    entry_desc = string.rep(" ", padding) .. entry_desc

                    d = string.format('%s: %s', entry.name, entry_desc)
                    if type(entry.command) == 'string' then
                        d = string.format('%s: %s %s', entry.name, entry.command, entry_desc)
                    end
                end

                if type(entry.command) == 'string' then
                    display = string.format('%s: %s', entry.name, entry.command)
                    if entry.desc then
                        display = string.format('%s: %s %s', entry.name, entry.command, entry.desc)
                    end
                    ordinal = display .. entry.command
                end
                return {
                    value = entry.name,
                    display = d,
                    ordinal = ordinal,
                }
            end,
        }),
        -- sorter = sorters.get_fzy_sorter(),
        attach_mappings = function(prompt_bufnr)
            local source_session = function()
                actions.close(prompt_bufnr)
                local entry = actionstate.get_selected_entry(prompt_bufnr)
                if entry then
                    Yabs:run_task(entry.value, { scope = scope })
                end
            end

            actions.select_default:replace(source_session)
            return true
        end,
    }):find()
end

return telescope.register_extension({
    exports = {
        tasks = function(opts)
            select_task(opts, scopes.ALL)
        end,
        current_language_tasks = function(opts)
            select_task(opts, scopes.LOCAL)
        end,
        global_tasks = function(opts)
            select_task(opts, scopes.GLOBAL)
        end,
    },
})
