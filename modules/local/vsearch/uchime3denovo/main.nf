process VSEARCH_UCHIME3_DENOVO {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/vsearch:2.31.0--hd2be7a0_0' :
        'quay.io/biocontainers/vsearch:2.31.0--hd2be7a0_0' }"

    input:
    tuple val(meta), path(consensus)

    output:
    tuple val(meta), path("*.nonchimeras.fasta"), optional: true, emit: nonchimeras
    tuple val(meta), path("*.chimeras.fasta"), optional: true, emit: chimeras
    tuple val(meta), path("*.log"), emit: log
    tuple val("${task.process}"), val('vsearch'), eval('vsearch --version 2>&1 | sed -n "1s/.*v\\([0-9.]*\\).*/\\1/p"'), emit: versions_vsearch, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    vsearch \\
        --uchime3_denovo ${consensus} \\
        --chimeras ${prefix}.chimeras.fasta \\
        --nonchimeras ${prefix}.nonchimeras.fasta \\
        --threads $task.cpus \\
        $args --no_progress 2>&1 | tee ${prefix}.log
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.chimeras.fasta
    touch ${prefix}.nonchimeras.fasta
    touch ${prefix}.log
    """
}
