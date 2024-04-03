#!/usr/bin/env wolframscript
(* ::Package:: *)

SetDirectory@ NotebookDirectory[];

<<"./src/pu_learning_queries.wl"

FileSystemScan[
	evaluatePUPrediction["gpt-3.5-turbo-0125", 0, "./results_MP/gpt-3.5"],
	"./data_MP/test_batch",
	FileNameForms->"*.mx"]
