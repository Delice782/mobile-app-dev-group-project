-- SQL to change default status for waste collectors
-- Run this in your database to make all new waste collectors active by default

-- Option 1: Alter table to set default status
ALTER TABLE `User` ALTER COLUMN `status` SET DEFAULT 'active';

-- Option 2: Update all existing pending waste collectors
UPDATE `User` SET `status` = 'active' WHERE `userRole` = 'Waste Collector' AND `status` = 'pending';

-- Option 3: Update all existing users to active (if you want everyone active)
UPDATE `User` SET `status` = 'active' WHERE `status` = 'pending';

-- Verify changes
SELECT COUNT(*) as active_collectors FROM `User` WHERE `userRole` = 'Waste Collector' AND `status` = 'active';
SELECT COUNT(*) as pending_collectors FROM `User` WHERE `userRole` = 'Waste Collector' AND `status` = 'pending';
