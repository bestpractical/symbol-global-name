
use strict;
use warnings;

use Test::More tests => 4;

{
    package My;

    our $VERSION = '0.1';
    our @ISA = ();
    sub foo { return 1; }

    use Symbol::Global::Name;
    our %res;
    $res{'scalar'} = Symbol::Global::Name->find( \$VERSION );
    $res{'sub'} = Symbol::Global::Name->find( \&foo );
    $res{'array'} = Symbol::Global::Name->find( \@ISA );
    $res{'hash'} = Symbol::Global::Name->find( \%ENV );
}

package main;
is($My::res{'scalar'}, '$My::VERSION', 'found name');
is($My::res{'sub'}, '&My::foo', 'found name');
is($My::res{'array'}, '@My::ISA', 'found name');
is($My::res{'hash'}, '%main::ENV', 'found name');

