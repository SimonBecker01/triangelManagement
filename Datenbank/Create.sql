CREATE TABLE `Users`(
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `Login` VARCHAR(255) NOT NULL,
    `Nachname` VARCHAR(255) NOT NULL,
    `Vorname` VARCHAR(255) NOT NULL,
    `Email` VARCHAR(255) NOT NULL,
    `salt` CHAR(60) NOT NULL,
    `hash` CHAR(128) NOT NULL,
    `Rolle` SMALLINT UNSIGNED NOT NULL,
    `forceResetPass` BOOLEAN NOT NULL DEFAULT 1
);
ALTER TABLE
    `Users` ADD UNIQUE `users_nachname_vorname_email_unique`(`Nachname`, `Vorname`, `Email`);
ALTER TABLE
    `Users` ADD UNIQUE `users_login_unique`(`Login`);
CREATE TABLE `Klienten`(
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `Nachname` VARCHAR(255) NOT NULL,
    `Vorname` VARCHAR(255) NOT NULL
);
ALTER TABLE
    `Klienten` ADD UNIQUE `klienten_nachname_vorname_unique`(`Nachname`, `Vorname`);
CREATE TABLE `Betreuungen`(
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `Betreuer` BIGINT UNSIGNED NOT NULL,
    `Klient` BIGINT UNSIGNED NOT NULL,
    `GueltigVon` DATE NULL,
    `GueltigBis` DATE NULL,
    `Wochenstunden` BIGINT NULL,
    `Stundensatz` BIGINT NULL
);
ALTER TABLE
    `Betreuungen` ADD UNIQUE `betreuungen_betreuer_klient_gueltigbis_gueltigvon_unique`(
        `Betreuer`,
        `Klient`,
        `GueltigBis`,
        `GueltigVon`
    );
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
    `Autor` BIGINT UNSIGNED NOT NULL
);
ALTER TABLE
    `Dokumente` ADD UNIQUE `dokumente_name_klient_gruppe_unique`(`Name`, `Klient`, `Gruppe`);
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
CREATE TABLE `Zeiterfassung`(
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `Betreuung` BIGINT UNSIGNED NOT NULL,
    `Taetigkeit` BIGINT UNSIGNED NOT NULL,
    `Von` DATETIME NOT NULL,
    `Bis` DATETIME NOT NULL,
    `Beschreibung` VARCHAR(255) NOT NULL DEFAULT ''
);
CREATE TABLE `Taetigkeit`(
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `Name` VARCHAR(255) NOT NULL,
    `Abrechenbar` BOOLEAN NOT NULL,
    `Buchbar` BOOLEAN NOT NULL
);
ALTER TABLE
    `Taetigkeit` ADD UNIQUE `taetigkeit_name_unique`(`Name`);
CREATE TABLE `Kategorienzuordnung`(
    `Kategorie` BIGINT NOT NULL,
    `Dokument` BIGINT NOT NULL,
    PRIMARY KEY(`Kategorie`, `Dokument`)
);
CREATE TABLE `Systemeinstellungen`(
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `Name` VARCHAR(255) NOT NULL,
    `Wert` BIGINT NOT NULL
);
ALTER TABLE
    `Systemeinstellungen` ADD UNIQUE `systemeinstellungen_name_unique`(`Name`);
ALTER TABLE
    `RechteGruppe` ADD CONSTRAINT `rechtegruppe_gruppe_foreign` FOREIGN KEY(`Gruppe`) REFERENCES `Gruppe`(`id`) ON DELETE CASCADE;
ALTER TABLE
    `Kategorienzuordnung` ADD CONSTRAINT `kategorienzuordnung_kategorie_foreign` FOREIGN KEY(`Kategorie`) REFERENCES `Kategorie`(`id`) ON DELETE CASCADE;
ALTER TABLE
    `Dokumente` ADD CONSTRAINT `dokumente_klient_foreign` FOREIGN KEY(`Klient`) REFERENCES `Klienten`(`id`);
ALTER TABLE
    `Users` ADD CONSTRAINT `users_rolle_foreign` FOREIGN KEY(`Rolle`) REFERENCES `Rollen`(`id`);
ALTER TABLE
    `Zeiterfassung` ADD CONSTRAINT `zeiterfassung_betreuung_foreign` FOREIGN KEY(`Betreuung`) REFERENCES `Betreuungen`(`id`);
ALTER TABLE
    `RechteKategorie` ADD CONSTRAINT `rechtekategorie_kategorie_foreign` FOREIGN KEY(`Kategorie`) REFERENCES `Kategorie`(`id`) ON DELETE CASCADE;
ALTER TABLE
    `RechteKategorie` ADD CONSTRAINT `rechtekategorie_rolle_foreign` FOREIGN KEY(`Rolle`) REFERENCES `Rollen`(`id`) ON DELETE CASCADE;
ALTER TABLE
    `RechteGruppe` ADD CONSTRAINT `rechtegruppe_rolle_foreign` FOREIGN KEY(`Rolle`) REFERENCES `Rollen`(`id`) ON DELETE CASCADE;
ALTER TABLE
    `Zeiterfassung` ADD CONSTRAINT `zeiterfassung_taetigkeit_foreign` FOREIGN KEY(`Taetigkeit`) REFERENCES `Taetigkeit`(`id`);
ALTER TABLE
    `Dokumente` ADD CONSTRAINT `dokumente_gruppe_foreign` FOREIGN KEY(`Gruppe`) REFERENCES `Gruppe`(`id`);
ALTER TABLE
    `Dokumente` ADD CONSTRAINT `dokumente_autor_foreign` FOREIGN KEY(`Autor`) REFERENCES `Users`(`id`);
ALTER TABLE
    `Betreuungen` ADD CONSTRAINT `betreuungen_klient_foreign` FOREIGN KEY(`Klient`) REFERENCES `Klienten`(`id`) ON DELETE CASCADE;
ALTER TABLE
    `Betreuungen` ADD CONSTRAINT `betreuungen_betreuer_foreign` FOREIGN KEY(`Betreuer`) REFERENCES `Users`(`id`) ON DELETE CASCADE;
ALTER TABLE
    `Kategorienzuordnung` ADD CONSTRAINT `kategorienzuordnung_dokument_foreign` FOREIGN KEY(`Dokument`) REFERENCES `Dokumente`(`id`) ON DELETE CASCADE;