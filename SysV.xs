/*******************************************************************************
*
*  $Revision: 26 $
*  $Author: mhx $
*  $Date: 2007/10/13 04:13:17 +0100 $
*
********************************************************************************
*
*  Version 2.x, Copyright (C) 2007, Marcus Holland-Moritz <mhx@cpan.org>.
*  Version 1.x, Copyright (C) 1999, Graham Barr <gbarr@pobox.com>.
*
*  This program is free software; you can redistribute it and/or
*  modify it under the same terms as Perl itself.
*
*******************************************************************************/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newCONSTSUB
#define NEED_sv_2pv_flags
#define NEED_sv_pvn_force_flags
#include "ppport.h"

#include <sys/types.h>

#if defined(HAS_MSG) || defined(HAS_SEM) || defined(HAS_SHM)
#  ifndef HAS_SEM
#    include <sys/ipc.h>
#  endif
#  ifdef HAS_MSG
#    include <sys/msg.h>
#  endif
#  ifdef HAS_SHM
#    if defined(PERL_SCO) || defined(PERL_ISC)
#      include <sys/sysmacros.h>	/* SHMLBA */
#    endif
#    include <sys/shm.h>
#    ifndef HAS_SHMAT_PROTOTYPE
       extern Shmat_t shmat(int, char *, int);
#    endif
#    if defined(HAS_SYSCONF) && defined(_SC_PAGESIZE)
#      undef  SHMLBA /* not static: determined at boot time */
#      define SHMLBA sysconf(_SC_PAGESIZE)
#    elif defined(HAS_GETPAGESIZE)
#      undef  SHMLBA /* not static: determined at boot time */
#      define SHMLBA getpagesize()
#    endif
#  endif
#endif

/* Required to get 'struct pte' for SHMLBA on ULTRIX. */
#if defined(__ultrix) || defined(__ultrix__) || defined(ultrix)
#include <machine/pte.h>
#endif

/* Required in BSDI to get PAGE_SIZE definition for SHMLBA.
 * Ugly.  More beautiful solutions welcome.
 * Shouting at BSDI sounds quite beautiful. */
#ifdef __bsdi__
#  include <vm/vm_param.h>	/* move upwards under HAS_SHM? */
#endif

#ifndef S_IRWXU
#  ifdef S_IRUSR
#    define S_IRWXU (S_IRUSR|S_IWUSR|S_IXUSR)
#    define S_IRWXG (S_IRGRP|S_IWGRP|S_IXGRP)
#    define S_IRWXO (S_IROTH|S_IWOTH|S_IXOTH)
#  else
#    define S_IRWXU 0700
#    define S_IRWXG 0070
#    define S_IRWXO 0007
#  endif
#endif

static void *sv2addr(SV *sv)
{
  if (SvPOK(sv) && SvCUR(sv) == sizeof(void *))
  {
    return *((void **) SvPVX(sv));
  }

  croak("invalid address value");

  return 0;
}

#include "const-c.inc"

MODULE=IPC::SysV	PACKAGE=IPC::Msg::stat

PROTOTYPES: ENABLE

void
pack(obj)
    SV	* obj
  PPCODE:
  {
#ifdef HAS_MSG
    SV *sv;
    struct msqid_ds ds;
    AV *list = (AV*)SvRV(obj);
    sv = *av_fetch(list,0,TRUE); ds.msg_perm.uid = SvIV(sv);
    sv = *av_fetch(list,1,TRUE); ds.msg_perm.gid = SvIV(sv);
    sv = *av_fetch(list,4,TRUE); ds.msg_perm.mode = SvIV(sv);
    sv = *av_fetch(list,6,TRUE); ds.msg_qbytes = SvIV(sv);
    ST(0) = sv_2mortal(newSVpvn((char *) &ds, sizeof(ds)));
    XSRETURN(1);
#else
    croak("System V msgxxx is not implemented on this machine");
#endif
  }

