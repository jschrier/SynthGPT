import json
from pymatgen.core import Composition


def get_SourceElem(comp_list, comp_type='Target'):
    source_elem = []
    env_elem = []
    for comp in comp_list:
        non_source_elem = []
        comp_dict = Composition(comp).get_el_amt_dict()
        elements_seq = list(comp_dict.keys())

        for ee in elements_seq:
            if ee in essen_elem:
                source_elem.append(ee)
            else:
                non_source_elem.append(ee)
        for ee in non_source_elem:
            env_elem.append(ee)

    source_elem = list(set(source_elem))
    env_elem = list(set(env_elem))

    return source_elem, env_elem


def get_AnionPart(composition, source_elem, ExceptionMode=False, TargetTypeMode=False):
    comp_dict = Composition(composition).get_el_amt_dict()
    ca_count = 0
    an_count = 0
    anion = ""
    for elem, stoi in comp_dict.items():
        if TargetTypeMode:
            if str(elem) in inorg_elem:
            #if str(elem) in source_elem:
                ca_count += 1
            else:
                an_count += 1
                anion += str(elem)+str(stoi)
        else:
            if str(elem) in source_elem:
                ca_count += 1
            else:
                an_count += 1
                anion += str(elem)+str(stoi)
    if ca_count == 0:
        if ExceptionMode:
            pass
        else:
            raise NotImplementedError('No source elem', composition)

    if anion != "":
        anion = str(Composition(anion).get_integer_formula_and_factor()[0])
    return anion


elem_library            = ['H','He','Li','Be','B','C','N','O','F','Ne','Na','Mg','Al',
                           'Si','P','S','Cl','Ar','K','Ca','Sc','Ti','V','Cr','Mn','Fe',
                           'Co','Ni','Cu','Zn','Ga','Ge','As','Se','Br','Kr','Rb','Sr',
                           'Y','Zr','Nb','Mo','Tc','Ru','Rh','Pd','Ag','Cd','In','Sn',
                           'Sb','Te','I','Xe','Cs','Ba','La','Ce','Pr','Nd','Pm','Sm',
                           'Eu','Gd','Tb','Dy','Ho','Er','Tm','Yb','Lu','Hf','Ta','W',
                           'Re','Os','Ir','Pt','Au','Hg','Tl','Pb','Bi','Po','At','Rn',
                           'Fr','Ra','Ac','Th','Pa','U','Np','Pu','Am','Cm','Bk','Cf',
                           'Es','Fm','Md','No','Lr','Rf','Db','Sg','Bh','Hs','Mt','Ds',
                           'Rg','Cn','Nh','Fl','Mc','Lv','Ts','Og']

alkali_metal            = ['Li','Na','K','Rb','Cs']
alkaline_earth_metal    = ['Be','Mg','Ca','Sr','Ba']
transition_metal        = ['Sc','Ti','V','Cr','Mn','Fe','Co','Ni','Cu','Zn',
                           'Y','Zr','Nb','Mo','Ru','Rh','Pd','Ag','Cd','Hf',
                           'Ta','W','Re','Os','Ir','Pt','Au','Hg']
lanthanide_elem         = ['La','Ce','Pr','Nd','Sm','Eu','Gd','Tb','Dy','Ho','Er','Tm','Yb','Lu']
actinide_elem           = ['Ac','Th','Pa','U','Np','Pu','Am','Cm','Bk','Cf','Es','Fm','Md','No','Lr']
post_transition_metal   = ['Al','Ga','In','Sn','Tl','Pb','Bi']
metalloid               = ['B','Si','Ge','As','Sb','Te']
non_metal               = ['H','C','N','O','F','P','S','Cl','Se','Br','I']
noble_gas               = ['He','Ne','Ar','Kr','Xe']
artificial_elem         = ['Tc','Pm','Po','At','Rn','Fr','Ra','Rf','Db','Sg','Bh',
                           'Hs','Mt','Ds','Rg','Cn','Nh','Fl','Mc','Lv','Ts','Og']

essen_elem = alkali_metal + alkaline_earth_metal + transition_metal \
             + lanthanide_elem + actinide_elem + post_transition_metal + metalloid + ['P','Se','S']

inorg_elem = alkali_metal + alkaline_earth_metal + transition_metal \
             + lanthanide_elem + actinide_elem + post_transition_metal + metalloid


