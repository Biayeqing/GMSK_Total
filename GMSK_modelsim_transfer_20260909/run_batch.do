transcript file transcript_batch.log
transcript on

onbreak {quit -code 1 -f}
onerror {quit -code 1 -f}

set TOP_NAME tb_top_GMSK_with_data_gen_ber
set RUN_VALUE 2
set RUN_UNIT ms
set REPORT_AT_NS 2000000
set EXIT_CODE 1

foreach OUT_FILE {
    gmsk_ber_report.txt
    gmsk_ber_compare_report.txt
    gmsk_ber_legacy_report.txt
    gmsk_ber_fir_report.txt
    gmsk_softout_bits.csv
    gmsk_softout_compare.csv
} {
    if {[file exists $OUT_FILE]} {
        if {[catch {file delete -force $OUT_FILE} CLEAN_MSG]} {
            puts "WARNING: Could not delete $OUT_FILE: $CLEAN_MSG"
        }
    }
}

do compile.do

vsim -c -voptargs=+acc -onfinish stop -L fifo_generator_v13_2_8 +REPORT_AT_NS=$REPORT_AT_NS work.$TOP_NAME
run $RUN_VALUE $RUN_UNIT

if {[file exists gmsk_ber_compare_report.txt]} {
    set fp [open gmsk_ber_compare_report.txt r]
    set report [read $fp]
    close $fp

    puts "==== gmsk_ber_compare_report.txt ===="
    puts $report

    set EXIT_CODE 0
} else {
    puts "ERROR: gmsk_ber_compare_report.txt was not generated."
}

quit -code $EXIT_CODE -f
