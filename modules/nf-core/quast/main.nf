process QUAST {
    tag "$meta.id"
    label 'process_medium'

    input:
        path consensus
        path fasta
        path gff
        val use_fasta
        val use_gff

    output:
        path "${prefix}"    , emit: results
        path '*.tsv'        , emit: tsv
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
            --output-dir $prefix \\
            $reference \\
            $features \\
            --threads $task.cpus \\
            $args \\
            ${consensus.join(' ')}

        ln -s ${prefix}/report.tsv

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            quast: \$(quast.py --version 2>&1 | sed 's/^.*QUAST v//; s/ .*\$//')
        END_VERSIONS
    """
}