use lib '../lib';
use strict;
use 5.010;
use List::Util::WeightedChoice qw( choose_weighted );
use Lacuna;
use Lacuna::Util qw(randint);
use DateTime;

my $config = Lacuna->config;
my $db = Lacuna->db;
my $lacunans_have_been_placed = 0;


create_database();
create_species();
open my $star_names, "<", "../var/starnames.txt";
create_star_map();
close $star_names;

sub create_database {
    $db->deploy({ add_drop_table => 1 });
}

sub create_species {
    say "Adding Lacunans.";
    $db->resultset('Lacuna::DB::Result::Species')->new({
        id                      => 1,
        name                    => 'Lacunan',
        description             => 'The economic dieties that control the Lacuna Expanse.',
        min_orbit               => 1,
        max_orbit               => 7,
        manufacturing_affinity  => 1, # cost of building new stuff
        deception_affinity      => 7, # spying ability
        research_affinity       => 1, # cost of upgrading
        management_affinity     => 4, # speed to build
        farming_affinity        => 1, # food
        mining_affinity         => 1, # minerals
        science_affinity        => 1, # energy, propultion, and other tech
        environmental_affinity  => 1, # waste and water
        political_affinity      => 7, # happiness
        trade_affinity          => 7, # speed of cargoships, and amount of cargo hauled
        growth_affinity         => 7, # price and speed of colony ships, and planetary command center start level
    })->insert;
    say "Adding humans.";
    $db->resultset('Lacuna::DB::Result::Species')->new({
        id                      => 2,
        name                    => 'Human',
        description             => 'A race of average intellect, and weak constitution.',
        min_orbit               => 3,
        max_orbit               => 3,
        manufacturing_affinity  => 4, # cost of building new stuff
        deception_affinity      => 4, # spying ability
        research_affinity       => 4, # cost of upgrading
        management_affinity     => 4, # speed to build
        farming_affinity        => 4, # food
        mining_affinity         => 4, # minerals
        science_affinity        => 4, # energy, propultion, and other tech
        environmental_affinity  => 4, # waste and water
        political_affinity      => 4, # happiness
        trade_affinity          => 4, # speed of cargoships, and amount of cargo hauled
        growth_affinity         => 4, # price and speed of colony ships, and planetary command center start level
    })->insert;
}


sub create_star_map {
    my $map_size = $config->get('map_size');
    my ($start_x, $end_x) = @{$map_size->{x}};
    my ($start_y, $end_y) = @{$map_size->{y}};
    my ($start_z, $end_z) = @{$map_size->{z}};
    my $star_count = abs($end_x - $start_x) * abs($end_y - $start_y) * abs($end_z - $start_z);
    my @star_colors = (qw(magenta red green blue yellow white));
    my $made_lacuna = 0;
    say "Adding stars.";
    for my $x ($start_x .. $end_x) {
        say "Start X $x";
        for my $y ($start_y .. $end_y) {
            say "Start Y $y";
            for my $z ($start_z .. $end_z) {
                say "Start Z $z";
                if (rand(100) <= 15) { # 15% chance of no star
                    say "No star at $x, $y, $z!";
                }
                else {
                    my $name = get_star_name();
                    if (!$made_lacuna && $x >= 0 && $y >= 0 && $z >= 0) {
                        $made_lacuna = 1;
                        $name = 'Lacuna';
                    }
                    say "Creating star $name at $x, $y, $z.";
                    my $star = $db->resultset('Lacuna::DB::Result::Star')->new({
                        name        => $name,
                        color       => $star_colors[rand(scalar(@star_colors))],
                        x           => $x,
                        y           => $y,
                        z           => $z,
                    });
                    $star->set_zone_from_xyz;
                    $star->insert;
                    add_bodies($star);
                }
                say "End Z $z";
            }
            say "End Y $y";
        }
        say "End X $x";
    }
}


