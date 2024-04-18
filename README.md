# SynthGPT

This repository contains the data and code for the study [Large Language Models for Inorganic Synthesis Predictions](insert-chemrxiv-link-here) by [Seongmin Kim](https://scholar.google.com/citations?user=HXcbuWQAAAAJ&hl=en&oi=ao), [Yousung Jung](https://scholar.google.com/citations?user=y8D-JCAAAAAJ&hl=en&oi=ao), and [Joshua Schrier](https://scholar.google.com/citations?user=zJC_7roAAAAJ&hl=en).

# Organization

**Input data** and pre-defined training and cross-validation and train/test splits are found in the `data_MP` and `data` folders, for the synthesizability and precursor selection tasks, respectively.

**Results** are in the `results_MP` and `results` folders, for the synthesizability and precursor selection tasks, respectively.  We have used a JSON format to facilitate interpretation of the results.

**Prompts** for the LLM are in the `prompts` folder as plain text files;  they can also be found in the online Supporting Information file.

**Source code** is in the `src` folder; some haphazard tests are included in `tests`.


# Instructions

Run the notebooks in the top-level directory in order.  Mathematica code (`.wls`) uses Mathematica 14.0 and no other libraries; Python uses VERSION and requires libraries LIBRARIES

The directory is organized around the order in which we performed the work, dividing the work into discrete tasks:  
 - Precursor selection  (scripts `00_Data_Curation.py` - `07_Estimate_Perfect_Elemwise.py`) 
- Synthesizability prediction (`08_Data_Preparation_Synthesizability.wls` - `11_Score_GPT_Outputs_Synthesizability.wls`)
- Rescoring results with GPT-4 (`12a_SetupData_Combined.wls` and `12b_Evaluate_Combined.wls` )

Yes, this is different from the order the paper.  "Life can only be understood backwards; but it must be lived forwards." --[Soren Kierkegaard](https://en.wikipedia.org/wiki/Søren_Kierkegaard) 

# Cite

A preprint appears at...
