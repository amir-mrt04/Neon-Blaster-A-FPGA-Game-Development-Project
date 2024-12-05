
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name NeonBlast -dir "E:/CADP/NeonBlast/planAhead_run_2" -part xc6slx9tqg144-3
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "vga.ucf" [current_fileset -constrset]
set hdlfile [add_files [list {VGA_Square.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {VGA_controller.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {NeonBlast.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set_property top NeonBlast $srcset
add_files [list {vga.ucf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc6slx9tqg144-3
