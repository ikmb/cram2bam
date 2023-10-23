//
// This file holds several functions specific to the workflow/esga.nf in the nf-core/esga pipeline
//

class WorkflowPipeline {

    //
    // Check and validate parameters
    //
    public static void initialise(params, log) {


        if (!params.reference) {
		log.info  "Must provide a reference FASTA file (--reference)"
	        System.exit(1)
        }
    

    }

}
