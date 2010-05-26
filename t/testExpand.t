use strict;
use warnings;

use Test::More tests => 1;                      # last test to print
$ENV{'SKIP_INIT'} = 1;
our %stats;
our %gender_vars;
require 'bucket.pl';

my $channel = "#xkcd";
my $nick1 = "halkeye";
my $nick2 = "zigdon";

{ no warnings 'redefine'; *main::Log = sub {}; *main::Report = sub {}; }

{
    %stats = ();
    $stats{users}{$channel}{$nick2}{last_active} = time;
    is(&expand("$nick1", $channel, "test \$someone", undef), "test $nick2", "testing \$someone replacement" );
}
#, $shehe, $he, $she, $they, $it $objective, $him, $her, $them $reflexive, $himselfherself, $himself, $herself, $themself, $itself $hishers, $hers, $theirs $determiner $hisher, $herhis, $their

foreach my $gvar ( sort { length $a <=> length $b } keys %gender_vars ) {
    foreach my $gender ('male','female','androgynous','inanimate', 'full name') {
        %stats = ();
        $stats{users}{$channel}{$nick2}{last_active} = time;
        $stats{users}{genders}{$nick1} = $gender;
        $stats{users}{genders}{$nick2} = $gender;

        my $genderName = $gender_vars{$gvar}{$gender};
        if ($gender eq 'full name')
        {
            $genderName =~ s/%N/$nick1/g;
        }

        is(
                &expand($nick1, $channel, "test --\$$gvar--", undef),
                "test --$genderName--1",
                "testing \$$gvar replacement - " . ucfirst($gender) 
        );
    }
}
