use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Timex',
    'VERSION_FROM' => 'tktimex', # finds $VERSION
    'ABSTRACT' => 'project time manager',
    'EXE_FILES'  => [qw/tktimex ctimex timexserver/],
    'dist'      => {'COMPRESS'=>'gzip -9', 'SUFFIX' => '.gz',
                    'POSTOP'=>'-$(CHMOD) 644 $(DISTVNAME).tar$(SUFFIX)'},
    'PM' =>
    {
     'Timex/ExcelExport.pm'    => '$(INST_LIBDIR)/Timex/ExcelExport.pm',
     'Timex/Project.pm'	       => '$(INST_LIBDIR)/Timex/Project.pm',
     'Timex/Project/Export.pm' => '$(INST_LIBDIR)/Timex/Project/Export.pm',
     'Timex/Project/XML.pm'    => '$(INST_LIBDIR)/Timex/Project/XML.pm',
     'Timex/Rcs.pm'	       => '$(INST_LIBDIR)/Timex/Rcs.pm',
     'Timex/Server.pm'	       => '$(INST_LIBDIR)/Timex/Server.pm',
     'Timex/Utmp.pm'	       => '$(INST_LIBDIR)/Timex/Utmp.pm',
     'Timex/MultiProject.pm'   => '$(INST_LIBDIR)/Timex/MultiProject.pm',

     'Tk/Autoscroll.pm'	       => '$(INST_LIBDIR)/Timex/Tk/Autoscroll.pm',
     'Tk/UnderlineAll.pm'      => '$(INST_LIBDIR)/Timex/Tk/UnderlineAll.pm',
     'Win32Util.pm'            => '$(INST_LIBDIR)/Timex/Win32Util.pm',

     'plain.up.gif'            => '$(INST_LIBDIR)/plain.up.gif',
     'plain.down.gif'          => '$(INST_LIBDIR)/plain.down.gif',
     'mini-clock.xpm'          => '$(INST_LIBDIR)/mini-clock.xpm',

     'Timex/de_template.csv'   => '$(INST_LIBDIR)/Timex/de_template.csv',
     'templates/oo.pjt'        => '$(INST_LIBDIR)/Timex/templates/oo.pjt',
    },
    'PREREQ_PM' => {'Tk'           => 402.003,
		    'Tk::Getopt'   => 0.34,
		    'Tk::Date'     => 0.30,
		    'Data::Dumper' => 0,
		    'Date::Calc'   => 0,
		    'XML::Parser'  => 0,
		    'Mail::Send'   => 0,
		   },
    'AUTHOR' => 'Slaven Rezic (slaven@rezic.de)',
);

#sub MY::top_targets {
#    'ci :
#	@echo Do not use because of symlinks
#
#';
#}

sub MY::postamble {
    <<EOF .

release:	dist
	../sf-upload/sf-upload -project ptktools -package tktimex -release \$(VERSION) -file \$(DISTVNAME).tar\$(SUFFIX) -notesfile README -changes ""

EOF
}
