--#EVENT config status
-- this will return a default json payload that passes healthcheck endpoint validation

local JSONreply = {}
JSONreply.status = "online"
JSONreply.disabled = false
return JSONreply
