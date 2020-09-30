std = 'lua51'
globals = {
	-- Murano Globals for all scripts
	'Asset',
	'Bulknotify',
	'Config',
	'Content',
	'Device',
	'Email',
	'Http',
	'Keystore',
	'Postgresql',
	'Renderer',
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
