#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

static SV *
fetch(pTHX_ AV *av, int i) {
    SV **v=av_fetch(av, i, 0);
    if (v) return *v;
    return &PL_sv_undef;
}

static I32
ix_sv_cmp(pTHX_ SV **a, SV **b) {
    return sv_cmp(*a, *b);
}

static I32
ix_rsv_cmp(pTHX_ SV **a, SV **b) {
    return sv_cmp(*b, *a);
}

static I32
ix_lsv_cmp(pTHX_ SV **a, SV **b) {
    return sv_cmp_locale(*a, *b);
}

static I32
ix_rlsv_cmp(pTHX_ SV **a, SV **b) {
    return sv_cmp_locale(*b, *a);
}

static I32
ix_nsv_cmp(pTHX_ SV **a, SV **b) {
    NV nv1 = SvNV(*a);
    NV nv2 = SvNV(*b);
    return nv1 < nv2 ? -1 : nv1 > nv2 ? 1 : 0;
}

static I32
ix_rnsv_cmp(pTHX_ SV **a, SV **b) {
    NV nv1 = SvNV(*b);
    NV nv2 = SvNV(*a);
    return nv1 < nv2 ? -1 : nv1 > nv2 ? 1 : 0;
}

static I32
ix_n_cmp(pTHX_ NV *a, NV *b) {
    NV nv1 = *a;
    NV nv2 = *b;
    return nv1 < nv2 ? -1 : nv1 > nv2 ? 1 : 0;
}

static I32
ix_rn_cmp(pTHX_ NV *a, NV *b) {
    NV nv1 = *b;
    NV nv2 = *a;
    return nv1 < nv2 ? -1 : nv1 > nv2 ? 1 : 0;
}

static I32
ix_isv_cmp(pTHX_ SV **a, SV **b) {
    IV iv1 = SvIV(*a);
    IV iv2 = SvIV(*b);
    return iv1 < iv2 ? -1 : iv1 > iv2 ? 1 : 0;
}

static I32
ix_risv_cmp(pTHX_ SV **a, SV **b) {
    IV iv1 = SvIV(*b);
    IV iv2 = SvIV(*a);
    return iv1 < iv2 ? -1 : iv1 > iv2 ? 1 : 0;
}

static I32
ix_i_cmp(pTHX_ IV *a, IV *b) {
    IV iv1 = *a;
    IV iv2 = *b;
    return iv1 < iv2 ? -1 : iv1 > iv2 ? 1 : 0;
}

static I32
ix_ri_cmp(pTHX_ IV *a, IV *b) {
    IV iv1 = *b;
    IV iv2 = *a;
    return iv1 < iv2 ? -1 : iv1 > iv2 ? 1 : 0;
}

static void *v_alloc(pTHX_ IV n, IV lsize) {
    void *r;
    Newc(799, r, n<<lsize, char, void);
    SAVEFREEPV(r);
    return r;
}

static void *av_alloc(pTHX_ IV n, IV lsize) {
    AV *av=(AV*)sv_2mortal((SV*)newAV());
    av_fill(av, n-1);
    return AvARRAY(av);
}

static void i_store(pTHX_ SV *v, void *to) {
    *((IV*)to)=SvIV(v);
}

static void n_store(pTHX_ SV *v, void *to) {
    *((NV*)to)=SvNV(v);
}

static void sv_store(pTHX_ SV *v, void *to) {
    *((SV**)to)=SvREFCNT_inc(v);
}

#define lsizeof(A) (ilog2(sizeof(A)))


static int ilog2(int i) {
    if (i>256) croak("internal error");
    if (i>128) return 8;
    if (i>64) return 7;
    if (i>32) return 6;
    if (i>16) return 5;
    if (i>8) return 4;
    if (i>4) return 3;
    if (i>2) return 2;
    if (i>1) return 1;
    return 0;
}

/* sorting types:

   0 => string
   1 => locale
   2 => number
   3 => integer

   128 => reverse string
   129 => reverse locale
   130 => reverse number
   131 => reverse integer

*/

typedef IV (*COMPARE_t)(pTHX_ void*, void*);
typedef void (*STORE_t)(pTHX_ SV*, void*);

