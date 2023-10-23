process SAMTOOLS_CRAM2BAM {

    container 'quay.io/biocontainers/samtools:1.17--hd87286a_1'

    tag "${meta.filename}"

    input:
    tuple val(meta), path(cram), path(crai)
    path(fasta)

    output:
    tuple val(meta), path(bam),path(bai), emit: bam
    path("versions.yml"), emit: versions

    script:
    bam = cram.getBaseName() + ".bam"
    bai = bam + ".crai"

    """
    samtools view -O BAM -o $bam -T $fasta $cram
    samtools index $bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

}

