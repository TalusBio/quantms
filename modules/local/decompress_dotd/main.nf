
process DECOMPRESS {
    tag "$meta.mzml_id"
    label 'process_low'
    label 'process_single'
    label 'error_retry'

    container 'ubuntu:22.04'

    stageInMode {
        if (task.attempt == 1) {
            if (executor == "awsbatch") {
                'symlink'
            } else {
                'link'
            }
        } else if (task.attempt == 2) {
            if (executor == "awsbatch") {
                'copy'
            } else {
                'symlink'
            }
        } else {
            'copy'
        }
    }

    input:
    tuple val(meta), path(compressed_file)

    output:
    tuple val(meta), path("*.d"),   emit: decompressed_files
    path "versions.yml",   emit: version
    path "*.log",   emit: log

    script:
    def prefix = task.ext.prefix ?: "${meta.mzml_id}"

    """
    function extract {
      if [ -z "\$1" ]; then
          echo "Usage: extract <path/file_name>.<gz|tar|tar.bz2>"
      else
          if [ -f \$1 ]; then
            case \$1 in
                *.tar.gz)    tar xvzf \$1    ;;
                *.gz)        gunzip \$1      ;;
                *.tar)       tar xvf \$1     ;;
                *)           echo "extract: '\$1' - unknown archive method" ;;
            esac
          else
            echo "\$1 - file does not exist"
          fi
      fi
    }

    tar --version 2>&1 | tee --append ${prefix}_decompression.log
    gunzip --version 2>&1 | tee --append ${prefix}_decompression.log
    echo "Unpacking..." | tee --append ${compressed_file.baseName}_decompression.log

    extract ${compressed_file} 2>&1 | tee --append ${compressed_file.baseName}_conversion.log
    mv *.d ${file(compressed_file.baseName).baseName}.d
    ls -l | tee --append ${compressed_file.baseName}_decompression.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gunzip: \$(gunzip --version | grep -oP "\\d+\\.\\d+")
        tar: \$(tar --version | grep -oP "\\d+\\.\\d+")
    END_VERSIONS
    """
}
