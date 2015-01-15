
-- -----------------------------------------------------
-- Table `sample`
-- -----------------------------------------------------
CREATE TABLE `sample` (
  `sample_id` INT NOT NULL,
  `raw_data_accession` VARCHAR(45) NOT NULL,
  `sample_accession` VARCHAR(45) NOT NULL,
  `sample_description` TINYTEXT NULL,
  `ncbi_taxid` INT NULL,
  `scientific_name` VARCHAR(45) NULL,
  `collected_by` VARCHAR(45) NULL,
  `source` NULL, -- ENUM('WTSI','UCL','Oxford') NULL,
  `collection_date` DATETIME NOT NULL,
  `location` VARCHAR(12) NOT NULL,
  `host_associated` TINYINT(1) NOT NULL,
  `specific_host` VARCHAR(45) NULL,
  `host_disease_status` NULL, -- ENUM('healthy','diseased','carriage') NULL,
  `host_isolation_source` VARCHAR(11) NOT NULL,
  `isolation_source` VARCHAR(10) NULL,
  `serovar` VARCHAR(45) NULL,
  `other_classification` VARCHAR(45) NULL,
  `strain` VARCHAR(45) NULL,
  `isolate` VARCHAR(45) NULL,
  `withdrawn` VARCHAR(45) NULL,
  `created_at` DATETIME NOT NULL,
  `updated_at` DATETIME NULL,
  `deleted_at` DATETIME NULL,
  PRIMARY KEY (`sample_id`),
  -- UNIQUE INDEX `sample_id_UNIQUE` (`sample_id` ASC),
  -- INDEX `fk_sample_location1_idx` (`location` ASC),
  -- INDEX `fk_sample_brenda1_idx` (`host_isolation_source` ASC),
  -- INDEX `fk_sample_taxonomy1_idx` (`ncbi_taxid` ASC),
  -- INDEX `fk_sample_envo1_idx` (`isolation_source` ASC),
  -- CONSTRAINT `fk_sample_location1`
    FOREIGN KEY (`location`)
    REFERENCES `gazetteer` (`gaz_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  -- CONSTRAINT `fk_sample_brenda1`
    FOREIGN KEY (`host_isolation_source`)
    REFERENCES `brenda` (`brenda_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  -- CONSTRAINT `fk_sample_taxonomy1`
    FOREIGN KEY (`ncbi_taxid`)
    REFERENCES `taxonomy` (`ncbi_taxid`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  -- CONSTRAINT `fk_sample_envo1`
    FOREIGN KEY (`isolation_source`)
    REFERENCES `envo` (`envo_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

-- -----------------------------------------------------
-- Triggers to mimic ENUMs
-- -----------------------------------------------------

CREATE TABLE sourceEnum (source text);

CREATE TRIGGER SourceTrigger BEFORE INSERT ON sample FOR EACH ROW
WHEN (SELECT COUNT(*) FROM sourceEnum WHERE  source = new.source) = 0 BEGIN
   SELECT RAISE(rollback, 'foreign-key violation: sample.source');
END;

INSERT INTO sourceEnum VALUES ('WTSI'), ('UCL'), ('Oxford');

CREATE TABLE hostDiseaseStatusEnum (host_disease_status text);

CREATE TRIGGER HDSTrigger BEFORE INSERT ON sample FOR EACH ROW
WHEN (SELECT COUNT(*) FROM hostDiseaseStatusEnum WHERE  host_disease_status = new.host_disease_status) = 0 BEGIN
   SELECT RAISE(rollback, 'foreign-key violation: sample.host_disease_status');
END;

INSERT INTO hostDiseaseStatusEnum VALUES ('healthy'), ('diseased'), ('carriage');


-- -----------------------------------------------------
-- Data for table `sample`
-- -----------------------------------------------------
INSERT INTO `sample` (`sample_id`, `raw_data_accession`, `sample_accession`, `sample_description`, `ncbi_taxid`, `scientific_name`, `collected_by`, `source`, `collection_date`, `location`, `host_associated`, `specific_host`, `host_disease_status`, `host_isolation_source`, `isolation_source`, `serovar`, `other_classification`, `strain`, `isolate`, `withdrawn`, `created_at`, `updated_at`, `deleted_at`) VALUES (1, 'data:1', 'sample:1', 'New sample', NULL, 'Homo sapiens', 'Tate JG', 'WTSI', '2015-01-10T14:30:00', 'GAZ:00444180', 1, 'Homo sapiens', 'healthy', 'BTO:0000645', NULL, 'serovar', NULL, 'strain', NULL, NULL, '20141202T16:55:00', '20141202T16:55:00', NULL);


-- -----------------------------------------------------
-- Table `run`
-- -----------------------------------------------------
CREATE TABLE `run` (
  `run_id` INT NOT NULL,
  `sample_id` INT NOT NULL,
  `sequencing_centre` VARCHAR(45) NULL,
  `ERR_accession_number` VARCHAR(45) NULL,
  `global_unique_name` VARCHAR(45) NULL,
  `qc_status` NULL, -- ENUM('pass','fail','unknown') NULL,
  `created_at` DATETIME NOT NULL,
  `updated_at` DATETIME NULL,
  `deleted_at` DATETIME NULL,
  -- INDEX `fk_run_sample1_idx` (`sample_id` ASC),
  PRIMARY KEY (`run_id`),
  -- CONSTRAINT `fk_run_sample1`
    FOREIGN KEY (`sample_id`)
    REFERENCES `sample` (`sample_id`)
    ON DELETE CASCADE
    ON UPDATE NO ACTION
);


-- -----------------------------------------------------
-- Triggers to mimic ENUMs
-- -----------------------------------------------------

CREATE TABLE qcStatusEnum (qc_status text);

CREATE TRIGGER QCStatusTrigger BEFORE INSERT ON run FOR EACH ROW
WHEN (SELECT COUNT(*) FROM qcStatusEnum WHERE  qc_status = new.qc_status) = 0 BEGIN
   SELECT RAISE(rollback, 'foreign-key violation: run.qc_status');
END;

INSERT INTO qcStatusEnum VALUES ('pass'), ('fail'), ('unknown');


-- -----------------------------------------------------
-- Table `file`
-- -----------------------------------------------------
CREATE TABLE `file` (
  `file_id` INT NOT NULL,
  `run_id` INT NOT NULL,
  `version` VARCHAR(45) NULL,
  `path` VARCHAR(45) NULL,
  `created_at` DATETIME NOT NULL,
  `updated_at` DATETIME NULL,
  `deleted_at` DATETIME NULL,
  PRIMARY KEY (`file_id`),
  -- INDEX `fk_file_run1_idx` (`run_id` ASC),
  -- CONSTRAINT `fk_file_run1`
    FOREIGN KEY (`run_id`)
    REFERENCES `run` (`run_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);


-- -----------------------------------------------------
-- Table `antimicrobial`
-- -----------------------------------------------------
CREATE TABLE `antimicrobial` (
  `name` VARCHAR(100) NOT NULL,
  `created_at` DATETIME NOT NULL,
  `updated_at` DATETIME NULL,
  `deleted_at` DATETIME NULL,
  PRIMARY KEY (`name`)
);


-- -----------------------------------------------------
-- Data for table `antimicrobial`
-- -----------------------------------------------------
INSERT INTO `antimicrobial` (`name`, `created_at`) VALUES ('am1', date('now')), ('am2',date('now'));


-- -----------------------------------------------------
-- Table `antimicrobial_resistance`
-- -----------------------------------------------------
CREATE TABLE `antimicrobial_resistance` (
  `sample_id` INT NOT NULL,
  `antimicrobial_name` VARCHAR(100) NOT NULL,
  `susceptibility` NOT NULL, -- ENUM('S','I','R') NOT NULL,
  `mic` VARCHAR(45) NOT NULL,
  `diagnostic_centre` VARCHAR(45) NULL,
  `created_at` DATETIME NOT NULL,
  `updated_at` DATETIME NULL,
  `deleted_at` DATETIME NULL,
  -- PRIMARY KEY (`antimicrobial_name`),
  -- INDEX `fk_antimicrobial_resistance_antimicrobial1_idx` (`antimicrobial_name` ASC),
  -- INDEX `fk_antimicrobial_resistance_Sample1_idx` (`sample_id` ASC),
  -- CONSTRAINT `fk_antimicrobial_resistance_antimicrobial1`
    FOREIGN KEY (`antimicrobial_name`)
    REFERENCES `antimicrobial` (`name`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  -- CONSTRAINT `fk_antimicrobial_resistance_Sample1`
    FOREIGN KEY (`sample_id`)
    REFERENCES `sample` (`sample_id`)
    ON DELETE CASCADE
    ON UPDATE NO ACTION
);

CREATE TABLE susceptibilityEnum (susceptibility text);

CREATE TRIGGER ResistanceTrigger BEFORE INSERT ON antimicrobial_resistance FOR EACH ROW
WHEN (SELECT COUNT(*) FROM susceptibilityEnum WHERE  susceptibility = new.susceptibility) = 0 BEGIN
   SELECT RAISE(rollback, 'foreign-key violation: antimicrobial_resistance.susceptibility');
END;

INSERT INTO susceptibilityEnum VALUES ('S'), ('I'), ('R');

-- -----------------------------------------------------
-- Data for table `antimicrobial_resistance`
-- -----------------------------------------------------
INSERT INTO `antimicrobial_resistance` (`sample_id`, `antimicrobial_name`, `susceptibility`, `mic`, `diagnostic_centre`, `created_at`)
  VALUES (1,'am1','S',50,'WTSI',date('now'));


-- -----------------------------------------------------
-- Table `gazetteer`
-- -----------------------------------------------------
CREATE TABLE `gazetteer` (
  `gaz_id` VARCHAR(12) NOT NULL,
  `description` VARCHAR(45) NULL,
  PRIMARY KEY (`gaz_id`)
);

-- -----------------------------------------------------
-- Data for table `gazetteer`
-- -----------------------------------------------------
INSERT INTO `gazetteer` (`gaz_id`, `description`) VALUES ('GAZ:00444180', 'Hinxton');


-- -----------------------------------------------------
-- Table `brenda`
-- -----------------------------------------------------
CREATE TABLE `brenda` (
  `brenda_id` VARCHAR(11) NOT NULL,
  `description` VARCHAR(45) NULL,
  PRIMARY KEY (`brenda_id`)
);


-- -----------------------------------------------------
-- Data for table `brenda`
-- -----------------------------------------------------
INSERT INTO `brenda` (`brenda_id`, `description`) VALUES ('BTO:0000645', 'Lung');


-- -----------------------------------------------------
-- Table `taxonomy`
-- -----------------------------------------------------
CREATE TABLE `taxonomy` (
  `ncbi_taxid` INT NOT NULL,
  `scientific_name` VARCHAR(45) NULL,
  PRIMARY KEY (`ncbi_taxid`)
);


-- -----------------------------------------------------
-- Data for table `taxonomy`
-- -----------------------------------------------------
INSERT INTO `taxonomy` (`ncbi_taxid`,`scientific_name`) VALUES (9606, 'Homo sapiens');


-- -----------------------------------------------------
-- Table `envo`
-- -----------------------------------------------------
CREATE TABLE `envo` (
  `envo_id` VARCHAR(10) NOT NULL,
  `description` VARCHAR(45) NULL,
  PRIMARY KEY (`envo_id`)
);


-- -----------------------------------------------------
-- Data for table `envo`
-- -----------------------------------------------------
INSERT INTO `envo` (`envo_id`, `description`) VALUES ('ENVO:00002148', 'coarse beach sand');


-- -----------------------------------------------------
-- Table `external_resources`
-- -----------------------------------------------------
CREATE TABLE `external_resources` (
  `resource_id` INT NOT NULL,
  `source` VARCHAR(45) NULL,
  `retrieved_at` DATETIME NOT NULL,
  `checksum` VARCHAR(45) NOT NULL,
  `version` VARCHAR(45) NULL,
  PRIMARY KEY (`resource_id`)
);


