from libc.stdint cimport int32_t, uint32_t, int8_t, int16_t, uint8_t
import numpy as np
cimport numpy as np
np.import_array()

cdef extern from "helpers.h":
    int as_gts(int *gts, int num_samples);

cdef extern from "htslib/hts.h":
    struct htsFile:
        pass

    htsFile *hts_open(char *fn, char *mode);

cdef extern from "htslib/vcf.h":
    const int BCF_DT_ID = 0;
    const int BCF_DT_SAMPLE = 2;


    const int BCF_BT_NULL   = 0
    const int BCF_BT_INT8   = 1
    const int BCF_BT_INT16  = 2
    const int BCF_BT_INT32  = 3
    const int BCF_BT_FLOAT  = 5
    const int BCF_BT_CHAR   = 7

    const int bcf_str_missing = 0x07
    const int bcf_str_vector_end = 0

    const int INT8_MIN = -128
    const int INT16_MIN = -32768
    const int INT32_MIN = -2147483648

    const int bcf_int8_vector_end  = -127
    const int bcf_int16_vector_end  = -32767
    const int bcf_int32_vector_end  = -2147483647
    
    const int bcf_int8_missing  = -127
    const int bcf_int16_missing  = -32767
    const int bcf_int32_missing  = -2147483647


    ctypedef union uv1:
        int32_t i; # integer value
        float f;   # float value

    ctypedef struct variant_t:
        pass
    ctypedef struct bcf_fmt_t:
        pass
    ctypedef struct bcf_info_t:
        int key;        # key: numeric tag id, the corresponding string is bcf_hdr_t::id[BCF_DT_ID][$key].key
        int type, len;  # type: one of BCF_BT_* types; len: vector length, 1 for scalars
        #} v1; # only set if $len==1; for easier access
        uv1 v1
        uint8_t *vptr;          # pointer to data array in bcf1_t->shared.s, excluding the size+type and tag id bytes
        uint32_t vptr_len;      # length of the vptr block or, when set, of the vptr_mod block, excluding offset
        uint32_t vptr_off;
        uint32_t vptr_free;   # vptr offset, i.e., the size of the INFO key plus size+type bytes
               # indicates that vptr-vptr_off must be freed; set only when modified and the new


    ctypedef struct bcf_dec_t:
        int m_fmt, m_info, m_id, m_als, m_allele, m_flt; # allocated size (high-water mark); do not change
        int n_flt;  # Number of FILTER fields
        int *flt;   # FILTER keys in the dictionary
        char *id, *als;     # ID and REF+ALT block (\0-seperated)
        char **allele;      # allele[0] is the REF (allele[] pointers to the als block); all null terminated
        bcf_info_t *info;   # INFO
        bcf_fmt_t *fmt;     # FORMAT and individual sample
        variant_t *var;     # $var and $var_type set only when set_variant_types called
        int n_var, var_type;
        int shared_dirty;   # if set, shared.s must be recreated on BCF output
        int indiv_dirty;    # if set, indiv.s must be recreated on BCF output

    ctypedef struct bcf1_t:
        int32_t rid;  #// CHROM
        int32_t pos;  #// POS
        int32_t rlen; #// length of REF
        float qual;   #// QUAL
        uint32_t n_info, n_allele;
        #uint32_t n_fmt:8, n_sample:24;
        #kstring_t shared, indiv;
        bcf_dec_t d; #// lazy evaluation: $d is not generated by bcf_read(), but by explicitly calling bcf_unpack()
        int max_unpack;        # // Set to BCF_UN_STR, BCF_UN_FLT, or BCF_UN_INFO to boost performance of vcf_parse when some of the fields wont be needed
        int unpacked;          # // remember what has been unpacked to allow calling bcf_unpack() repeatedly without redoing the work
        int unpack_size[3];    # // the original block size of ID, REF+ALT and FILTER
        int errcode;   # // one of BCF_ERR_* codes

    ctypedef struct bcf_idpair_t:
        pass
    ctypedef struct bcf_hrec_t:
        pass

    ctypedef struct kstring_t:
        pass

    ctypedef struct bcf_hdr_t:
        int32_t n[3];
        bcf_idpair_t *id[3];
        void *dict[3];         # ID dictionary, contig dict and sample dict
        char **samples;
        bcf_hrec_t **hrec;
        int nhrec, dirty;
        int ntransl, *transl[2]; # for bcf_translate()
        int nsamples_ori;        # for bcf_hdr_set_samples()
        uint8_t *keep_samples;
        kstring_t mem;


    bint bcf_float_is_missing(float f)
    bint bcf_float_is_vector_end(float f)


    void bcf_destroy(bcf1_t *v);
    bcf1_t * bcf_init();

    bcf_hdr_t *bcf_hdr_read(htsFile *fp);
    int bcf_hdr_set_samples(bcf_hdr_t *hdr, const char *samples, int is_file);
    int bcf_hdr_nsamples(const bcf_hdr_t *hdr);
    void bcf_hdr_destroy(const bcf_hdr_t *hdr)
    char *bcf_hdr_fmt_text(const bcf_hdr_t *hdr, int is_bcf, int *len);

    int hts_close(htsFile *fp);

    int bcf_read(htsFile *fp, const bcf_hdr_t *h, bcf1_t *v) nogil;

    const char *bcf_hdr_id2name(const bcf_hdr_t *hdr, int rid);
    const char *bcf_hdr_int2id(const bcf_hdr_t *hdr, int type, int int_id)

    int bcf_unpack(bcf1_t *b, int which) nogil;


    int bcf_get_genotypes(const bcf_hdr_t *hdr, bcf1_t *line, int **dst, int *ndst);
    int bcf_get_format_int32(const bcf_hdr_t *hdr, bcf1_t *line, char * tag, int **dst, int *ndst);
    int bcf_get_format_float(const bcf_hdr_t *hdr, bcf1_t *line, char * tag, float **dst, int *ndst)

    int bcf_get_format_values(const bcf_hdr_t *hdr, bcf1_t *line, const char *tag, void **dst, int *ndst, int type);
    bint bcf_gt_is_phased(int);
    int bcf_gt_allele(int);
    bint bcf_float_is_missing(float);
    bcf_info_t *bcf_get_info(const bcf_hdr_t *hdr, bcf1_t *line, const char *key);

