include { VSEARCH_FASTQFILTER } from '../../../modules/local/vsearch/fastqfilter'
include { VSEARCH_DEREPLICATE } from '../../../modules/nf-core/vsearch/dereplicate'
include { VSEARCH_CLUSTER     } from '../../../modules/local/vsearch/cluster'

//
// Per sample x target consensus generation:
// fastq -> optional vsearch filtering + fasta conversion -> dereplicate (sizeout) -> cluster
// Clustering and optional fastq filtering parameters are taken from meta via conf/modules.config
//

workflow TARGET_CONSENSUS {

    take:
    ch_target_reads // channel: [ meta, fastq ], one element per sample x target

    main:

    VSEARCH_FASTQFILTER(ch_target_reads)

    VSEARCH_DEREPLICATE(VSEARCH_FASTQFILTER.out.fasta)

    VSEARCH_CLUSTER(VSEARCH_DEREPLICATE.out.fasta)

    emit:
    filtered  = VSEARCH_FASTQFILTER.out.fasta
    derep     = VSEARCH_DEREPLICATE.out.fasta
    consensus = VSEARCH_CLUSTER.out.consensus // channel: [ meta, fasta ]
}