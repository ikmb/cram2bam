//
// This file holds several functions specific to the workflow/esga.nf in the nf-core/esga pipeline
//

class WorkflowMain {

    //
    // Check and validate parameters
    //
    //
    // Validate parameters and print summary to screen
    //
    public static void initialise(workflow, params, log) {

        log.info header(workflow)

        // Print help to screen if required
        if (params.help) {
            log.info help(workflow, params, log)
            System.exit(0)
        }
    }

    // DEV: Change name of the pipeline below
    public static String header(workflow) {
        def headr = ''
        def info_line = "IKMB ${workflow.manifest.description} | version ${workflow.manifest.version}"
        headr = """
    ===============================================================================
    ${info_line}
    ===============================================================================
    """
        return headr
    }

    public static String help(workflow, params, log) {
        def command = "nextflow run ${workflow.manifest.name} --samples Samples.csv --assembly GRCh38 --kit xGen_v2 -profile diagnostic"
        def help_string = ''
        // Help message
        help_string = """

           Usage: nextflow run ikmb/pipeline -samples Samples.csv

           Required parameters:
           --samples                      A sample list in CSV format (see website for formatting hints)
           --email                        Email address to send reports to (enclosed in '')
           Optional parameters:
           --run_name                     A descriptive name for this pipeline run
           Output:
           --outdir                       Local directory to which all output is written (default: results)
        """
        return help_string
    }

}
