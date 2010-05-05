package Lacuna::DB::Result::Body::Planet::P16;

use Moose;
extends 'Lacuna::DB::Result::Body::Planet';


use constant image => 'p16';
use constant surface => 'surface-c';

use constant water => 5000;

# resource concentrations
use constant rutile => 600;

use constant chromite => 400;

use constant galena => 200;

use constant uraninite => 800;

use constant goethite => 300;

use constant halite => 700;

use constant trona => 900;

use constant sulfur => 100;

use constant kerogen => 2700;

use constant anthracite => 3300;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

