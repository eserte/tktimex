#!/usr/bin/env perl
# -*- perl -*-
#
# DO NOT EDIT, created automatically by
# /home/slavenr/bin/sh/mkprereqinst
# on Tue Apr 26 13:12:42 2005
#
# Run this script as
#    perl prereqinst.pl
#
# The latest version of mkprereqinst may be found at
#     http://www.perl.com/CPAN-local/authors/id/S/SR/SREZIC/
# or any other CPAN mirror.

use Getopt::Long;
my $require_errors;
my $use = 'cpan';
my $q;

if (!GetOptions("ppm"  => sub { $use = 'ppm'  },
		"cpan" => sub { $use = 'cpan' },
                "q"    => \$q,
	       )) {
    die "usage: $0 [-q] [-ppm | -cpan]\n";
}

$ENV{FTP_PASSIVE} = 1;

if ($use eq 'ppm') {
    require PPM;
    do { print STDERR 'Install Mail-Send'.qq(\n); PPM::InstallPackage(package => 'Mail-Send') or warn ' (not successful)'.qq(\n); } if !eval 'require Mail::Send';
    do { print STDERR 'Install Tk-Getopt'.qq(\n); PPM::InstallPackage(package => 'Tk-Getopt') or warn ' (not successful)'.qq(\n); } if !eval 'require Tk::Getopt; Tk::Getopt->VERSION(0.34)';
    do { print STDERR 'Install File-Spec'.qq(\n); PPM::InstallPackage(package => 'File-Spec') or warn ' (not successful)'.qq(\n); } if !eval 'require File::Spec';
    do { print STDERR 'Install Data-Dumper'.qq(\n); PPM::InstallPackage(package => 'Data-Dumper') or warn ' (not successful)'.qq(\n); } if !eval 'require Data::Dumper';
    do { print STDERR 'Install Date-Calc'.qq(\n); PPM::InstallPackage(package => 'Date-Calc') or warn ' (not successful)'.qq(\n); } if !eval 'require Date::Calc';
    do { print STDERR 'Install Tk-Date'.qq(\n); PPM::InstallPackage(package => 'Tk-Date') or warn ' (not successful)'.qq(\n); } if !eval 'require Tk::Date; Tk::Date->VERSION(0.3)';
    do { print STDERR 'Install Spreadsheet-WriteExcel'.qq(\n); PPM::InstallPackage(package => 'Spreadsheet-WriteExcel') or warn ' (not successful)'.qq(\n); } if !eval 'require Spreadsheet::WriteExcel; Spreadsheet::WriteExcel->VERSION(0.42)';
    do { print STDERR 'Install XML-Parser'.qq(\n); PPM::InstallPackage(package => 'XML-Parser') or warn ' (not successful)'.qq(\n); } if !eval 'require XML::Parser';
    do { print STDERR 'Install Tk'.qq(\n); PPM::InstallPackage(package => 'Tk') or warn ' (not successful)'.qq(\n); } if !eval 'require Tk; Tk->VERSION(402.003)';
} else {
    use CPAN;
    if (!eval q{ CPAN->VERSION(1.70) }) {
	install 'CPAN';
        CPAN::Shell->reload('cpan');
    }
    install 'Mail::Send' if !eval 'require Mail::Send';
    install 'Tk::Getopt' if !eval 'require Tk::Getopt; Tk::Getopt->VERSION(0.34)';
    install 'File::Spec' if !eval 'require File::Spec';
    install 'Data::Dumper' if !eval 'require Data::Dumper';
    install 'Date::Calc' if !eval 'require Date::Calc';
    install 'Tk::Date' if !eval 'require Tk::Date; Tk::Date->VERSION(0.3)';
    install 'Spreadsheet::WriteExcel' if !eval 'require Spreadsheet::WriteExcel; Spreadsheet::WriteExcel->VERSION(0.42)';
    install 'XML::Parser' if !eval 'require XML::Parser';
    install 'Tk' if !eval 'require Tk; Tk->VERSION(402.003)';
}
if (!eval 'require Mail::Send;') { warn $@; $require_errors++ }
if (!eval 'require Tk::Getopt; Tk::Getopt->VERSION(0.34);') { warn $@; $require_errors++ }
if (!eval 'require File::Spec;') { warn $@; $require_errors++ }
if (!eval 'require Data::Dumper;') { warn $@; $require_errors++ }
if (!eval 'require Date::Calc;') { warn $@; $require_errors++ }
if (!eval 'require Tk::Date; Tk::Date->VERSION(0.3);') { warn $@; $require_errors++ }
if (!eval 'require Spreadsheet::WriteExcel; Spreadsheet::WriteExcel->VERSION(0.42);') { warn $@; $require_errors++ }
if (!eval 'require XML::Parser;') { warn $@; $require_errors++ }
if (!eval 'require Tk; Tk->VERSION(402.003);') { warn $@; $require_errors++ }

if (!$require_errors) { warn "Autoinstallation of prerequisites completed\n" unless $q } else { warn "$require_errors error(s) encountered while installing prerequisites\n" } 
