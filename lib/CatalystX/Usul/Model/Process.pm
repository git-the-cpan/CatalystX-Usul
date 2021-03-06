# @(#)Ident: ;

package CatalystX::Usul::Model::Process;

use strict;
use version; our $VERSION = qv( sprintf '0.17.%d', q$Rev: 1 $ =~ /\d+/gmx );

use CatalystX::Usul::Moose;
use Class::Usul::IPC;
use CatalystX::Usul::Constants;
use CatalystX::Usul::Functions qw(throw);
use TryCatch;

extends q(CatalystX::Usul::Model);
with    q(CatalystX::Usul::TraitFor::Model::StashHelper);
with    q(CatalystX::Usul::TraitFor::Model::QueryingRequest);

has '_fs_model'   => is => 'lazy', isa => Object,
   default        => sub { $_[ 0 ]->context->model( q(FileSystem) ) },
   init_arg       => undef, reader => 'fs_model';

has '_ipc'        => is => 'lazy', isa => IPCClass,
   default        => sub { Class::Usul::IPC->new( builder => $_[ 0 ]->usul ) },
   handles        => [ qw(process_table run_cmd) ], init_arg => undef,
   reader         => 'ipc';

has '_user_model' => is => 'lazy', isa => Object,
   default        => sub { $_[ 0 ]->context->model( q(UsersUnix) ) },
   init_arg       => undef, reader => 'user_model';

sub proc_table_form {
   my ($self, $ptype) = @_; my ($data, $fss, $text, $users); $ptype ||= 1;

   my $s       = $self->context->stash;
   my $form    = $s->{form}->{name};
   my $user    = $s->{process_params}->{user   };
   my $fsystem = $s->{process_params}->{fsystem};
   my $signals = $s->{process_params}->{signals};
   my $pattern = $self->query_value( q(pattern) ) || NUL;

   try { # Retrieve data from model
      $data = $self->process_table
         ( { fsystem => $fsystem,
             pattern => [ NUL, NUL, $pattern, NUL ]->[ $ptype ],
             type    => $ptype,
             user    => $user } );

      if ($ptype == 1) {
         $users = [ NUL, q(All), @{ $self->user_model->list } ];
      }

      if ($ptype == 3) {
         my $res = $self->fs_model->get_file_systems( $fsystem );

         $fss = [ NUL, @{ $res->file_systems } ];
      }
   }
   catch ($e) { return $self->add_error( $e ) }

   # Add HTML elements items to form
   $self->clear_form( { firstfld => q(ptype) } );

   if ($data->count) {
      $self->add_field( { data   => $data,   id       => q(processes),
                          select => q(left), sortable => TRUE,
                          type   => q(table) } );
   }
   else {
      if ($ptype == 1 || $ptype == 2) {
         if ($user eq q(All)) {
            $text = 'There are no killable processes for any user';
         }
         else { $text = "There are no killable processes for the user $user" }
      }
      else { $text = 'There are no processes on this filesystem' }

      $self->add_field( { text => $text, type => q(note) } );
   }

   $self->group_fields( { id => $form.q(.select) } );

   # Add buttons to form
   $self->add_buttons( qw(Terminate Kill Abort) );

   # Add controls to append div
   $self->add_append( { default  => $ptype,
                        labels   => { 1 => 'All processes',
                                      2 => 'Specific Processes',
                                      3 => 'Processes by filesystem' },
                        name     => q(ptype),
                        prompt   => 'Display&#160;type',
                        onchange => 'submit()',
                        pwidth   => 10,
                        sep      => '&#160;',
                        type     => q(popupMenu),
                        values   => [ NUL, qw(1 2 3) ] } );

   if ($ptype) {
      if ($ptype == 1) {
         $self->add_append( { default   => $user,
                              name      => q(user),
                              onchange  => 'submit()',
                              prompt    => 'Show&#160;users',
                              pwidth    => 10,
                              sep       => '&#160;',
                              type      => q(popupMenu),
                              values    => $users } );
         $pattern and $self->add_hidden( q(pattern), $pattern );
         $fsystem and $self->add_hidden( q(fsystem), $fsystem );
      }
      elsif ($ptype == 2) {
         $self->add_append( { default   => $pattern,
                              maxlength => 64,
                              name      => q(pattern),
                              onblur    => 'submit()',
                              prompt    => 'Pattern',
                              pwidth    => 10,
                              sep       => '&#160;',
                              type      => q(textfield),
                              width     => 15 } );
         $fsystem and $self->add_hidden( q(fsystem), $fsystem );
         $user    and $self->add_hidden( q(user), $user );
      }
      elsif ($ptype == 3) {
         $self->add_append( { default   => $fsystem,
                              name      => q(fsystem),
                              onchange  => 'submit()',
                              prompt    => 'Filesystem',
                              pwidth    => 10,
                              sep       => '&#160;',
                              type      => q(popupMenu),
                              values    => $fss } );
         $pattern and $self->add_hidden( q(pattern), $pattern );
         $user    and $self->add_hidden( q(user), $user );
      }
   }

   $self->add_append( { default  => $signals,
                        labels   => { 1 => 'Process only',
                                      2 => 'Process and children' },
                        name     => q(signals),
                        onchange => 'submit()',
                        prompt   => 'Propagation',
                        pwidth   => 10,
                        sep      => '&#160;',
                        type     => q(popupMenu),
                        values   => [ NUL, 1, 2 ] } );
   return;
}

sub signal_process {
   my $self = shift; my $pids = $self->query_array( q(processes) );

   $pids->[ 0 ] or throw 'Processes not specified';

   my $flag = $self->query_value( q(signals) ) eq q(1) ? TRUE : FALSE;
   my $ref  = { Abort => q(ABRT), Kill => q(KILL), Terminate => q(TERM) };
   my $sig  = $ref->{ $self->context->stash->{_method} || q(Terminate) };

   $self->add_result( $self->ipc->signal_process( $flag, $sig, $pids )->out );
   return TRUE;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 Name

CatalystX::Usul::Model::Process - View and signal processes

=head1 Version

Describes v0.17.$Rev: 1 $

=head1 Synopsis

   package MyApp;

   use Catalyst qw(ConfigComponents...);

   # In the application configuration file
   <component name="Model::Process">
      <parent_classes>CatalystX::Usul::Model::Process</parent_classes>
   </component>

=head1 Description

Displays the process table and allows signals to be sent to selected
processes

=head1 Subroutines/Methods

=head2 proc_table_form

   $self->proc_table_form( $process_type );

Stuffs the stash with the data for the process table screen

=head2 signal_process

   $bool = $self->signal_process;

Send a signal the the selected processes

=head1 Configuration and Environment

None

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<CatalystX::Usul::IPC>

=item L<CatalystX::Usul::Model>

=item L<CatalystX::Usul::TraitFor::Model::QueryingRequest>

=item L<CatalystX::Usul::TraitFor::Model::StashHelper>

=item L<CatalystX::Usul::Moose>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <Support at RoxSoft.co.uk> >>

=head1 License and Copyright

Copyright (c) 2014 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
