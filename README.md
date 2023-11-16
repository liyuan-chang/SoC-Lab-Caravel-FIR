# Caravel FIR
Integrate FIR Engine and Execution Memory with WB-AXI Interface into User Project Area of Caravel SoC

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

## Block diagram
### Caravel SoC
<img src="asset/caravel_soc.png" width="90%" height="90%">

### User project
<img src="asset/user_project.png" width="90%" height="90%">

### Verilog-FIR
<img src="asset/verilog-fir.png" width="70%" height="70%">
