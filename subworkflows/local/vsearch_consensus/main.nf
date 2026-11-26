include { VSEARCH_FASTQFILTER } from '../../../modules/local/vsearch/fastqfilter'
include { VSEARCH_DEREPLICATE } from '../../../modules/local/vsearch/dereplicate'
include { VSEARCH_CLUSTER     } from '../../../modules/local/vsearch/cluster'
include { VSEARCH_UCHIME3_DENOVO } from '../../../modules/local/vsearch/uchime3denovo'

//
// Per sample x target consensus generation:
// fastq -> optional vsearch filtering + fasta conversion -> dereplicate (sizeout) -> cluster
// Clustering and optional fastq filtering parameters are taken from meta via conf/modules.config
//

workflow VSEARCH_CONSENSUS {

    take:
    ch_target_reads // channel: [ meta, fastq ], one element per sample x target

    main:

    VSEARCH_FASTQFILTER(ch_target_reads)

    // Only dereplicate if the filtered fasta is not empty
    VSEARCH_DEREPLICATE(VSEARCH_FASTQFILTER.out.fasta.filter { _meta, file -> file.size() > 0 })

    VSEARCH_CLUSTER(VSEARCH_DEREPLICATE.out.fasta)

    VSEARCH_UCHIME3_DENOVO(VSEARCH_CLUSTER.out.consensus)

    emit:
    filtered  = VSEARCH_FASTQFILTER.out.fasta
    derep     = VSEARCH_DEREPLICATE.out.fasta
    consensus = VSEARCH_CLUSTER.out.consensus
    nonchimeras = VSEARCH_UCHIME3_DENOVO.out.nonchimeras
}