void
unpack(obj,buf)
    SV * obj
    SV * buf
  PPCODE:
  {
#ifdef HAS_MSG
    STRLEN len;
    SV **sv_ptr;
    AV *list = (AV*) SvRV(obj);
    struct msqid_ds *ds = (struct msqid_ds *) SvPV(buf, len);
    if (len != sizeof(*ds))
    {
      croak("Bad arg length for %s, length is %d, should be %d",
      	    "IPC::Msg::stat",
      	    len, sizeof(*ds));
    }
    sv_ptr = av_fetch(list,0,TRUE);
    sv_setiv(*sv_ptr, ds->msg_perm.uid);
    sv_ptr = av_fetch(list,1,TRUE);
    sv_setiv(*sv_ptr, ds->msg_perm.gid);
    sv_ptr = av_fetch(list,2,TRUE);
    sv_setiv(*sv_ptr, ds->msg_perm.cuid);
    sv_ptr = av_fetch(list,3,TRUE);
    sv_setiv(*sv_ptr, ds->msg_perm.cgid);
    sv_ptr = av_fetch(list,4,TRUE);
    sv_setiv(*sv_ptr, ds->msg_perm.mode);
    sv_ptr = av_fetch(list,5,TRUE);
    sv_setiv(*sv_ptr, ds->msg_qnum);
    sv_ptr = av_fetch(list,6,TRUE);
    sv_setiv(*sv_ptr, ds->msg_qbytes);
    sv_ptr = av_fetch(list,7,TRUE);
    sv_setiv(*sv_ptr, ds->msg_lspid);
    sv_ptr = av_fetch(list,8,TRUE);
    sv_setiv(*sv_ptr, ds->msg_lrpid);
    sv_ptr = av_fetch(list,9,TRUE);
    sv_setiv(*sv_ptr, ds->msg_stime);
    sv_ptr = av_fetch(list,10,TRUE);
    sv_setiv(*sv_ptr, ds->msg_rtime);
    sv_ptr = av_fetch(list,11,TRUE);
    sv_setiv(*sv_ptr, ds->msg_ctime);
    XSRETURN(1);
#else
    croak("System V msgxxx is not implemented on this machine");
#endif
  }

MODULE=IPC::SysV	PACKAGE=IPC::Semaphore::stat

void
unpack(obj,ds)
    SV * obj
    SV * ds
PPCODE:
  {
#ifdef HAS_SEM
    STRLEN len;
    AV *list = (AV*) SvRV(obj);
    struct semid_ds *data = (struct semid_ds *) SvPV(ds, len);
    if(!sv_isa(obj, "IPC::Semaphore::stat"))
    {
      croak("method %s not called a %s object",
      	"unpack","IPC::Semaphore::stat");
    }
    if (len != sizeof(*data))
    {
      croak("Bad arg length for %s, length is %d, should be %d",
      	    "IPC::Semaphore::stat",
      	    len, sizeof(*data));
    }
    sv_setiv(*av_fetch(list,0,TRUE), data[0].sem_perm.uid);
    sv_setiv(*av_fetch(list,1,TRUE), data[0].sem_perm.gid);
    sv_setiv(*av_fetch(list,2,TRUE), data[0].sem_perm.cuid);
    sv_setiv(*av_fetch(list,3,TRUE), data[0].sem_perm.cgid);
    sv_setiv(*av_fetch(list,4,TRUE), data[0].sem_perm.mode);
    sv_setiv(*av_fetch(list,5,TRUE), data[0].sem_ctime);
    sv_setiv(*av_fetch(list,6,TRUE), data[0].sem_otime);
    sv_setiv(*av_fetch(list,7,TRUE), data[0].sem_nsems);
    XSRETURN(1);
#else
    croak("System V semxxx is not implemented on this machine");
#endif
  }

void
pack(obj)
    SV	* obj
