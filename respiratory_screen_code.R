###Title: eMERGE COVID Respiratory Symptom Identifier
###Author: Zachary Strasser
###Date: 12/21/21
###Purpose: Takes two specific CSV files extracted from an EHR and generates multiple files for chart review and data analysis

#load libraries
library('dplyr')
library('tidyr')
library('data.table')
library('UpSetR')
library('mltools')

#Load CSV 1 into csv_patient_list. 
#CSV 1 is made up of 3 columns - Patient Identifier,  Positive Covid Date (YYYY-MM-DD), Defines COVID diagnosis by either ICD or Lab Test
csv_patient_list <- read_csv(csv_patient_list.csv)

#rename the three columns
names(csv_patient_list) <-c('patient_ID', 'COVID_date', "COVID_type")

#CSV 2 is made up of 4 columns - Patient Identifier, Concept Type (either 'ICD', 'RxNorm', or 'CPT'), Concept ID, Concept Date (YYYY-MM-DD)
#####ICD's should be ICD10 with period removed
#####RxNorm for that medication
#####CPT for
csv_concepts <- read_csv(csv_concepts.csv)

#rename the three columns
names(csv_concepts)<-c('patient_ID', 'Concept_type', 'Concept_ID', 'Concept_date')

#######create groups of respiratory concepts

#pneumonia (except that caused by tuberculosis) as defined by CCSR
pneumonia = c('A0103',	'A0222',	'A202',	'A212',	'A221',	
              'A310',	'A3701',	'A3711',	'A3781',	'A3791',	
              'A430',	'A481',	'A5004',	'A5272',	'A5484',	
              'B012',	'B052',	'B0681',	'B250',	'B371',	'B380',	
              'B381',	'B382',	'B390',	'B391',	'B392',	'B583',	'B59',	
              'B7781',	'J09X1',	'J1000',	'J1001',	'J1008',	'J1100',	
              'J1108',	'J120',	'J121',	'J122',	'J123',	'J1281',	'J1282',	
              'J1289',	'J129',	'J13',	'J14',	'J150',	'J151',	'J1520',	
              'J15211',	'J15212',	'J1529',	'J153',	'J154',	'J155',	'J156',	
              'J157',	'J158',	'J159',	'J160',	'J168',	'J17',	'J180',	
              'J181',	'J188',	'J189',	'J851',	'J95851',
              'A0103',	'A0222',	'A202',	'A212',	'A221',	
              '0310',	'4843',	
              '48284',	'0951',	
              '0521',	'0551',	'05679',	'4841',	'1124',	'1140',	
              '1144',	'1145',	'11505',	'1304',	'1363',	
              '1270',	'48801', '48811', '48881', '4870',	
              '4800',	'4801',	'4802',	'J123',	'4803',	
              '4808',	'4809', '4870',	'481',	'4822',	'4820',	'4821',	'48240',	
              '48241',	'48242',	'48249',	'48232',	'48230', '48231', '48239',	'48282',	'48283',	
              '4830',	'48281',	'48289',	'4829',	'4831',	'4838',	
              '0730', '11515', '11595', '4847', '4848', '5171',	
              '485', '481',	'J188',	'486',	'5130',	'99731'
)

#COPD and bronchiectasis defined by CCSR
COPD = c('J410',	'J411',	'J418',	'J42',	'J430',	
         'J431',	'J432',	'J438',	'J439',	'J440',	
         'J441',	'J449',	'J470',	'J471',	'J479',
         '4910',	'4911',	'4918',	'4919',	'4920', 
         '4928',	'49122', '49321', '49121', 
         '49122',	'49120', '49320', '496', 
         '4941',	'4940'
)

#asthma defined by CCSR
asthma = c('J4520',	'J4521',	'J4522',	'J4530',	'J4531',	
           'J4532',	'J4540',	'J4541',	'J4542',	'J4550',	
           'J4551',	'J4552',	'J45901',	'J45902',	'J45909',	
           'J45990',	'J45991',	'J45998',
           '49300', '49310',	'49302', '49312',	'49301', '49311',	
           'J4551',	'J4552',	'49392',	'49391',	'49390',	
           '49381',	'49382',	'49390')

#respiratory failure; insufficiency; arrest defined by CCSR
resp_failure = c('J80',	'J95821',	'J95822',	'J9600',	'J9601',	'J9602',	'J9610',	
                 'J9611',	'J9612',	'J9620',	'J9621',	'J9622',	'J9690',	
                 'J9691',	'J9692',	'R092',
                 '51882',	'51851',	'51853',	'51881',	'51883',	'7991'
)

