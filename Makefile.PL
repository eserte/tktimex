use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Timex',
    'VERSION_FROM' => 'tktimex', # finds $VERSION
    'EXE_FILES'  => ['tktimex'],
    'dist'      => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => '.gz',
                    'POSTOP'=>'-$(CHMOD) 644 $(DISTVNAME).tar$(SUFFIX)'},
    'PM' => {'Timex/Project.pm'   => '$(INST_LIBDIR)/Timex/Project.pm',
	     'Tk/UnderlineAll.pm' => '$(INST_LIBDIR)/Tk/UnderlineAll.pm',
	    },
    'PREREQ_PM' => {'Tk' => 402.003,
		    'Tk::Getopt' => 0.34,
		    'Tk::FileDialog' => 0,
		    'Tk::Date' => 0.21,
		    'Data::Dumper' => 0,
		   },
);
