import json
import re
import numpy as np
import requests
import time
from tqdm import tqdm
from pymatgen.core import Composition


def doi2pubdate(data, your_scopus_apikey_list):
    def preparing_text_dataset(url, h):
        try:
            page_request = requests.get(url, headers=h)
            count = 0
            while page_request.status_code != 200:
                page_request = requests.get(url, headers=h)
                count += 1
                if count == 100:
                    print("Infinite recursive..")
                time.sleep(0.2)
            if count >= 100:
                print("Infinite recursive escape!")
            page = json.loads(page_request.content.decode("utf-8-sig"))
            articles_list = page['search-results']['entry']
            titles = []
            pubdates = []
            dois = []
            abstracts = []
            for article in articles_list:
                if article.get('dc:title'):
                    title = article['dc:title']
                else:
                    title = "N/A"
                if article.get('prism:coverDate'):
                    pubdate = article['prism:coverDate']
                else:
                    pubdate = "N/A"
                if article.get('prism:doi'):
                    doi = article['prism:doi']
                else:
                    doi = "N/A"
                if article.get('dc:description'):
                    abstract = article['dc:description']
                else:
                    abstract = "N/A"
                #
                titles.append(title)
                pubdates.append(pubdate)
                dois.append(doi)
                abstracts.append(abstract)
        except:
            print("\nRequests error, ", url, "\n")
            titles = ["N/A"]
            pubdates = ["N/A"]
            dois = ["N/A"]
            abstracts = ["N/A"]
        try:
            item_num = int(page['search-results']['opensearch:itemsPerPage'])
        except:
            print("\nItem_num error\n")
            item_num = 1
        try:
            total_num = int(page['search-results']['opensearch:totalResults'])
        except:
            print("\nTotal_num error\n")
            total_num = 9999999
        try:
            link_list = page['search-results']['link']
            next_url = "N/A"
            for link in link_list:
                if link['@ref'] == 'next':
                    next_url = link['@href']
        except:
            print("\nNext_url error\n")
            next_url = "N/A"
        try:
            remaining_num = int(page_request.headers["X-RateLimit-Remaining"])
            reset_time = time.ctime(int(str(page_request.headers["X-RateLimit-Reset"])[:-3]))
        except:
            print("\nRemaining_num & reset_time error\n")
            remaining_num = "Error"
            reset_time = "Error"
            #
        return titles, pubdates, dois, abstracts, item_num, total_num, next_url, remaining_num, reset_time

    def checking_apikey_remaining(url, h):
        page_request = requests.get(url, headers=h)
        try:
            remaining_num = int(page_request.headers["X-RateLimit-Remaining"])
        except:
            remaining_num = 0
        if remaining_num < 10:
            check = True
        else:
            check = False
        return check

    def encoding_keyword(keyword):
        encoded_keyword = re.sub("[(]", "%28", keyword)
        encoded_keyword = re.sub("[)]", "%29", encoded_keyword)
        encoded_keyword = re.sub("[/]", "%2f", encoded_keyword)
        return encoded_keyword

    api_resource = "http://api.elsevier.com/content/search/scopus"

    # headers
    headers = {}
    apikey_list = your_scopus_apikey_list
    ith_apikey = 0
    headers['X-ELS-APIKey'] = apikey_list[ith_apikey]
    headers['X-ELS-ResourceVersion'] = 'XOCS'
    headers['Accept'] = 'application/json'

    remaining_num = 0

    result = []
    for dd in tqdm(data):
        keyword = "DOI" + "(" + dd['doi'] + ")"
        encoded_keyword = encoding_keyword(keyword+ '+AND+(DOCTYPE(ar))')   # Article document type only
        query = "?query=" + encoded_keyword   #"KEYWORD" in author keyword
        cursor = "&cursor=*&count=25"
        condition = "&view=complete&sort=pubyear"
        field = "&field=doi,title,description,coverDate"
        #date = "&date=1900-2019"
        url = api_resource + query + cursor + condition + field

        if remaining_num < 10:
            while checking_apikey_remaining(url, headers):
                ith_apikey += 1
                time.sleep(0.1)
                if len(apikey_list) > ith_apikey:
                    headers['X-ELS-APIKey'] = apikey_list[ith_apikey]
                    print("Changing API key")
                else:
                    print("End API key list")
                    break

        titles, pubdates, dois, abstracts, item_num, total_num, url, remaining_num, reset_time = preparing_text_dataset(url, headers)

        rr = {}
        rr['Target'] = dd['Target']
        rr['Products'] = dd['Products']
        rr['Precursors'] = dd['Precursors']
        rr['doi'] = dd['doi']
        if (len(dois) == 1) and (dois[0] == dd['doi']) and (len(pubdates) == 1):
            rr['pubdate'] = pubdates[0]
        else:
            rr['pubdate'] = 'N/A'
        result.append(rr)

    return result

