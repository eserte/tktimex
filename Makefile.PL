use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Timex',
    'VERSION_FROM' => 'tktimex', # finds $VERSION
    'ABSTRACT' => 'project time manager',
    'EXE_FILES'  => [qw/tktimex ctimex/],
    'dist'      => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => '.gz',
                    'POSTOP'=>'-$(CHMOD) 644 $(DISTVNAME).tar$(SUFFIX)'},
    'PM' => {'Timex/Project.pm'   => '$(INST_LIBDIR)/Timex/Project.pm',
	     'Timex/Project/Export.pm' => '$(INST_LIBDIR)/Timex/Project/Export.pm',
	     'Timex/Project/XML.pm' => '$(INST_LIBDIR)/Timex/Project/XML.pm',
	     'Timex/Rcs.pm' => '$(INST_LIBDIR)/Timex/Rcs.pm',
	     'Timex/Server.pm' => '$(INST_LIBDIR)/Timex/Server.pm',
	     'Tk/UnderlineAll.pm' => '$(INST_LIBDIR)/Tk/UnderlineAll.pm',
	     'Tk/Autoscroll.pm' => '$(INST_LIBDIR)/Tk/Autoscroll.pm',
	    },
    'PREREQ_PM' => {'Tk'           => 402.003,
		    'Tk::Getopt'   => 0.34,
		    'Tk::Date'     => 0.21,
		    'Data::Dumper' => 0,
		   },
    # COREQ: XML::Parser
    'AUTHOR' => 'Slaven Rezic (eserte@cs.tu-berlin.de)',
);

#sub MY::top_targets {
#    'ci :
#	@echo Do not use because of symlinks
#
#';
#}

