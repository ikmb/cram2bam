#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// DEV: Update this block with a description and the name of the pipeline
/**
===============================
Pipeline
===============================

This Pipeline performs ....

### Homepage / git
git@github.com:ikmb/pipeline.git

**/

// Pipeline version
params.version = workflow.manifest.version

def summary = [:]

run_name = ( params.run_name == false) ? "${workflow.sessionId}" : "${params.run_name}"

WorkflowMain.initialise(workflow, params, log)

// DEV: Rename this and the file under lib/ to something matching this pipeline (e.g. WorkflowExomes)
WorkflowPipeline.initialise( params, log)

// DEV: Rename this to something matching this pipeline, e.g. "EXOMES"
include { MAIN } from './workflows/main'

multiqc_report = Channel.from([])

workflow {

    // DEV: Rename to something matching this pipeline (see above)
    MAIN()

    multiqc_report = multiqc_report.mix(MAIN.out.qc).toList()
}

workflow.onComplete {
    log.info "========================================="
    log.info "Duration:		$workflow.duration"
    log.info "========================================="

    def email_fields = [:]
    email_fields['version'] = workflow.manifest.version
    email_fields['session'] = workflow.sessionId
    email_fields['runName'] = run_name
    email_fields['Samples'] = params.samples
    email_fields['success'] = workflow.success
    email_fields['dateStarted'] = workflow.start
    email_fields['dateComplete'] = workflow.complete
    email_fields['duration'] = workflow.duration
    email_fields['exitStatus'] = workflow.exitStatus
    email_fields['errorMessage'] = (workflow.errorMessage ?: 'None')
    email_fields['errorReport'] = (workflow.errorReport ?: 'None')
    email_fields['commandLine'] = workflow.commandLine
    email_fields['projectDir'] = workflow.projectDir
    email_fields['script_file'] = workflow.scriptFile
    email_fields['launchDir'] = workflow.launchDir
    email_fields['user'] = workflow.userName
    email_fields['Pipeline script hash ID'] = workflow.scriptId
    email_fields['manifest'] = workflow.manifest
    email_fields['summary'] = summary

    email_info = ""
    for (s in email_fields) {
        email_info += "\n${s.key}: ${s.value}"
    }

    def output_d = new File( "${params.outdir}/pipeline_info/" )
    if( !output_d.exists() ) {
        output_d.mkdirs()
    }

    def output_tf = new File( output_d, "pipeline_report.txt" )
    output_tf.withWriter { w -> w << email_info }	

   // make txt template
    def engine = new groovy.text.GStringTemplateEngine()

    def tf = new File("$baseDir/assets/email_template.txt")
    def txt_template = engine.createTemplate(tf).make(email_fields)
    def email_txt = txt_template.toString()

    // make email template
    def hf = new File("$baseDir/assets/email_template.html")
    def html_template = engine.createTemplate(hf).make(email_fields)
    def email_html = html_template.toString()
  
    def subject = "Pipeline finished ($run_name)."

    if (params.email) {

        def mqc_report = null
        try {
            if (workflow.success && !params.skip_multiqc) {
                mqc_report = multiqc_report.getVal()
                if (mqc_report.getClass() == ArrayList){
                    log.warn "[PIpeline] Found multiple reports from process 'multiqc', will use only one"
                    mqc_report = mqc_report[0]
                }
            }
        } catch (all) {
            log.warn "[IKMB ExoSeq] Could not attach MultiQC report to summary email"
        }

        def smail_fields = [ email: params.email, subject: subject, email_txt: email_txt, email_html: email_html, baseDir: "$baseDir", mqcFile: mqc_report, mqcMaxSize: params.maxMultiqcEmailFileSize.toBytes() ]
        def sf = new File("$baseDir/assets/sendmail_template.txt")	
        def sendmail_template = engine.createTemplate(sf).make(smail_fields)
        def sendmail_html = sendmail_template.toString()

    try {
        if( params.plaintext_email ){ throw GroovyException('Send plaintext e-mail, not HTML') }
            // Try to send HTML e-mail using sendmail
            [ 'sendmail', '-t' ].execute() << sendmail_html
        } catch (all) {
          // Catch failures and try with plaintext
          [ 'mail', '-s', subject, params.email ].execute() << email_txt
        }
    }

}

