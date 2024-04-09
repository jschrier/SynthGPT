#!/usr/bin/env wolframscript
(* ::Package:: *)

SetDirectory@ NotebookDirectory[];

<<"./src/pu_learning_queries.wl"

FileSystemScan[
	evaluatePUPrediction["gpt-4-0125-preview", 0, "./results_MP/gpt-4"],
	"./data_MP/test_batch",
	FileNameForms->"*.mx"]
