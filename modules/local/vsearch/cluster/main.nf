process VSEARCH_CLUSTER {
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/vsearch:2.31.0--hd2be7a0_0' :
        'quay.io/biocontainers/vsearch:2.31.0--hd2be7a0_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path('*.centroids.fasta')    , optional: true, emit: centroids
    tuple val(meta), path('*.consensus.fasta')    , optional: true, emit: consensus
    tuple val(meta), path('*.clusters.fasta')     , optional: true, emit: clusters
    tuple val(meta), path('*.uc')                 , optional: true, emit: uc
    tuple val(meta), path('*.otu.tsv')            , optional: true, emit: otu
    tuple val(meta), path('*.profile.txt')        , optional: true, emit: profile
    tuple val(meta), path('*.out.tsv')            , optional: true, emit: out
    tuple val("${task.process}"), val('vsearch'), eval('vsearch --version 2>&1 | sed -n "1s/.*v\\([0-9.]*\\).*/\\1/p"'), emit: versions_vsearch, topic: versions
    tuple val("${task.process}"), val('samtools'), eval("samtools version | sed '1!d;s/.* //'"), emit: versions_samtools, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def output_flags = (task.ext.args3 ?: '').tokenize()
    def prefix = task.ext.prefix ?: "${meta.id}"

    if (!(args2.contains("--cluster_fast") || args2.contains("--cluster_size") || args2.contains("--cluster_smallmem") || args2.contains("--cluster_unoise"))) {
        error "Unknown clustering option provided (${args2})"
    }
    if (!output_flags) {
        error "No vsearch output flags provided; set task.ext.args3 to one or more valid output flags such as --consout --centroids --uc"
    }

    def out_args = output_flags.collect { flag ->
        if (flag == '--centroids') {
            "--centroids ${prefix}.centroids.fasta"
        } else if (flag == '--consout') {
            "--consout ${prefix}.consensus.fasta"
        } else if (flag == '--clusters') {
            "--clusters ${prefix}.clusters.fasta"
        } else if (flag == '--uc') {
            "--uc ${prefix}.uc"
        } else if (flag == '--otutabout') {
            "--otutabout ${prefix}.otu.tsv"
        } else if (flag == '--profile') {
            "--profile ${prefix}.profile.txt"
        } else if (flag == '--userout') {
            "--userout ${prefix}.out.tsv"
        } else {
            error "Unsupported output flag for VSEARCH_CLUSTER: ${flag}"
        }
    }.join(' ')

    """
    vsearch \\
        $args2 $fasta \\
        $out_args \\
        --threads $task.cpus \\
        $args
    """

    stub:
    def args2 = task.ext.args2 ?: ''
    def output_flags = (task.ext.args3 ?: '').tokenize()
    def prefix = task.ext.prefix ?: "${meta.id}"

    if (!(args2.contains("--cluster_fast") || args2.contains("--cluster_size") || args2.contains("--cluster_smallmem") || args2.contains("--cluster_unoise"))) {
        error "Unknown clustering option provided (${args2})"
    }
    if (!output_flags) {
        error "No vsearch output flags provided; set task.ext.args3 to one or more valid output flags"
    }

    def stub_lines = output_flags.collect { flag ->
        if (flag == '--centroids') {
            "touch ${prefix}.centroids.fasta"
        } else if (flag == '--consout') {
            "touch ${prefix}.consensus.fasta"
        } else if (flag == '--clusters') {
            "touch ${prefix}.clusters.fasta"
        } else if (flag == '--uc') {
            "touch ${prefix}.uc"
        } else if (flag == '--otutabout') {
            "touch ${prefix}.otu.tsv"
        } else if (flag == '--profile') {
            "touch ${prefix}.profile.txt"
        } else if (flag == '--userout') {
            "touch ${prefix}.out.tsv"
        } else {
            error "Unsupported output flag for VSEARCH_CLUSTER: ${flag}"
        }
    }.join('\n')

    """
    ${stub_lines}
    """
}