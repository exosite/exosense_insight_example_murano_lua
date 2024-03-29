---
-- This is all of the deep a gory details of making an Insight Module work.
-- Feel free to look around.
-- Avoid making changes here unless you know what you're up to. (or just willing to take the risks)

local Insight = {}

Insight._functions = {}

Insight._meta_info = {
    name = 'Unnamed Insight',
    group_id_required = false,
    description = 'Someone forgot to configure their module',
    wants_lifecycle_events = false,
}

-- --------------------------------------------------------------------------------------------------
-- These functions and constants are used to add Insight Module Functions. (and module meta)

Insight.primitives = {
  NUMERIC = 'NUMERIC',
  STRING = 'STRING',
  BOOLEAN = 'BOOLEAN',
  JSON = 'JSON',
}

Insight.constant_types = {
  STRING = 'string',
  NUMBER = 'number',
  BOOLEAN = 'boolean',
  DURATION_MODIFIER = 'duration_modifier',
}

function Insight.meta(info)
  local final = {
    name = 'Unnamed Insight',
    description = 'Someone forgot to configure their module',
    group_id_required = false,
    wants_lifecycle_events = false,
    author = "Your Name Here",
    author_contact = "your@email.address.here",
  }

  for k,v in pairs(info) do
    final[k] = v
  end

  local overrides = {
    wants_lifecycle_events = false,
  }

  for k,v in pairs(overrides) do
    final[k] = v
  end

  Insight._meta_info = final
end


function Insight.add(function_id, function_details)
  Insight.add_group(function_id, '*', function_details)
end

function Insight.add_group(function_id, group_id, function_details)
  -- oh lua; make sure arrays are arrays for to_json
  for _,k in pairs({'constants', 'inlets', 'outlets'}) do
    if function_details[k] then
      setmetatable(function_details[k], {['__type']='slice'})
    else
      function_details[k] = setmetatable({}, {['__type']='slice'})
    end
  end

  if Insight._functions[group_id] == nil then
    Insight._functions[group_id] = {}
  end

  Insight._functions[group_id][function_id] = function_details

  if group_id ~= '*' and not (Insight._meta_info or {}).group_id_required then
    Insight._meta_info.group_id_required = true
  end
end

-- --------------------------------------------------------------------------------------------------
-- These functions are used by the REST Interface.


function Insight.info()
  return Insight._meta_info
end

function Insight.listInsights(request)
  -- log.debug(to_json(request))
  local insights = {}
  for k,v in pairs(Insight._functions['*']) do
    v.fn = nil
    v.id = k
    table.insert(insights, v)
  end
  local gid = (request.body or {}).group_id
  if gid and Insight._functions[gid] then
    for k,v in pairs(Insight._functions[gid]) do
      v.fn = nil
      v.id = k
      table.insert(insights, v)
    end
  end
  return {
    total = #insights,
    count = #insights,
    insights = insights,
  }
end

function Insight.infoInsight(request)
  -- log.debug(to_json(request))
  local fin = (request.parameters or {}).fn
  local found = Insight._functions['*'][fin]
  if found == nil then
    return nil, {
      name='Not Implemented',
      message = 'Function "' .. tostring(fin) .. '" is not implemented'
    }
  end
  found.id = request.function_id
  found.fn = nil
  return found
end

function Insight.lifecycle(request)
  -- log.debug(to_json(request))
  return {}
end

local function deepcopy(tbl)
  local new={}
  for k,v in pairs(tbl) do
    if type(v) == 'table' then
      new[k] = deepcopy(v)
    else
      new[k] = v
    end
  end
  return new
end

local function transpose(m)
  local rotated = {}
  for c, m_1_c in ipairs(m[1]) do
     local col = {m_1_c}
     for r = 2, #m do
        col[r] = m[r][c]
     end
     table.insert(rotated, col)
  end
  return rotated
end

local function query_prior(id)
  local metric_names = {}
  local lid = string.gsub(id, '[^%w_]', '')
  for _,v in pairs({'A', 'B', 'C', 'D', 'E', '1', '2', '3', '4', '5'}) do
    table.insert(metric_names, lid .. '_' .. v)
  end
  local query = {
    mode = 'split',
    epoch = 'u',
    limit = 4,
    metrics = metric_names,
    relative_start = '-999w',
  }
  local result = Tsdb.query(query)
  local ret = {
    prior = {}
  }
  for k,v in pairs(result.values or {}) do
    local n = string.gsub(k, '^(.*)_(.)$', '%2')
    local vv = (v[1] or {})[2]
    if vv then
      ret[n] = vv
    end
    ret.prior[n] = v
  end

  -- Also map 1..5 from "1".."5", making it easier for developers.
  for i,k in ipairs({'1', '2', '3', '4', '5'}) do
    ret[i] = ret[k]
  end
  return ret
