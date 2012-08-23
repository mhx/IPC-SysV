################################################################################
#
#  $Revision: 9 $
#  $Author: mhx $
#  $Date: 2007/10/13 04:14:11 +0100 $
#
################################################################################
#
#  Version 2.x, Copyright (C) 2007, Marcus Holland-Moritz <mhx@cpan.org>.
#  Version 1.x, Copyright (C) 1999, Graham Barr <gbarr@pobox.com>.
#
#  This program is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
################################################################################

BEGIN {
  if ($ENV{'PERL_CORE'}) {
    chdir 't' if -d 't';
    @INC = '../lib' if -d '../lib' && -d '../ext';
  }

  require Test::More; import Test::More;
  require Config; import Config;

  if ($ENV{'PERL_CORE'} && $Config{'extensions'} !~ m[\bIPC/SysV\b]) {
    plan(skip_all => 'IPC::SysV was not built');
  }
}

if ($Config{'d_sem'} ne 'define') {
  plan(skip_all => '$Config{d_sem} undefined');
}
elsif ($Config{'d_msg'} ne 'define') {
  plan(skip_all => '$Config{d_msg} undefined');
}

plan(tests => 11);

use IPC::SysV qw(
	SETALL
	IPC_PRIVATE
	IPC_CREAT
	IPC_RMID
	IPC_NOWAIT
	IPC_STAT
	S_IRWXU
	S_IRWXG
	S_IRWXO
);
use IPC::Semaphore;

my $sem = IPC::Semaphore->new(IPC_PRIVATE, 10, S_IRWXU | S_IRWXG | S_IRWXO | IPC_CREAT);

unless (defined $sem) {
  my $err = $!;
  my $info = "IPC::Semaphore->new failed: $err";
  if ($err == &IPC::SysV::ENOSPC) {
    plan(skip_all => $info);
  }
  else {
    die $info;
  }
}

pass('acquired a semaphore');

ok(my $st = $sem->stat,'stat it');

ok($sem->setall( (0) x 10),'set all');

my @sem = $sem->getall;
cmp_ok(join("",@sem),'eq',"0000000000",'get all');

$sem[2] = 1;
ok($sem->setall( @sem ),'set after change');

@sem = $sem->getall;
cmp_ok(join("",@sem),'eq',"0010000000",'get again');

my $ncnt = $sem->getncnt(0);
ok(!$sem->getncnt(0),'procs waiting now');
ok(defined($ncnt),'prev procs waiting');

ok($sem->op(2,-1,IPC_NOWAIT),'op nowait');

ok(!$sem->getncnt(0),'no procs waiting');

END {
  ok($sem->remove,'release') if defined $sem;
}
