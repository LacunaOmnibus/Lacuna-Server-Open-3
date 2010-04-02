package Lacuna::DB::Building::Energy::Singularity;

use Moose;
extends 'Lacuna::DB::Building::Energy';

use constant controller_class => 'Lacuna::Building::Singularity';

use constant image => 'singularity';

use constant university_prereq => 15;

use constant name => 'Singularity Energy Plant';

use constant food_to_build => 1000;

use constant energy_to_build => 1105;

use constant ore_to_build => 1400;

use constant water_to_build => 1100;

use constant waste_to_build => 1475;

use constant time_to_build => 1200;

use constant food_consumption => 27;

use constant energy_consumption => 350;

use constant energy_production => 1900;

use constant ore_consumption => 23;

use constant water_consumption => 25;

use constant waste_production => 90;



no Moose;
__PACKAGE__->meta->make_immutable;