def get_ordered_syn_elem_library(data):

    def get_ElemCountDict(data):
        elem_count_dict = {}
        for i in range(len(data['reactions'])):
            for j in range(len(data['reactions'][i]['target']['composition'])):
                for key, value in data['reactions'][i]['target']['composition'][j]['elements'].items():
                    if key not in elem_count_dict.keys():
                        elem_count_dict[key] = 1
                    elif key in elem_count_dict.keys():
                        elem_count_dict[key] += 1
                    else:
                        print('error')
        #print(elem_count_dict)
        return elem_count_dict

    elem_count_dict = get_ElemCountDict(data)
    total_elem = [alkali_metal, alkaline_earth_metal, transition_metal, lanthanide_elem, actinide_elem, post_transition_metal, metalloid, non_metal, noble_gas, artificial_elem]

    #print(len(elem_library)) # 118

    syn_elem_library = []
    unsyn_elem_library = []
    for key, value in elem_count_dict.items():
        if (key in elem_library) and (value > 0):
            syn_elem_library.append(key)
        else:
            unsyn_elem_library.append(key)

    ordered_syn_elem_library = []
    for elem_group in total_elem:
        for i in elem_group:
            if i in syn_elem_library:
                ordered_syn_elem_library.append(i)

    return ordered_syn_elem_library


