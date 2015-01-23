{
  schema_class => 'Bio::HICF::Schema',
  resultsets => [ qw(
    Antimicrobial
    AntimicrobialResistance
    Brenda
    Envo
    Gazetteer
    Manifest
    Sample
    Taxonomy
  ) ],
    # ExternalResource
    # File
    # Run
  fixture_sets => {
    main => [
      Brenda => [
        [ qw( brenda_id description) ],
        [ qw( BTO:0000645 Lung ) ],
      ],
      Envo => [
        [ qw( envo_id description ) ],
        [ qw( ENVO:00002148 coarse beach sand ) ],
      ],
      Gazetteer => [
        [ qw( gaz_id description ) ],
        [ qw( GAZ:00444180 Hinxton ) ],
      ],
      Taxonomy => [
        [ qw( ncbi_taxid ) ],
        [ qw( 9606 ) ],
      ],
      Antimicrobial => [
        [ qw( name created_at ) ],
        [ qw( am1 2014-10-12T12:15:00 ) ],
        [ qw( am2 2014-11-12T12:15:00 ) ],
      ],
      Sample => [
        [ qw( manifest_id
              raw_data_accession
              sample_accession
              sample_description
              collected_at
              ncbi_taxid
              scientific_name
              collected_by
              collection_date
              location
              host_associated
              specific_host
              host_disease_status
              host_isolation_source
              isolation_source
              serovar
              other_classification
              strain
              isolate
              withdrawn
              created_at
              updated_at
              deleted_at ) ],
        [ '4162F712-1DD2-11B2-B17E-C09EFE1DC403',
          'data:1',
          'sample:1',
          'New sample',
          'WTSI',
          9606,
          undef,
          'Tate JG',
          '2015-01-10T14:30:00',
          'GAZ:00444180',
          1,
          'Homo sapiens',
          'healthy',
          'BTO:0000645',
          undef,
          'serovar',
          undef,
          'strain',
          undef,
          undef,
          '2014-12-02T16:55:00',
          '2014-12-02T16:55:00',
          undef ],
      ],
      AntimicrobialResistance => [
        [ qw( sample_id
              antimicrobial_name
              susceptibility
              mic
              diagnostic_centre
              created_at ) ],
        [ qw( 1 am1 S 50 WTSI 2014-12-02T16:55:00 ) ],
      ],
    ],
  },
};
