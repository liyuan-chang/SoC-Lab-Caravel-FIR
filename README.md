# Caravel FIR
Integrate FIR Engine and Execution Memory with WB-AXI Interface into User Project Area of Caravel SoC

## File Hierarchy
* lab-exmem_fir/
    * testbench/counter_la_fir/
        * counter_la_fir_tb.v
        * counter_la_fir_tb.c
        * fir.c
        * fir.h
        * include.rtl.list
    * rtl/user/
        * bram.v
        * user_proj_example.counter.v
    * simulation_result/
* lab-caravel_fir/
    * testbench/counter_la_fir/
        * counter_la_fir_tb.v
        * counter_la_fir_tb.c
        * fir.c
        * fir.h
        * include.rtl.list
        * out_gold.dat
    * rtl/user/
        * bram11.v
        * bram12.v
        * fir_wrapper.v
        * fir.v
        * user_proj_example.counter.v
    * constraint/
    * simulation_result/
    * synthesis_report/

## Simulation for Exmem-FIR
```sh
cd ./lab-exmem_fir/testbench/counter_la_fir
source run_clean
source run_sim
```

## Simulation for Caravel-FIR
```sh
cd ./lab-caravel_fir/testbench/counter_la_fir
source run_clean
source run_sim
```

## Block Diagram
### Caravel SoC
<img src="asset/caravel_soc.png" width="90%" height="90%">

### User project
<img src="asset/user_project.png" width="90%" height="90%">

### Verilog-FIR
<img src="asset/verilog-fir.png" width="70%" height="70%">
