{
  schema_class => 'Bio::HICF::Schema',
  resultsets => [ qw(
    Antimicrobial
    AntimicrobialResistance
    Assembly
    Brenda
    Checklist
    Envo
    File
    Gazetteer
    Location
    Manifest
    Sample
    Taxonomy
  ) ],
    # ExternalResource
  fixture_sets => {
    main => [
      Antimicrobial => [
        [ qw( name created_at ) ],
        [ 'am1', '2014-10-12 12:15:00' ],
        [ 'am2', '2014-11-12 12:15:00' ],
      ],
      AntimicrobialResistance => [
        [ qw( sample_id
              antimicrobial_name
              susceptibility
              mic
              equality
              method
              created_at ) ],
        [ 1, 'am1', 'S', 50, 'eq', 'WTSI', '2014-12-02 16:55:00' ],
      ],
      Assembly => [
        [ qw( assembly_id sample_accession type ) ],
        [ qw( 1 ERS111111 ERS ) ],
        [ qw( 2 ERS222222 ERS ) ],
      ],
      Brenda => [
        [ qw( id description) ],
        [ qw( BTO:0000645 Lung ) ],
      ],
      Checklist => [
        [ qw( checklist_id config config name created_at ) ],
        [ 1,
          qw(<checklist hicf>
  header_row "raw data accession,sample accession,sample description,collected at,tax ID,scientific name,collected by,collection date,location,host associated,specific host,host disease status,host isolation source,patient location,isolation source,serovar,other classification,strain,isolate,antimicrobial resistance,,,,,,,,"
  <dependencies>
    <if host_associated>
      then specific_host
      then host_disease_status
      then host_isolation_source
      then patient_location
      else isolation_source
    </if>
    <some_of>
      taxid_or_name tax_id
      taxid_or_name scientific_name
    </some_of>
    <one_of>
      serovar_or_other_classification serovar
      serovar_or_other_classification other_classification
      strain_or_isolate strain
      strain_or_isolate isolate
    </one_of>
  </dependencies>
  <field>
    name         raw_data_accession
    description  'Accession for raw data i.e. fastq/bam files.'
    type         Str
    required     1
  </field>
  <field>
    name         sample_accession
    description  'Accession for the sample.'
    type         Str
    required     1
  </field>
  <field>
    name         donor_id
    description  'Internal ID for the sample.'
    type         Str
    required     1
  </field>
  <field>
    name         sample_description
    description  'Free text description of the sample.'
    type         Str
  </field>
  <field>
    name         submitted_by
    description  'ID of the institute that performed the study. Must be one of "CAMBRIDGE", "UCL", or "OXFORD".'
    type         Enum
    values       CAMBRIDGE
    values       UCL
    values       OXFORD
    required     1
  </field>
  <field>
    name         tax_id
    description  'Taxonomy ID of the organism that provided the sequenced genetic material, e.g. "9606".'
    type         Int
  </field>
  <field>
    name         scientific_name
    description  'The full scientific name of the organism that provided the sequenced genetic material, e.g. "Homo sapiens".'
    type         Str
  </field>
  <field>
    name         collected_by
    description  'Name of person(s) who collected the specimen. Must be a comma-separated list of full names, in the form Surname INITIAL(S), e.g. "Tate JG, Keane J".'
    type         Str
    validation   (\w{2,}\s+\w+,?)+
  </field>
  <field>
    name         source
    description  'Information about the source of the sample, e.g. BSAC ID.'
    type         Str
  </field>
  <field>
    name         collection_date
    description  'Date and time that the specimen was collected, e.g. 2014-12-01T14:39Z. Must be given in an ISO8601-compatible format.'
    type         DateTime
    required     1
  </field>
  <field>
    name         location
    description  'Locality of isolation of the sampled organism indicated in terms of political names for nations, oceans or seas, followed by regions and localities. Must be a term from the GAZ ontology.'
    type         Ontology
    path         .cached_test_files/gaz.obo
    required     1
  </field>
  <field>
    name         host_associated
    description  'Is the organism from which the sample was obtained associated with a host organism ? Must be either "yes" or "no".'
    type         Bool
    required     1
  </field>
  <field>
    name         specific_host
    description  'Natural (as opposed to laboratory) host to the organism from which the sample was obtained (or "free-living" if not host associated). Must be the full scientific name of host organism.'
    type         Str
  </field>
  <field>
    name         host_disease_status
    description  'Condition of host. Must be one of "diseased", "healthy" or "carriage".'
    type         Enum
    values       healthy
    values       diseased
    values       carriage
  </field>
  <field>
    name         host_isolation_source
    description  'Name of host tissue or organ sampled for analysis. Must be a term from the BRENDA ontology.'
    type         Ontology
    path         .cached_test_files/bto.obo
  </field>
  <field>
    name         patient_location
    description  'Describes the health care situation of a human host when the sample was obtained. Must be one of "inpatient" or "community". For non-human host, use "community".'
    type         Enum
    values       inpatient
    values       community
  </field>
  <field>
    name         isolation_source
    description  'Describes the physical, environmental and/or local geographical source of the biological sample from which the sample was derived. Must be a term from the EnvO ontology.'
    type         Ontology
    path         .cached_test_files/envo-basic.obo
  </field>
  <field>
    name         serovar
    description  'Serological variety of a species characterised by its antigenic properties.'
    type         Str
  </field>
  <field>
    name         other_classification
    description  'Other appropriate classification terms for the sample organism.'
    type         Str
  </field>
  <field>
    name         strain
    description  'Name of strain from which sample was obtained.'
    type         Str
  </field>
  <field>
    name         isolate
    description  'Name of isolate from which sample was obtained.'
    type         Str
  </field>
  <field>
    name         antimicrobial_resistance
    description  'Comma-separated list of antibiotics to which the sampled organism displays resistance. Each antibiotic must be followed by the SIR and, optionally, the MIC, and method used. See notes.'
    type         Str
    validation   ^((([A-Za-z\d\- ]+);([SIR]);(\d+)(;(\w+))?),? *)+$
  </field>
</checklist>),
          'hicf',
          '2015-01-29 09:30:00' ],
      ],
      Envo => [
        [ qw( id description ) ],
        [ qw( ENVO:00002148 coarse beach sand ) ],
      ],
      File => [
        [ qw( file_id assembly_id version path md5 ) ],
        [ qw( 1 1 1 /home/testuser/ERS111111_123456789a123456789b123456789cda.fa 123456789a123456789b123456789cda ) ],
        [ qw( 2 1 2 /home/testuser/ERS111111_123456789a123456789b123456789cdb.fa 123456789a123456789b123456789cdb ) ],
      ],
      Gazetteer => [
        [ qw( id description ) ],
        [ qw( GAZ:00444180 Hinxton ) ],
      ],
      Manifest => [
        [ qw( manifest_id checklist_id md5 created_at ) ],
        [ '4162F712-1DD2-11B2-B17E-C09EFE1DC403', 1, '8fb372b3d14392b8a21dd296dc7d9f5a', '2015-01-29 09_30_00' ],
        [ '0162F712-1DD2-11B2-B17E-C09EFE1DC403', 1, '0fb372b3d14392b8a21dd296dc7d9f5a', '2015-01-29 09_30_00' ],
      ],
      Sample => [
        [ qw( manifest_id
              raw_data_accession
              sample_accession
              donor_id
              sample_description
              submitted_by
              tax_id
              scientific_name
              collected_by
              collection_date
              location
              host_associated
              specific_host
              host_disease_status
              host_isolation_source
              patient_location
              isolation_source
              serovar
              other_classification
              strain
              isolate
              withdrawn
              created_at
              deleted_at ) ],
        [ '4162F712-1DD2-11B2-B17E-C09EFE1DC403',
          'data:1',
          'ERS111111',
          'donor1',
          'New sample',
          'OXFORD',
          10090,
          'Mus musculus',
          'Tate JG',
          1428658943,
          'GAZ:00444180',
          1,
          'Homo sapiens',
          'healthy',
          'BTO:0000645',
          'inpatient',
          undef,
          'serovar',
          undef,
          'strain',
          undef,
          undef,
          '2014-12-02 16:55:00',
          undef ],
      ],
      Taxonomy => [
        [ qw( tax_id name lft rgt parent_tax_id ) ],
        [ 9606, 'Homo sapiens', 1, 1, 1 ],
        [ 63221, 'Homo sapiens neanderthalensis', 1, 1, 1 ],
      ],
    ],
  },
};
