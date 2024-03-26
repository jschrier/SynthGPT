#!/usr/bin/env wolframscript
(* ::Package:: *)

SetDirectory@NotebookDirectory[];
<<"./src/statistical_baseline.wl"

(* setup calculation by defining possible precursors and targets *)
precursors = Import["./data/precursors.json", "RawJSON"];
targetElements = sourceElementsInTargets@ Import["./data/targets.json", "RawJSON"];

(* compute categorical distribution of precursors for each source element *)
weights = AssociationMap[ elementDistribution[precursors],  targetElements];

(* compute top-1 results *)
FileSystemScan[ evaluateBaselinePrediction[weights, 1], "./data/cross_validation/"]

(* compute top-5 results *)
FileSystemScan[ evaluateBaselinePrediction[weights, 5], "./data/cross_validation/"]
