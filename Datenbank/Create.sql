CREATE TABLE `Users`(
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `Login` VARCHAR(255) NOT NULL,
    `last_name` VARCHAR(255) NOT NULL,
    `first_name` VARCHAR(255) NOT NULL,
    `email` VARCHAR(255) NOT NULL,
    `salt` CHAR(60) NOT NULL,
    `hash` CHAR(128) NOT NULL,
    `role` SMALLINT UNSIGNED NOT NULL,
    `forceResetPass` SMALLINT UNSIGNED NOT NULL DEFAULT 1
);
ALTER TABLE
    `Users` ADD UNIQUE `users_last_name_first_name_email_unique`(`last_name`, `first_name`, `email`);
ALTER TABLE
    `Users` ADD UNIQUE `users_login_unique`(`Login`);
CREATE TABLE `Klienten`(
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `last_name` VARCHAR(255) NOT NULL,
    `first_name` VARCHAR(255) NOT NULL
);
ALTER TABLE
    `Klienten` ADD UNIQUE `klienten_last_name_first_name_unique`(`last_name`, `first_name`);
CREATE TABLE `Betreuungen`(
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `Betreuer` BIGINT UNSIGNED NOT NULL,
    `Klient` BIGINT UNSIGNED NOT NULL,
    `Vereinbarung` BIGINT UNSIGNED NOT NULL
);
ALTER TABLE
    `Betreuungen` ADD UNIQUE `betreuungen_Betreuer_klient_unique`(`Betreuer`, `Klient`);
