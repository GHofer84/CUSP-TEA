# TEA Simulation Framework (MATLAB)

A modular MATLAB framework for **scenario-based Monte Carlo techno-economic assessments (TEA)** of power plant configurations **with and without CO2 capture**.

Designed for **reproducibility** and **comparability across scenarios**.

---

## Quick Start

```bash
git clone <repo-url>
cd TEA-framework
```

Open MATLAB and run:

```matlab
startup
RUNcomputeSimulation
```

This will:
- Run all scenarios  
- Generate figures  
- Save a reproducible snapshot  

---

## What This Does

- Monte Carlo TEA for:
  - Coal  
  - Natural-gas-refired coal (NG)  
  - Natural Gas Combined Cycle (NGCC)

- CO2 capture configurations:
  - Point-source capture (PSC)  
  - Direct air capture (DAC)

- Outputs:
  - Breakeven credit distributions  
  - LCOE summaries & heatmaps  
  - PSC–DAC overlap metrics  
  - Publication-ready figures  

---

## Project Structure

```text
/src
  core/        # Simulation logic
  drivers/     # Entry points (run scripts)
  plotting/    # Figure generation
  utils/       # Helpers (sampling, styling, IO)
  startup.m    # Initialization
```

---

## Common Workflows

### Full simulation
```matlab
RUNcomputeSimulation
```

### Overlap + summary metrics
```matlab
RUNcomputeOverlap
```

### Load previous run
```matlab
RUNloadSnapshot
```

### Reproduce run (exact or modified parameters)
```matlab
RUNreproduceSnapshot
```

---

## Configuration

All parameters are defined in:

```matlab
/src/core/defineParams.m
```

Includes:
- Economic assumptions  
- Scenario definitions (Coal, NG, NGCC)  
- PSC & DAC parameter blocks  
- Sampling distributions:
  - Uniform  
  - Skewed  
  - Triangular  

---

## Reproducibility

Each run stores a snapshot containing:

- RNG state  
- Full parameter set  
- Scenario configuration  
- All outputs  

Enables:
- Exact reruns  
- Controlled parameter updates  

---

## Requirements

- MATLAB **R2023a+**  
- Statistics and Machine Learning Toolbox *(for LHS sampling)*  

---

## Design Philosophy

- Scenario clarity over abstraction  
- Deterministic reproducibility  
- Separation of concerns (drivers / core / plotting)  
- Extensible for new technologies and policy instruments