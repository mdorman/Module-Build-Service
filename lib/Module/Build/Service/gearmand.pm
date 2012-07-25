package Module::Build::Service::gearmand;
# ABSTRACT: Service implementation for gearmand

use Log::Any qw{$log};
use Moo;
extends 'Module::Build::Service::Base';
with 'Module::Build::Service::Fork';

=head1 SYNOPSIS

  $self->services ([[gearmand => 1]]);

=head1 DESCRIPTION

This is a service definition for gearman.  By default we start the
service listening to on localhost:4730 with no config.  You can use
the following arguments to the service definition to customize this.

=attr command

The command line to use when invoking gearmand.  Defaults to:

  <bin> -L <listen> -p <port> --verbose DEBUG

=cut

sub _build_command {
    my ($self) = @_;
    [$self->bin, "-L", $self->listen, "-p", $self->port, "--verbose", "DEBUG"]
}

=attr listen

If you just want gearmand to listen on a different address, specify
the address here.

=cut

has 'listen' => (is => 'lazy');
sub _build_listen {'127.0.0.1'}

=attr port

If you just want gearmand to listen on a different port, specify the
port here.

=cut

has 'port' => (is => 'lazy',
               isa => sub {$_[0] =~ m/^\d+$/});

sub _build_port {'4730'}

=attr OTHER

See L<Module::Build::Service::Base> and
L<Module::Build::Service::Fork> for more configurable attributes.

=cut

1;
