#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

static SV *
fetch(AV *av, int i) {
    SV **v=av_fetch(av, i, 0);
    if (v) return *v;
    return &PL_sv_undef;
}

static I32
ixcmp(pTHX_ SV **a, SV **b) {
    return sv_cmp(*a, *b);
}

static I32
ixlcmp(pTHX_ SV **a, SV **b) {
    return sv_cmp_locale(*a, *b);
}

static I32
ixncmp(pTHX_ SV **a, SV **b) {
    NV nv1 = SvNV(*a);
    NV nv2 = SvNV(*b);
    return nv1 < nv2 ? -1 : nv1 > nv2 ? 1 : 0;
}

static I32
ixicmp(pTHX_ SV **a, SV **b) {
    IV iv1 = SvIV(*a);
    IV iv2 = SvIV(*b);
    return iv1 < iv2 ? -1 : iv1 > iv2 ? 1 : 0;
}



MODULE = Sort::Key		PACKAGE = Sort::Key		
PROTOTYPES: DISABLE

void
_keysort(I32 type, AV *keys, AV *values)
PREINIT:
    SV **k;
    SV ***ix;
    IV len;
    IV i;
    I32 (*cmp)(pTHX_ SV **, SV **);
PPCODE:
    switch(type) {
    case 0:
	cmp=&ixcmp;
	break;
    case 1:
	cmp=&ixlcmp;
	break;
    case 2:
	cmp=&ixncmp;
	break;
    case 3:
	cmp=&ixicmp;
	break;
    }
    len=av_len(keys)+1;
    k=AvARRAY(keys);
    New(799, ix, len, SV**);
    for (i=0; i<len; i++) ix[i]=k+i;
    sortsv((SV **)ix, len, (SVCOMPARE_t)cmp);
    for (i=0; i<len; i++) {
	IV j=ix[i]-k;
	SV *val=fetch(values, j);
	if (!av_store(keys, i, SvREFCNT_inc(val))) SvREFCNT_dec(val);
    }
    Safefree(ix);

