process CUTADAPT_DEMUX {
    tag "$meta.id"
    label 'process_low'

    // Container definitions copied from the nf-core cutadapt module; cutadapt >= 4.0 is required for --json
    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/cutadapt:5.2--py311haab0aaa_0' :
        'quay.io/biocontainers/cutadapt:5.2--py311haab0aaa_0'}"

    input:
    tuple val(meta), path(reads, stageAs: 'input/*')
    path adapters

    output:
    // per-target files <prefix>.<target>.fastq.gz and, if present, <prefix>.unknown.fastq.gz
    tuple val(meta), path("${prefix}.*.fastq.gz")    , optional: true, emit: reads
    tuple val(meta), path("${prefix}.cutadapt.json") , emit: json
    tuple val(meta), path("${prefix}.cutadapt.log")  , emit: log
    tuple val("${task.process}"), val('cutadapt'), eval('cutadapt --version'), emit: versions_cutadapt, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix   = task.ext.prefix ?: "${meta.id}"
    """
    cutadapt \\
        --match-read-wildcards \\
        -j $task.cpus \\
        $args \\
        -g file:$adapters \\
        --json ${prefix}.cutadapt.json \\
        -o "${prefix}.{name}.fastq.gz" \\
        $reads \\
        > ${prefix}.cutadapt.log

    # drop empty outputs, downstream tools (vsearch) fail on empty input;
    # counts per target (including zeros) remain available in the json report
    for f in ${prefix}.*.fastq.gz; do
        [ -e "\$f" ] || continue
        if [ -z "\$(gzip -dc "\$f" | head -c 1)" ]; then
            rm "\$f"
        fi
    done
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    for name in \$(grep '^>' $adapters | sed 's/^>//; s/[[:space:]].*//'); do
        printf '@stub\\nA\\n+\\nI\\n' | gzip > ${prefix}.\${name}.fastq.gz
    done
    echo '{}' > ${prefix}.cutadapt.json
    touch ${prefix}.cutadapt.log
    """
}