static void
_keysort(pTHX_ IV type, SV *keygen, SV **values, I32 ax, IV len) {
    dSP;
    if (len) {
	void *keys;
	void **ixkeys;
	IV i;
	SV *old_defsv;
	SV **from, **to;

	IV lsize;
	COMPARE_t cmp;
	STORE_t store;

	switch(type) {
	case 0:
	case 128:
	    if (PL_curcop->op_private & HINT_LOCALE) type = type | 128;
	    break;
	case 2:
	case 130:
	    if (PL_curcop->op_private & HINT_INTEGER) type = type + 1;
	    break;
	}

	switch(type) {
	case 0:
	    cmp = (COMPARE_t)&ix_sv_cmp;
	    lsize = lsizeof(SV*);
	    keys = av_alloc(aTHX_ len, lsize);
	    store = sv_store;
	    break;
	case 1:
	    cmp = (COMPARE_t)&ix_lsv_cmp;
	    lsize = lsizeof(SV*);
	    keys = av_alloc(aTHX_ len, lsize);
	    store = sv_store;
	    break;
	case 2:
	    cmp = (COMPARE_t)&ix_n_cmp;
	    lsize = lsizeof(NV);
	    keys = v_alloc(aTHX_ len, lsize);
	    store = n_store;
	    break;
	case 3:
	    cmp = (COMPARE_t)&ix_i_cmp;
	    lsize = lsizeof(IV);
	    keys = v_alloc(aTHX_ len, lsize);
	    store = i_store;
	    break;
	case 128:
	    cmp = (COMPARE_t)&ix_rsv_cmp;
	    lsize = lsizeof(SV*);
	    keys = av_alloc(aTHX_ len, lsize);
	    store = sv_store;
	    break;
	case 129:
	    cmp = (COMPARE_t)&ix_rlsv_cmp;
	    lsize = lsizeof(SV*);
	    keys = av_alloc(aTHX_ len, lsize);
	    store = sv_store;
	    break;
	case 130:
	    cmp = (COMPARE_t)&ix_rn_cmp;
	    lsize = lsizeof(NV);
	    keys = v_alloc(aTHX_ len, lsize);
	    store = n_store;
	    break;
	case 131:
	    cmp = (COMPARE_t)&ix_ri_cmp;
	    lsize = lsizeof(IV);
	    keys = v_alloc(aTHX_ len, lsize);
	    store = i_store;
	    break;
	default:
	    croak("unsupported sort type %d", type);
	}

	New(799, ixkeys, len, void*);
	SAVEFREEPV(ixkeys);
	old_defsv=DEFSV;
	SAVE_DEFSV;
	for (i=0; i<len; i++) {
	    IV count;
	    SV *current;
	    SV *result;
	    void *target;
	    /* warn("values=%p SP=%p SP-len=%p, &ST(0)=%p\n", values, SP, SP-len, &ST(0)); */
	    ENTER;
	    SAVETMPS;
	    current = values ? values[i] : ST(i+1); /* WARNING: hard coded offset!!! */ 
	    DEFSV = current ? current : sv_2mortal(newSV(0));
	    PUSHMARK(SP);
	    PUTBACK;
	    count = call_sv(keygen, G_SCALAR);
	    SPAGAIN;
	    if (count != 1)
		croak("wrong number of results returned from key generation sub");
	    result = POPs;
	    /* warn("key: %_\n", result); */
	    ixkeys[i] = target = keys+(i<<lsize);
	    (*store)(aTHX_ result, target);
	    FREETMPS;
	    LEAVE;
	}
	DEFSV=old_defsv;
	sortsv((SV**)ixkeys, len, (SVCOMPARE_t)cmp);
	if (values) {
	    from = to = values;
	}
	else {
	    from = &ST(1); /* WARNING: hard coded offset!!! */ 
	    to = &ST(0);
	}
	for(i=0; i<len; i++) {
	    IV j = (ixkeys[i]-keys)>>lsize;
	    ixkeys[i] = from[j];
	}
	for(i=0; i<len; i++) {
	    to[i] = (SV*)ixkeys[i];
	}
    }
}

typedef struct multikey {
    COMPARE_t cmp;
    void *data;
    IV lsize;
} MK;

