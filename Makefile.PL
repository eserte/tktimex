use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $pm =
    {
     'Timex/ExcelExport.pm'    => '$(INST_LIBDIR)/Timex/ExcelExport.pm',
     'Timex/Plugin.pm'         => '$(INST_LIBDIR)/Timex/Plugin.pm',
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

     'Timex/plain.up.gif'      => '$(INST_LIBDIR)/Timex/plain.up.gif',
     'Timex/plain.down.gif'    => '$(INST_LIBDIR)/Timex/plain.down.gif',
     'Timex/mini-clock.xpm'    => '$(INST_LIBDIR)/Timex/mini-clock.xpm',

     'Timex/de_template.csv'   => '$(INST_LIBDIR)/Timex/de_template.csv',
     'templates/oo.pjt'        => '$(INST_LIBDIR)/Timex/templates/oo.pjt',
    };
if ($^O eq 'MSWin32') {
    $pm->{'Timex/mini-clock.ico'} = '$(INST_LIBDIR)/Timex/mini-clock.ico';
}

my %prereq_pm =
    ('Tk'           => 402.003,
     'Tk::Getopt'   => 0.49,
     'Tk::Date'     => 0.30,
     'Data::Dumper' => 0,
     'Mail::Send'   => 0,
     'File::Spec'   => 0,
     # These are only corequisites:
     'Spreadsheet::WriteExcel' => 0.42,
     'XML::Parser'  => 0,
    );

{
    # we accept Date::Calc OR Date::Pcalc
    my $prereq = "Date::Calc";
    my $file = "$prereq.pm";
    $file =~ s{::}{/}g;
    eval { require $file };
    if ($@) {
	$prereq_pm{"Date::Pcalc"} = 0;
    } else {
	$prereq_pm{"Date::Calc"} = 0;
    }
}

WriteMakefile(
    'NAME'	=> 'Timex',
    'VERSION_FROM' => 'tktimex', # finds $VERSION
    'ABSTRACT' => 'time recording tool',
    'EXE_FILES'  => [qw/tktimex ctimex timexserver/],
    'dist'      => {'COMPRESS'=>'gzip -9', 'SUFFIX' => '.gz',
                    'POSTOP'=>'-$(CHMOD) 644 $(DISTVNAME).tar$(SUFFIX)'},
    'PM' => $pm,
    'PREREQ_PM' => \%prereq_pm,
    'AUTHOR' => 'Slaven Rezic (slaven@rezic.de)',
);

#sub MY::top_targets {
#    'ci :
#	@echo Do not use because of symlinks
#
#';
#}

sub MY::postamble {
    my $postamble = '';

    if (defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../perl.release.mk") {
	$postamble .= <<'EOF';

CVS_DIR=${HOME}/work/timex

SF_PROJECT=ptktools
SF_PACKAGE=tktimex

.include "../perl.release.mk"
.include "../perl.cvs.mk"

EOF
    }

    $postamble;
}
