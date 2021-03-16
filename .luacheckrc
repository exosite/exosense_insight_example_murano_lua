std = 'lua51'
globals = {
	-- Murano Globals for all scripts
	'Asset',
	'Config',
	'Content',
	'Device',
	'Email',
	'Http',
	'Keystore',
	'Postgresql',
	'Scripts',
	'Spms',
	'table',
	'Timer',
	'Transformer',
	'Tsdb',
	'Twilio',
	'Websocket',
	'context',
	'from_json',
	'json',
	'log',
	'murano',
	'os.now',
	'to_json',
	-- Included modules (which are visible from all scripts)
}
exclude_files = {
	'modules/src/*',
	'modules/date.lua',
}