sub add_bodies {
    my $star = shift;
    my @body_types = ('habitable', 'asteroid', 'gas giant');
    my @body_type_weights = (qw(60 15 15));
    my @planet_classes = qw(Lacuna::DB::Result::Body::Planet::P1 Lacuna::DB::Result::Body::Planet::P2 Lacuna::DB::Result::Body::Planet::P3 Lacuna::DB::Result::Body::Planet::P4
        Lacuna::DB::Result::Body::Planet::P5 Lacuna::DB::Result::Body::Planet::P6 Lacuna::DB::Result::Body::Planet::P7 Lacuna::DB::Result::Body::Planet::P8 Lacuna::DB::Result::Body::Planet::P9
        Lacuna::DB::Result::Body::Planet::P10 Lacuna::DB::Result::Body::Planet::P11 Lacuna::DB::Result::Body::Planet::P12 Lacuna::DB::Result::Body::Planet::P13
        Lacuna::DB::Result::Body::Planet::P14 Lacuna::DB::Result::Body::Planet::P15 Lacuna::DB::Result::Body::Planet::P16 Lacuna::DB::Result::Body::Planet::P17
        Lacuna::DB::Result::Body::Planet::P18 Lacuna::DB::Result::Body::Planet::P19 Lacuna::DB::Result::Body::Planet::P20);
    my @gas_giant_classes = qw(Lacuna::DB::Result::Body::Planet::GasGiant::G1 Lacuna::DB::Result::Body::Planet::GasGiant::G2 Lacuna::DB::Result::Body::Planet::GasGiant::G3
        Lacuna::DB::Result::Body::Planet::GasGiant::G4 Lacuna::DB::Result::Body::Planet::GasGiant::G5);
    my @asteroid_classes = qw(Lacuna::DB::Result::Body::Asteroid::A1 Lacuna::DB::Result::Body::Asteroid::A2 Lacuna::DB::Result::Body::Asteroid::A3
        Lacuna::DB::Result::Body::Asteroid::A4 Lacuna::DB::Result::Body::Asteroid::A5);
    say "\tAdding bodies.";
    for my $orbit (1..7) {
        my $name = $star->name." ".$orbit;
        if (randint(1,100) <= 10) { # 10% chance of no body in an orbit
            say "\tNo body at $name!";
        } 
        else {
            my $type = ($orbit == 3) ? 'habitable' : choose_weighted(\@body_types, \@body_type_weights); # orbit 3 should always be habitable
            say "\tAdding a $type at $name (".$star->x.",".$star->y.",".$star->z.").";
            my $params = {
                name                => $name,
                orbit               => $orbit,
                x                   => $star->x,
                y                   => $star->y,
                z                   => $star->z,
                star_id             => $star->id,
                zone                => $star->zone,
                usable_as_starter   => 0,
            };
            my $body;
            if ($type eq 'habitable') {
                $params->{class} = $planet_classes[rand(scalar(@planet_classes))];
                $params->{size} = ($params->{orbit} == 3) ? randint(35,55) : randint(25,75);
                $params->{usable_as_starter} = ($params->{size} >= 40 && $params->{size} <= 50) ? randint(1,9999) : 0;
            }
            elsif ($type eq 'asteroid') {
                $params->{class} = $asteroid_classes[rand(scalar(@asteroid_classes))];
                $params->{size} = randint(1,10);
            }
            else {
                $params->{class} = $gas_giant_classes[rand(scalar(@gas_giant_classes))];
                $params->{size} = randint(70,121);
            }
            $body = $db->resultset('Lacuna::DB::Result::Body')->new($params);
            $body->insert;
            if ($body->isa('Lacuna::DB::Result::Body::Planet') && !$body->isa('Lacuna::DB::Result::Body::Planet::GasGiant')) {
                if ($star->name eq 'Lacuna' && !$lacunans_have_been_placed) {
                    create_lacunan_home_world($body);
                    next;
                }
                else {
                    add_features($body);
                }
            }
        }
    }
}

sub add_features {
    my $body = shift;
    say "\t\tAdding features to body.";
    my $now = DateTime->now;
    foreach  my $x (-3, -1, 2, 4, 1) {
        my $chance = randint(1,100);
        my $y = randint(-5,5);
        if ($chance <= 5) {
            say "\t\t\tAdding lake.";
            $db->resultset('Lacuna::DB::Result::Building')->new({
                date_created    => $now,
                level           => 1,
                x               => $x,
                y               => $y,
                class           => 'Lacuna::DB::Result::Building::Permanent::Lake',
                body_id         => $body->id,
            })->insert;
        }
        elsif ($chance > 45 && $chance <= 50) {
            say "\t\t\tAdding rocky outcropping.";
            $db->resultset('Lacuna::DB::Result::Building')->new({
                date_created    => $now,
                level           => 1,
                x               => $x,
                y               => $y,
                class           => 'Lacuna::DB::Result::Building::Permanent::RockyOutcrop',
                body_id         => $body->id,
            })->insert;
        }
        elsif ($chance > 95) {
            say "\t\t\tAdding crater.";
            $db->resultset('Lacuna::DB::Result::Building')->new({
                date_created    => $now,
                level           => 1,
                x               => $x,
                y               => $y,
                class           => 'Lacuna::DB::Result::Building::Permanent::Crater',
                body_id         => $body->id,
            })->insert;
        }
    }
}


sub create_lacunan_home_world {
    my $body = shift;
    $body->update({name=>'Lacuna'});
    say "\t\t\tMaking this the Lacunans home world.";
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->new({
        id                  => 1,
        name                => 'Lacuna Expanse Corp',
        date_created        => DateTime->now,
        species_id          => 1,
        status_message      => 'Will trade for Essentia.',
        password            => Lacuna::DB::Result::Empire->encrypt_password(rand(99999999)),
    });
    $empire->insert;
    $empire->found($body);
    $lacunans_have_been_placed = 1;    
}



sub get_star_name {
    my $name = <$star_names>;
    chomp $name;
    return $name;
}