PPCODE:
  {
#ifdef HAS_SEM
    SV **sv_ptr;
    struct semid_ds ds;
    AV *list = (AV*)SvRV(obj);
    if(!sv_isa(obj, "IPC::Semaphore::stat"))
    {
      croak("method %s not called a %s object",
            "pack","IPC::Semaphore::stat");
    }
    if((sv_ptr = av_fetch(list,0,TRUE)) && *sv_ptr)
      ds.sem_perm.uid = SvIV(*sv_ptr);
    if((sv_ptr = av_fetch(list,1,TRUE)) && *sv_ptr)
      ds.sem_perm.gid = SvIV(*sv_ptr);
    if((sv_ptr = av_fetch(list,2,TRUE)) && *sv_ptr)
      ds.sem_perm.cuid = SvIV(*sv_ptr);
    if((sv_ptr = av_fetch(list,3,TRUE)) && *sv_ptr)
      ds.sem_perm.cgid = SvIV(*sv_ptr);
    if((sv_ptr = av_fetch(list,4,TRUE)) && *sv_ptr)
      ds.sem_perm.mode = SvIV(*sv_ptr);
    if((sv_ptr = av_fetch(list,5,TRUE)) && *sv_ptr)
      ds.sem_ctime = SvIV(*sv_ptr);
    if((sv_ptr = av_fetch(list,6,TRUE)) && *sv_ptr)
      ds.sem_otime = SvIV(*sv_ptr);
    if((sv_ptr = av_fetch(list,7,TRUE)) && *sv_ptr)
      ds.sem_nsems = SvIV(*sv_ptr);
    ST(0) = sv_2mortal(newSVpvn((char *) &ds, sizeof(ds)));
    XSRETURN(1);
#else
    croak("System V semxxx is not implemented on this machine");
#endif
  }

MODULE=IPC::SysV	PACKAGE=IPC::SysV

void
ftok(path, id = &PL_sv_undef)
    const char *path
    SV *id
  PREINIT:
    int proj_id = 1;
    key_t k;
  CODE:
#if defined(HAS_SEM) || defined(HAS_SHM)
    if (SvOK(id))
    {
      if (SvIOK(id))
      {
        proj_id = (int) SvIVX(id);
      }
      else if (SvPOK(id) && SvCUR(id) == sizeof(char))
      {
        proj_id = (int) *SvPVX(id);
      }
      else
      {
        croak("invalid project id");
      }
    }

    k = ftok(path, proj_id);
    ST(0) = k == (key_t) -1 ? &PL_sv_undef : sv_2mortal(newSViv(k));
    XSRETURN(1);
#else
    Perl_die(aTHX_ PL_no_func, "ftok"); return;
#endif

void
memread(addr, sv, pos, size)
    SV *addr
    SV *sv
    int pos
    int size
  CODE:
    void *caddr = sv2addr(addr);
    char *dst;
    if (!SvOK(sv))
    {
      sv_setpvn(sv, "", 0);
    }
    SvPV_force_nolen(sv);
    dst = SvGROW(sv, (STRLEN) size + 1);
    Copy(caddr + pos, dst, size, char);
    SvCUR_set(sv, size);
    *SvEND(sv) = '\0';
    SvSETMAGIC(sv);
#ifndef INCOMPLETE_TAINTS
    /* who knows who has been playing with this memory? */
    SvTAINTED_on(sv);
#endif
    XSRETURN_YES;

void
memwrite(addr, sv, pos, size)
    SV *addr
    SV *sv
    int pos
    int size
  CODE:
    void *caddr = sv2addr(addr);
    STRLEN len;
    const char *src = SvPV_const(sv, len);
    int n = ((int) len > size) ? size : (int) len;
    Copy(src, caddr + pos, n, char);
    if (n < size)
    {
      memzero(caddr + pos + n, size - n);
    }
    XSRETURN_YES;

void
shmat(id, addr, flag)
    int id
    SV *addr
    int flag
  CODE:
#ifdef HAS_SHM
    void *caddr = SvOK(addr) ? sv2addr(addr) : NULL;
    void *shm = (void *) shmat(id, caddr, flag);
    ST(0) = shm == (void *) -1 ? &PL_sv_undef
                               : sv_2mortal(newSVpvn((char *) &shm, sizeof(void *)));
    XSRETURN(1);
#else
    Perl_die(aTHX_ PL_no_func, "shmat"); return;
#endif

void
shmdt(addr)
    SV *addr
  CODE:
#ifdef HAS_SHM
    void *caddr = sv2addr(addr);
    int rv = shmdt(caddr);
    ST(0) = rv == -1 ? &PL_sv_undef : sv_2mortal(newSViv(rv));
    XSRETURN(1);
#else
    Perl_die(aTHX_ PL_no_func, "shmdt"); return;
#endif

INCLUDE: const-xs.inc

