#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_sv_2pvbyte
#include "ppport.h"

#include "src/csnappy_compress.c"
#include "src/csnappy_decompress.c"

MODULE = Compress::Snappy    PACKAGE = Compress::Snappy

PROTOTYPES: ENABLE

SV *
compress (sv)
    SV *sv
PREINIT:
    char *str;
    STRLEN len;
    uint32_t compressed_len;
    void *working_memory;
CODE:
    if (SvROK(sv))
        sv = SvRV(sv);
    if (! SvOK(sv))
        XSRETURN_NO;
    str = SvPVbyte(sv, len);
    if (! len)
        XSRETURN_NO;
    compressed_len = csnappy_max_compressed_length(len);
    if (! compressed_len)
        XSRETURN_UNDEF;
    Newx(working_memory, CSNAPPY_WORKMEM_BYTES, void *);
    if (! working_memory)
        XSRETURN_UNDEF;
    RETVAL = newSV(compressed_len);
    csnappy_compress(str, len, SvPVX(RETVAL), &compressed_len,
                     working_memory, CSNAPPY_WORKMEM_BYTES_POWER_OF_TWO);
    Safefree(working_memory);
    SvCUR_set(RETVAL, compressed_len);
    SvPOK_on(RETVAL);
OUTPUT:
    RETVAL

SV *
decompress (sv)
    SV *sv
ALIAS:
    uncompress = 1
PREINIT:
    char *str;
    STRLEN len;
    uint32_t decompressed_len;
CODE:
    PERL_UNUSED_VAR(ix); /* -W */
    if (SvROK(sv))
        sv = SvRV(sv);
    if (! SvOK(sv))
        XSRETURN_NO;
    str = SvPVbyte(sv, len);
    if (! len)
        XSRETURN_NO;
    if (0 > csnappy_get_uncompressed_length(str, len, &decompressed_len))
        XSRETURN_UNDEF;
    if (! decompressed_len)
        XSRETURN_UNDEF;
    RETVAL = newSV(decompressed_len);
    if (csnappy_decompress(str, len, SvPVX(RETVAL), decompressed_len))
        XSRETURN_UNDEF;
    SvCUR_set(RETVAL, decompressed_len);
    SvPOK_on(RETVAL);
OUTPUT:
    RETVAL