#other specified and unspecified low resp disease defined by CCSR
lower_resp = c('A065',	'A157',	'A158',	'A159',	'B400',	'B401',	'B402',	'B410',	
               'B420',	'B440',	'B441',	'B450',	'B460',	'B671',	'J182',	'J22',	
               'J810',	'J811',	'J82',	'J8281',	'J8282',	'J8283',	'J8289',	
               'J8401',	'J8402',	'J8403',	'J8409',	'J8410',	'J84111',	'J84112',	
               'J84113',	'J84114',	'J84115',	'J84116',	'J84117',	'J8417',	
               'J84170',	'J84178',	'J842',	'J8481',	'J8482',	'J8483',	
               'J84841',	'J84842',	'J84843',	'J84848',	'J8489',	'J849',	
               'J852',	'J9801',	'J9809',	'J984',	'J986',	'J988',	'J989',	
               'J99',	'M0510',	'M05111',	'M05112',	'M05119',	'M05121',	'M05122',	
               'M05129',	'M05131',	'M05132',	'M05139',	'M05141',	'M05142',	
               'M05149',	'M05151',	'M05152',	'M05159',	'M05161',	'M05162',	
               'M05169',	'M05171',	'M05172',	'M05179',	'M0519',
               '0064',	'01000', '01001', '01002', '01003', '01004', '01005', '01006', '01080',
               '01081', '01082', '01083', '01084', '01085', '01086', '01090', '01091',
               '01092', '01093', '01094', '01095', '01096',
               '01280',	'01281',	'01282',	'01283', '01284',	'01285',	'01286',
               '1161',	'1171',	'4846',	'1175',	'1221',	'514',	
               '5184',	'514',	'5183',		'5160',	'5162',	'5161',	'5168',	'515',	'51630',	'51631',	
               '51632',	'51633',	'51634',	'51636',	'51637',	
               '51635',	'5164',	'5165',	'51663',	
               '51661',	'51662',	'51664',	'51669', '515',	'5169',	
               '5130',	'51911',	'51919',	'51889',	'5194',	'5198',	'5199',	
               '5178',	'71481'
)

#resp signs and symptoms defined by CCSR
resp_signs_symptoms = c('R040',	'R041',	'R042',	'R0481',	'R0489',	'R049',	'R05',	
                        'R0600',	'R0601',	'R0602',	'R0603',	'R0609',	'R061',	
                        'R062',	'R063',	'R064',	'R065',	'R066',	'R067',	'R0681',	
                        'R0682',	'R0683',	'R0689',	'R069',	'R070',	'R071',	'R0781',	
                        'R0782',	'R0901',	'R0902',	'R093',	'R0981',	'R0982',
                        '7847', '7848', '78630', '78631', '78639', '78630', '7862',
                        '78609', '78602', '78605', '51882', '78609', '7861', '78607',
                        '78604', '78601', '7868', '78603', '78606', '78601', '7841', '78652',
                        '79901', '79902', '7864', '78491'
)

######group medications

#short_acting_bronchodilator - all RxNorm codes represents all meds with albuterol and levalbuterol
#includes generics albuterol and levalbuterol found in RxNorm
SABA = c('151539',	'202908',	'285059',	'352394',	'647295',	'8887',	'435',	'1008406',	
         '214199',	'812737',	'818865',	'142153',	'859088',	'1437704',	'2166797',	
         '1649961',	'352051',	'1190225',	'801095',	'746763',	'745752',	'1190222',	
         '573621',	'1437703',	'575803',	'1649958',	'801093',	'746762',	'801094',	
         '1649967',	'1649959',	'2108261',	'2108228',	'2284638',	'245314',	'755497',	
         '630208',	'199924',	'2166796',	'247840',	'104514',	'2123076',	'153741',	
         '2123072',	'153742',	'392321',	'1437702',	'1649560',	'351136',	'351137',	
         '745679',	'197318',	'1190220',	'386998',	'197316',	'248066',	'359144',	
         '252298',	'359145',	'801092',	'2123111',	'315288',	'329498',	'329499',	
         '330648',	'330935',	'332347',	'340169',	'343177',	'346188',	'353441',	
         '353535',	'360330',	'393289',	'405969',	'2108243',	'2108264',	'2108368',	
         '370542',	'370543',	'370790',	'379496',	'544499',	'745678',	'1649559',	'2108226',	
         '2108233',	'2108259',	'2284636',	'1154598',	'1154602',	'1154603',	'1154604',	
         '1154605',	'1154606',	'1649960',	'1165995',	'1166889',	'1166997',	'1182471',	'1187868',
         '237159',	'237160',	'487066',	'1855391',	'833470',	'261136',	'352132',	'746466',	'574380',	
         '575869',	'630765',	'833469',	'1855390',	'746465',	'2108213',	'242754',	'745791',	'1855389',	
         '349590',	'311286',	'346137',	'346138',	'350963',	'597907',	'1855388',	'745790',	'2108209',	
         '1163444',	'1186445',	'261702')

#consists of ipratropium and it's derivatives from RxNorm Nav
SAMA = c('151390',	'151539',	'285059',	'7213',	'214199',	'203212',	'1445143',	'1546373',	'1309404',	
         '1437704',	'1190225',	'836368',	'836367',	'1190222',	'1437703',	'746449',	'2108261',	
         '2284638',	'836343',	'1190220',	'1437702',	'836358',	'1797833',	'1797844',	'836280',	
         '836291',	'836342',	'836357',	'1437701',	'1190219',	'746447',	'1797832',	'2108259',	
         '2108449',	'2284636',	'1154598',	'1158614',	'1158615',	'1166889',	'1166997',	'1173573')

