/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_mxampseq_pipeline'
include { ONT_PREPROCESSING      } from '../subworkflows/local/ont_preprocessing'
include { CUTADAPT_DEMUX         } from '../modules/local/cutadapt/demux'
include { TARGET_CONSENSUS       } from '../subworkflows/local/target_consensus'
include { SAVONT_CONSENSUS } from '../subworkflows/local/savont_consensus'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow MXAMPSEQ {

    take:
    ch_samplesheet // channel: [ meta, reads ]
    ch_adapters    // value channel: linked-adapter fasta
    ch_targets     // value channel: map target name -> clustering settings
    outdir

    main:

    def ch_versions = channel.empty()

    //
    // SUBWORKFLOW: sample-level adapter trimming and read filtering
    //
    ONT_PREPROCESSING(ch_samplesheet, params.skip_porechop_abi, params.skip_chopper)

    //
    // MODULE: demultiplex each sample into targets
    //
    CUTADAPT_DEMUX(ONT_PREPROCESSING.out.reads, ch_adapters)

    //
    // One element per sample x target, the file name is <sample>.<target>.fastq.gz;
    // reads matching no target (<sample>.unknown.fastq.gz) are split off
    //
    def ch_demux = CUTADAPT_DEMUX.out.reads
        .flatMap { meta, fastqs ->
            [ fastqs ].flatten().collect { fq ->
                def target = fq.name.substring(meta.id.length() + 1, fq.name.length() - '.fastq.gz'.length())
                [ meta, target, fq ]
            }
        }
        .branch { _meta, target, _fq ->
            unknown: target == 'unknown'
            targeted: true
        }

    //
    // Per sample x target meta carrying the target's clustering settings
    //
    def ch_target_reads = ch_demux.targeted
        .combine(ch_targets.map { setup -> [ setup ] })
        .map { meta, target, fq, setup ->
            def target_setup = setup[target]
            if (target_setup == null) {
                error "Target '${target}' (sample ${meta.id}) not found in analysis setup"
            }
            [ [ id: "${meta.id}_${target}", sample: meta.id, target: target ] + target_setup, fq ]
        }

    // ch_target_reads.view { meta, fq -> "target meta: ${meta}" }

    //
    // SUBWORKFLOW: dereplicate and cluster each sample x target into consensus sequences
    //
    TARGET_CONSENSUS(ch_target_reads)

    //
    // Collate and save software versions
    //
    def topic_versions = channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
        }
        .groupTuple(by:0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    def ch_collated_versions = softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${outdir}/pipeline_info",
            name: 'nf_core_'  +  'mxampseq_software_'  + 'versions.yml',
            sort: true,
            newLine: true
        )
    emit:
    versions       = ch_collated_versions        // channel: path(software versions YAML)
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
