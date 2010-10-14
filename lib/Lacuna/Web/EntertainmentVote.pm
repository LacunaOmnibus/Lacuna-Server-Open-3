package Lacuna::Web::EntertainmentVote;

use Moose;
no warnings qw(uninitialized);
extends qw(Lacuna::Web);
use Lacuna::Util qw(randint);

sub www_default {
    my ($self, $request) = @_;
    my $session = $self->get_session($request->param('session_id'));
    unless (defined $session) {
        confess [ 401, 'You must be logged in to vote.'];
    }
    my $empire = $session->empire;
    unless (defined $empire) {
        confess [401, 'Empire not found.'];
    }
    my $url = $request->param('site_url');
    unless (defined $url) {
        confess [417, 'You need to specify a site.'];
    }
    my $found;
    foreach my $site (@{Lacuna->config->get('voting_sites')}) {
        if ($site->{url} eq $url) {
            $found = 1;
            last;
        }
    }
    unless ($found) {
        confess [404, 'You specified an invalid site.'];
    }
    my $cache = Lacuna->cache;
    $cache->set($url,$empire->id,1, 60*60*24);
    my $ticket = randint(1,99999);
    my $ymd = DateTime->now->ymd;
    if ($ticket > $cache->get('high_vote', $ymd)) {
        $cache->set('high_vote', $ymd, $ticket, 60*60*48);
        $cache->set('high_vote_empire', $ymd, $empire->id, 60*60*48);
    }
    Lacuna->db->resultset('Lacuna::DB::Result::Log::Lottery')->new({
        empire_id   => $empire->id,
        empire_name => $empire->name,
        ip_address  => $request->address,
        api_key     => $empire->current_session->api_key,
        url         => $url,
    })->insert;
    return [$url, { status => 302 }];

}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