#salmeterol, formoterol, arformoterol, indacaterol, vilanterol, olaodaterol, and derivatives, 
LABA = c('203159',	'301543',	'1918195',	'36117',	'284635',	'72616',	'1918199',	'1918211',	'2110516',	
         '2395831',	'2395834',	'2110513',	'2110510',	'896237',	'1918205',	'896229',	'896165',	'896185',	
         '896273',	'896235',	'896212',	'896245',	'896222',	'896243',	'896190',	'866047',	'2395828',	'866049',	
         '896271',	'866045',	'896163',	'896188',	'896220',	'896233',	'896241',	'896269',	'2395827',	'2395830',	
         '2395833',	'2110507',	'2110512',	'2110515',	'866046',	'896189',	'896270',	'1918197',	'2110508',	
         '2395832',	'1918203',	'2395826',	'896239',	'896228',	'896236',	'896209',	'1918209',	'896218',	
         '896231',	'896186',	'896272',	'896184',	'896267',	'896244',	'2395829',	'866044',	'896161',	'866048',	
         '1918194',	'328641',	'331524',	'2395825',	'744485',	'746717',	'866043',	'1158502',	'1165654',	'1180757',	
         '1171309',	'1918198', '152611',	'327148',	'723732',	'1372704',	'1790640',	'2205095',	'2387325',	'25255',	
         '1002293',	'389132',	'1790638',	'2205093',	'2387330',	'236216',	'998038',	'2196592',	'1246313',	'2205099',	
         '1246315',	'1246328',	'1246306',	'1246317',	'2387328',	'1246321',	'1246310',	'2205104',	'1660938',	
         '1790644',	'2387331',	'1660934',	'1246290',	'1799451',	'1246289',	'1246305',	'1246320',	'1246309',	
         '1246312',	'2196591',	'1790641',	'2205096',	'2387327',	'745810',	'998049',	'1790642',	'2108405',	
         '2108397',	'2205097',	'2387323',	'1246308',	'1246319',	'2196590',	'2205094',	'2205103',	
         '1246311',	'1246314',	'1246316',	'1246326',	'1246304',	'1246288',	'2387329',	'1660937',	
         '1790639',	'2387326',	'1660933',	'1790634',	'1799449',	'1246287',	'1246307',	'1246318',	
         '2205090',	'745797',	'998040',	'1790637',	'2205092',	'2108395',	'2108402',	'2386036',	
         '1156069',	'1165644',	'1165648',	'2205091',	'2109870',	'2386035',	'1185492',	'1166984',	
         '1172619',	'1185816',	'2205098',	'1790643',	'2387324', '669390',	'304962',	'668284',	'695935',	
         '695933',	'2108278',	'668956',	'668954',	'2108276',	'1158257',	'1167345', '1114326',	'1721575',	'1114325',	
         '1720953',	'1114333',	'1799457',	'1721577',	'2108447',	'2108415',	'1720948',	'1114329',	'1721572',	
         '1799455',	'2108413',	'2108445',	'1160688',	'2109874',	'1170103',	'1720952',	'1114330',	'1720949', '1945040',	
         '1487520',	'1539887',	'1424884',	'1945038',	'1424888',	'1487518',	'1424883',	'1945048',	'1648789',	'2395775',	
         '1539893',	'1487528',	'1648785',	'1487524',	'1945044',	'1539891',	'2395771',	'1945041',	'2395770',	'1487521',	
         '1539888',	'1648784',	'1945042',	'1487522',	'1539889',	'1648788',	'1945047',	'1424889',	'1487527',	'1424899',	
         '1945039',	'1487519',	'1648783',	'2395769',	'2395774',	'1424885',	'1945037',	'1424887',	'1487517',	'1945036',	
         '1424886',	'1487516',	'1945043',	'1539890',	'1487523', '1945040',	'1487520',	'1539887',	'1424884',	'1945038',	
         '1424888',	'1487518',	'1424883',	'1945048',	'1648789',	'2395775',	'1539893',	'1487528',	'1648785',	'1487524',	
         '1945044',	'1539891',	'2395771',	'1945041',	'2395770',	'1487521',	'1539888',	'1648784',	'1945042',	'1487522',	
         '1539889',	'1648788',	'1945047',	'1424889',	'1487527',	'1424899',	'1945039',	'1487519',	'1648783',	'2395769',	
         '2395774',	'1424885',	'1945037',	'1424887',	'1487517',	'1945036',	'1424886',	'1487516',	'1945043',	'1539890',	
         '1487523')

