/******************************************************************************************************************************************************************************************
Formula Name: AXEW_AXE_ADJ_LOS_SENIORITY_DATE_FF
Formula Type: Employment Seniority Date Adjustment
Description : Calculate Adjusted Length of Service Seniority Date From AXEW_SERVICE_DATES Person EIT Value

Org/Developer					Date				Comments
-------------------------------------------------------------------------------------------------------------
Deloitte/Karthikeya Andey			06/03/2021			Initial version
Deloitte/Sai Prathap Reddy			06/07/2022			modified Version		INC1780390

Important points to consider:
-----------------------------
1. For inactive Employees, EFF effective start date should be present between Employees hire date and termination date. 
2. For active Employees, EFF effective start date can be present post hire date. If it is greater than system date, then Seniority date will be adjusted only on EFF effective start date.
3. If only top of the stack EFF record is present, then only top of the stack seniority date record will be adjusted to match with Adjusted Length of Service EFF date value.
4. If historical EFF records are present, then all the corresponding seniority date records will be adjusted to match with respective Adjusted Length of Service EFF date values.
*********************************************************************************************************************************************************************************************/
DEFAULT FOR PER_ASG_EFFECTIVE_SEQUENCE IS -1
DEFAULT FOR PER_ASG_ACTION_CODE IS ' '
DEFAULT FOR PER_ASG_REL_DATE_START IS '0001/01/01 00:00:00' (date)
DEFAULT FOR PER_ASG_REL_ACTUAL_TERMINATION_DATE IS '0001/01/01 00:00:00' (date)
DEFAULT FOR PER_SYS_DATE_TIME IS ' '

DEFAULT FOR EFFECTIVE_START_DATE IS '0001/01/01 00:00:00' (date)
DEFAULT FOR EFFECTIVE_END_DATE IS '0001/01/01 00:00:00' (date)
DEFAULT FOR SENIORITY_DATE_CODE IS ' '

DEFAULT_DATA_VALUE FOR PER_PERSON_EIT_ALL_PEI_INFORMATION_CATEGORY IS ' '
DEFAULT_DATA_VALUE FOR PER_PERSON_EIT_ALL_PEI_INFORMATION_DATE1 IS '0001/01/01 00:00:00' (date)
DEFAULT_DATA_VALUE FOR PER_PERSON_EIT_ALL_EFFECTIVE_START_DATE IS '0001/01/01 00:00:00' (date)
DEFAULT_DATA_VALUE FOR PER_PERSON_EIT_ALL_EFFECTIVE_END_DATE IS '4712/12/31 00:00:00' (date)

DEFAULT_DATA_VALUE FOR PER_SENDT_F_V3_SENIORITY_DATE_CODE IS ' '
DEFAULT_DATA_VALUE FOR PER_SENDT_F_V3_TOTAL_MANUAL_ADJUSTMENT_DAYS IS 0
DEFAULT_DATA_VALUE FOR PER_SENDT_F_V3_EFFECTIVE_START_DATE IS '0001/01/01 00:00:00' (date)
DEFAULT_DATA_VALUE FOR PER_SENDT_F_V3_EXIT_DATE IS '0001/01/01 00:00:00' (date)

INPUTS ARE	EFFECTIVE_START_DATE (date),
		EFFECTIVE_END_DATE (date),
		SENIORITY_DATE_CODE (text)

seniority_adjust_in_days	= 0
seniority_adjust_comment	= ' '
eff_date			= EFFECTIVE_START_DATE

l_eff_seq_flag_check		= 'TRUE'
l_seniority_date_code		= SENIORITY_DATE_CODE
l_sysdate			= SUBSTR(PER_SYS_DATE_TIME, 1, 10)
l_temp_date			= l_sysdate
i				= 1
l_manual_adj_days		= 0

IF (PER_ASG_EFFECTIVE_SEQUENCE > 1 AND TO_CHAR(eff_date, 'YYYY-MM-DD') != TO_CHAR(EFFECTIVE_END_DATE, 'YYYY-MM-DD')) THEN
(
	l_eff_seq_flag_check = 'FALSE'
)

IF (TO_CHAR(eff_date, 'YYYY-MM-DD') = TO_CHAR(PER_ASG_REL_DATE_START, 'YYYY-MM-DD')) AND (l_eff_seq_flag_check = 'TRUE') THEN
( 		
	l_arr_index = PER_SENDT_F_V3_EFFECTIVE_START_DATE.FIRST(-1)
	WHILE PER_SENDT_F_V3_EFFECTIVE_START_DATE.EXISTS(l_arr_index) LOOP
	(	
		IF (TO_CHAR(eff_date, 'YYYY-MM-DD') = TO_CHAR(PER_SENDT_F_V3_EFFECTIVE_START_DATE[l_arr_index], 'YYYY-MM-DD')) AND (PER_SENDT_F_V3_SENIORITY_DATE_CODE[l_arr_index] =  l_seniority_date_code) THEN
		(
			l_manual_adj_days = PER_SENDT_F_V3_TOTAL_MANUAL_ADJUSTMENT_DAYS[l_arr_index]
		)
		l_arr_index = PER_SENDT_F_V3_EFFECTIVE_START_DATE.NEXT(l_arr_index, -1)
	)
	
	IF TO_CHAR(PER_ASG_REL_ACTUAL_TERMINATION_DATE, 'YYYY-MM-DD') != '0001-01-01' THEN
	(
		l_temp_date = TO_CHAR(PER_ASG_REL_ACTUAL_TERMINATION_DATE, 'YYYY-MM-DD')
	)ELSE
	(
		l_temp_date = l_sysdate
	)
	
	/* INC1780390 - Added to filter the blank data*/
	l_EIT_PEI_INFO_Default = '0001-01-01'		
	WHILE PER_PERSON_EIT_ALL_PEI_INFORMATION_DATE1.EXISTS(i) LOOP
	(
		IF PER_PERSON_EIT_ALL_PEI_INFORMATION_CATEGORY[i] = 'AXEW_SERVICE_DATES' 
		AND l_temp_date >= TO_CHAR(PER_PERSON_EIT_ALL_EFFECTIVE_START_DATE[i], 'YYYY-MM-DD')
		AND l_temp_date <= TO_CHAR(PER_PERSON_EIT_ALL_EFFECTIVE_END_DATE[i], 'YYYY-MM-DD')
		
		 /* INC1780390 - Added to filter the blank data*/
		AND  l_EIT_PEI_INFO_Default < TO_CHAR(PER_PERSON_EIT_ALL_PEI_INFORMATION_DATE1[i], 'YYYY-MM-DD')
  
		THEN
		(
			l_diff_in_days = DAYS_BETWEEN(PER_ASG_REL_DATE_START, PER_PERSON_EIT_ALL_PEI_INFORMATION_DATE1[i])
						
			seniority_adjust_in_days = (l_diff_in_days - l_manual_adj_days)
			seniority_adjust_comment = 'Auto adjustment based on Service Dates EIT'
		)
		i = i + 1
	)
)

RETURN eff_date, seniority_adjust_comment, seniority_adjust_in_days