package POE::Component::IRC::Plugin::WWW::GetPageTitle::Bucket;
use strict;
use warnings;
use Carp qw(croak);

#use Encode qw(decode);
#use Encode::Guess;
#use URI::Find::Schemeless;
use POE;
use POE::Component::Client::HTTP;
use Regexp::Common qw /URI/;
use POE::Component::IRC::Plugin qw( :ALL );

use base qw(POE::Component::IRC::Plugin);

# Plugin object constructor
sub new 
{
    my $package = shift;
    croak "$package requires an even number of arguments" if @_ & 1;
    my %self = @_;
    return bless \%self, $package;
}

sub PCI_register 
{
    my ($self, $irc) = splice @_, 0, 2;

    $self->{irc} = $irc;
    $irc->plugin_register( $self, 'SERVER', qw(public) );
    #$self->_register_state('get_title_response', \&get_title_response);
    
    POE::Component::Client::HTTP->spawn(
        Agent     => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_2; en-us) AppleWebKit/531.21.8 (KHTML, like Gecko) Version/4.0.4 Safari/531.21.10',
        Alias     => 'page_title_ua',       # defaults to 'weeble'
        #Timeout   => 60,                    # defaults to 180 seconds
    );
    $self->{session_id} = POE::Session->create(
        object_states => [
            $self => [ qw(_shutdown _start get_title_response) ],
        ],
    )->ID();

    return 1;
}

sub PCI_unregister 
{
    my ($self,$irc) = splice @_, 0, 2;
    $poe_kernel->call( $self->{session_id} => '_shutdown' );
    delete $self->{irc};

    return 1;
}

sub _start 
{
    my ($kernel, $self) = @_[KERNEL, OBJECT];
    $self->{session_id} = $_[SESSION]->ID();
    # Make sure our POE session stays around. Could use aliases but that is so messy :)
    $kernel->refcount_increment( $self->{session_id}, __PACKAGE__ );
    return;
}

sub _shutdown 
{
    my ($kernel, $self) = @_[KERNEL, OBJECT];
    $kernel->alarm_remove_all();
    $kernel->refcount_decrement( $self->{session_id}, __PACKAGE__ );
    $kernel->call( 'page_title_ua' => 'shutdown' );

    return;
}

sub S_public
{ 
    my ($self,$irc,) = splice @_, 0, 2;
    my $who = ${ $_[0] };
    my $channel = ${ $_[1] }->[0];
    my $what = ${ $_[2] };

    my @urls = $what =~ /($RE{URI}{HTTP})/g;
    #my $finder = URI::Find::Schemeless->new( sub { push @urls, shift } );
    #$finder->find( \$what );
    print STDERR "Looking for: " . Data::Dumper::Dumper($what, \@urls);
    return PCI_EAT_NONE unless scalar @urls;

    print STDERR "Making UA for $urls[0]\n";

    print STDERR "Grabbing $urls[0]\n";
    my $args = {
        channel => $channel, 
        irc_session => $irc->session_id(),
    };
    my $request = HTTP::Request->new( GET => $urls[0] );

    print STDERR "Calling directly\n";
    $poe_kernel->call($self->{session_id}, 'get_title_response', undef); 
    print STDERR "Making Post\n";
    $poe_kernel->post('page_title_ua', 'request','get_title_response', $request, $args);
    print STDERR "Returning eat none\n";
    return PCI_EAT_NONE;
}

sub response_get_title_response
{
    print STDERR "in response_get_title_response()\n";
    return get_title_response(@_);
}
    
sub get_title_response
{
    print STDERR "in get_title_response()\n";
    my ($kernel, $self, $request_packet, $response_packet) = @_[KERNEL, OBJECT, ARG0, ARG1];
    if (!$response_packet)
    {
        print STDERR "No request\n";
        return;
    }
    my $args = $request_packet->[1];
    # HTTP::Request
    my $request_object  = $request_packet->[0];

    # HTTP::Response
    my $resp = $response_packet->[0];

    print STDERR "got: ", $resp->content(), "\n";

    my $title = "";
    if($resp->is_success()) {
        ( $title ) = $resp->decoded_content =~ m|<title[^>]*>(.+?)</title>|si;
    } else {
        #$irc->yield( privmsg => $channel => "Error getting url: ". $resp->message());
    }
    print STDERR "got title - $title\n";
    #$irc->yield( privmsg => $channel => $title);
    $kernel->post( delete $args->{irc_session}, 'privmsg', delete $args->{channel}, $title);
}

=cut
sub _make_response_message 
{
    my $self   = shift;
    my $in_ref = shift;
    return [$in_ref->{error}] if exists $in_ref->{error};

    defined $in_ref->{title}
        and $in_ref->{title} =~ s/\s/ /g;

    return [to_utf8($in_ref->{title})];
    return [$in_ref->{title}];
}
=cut

=cut
# http://search.cpan.org/~hinrik/POE-Component-IRC-6.59/lib/POE/Component/IRC/Cookbook/Translator.pod
# Some IRC users use CP1252, some use UTF-8. Let's decode it properly.
sub to_utf8 {
    my ($line) = @_;
    my $utf8 = guess_encoding($line, 'utf8');
    return ref $utf8 ? decode('utf8', $line) : decode('cp1252', $line);
}
=cut

1;
