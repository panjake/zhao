CREATE TABLE `user` (
  `user_id` int(11) NOT NULL AUTO_INCREMENT,
  `model` varchar(45) NOT NULL DEFAULT '' COMMENT '机种',
  `identifier` char(64) DEFAULT NULL COMMENT 'openudid',
  `identifier2` char(64) DEFAULT NULL COMMENT 'mac address',
  `last_update` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `create_time` timestamp NOT NULL DEFAULT '2010-01-01 00:00:00',
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `u_identifier` (`identifier`),
  KEY `i_mac` (`identifier2`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COMMENT='用户';



CREATE TABLE `campaign` (
  `campaign_id` int(11) NOT NULL AUTO_INCREMENT,
  `location` varchar(255) CHARACTER SET latin1 COLLATE latin1_general_ci NOT NULL DEFAULT '' ,
  `start_time` datetime NOT NULL DEFAULT '2010-01-01 00:00:00',
  `end_time` datetime NOT NULL DEFAULT '2110-12-31 23:59:59',
  `status` tinyint(4) NOT NULL DEFAULT '0' COMMENT '状态',
  `budget` decimal(11,4) NOT NULL DEFAULT '0.0000' COMMENT '预算',
  `price_a` decimal(4,2) DEFAULT '0.00',
  `price_b` decimal(4,2) DEFAULT '0.00',
  `confirm_url` varchar(255) DEFAULT NULL,
  `remark` text COMMENT '备注',
  `last_update` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `create_time` timestamp NOT NULL DEFAULT '2010-01-01 00:00:00',
  PRIMARY KEY (`campaign_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

CREATE TABLE `media` (
  `media_id` int(11) NOT NULL AUTO_INCREMENT,
  `is_approved` tinyint(1) NOT NULL DEFAULT '0' COMMENT '审查rank ',
  `callback` varchar(255) DEFAULT NULL COMMENT '成果通知URL',
  `last_update` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `create_time` timestamp NOT NULL DEFAULT '2010-01-01 00:00:00',
  PRIMARY KEY (`media_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ;


CREATE TABLE `achieve_to_forward` (
  `achieve_id` char(36) NOT NULL,
  `forward_time` timestamp NULL DEFAULT NULL,
  `attempted` tinyint(4) DEFAULT NULL COMMENT '通知失败次数',
  `message` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`achieve_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE `click_to_forward` (
  `click_id` char(36) NOT NULL,
  `forward_time` timestamp NULL DEFAULT NULL,
  `attempted` tinyint(4) DEFAULT NULL COMMENT '通知失败次数',
  `message` varchar(45) DEFAULT NULL,
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`click_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE `media_price` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `campaign_id` int(11) NOT NULL,
  `price_b` decimal(4,2) DEFAULT '0.00',
  `media_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `u_campaign_meida` (`campaign_id`,`media_id`) USING BTREE
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;







