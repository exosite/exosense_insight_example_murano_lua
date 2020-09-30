--

local Insight = {}

Insight.functions = {
  adder = {
    constants = {
      {
        name = "value",
        type = "number"
      },
    },
    description = "Adds a value to the signal",
    name = "adder",
    inlets = {
      {
        name = 'Signal',
        tag = 'x',
        primitive_type = 'NUMERIC',
        data_type = {'NUMBER', 'TEMPERATURE'},
      }
    },
    outlets = {
      primitive_type = 'NUMERIC',
    },
    fn = function(request)
      local dataIN = request.data
      local constants = request.args.constants
      local dataOUT = {}

      -- dataIN is a list of data points
      for _, dp in pairs(dataIN) do

        -- Each signal value in dataOUT should keep the incoming metadata
        dp.value = dp.value + constants.value

        table.insert(dataOUT, dp)
      end
      return {dataOUT}
    end
  },
  lowercase = {
    constants = {
      {
        name = "onlyFirst",
        description = "Only lowercase the first character or all characters",
        type = "boolean",
      },
    },
    description = "Lower case strings",
    name = "lowercase",
    inlets = {
      {
        name = 'Signal',
        tag = 'input',
        primitive_type = 'STRING',
      },
    },
    outlets = {
      {
        primitive_type = 'STRING',
      },
    },
    fn = function(request)
      local dataIN = request.data
      local constants = request.args.constants
      local dataOUT = {}
      for _, dp in pairs(dataIN) do
        local value = tostring(dp.value)
        if constants.onlyFirst then
        dp.value = string.lower(string.sub(value, 1, 1)) .. string.sub(value, 2)
        else
          dp.value = string.lower(value)
        end
      end
      return {dataOUT}
    end
  },
  histR = {
    name = 'Does history',
    description = 'really.',
    inlets = {
      {
        name = 'Numbers',
        tag = 'A',
        primitive_type = 'NUMERIC',
      }
    },
    outlets = {
      {
        primitive_type = 'NUMERIC',
      },
    },
    history = {
      limit = {value = 1},
    },
    fn = function(request)
      log.debug(to_json(request))
      return setmetatable({
        setmetatable({}, {['__type']='slice'})
      }, {['__type']='slice'})
    end
  },
  linearGain = {
    name = 'Linear Gain',
    description = 'really.',
    constants = {
      {
        name = "gain",
        type = "number"
      }, {
        name = "offset",
        type = "number"
      }
    },
    inlets = {
      {
        name = 'Numbers',
        tag = 'x',
        primitive_type = 'NUMERIC',
      }
    },
    outlets = {
      {
        primitive_type = 'NUMERIC',
      },
    },
    fn = function(request)
      local dataIN = request.data
      local constants = request.args.constants
      local dataOUT = {}

      -- dataIN is a list of data points
      for _, dp in pairs(dataIN) do

        -- Each signal value in dataOUT should keep the incoming metadata
        dp.value = dp.value * constants.gain + constants.offset

        table.insert(dataOUT, dp)
      end
      return {dataOUT}
    end
  },
  windowedRollingCount = {
    name = 'Rolling Aggregation by Count',
    description = 'Aggregate a number of past data points',
    constants = {
      {
        name = 'count',
        type = 'number',
        description = 'Number of past entries to combine',
        minimum = 1,
        default = 1,
        required = true,
      }, {
        name = 'aggregation',
        type = 'string',
        enum = {'min', 'max', 'mean', 'sum', 'count'},
        description = 'How to combine the values',
        required = true,
      }
    },
    history = {
      limit = { constant ='count' },
    },
    inlets = {
      {
        primitive_type = 'NUMERIC',
      }
    },
    outlets = {
      {
        primitive_type = 'NUMERIC',
      },
    },
    fn = function(request)
      local dataIN = request.data
      local constants = request.args.constants
      local dataOUT = {}
      local op = constants.aggregation
      local history = request.history

      local hisValues = {}
      for metricId, values in pairs(history) do
        if values[1].tags and values[1].tags.inlet and values[1].tags.inlet == "0" then
          hisValues = values
        end
      end

      local values = {}
      for _, dp in pairs(hisValues) do
        table.insert(values, dp.value)
      end

      local result = 0
      if op == "min" then
        result = math.min(unpack(values))
      elseif op == "max" then
        result = math.max(unpack(values))
      elseif op == "count" then
        result = table.getn(values)
      elseif op == "sum" or op == "mean" then
        -- sum
        for _,v in pairs(values) do
          result = result + v
        end

        -- mean
        if op == "mean" then
          result = result / table.getn(values)
        end
      end

      -- dataIN is a list of data points
      for _, dp in pairs(dataIN) do

        -- Each signal value in dataOUT should keep the incoming metadata
        dp.value = result

        table.insert(dataOUT, dp)
      end
      return {dataOUT}
    end
  }, 
}

function Insight.info()
  return {
    name = 'Simple Insight',
    group_id_required = false,
    description = 'Awesome if this works',
    wants_lifecycle_events = false,
  }
end

function Insight.listInsights(request)
  log.debug(to_json(request))
  local insights = {}
  for k,v in pairs(Insight.functions) do
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
  local found = Insight.functions[request.function_id]
  if found == nil then
    return nil, {
      name='Not Implemented',
      message = 'Function "' .. tostring(request.function_id) .. '" is not implemented'
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

function Insight.process(request)
  log.debug(to_json(request))
  local found = Insight.functions[request.args.function_id]
  if found == nil then
    return nil, {
      name='Not Implemented',
      message = 'Function "' .. tostring(request.args.function_id) .. '" is not implemented'
    }
  end
  return found.fn(request)
end

return Insight