CREATE TABLE `Rollen`(
    `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `Rolle` VARCHAR(255) NOT NULL
);
ALTER TABLE
    `Rollen` ADD UNIQUE `rollen_rolle_unique`(`Rolle`);
CREATE TABLE `Dokumente`(
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `Name` VARCHAR(255) NOT NULL,
    `Datei` VARCHAR(255) NOT NULL,
    `Klient` BIGINT UNSIGNED NOT NULL,
    `Gruppe` BIGINT UNSIGNED NOT NULL,
    `Kategorie` BIGINT UNSIGNED NOT NULL,
    `Author` BIGINT UNSIGNED NOT NULL,
    `Vorlage` BIGINT UNSIGNED NULL
);
ALTER TABLE
    `Dokumente` ADD UNIQUE `dokumente_name_klient_gruppe_kategorie_unique`(
        `Name`,
        `Klient`,
        `Gruppe`,
        `Kategorie`
    );
ALTER TABLE
    `Dokumente` ADD UNIQUE `dokumente_datei_unique`(`Datei`);
CREATE TABLE `Kategorie`(
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `Name` VARCHAR(255) NOT NULL
);
ALTER TABLE
    `Kategorie` ADD UNIQUE `kategorie_name_unique`(`Name`);
CREATE TABLE `Gruppe`(
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `Name` VARCHAR(255) NOT NULL
);
ALTER TABLE
    `Gruppe` ADD UNIQUE `gruppe_name_unique`(`Name`);
CREATE TABLE `RechteGruppe`(
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `Rolle` SMALLINT UNSIGNED NOT NULL,
    `Gruppe` BIGINT UNSIGNED NOT NULL
);
ALTER TABLE
    `RechteGruppe` ADD UNIQUE `rechtegruppe_rolle_gruppe_unique`(`Rolle`, `Gruppe`);
CREATE TABLE `RechteKategorie`(
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `Rolle` SMALLINT UNSIGNED NOT NULL,
    `Kategorie` BIGINT UNSIGNED NOT NULL
);
ALTER TABLE
    `RechteKategorie` ADD UNIQUE `rechtekategorie_rolle_kategorie_unique`(`Rolle`, `Kategorie`);
CREATE TABLE `Vorlagen`(
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `Name` VARCHAR(255) NOT NULL,
    `Datei` VARCHAR(255) NOT NULL
);
ALTER TABLE
    `Vorlagen` ADD UNIQUE `vorlagen_name_unique`(`Name`);
CREATE TABLE `Variablen`(
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `Vorlage` BIGINT UNSIGNED NOT NULL,
    `Name` VARCHAR(255) NOT NULL
);
ALTER TABLE
    `Variablen` ADD UNIQUE `variablen_vorlage_name_unique`(`Vorlage`, `Name`);
CREATE TABLE `VariablenWerte`(
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `Variable` BIGINT UNSIGNED NOT NULL,
    `Dokument` BIGINT UNSIGNED NOT NULL,
    `Wert` VARCHAR(255) NOT NULL
);
ALTER TABLE
    `VariablenWerte` ADD UNIQUE `variablenwerte_variable_dokument_unique`(`Variable`, `Dokument`);
CREATE TABLE `Zeiterfassung`(
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `Betreuung` BIGINT UNSIGNED NOT NULL,
    `Taetigkeit` BIGINT UNSIGNED NOT NULL,
    `von` DATETIME NOT NULL,
    `bis` DATETIME NOT NULL,
	`Beschreibung` VARCHAR DEFAULT ""
);
CREATE TABLE `Taetigkeit`(
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `Name` VARCHAR(255) NOT NULL,
    `Abrechenbar` BOOLEAN NOT NULL
);
CREATE TABLE `Misc`(
    `name` VARCHAR(255) NOT NULL,
    `value` VARCHAR(255) NOT NULL,
    PRIMARY KEY(`name`)
);
ALTER TABLE
    `RechteGruppe` ADD CONSTRAINT `rechtegruppe_gruppe_foreign` FOREIGN KEY(`Gruppe`) REFERENCES `Gruppe`(`id`);
ALTER TABLE
    `Dokumente` ADD CONSTRAINT `dokumente_kategorie_foreign` FOREIGN KEY(`Kategorie`) REFERENCES `Kategorie`(`id`);
ALTER TABLE
    `Dokumente` ADD CONSTRAINT `dokumente_vorlage_foreign` FOREIGN KEY(`Vorlage`) REFERENCES `Vorlagen`(`id`);
ALTER TABLE
    `Dokumente` ADD CONSTRAINT `dokumente_klient_foreign` FOREIGN KEY(`Klient`) REFERENCES `Klienten`(`id`);
ALTER TABLE
    `Users` ADD CONSTRAINT `users_role_foreign` FOREIGN KEY(`role`) REFERENCES `Rollen`(`id`);
ALTER TABLE
    `Zeiterfassung` ADD CONSTRAINT `zeiterfassung_betreuung_foreign` FOREIGN KEY(`Betreuung`) REFERENCES `Betreuungen`(`id`);
ALTER TABLE
    `RechteKategorie` ADD CONSTRAINT `rechtekategorie_kategorie_foreign` FOREIGN KEY(`Kategorie`) REFERENCES `Kategorie`(`id`);
ALTER TABLE
    `RechteKategorie` ADD CONSTRAINT `rechtekategorie_rolle_foreign` FOREIGN KEY(`Rolle`) REFERENCES `Rollen`(`id`);
ALTER TABLE
    `RechteGruppe` ADD CONSTRAINT `rechtegruppe_rolle_foreign` FOREIGN KEY(`Rolle`) REFERENCES `Rollen`(`id`);
ALTER TABLE
    `Zeiterfassung` ADD CONSTRAINT `zeiterfassung_taetigkeit_foreign` FOREIGN KEY(`Taetigkeit`) REFERENCES `Taetigkeit`(`id`);
ALTER TABLE
    `VariablenWerte` ADD CONSTRAINT `variablenwerte_dokument_foreign` FOREIGN KEY(`Dokument`) REFERENCES `Dokumente`(`id`);
ALTER TABLE
    `Dokumente` ADD CONSTRAINT `dokumente_gruppe_foreign` FOREIGN KEY(`Gruppe`) REFERENCES `Gruppe`(`id`);
ALTER TABLE
    `Dokumente` ADD CONSTRAINT `dokumente_author_foreign` FOREIGN KEY(`Author`) REFERENCES `Users`(`id`);
ALTER TABLE
    `Betreuungen` ADD CONSTRAINT `betreuungen_vereinbarung_foreign` FOREIGN KEY(`Vereinbarung`) REFERENCES `Dokumente`(`id`);
ALTER TABLE
    `Variablen` ADD CONSTRAINT `variablen_vorlage_foreign` FOREIGN KEY(`Vorlage`) REFERENCES `Vorlagen`(`id`);
ALTER TABLE
    `Betreuungen` ADD CONSTRAINT `betreuungen_klient_foreign` FOREIGN KEY(`Klient`) REFERENCES `Klienten`(`id`);
ALTER TABLE
    `VariablenWerte` ADD CONSTRAINT `variablenwerte_variable_foreign` FOREIGN KEY(`Variable`) REFERENCES `Variablen`(`id`);
ALTER TABLE
    `Betreuungen` ADD CONSTRAINT `betreuungen_Betreuer_foreign` FOREIGN KEY(`Betreuer`) REFERENCES `Users`(`id`);