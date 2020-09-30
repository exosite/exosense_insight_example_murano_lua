--#ENDPOINT POST /insights
-- luacheck: globals response request
-- listInsights

return require('insight').listInsights(request)