static IV _multikeycmp(pTHX_ void *a, void *b) {
    MK *keys = (MK*)PL_sortcop;
    IV r = (*(keys->cmp))(aTHX_ a, b);
    if (r) 
	return r;
    else {
	IV ixa = (a-keys->data) >> keys->lsize;
	IV ixb = (b-keys->data) >> keys->lsize;
	COMPARE_t cmp;
	while(1) {
	    keys++;
	    cmp=keys->cmp;
	    if (!cmp)
		return 0;
	    a = keys->data+(ixa<<keys->lsize);
	    b = keys->data+(ixb<<keys->lsize);
	    r = (*cmp)(aTHX_ a, b);
	    if (r)
		return r;
	}
    }
    return 0; /* dead code just to remove warnings from some
	       * compilers */
}

static void
_multikeysort (pTHX_ SV *keygen, SV *keytypes,
	       SV**values, I32 ax, IV len) {
    dSP;
    STRLEN nkeys;
    unsigned char *types=(unsigned char *)SvPV(keytypes, nkeys);

    if (nkeys<1)
	croak("empty multikey type list passed");

    if (len) {
	IV i;
	MK *keys;
	STORE_t *store;
	void **ixkeys;
	SV *old_defsv;
	SV **from, **to;

	New(799, keys, nkeys+1, MK);
	SAVEFREEPV(keys);
	New(799, store, nkeys, STORE_t);
	SAVEFREEPV(store);
	
	for(i=0; i<nkeys; i++) {
	    MK *key = keys+i;
	    switch(types[i]) {
	    case 0:
		key->cmp = (COMPARE_t)&ix_sv_cmp;
		key->lsize = lsizeof(SV*);
		key->data = av_alloc(aTHX_ len, key->lsize);
		store[i] = sv_store;
		break;
	    case 1:
		key->cmp = (COMPARE_t)&ix_lsv_cmp;
		key->lsize = lsizeof(SV*);
		key->data = av_alloc(aTHX_ len, key->lsize);
		store[i] = sv_store;
		break;
	    case 2:
		key->cmp = (COMPARE_t)&ix_n_cmp;
		key->lsize = lsizeof(NV);
		key->data = v_alloc(aTHX_ len, key->lsize);
		store[i] = n_store;
		break;
	    case 3:
		key->cmp = (COMPARE_t)&ix_i_cmp;
		key->lsize = lsizeof(IV);
		key->data = v_alloc(aTHX_ len, key->lsize);
		store[i] = i_store;
		break;
	    case 128:
		key->cmp = (COMPARE_t)&ix_rsv_cmp;
		key->lsize = lsizeof(SV*);
		key->data = av_alloc(aTHX_ len, key->lsize);
		store[i] = sv_store;
		break;
	    case 129:
		key->cmp = (COMPARE_t)&ix_rlsv_cmp;
		key->lsize = lsizeof(SV*);
		key->data = av_alloc(aTHX_ len, key->lsize);
		store[i] = sv_store;
		break;
	    case 130:
		key->cmp = (COMPARE_t)&ix_rn_cmp;
		key->lsize = lsizeof(NV);
		key->data = v_alloc(aTHX_ len, key->lsize);
		store[i] = n_store;
		break;
	    case 131:
		key->cmp = (COMPARE_t)&ix_ri_cmp;
		key->lsize = lsizeof(IV);
		key->data = v_alloc(aTHX_ len, key->lsize);
		store[i] = i_store;
		break;
	    default:
		croak("unsupported sort type %d", types[i]);
	    }
	}

	keys[nkeys].cmp = 0;
	keys[nkeys].data = 0;
	keys[nkeys].lsize = 0;
	    
	New(799, ixkeys, len, void*);
	SAVEFREEPV(ixkeys);
	old_defsv=DEFSV;
	SAVE_DEFSV;
	for (i=0; i<len; i++) {
	    IV count;
	    SV *current;
	    void *target;
	    ENTER;
	    SAVETMPS;
	    current = values ? values[i] : ST(i+2); /* WARNING: hard coded offset!!! */ 
	    DEFSV = current ? current : sv_2mortal(newSV(0));
	    PUSHMARK(SP);
	    PUTBACK;
	    count = call_sv(keygen, G_ARRAY);
	    SPAGAIN;
	    if (count != nkeys)
		croak("wrong number of results returned "
		      "from multikey generation sub "
		      "(%d expected, %d returned)",
		      nkeys, count);
	    while(count-- > 0) {
		SV *result = POPs;
		MK *key = keys+count;
		target = key->data + (i<<key->lsize);
		(*(store[count]))(aTHX_ result, target);
	    }
	    ixkeys[i] = target;
	    FREETMPS;
	    LEAVE;
	}
	DEFSV=old_defsv;
	SAVEVPTR(PL_sortcop);
	PL_sortcop = (OP*)keys;
	sortsv((SV**)ixkeys, len, (SVCOMPARE_t)_multikeycmp);
	if (values) {
	    from = to = values;
	}
	else {
	    from = &ST(2); /* WARNING: hard coded offset!!! */ 
	    to = &ST(0);
	}
	for(i=0; i<len; i++) {
	    IV j = (ixkeys[i]-keys->data)>>keys->lsize;
	    ixkeys[i] = from[j];
	}
	for(i=0; i<len; i++) {
	    to[i] = (SV*)ixkeys[i];
	}
    }
}


