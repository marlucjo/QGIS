#!/usr/bin/env perl
###########################################################################
#    processing2cpp.pl
#    ---------------------
#    begin                : July 2015
#    copyright            : (C) 2015 by Juergen E. Fischer
#    email                : jef at norbit dot de
###########################################################################
#                                                                         #
#   This program is free software; you can redistribute it and/or modify  #
#   it under the terms of the GNU General Public License as published by  #
#   the Free Software Foundation; either version 2 of the License, or     #
#   (at your option) any later version.                                   #
#                                                                         #
###########################################################################

use XML::Simple;
use YAML::XS qw/LoadFile/;
use Data::Dumper;

sub xmlescape {
  my $data = shift;

  $data =~ s/&/&amp;/sg;
  $data =~ s/</&lt;/sg;
  $data =~ s/>/&gt;/sg;
  $data =~ s/"/&quot;/sg;

  return $data;
}


die "usage: $0 dir\n" unless @ARGV==1;
die "directory $ARGV[0] not found" unless -d $ARGV[0];

my %strings;

for my $f (<python/plugins/processing/algs/otb/description/*.xml>) {
	my $xml = XMLin($f, ForceArray=>1);

	foreach my $k (qw/longname group description/) {
		$strings{"OTBAlgorithm"}{$xml->{$k}->[0]} = 1;
	}
}

for my $f (<python/plugins/processing/algs/grass*/description/*.txt>) {
	open I, $f;
	my $name = scalar(<I>);
	my $desc = scalar(<I>);
	my $group = scalar(<I>);
	close I;

	chop $desc;
	chop $group;

	$strings{"GrassAlgorithm"}{$desc} = 1;
	$strings{"GrassAlgorithm"}{$group} = 1;
}

for my $f (<python/plugins/processing/algs/taudem/description/*/*.txt>) {
	open I, $f;
	my $desc = scalar(<I>);
	my $name = scalar(<I>);
	my $group = scalar(<I>);
	close I;

	chop $desc;
	chop $group;

	$strings{"TAUDEMAlgorithm"}{$desc} = 1;
	$strings{"TAUDEMAlgorithm"}{$group} = 1;
}

for my $f (<python/plugins/processing/algs/saga/description/*/*.txt>) {
	open I, $f;
	my $desc = scalar(<I>);
	close I;

	chop $desc;

	$strings{"SAGAAlgorithm"}{$desc} = 1;
}

for my $f (<python/plugins/processing/algs/help/*.yaml>) {
	my ($base) = $f =~ /.*\/(.*)\.yaml$/;
	$base = uc $base;
	my $yaml = LoadFile($f);
	for my $k (keys %$yaml) {
		$strings{"${base}Algorithm"}{$yaml->{$k}} = 1;
	}
}

for my $f ( ("python/plugins/processing/gui/algnames.txt") ) {
	open I, $f;
	while(<I>) {
		chop;
		s/^.*,//;
		foreach my $v (split "/", $_) {
			$strings{"AlgorithmClassification"}{$v} = 1;
		}
	}
	close I;
}

foreach my $k (keys %strings) {
	die "$ARGV[0]/$k-i18n.ui already exists" if -f "$ARGV[0]/$k-i18n.ui";
	open F, ">$ARGV[0]/$k-i18n.ui";
	binmode(F, ":utf8");

print F <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
 <!--
 This is NOT a proper UI code. This file is only designed to be caught
 by qmake and included in lupdate. It contains all translateable strings collected
 by scripts/processing2ui.pl.
 -->
<ui version="4.0">
  <class>$k</class>;
EOF

	foreach my $v (keys %{ $strings{$k} } ) {
		next if $v eq "";
		print F "  <property><string>" . xmlescape($v) . "</string></property>\n";
	}

	print F <<EOF;
</ui>
EOF

	close F;
}
