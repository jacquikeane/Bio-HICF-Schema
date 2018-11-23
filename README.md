# Bio-HICF-Schema
APIs for the HICF databases

[![Build Status](https://travis-ci.org/sanger-pathogens/Bio-HICF-Schema.svg?branch=master)](https://travis-ci.org/sanger-pathogens/Bio-HICF-Schema)    
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-brightgreen.svg)](https://github.com/sanger-pathogens/Bio-HICF-Schema/blob/master/license_file)   

## Contents
  * [Introduction](#introduction)
  * [Installation](#installation)
    * [Required dependencies](#required-dependencies)
    * [From Source](#from-source)
    * [Running the tests](#running-the-tests)
  * [Usage](#usage)
    * [add\_midas\_user](#add_midas_user)
    * [add\_multiple\_midas\_users](#add_multiple_midas_users)
    * [build\_schemata\.pl](#build_schematapl)
    * [delete\_midas\_user](#delete_midas_user)
    * [geocode\_samples\_cron](#geocode_samples_cron)
    * [load\_antimicrobials](#load_antimicrobials)
    * [load\_manifest](#load_manifest)
    * [load\_ontology](#load_ontology)
    * [load\_samples\_cron](#load_samples_cron)
    * [load\_tax\_tree](#load_tax_tree)
    * [set\_midas\_password](#set_midas_password)
  * [License](#license)
  * [Feedback/Issues](#feedbackissues)

## Introduction
Database schema module, including loading scripts.

## Installation
Bio-HICF-Schema has the following dependencies:

### Required dependencies
* [Bio-Metadata-Validator](https://github.com/sanger-pathogens/Bio-Metadata-Validator)

Details for installing Bio-HICF-Schema are provided below. If you encounter an issue when installing Bio-HICF-Schema please contact your local system administrator. If you encounter a bug please log it [here](https://github.com/sanger-pathogens/Bio-HICF-Schema/issues) or email us at path-help@sanger.ac.uk.

### From Source

Clone the repository:   
   
`git clone https://github.com/sanger-pathogens/Bio-HICF-Schema.git`   
   
Move into the directory and install all dependencies using [DistZilla](http://dzil.org/):   
  
```
cd Bio-HICF-Schema
dzil authordeps --missing | cpanm
dzil listdeps --missing | cpanm
```
  
Run the tests:   
  
`dzil test`   
If the tests pass, install Bio-HICF-Schema:   
  
`dzil install`   

### Running the tests
The test can be run with dzil from the top level directory:  
  
`dzil test`  
## Usage
Bio-HICF-Schema includes the following scripts.

### add_midas_user
```
add_midas_user [-dehnpu] [long options...]
	       -d STR --dbconfig STR        path to the database configuration file
	       -u STR --username STR        the username for the new user
	       -p[=STR] --passphrase[=STR]  set a password for the user
	       -e STR --email STR           the email address for the user
	       -n STR --name STR            the display name for the user
	       -h --help                    print usage message
```
### add_multiple_midas_users
```
add_multiple_midas_users [-dh] [long options...]
			 -d STR --dbconfig STR  path to the database configuration file
			 -h --help              print usage message
```
### build_schemata.pl
Dumps the two HICF schemata as DBIC models

### delete_midas_user
```
delete_midas_user [-dhu] [long options...]
		  -d STR --dbconfig STR  path to the database configuration file
		  -u STR --username STR  the username for the user to be deleted
		  -h --help              print usage message
```
### geocode_samples_cron
Cron script to geocode sample locations

### load_antimicrobials
```
load_antimicrobials [-ch] [long options...] <filename>
		    -c STR --config STR  path to the configuration file
		    -h --help            print usage message
```
### load_manifest
```
load_manifest [-cdh] [long options...] <filename>
	      -c STR --checklist STR  path to the checklist configuration file
	      -d STR --dbconfig STR   path to the database configuration file
	      -h --help               print usage message
```
### load_ontology
```
load_ontology [-cho] [long options...] <filename>
	      -o STR --ontology STR  name of the ontology to load
	      -c STR --config STR    path to the configuration file
	      -h --help              print usage message
```
### load_samples_cron
Cron script to load new assemblies for HICF samples

### load_tax_tree
```
load_tax_tree [-ch] [long options...]
	      -c STR --config STR  path to the configuration file
	      -h --help            print usage message
```
### set_midas_password
```
set_midas_password [-dhpu] [long options...]
		   -d STR --dbconfig STR    path to the database configuration file
		   -u STR --username STR    the username whose password will be changed
		   -p STR --passphrase STR  the new password for the user
		   -h --help                print usage message
```

## License
Bio-HICF-Schema is free software, licensed under [GPLv3](https://github.com/sanger-pathogens/Bio-HICF-Schema/blob/master/license_file).

## Feedback/Issues
Please report any issues to the [issues page](https://github.com/sanger-pathogens/Bio-HICF-Schema/issues) or email path-help@sanger.ac.uk.
