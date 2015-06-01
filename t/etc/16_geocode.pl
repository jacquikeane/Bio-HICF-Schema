{
  schema_class => 'Bio::HICF::Schema',
  resultsets => [ qw(
    Gazetteer
    Location
    Sample
  ) ],
  fixture_sets => {
    main => [
      Gazetteer => [
        [ qw( id description ) ],
        [ 'GAZ:00489637', 'University of Oxford' ],
      ],
      Location => [
        [ qw( gaz_term
              lat
              lng ) ],
        [ qw( GAZ:00444180 52.078972 0.187583 ) ]
      ],
      Sample => [
        [ qw( manifest_id
              raw_data_accession
              sample_accession
              sample_description
              collected_at
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
          'data:2',
          'ERS222222',
          'New sample',
          'OXFORD',
          9606,
          undef,
          'Tate JG',
          1428658943,
          'GAZ:00489637',
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
        [ '4162F712-1DD2-11B2-B17E-C09EFE1DC403',
          'data:3',
          'ERS333333',
          'New sample',
          'OXFORD',
          9606,
          undef,
          'Tate JG',
          1428658943,
          'not available; not collected',
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
    ]
  }
}

