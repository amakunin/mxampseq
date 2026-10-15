process CHECK_INPUT_FASTQ {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.filtered.fastq.gz"), optional: true, emit: passed
    path("${meta.id}.status.tsv"), emit: status

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}.filtered"
    """
    reads_n=\$(gzip -cd ${reads} | awk 'END {print int(NR/4)}')

    if [ "\$reads_n" -gt 0 ]; then
        cp ${reads} ${prefix}.fastq.gz
        printf '%s\\t%s\\t%s\\t%s\\t%s\\n' '${meta.id}' 'NA' 'input' 'present' "\$reads_n reads" > ${meta.id}.status.tsv
    else
        printf '%s\\t%s\\t%s\\t%s\\t%s\\n' '${meta.id}' 'NA' 'input' 'empty_input' '0 reads' > ${meta.id}.status.tsv
    fi
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}.filtered"
    """
    touch ${prefix}.fastq.gz
    printf '%s\\t%s\\t%s\\t%s\\t%s\\n' '${meta.id}' 'NA' 'input' 'present' 'stub' > ${meta.id}.status.tsv
    """
}