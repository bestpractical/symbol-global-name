use 5.008;
use strict;
use warnings;

package Symbol::Global::Name;

our $VERSION = '0.01';

=head1 NAME

Symbol::Global::Name - finds name and type of a global variable

=head1 SYNOPSIS

    package My;
    our $VERSION = '0.1';

    use Symbol::Global::Name;
    print Symbol::Global::Name->find( \$VERSION );

    # prints '$My::VERSION'

=head1 DESCRIPTION

Lookups symbol table to find an element by reference.

=cut
 
our %REF_SYMBOLS = (
    SCALAR => '$',
    ARRAY  => '@',
    HASH   => '%',
    CODE   => '&',
);

=head1 METHODS

=head2 find

    Symbol::Global::Name->find( \$VERSION );
    Symbol::Global::Name->find( reference => \$VERSION );
    Symbol::Global::Name->find( reference => \$VERSION, package => 'My::Package' );

Takes a reference and optional package name. Returns name
of the referenced variable as long as it's in the package
or sub-package and it's a global variable. Returned name
is prefixed with type sigil, eg. '$', '@', '%', '&' or '*'.

=cut

my $last_package = '';
sub find {
    my $self = shift;
    my %args = (
        @_%2? ( reference => @_ ) : (@_),
    );

    my $package = $args{'package'};

    if ( !$package && $last_package ) {
        my $tmp = $self->_find( $args{'reference'}, $last_package );
        return $tmp if $tmp;
    }
    $package ||= 'main::';
    $package .= '::' unless substr( $package, -2 ) eq '::';
    return $self->_find( $args{'reference'}, $package );
}

sub _find {
    my $self = shift;
    my $ref  = shift;
    my $pack = shift;

    no strict 'refs';
    my $name = undef;

    # scan $pack's nametable(hash)
    foreach my $k ( keys %{$pack} ) {

        # The hash for main:: has a reference to itself
        next if $k eq 'main::';

        # if the entry has a trailing '::' then
        # it is a link to another name space
        if ( substr( $k, -2 ) eq '::') {
            $name = $self->_find( $ref, $k );
            return $name if $name;
        }

        # entry of the table with references to
        # SCALAR, ARRAY... and other types with
        # the same name
        my $entry = ${$pack}{$k};
        next unless $entry;

        # get entry for type we are looking for

        # XXX skip references to scalars or other references.
        # Otherwie 5.10 goes boom. may be we should skip any
        # reference
        next if ref($entry) eq 'SCALAR' || ref($entry) eq 'REF';

        my $entry_ref = *{$entry}{ ref($ref) };
        next unless $entry_ref;

        # if references are equal then we've found
        if ( $entry_ref == $ref ) {
            $last_package = $pack;
            return ( $REF_SYMBOLS{ ref($ref) } || '*' ) . $pack . $k;
        }
    }
    return '';
}

=head1 AUTHOR

Ruslan Zakirov E<lt>ruz@bestpractical.comE<gt>

=head1 LICENSE

Under the same terms as perl itself.

=cut

1;
