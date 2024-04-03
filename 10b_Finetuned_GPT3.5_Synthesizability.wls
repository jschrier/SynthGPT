#!/usr/bin/env wolframscript
(* ::Package:: *)

SetDirectory@ NotebookDirectory[];

<<"./src/pu_learning_queries.wl"

FileSystemScan[
	evaluatePUPrediction[
	"ft:gpt-3.5-turbo-0125:fordham-university:synthesizability:99otCcgz",
	 0, "./results_MP/gpt-3.5_finetune"],
	"./data_MP/test_batch",
	FileNameForms->"*.mx"]