#tiotropium, umecledium, aclidinium and derivtives
LAMA = c('274535',	'1651267',	'69120',	'1658460',	'393575',	'1552007',	'1298831',	'2462023',	'2166204',	'1651271',	
         '1667882',	'1552004',	'2166928',	'1651275',	'1667886',	'580261',	'1552009',	'1551897',	'1667881',	'1799463',	
         '1658462',	'2108546',	'2284622',	'2284648',	'2166203',	'1552008',	'1667880',	'1552002',	'1651274',	'1667885',	
         '485032',	'2166927',	'1651266',	'1551894',	'1667879',	'1799461',	'2108544',	'2284620',	'2284646',	'1658458',	
         '1162108',	'1651270',	'1177261', '1303103',	'2205095',	'1303098',	'2205093',	'1303097',	'1607112',	'1303107',	
         '2205104',	'2205099',	'1303104',	'2205096',	'1303105',	'2205097',	'1607111',	'2205094',	'2205103',	'1303102',	
         '1303099',	'1303101',	'2205092',	'1303100',	'2205091',	'1303106',	'2205098', '1945040',	'1487520',	'1539881',	
         '1487514',	'1945038',	'1487518',	'1487512',	'1945048',	'1539885',	'2395775',	'1487528',	'1487524',	'1596445',	
         '1945044',	'2395771',	'1945041',	'2395770',	'1487521',	'1539882',	'1945042',	'1487522',	'1539883',	'1945047',	
         '1487527',	'1945039',	'1487519',	'2395769',	'1596444',	'2395774',	'1539251',	'1487515',	'1945037',	'1487517',	
         '1539250',	'1945036',	'1487516',	'1539249',	'1945043',	'1487523',	'1539884')

#######group procedures

#multiple oxygen testing
mult_oxy = c('94761')

#pulmonary functioning test - spirometry, lung volume, diffusion capacity
PFT = c('94010', '94011', '940212', '94060', '94070', '94150', 
        '94200', '94375', '94726', '94727', '94729', '94013', '94726', '94727', 
        '94728', '94729')

#pulmonary stress test
PST = c('96417', '96418', '94619', '96421')

####label the original concept codes by the names of the above groups

#create a new column for concept names
csv_concepts['code_label'] <- NA

#label codes in the column that are related to resp 
csv_concepts = mutate(csv_concepts, code_label = case_when(csv_concepts$Concept_ID %in% pneumonia & csv_concepts$Concept_type=="ICD" ~ "PNA", 
                                                           csv_concepts$Concept_ID %in% COPD & csv_concepts$Concept_type=="ICD" ~ "COPD",
                                                           csv_concepts$Concept_ID %in% asthma & csv_concepts$Concept_type=="ICD" ~ 'asthma',
                                                           csv_concepts$Concept_ID %in% resp_failure & csv_concepts$Concept_type=="ICD" ~ "resp_failure",
                                                           csv_concepts$Concept_ID %in% lower_resp & csv_concepts$Concept_type=="ICD" ~ 'lower_resp',
                                                           csv_concepts$Concept_ID %in% resp_signs_symptoms & csv_concepts$Concept_type=="ICD" ~ 'resp_signs_symptoms', 
                                                           csv_concepts$Concept_ID %in% SABA & csv_concepts$Concept_type=="RxNorm" ~ 'SABA',
                                                           csv_concepts$Concept_ID %in% SAMA & csv_concepts$Concept_type=="RxNorm" ~ 'SAMA',
                                                           csv_concepts$Concept_ID %in% LABA & csv_concepts$Concept_type=="RxNorm" ~ 'LABA',
                                                           csv_concepts$Concept_ID %in% LAMA & csv_concepts$Concept_type=="RxNorm" ~ 'LAMA',
                                                           csv_concepts$Concept_ID %in% mult_oxy & csv_concepts$Concept_type=="CPT" ~ 'mult_oxy',
                                                           csv_concepts$Concept_ID %in% PFT & csv_concepts$Concept_type=="CPT" ~ 'PFT',
                                                           csv_concepts$Concept_ID %in% PST & csv_concepts$Concept_type=="CPT" ~ 'PST'))

#remove the above groupings
rm(asthma, COPD, LABA, LAMA, lower_resp, mult_oxy, PFT, pneumonia, PST, resp_failure, resp_signs_symptoms, SABA, SAMA)

########prepare the two data tables for merging##############################################################
#delete duplicate rows in patient list
csv_patient_list = unique(csv_patient_list)
csv_patient_list = csv_patient_list[,c('patient_ID', 'COVID_date')]
csv_patient_list = unique(csv_patient_list)

#delete any csv_concepts without values
csv_concepts = csv_concepts[!(csv_concepts$Concept_ID==''),]

#only keep rows that have a code name
csv_concepts = csv_concepts[!is.na(csv_concepts$code_label),]

#keep only unique rows for the conepts
csv_concepts = unique(csv_concepts)

#only include patient_ids that have at least one resp label
csv_patient_list = csv_patient_list[csv_patient_list$patient_ID %in% csv_concepts$patient_ID,]
csv_patient_list = csv_patient_list[!duplicated(csv_patient_list$patient_ID),]

#left join (make sure row number does not change for csv_concepts in this step)
#####this will need to be inserted: 
csv_concepts$patient_ID = as.integer(csv_concepts$patient_ID)
csv_concepts = left_join(csv_concepts, csv_patient_list, by= 'patient_ID')
#make should now match the number of rows in csv_concepts

#make sure date columns are both in the right format 
csv_concepts$Concept_date = as.Date(csv_concepts$Concept_date)
csv_concepts$COVID_date = as.Date(csv_concepts$COVID_date)

#######CREATE A NEW COLUMN FOR IDENTIFYING NEW RESPIRATORY SYMPTOMS###########################################

