#! /usr/bin/perl -w
#---------------------------------------------------------------------------------
#  make_fare.pl is part of the BART dashboard widget.  (c) 2008 Bret Victor
#                                                      (c) 2010 Bradley Froehle
#  This software is licensed under the terms of the open source MIT license.
#---------------------------------------------------------------------------------
#
#  perl make_fare.pl > Fare.js
#
#  Downloads the line schedules from bart.gov and generates a JavaScript
#  fare table on stdout.  This becomes the Fare.js file.
#
# (Requires LWP::Simple & XML::Simple.  Found in MacPorts p5-libwww-perl & p5-xml-simple.)


use strict;
use LWP::Simple;
use XML::Simple;

#-----------------------------------------------------------------
#  Tables
my $date = '07/01/2012';

my %station_names = (

    MLBR => "Millbrae",
    SFIA => "SFO",
    SBRN => "San Bruno",
    SSAN => "South SF",
    COLM => "Colma",
    
    DALY => "Daly City",
    BALB => "Balboa Park",
    
    WOAK => "West Oakland",
    EMBR => "Embarcadero", 
    MONT => "Montgomery", 
    POWL => "Powell", 
    CIVC => "Civic Center",
    '16TH' => "16th St",
    '24TH' => "24th St",

    PITT => "Pittsburg", 
    NCON => "North Concord",
    CONC => "Concord", 
    PHIL => "Pleasant Hill",
    WCRK => "Walnut Creek",
    LAFY => "Lafayette", 
    ORIN => "Orinda", 
    ROCK => "Rockridge", 
    MCAR => "MacArthur",
    '12TH' => "12th St",
    '19TH' => "19th St",
    
    HAYW => "Hayward", 
    SHAY => "South Hayward",
    UCTY => "Union City",
    FRMT => "Fremont",

    LAKE => "Lake Merritt", 
    FTVL => "Fruitvale", 
    COLS => "Coliseum",
    SANL => "San Leandro",
    BAYF => "Bay Fair",
    
    RICH => "Richmond", 
    DELN => "Del Norte", 
    PLZA => "Plaza", 
    NBRK => "North Berkeley",
    DBRK => "Berkeley", 
    ASHB => "Ashby",
    
    GLEN => "Glen Park",
    CAST => "Castro Valley",
    WDUB => "West Dublin",
    DUBL => "Dublin",
);



#-----------------------------------------------------------------
#  Main code

my %fares;
my $xml = new XML::Simple;

for my $from_station (sort keys %station_names) {
    warn "from $station_names{$from_station}...\n";
    for my $to_station (sort keys %station_names) {
        my $url = makeUrl($from_station, $to_station);
        my $content = get($url);
        my $fare = getFareFromXml($content);
        $fares{$station_names{$from_station}}{$station_names{$to_station}} = $fare;
    }
}
print getJavascript(\%fares);
exit();


#-----------------------------------------------------------------
#  Main subroutines

sub makeUrl {
    my ($from_station, $to_station) = @_;
    return "http://api.bart.gov/api/sched.aspx?cmd=fare&orig=$from_station" .
           "&dest=$to_station&date=$date&key=MW9S-E7SL-26DU-VV8V";
}

sub getFareFromXml {
    my ($content) = @_;
    my $data = $xml->XMLin($content);
    my ($dollars,$cents) = ($data->{trip}->{fare} =~ /(\d+)\.(\d+)/);
    unless (defined $dollars) { die "could not understand this:\n\n$content\n"; }
    return 100 * $dollars + $cents;
}

#-----------------------------------------------------------------
#  JavaScript output generation

sub getJavascript {
    my ($fares) = @_;
    my $now = localtime;
    
    my @fare_list;
    my @station_names = sort values %station_names;
    my $number_of_stations = @station_names;
    
    for my $from_station (@station_names) {
        for my $to_station (@station_names) {
            push @fare_list, $fares->{$from_station}{$to_station};
        }
    }
    
    my $fare_string = join(", ", @fare_list);
    my $station_string = '"' . join('", "', @station_names) . '"';
    
    return <<_EOT_;
//-----------------------------------------------------------------------------
//  Fare.js is part of the BART dashboard widget.       (c) 2008 Bret Victor
//  This software is licensed under the terms of the open source MIT license.
//-----------------------------------------------------------------------------
//
//  Automatically generated by make_fare.pl on $now.
//
//  cents = Fare.getCentsBetween("Del Norte", "Castro Valley")
//

function Fare () {

    var fares = [ $fare_string ];
    
    var station_names = [ $station_string ];

    var station_indexes = {}
    for (var i=0; i < station_names.length; i++) {
        station_indexes[ station_names[i] ] = i
    }
    
    Fare.getCentsBetween = function (start_name, end_name) {
        var start_index = station_indexes[start_name]
        var end_index   = station_indexes[end_name]
        return fares[ start_index * $number_of_stations + end_index ]
    }
}

// Open the package.
Fare();

_EOT_
}

