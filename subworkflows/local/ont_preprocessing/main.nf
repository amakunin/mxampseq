include { PORECHOP_ABI } from '../../../modules/nf-core/porechop/abi/main'
include { CHOPPER      } from '../../../modules/nf-core/chopper/main'

//
// Sample-level ONT preprocessing before target demultiplexing:
// adapter trimming (Porechop_ABI) followed by read filtering (Chopper),
// each independently skippable. Tool arguments come from pipeline-level
// params via conf/modules.config; no filtering defaults are set here.
//

workflow ONT_PREPROCESSING {

    take:
    ch_reads          // channel: [ meta, fastq ], one element per sample
    skip_porechop_abi // boolean: skip adapter trimming
    skip_chopper      // boolean: skip read filtering

    main:

    def ch_trimmed = ch_reads
    def ch_porechop_log = channel.empty()
    if (!skip_porechop_abi) {
        PORECHOP_ABI(ch_reads, [])
        ch_trimmed = PORECHOP_ABI.out.reads
        ch_porechop_log = PORECHOP_ABI.out.log
    }

    def ch_filtered = ch_trimmed
    if (!skip_chopper) {
        CHOPPER(ch_trimmed, [])
        ch_filtered = CHOPPER.out.fastq
    }

    emit:
    reads        = ch_filtered     // channel: [ meta, fastq ]
    porechop_log = ch_porechop_log // channel: [ meta, log ]
}
