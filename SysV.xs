#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/types.h>
#ifdef __linux__
#include <asm/page.h>
#endif
#if defined(HAS_MSG) || defined(HAS_SEM) || defined(HAS_SHM)
#include <sys/ipc.h>
#ifdef HAS_MSG
#include <sys/msg.h>
#endif
#ifdef HAS_SEM
#include <sys/sem.h>
#endif
#ifdef HAS_SHM
#include <sys/shm.h>
# ifndef HAS_SHMAT_PROTOTYPE
    extern Shmat_t shmat _((int, char *, int));
# endif
#endif
#endif

#ifndef newCONSTSUB
static void
newCONSTSUB(stash,name,sv)
    HV *stash;
    char *name;
    SV *sv;
{
#ifdef dTHR
    dTHR;
#endif
    U32 oldhints = hints;
    HV *old_cop_stash = curcop->cop_stash;
    HV *old_curstash = curstash;
    line_t oldline = curcop->cop_line;
    curcop->cop_line = copline;

    hints &= ~HINT_BLOCK_SCOPE;
    if(stash)
	curstash = curcop->cop_stash = stash;

    newSUB(
	start_subparse(FALSE, 0),
	newSVOP(OP_CONST, 0, newSVpv(name,0)),
	newSVOP(OP_CONST, 0, &sv_no),	/* SvPV(&sv_no) == "" -- GMB */
	newSTATEOP(0, Nullch, newSVOP(OP_CONST, 0, sv))
    );

    hints = oldhints;
    curcop->cop_stash = old_cop_stash;
    curstash = old_curstash;
    curcop->cop_line = oldline;
}
#endif

MODULE=IPC::SysV	PACKAGE=IPC::Msg::stat

PROTOTYPES: ENABLE

void
pack(obj)
    SV	* obj
PPCODE:
{
    SV *sv;
    struct msqid_ds ds;
    AV *list = (AV*)SvRV(obj);
    sv = *av_fetch(list,0,TRUE); ds.msg_perm.uid = SvIV(sv);
    sv = *av_fetch(list,1,TRUE); ds.msg_perm.gid = SvIV(sv);
    sv = *av_fetch(list,4,TRUE); ds.msg_perm.mode = SvIV(sv);
    sv = *av_fetch(list,6,TRUE); ds.msg_qbytes = SvIV(sv);
    ST(0) = sv_2mortal(newSVpv((char *)&ds,sizeof(ds)));
    XSRETURN(1);
}

void
unpack(obj,buf)
    SV * obj
    SV * buf
