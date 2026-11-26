include { SAVONT_ASV } from '../../../modules/local/savont_asv'
include { SAVONT_EXPORT } from '../../../modules/local/savont_export'


workflow SAVONT_CONSENSUS {

    take:
    ch_target_reads // channel: [ meta, fastq ], one element per sample x target

    main:
    if (params.sample_inference == "pooled") {
        ch_reads_to_savont =
            ch_target_reads
                .toSortedList { a, b -> a[0].id <=> b[0].id }
                .map { list ->
                    def reads = list.collect { _meta, read -> read }
                    def ids = list.collect { meta, _reads -> meta.id }.join("\t")
                    def ids_for_export = list.collect { meta, _reads -> meta.id }.join(" ")
                    [ [id: 'pooled'], reads, "ID\t${ids}", ids_for_export, true ] }
        SAVONT_ASV (ch_reads_to_savont)
        SAVONT_EXPORT ( SAVONT_ASV.out.output_folder )
        ch_asv_fasta = SAVONT_EXPORT.out.fasta
        ch_asv_table = SAVONT_EXPORT.out.asv
        ch_stats_savont = SAVONT_ASV.out.stats
    } else if (params.sample_inference == "independent") {
        ch_reads_to_savont =
            ch_target_reads
                .map { meta, reads ->
                    [ meta, reads, "ID\t${meta.id}", meta.id, false ] }
        SAVONT_ASV (ch_reads_to_savont)
        ch_reads_to_savont_export =
            SAVONT_ASV.out.output_folder
                .toSortedList { a, b -> a[0].id <=> b[0].id }
                .map { list ->
                    def folders = list.collect { _meta, folder, _sample -> folder }
                    def ids = list.collect { meta, _folder, _sample -> meta.id }.join(" ")
                    [ [id: 'independent'], folders, ids ] }
        SAVONT_EXPORT ( ch_reads_to_savont_export )
        ch_asv_fasta = SAVONT_EXPORT.out.fasta
        ch_asv_table = SAVONT_EXPORT.out.asv
        ch_stats_savont = SAVONT_ASV.out.stats
            .collectFile(name: 'savont_stats.tsv', keepHeader: true, sort: true, cache: true, newLine: true)
    }

    emit:
    asv_fasta = ch_asv_fasta
    asv_table = ch_asv_table
    stats_savont = ch_stats_savont

}