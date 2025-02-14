-- Copyright (c) 2020-2021 shadmansaleh
-- MIT license, see LICENSE for more details.
local require = require('lualine_require').require
local Tab = require 'lualine.components.tabs.tab'
local M = require('lualine.component'):extend()
local highlight = require 'lualine.highlight'

local default_options = {
  max_length = 0,
  mode = 0,
  tabs_color = {
    active = nil,
    inactive = nil,
  },
}

local function get_hl(section, is_active)
  local suffix = is_active and '_normal' or '_inactive'
  local section_redirects = {
    lualine_x = 'lualine_c',
    lualine_y = 'lualine_b',
    lualine_z = 'lualine_a',
  }
  if section_redirects[section] then
    section = highlight.highlight_exists(section .. suffix) and section or section_redirects[section]
  end
  return section .. suffix
end

function M:init(options)
  M.super.init(self, options)
  default_options.tabs_color = {
    active = get_hl(options.self.section, true),
    inactive = get_hl(options.self.section, false),
  }
  self.options = vim.tbl_deep_extend('keep', self.options or {}, default_options)
  -- stylua: ignore
  self.highlights = {
    active = highlight.create_component_highlight_group(
      self.options.tabs_color.active,
      'tabs_active',
      self.options
    ),
    inactive = highlight.create_component_highlight_group(
      self.options.tabs_color.inactive,
      'tabs_active',
      self.options
    ),
  }
end

function M:update_status()
  local data = {}
  local tabs = {}
  for t = 1, vim.fn.tabpagenr '$' do
    tabs[#tabs + 1] = Tab { tabnr = t, options = self.options, highlights = self.highlights }
  end
  local current = vim.fn.tabpagenr()
  tabs[1].first = true
  tabs[#tabs].last = true
  if tabs[current] then
    tabs[current].current = true
  end
  if tabs[current - 1] then
    tabs[current - 1].beforecurrent = true
  end
  if tabs[current + 1] then
    tabs[current + 1].aftercurrent = true
  end

  local max_length = self.options.max_length
  if max_length == 0 then
    max_length = math.floor(vim.o.columns / 3)
  end
  local total_length
  for i, tab in pairs(tabs) do
    if tab.current then
      current = i
    end
  end
  local current_tab = tabs[current]
  if current_tab == nil then
    local t = Tab { tabnr = vim.fn.tabpagenr(), options = self.options, highlights = self.highlights }
    t.current = true
    t.last = true
    data[#data + 1] = t:render()
  else
    data[#data + 1] = current_tab:render()
    total_length = current_tab.len
    local i = 0
    local before, after
    while true do
      i = i + 1
      before = tabs[current - i]
      after = tabs[current + i]
      local rendered_before, rendered_after
      if before == nil and after == nil then
        break
      end
      if before then
        rendered_before = before:render()
        total_length = total_length + before.len
        if total_length > max_length then
          break
        end
        table.insert(data, 1, rendered_before)
      end
      if after then
        rendered_after = after:render()
        total_length = total_length + after.len
        if total_length > max_length then
          break
        end
        data[#data + 1] = rendered_after
      end
    end
    if total_length > max_length then
      if before ~= nil then
        before.ellipse = true
        before.first = true
        table.insert(data, 1, before:render())
      end
      if after ~= nil then
        after.ellipse = true
        after.last = true
        data[#data + 1] = after:render()
      end
    end
  end

  return table.concat(data)
end

vim.cmd [[
  function! LualineSwitchTab(tabnr, mouseclicks, mousebutton, modifiers)
    execute a:tabnr . "tabnext"
  endfunction
]]

return M
