#!/usr/bin/env wolframscript
(* ::Package:: *)

(* create summary scores for the PU learning tasks *)

(*  compute the summary statistics, saving result into file  *)
SetDirectory@NotebookDirectory[];
<<"./src/pu_learning_queries.wl"

summarize/@ {"./results_MP/gpt-3.5", "./results_MP/gpt-3.5_finetune", "./results_MP/gpt-4"}
