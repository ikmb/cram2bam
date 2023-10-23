include { SAMTOOLS_CRAM2BAM as CRAM2BAM } from '../modules/samtools/cram2bam'
include { SOFTWARE_VERSIONS } from '../modules/software_versions'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './../modules/custom/dumpsoftwareversions'
include { MULTIQC } from './../modules/multiqc'

ch_versions = Channel.from([])
multiqc_files = Channel.from([])

ch_crams = Channel.fromPath(params.crams).map { c -> tuple([ filename: c.getBaseName() ], file(c, checkIfExists: true), file(c + ".crai", checkIfExists: true)) }
ch_fasta = Channel.fromPath(params.reference, checkIfExists: true).collect()

workflow CONVERT_CRAM {

    main:

    CRAM2BAM(
        ch_crams,
        ch_fasta
    )

    SOFTWARE_VERSIONS(
        ch_versions.collect()
    )		
	
    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )
	
    multiqc_files = multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml)

    MULTIQC(
        multiqc_files.collect()
    )

    emit:
    qc = MULTIQC.out.html
	
}

