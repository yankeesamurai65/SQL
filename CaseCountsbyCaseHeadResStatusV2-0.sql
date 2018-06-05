--*****************************************************************************************************************************
--*		Case and Individual Residency Status ver. 2.0  
--*
--*Reporting Based on Program and Residency Status
--*  OBJECTIVE:  Provide a count of cases with caseheads and individuals reflecting the major residency status subdivisions
--*		1.  Adult US_Citizen (Citizenship Status Codes DC, DE, UC, NC, and NA)
--*			a.  DC is a Dual Citizen
--*			b.	DE is derived citizenship (e.g. born overseas to US Citizens)
--*			c.	UC is a US Citizen at birth
--*			d.  NC is a Naturalized Citizen
--*			e.  NA is a US National
--*		2. Permanent Residents (11)
--*			a.	11 is a permanent resident
--*		3. Claiming PRUCOL (PL, CP)
--*			a.	PL is claiming PRUCOL or a Permanent Resident Under Color of Law
--*			b.  CP is CalWORKS PRUCOL eligibility
--*		4. Work Permit (WP, 17)
--*			a.  WP is a Work Permit or Work Visa
--*			b.  17 is Sp Ag Wrkr-SAW/Rpl Ag Wrkr-RAW
--*		5.  Undocumented Immigrant (UA)
--*			a.  UA is an undocumented alien
--*		6.  All Others reflects all other codes (6-8, 10, 13-14, 18-19, AS, DP, LA, NR, RE, VX, VY, XX)
--*		7.  IsNull relfects those cases where the citizen information field is recorded as NULL
--*
--*  Report is organized to present a rolling six years of monthly case/inidividual counts between major residency  
--*  status subdivsions in both graphical and tabular form to provide insights about prgoram participations levels
--*  between the residency status subdivsions and to provide a basis for comparison between these.
--*
--*  Basis for this report is the CIS_MR MR0007E
--*
--*  Report requirement responds to content from a meeting conducted between Madeline and Emily on 26 Jun 2017.
--*		Adjusted on 16 Oct 17 based on feedback provided through EBSD Operations.
--*
--*  Following revision, this report is congruent with the corresponding content within Franks's
--*		earlier Case and Individual Profile report with the added benefit of presenting longitudinal results.
--*  
--*  Completed By:  Masahiro Kamei
--*  Project Initiated:				26 Jun 17
--*  Initial Scope:					27 Jun 17
--*  Requirements Determination:	28 Jun 17
--*  Proof of Concept:				30 Jun 17
--*  Production:					03 Jun 17
--*  Testing:						07 Jul 17
--*  Deployment:					10 Jul 17
--*  Revised:					16 Oct 17
--****************************************************************************************************************************

DECLARE @PgmType AS VARCHAR(2)
DECLARE @RecordType AS VARCHAR(1)
DECLARE @EligStatus1 AS VARCHAR(2)
DECLARE @EligStatus2 AS VARCHAR(2)

SET @PgmType = 'MC'
SET @RecordType = 'I'
SET @EligStatus1 = (CASE WHEN @RecordType = 'I'
						THEN 'PS'
						ELSE 'XX'
					END)
SET @EligStatus2 = (CASE WHEN @RecordType = 'I'
						THEN 'PE'
						ELSE ''
					END)

USE CIS_Daily		
		
SELECT		

	A.CREATE_YEAR
	,A.CREATE_MONTH
	--,A.ELIG_STS
	
	,CASE WHEN A.CREATE_MONTH > 6 
		THEN A.CREATE_YEAR + 1 
		ELSE A.CREATE_YEAR
	END FY

	,COUNT (DISTINCT CASE WHEN A.CTZN_STS_CD IN ('DC','DE','NA','NC','UC') 
		THEN A.CWIN
		ELSE NULL
		END) AS 'Citizens'
		
	,COUNT(DISTINCT CASE WHEN A.CTZN_STS_CD IN ('11') 
		THEN A.CWIN
		ELSE NULL
	END) AS 'Permanent Residents'	

	,COUNT(DISTINCT CASE WHEN A.CTZN_STS_CD IN ('PL','CP')
		THEN A.CWIN
		ELSE NULL
	END) AS 'Claiming PRUCOL'

	,COUNT(DISTINCT CASE WHEN A.CTZN_STS_CD IN ('WP','17')
		THEN A.CWIN
		ELSE NULL
	END) AS 'Work Permit'
		
	,COUNT(DISTINCT CASE WHEN A.CTZN_STS_CD IN ('UA') 
		THEN A.CWIN	
		ELSE NULL
	END) AS 'Undocumented Immigrants'	

	,COUNT(DISTINCT CASE WHEN A.CTZN_STS_CD IN ('6','7','8','10','13','14','18','19','AS','DP','LA','NR','RE','VX','VY','XX') 
		THEN A.CWIN 	
		ELSE NULL
	END) AS 'All Others'

	,COUNT(DISTINCT CASE WHEN A.CTZN_STS_CD IS NULL  
		THEN A.CWIN	
		ELSE NULL
	END) AS 'Is Null'
		
	,(COUNT(DISTINCT CASE WHEN A.CTZN_STS_CD IN ('6','7','8','10','11','13','14','17','18','19','AS','CP','DC','DE','DP','LA',
			'NA','NC','NR','PL','RE','UA','UC','VX','VY','WP','XX') 
			THEN A.CWIN	
			ELSE NULL
		END) 
	
		+

		COUNT(DISTINCT CASE WHEN A.CTZN_STS_CD IS NULL  
			THEN A.CWIN	
			ELSE NULL
		END) 
	) AS 'Unduplicated Count'

		
FROM CIS_MR..MR0007E AS A		
		
WHERE A.PGM_TYP_CD = @PgmType		
	AND A.CreatedDate > GETDATE()-2191.5
	--* 2,191.5 is the count of days representing a rolling 6-year window	
	AND A.RECORD_TYPE = @RecordType	
	AND (CASE WHEN A.ELIG_STS IS NULL
			THEN 'XX'
			ELSE A.ELIG_STS
		END) IN (@EligStatus1, @EligStatus2)
		
GROUP BY 
	A.CREATE_YEAR
	,A.CREATE_MONTH

	
ORDER BY 	
	A.CREATE_YEAR DESC
	,A.CREATE_MONTH DESC
	