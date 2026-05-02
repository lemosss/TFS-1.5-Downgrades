function onUpdateDatabase()
	print("> Updating database to version 30 (player shop history)")
	db.query([[
		CREATE TABLE IF NOT EXISTS `playershop_history` (
			`id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
			`seller_guid`  INT UNSIGNED NOT NULL,
			`buyer_name`   VARCHAR(40)  NOT NULL,
			`item_id`      SMALLINT UNSIGNED NOT NULL,
			`item_name`    VARCHAR(120) NOT NULL,
			`item_count`   SMALLINT UNSIGNED NOT NULL DEFAULT 1,
			`price_total`  BIGINT UNSIGNED NOT NULL DEFAULT 0,
			`ts`           INT UNSIGNED NOT NULL,
			PRIMARY KEY (`id`),
			KEY `idx_seller_ts` (`seller_guid`, `ts`)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	]])
	return true
end
