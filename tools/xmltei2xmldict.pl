#!/usr/bin/perl
# d for debug

# V1.4 5/2004 Michael Bunk                                                                    
#   * added option to generate 00-database-allchars header  
#
# V1.3 4/2004 Michael Bunk kleinerurm-at-gmx.net
#   * finally used FindBin
#   * use warnings; instead of #!perl -w to avoid warnings
#     in foreign code (Sablotron module)
#    
# V1.1 2/2004 Michael Bunk kleinerurm-at-gmx.net
#   * put .pm files into lib/
#
# V1.0 6/2003 Michael Bunk kleinerurm-at-gmx.net
#   * based on tei2dict_xml.pl
#
# Note from the homepage of the package SP, where nsgmls forms a part:
#   Note that only the Win32/Unicode binaries are compiled with
#   multibyte support. To get multibyte support on other platforms,
#   you must compile from source. (If this is a problem, let me know.)
#   (James Clark)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software 
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

use warnings;
use strict;
use FindBin;
use lib "$FindBin::Bin";
use XML::ESISParser;
use Getopt::Std;
use XML::Sablotron;
use XML::Sablotron::DOM;
use lib::TEIHandlerxml_xml;

our ($opt_f, $opt_h, $opt_s, $opt_c, $opt_u, $opt_l, $opt_i,
  $opt_r, $opt_t, $opt_a, $sab, $sit);
getopts('surai:l:f:t:');

if (!defined $opt_f) {
 print STDERR "\n$0 - convert Text Encoding Initiative files to\n";
 print STDERR " dictd database format keeping the xml in the <entry> elements\n\n";
 print STDERR " The TEI inputfile is expected as XML in TEI P4 format, see\n";
 print STDERR " http://www.tei-c.org/\n";
 print STDERR " Outputs .index and .dict file. The index is sorted with 'sort ...'\n";
 print STDERR " This help is outputted, because here was no tei file given.\n\n"; 
 print STDERR "Usage: $0 -f <teifile> [-sura] [-i <filtercmd>|-t <stylesheet.xsl>] [-l <locale>]\n";
 print STDERR " -s\t skip TEI header: do not treat it to generate\n";
 print STDERR "   \t  00-database-info & co special entrys (good to convert adapted\n";
 print STDERR "   \t  SGML tei files)\n";
 print STDERR " -u\t generate headword 00-database-utf8 in index file to\n";
 print STDERR "   \t  mark the database being in UTF-8 encoding\n";
 print STDERR "   \t  When this is given, 'sort' is called without -d option,\n";
 print STDERR "   \t  ie. all characters are used in comparisons\n";
 print STDERR " -r\t generate reverse index (use <tr> instead of <orth>)\n";
 print STDERR " -a\t generate headword 00-database-allchars (but no change in index mangling!)\n";
 print STDERR " -i <filtercmd>\t execute filtercmd for each entry (eg. 'sabcmd style.xsl')\n";
 print STDERR " -t <stylesheet.xsl>\t use an XSLT stylesheet for filtering the entries\n";
 print STDERR "   \t  with the Sablotron library. Excludes -i.\n";
 print STDERR " -l <locale>\t call 'sort' using <locale>. If not given, 'C' locale\n";
 print STDERR "   \t  will be used ('C' locale for normal & utf-8 index)\n";
 print STDERR " <teifile>\t name of tei inputfile\n\n";
 die;
 }
 
our $file = $opt_f;
die "Can't find file \"$file\"" unless -f $file;

die "Only one of -i and -t may be given" if $opt_i && $opt_t;

our $my_handler = lib::TEIHandlerxml_xml->new();

$my_handler->set_options($file, # hand over name for .dict and .index output files
    $opt_s ? 1 : 0,		# skip TEI header
    $opt_u ? 1 : 0,		# generate 00-database-utf8
    $opt_l ? $opt_l : "C",	# locale
    $opt_i ? $opt_i : "",	# filter command
    $opt_t,			# stylesheet for Sablotron
    $opt_r ? 1 : 0,		# generate reverse index
    $opt_a ? 1 : 0);		# generate 00-database-allchars
    
# XML::ESISParser should set these if IsSGML != 1
$ENV{SP_ENCODING} = "XML";
$ENV{SP_CHARSET_FIXED} = "YES";

if (!defined($ENV{SGML_CATALOG_FILES})) {
 print STDERR "Warning: SGML_CATALOG_FILES is not set.\nPlease set it to point to\n";
 print STDERR " - the xml.soc file from the (Open)SP distribution\n";
 print STDERR " - the TEI catalog file(s)\n";
 $ENV{SGML_CATALOG_FILES}= "/usr/share/doc/packages/sp/html-xml/xml.soc:/var/lib/sgml/CATALOG.tei_4xml:/var/lib/sgml/CATALOG.iso_ent";
 print STDERR "Using SGML_CATALOG_FILES=$ENV{SGML_CATALOG_FILES}\n";
 }
 
# FIXME the following schould be removed if we use XML,
# but if we do, we get:
# > XML::ESISParser::parse: unable to parse `file.tei'
# > nsgmls:/usr/lib/sgml/declaration/xml.decl:1:W: SGML declaration was not implied
# now that we set SP_ENCODING and SP_CHARSET_FIXED by ourselvelves,
# it might be different. It seems ESISParser.pm is not supporting XML...
our @additional_args;
push (@additional_args, IsSGML => 1);

XML::ESISParser->new->parse(Source => { SystemId => $file },
                            Handler => $my_handler,@additional_args,
#Declaration => "/usr/share/sgml/opensp/xml.dcl"
  );

print STDERR "Created $Dict::headwords headwords (including multiple <orth>-s / from the <tr>-s).\n";

# EOF