# Prepare data
def DataPreparation():
    # random splitted cv dataset load
    file_path = "./data/cross_validation/random_cv1.json"
    with open(file_path, "r") as json_file:
        data1 = json.load(json_file)
    file_path = "./data/cross_validation/random_cv2.json"
    with open(file_path, "r") as json_file:
        data2 = json.load(json_file)
    file_path = "./data/cross_validation/random_cv3.json"
    with open(file_path, "r") as json_file:
        data3 = json.load(json_file)
    file_path = "./data/cross_validation/random_cv4.json"
    with open(file_path, "r") as json_file:
        data4 = json.load(json_file)
    file_path = "./data/cross_validation/random_cv5.json"
    with open(file_path, "r") as json_file:
        data5 = json.load(json_file)

    data_fold = {}

    for k, data in enumerate([data1, data2, data3, data4, data5]):
        data_TP_test = []

        for tar, pre_set_list in data['test'].items():
            syn = {}
            syn['Target'] = [tar]
            syn['Precursors'] = pre_set_list
            data_TP_test.append(syn)

        data_fold[str(k+1)] = data_TP_test

    return data_fold

def Calculate_IdealAccuracy(data):

    file_path = "./data/elemwise_formulation/pre_anion_part.json"
    with open(file_path, "r") as json_file:
        pre_anion_part = json.load(json_file)

    file_path = "./data/elemwise_formulation/stoi_dict.json"
    with open(file_path, "r") as json_file:
        stoi_dict = json.load(json_file)

    in_domain_data = []
    out_domain_data = []

    for rxn in data:

        tar_source_elem_list = get_SourceElem(rxn['Target'])[0]
        check_matrix = []
        for pre_set in rxn['Precursors']:
            # Check the tar_sourceelem_num == pre_sourceelem_num & single source elem per one precursor
            tar_source_num = len(tar_source_elem_list)
            pre_source_num = 0
            check1 = True
            total_pre_source_elem_list = []
            for pre in pre_set:
                pre_source_elem_list = get_SourceElem([pre])[0]
                p_sn = len(pre_source_elem_list)
                if p_sn != 1:
                    check1 = False
                pre_source_num += p_sn
                total_pre_source_elem_list += pre_source_elem_list
            if set(tar_source_elem_list) != set(total_pre_source_elem_list):
                check1 = False
            if tar_source_num != pre_source_num:
                check1 = False
            if check1 == False:
                check_matrix.append(False)
                continue

            # Check the precursor_anion_part is in pre_anion_part
            check2 = True
            for pre in pre_set:
                pre_source_elem_list = get_SourceElem([pre])[0]
                pre_anion = get_AnionPart(pre, pre_source_elem_list)
                if pre_anion not in pre_anion_part:
                    check2 = False
            if check2 == False:
                check_matrix.append(False)
                continue


            # Check the formula is in formulated composition (stoi ratio of source_elem + pre template)
            check3 = True
            for pre in pre_set:
                pre_source_elem_list = get_SourceElem([pre])[0]
                pre_anion = get_AnionPart(pre, pre_source_elem_list)
                if pre_anion in pre_anion_part:
                    formulated_comp_form = stoi_dict[pre_source_elem_list[0]+pre_anion]
                    if Composition(pre) != Composition(formulated_comp_form[0]):
                        check3 = False
            if check3 == False:
                check_matrix.append(False)
                continue
            
            check_matrix.append(check1 and check2 and check3)

        if True in check_matrix:
            in_domain_data.append(rxn)
        else:
            out_domain_data.append(rxn)

    print("Hypothetical in-domain ratio : ",len(in_domain_data)/len(data))
    
    return len(in_domain_data), len(in_domain_data)/len(data)


if __name__ == "__main__":
    data_fold = DataPreparation()

    # Calculate ideal upper bound accruacy (Maximum in-domain accuracy)
    
    summary_top1_result = []
    
    for key, data in data_fold.items():
        correct_n, accuracy = Calculate_IdealAccuracy(data)
        
        cv_result = {}
        cv_result["dataset"] = "random_cv"+key+".json"
        cv_result["accuracy"] = round(accuracy,4)
        cv_result["n_correct"] = correct_n
        cv_result["n_test"] = len(data)
        
        summary_top1_result.append(cv_result)
    
    file_path = "./results/perfect_elemwise/summary_top1.json"
    with open(file_path, 'w') as outfile:
        json.dump(summary_top1_result, outfile, indent=4)
    
