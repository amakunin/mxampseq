include { PORECHOP_ABI } from '../../../modules/nf-core/porechop/abi/main'
include { CHOPPER      } from '../../../modules/nf-core/chopper/main'

// Filter out empty read files and log warnings for samples with no reads

def filterEmptyReads(ch_reads, stage) {
    def split = ch_reads.branch { item ->
        empty: item[1].countFastq() == 0
        nonempty: true
    }

    split.empty
        .map { meta, _reads -> meta.id }
        .collect()
        .subscribe { sample_ids ->
            if (sample_ids) {
                log.warn "Samples with no reads at ${stage} will be skipped:\n${sample_ids.join('\n')}"
            }
        }

    def ch_nonempty = split.nonempty.ifEmpty {
        error "All samples have zero reads at ${stage}; cannot continue."
    }

    return ch_nonempty
}

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

    // Filter empty files
    ch_reads = filterEmptyReads(ch_reads, "initial preprocessing")

    def ch_trimmed = ch_reads
    def ch_porechop_log = channel.empty()
    if (!skip_porechop_abi) {
        PORECHOP_ABI(ch_reads, [])
        ch_trimmed = filterEmptyReads(PORECHOP_ABI.out.reads, "after Porechop_ABI")
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