PPCODE:
{
    STRLEN len;
    SV **sv_ptr;
    struct msqid_ds *ds = (struct msqid_ds *)SvPV(buf,len);
    AV *list = (AV*)SvRV(obj);
    if (len != sizeof(*ds)) {
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
}

MODULE=IPC::SysV	PACKAGE=IPC::Semaphore::stat

void
unpack(obj,ds)
    SV * obj
    SV * ds
PPCODE:
{
    STRLEN len;
    AV *list = (AV*)SvRV(obj);
    struct semid_ds *data = (struct semid_ds *)SvPV(ds,len);
    if(!sv_isa(obj, "IPC::Semaphore::stat"))
	croak("method %s not called a %s object",
		"unpack","IPC::Semaphore::stat");
    if (len != sizeof(*data)) {
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
}

void
pack(obj)
    SV	* obj
PPCODE:
{
    SV **sv_ptr;
    SV *sv;
    struct semid_ds ds;
    AV *list = (AV*)SvRV(obj);
    if(!sv_isa(obj, "IPC::Semaphore::stat"))
	croak("method %s not called a %s object",
		"pack","IPC::Semaphore::stat");
    if((sv_ptr = av_fetch(list,0,TRUE)) && (sv = *sv_ptr))
	ds.sem_perm.uid = SvIV(*sv_ptr);
    if((sv_ptr = av_fetch(list,1,TRUE)) && (sv = *sv_ptr))
	ds.sem_perm.gid = SvIV(*sv_ptr);
    if((sv_ptr = av_fetch(list,2,TRUE)) && (sv = *sv_ptr))
	ds.sem_perm.cuid = SvIV(*sv_ptr);
    if((sv_ptr = av_fetch(list,3,TRUE)) && (sv = *sv_ptr))
	ds.sem_perm.cgid = SvIV(*sv_ptr);
    if((sv_ptr = av_fetch(list,4,TRUE)) && (sv = *sv_ptr))
	ds.sem_perm.mode = SvIV(*sv_ptr);
    if((sv_ptr = av_fetch(list,5,TRUE)) && (sv = *sv_ptr))
	ds.sem_ctime = SvIV(*sv_ptr);
    if((sv_ptr = av_fetch(list,6,TRUE)) && (sv = *sv_ptr))
	ds.sem_otime = SvIV(*sv_ptr);
    if((sv_ptr = av_fetch(list,7,TRUE)) && (sv = *sv_ptr))
	ds.sem_nsems = SvIV(*sv_ptr);
    ST(0) = sv_2mortal(newSVpv((char *)&ds,sizeof(ds)));
    XSRETURN(1);
}

BOOT:
{
    HV *stash = gv_stashpvn("IPC::SysV", 9, TRUE);
    /*
     * constant subs for IPC::SysV
     */
#ifdef GETVAL
        newCONSTSUB(stash,"GETVAL", newSViv(GETVAL));
#endif
#ifdef GETPID
        newCONSTSUB(stash,"GETPID", newSViv(GETPID));
#endif
#ifdef GETNCNT
        newCONSTSUB(stash,"GETNCNT", newSViv(GETNCNT));
#endif
#ifdef GETZCNT
        newCONSTSUB(stash,"GETZCNT", newSViv(GETZCNT));
#endif
#ifdef GETALL
        newCONSTSUB(stash,"GETALL", newSViv(GETALL));
#endif
#ifdef IPC_ALLOC
        newCONSTSUB(stash,"IPC_ALLOC", newSViv(IPC_ALLOC));
#endif
#ifdef IPC_CREAT
        newCONSTSUB(stash,"IPC_CREAT", newSViv(IPC_CREAT));
#endif
#ifdef IPC_EXCL
        newCONSTSUB(stash,"IPC_EXCL", newSViv(IPC_EXCL));
#endif
#ifdef IPC_LOCKED
        newCONSTSUB(stash,"IPC_LOCKED", newSViv(IPC_LOCKED));
#endif
#ifdef IPC_M
        newCONSTSUB(stash,"IPC_M", newSViv(IPC_M));
#endif
#ifdef IPC_NOERROR
        newCONSTSUB(stash,"IPC_NOERROR", newSViv(IPC_NOERROR));
#endif
#ifdef IPC_NOWAIT
        newCONSTSUB(stash,"IPC_NOWAIT", newSViv(IPC_NOWAIT));
#endif
#ifdef IPC_PRIVATE
        newCONSTSUB(stash,"IPC_PRIVATE", newSViv(IPC_PRIVATE));
#endif
#ifdef IPC_R
        newCONSTSUB(stash,"IPC_R", newSViv(IPC_R));
#endif
#ifdef IPC_RMID
        newCONSTSUB(stash,"IPC_RMID", newSViv(IPC_RMID));
#endif
#ifdef IPC_SET
        newCONSTSUB(stash,"IPC_SET", newSViv(IPC_SET));
#endif
#ifdef IPC_STAT
        newCONSTSUB(stash,"IPC_STAT", newSViv(IPC_STAT));
#endif
#ifdef IPC_W
        newCONSTSUB(stash,"IPC_W", newSViv(IPC_W));
#endif
#ifdef IPC_WANTED
        newCONSTSUB(stash,"IPC_WANTED", newSViv(IPC_WANTED));
#endif
#ifdef MSG_NOERROR
        newCONSTSUB(stash,"MSG_NOERROR", newSViv(MSG_NOERROR));
#endif
#ifdef MSG_FWAIT
        newCONSTSUB(stash,"MSG_FWAIT", newSViv(MSG_FWAIT));
#endif
#ifdef MSG_LOCKED
        newCONSTSUB(stash,"MSG_LOCKED", newSViv(MSG_LOCKED));
#endif
#ifdef MSG_MWAIT
        newCONSTSUB(stash,"MSG_MWAIT", newSViv(MSG_MWAIT));
#endif
#ifdef MSG_WAIT
        newCONSTSUB(stash,"MSG_WAIT", newSViv(MSG_WAIT));
#endif
#ifdef MSG_R
        newCONSTSUB(stash,"MSG_R", newSViv(MSG_R));
#endif
#ifdef MSG_RWAIT
        newCONSTSUB(stash,"MSG_RWAIT", newSViv(MSG_RWAIT));
#endif
#ifdef MSG_STAT
        newCONSTSUB(stash,"MSG_STAT", newSViv(MSG_STAT));
#endif
#ifdef MSG_W
        newCONSTSUB(stash,"MSG_W", newSViv(MSG_W));
#endif
#ifdef MSG_WWAIT
        newCONSTSUB(stash,"MSG_WWAIT", newSViv(MSG_WWAIT));
#endif
#ifdef SEM_A
        newCONSTSUB(stash,"SEM_A", newSViv(SEM_A));
#endif
#ifdef SEM_ALLOC
        newCONSTSUB(stash,"SEM_ALLOC", newSViv(SEM_ALLOC));
#endif
#ifdef SEM_DEST
        newCONSTSUB(stash,"SEM_DEST", newSViv(SEM_DEST));
#endif
#ifdef SEM_ERR
        newCONSTSUB(stash,"SEM_ERR", newSViv(SEM_ERR));
#endif
#ifdef SEM_R
        newCONSTSUB(stash,"SEM_R", newSViv(SEM_R));
#endif
#ifdef SEM_ORDER
        newCONSTSUB(stash,"SEM_ORDER", newSViv(SEM_ORDER));
#endif
#ifdef SEM_UNDO
        newCONSTSUB(stash,"SEM_UNDO", newSViv(SEM_UNDO));
#endif
#ifdef SETVAL
        newCONSTSUB(stash,"SETVAL", newSViv(SETVAL));
#endif
#ifdef SETALL
        newCONSTSUB(stash,"SETALL", newSViv(SETALL));
#endif
#ifdef SHMLBA
        newCONSTSUB(stash,"SHMLBA", newSViv(SHMLBA));
#endif
#ifdef SHM_CLEAR
        newCONSTSUB(stash,"SHM_CLEAR", newSViv(SHM_CLEAR));
#endif
#ifdef SHM_COPY
        newCONSTSUB(stash,"SHM_COPY", newSViv(SHM_COPY));
#endif
#ifdef SHM_DEST
        newCONSTSUB(stash,"SHM_DEST", newSViv(SHM_DEST));
#endif
#ifdef SHM_FMAP
        newCONSTSUB(stash,"SHM_FMAP", newSViv(SHM_FMAP));
#endif
#ifdef SHM_INIT
        newCONSTSUB(stash,"SHM_INIT", newSViv(SHM_INIT));
#endif
#ifdef SHM_LOCK
        newCONSTSUB(stash,"SHM_LOCK", newSViv(SHM_LOCK));
#endif
#ifdef SHM_LOCKED
        newCONSTSUB(stash,"SHM_LOCKED", newSViv(SHM_LOCKED));
#endif
#ifdef SHM_MAP
        newCONSTSUB(stash,"SHM_MAP", newSViv(SHM_MAP));
#endif
#ifdef SHM_NOSWAP
        newCONSTSUB(stash,"SHM_NOSWAP", newSViv(SHM_NOSWAP));
#endif
#ifdef SHM_RDONLY
        newCONSTSUB(stash,"SHM_RDONLY", newSViv(SHM_RDONLY));
#endif
#ifdef SHM_REMOVED
        newCONSTSUB(stash,"SHM_REMOVED", newSViv(SHM_REMOVED));
#endif
#ifdef SHM_RND
        newCONSTSUB(stash,"SHM_RND", newSViv(SHM_RND));
#endif
#ifdef SHM_SHARE_MMU
        newCONSTSUB(stash,"SHM_SHARE_MMU", newSViv(SHM_SHARE_MMU));
#endif
#ifdef SHM_SHATTR
        newCONSTSUB(stash,"SHM_SHATTR", newSViv(SHM_SHATTR));
#endif
#ifdef SHM_SIZE
        newCONSTSUB(stash,"SHM_SIZE", newSViv(SHM_SIZE));
#endif
#ifdef SHM_UNLOCK
        newCONSTSUB(stash,"SHM_UNLOCK", newSViv(SHM_UNLOCK));
#endif
#ifdef SHM_W
        newCONSTSUB(stash,"SHM_W", newSViv(SHM_W));
#endif
#ifdef S_IRUSR
        newCONSTSUB(stash,"S_IRUSR", newSViv(S_IRUSR));
#endif
#ifdef S_IWUSR
        newCONSTSUB(stash,"S_IWUSR", newSViv(S_IWUSR));
#endif
#ifdef S_IRWXU
        newCONSTSUB(stash,"S_IRWXU", newSViv(S_IRWXU));
#endif
#ifdef S_IRGRP
        newCONSTSUB(stash,"S_IRGRP", newSViv(S_IRGRP));
#endif
#ifdef S_IWGRP
        newCONSTSUB(stash,"S_IWGRP", newSViv(S_IWGRP));
#endif
#ifdef S_IRWXG
        newCONSTSUB(stash,"S_IRWXG", newSViv(S_IRWXG));
#endif
#ifdef S_IROTH
        newCONSTSUB(stash,"S_IROTH", newSViv(S_IROTH));
#endif
#ifdef S_IWOTH
        newCONSTSUB(stash,"S_IWOTH", newSViv(S_IWOTH));
#endif
#ifdef S_IRWXO
        newCONSTSUB(stash,"S_IRWXO", newSViv(S_IRWXO));
#endif
}

int
ftok(path, id)
        char *          path
        int             id
    CODE:
#if defined(HAS_SEM) || defined(HAS_SHM)
        key_t k = ftok(path, id);
        ST(0) = k == (key_t) -1 ? &sv_undef : sv_2mortal(newSViv(k));
#else
        DIE(no_func, "ftok");
#endif