MODULE = Sort::Key		PACKAGE = Sort::Key		
PROTOTYPES: ENABLE

void
keysort(SV *keygen, ...)
PROTOTYPE: &@
ALIAS:
    lkeysort = 1
    nkeysort = 2
    ikeysort = 3
    rkeysort = 128
    rlkeysort = 129
    rnkeysort = 130
    rikeysort = 131
PPCODE:
    items--;
    if (items) {
	_keysort(aTHX_ ix, keygen, 0, ax, items);
	SP=&ST(items-1);
    }


void
keysort_inplace(SV *keygen, AV *values)
PROTOTYPE: &\@
PREINIT:
    AV *magic_values=0;
    int len;
ALIAS:
    lkeysort_inplace = 1
    nkeysort_inplace = 2
    ikeysort_inplace = 3
    rkeysort_inplace = 128
    rlkeysort_inplace = 129
    rnkeysort_inplace = 130
    rikeysort_inplace = 131
PPCODE:
    if ((len=av_len(values)+1)) {
	/* warn("ix=%d\n", ix); */
	if (SvMAGICAL(values) || AvREIFY(values)) {
	    int i;
	    magic_values = values;
	    values = (AV*)sv_2mortal((SV*)newAV());
	    av_extend(values, len-1);
	    for (i=0; i<len; i++) {
		SV **currentp = av_fetch(magic_values, i, 0);
		av_store( values, i,
			  ( currentp
			    ? SvREFCNT_inc(*currentp)
			    : newSV(0) ) );
	    }
	}

	_keysort(aTHX_ ix, keygen, AvARRAY(values), 0, len);

	if (magic_values) {
	    int i;
	    SV **values_array = AvARRAY(values);
	    for(i=0; i<len; i++) {
		SV *current = values_array[i];
		if (!current) current = &PL_sv_undef;
		if (!av_store(magic_values, i, SvREFCNT_inc(current)))
		    SvREFCNT_dec(current);
	    }
	}
    }


void
_multikeysort(SV *keygen, SV *keytypes, ...)
PROTOTYPE: &$@
PPCODE:
    items-=2;
    if (items) {
	_multikeysort(aTHX_ keygen, keytypes, 0, ax, items);
	SP=&ST(items-1);
    }


void
_multikeysort_inplace(SV *keygen, SV *keytypes, AV *values)
PROTOTYPE: &\@
PREINIT:
    AV *magic_values=0;
    int len;
PPCODE:
    if ((len=av_len(values)+1)) {
	/* warn("ix=%d\n", ix); */
	if (SvMAGICAL(values) || AvREIFY(values)) {
	    int i;
	    magic_values = values;
	    values = (AV*)sv_2mortal((SV*)newAV());
	    av_extend(values, len-1);
	    for (i=0; i<len; i++) {
		SV **currentp = av_fetch(magic_values, i, 0);
		av_store( values, i,
			  ( currentp
			    ? SvREFCNT_inc(*currentp)
			    : newSV(0) ) );
	    }
	}

	_multikeysort(aTHX_ keygen, keytypes, AvARRAY(values), 0, len);

	if (magic_values) {
	    int i;
	    SV **values_array = AvARRAY(values);
	    for(i=0; i<len; i++) {
		SV *current = values_array[i];
		if (!current) current = &PL_sv_undef;
		if (!av_store(magic_values, i, SvREFCNT_inc(current)))
		    SvREFCNT_dec(current);
	    }
	}
    }
