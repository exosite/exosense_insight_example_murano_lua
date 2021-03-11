---
-- FIXME: Explain what this file is and why they should not edit it.

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
    group_id_required = false,
    description = 'Someone forgot to configure their module',
    wants_lifecycle_events = false,
  }

  for k,v in pairs(info) do
    final[k] = v
  end

  local overrides = {
    group_id_required = false,
    wants_lifecycle_events = false,
  }

  for k,v in pairs(overrides) do
    final[k] = v
  end

  Insight._meta_info = final
end


function Insight.add(function_id, function_details)
  Insight._functions[function_id] = function_details

  -- OR? Insight.add_group(function_id, '*', function_details)
end

-- function Insight.add_group(function_id, group_id, function_details)
-- end

-- --------------------------------------------------------------------------------------------------
-- These functions are used by the REST Interface.


function Insight.info()
  return Insight._meta_info
end

function Insight.listInsights(request)
  log.debug(to_json(request))
  local insights = {}
  for k,v in pairs(Insight._functions) do
    v.fn = nil
    v.id = k
    table.insert(insights, v)
  end
  return {
    total = #insights,
    count = #insights,
    insights = insights,
  }
end

function Insight.infoInsight(request)
  log.debug(to_json(request))
  local fin = (request.parameters or {}).fn
  local found = Insight._functions[fin]
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
  log.debug(to_json(request))
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
  for _,v in pairs({'A', 'B', 'C', 'D', 'E', '0', '1', '2', '3', '4'}) do
    table.insert(metric_names, lid .. '_' .. v)
  end
  local query = {
    mode = 'split',
    epoch = 'u',
    limit = 1,
    metrics = metric_names,
    relative_start = '-999w',
  }
  local result = Tsdb.query(query)
  local ret = {}
  for k,v in pairs(result.values or {}) do
    local n = string.gsub(k, '_(.)$', '%1')
    local vv = (v[1] or {})[2]
    if vv then
      ret[n] = vv
    end
  end
  return ret
end

-- This handles single inlet, multiple outlet insight functions.
local function default_raw_fn(fn, request)
  local dataIN = request.data
  local constants = request.args.constants
  local dataOUT = {}

  local prior = query_prior(request.id or '_')

  -- dataIN is a list of data points
  for _, dp in pairs(dataIN) do

    -- gather multiple return values into separate outlets.
    local outlets = { fn(dp.value, constants, prior) }
    -- Each signal value in dataOUT should keep the incoming metadata
    for k,v in pairs(outlets) do
      local n = deepcopy(dp)
      n.value = v
      outlets[k] = n
    end

    table.insert(dataOUT, outlets)
  end

  dataOUT = transpose(dataOUT)

  return setmetatable({dataOUT}, {['__type']='slice'})
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

  Tsdb.multiWrite({datapoints=towrite})
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
      ow[lid .. '_' .. tostring(idx)] = sd.value
      -- Just overwrite multiples. should all be same anyhow.
    end
    table.insert(towrite, ow)
  end

  Tsdb.multiWrite({datapoints=towrite})
end

function Insight.process(request)
  log.debug(to_json(request))
  -- Maybe group_id support.
  local fid = (request.args or {}).function_id
  local found = Insight._functions[fid]
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