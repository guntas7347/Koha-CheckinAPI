package Koha::Plugin::Com::Guntas::CheckinAPI;

use Modern::Perl;
use base qw(Koha::Plugins::Base);

our $metadata = {
    name            => 'Checkin API',
    author          => 'Guntas Singh',
    date_authored   => '2026-03-29',
    date_updated    => '2026-03-29',
    minimum_version => '24.11.00.000',
    maximum_version => undef,
    version         => '1.2',
    description     => 'Checkin API for Koha'
};

sub new {
    my ( $class, $args ) = @_;
    $args->{metadata} = $metadata;
    $args->{metadata}->{class} = $class;
    my $self = $class->SUPER::new($args);
    return $self;
}

sub api_routes {
    my ( $self, $args ) = @_;

    my $spec_dir = $self->mbf_dir();

    my $schema = JSON::Validator::Schema::OpenAPIv2->new;

    my $spec = $schema->resolve("file://$spec_dir/openapi.json");

    return $self->_convert_refs_to_absolute(
        $spec->data->{paths},
        "file://$spec_dir/"
    );
}

sub api_namespace {
    my ( $self ) = @_;

    return 'guntas';
}


# Helpers
sub _convert_refs_to_absolute {
    my ( $self, $hashref, $path_prefix ) = @_;
    foreach my $key (keys %{ $hashref }) {
        if ($key eq '$ref') {
            if ($hashref->{$key} =~ /^\./) {
                $hashref->{$key} = $path_prefix . $hashref->{$key};
            }
        } elsif (ref $hashref->{$key} eq 'HASH' ) {
            $hashref->{$key} = $self->_convert_refs_to_absolute($hashref->{$key}, $path_prefix);
        } elsif (ref($hashref->{$key}) eq 'ARRAY') {
            $hashref->{$key} = $self->_convert_array_refs_to_absolute($hashref->{$key}, $path_prefix);
        }
    }
    return $hashref;
}

sub _convert_array_refs_to_absolute {
    my ( $self, $arrayref, $path_prefix ) = @_;
    my @res;
    foreach my $item (@{ $arrayref }) {
        if (ref($item) eq 'HASH') {
            $item = $self->_convert_refs_to_absolute($item, $path_prefix);
        }
        push @res, $item;
    }
    return \@res;
}

1;