#for each concept, find patients that have this resp code used at greater than than 89-365 days after COVID
#find patients that had the resp diagnosis in their chart more than 14 days before COVID
#mark a 1 in the column if the patient has this as a new feature (in 89-365, but not present before 14 days before COVID)

####may need old but not new

#PNA
#check if the patient has a pneumonia diagnosis after COVID
codes_present_90_365 = csv_concepts[(csv_concepts$code_label=='PNA' & ((csv_concepts$Concept_date-csv_concepts$COVID_date)>89) & (csv_concepts$Concept_date-csv_concepts$COVID_date)<366),]

#check if the patient had at least one pnuemonia diagnosis at a point greater than 14 days before COVID
codes_present_before_neg_14 = csv_concepts[(csv_concepts$code_label=='PNA' & (csv_concepts$Concept_date-csv_concepts$COVID_date)<(-14)),]

#store the patient details if the patient had resp_feature, but did not have it before COVID
positive_code = codes_present_90_365[!(codes_present_90_365$patient_ID %in% codes_present_before_neg_14$patient_ID),]

#create variables representing new not old, new and old, and old
csv_patient_list['PNA'] = case_when(csv_patient_list$patient_ID %in% positive_code$patient_ID ~ 'new_not_old',
                                    csv_patient_list$patient_ID %in% codes_present_90_365$patient_ID ~ 'new_and_old',
                                    csv_patient_list$patient_ID %in% codes_present_before_neg_14$patient_ID ~ 'old',
                                    TRUE ~ "no"
)

#save all respiratory phenotypes that are potentially new for a patient in this variable
reference_codes = positive_code

#COPD
codes_present_90_365 = csv_concepts[(csv_concepts$code_label=='COPD' & ((csv_concepts$Concept_date-csv_concepts$COVID_date)>89) & (csv_concepts$Concept_date-csv_concepts$COVID_date)<366),]
codes_present_before_neg_14 = csv_concepts[(csv_concepts$code_label=='COPD' & (csv_concepts$Concept_date-csv_concepts$COVID_date)<(-14)),]
positive_code = codes_present_90_365[!(codes_present_90_365$patient_ID %in% codes_present_before_neg_14$patient_ID),]
csv_patient_list['COPD'] = case_when(csv_patient_list$patient_ID %in% positive_code$patient_ID ~ 'new_not_old',
                                     csv_patient_list$patient_ID %in% codes_present_90_365$patient_ID ~ 'new_and_old',
                                     csv_patient_list$patient_ID %in% codes_present_before_neg_14$patient_ID ~ 'old',
                                     TRUE ~ "no")

reference_codes = rbind(reference_codes, positive_code)

#asthma
codes_present_90_365 = csv_concepts[(csv_concepts$code_label=='asthma' & ((csv_concepts$Concept_date-csv_concepts$COVID_date)>89) & (csv_concepts$Concept_date-csv_concepts$COVID_date)<366),]
codes_present_before_neg_14 = csv_concepts[(csv_concepts$code_label=='asthma' & (csv_concepts$Concept_date-csv_concepts$COVID_date)<(-14)),]
positive_code = codes_present_90_365[!(codes_present_90_365$patient_ID %in% codes_present_before_neg_14$patient_ID),]
csv_patient_list['asthma'] = case_when(csv_patient_list$patient_ID %in% positive_code$patient_ID ~ 'new_not_old',
                                       csv_patient_list$patient_ID %in% codes_present_90_365$patient_ID ~ 'new_and_old',
                                       csv_patient_list$patient_ID %in% codes_present_before_neg_14$patient_ID ~ 'old',
                                       TRUE ~ "no")

reference_codes = rbind(reference_codes, positive_code)

#resp_failure
codes_present_90_365 = csv_concepts[(csv_concepts$code_label=='resp_failure' & ((csv_concepts$Concept_date-csv_concepts$COVID_date)>89) & (csv_concepts$Concept_date-csv_concepts$COVID_date)<366),]
codes_present_before_neg_14 = csv_concepts[(csv_concepts$code_label=='resp_failure' & (csv_concepts$Concept_date-csv_concepts$COVID_date)<(-14)),]
positive_code = codes_present_90_365[!(codes_present_90_365$patient_ID %in% codes_present_before_neg_14$patient_ID),]
csv_patient_list['resp_failure'] = case_when(csv_patient_list$patient_ID %in% positive_code$patient_ID ~ 'new_not_old',
                                             csv_patient_list$patient_ID %in% codes_present_90_365$patient_ID ~ 'new_and_old',
                                             csv_patient_list$patient_ID %in% codes_present_before_neg_14$patient_ID ~ 'old',
                                             TRUE ~ "no")

reference_codes = rbind(reference_codes, positive_code)

#lower_resp
codes_present_90_365 = csv_concepts[(csv_concepts$code_label=='lower_resp' & ((csv_concepts$Concept_date-csv_concepts$COVID_date)>89) & (csv_concepts$Concept_date-csv_concepts$COVID_date)<366),]
codes_present_before_neg_14 = csv_concepts[(csv_concepts$code_label=='lower_resp' & (csv_concepts$Concept_date-csv_concepts$COVID_date)<(-14)),]
positive_code = codes_present_90_365[!(codes_present_90_365$patient_ID %in% codes_present_before_neg_14$patient_ID),]
csv_patient_list['lower_resp'] = case_when(csv_patient_list$patient_ID %in% positive_code$patient_ID ~ 'new_not_old',
                                           csv_patient_list$patient_ID %in% codes_present_90_365$patient_ID ~ 'new_and_old',
                                           csv_patient_list$patient_ID %in% codes_present_before_neg_14$patient_ID ~ 'old',
                                           TRUE ~ "no")