def select_CorrectlyParsedSynData(data, ordered_syn_elem_library):

    def rangedtemp_to_avgtemp(a):
        temp_list = []
        temp = None
        unit = 'Unlabeled'

        if a != None:
            for n in range(len(a)):
                if len(a[n]['values']) > 0:
                    temp_list += a[n]['values']
                    unit = a[n]['units']
                elif (len(a[n]['values']) == 0):
                    if (a[n]['max_value'] != None):
                        temp_list += [a[n]['max_value']]
                        unit = a[n]['units']
                    if (a[n]['min_value'] != None):
                        temp_list += [a[n]['min_value']]
                        unit = a[n]['units']
            if (len(temp_list)>0):
                temp = np.mean(np.array(temp_list)) # averaging
            if (unit != 'Unlabeled') and ('C' not in unit):
                temp = temp - 273
                unit = 'C'

        return temp, unit

    result = []
    result_for_PreTar = []
    filtered_data = []
    consistent_data_count = 0
    for i in range(len(data['reactions'])):
        syn = {}
        syn['Target'] = []
        syn['Precursors'] = []
        syn['Operation'] = []
        syn['doi'] = data['reactions'][i]['doi']

        syn_TP = {}
        syn_TP['Target'] = []
        syn_TP['Precursors'] = []
        syn_TP['doi'] = data['reactions'][i]['doi']

        original_rxn_string = data['reactions'][i]['reaction_string']

        # Before parsing, check the mismatched (inconsistent) cases
        # ['reaction', 'reaction_string', 'target', 'precursors']

        left_side_list = [item['material'] for item in data['reactions'][i]['reaction']['left_side']]
        right_side_list = [item['material'] for item in data['reactions'][i]['reaction']['right_side']]
        left_check = True
        for left in left_side_list:
            if left not in data['reactions'][i]['reaction_string'].split('==')[0].split():
                left_check = False
        right_check = True
        for right in right_side_list:
            if right not in data['reactions'][i]['reaction_string'].split('==')[1].split():
                right_check = False
        target_list = [item['formula'] for item in data['reactions'][i]['target']['composition']]
        precursor_list = [item2['formula']for item in data['reactions'][i]['precursors'] for item2 in item['composition']]
        tar_check = True
        for tar in target_list:
            if tar not in data['reactions'][i]['reaction_string'].split('==')[1].split():
                tar_check = False
        pre_check = True
        for pre in precursor_list:
            if pre not in data['reactions'][i]['reaction_string'].split('==')[0].split():
                pre_check = False
        if (left_check and right_check and tar_check and pre_check) == False:
            continue

        consistent_data_count += 1

        # Target parsing
        if len(data['reactions'][i]['target']['composition']) >= 1:
            for ii in range(len(data['reactions'][i]['target']['composition'])):
                tar_composition = data['reactions'][i]['target']['composition'][ii]['formula']
                original_tar_composition = re.sub('[*]', '', tar_composition)
                try:
                    comp = Composition(str(tar_composition))
                    if len(comp.get_el_amt_dict()) != 0:
                        check = True
                        for elem in comp.get_el_amt_dict().keys():
                            if elem not in ordered_syn_elem_library:
                                check = False
                        if check:
                            syn['Target'].append(str(tar_composition))
                            original_rxn_string = original_rxn_string.replace(original_tar_composition, str(tar_composition))
                except:
                    # x, y, z in stoi case
                    element = data['reactions'][i]['target']['composition'][ii]['elements']
                    amount_var = data['reactions'][i]['target']['amounts_vars']
                    try:
                        tar_compound_name = ""
                        for elem, stoi in element.items():
                            if re.search("[a-zA-Z]", stoi) != None:
                                check = True
                                var_s = re.findall("[a-zA-Z]", stoi)
                                for var in var_s:
                                    if len(amount_var[var]['values']) != 0:
                                        stoi = re.sub(var, str(round(np.mean(amount_var[var]['values']),3)), stoi)
                                    elif (amount_var[var]['max_value'] != None) and (amount_var[var]['min_value'] != None):
                                        stoi = re.sub(var, round((amount_var[var]['max_value']+amount_var[var]['min_value'])/2,3), stoi)
                                    elif amount_var[var]['max_value'] != None:
                                        stoi = re.sub(var, round(amount_var[var]['max_value'],3), stoi)
                                    elif amount_var[var]['min_value'] != None:
                                        stoi = re.sub(var, round(amount_var[var]['min_value'],3), stoi)
                                    else:
                                        check = False
                                if check:
                                    stoi = eval(stoi)
                                    if (round(stoi,3) > 15) or (round(stoi,3) < 0):
                                        raise NotImplementedError()
                                    stoi = str(round(stoi,3))
                            #if stoi != '0':
                            if float(stoi) != 0:
                                tar_compound_name += elem + stoi

                        comp = Composition(str(tar_compound_name))
                        if len(comp.get_el_amt_dict()) != 0:
                            check = True
                            for elem in comp.get_el_amt_dict().keys():
                                if elem not in ordered_syn_elem_library:
                                    check = False
                            if check:
                                comp = Composition(str(tar_compound_name))
                                syn['Target'].append(str(tar_compound_name))
                                original_rxn_string = original_rxn_string.replace(original_tar_composition, str(tar_compound_name))
                    except:
                        pass # skip vague composition cases

        # Precursors parsing
        for j in range(len(data['reactions'][i]['precursors'])):
            if len(data['reactions'][i]['precursors'][j]['composition']) == 1:
                pre_composition = data['reactions'][i]['precursors'][j]['composition'][0]['formula']
                original_pre_composition = pre_composition
                try:
                    pre_composition = re.sub('[^()1-9]?[1-9]?H2O', '', pre_composition)
                    comp = Composition(str(pre_composition))
                    if len(comp.get_el_amt_dict()) != 0:
                        check = True
                        for elem, stoi in comp.items():
                            if str(elem) not in ordered_syn_elem_library:
                                check = False
                        if str(pre_composition) == 'FeC2O4.2H20': pre_composition = 'FeC2O4'
                        if str(pre_composition) in ['C4H6Mn','PO(OC4H9)4','Fe(CH3CHOHCOO)2','CoCO3.3Co(OH)2']: check = False
                        if check:
                            syn['Precursors'].append(str(pre_composition))
                            original_rxn_string = original_rxn_string.replace(original_pre_composition, str(pre_composition))
                except:
                    pass # skip vague composition cases

            elif len(data['reactions'][i]['precursors'][j]['composition']) > 1:
                pass # skip vague or multi_counter_part cases

        # Operation parsing
        for j in range(len(data['reactions'][i]['operations'])):
            a = data['reactions'][i]['operations'][j]['type']
            T = 0
            if a == 'StartingSynthesis':    a = 'Start'
            elif a == 'HeatingOperation':   a = 'Heat'
            elif a == 'QuenchingOperation': a = 'Quench'
            elif a == 'DryingOperation':    a = 'Dry'
            elif a == 'MixingOperation':
                a = 'Mix'
            elif a == 'ShapingOperation':
                a = 'Shape'
            T = data['reactions'][i]['operations'][j]['conditions']['heating_temperature']
            T, u = rangedtemp_to_avgtemp(T) # unit : Celsius
            if T != None:
                if (T<=300)or(T>1600)or(a=='Start')or(a=='Quench')or(a=='Dry')or(a=='Mix')or(a=='Shape'):
                    T = None
            if T != None:
                syn['Operation'].append([a, round(T,1)])


        syn['rxn_string'] = original_rxn_string
        # Collect Data
        if (len(syn['Target'])!=0) and (len(syn['Precursors']) not in [0, 1]) and (len(syn['Operation']) != 0):
            result.append(syn)
        else:
            filtered_data.append(syn)

        # dataset which only contains Target & Precursors
        if (len(syn['Target'])!=0) and (len(syn['Precursors']) not in [0, 1]):
            syn_TP['Target'] = syn['Target']
            syn_TP['Precursors'] = syn['Precursors']
            syn_TP['rxn_string'] = syn['rxn_string']
            result_for_PreTar.append(syn_TP)

    print(consistent_data_count, len(data['reactions'])-consistent_data_count, consistent_data_count-len(result_for_PreTar))

    return result, filtered_data, result_for_PreTar


