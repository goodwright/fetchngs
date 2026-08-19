
process SRA_IDS_TO_RUNINFO {
    tag "$id"
    label 'error_retry'

    conda "conda-forge::python=3.9.5"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9--1' :
        'biocontainers/python:3.9--1' }"

    input:
    val id
    val fields

    output:
    path "*.tsv"       , emit: tsv
    tuple val("${task.process}"), val('python'), eval('python --version | sed "s/Python //g"'), emit: versions_python, topic: versions

    script:
    def metadata_fields = fields ? "--ena_metadata_fields ${fields}" : ''
    def offline = task.ext.offline ?: false
    if (offline) {
        def fixture = file("${projectDir}/assets/offline/${id}.runinfo.tsv")
        if (!fixture.exists()) {
            error("No offline runinfo fixture for accession '${id}' (looked for ${fixture})")
        }
        // Inlined rather than staged so the fixture reaches the task without projectDir being mounted
        """
        cat <<'END_RUNINFO' > ${id}.runinfo.tsv
${fixture.text.trim()}
END_RUNINFO
        """
    } else {
        """
        echo $id > id.txt
        sra_ids_to_runinfo.py \\
            id.txt \\
            ${id}.runinfo.tsv \\
            $metadata_fields
        """
    }

    stub:
    """
    touch ${id}.runinfo.tsv
    """
}
