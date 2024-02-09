# DLFP8.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://chengchingwen.github.io/DLFP8.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://chengchingwen.github.io/DLFP8.jl/dev/)
[![Build Status](https://github.com/chengchingwen/DLFP8.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/chengchingwen/DLFP8.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/chengchingwen/DLFP8.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/chengchingwen/DLFP8.jl)

Provide the 8-bits floats (`FP8`) proposed in [FP8 Formats for Deep Learning](https://arxiv.org/abs/2209.05433) (`Float8_E4M3FN`, `Float8E5M2`) and [8-bit Numerical Formats For Deep Neural Networks](https://arxiv.org/abs/2206.02915) (`Float8_E4M3FNUZ`, `Float8_E5M2FNUZ`). Mainly for handling data stored in this format. All floating-point arithmetics are with `Float32` and convert the output back to `FP8`.
