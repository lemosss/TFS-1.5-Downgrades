function onUpdateDatabase()
	print("> Updating database to version 30 (account coins balance)")
	db.query("ALTER TABLE `accounts` ADD COLUMN `coins` INT UNSIGNED NOT NULL DEFAULT 0 AFTER `creation`")
	return true
end