end

local function save_state(id, state)
  local json = to_json(state)
  local lid = string.gsub(id, '[^%w_]', '') .. '_state'
  Tsdb.write({
    metrics = {
      [lid] = json
    }
  })
end

local function retrive_state(id)
  local lid = string.gsub(id, '[^%w_]', '') .. '_state'
  local query = {
    mode = 'split',
    epoch = 'u',
    limit = 1,
    metrics = {lid},
    relative_start = '-999w',
  }
  local result = Tsdb.query(query)
  local json = (((result.values or {})[lid] or {})[1] or {})[2] or "{}"
  local tbl = from_json(json)
  return tbl
end

-- This handles single inlet, multiple outlet insight functions.
local function default_raw_fn(fn, request)
  local dataIN = request.data
  local constants = request.args.constants
  local dataOUT = {}

  local rid = request.id or '_'
  local prior = query_prior(rid)
  prior._f = {
    save = function(state)
      return save_state(rid, state)
    end,
    restore = function()
      return retrive_state(rid)
    end
  }

  -- dataIN is a list of data points
  for _, dp in pairs(dataIN) do

    -- gather multiple return values into separate outlets.
    local status, outlets_or_error = pcall(function()
      return { fn(dp.value, constants, prior) }
    end)
    if status then
      local outlets = outlets_or_error

      -- Each signal value in dataOUT should keep the incoming metadata
      for k,v in pairs(outlets) do
        if json.is_null(v) then
          outlets[k] = json.null
        else
          local n = deepcopy(dp)
          n.value = v
          outlets[k] = n
        end
      end

      table.insert(dataOUT, outlets)
    else
      log.error('FUNCTION EXEC ERROR', (request.args or {}).function_id, outlets_or_error)
      table.insert(dataOUT, {})
    end
  end

  dataOUT = transpose(dataOUT)

  for _,t in pairs(dataOUT) do
    setmetatable(t, {['__type']='slice'})
    for i,v in pairs(t) do
      if json.is_null(v) then
        table.remove(t, i)
      end
    end
  end
  return setmetatable(dataOUT, {['__type']='slice'})
end

local function save_inlets(id, data)
  local towrite = {}
  local lid = string.gsub(id, '[^%w_]', '')
  for _,sd in pairs(data) do
    local tn = (sd.tags or {}).inlet or 'A'
    table.insert(towrite, {
      metrics = {
        [lid .. '_' .. tn] = sd.value,
      },
      ts = sd.ts,
    })
  end

  if next(towrite) ~= nil then
    Tsdb.multiWrite({datapoints=towrite})
  end
end

local function save_outlets(id, outlets)
  local towrite = {}
  local lid = string.gsub(id, '[^%w_]', '')
  -- On each outlet
  for idx,outlet in ipairs(outlets) do
    local ow = {
      metrics = { },
      ts = 0,
    }
    for _,sd in pairs(outlet) do
      ow.ts = sd.ts
      ow.metrics[lid .. '_' .. tostring(idx)] = type(sd.value) == 'table' and json.stringify(sd.value) or sd.value
      -- Just overwrite multiples. should all be same anyhow.
    end
    if next(ow.metrics) ~= nil then
      table.insert(towrite, ow)
    end
  end

  if next(towrite) ~= nil then
    Tsdb.multiWrite({datapoints=towrite})
  end
end

function Insight.process(request)
  -- log.debug(to_json(request))
  -- Maybe group_id support.
  local gid = (request.args or {}).group_id or '*'
  local fid = (request.args or {}).function_id
  local found = Insight._functions[gid][fid]
  if found == nil then
    return nil, {
      name='Not Implemented',
      message = 'Function "' .. tostring(fid) .. '" is not implemented'
    }
  end

  save_inlets(request.id or '_', request.data or {})

  local results = setmetatable({
    setmetatable({}, {['__type']='slice'})
  }, {['__type']='slice'})

  if found.raw_fn ~= nil then
    results = found.raw_fn(request)
  end

  if found.fn ~= nil then
    results = default_raw_fn(found.fn, request)
  end

  save_outlets(request.id or '_', results or {})

  return results
end

return Insight
