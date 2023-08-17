/* groovylint-disable DuplicateStringLiteral */
process DOTD2MQC_INDIVIDUAL {
    tag "$meta.experiment_id"
    label 'process_single'

    conda "base::python=3.10"
    container "continuumio/miniconda3:23.5.2-0-alpine"

    input:
    tuple val(meta), path(dot_d_file)

    output:
    tuple path("dotd_mqc.yml"), path("*.tsv"), emit: dotd_mqc_data
    path "versions.yml", emit: version
    path "*.log", emit: log

    script:
    def prefix = task.ext.prefix ?: "${meta.mzml_id}"

    """
    dotd_2_mqc.py single "${dot_d_file}" \${PWD}  \\
        2>&1 | tee dotd_2_mqc_${prefix}.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dotd_2_mqc: \$(dotd_2_mqc.py --version | grep -oE "\\d\\.\\d\\.\\d")
        dotd_2_mqc_python: \$(python --version | grep -oE "\\d\\.\\d\\.\\d")
    END_VERSIONS
    """
}


process DOTD2MQC_AGGREGATE {
    label 'process_single'

    conda 'base::python=3.10'
    container 'continuumio/miniconda3:23.5.2-0-alpine'

    input:
    path '*.tsv'

    output:
    path 'general_stats.tsv', emit: dotd_mqc_data
    path 'versions.yml', emit: version
    path '*.log', emit: log

    script:
    """
    ls -lcth

    dotd_2_mqc.py aggregate \${PWD} \${PWD}  \\
        2>&1 | tee dotd_2_mqc_agg.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dotd_2_mqc: \$(dotd_2_mqc.py --version | grep -oE "\\d\\.\\d\\.\\d")
        dotd_2_mqc_python: \$(python --version | grep -oE "\\d\\.\\d\\.\\d")
    END_VERSIONS
    """
}