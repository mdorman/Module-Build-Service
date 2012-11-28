package Module::Build::Service::Fork;
# ABSTRACT: Role for process handling in service implementations

use File::Spec qw{};
use IPC::Run qw{start};
use Log::Any qw{$log};
use Moo::Role;
use Try::Tiny;

requires '_build_command';

=head1 SYNOPSIS

  package Module::Build::Service::foo;

  use Moo;
  extends 'Module::Build::Service::Base';
  with 'Module::Build::Service::Fork';

  sub _build_command {
    my ($self) = @_;
    [$self->bin, qw{-f flag1 -g flag2 -h}];
  }
  sub _build_log { ',,foo.log' }
  sub _build_executable { 'foo' }

=head1 DESCRIPTION

This is a role that tries to factor out a lot of boilerplate in
defining services that involve forking an executable to run the
service.

=attr bin

The full path to the binary executable for starting the service.

If this is not specified, we search for L<executable> in L<path>.

=cut

has 'bin' => (is => 'lazy');

# Search the list of directories specified in ->path for the
# executable specified in ->executable.
sub _build_bin {
    my ($self) = @_;
    for my $location (@{$self->path}) {
        my $executable = File::Spec->catfile ($location, $self->executable);
        -x $executable and return $executable;
    }
    die "Couldn't locate " . $self->executable . " binary";
}

=attr command

The command-line for the executable.  Each class including the role
must define it, as there is no sensible default.

=cut

has 'command' => (is => 'lazy',
                  isa => sub {ref $_[0] eq "ARRAY"});

=attr executable

The bare name of the executable that is run to start the service.
Defaults to C<service_name>.

If you specify C<bin> directly (either in a parameter to C<new>, or by
overriding L<_build_bin>), you don't actually need to specify this
unless you use it yourself, as it is only used when trying to generate
L<bin> automatically.

=cut

has 'executable' => (is => 'lazy');

sub _build_executable {
    my ($self) = @_;
    $self->service_name
}

=attr path

The list of directories in which we should search for the executable.
The default is C</usr/sbin> and C</usr/local/sbin>.

If you specify C<bin> directly (either in a parameter to C<new>, or by
overriding L<_build_bin>), you don't actually need to specify this
unless you use it yourself, as it is only used when trying to generate
L<bin> automatically.

=cut

has 'path' => (is => 'lazy',
               isa => sub {ref $_[0] eq "ARRAY"});

# Specify our default list of directories to search
sub _build_path {
    ['/usr/sbin', '/usr/local/sbin'];
}

has 'handle' => (is => 'rwp');

=method start_service

A default implementation of C<start_service> that starts the
contents of C<command>.

=cut

sub start_service {
    my ($self) = @_;
    $log->tracef ("%s service starting", $self->service_name);
    try {
        my @output = (\undef);
        if (my $logfile = $self->log) {
            $log->tracef ("%s base logfile is %s", $self->service_name, $logfile);
            $logfile = File::Spec->catfile ($self->_builder->mbs_log_dir, $self->log) unless substr $logfile, 0, 1 eq '/';
            push @output, '>>', $logfile, '2>', $logfile;
        }
        $log->tracef ("%s output is %s", $self->service_name, \@output);
        my $handle = start $self->command, @output or die $?;
        $self->_set_handle ($handle);
        $log->tracef ("%s service started", $self->service_name);
    } catch {
        $log->criticalf ("%s service failed: %s", $self->service_name, $_);
        die $_;
    };
}

=method stop_service

A default implementation of C<stop_service> that just terminates the child
process.  Generally adequate.  It can be overridden or modified as
appropriate.

=cut

sub stop_service {
    my ($self) = @_;
    $log->tracef ("%s service stopping", $self->service_name);
    try {
        $self->handle->kill_kill;
        $log->tracef ("%s service stopped", $self->service_name);
        1;
    } catch {
        0;
    };
}

1;