def add_GasPhase(PreparedData):
    # Complete reaction (products and reactants) e.g., CO2, H2O, etc..
    CompleteRxn_Data = []
    NonCompleteRxn_Data = []
    for i, dd in enumerate(PreparedData):
        syn_data = {}
        syn_data['Target'] = dd['Target']
        syn_data['Products'] = []
        for comp in dd['Target']:
            syn_data['Products'].append(comp)
        syn_data['Precursors'] = []
        for comp in dd['Precursors']:
            syn_data['Precursors'].append(comp)
        syn_data['doi'] = dd['doi']

        left_part, right_part = dd['rxn_string'].split('==')
        reactants = left_part.split(' +')
        reactants = [a.split()[-1] for a in reactants]
        products = right_part.split(' +')
        products = [a.split()[-1] for a in products]
        products2 = []
        for p in products:
            p_list = p.split('-')
            for pp in p_list:
                pp = re.sub('^[0-9.]+', '', pp)
                pp = re.sub('^[xyz][)]', '', pp)
                pp = re.sub('^[xyz]', '', pp)
                pp = re.sub('^[(][xyz][(]', '', pp)
                pp = re.sub('^[(][0-9]+', '', pp)
                pp = re.sub('^[.][0-9]+', '', pp)
                pp = re.sub('^[+][0-9]+[)][)]', '', pp)
                pp = re.sub('^[xyz][)]', '', pp)
                if pp != '':
                    products2.append(pp)

        check = 1
        for a in reactants:
            if a not in dd['Precursors']:
                if a in ['CO2','H2O','O2','NH3','NH4OH']:
                    syn_data['Precursors'].append(a)
                elif a in [']','[NO3','[OH-]']:
                    check = 2
                else:
                    #print(a)
                    check = 3

        for a in products2:
            if a not in dd['Target']:
                if a in ['CO2','H2O','O2','NH3','NH4OH']:
                    syn_data['Products'].append(a)
                elif a in [']','[NO3','[OH-]','[CH3COO']:
                    check = 2
                else:
                    #print(a)
                    check = 3
        if check == 1:
            CompleteRxn_Data.append(syn_data)
        elif check == 2:
            NonCompleteRxn_Data.append(syn_data)
        else:
            NonCompleteRxn_Data.append(dd)

    return CompleteRxn_Data, NonCompleteRxn_Data