reference_codes = rbind(reference_codes, positive_code)

#resp_signs
codes_present_90_365 = csv_concepts[(csv_concepts$code_label=='resp_signs_symptoms' & ((csv_concepts$Concept_date-csv_concepts$COVID_date)>89) & (csv_concepts$Concept_date-csv_concepts$COVID_date)<366),]
codes_present_before_neg_14 = csv_concepts[(csv_concepts$code_label=='resp_signs_symptoms' & (csv_concepts$Concept_date-csv_concepts$COVID_date)<(-14)),]
positive_code = codes_present_90_365[!(codes_present_90_365$patient_ID %in% codes_present_before_neg_14$patient_ID),]
csv_patient_list['resp_signs_symptoms'] = case_when(csv_patient_list$patient_ID %in% positive_code$patient_ID ~ 'new_not_old',
                                                    csv_patient_list$patient_ID %in% codes_present_90_365$patient_ID ~ 'new_and_old',
                                                    csv_patient_list$patient_ID %in% codes_present_before_neg_14$patient_ID ~ 'old',
                                                    TRUE ~ "no")

reference_codes = rbind(reference_codes, positive_code)

#SABA
codes_present_90_365 = csv_concepts[(csv_concepts$code_label=='SABA' & ((csv_concepts$Concept_date-csv_concepts$COVID_date)>89) & (csv_concepts$Concept_date-csv_concepts$COVID_date)<366),]
codes_present_before_neg_14 = csv_concepts[(csv_concepts$code_label=='SABA' & (csv_concepts$Concept_date-csv_concepts$COVID_date)<(-14)),]
positive_code = codes_present_90_365[!(codes_present_90_365$patient_ID %in% codes_present_before_neg_14$patient_ID),]
csv_patient_list['SABA'] = case_when(csv_patient_list$patient_ID %in% positive_code$patient_ID ~ 'new_not_old',
                                     csv_patient_list$patient_ID %in% codes_present_90_365$patient_ID ~ 'new_and_old',
                                     csv_patient_list$patient_ID %in% codes_present_before_neg_14$patient_ID ~ 'old',
                                     TRUE ~ "no")

reference_codes = rbind(reference_codes, positive_code)

#SAMA
codes_present_90_365 = csv_concepts[(csv_concepts$code_label=='SAMA' & ((csv_concepts$Concept_date-csv_concepts$COVID_date)>89) & (csv_concepts$Concept_date-csv_concepts$COVID_date)<366),]
codes_present_before_neg_14 = csv_concepts[(csv_concepts$code_label=='SAMA' & (csv_concepts$Concept_date-csv_concepts$COVID_date)<(-14)),]
positive_code = codes_present_90_365[!(codes_present_90_365$patient_ID %in% codes_present_before_neg_14$patient_ID),]
csv_patient_list['SAMA'] = case_when(csv_patient_list$patient_ID %in% positive_code$patient_ID ~ 'new_not_old',
                                     csv_patient_list$patient_ID %in% codes_present_90_365$patient_ID ~ 'new_and_old',
                                     csv_patient_list$patient_ID %in% codes_present_before_neg_14$patient_ID ~ 'old',
                                     TRUE ~ "no")

reference_codes = rbind(reference_codes, positive_code)

#LABA
codes_present_90_365 = csv_concepts[(csv_concepts$code_label=='LABA' & ((csv_concepts$Concept_date-csv_concepts$COVID_date)>89) & (csv_concepts$Concept_date-csv_concepts$COVID_date)<366),]
codes_present_before_neg_14 = csv_concepts[(csv_concepts$code_label=='LABA' & (csv_concepts$Concept_date-csv_concepts$COVID_date)<(-14)),]
positive_code = codes_present_90_365[!(codes_present_90_365$patient_ID %in% codes_present_before_neg_14$patient_ID),]
csv_patient_list['LABA'] = case_when(csv_patient_list$patient_ID %in% positive_code$patient_ID ~ 'new_not_old',
                                     csv_patient_list$patient_ID %in% codes_present_90_365$patient_ID ~ 'new_and_old',
                                     csv_patient_list$patient_ID %in% codes_present_before_neg_14$patient_ID ~ 'old',
                                     TRUE ~ "no")

reference_codes = rbind(reference_codes, positive_code)

