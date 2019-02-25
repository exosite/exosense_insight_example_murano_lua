-- listInsights

local insightsByGroup = {}
local emptyList = {}
setmetatable(emptyList, {['__type']='slice'})

local addNumber = {
  id = "addNumbers",
  name = "Add Numbers",
  description = "Sum one data point and a user-defined value",
  constants = {
    {
      name = "adder",
      type = "number"
    }
  },
  inlets = {
    {
      data_type = "NUMBER",
      data_unit = "",
      description = "One number"
    }
  },
  outlets = {
    data_type = "NUMBER",
    data_unit = ""
  }
}

local addSquareNumber = {
  id = "addSquareNumber",
  name = "Add Square Numbers",
  description = "Sum one data point with a squared user-defined value",
  constants = {
    {
      name = "numbertobesqured",
      type = "number"
    }
  },
  inlets = {
    {
      data_type = "NUMBER",
      data_unit = "",
      description = "One number"
    }
  },
  outlets = {
    data_type = "NUMBER",
    data_unit = ""
  }
}

insightsByGroup["80000001"] = {addSquareNumber, addNumber}

if request.body.group_id == '' then
  insightGroup = {addNumber} 
else
  insightGroup = insightsByGroup[request.body.group_id]
end

local requestedGroup = insightGroup
if insightGroup == nil then
  return {error = "group_id "..request.body.group_id.." does not exist"}
end
local count = table.getn(requestedGroup)
local total = table.getn(requestedGroup)

return {
  count = count,
  total = total,
  insights = requestedGroup
}
