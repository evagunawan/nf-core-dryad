process QUAST {

    tag "$meta.id"
    label 'process_medium'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/quast:5.2.0--py39pl5321h4e691d4_3'
        }"

    input:
        path consensus
        path fasta
        path gff
        val use_fasta
        val use_gff

    output:
        path "${prefix}"    , emit: quast_results
        path '*.tsv'        , emit: quast_tsv
        path "versions.yml" , emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        def args = task.ext.args   ?: ''
        prefix   = task.ext.prefix ?: 'quast'
        def features  = use_gff ? "--features $gff" : ''
        def reference = use_fasta ? "-r $fasta" : ''

        """
        quast.py \\
            ${contigs} \\
            -o .

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            quast: \$(quast.py --version 2>&1 | sed 's/^.*QUAST v//; s/ .*\$//')
        END_VERSIONS
    """
}