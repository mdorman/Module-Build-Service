package Module::Build::Service::Base;
# ABSTRACT: Base class for service implementations

use IPC::Run qw{run};
use Log::Any qw{$log};
use Moo;

=begin Pod::Coverage

BUILD
DEMOLISH
run_hook

=end Pod::Coverage

=head1 SYNOPSIS

  package Module::Build::Service::foo;

  use Moo;
  extends 'Module::Build::Service::Base';
  sub _build_log { ',,foo.log' }

=head1 DESCRIPTION

This is the base class for all services defined for
C<Module::Build::Service::*>.

Each service based on this class will, at runtime, look for various
hooks to be defined in the user's subclass of
C<Module::Build::Service>, and run them at the appropriate time.

The hooks are:

=over

=item SERVICE_L<service_name>_pre_start_hook

=item SERVICE_L<service_name>_post_start_hook

=item SERVICE_L<service_name>_pre_stop_hook

=item SERVICE_L<service_name>_post_stop_hook

=back

=cut

has '_builder' => (is => 'ro',
                   isa => sub {$_[0]->isa ('Module::Build::Service')},
                   required => 1);

=attr log

Where to log output from the service executable.  Defaults to
C<_build/mbs/log/E<lt>service_nameE<gt>.log>.

=cut

has 'log' => (is => 'lazy');

sub _build_log {
    my ($self) = @_;
    $self->service_name . ".log";
}

=attr service_name

A sensible identifier for the service.  Defaults to the name of the
package after removing Module::Build::Service::

=cut

has 'service_name' => (is => 'lazy');
sub _build_service_name {
    my ($self) = @_;
    my $name = ref $self;
    $log->tracef ("Module name is %s", $name);
    ($name =~ m/^Module::Build::Service::(.+)$/)[0];
}

=pod

For each attribute, you can either pass in a value when instantiating
the object, or you can define a C<_build_E<lt>attributeE<gt>>
subroutine that will provide (or calculate) the appropriate value.

=cut

# Starts the service on object creation, making sure to run the
# appropriate hooks.
sub BUILD {
    my ($self) = @_;
    $log->tracef ("Checking for pre_start hooks for %s", $self->service_name);
    $self->run_hook ("start", "pre");
    $log->tracef ("Starting service %s", $self->service_name);
    $self->start_service;
    $log->tracef ("Checking for post_start hooks for %s", $self->service_name);
    $self->run_hook ("start", "post");
}

# Stops the service on object destruction, making sure to run the
# appropriate hooks.
sub DEMOLISH {
    my ($self) = @_;
    $log->tracef ("Checking for pre_stop hooks for %s", $self->service_name);
    $self->run_hook ("stop", "pre");
    $log->trace ("Stopping service %s", $self->service_name);
    $self->stop_service;
    $log->tracef ("Checking for post_stop hooks for %s", $self->service_name);
    $self->run_hook ("stop", "post");
}

# See whether the C<_builder> instance has the appropriate hook
# method, and if so, invoke it.
sub run_hook {
    my ($self, $action, $modifier) = @_;
    my $hook = join "_", "SERVICE", $self->service_name, $modifier, $action, "hook";
    $log->tracef ("Looking for hook %s", $hook);
    if ($self->_builder->can ($hook)) {
        $log->tracef ("Running %s", $hook);
        $self->_builder->$hook ($self);
    }
}

=method run_process

Run the given command line (with a fully qualified binary), and return
the result, as well as any output.

=cut

sub run_process {
    my ($self, @args) = @_;
    my $output;
    my $result = run \@args, \undef, '>&', \$output;
    return $result, $output;
}

1;
