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

        process QUAST_SUMMARY {
        label 'process_single'

        container "quay.io/wslh-bioinformatics/pandas@sha256:9ba0a1f5518652ae26501ea464f466dcbb69e43d85250241b308b96406cac458"

        input:
        path("data*/*")

        output:
        path("quast_results.tsv"), emit: quast_tsv

        when:
        task.ext.when == null || task.ext.when

        #!/usr/bin/python3.7
        import os
        import glob
        import pandas as pd
        from pandas import DataFrame

        # function for summarizing quast output
        def summarize_quast(file):
            # get sample id from file name and set up data list
            sample_id = os.path.basename(file).split(".")[0]
            # read in data frame from file
            df = pd.read_csv(file, sep='\\t')
            # get contigs, total length and assembly length columns
            df = df.iloc[:,[1,7,17]]
            # assign sample id as column
            df = df.assign(Sample=sample_id)
            # rename columns
            df = df.rename(columns={'# contigs (>= 0 bp)':'Contigs','Total length (>= 0 bp)':'Assembly Length (bp)'})
            # re-order data frame
            df = df[['Sample', 'Contigs','Assembly Length (bp)', 'N50']]
            return df

        # get quast output files
        files = glob.glob("data*/*.transposed.quast.report.tsv*")

        # summarize quast output files
        dfs = map(summarize_quast,files)
        dfs = list(dfs)

        # concatenate dfs and write data frame to file
        if len(dfs) > 1:
            dfs_concat = pd.concat(dfs)
            dfs_concat.to_csv(f'quast_results.tsv',sep='\\t', index=False, header=True, na_rep='NaN')
        else:
            dfs = dfs[0]
            dfs.to_csv(f'quast_results.tsv',sep='\\t', index=False, header=True, na_rep='NaN')
    """
}