include { SAVONT_ASV } from '../../../modules/local/savont_asv'
include { SAVONT_EXPORT } from '../../../modules/local/savont_export'

workflow SAVONT_CONSENSUS {

    take:
    ch_target_reads // channel: [ meta, fastq ], one element per sample x target

    main:
    def ch_validated_reads = ch_target_reads.map { meta, reads ->
        if (!['pooled', 'independent'].contains(meta.savont_mode)) {
            error "Unsupported savont_mode '${meta.savont_mode}' for target '${meta.target}'"
        }
        [ meta, reads ]
    }

    def ch_by_mode = ch_validated_reads.branch {
        meta, _reads ->
            // Pooled mode: inputs are grouped by target, sorted with their metadata/read pairs intact, and produce one ASV task and export per target.
            pooled:      meta.savont_mode == 'pooled'
            // Independent mode: ASV runs per sample-target; output folders are grouped by target before export.
            independent: meta.savont_mode == 'independent'
    }

    // One pooled Savont run per target; retain deterministic sample ordering within each target.
    def ch_pooled_input = ch_by_mode.pooled
        .map { meta, read -> tuple(meta.target, meta, read) }
        .groupTuple(by: 0)
        .map { target, metas, reads ->
            def sorted = [metas, reads].transpose()
                .sort { a, b -> a[0].id <=> b[0].id }

            def target_reads = sorted.collect { _meta, read -> read }
            def ids = sorted.collect { meta, _read -> meta.id }.join('\t')
            def ids_for_export = sorted.collect { meta, _read -> meta.id }.join(' ')

            [
                [id: "pooled_${target}", target: target, savont_mode: 'pooled'],
                target_reads,
                "ID\t${ids}",
                ids_for_export,
                true
            ]
        }

    def ch_independent_input = ch_by_mode.independent
        .map { meta, reads ->
            [ meta, reads, "ID\t${meta.id}", meta.id, false ]
        }

    // Each tuple triggers its own ASV task: pooled per target, independent per sample-target.
    def ch_savont_asv_input = ch_pooled_input.mix(ch_independent_input)
    SAVONT_ASV(ch_savont_asv_input)

    def ch_asv_by_mode = SAVONT_ASV.out.output_folder.branch {
        meta, _folder, _sample_string ->
            pooled:      meta.savont_mode == 'pooled'
            independent: meta.savont_mode == 'independent'
    }

    // Merge independent results separately for each target.
    def ch_independent_export = ch_asv_by_mode.independent
        .map { meta, folder, sample_string ->
            tuple(meta.target, meta, folder, sample_string)
        }
        .groupTuple(by: 0)
        .map { target, metas, folders, sample_strings ->
            def entries = [metas, folders, sample_strings].transpose()
                .sort { a, b -> a[0].id <=> b[0].id }

            def target_folders = entries.collect { _meta, folder, _sample -> folder }
            def ids = entries.collect { _meta, _folder, sample -> sample }.join(' ')

            [
                [id: "independent_${target}", target: target, savont_mode: 'independent'],
                target_folders,
                ids
            ]
        }

    def savont_export_input = ch_asv_by_mode.pooled.mix(ch_independent_export)
    SAVONT_EXPORT(savont_export_input)

    def ch_stats_by_mode = SAVONT_ASV.out.stats.branch {
        meta, _stats ->
            pooled:      meta.savont_mode == 'pooled'
            independent: meta.savont_mode == 'independent'
    }

    def ch_independent_stats = ch_stats_by_mode.independent
        .collectFile(keepHeader: true, sort: true, cache: true, newLine: true) { item ->
            [ "savont_stats_${item[0].target}.tsv", item[1] ]
        }

    def ch_stats_savont = ch_stats_by_mode.pooled
        .map { _meta, stats -> stats }
        .mix(ch_independent_stats)

    emit:
    asv_fasta   = SAVONT_EXPORT.out.fasta
    asv_table   = SAVONT_EXPORT.out.asv
    stats_savont = ch_stats_savont
}