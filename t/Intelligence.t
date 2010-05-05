use lib '../lib';
use Test::More tests => 9;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;


my $result;


my $uni = Lacuna::DB::Result::Building::University->new(
    simpledb        => $tester->db,
    x               => 0,
    y               => -1,
    class           => 'Lacuna::DB::Result::Building::University',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 2,
);
$home->build_building($uni);
$uni->finish_upgrade;

$home->ore_capacity(5000);
$home->energy_capacity(5000);
$home->food_capacity(5000);
$home->water_capacity(5000);
$home->bauxite_stored(5000);
$home->algae_stored(5000);
$home->energy_stored(5000);
$home->water_stored(5000);
$home->ore_hour(5000);
$home->energy_hour(5000);
$home->algae_production_hour(5000);
$home->water_hour(5000);
$home->needs_recalc(0);
$home->put;


$result = $tester->post('intelligence', 'build', [$session_id, $home->id, 0, 1]);
ok($result->{result}{building}{id}, "built an intelligence ministry");
my $intelligence = $empire->get_building('Lacuna::DB::Result::Building::Intelligence',$result->{result}{building}{id});
$intelligence->finish_upgrade;

$result = $tester->post('intelligence', 'view', [$session_id, $intelligence->id]);
is($result->{result}{spies}{maximum}, 5, "get spy data");

$result = $tester->post('intelligence', 'train_spy', [$session_id, $intelligence->id, 3]);
is($result->{result}{trained}, 3, "train a spy");

$result = $tester->post('intelligence', 'view_spies', [$session_id, $intelligence->id]);
is($result->{result}{spies}[0]{is_available}, 0, "spy training");
is($result->{result}{possible_assignments}[0], 'Idle', "possible assignments");
my $spy_id = $result->{result}{spies}[0]{id};

$result = $tester->post('intelligence', 'name_spy', [$session_id, $intelligence->id, $spy_id, 'Waldo']);
ok(exists $result->{result}, 'name spy seems to work');

$result = $tester->post('intelligence', 'view_spies', [$session_id, $intelligence->id]);
is($result->{result}{spies}[0]{name}, 'Waldo', "spy naming works");

$result = $tester->post('intelligence', 'burn_spy', [$session_id, $intelligence->id, $spy_id]);
ok(exists$result->{result}, "burn a spy");

my $shipyard = Lacuna::DB::Result::Building::Shipyard->new(
    simpledb        => $tester->db,
    x               => 1,
    y               => 1,
    class           => 'Lacuna::DB::Result::Building::Shipyard',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 5,
);
$home->build_building($shipyard);
$shipyard->finish_upgrade;

my $spaceport = Lacuna::DB::Result::Building::SpacePort->new(
    simpledb        => $tester->db,
    x               => 1,
    y               => 2,
    class           => 'Lacuna::DB::Result::Building::SpacePort',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 5,
    spy_pod_count   => 5,
);
$home->build_building($spaceport);
$spaceport->finish_upgrade;

# need a spy done right now
$tester->db->domain('spies')->insert({
    from_body_id    => $home->id,
    on_body_id      => $home->id,
    task            => 'Idle',
    available_on    => DateTime->now,
    empire_id       => $empire->id,    
});
sleep 2;

$result = $tester->post('spaceport', 'send_spy_pod', [$session_id, $home->id, {body_name=>'Lacuna'}]);
is($result->{error}{code}, 1013, "leave isolationsts alone");


END {
    $tester->cleanup;
}