def select_ElemConservation(PreparedData):
    # check the elemental balance
    ElemConserved_Data = []
    ElemNonConserved_Data = []

    elem_dif_count_dict = {}
    #count = 0
    for i in range(len(PreparedData)):
        tar_elems = []
        for t in PreparedData[i]['Products']:
            elems = list(Composition(t).get_el_amt_dict())
            tar_elems.extend(elems)
        tar_elems = list(set(tar_elems))

        pre_elems = []
        for t in PreparedData[i]['Precursors']:
            elems = list(Composition(t).get_el_amt_dict())
            pre_elems.extend(elems)
        pre_elems = list(set(pre_elems))

        elem_diff = []
        for t_e in tar_elems:
            if t_e not in pre_elems:
                elem_diff.append('+'+t_e)
        for p_e in pre_elems:
            if p_e not in tar_elems:
                elem_diff.append('-'+p_e)
        elem_diff.sort()

        should_be_conserved_elem = []
        for ee in inorg_elem:
            should_be_conserved_elem.append('+'+ee)
            should_be_conserved_elem.append('-'+ee)

        conservation_check = True
        for ee in elem_diff:
            if ee in should_be_conserved_elem:
                conservation_check = False


        if str(elem_diff) not in elem_dif_count_dict.keys():
            elem_dif_count_dict[str(elem_diff)] = 1
        else:
            elem_dif_count_dict[str(elem_diff)] += 1

        # It's okay cases,
        if str(elem_diff) in ['[]']:                 # Conserved rxn
            ElemConserved_Data.append(PreparedData[i])
        # Forbidden cases,
        elif conservation_check == False:
            ElemNonConserved_Data.append(PreparedData[i])
        # Ambiquous cases,
        else:
            if str(elem_diff) not in elem_dif_count_dict.keys():
                elem_dif_count_dict[str(elem_diff)] = 1
            else:
                elem_dif_count_dict[str(elem_diff)] += 1
            """
            [("['+Br', '-C']", 1),
             ("['+I']", 1),
             ("['+H', '+P']", 1),
             ("['+Br', '-H']", 1),
             ("['+Cl']", 1),
             ("['+Br', '-C', '-H', '-N']", 1),
             ("['+Cl', '-C', '-H']", 1),
             ("['+S']", 1),
             ("['+P', '-C', '-H']", 1),
             ("['+N']", 2),
             ("['+S', '-C']", 3),
             ("['-Se']", 5),
             ("['+Cl', '-C', '-H', '-N']", 5),
             ("['+P', '-C']", 10),
             ("['+Cl', '-C']", 13)]
            """
            ElemNonConserved_Data.append(PreparedData[i])

    #sorted_dict = sorted(elem_dif_count_dict.items(), key= lambda item:item[1])

    return ElemConserved_Data, ElemNonConserved_Data


def select_SingleProduct(PreparedData):
    # check the number of phase in target part
    SingleProduct_Data = []
    MultiProduct_Data = []

    for i in range(len(PreparedData)):
        if len(PreparedData[i]['Target']) == 1:
            SingleProduct_Data.append(PreparedData[i])
        else:
            MultiProduct_Data.append(PreparedData[i])

    return SingleProduct_Data, MultiProduct_Data


def select_10above_nonsourced_precursor_case(PreparedData):
    # Erase such as O2O3, I, H2, H, N2, N, ... in precursors cases
    Selected_Data = []
    Filtered_Data = []

    # Count the number of precursor usage.
    product_nonsource_dict = {}
    precursor_nonsource_dict ={}
    for dd in PreparedData:
        for pp in dd['Products']:
            pp_elem_list = list(Composition(pp).get_el_amt_dict().keys())
            count = 0
            for elem in pp_elem_list:
                if elem in inorg_elem:
                    count += 1
            if count == 0:
                if pp not in product_nonsource_dict:
                    product_nonsource_dict[pp] = 1
                else:
                    product_nonsource_dict[pp] += 1
        for pp in dd['Precursors']:
            pp_elem_list = list(Composition(pp).get_el_amt_dict().keys())
            count = 0
            for elem in pp_elem_list:
                if elem in inorg_elem:
                    count += 1
            if count == 0:
                if pp not in precursor_nonsource_dict:
                    precursor_nonsource_dict[pp] = 1
                else:
                    precursor_nonsource_dict[pp] += 1

    for dd in PreparedData:
        precursor_usednumber_list = []
        for pp in dd['Precursors']:
            pp_elem_list = list(Composition(pp).get_el_amt_dict().keys())
            count = 0
            for elem in pp_elem_list:
                if elem in inorg_elem:
                    count += 1
            if count == 0:
                precursor_usednumber_list.append(precursor_nonsource_dict[pp])
        if len(precursor_usednumber_list) == 0:
            check = True
        else:
            if min(precursor_usednumber_list) >= 10:
                check = True
            else:
                check = False
        if check:
            Selected_Data.append(dd)
        else:
            Filtered_Data.append(dd)
    return Selected_Data, Filtered_Data

def delete_NonPrecursorCompound(PreparedData):
    """
    Remove NonPrecursorCompound (e.g., O2, H2O)
    """
    result = []
    non_precursor_compound_list = [Composition('O2'), Composition('H2O')]
    for i in range(len(PreparedData)):
        syn_data = PreparedData[i]

        # Create the new precursor set by removing the NonPrecursorCompound
        removed_precursor_part = []
        for pre in PreparedData[i]['Precursors']:
            if Composition(pre) in non_precursor_compound_list:
                pass
            else:
                removed_precursor_part.append(pre)

        # Fix the precursor part
        syn_data['Precursors'] = removed_precursor_part
        result.append(syn_data)
    return result