#LAMA
codes_present_90_365 = csv_concepts[(csv_concepts$code_label=='LAMA' & ((csv_concepts$Concept_date-csv_concepts$COVID_date)>89) & (csv_concepts$Concept_date-csv_concepts$COVID_date)<366),]
codes_present_before_neg_14 = csv_concepts[(csv_concepts$code_label=='LAMA' & (csv_concepts$Concept_date-csv_concepts$COVID_date)<(-14)),]
positive_code = codes_present_90_365[!(codes_present_90_365$patient_ID %in% codes_present_before_neg_14$patient_ID),]
csv_patient_list['LAMA'] = case_when(csv_patient_list$patient_ID %in% positive_code$patient_ID ~ 'new_not_old',
                                     csv_patient_list$patient_ID %in% codes_present_90_365$patient_ID ~ 'new_and_old',
                                     csv_patient_list$patient_ID %in% codes_present_before_neg_14$patient_ID ~ 'old',
                                     TRUE ~ "no")

reference_codes = rbind(reference_codes, positive_code)

#mult_oxy
codes_present_90_365 = csv_concepts[(csv_concepts$code_label=='mult_oxy' & ((csv_concepts$Concept_date-csv_concepts$COVID_date)>89) & (csv_concepts$Concept_date-csv_concepts$COVID_date)<366),]
codes_present_before_neg_14 = csv_concepts[(csv_concepts$code_label=='mult_oxy' & (csv_concepts$Concept_date-csv_concepts$COVID_date)<(-14)),]
positive_code = codes_present_90_365[!(codes_present_90_365$patient_ID %in% codes_present_before_neg_14$patient_ID),]
csv_patient_list['mult_oxy'] = case_when(csv_patient_list$patient_ID %in% positive_code$patient_ID ~ 'new_not_old',
                                         csv_patient_list$patient_ID %in% codes_present_90_365$patient_ID ~ 'new_and_old',
                                         csv_patient_list$patient_ID %in% codes_present_before_neg_14$patient_ID ~ 'old',
                                         TRUE ~ "no")

reference_codes = rbind(reference_codes, positive_code)

#PFT
codes_present_90_365 = csv_concepts[(csv_concepts$code_label=='PFT' & ((csv_concepts$Concept_date-csv_concepts$COVID_date)>89) & (csv_concepts$Concept_date-csv_concepts$COVID_date)<366),]
codes_present_before_neg_14 = csv_concepts[(csv_concepts$code_label=='PFT' & (csv_concepts$Concept_date-csv_concepts$COVID_date)<(-14)),]
positive_code = codes_present_90_365[!(codes_present_90_365$patient_ID %in% codes_present_before_neg_14$patient_ID),]
csv_patient_list['PFT'] = case_when(csv_patient_list$patient_ID %in% positive_code$patient_ID ~ 'new_not_old',
                                    csv_patient_list$patient_ID %in% codes_present_90_365$patient_ID ~ 'new_and_old',
                                    csv_patient_list$patient_ID %in% codes_present_before_neg_14$patient_ID ~ 'old',
                                    TRUE ~ "no")

reference_codes = rbind(reference_codes, positive_code)

#PST
codes_present_90_365 = csv_concepts[(csv_concepts$code_label=='PST' & ((csv_concepts$Concept_date-csv_concepts$COVID_date)>89) & (csv_concepts$Concept_date-csv_concepts$COVID_date)<366),]
codes_present_before_neg_14 = csv_concepts[(csv_concepts$code_label=='PST' & (csv_concepts$Concept_date-csv_concepts$COVID_date)<(-14)),]
positive_code = codes_present_90_365[!(codes_present_90_365$patient_ID %in% codes_present_before_neg_14$patient_ID),]
csv_patient_list['PST'] = case_when(csv_patient_list$patient_ID %in% positive_code$patient_ID ~ 'new_not_old',
                                    csv_patient_list$patient_ID %in% codes_present_90_365$patient_ID ~ 'new_and_old',
                                    csv_patient_list$patient_ID %in% codes_present_before_neg_14$patient_ID ~ 'old',
                                    TRUE ~ "no")

reference_codes = rbind(reference_codes, positive_code)

###########TOTAL PHENOTYPES##########################################################################
#determine summary statistics for if a phenotype is ever mentioned for a patient

#function to determine if the label is ever used for a patient
new.function <- function(a) {
  ifelse(a=='no', 0, 1)
}

#test = new.function(csv_patient_list)
test = (data.frame(lapply(csv_patient_list[,c('PNA', 'COPD', 'asthma', 'resp_failure', 'lower_resp', 
                                              'resp_signs_symptoms', 'SABA', 'SAMA', 'LABA', 'LAMA', 
                                              'mult_oxy', 'PFT', 'PST')], new.function)))

#check total stats of new and old
total_col_stats = data.frame(colSums(test[,c('PNA', 'COPD', 'asthma', 'resp_failure', 'lower_resp', 
                                             'resp_signs_symptoms', 'SABA', 'SAMA', 'LABA', 'LAMA', 
                                             'mult_oxy', 'PFT', 'PST')]))

###########NEW PHENOTYPES##########################################################################
#determine summary statistics for whether or not a label is used between 90 and 365 days after the COVID diagnosis

#function to determine if new
new.function <- function(a) {
  ifelse((a=='new_and_old' | a=='new_not_old'), 1, 0)
}

#test = new.function(csv_patient_list)
test = (data.frame(lapply(csv_patient_list[,c('PNA', 'COPD', 'asthma', 'resp_failure', 'lower_resp', 
                                              'resp_signs_symptoms', 'SABA', 'SAMA', 'LABA', 'LAMA', 
                                              'mult_oxy', 'PFT', 'PST')], new.function)))

