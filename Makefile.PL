use ExtUtils::MakeMaker;

WriteMakefile
  (
   'NAME'       => 'protocol',
   'VERSION_FROM' => "lib/protocol.pm",
   'PREREQ_PM' => {
                   'Filter::Simple' => 0,
                  },
   'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz", },
  );