def remove_Duplicate(data):
    result = []
    tar_pre_dict = {}
    for i in range(len(data)):
        tar_list = data[i]['Target']
        tar_list.sort()

        pre_list = data[i]['Precursors']
        pre_list.sort()

        tar = str(tar_list)
        pre = str(pre_list)
        tar_pre = tar + '<=' + pre

        pubdate = data[i]['pubdate']

        if tar_pre not in tar_pre_dict:
            tar_pre_dict[tar_pre] = []
            tar_pre_dict[tar_pre].append([i,pubdate])
        else:
            tar_pre_dict[tar_pre].append([i,pubdate])

    for tar_pre, value in tar_pre_dict.items():
        if len(value) == 1:
            idx, pubdate = value[0]
            result.append(data[idx])
        else:
            idx_pubdate_dict = {}
            for d in value:
                idx, pubdate = d
                idx_pubdate_dict[idx] = pubdate

            sorted_dict = sorted(idx_pubdate_dict.items(), key= lambda item:item[1])
            #print(sorted_dict)
            result.append(data[sorted_dict[0][0]])

    return result


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
def DataPreparation(scopus_apikey_list):
    # Text-mined dataset load
    with open("data/solid-state_dataset_20200713.json", 'r', encoding='utf-8-sig') as json_file:
        data = json.load(json_file) # 31782
    ordered_syn_elem_library = get_ordered_syn_elem_library(data)   # target_elem in elem_library

    data_TPO, f, data_TP = select_CorrectlyParsedSynData(data, ordered_syn_elem_library)
    print(len(data_TP))     # 19588
    CompleteRxn_Data, NonCompleteRxn_Data = add_GasPhase(data_TP)
    print(len(CompleteRxn_Data), len(NonCompleteRxn_Data))          # 19071,  517
    ElemConserved_Data, ElemNonConserved_Data = select_ElemConservation(CompleteRxn_Data)
    print(len(ElemConserved_Data), len(ElemNonConserved_Data))      # 18869,  202
    SingleProduct_Data, MultiProduct_Data     = select_SingleProduct(ElemConserved_Data)
    print(len(SingleProduct_Data), len(MultiProduct_Data))          # 18869,  0
    Selected_Data, Filtered_Data = select_10above_nonsourced_precursor_case(SingleProduct_Data)
    print(len(Selected_Data), len(Filtered_Data))                   # 18786,  83
    Selected_Data = delete_NonPrecursorCompound(Selected_Data)

    Selected_Data_withPubdate = doi2pubdate(Selected_Data, your_scopus_apikey_list=scopus_apikey_list)

    file_path = "./dataset/Selected_Data_withPubdate.json"
    with open(file_path, 'w') as outfile:
        json.dump(Selected_Data_withPubdate, outfile, indent=4)

    Selected_Data_withPubdate_duplicate_removed = remove_Duplicate(Selected_Data_withPubdate)
    print(len(Selected_Data_withPubdate_duplicate_removed))     # 11923

    file_path = "./dataset/Selected_Data_withPubdate (duplicate removed).json"
    with open(file_path, 'w') as outfile:
        json.dump(Selected_Data_withPubdate_duplicate_removed, outfile, indent=4)


if __name__ == "__main__":
    print("\n---------------------------------------------------------------------------------")
    print("List of your apikey is necessary to extract publication year information from DOI")
    print("---------------------------------------------------------------------------------\n")
    scopus_apikey_list = []
    apikey = input("Enter the apikey : (If you want to end typing the apikey, just type 'enter') \n")
    while True:
        if apikey not in ['', 'enter']:
            scopus_apikey_list.append(apikey)
        else:
            break
        apikey = input()
    """
    ---------------------------------------
        Example of scopus_apikey_list
    ---------------------------------------
    scopus_apikey_list = ['aaaaabbbbbcccccddddd00001', 'aaaaabbbbbcccccddddd00002',
                          'aaaaabbbbbcccccddddd00003', 'aaaaabbbbbcccccddddd00004',
                          'aaaaabbbbbcccccddddd00005', 'aaaaabbbbbcccccddddd00006',
                          'aaaaabbbbbcccccddddd00007', 'aaaaabbbbbcccccddddd00008']
    """
    DataPreparation(scopus_apikey_list)
