################################################################################
#
#  $Revision: 1 $
#  $Author: mhx $
#  $Date: 2007/10/13 16:07:25 +0100 $
#
################################################################################
#
#  Version 2.x, Copyright (C) 2007, Marcus Holland-Moritz <mhx@cpan.org>.
#  Version 1.x, Copyright (C) 1997, Graham Barr <gbarr@pobox.com>.
#
#  This program is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
################################################################################

package IPC::SharedMem;

use IPC::SysV qw(IPC_STAT IPC_RMID shmat shmdt memread memwrite);
use strict;
use vars qw($VERSION);
use Carp;

$VERSION = do { my @r = '$Snapshot: /IPC-SysV/1.99_03 $' =~ /(\d+\.\d+(?:_\d+)?)/; @r ? $r[0] : '9.99' };
$VERSION = eval $VERSION;

# Figure out if we have support for native sized types
my $N = do { my $foo = eval { pack "L!", 0 }; $@ ? '' : '!' };

{
    package IPC::SharedMem::stat;

    use Class::Struct qw(struct);

    struct 'IPC::SharedMem::stat' => [
	uid	=> '$',
	gid	=> '$',
	cuid	=> '$',
	cgid	=> '$',
	mode	=> '$',
	segsz	=> '$',
	lpid	=> '$',
	cpid	=> '$',
	nattch	=> '$',
	atime	=> '$',
	dtime	=> '$',
	ctime	=> '$',
    ];
}

sub new
{
  @_ == 4 or croak 'IPC::SharedMem->new(KEY, SIZE, FLAGS)';
  my($class, $key, $size, $flags) = @_;

  my $id = shmget $key, $size, $flags or return undef;

  bless { _id => $id, _addr => undef, _isrm => 0 }, $class
}

sub id
{
  my $self = shift;
  $self->{_id};
}

sub addr
{
  my $self = shift;
  $self->{_addr};
}

sub stat
{
  my $self = shift;
  my $data = '';
  shmctl $self->id, IPC_STAT, $data or return undef;
  IPC::SharedMem::stat->new->unpack($data);
}

sub attach
{
  @_ >= 1 && @_ <= 2 or croak '$shm->attach([FLAG])';
  my($self, $flag) = @_;
  defined $self->addr and return undef;
  $self->{_addr} = shmat($self->id, undef, $flag || 0);
  defined $self->addr;
}

sub detach
{
  my $self = shift;
  defined $self->addr or return undef;
  defined shmdt($self->addr);
}

sub remove
{
  my $self = shift;
  return undef if $self->is_removed;
  my $rv = shmctl $self->id, IPC_RMID, 0;
  $self->{_isrm} = 1 if $rv;
  return $rv;
}

sub is_removed
{
  my $self = shift;
  $self->{_isrm};
}

sub read
{
  @_ == 3 or croak '$shm->read(POS, SIZE)';
  my($self, $pos, $size) = @_;
  my $buf = '';
  if (defined $self->addr) {
    memread($self->addr, $buf, $pos, $size) or return undef;
  }
  else {
    shmread($self->id, $buf, $pos, $size) or return undef;
  }
  $buf;
}

sub write
{
  @_ == 4 or croak '$shm->write(STRING, POS, SIZE)';
  my($self, $str, $pos, $size) = @_;
  if (defined $self->addr) {
    return memwrite($self->addr, $str, $pos, $size);
  }
  else {
    return shmwrite($self->id, $str, $pos, $size);
  }
}

1;

__END__

=head1 NAME

IPC::SharedMem - SysV Shared Memory IPC object class

=head1 SYNOPSIS

    use IPC::SysV qw(IPC_PRIVATE S_IRUSR S_IWUSR);
    use IPC::SharedMem;

    $msg = new IPC::Msg(IPC_PRIVATE, S_IRUSR | S_IWUSR);

    $msg->snd(pack("l! a*",$msgtype,$msg));

    $msg->rcv($buf,256);

    $ds = $msg->stat;

    $msg->remove;

=head1 DESCRIPTION

A class providing an object based interface to SysV IPC message queues.

=head1 METHODS

=over 4

=item new ( KEY , FLAGS )

Creates a new message queue associated with C<KEY>. A new queue is
created if

=over 4

=item *

C<KEY> is equal to C<IPC_PRIVATE>

=item *

C<KEY> does not already  have  a  message queue
associated with it, and C<I<FLAGS> & IPC_CREAT> is true.

=back

On creation of a new message queue C<FLAGS> is used to set the
permissions.  Be careful not to set any flags that the Sys V
IPC implementation does not allow: in some systems setting
execute bits makes the operations fail.

=item id

Returns the system message queue identifier.

=item rcv ( BUF, LEN [, TYPE [, FLAGS ]] )

Read a message from the queue. Returns the type of the message read.
See L<msgrcv>.  The  BUF becomes tainted.

=item remove

Remove the shared memory from the system or mark it as removed.

=item snd ( TYPE, MSG [, FLAGS ] )

Place a message on the queue with the data from C<MSG> and with type C<TYPE>.
See L<msgsnd>.

=item stat

Returns an object of type C<IPC::SharedMem::stat> which is a sub-class
of C<Class::Struct>. It provides the following fields. For a description
of these fields see you system documentation.

    uid
    gid
    cuid
    cgid
    mode
    segsz
    lpid
    cpid
    nattach
    atime
    dtime
    ctime

=back

=head1 SEE ALSO

L<IPC::SysV> L<Class::Struct>

=head1 AUTHORS

Graham Barr <gbarr@pobox.com>
Marcus Holland-Moritz <mhx@cpan.org>

=head1 COPYRIGHT

Version 2.x, Copyright (C) 2007, Marcus Holland-Moritz.

Version 1.x, Copyright (c) 1997, Graham Barr.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

