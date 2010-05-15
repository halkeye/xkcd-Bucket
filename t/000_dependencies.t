package Bot::Bucket::t::000_dependencies;
use strict;
use warnings;

# tests for the existence of all dependencies.

use Test::More;

my %modules = (
    # module name  => minimum version
    'POE' => '',
    'POE::Component::IRC' => '',
    'POE::Component::IRC::State' => '',
    'POE::Component::IRC::Plugin::NickServID' => '',
    'POE::Component::IRC::Plugin::Connector' => '',
    'POE::Component::SimpleDBI' => '',
    'Lingua::EN::Conjugate'  => '',
    'Lingua::EN::Inflect' => '',
    'Lingua::EN::Syllable' => '',    # don't import anything
    'YAML' => '',
    'Data::Dumper' => '',
    'Fcntl' => '',
    'HTML::Entities' => '',
    'URI::Escape' => '',
    'LWP::Simple' => '',
    'XML::Simple' => '',
);

foreach my $module (keys %modules)
{
    my $version = $modules{$module};
    # we use require (when possible) to avoid importing meta, blessed
    # etc (which the various Moose classes want to do).
    #$version ? use_ok($module, $version) : require_ok($module);
    require_ok($module);
    cmp_ok(VERSION($module), '>=', $version, "$module >= $version") if $version;
}
done_testing;