#check total stats of new and old
new_col_stats = data.frame(colSums(test[,c('PNA', 'COPD', 'asthma', 'resp_failure', 'lower_resp', 
                                           'resp_signs_symptoms', 'SABA', 'SAMA', 'LABA', 'LAMA', 
                                           'mult_oxy', 'PFT', 'PST')]))
############NEW_PHENOTYPES_NOT_OLD#######################################################################
#determine summary statistics for whether or not a label is used between 90 and 365 days after the COVID diagnosis and not old

#function to determine if old and new variables
new.function <- function(a) {
  ifelse((a=='new_not_old'), 1, 0)
}

#test = new.function(csv_patient_list)
test = (data.frame(lapply(csv_patient_list[,c('PNA', 'COPD', 'asthma', 'resp_failure', 'lower_resp', 
                                              'resp_signs_symptoms', 'SABA', 'SAMA', 'LABA', 'LAMA', 
                                              'mult_oxy', 'PFT', 'PST')], new.function)))

#check total stats of new and now old
new_not_old_col_stats = data.frame(colSums(test[,c('PNA', 'COPD', 'asthma', 'resp_failure', 'lower_resp', 
                                                   'resp_signs_symptoms', 'SABA', 'SAMA', 'LABA', 'LAMA', 
                                                   'mult_oxy', 'PFT', 'PST')]))

##############SAMPLING RANDOMLY FROM NEW AND NOT OLD GROUPS FOR PATIENT LIST#################################################################3

#add back patient ID's
test[,'patient_ID'] = csv_patient_list$patient_ID

#COPY OF TEST
test_2 = test

test_2['summed_row'] = rowSums(test_2[,c('PNA', 'COPD', 'asthma', 'resp_failure', 'lower_resp', 'resp_signs_symptoms', 
                                         'SABA', 'SAMA', 'LABA', 'LAMA', 'mult_oxy', 'PFT', 'PST')])

respiratory_patients_2 = test_2$patient_ID[test_2$summed_row>=1]

#set seed
set.seed(5)

#randomly selected 100 at random
random_patient_list = sample(respiratory_patients_2, 100)
random_patient_list = csv_patient_list[csv_patient_list$patient_ID %in% random_patient_list,][,c('patient_ID', 'COVID_date')]

#write the random list
write.csv(random_patient_list, './random_patient_list.csv')

#remove unneccesary data tables
rm(test_2, respiratory_patients_2, random_patient_list)

##############GENERATES LIST BY SAMPLING EQUALLY FROM EACH LABEL OF NEW AND NOT OLD GROUPS#################################################################3

#pivot the table from wide to long
test.long <- pivot_longer(test, cols=1:13, names_to = "Label", values_to = "Presence")

#only keep values where the disease is present
test.long = test.long[test.long[,'Presence']==1,]

#drop the presence columns
test.long = test.long[,c('patient_ID', "Label")]

#randomly select 10 phenotypes from each group (THIS FUNCTION MAY NEED TO BE CHANGED IF THERE ARE NOT ENOUGH LABELS FOR EACH GROUP)
chart_review = test.long %>% group_by(Label) %>% sample_n(10)

#remove unnecessary tables
rm(codes_present_90_365, codes_present_before_neg_14, positive_code, csv_concepts, new.function, test)

#write a table for chart review, that gives the patient ID, the phenotype used to select this ID, and the COVID date
stratified_patient_list = merge(chart_review, csv_patient_list[,c('patient_ID', 'COVID_date')], by = 'patient_ID')
write.csv(stratified_patient_list, './stratified_patient_list.csv')
rm(csv_patient_list)

###############create summary statistics#################################################################

######stats) <-'total_resp_labels'
names(new_col_stats) <- 'new_resp_labels'
names(new_not_old_col_stats) <- 'new_not_old_labels'

summary = bind_cols(total_col_stats, new_col_stats, new_not_old_col_stats)
rm(total_col_stats, new_col_stats, new_not_old_col_stats)

#write a table for all identified phenotypes
write.csv(summary, './summary_stats.csv', )

######################################creates reference list for help with chart review#####################

#write a table with all of the new_resp_dates for all of the patients
fwrite(reference_codes, './new_resp_dates.csv')

##############################################create upset plot##############################################
test.long[,"Present"] = 1
check = pivot_wider(test.long, names_from=Label, values_from=Present)
check[is.na(check)]<-0
check[,c('PNA', 'COPD', 'asthma', 'resp_failure', 'lower_resp', 'resp_signs_symptoms')]
check_2 = one_hot(as.data.table(check))

#save upset plot
pdf(file="resp_upset_plot.pdf", onefile=FALSE) # or other device
#####added this row
upset(check_2, sets = c('PNA', 'COPD', 'asthma', 'resp_failure', 'lower_resp', 'resp_signs_symptoms', 'SABA', 'SAMA', 'LABA', 'LAMA', 'mult_oxy', 'PFT', 'PST'), order.by = 'freq', nintersects=15)
dev.off()

##################save image of workspace####################################################################
save.image('complete list')

