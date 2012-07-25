package Module::Build::Service::memcached;
# ABSTRACT: Service implementation for memcached

use Log::Any qw{$log};
use Moo;
extends 'Module::Build::Service::Base';
with 'Module::Build::Service::Fork';

=head1 SYNOPSIS

  $self->services ([[memcached => 1]]);

=head1 DESCRIPTION

This is a service definition for memcached.  By default we start the
service listening to on localhost:50098 with no config.  You can use
the following arguments to the service definition to customize this.

=attr command

The command line to use when invoking memcached.  Defaults to:

  <bin> -l <listen> -p <port> -vv

=cut

sub _build_command {
    my ($self) = @_;
    [$self->bin, "-l", $self->listen, "-p", $self->port, "-vv"];
}

=attr listen

If you just want memcached to listen on a different address, specify
the address here.

=cut

has 'listen' => (is => 'lazy');
sub _build_listen {'127.0.0.1'}

=attr path

The path(s) in which to look for the memcached executable.  Defaults to
is C</usr/sbin>, C</usr/local/sbin>, C</usr/bin> and C</usr/local/bin>.

=cut

sub _build_path {['/usr/sbin', '/usr/local/sbin', '/usr/bin', '/usr/local/bin']}

=attr port

If you just want memcached to listen on a different port, specify the
port here.

=cut

has 'port' => (is => 'lazy',
               isa => sub {$_[0] =~ m/^\d+$/});
sub _build_port {'50098'}

=attr OTHER

See L<Module::Build::Service::Base> and
L<Module::Build::Service::Fork> for more configurable attributes.

=cut

1;
