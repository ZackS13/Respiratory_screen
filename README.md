# Respiratory_screen
This project selects patients who based of the EHR data, are likely to have persistent or worsened respiratory symptoms due to COVID-19. It takes in two CSV files (with specific specifications in a separate Word file) and produces 4 tables for analysis and chart review, and an UpSet Plot

In order to run this script the institution needs to have two CSV files. The first csv_patient_list should be arranged in the following way:

| Patient Identifier <br /> (numerical)	 | Positive COVID Date <br /> (mm-dd-yyyy) | ICD Code or Lab <br />  (ICD code or lab) | 
| ------ | ------ | ------ | 
| <br /> | |  | 
| <br /> |  | | 
| <br /> |  | | 


The second CSV file, csv_concepts.csv should be arranged in the following manner:

| Patient Identifier <br /> (numerical)	| Concept Code Type <br /> (string stating one of four types of concepts 'ICD', 'CPT', 'LOINC', or 'RxNorm') | Concept Code ID <br /> (string)	 | Column 4 Date <br /> (mm-dd-yyyy)  |
| ------ | ------ | ------ | ------ |
| <br /> |  | |  |
| <br /> |  | |  |
| <br /> |  | | 

The ICD code should be a alphanumeric format without periods  <br /> 
The CPT should be in numeric format  <br /> 
The RxNorm should be in numeric format   <br /> 


The script produces four CSV files as output.

The first two tables are for chart review ("stratified_patient_list.csv" and "random_patient_list.csv"). The random_patient_list is of 100 patients and includes the patient_ID and the COVID_date. The stratified_patient_list.csv includes 130 patients (10 from each label) and includes their identifier, the respiratory label that flagged the specific as a potential respiratory symptom case, and the date of COVID. Below is a sample of the "stratified_patient_list": 

| patient_ID| label| COVID_date |
| ------ | ------ | ------ | 
| xxxxxxxxx | COPD | yyyy-mm-dd | 
| <br /> |  | |  
| <br /> |  | | 
| <br /> |  | | 

The third table ("new_resp_dates,csv") lists all new respiratory codes for each of the identified patients to help with chart review for identifying when a patient was flagged as having a potential ongoing pulmonary disease
| patient_ID| Concept_type| Concept_ID | Concept_date | code_label | COVID_date|
| ------ | ------ | ------ |  ------ | ------ | ------ | 
| xxxxxx | ICD |J17 | xxxx-xx-xx |COPD |xxxx-xx-xx  |  
| xxxxxx | CPT |94761 | xxxx-xx-xx  | mult_oxy |xxxx-xx-xx  |  
| <br /> |  | |  | |  |  


The third table, "summary_stats.csv", provides summary statistics for each of the labels: 
| | total_resp_labels| new_resp_labels| new_not_old_labels |
| ------ | ------ | ------ | ------ | 
| PNA |  | |  | 
| COPD |  | |  |
| asthma |  | |  | 
| resp_failure |  | |  |
| lower_resp |  | |  | 
| resp_signs_symptoms |  | |  |
| SABA |  | |  | 
| SAMA |  | |  |
| LABA |  | |  | 
| LAMA |  | |  |
| mult_oxy |  | |  | 
| PFT |  | |  |
| PST |  | |  |

The script also produces an upset figure, "resp_upset_plot.pdf",  based on new respiratory codes in your local data. <br />
Below is a sample with simulated data

![Upset](simulated_upset.png)
