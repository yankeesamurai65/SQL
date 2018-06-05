--*****************************************************************************************************************************
--*		Categorical Aid Dashboard Supporting Dat  
--*
--*  Reporting Based on Fiscal Year, Fiscal Quarter, and Program Type.
--*  OBJECTIVE:  Provide a dashboard reflecting the current budget position (approved budget, estimated actual, or closeout),
--*					projections based on the current budget position, current obligations, and case count at monthly granularity.
--*		1. Rationalizes on Fiscal Year
--*		2. Derives Fiscal Quarter
--*		3. Converts calendar months to Fiscal Months
--*		4. Determines current FY budget based on budget position:
--*			a.  Approved Budget
--*			b.  Current EA
--*			c.  Current Actuals
--*		5. Determines obligation plan, or a forecast of expenditures for each month
--*			a.  Determines average monthly proportion of expenditures 
--*			b.  A perfectly straight-line program would execute 8.33% of the annual budget each month
--*			c.  Averages the same month across 5 fiscal years of execution history.
--*		5.  Determines actual obligations for each month
--*		6.  Determines program case count for each month
--*		7.  Obligation Plan, Actuals, and Case Count are not cumulated.
--*
--*  Report is organized to present a chart with clustered bars per month that support ease of comparison between  
--*  the obligation plan and the actuals.  Case count is depicted by a line using a secondary axis.  
--*
--*  Basis for this report is the CIS_MR MRB026E, primarily, as well as MRA027E, MRB027E, MRA086M, and MRB086M.
--*
--*  Report requirement is based on current direction regarding establishing a first-ever Fiscal Dashboard for this
--*		organization.
--*  
--*  Completed By:  Masahiro Kamei
--*  Project Initiated:				03 May 17
--*  Initial Scope:					12 May 17
--*  Requirements Determination:	26 May 17
--*  Proof of Concept:				31 Aug 17
--*  Production:					29 Sep 17
--*  Testing:						01 Nov 17
--*  Deployment:					14 Dec 17
--*  Revised:						10 Jan 18
--*  Revised:						04 Apr 18
--****************************************************************************************************************************

-- Declaration of parameters for use in diagnostic testing
DECLARE @Program AS VARCHAR(2)
DECLARE @AidCode AS VARCHAR(2)
DECLARE @BudPos AS VARCHAR(16)

-- Declaration of local variables
DECLARE @CurrFY AS INT
DECLARE @Budget AS TABLE
	(
		Pgm VARCHAR(2)
		,BudYr INT
		,AppBudget INT
		,CurrEA INT
		,CurrAct INT
	)


--  Only required for diagnostic testing
SET @Program = 'GA'
SET @AidCode = '30'
SET @BudPos = 'Most Recent EA'
--  End parameters

-- Determines the current Fiscal Year (July through June)
SET @CurrFY = 
	CASE	
		WHEN MONTH(GETDATE()) > 6 THEN YEAR(GETDATE())+1
		ELSE YEAR(GETDATE())
	END

-- This is a temporary work-around pending architectural enhacements to access local fiscal data
INSERT INTO @Budget
	SELECT       'AA', 2013, 6084811, 6228976, 6384811
	UNION SELECT 'AA', 2014, 6084811, 6851952, 6579045
	UNION SELECT 'AA', 2015, 6579045, 7726883, 7879736
	UNION SELECT 'AA', 2016, 7865285, 8322506, 8365285
	UNION SELECT 'AA', 2017, 7865285, 8397321, 8397990
	UNION SELECT 'AA', 2018, 8766501, 8776501, 8766501
	UNION SELECT 'CW', 2013, 12906532, 11541339, 11895597
	UNION SELECT 'CW', 2014, 12906532, 11786828, 11541339
	UNION SELECT 'CW', 2015, 11541339, 11799128, 11763811
	UNION SELECT 'CW', 2016, 12198913, 10947937, 11298913
	UNION SELECT 'CW', 2017, 12198913, 10704416, 10785405
	UNION SELECT 'CW', 2018, 11108907, 10645817, 10645817
	UNION SELECT 'AR', 2016, 0, 58666, 105010
	UNION SELECT 'AR', 2017, 150010, 63284, 128284
	UNION SELECT 'AR', 2018, 90000, 90000, 90000
	UNION SELECT 'FC', 2013, 6833520, 7170062, 7158645
	UNION SELECT 'FC', 2014, 6833520, 6898760, 7725249
	UNION SELECT 'FC', 2015, 7616935, 7360458, 7338957
	UNION SELECT 'FC', 2016, 7583872, 7659616, 8056203
	UNION SELECT 'FC', 2017, 7656203, 8672463, 8570841
	UNION SELECT 'FC', 2018, 9618445, 9643857, 9643857	
	UNION SELECT 'KG', 2018, 0, 463090, 0
	UNION SELECT 'RC', 2013, 5706, 4610, 6706
	UNION SELECT 'RC', 2014, 5706, 8526, 5706
	UNION SELECT 'RC', 2015, 5706, 8520, 8520
	UNION SELECT 'RC', 2016, 8520, 8520, 8520
	UNION SELECT 'RC', 2017, 8520, 8520, 0
	UNION SELECT 'RC', 2018, 8520, 8520, 0
	UNION SELECT 'GA', 2013, 559440, 559440, 557440
	UNION SELECT 'GA', 2014, 557440, 467090, 559440
	UNION SELECT 'GA', 2015, 559440, 430273, 534440
	UNION SELECT 'GA', 2016, 525508, 547722, 604440
	UNION SELECT 'GA', 2017, 559440, 829218, 809440
	UNION SELECT 'GA', 2018, 912140, 839842, 839842

USE CIS_MR;

--  Obtain Main and Supplemental Payments for both the current and previous reporting month
WITH MainSupp AS
	(SELECT 
		CREATE_YEAR
		,CREATE_MONTH
		,PGM_TYP_CD
		,SUM(ISS_AMT) AS Amount

	FROM MRB026E

	WHERE 
		CreatedDate >= GETDATE() - 2190
		AND TRANS_TYPE IN ('MA','SU')
		AND PAID_FOR_CUR_PRIOR IN ('C','P')

	GROUP BY
		CREATE_YEAR
		,CREATE_MONTH
		,PGM_TYP_CD
	)

--Obtain Canceled issuances, both current and prior month
,Canceled AS
	(SELECT 
		CREATE_YEAR
		,CREATE_MONTH
		,PGM_TYP_CD
		,SUM(ISS_AMT) AS Amount

	FROM MRB026E

	WHERE 
		CreatedDate >= GETDATE() - 2190
		AND TRANS_TYPE IN ('CA')
		AND PAID_FOR_CUR_PRIOR IN ('C','P')

	GROUP BY
		CREATE_YEAR
		,CREATE_MONTH
		,PGM_TYP_CD
	)

--Obtain all abatements
,Abated AS
	(SELECT
		CREATE_YEAR
		,CREATE_MONTH
		,PGM_TYP_CD
		,SUM(ABATEMENT_AMT) AS Amount

	FROM MRB086M

	WHERE 
		CreatedDate >= GETDATE() - 2190
		AND TRAN_TYP IN ('R','S')

	GROUP BY
		CREATE_YEAR
		,CREATE_MONTH
		,PGM_TYP_CD
	)

--Obtain all recoupments
,Recoup AS

	(SELECT 
		CREATE_YEAR
		,CREATE_MONTH
		,PGM_TYP_CD
		,SUM(AMOUNT) AS Amount

	FROM MRA086M

	WHERE 
		CreatedDate >= GETDATE() - 2190

	GROUP BY
		CREATE_YEAR
		,CREATE_MONTH
		,PGM_TYP_CD
	),

--Obtain all positively signed adjustments
PosAdj AS

	(SELECT 
		CREATE_YEAR
		,CREATE_MONTH
		,PGM_TYP_CD
		,SUM(ADJUSTMENT_AMT) AS Amount

	FROM MRA027E

	WHERE 
		CreatedDate >= GETDATE() - 2190
		AND CURRENT_PRIOR_IND IN ('C','P')

	GROUP BY
		CREATE_YEAR
		,CREATE_MONTH
		,PGM_TYP_CD
	),

--Obtain all negatively signed adjustments
NegAdj AS

	(SELECT 
		CREATE_YEAR
		,CREATE_MONTH
		,PGM_TYP_CD
		,SUM(ADJUSTMENT_AMT) AS Amount

	FROM MRB027E

	WHERE 
		CreatedDate >= GETDATE() - 2190
		AND CURRENT_PRIOR_IND IN ('C','P')
		AND PGM_AID_CD NOT IN ('9X')

	GROUP BY
		CREATE_YEAR
		,CREATE_MONTH
		,PGM_TYP_CD
	),

--Regularize data to Fiscal Years, Quarters, and Months
FY AS 

	(SELECT
		A.CREATE_YEAR
		,A.CREATE_MONTH

		,CASE	
			WHEN A.CREATE_MONTH > 6 THEN A.CREATE_YEAR + 1
			ELSE A.CREATE_YEAR
		END AS FiscalYr

		,CASE
			WHEN A.CREATE_MONTH > 6 THEN A.CREATE_MONTH - 6
			ELSE A.CREATE_MONTH + 6
		END AS FiscalMo

		,CASE
			WHEN A.CREATE_MONTH IN ('07','08','09') THEN '1Q'
			WHEN A.CREATE_MONTH IN ('10','11','12') THEN '2Q'
			WHEN A.CREATE_MONTH IN ('01','02','03') THEN '3Q'
			WHEN A.CREATE_MONTH IN ('04','05','06') THEN '4Q'
			ELSE NULL
		END AS FiscalQtr

		,A.PGM_TYP_CD
		,MAX(ISNULL(MainSupp.Amount,0) - ISNULL(Canceled.Amount,0) + ISNULL(Abated.Amount,0) + ISNULL(Recoup.Amount,0) + ISNULL(PosAdj .Amount,0) + ISNULL(NegAdj.Amount,0)) AS Amount
	
	FROM MRB026E AS A

	LEFT JOIN MainSupp
		ON MainSupp.CREATE_YEAR = A.CREATE_YEAR
		AND MainSupp.CREATE_MONTH = A.CREATE_MONTH
		AND MainSupp.PGM_TYP_CD = A.PGM_TYP_CD

	LEFT JOIN Canceled 
		ON Canceled.CREATE_YEAR = A.CREATE_YEAR
		AND Canceled.CREATE_MONTH = A.CREATE_MONTH
		AND Canceled.PGM_TYP_CD = A.PGM_TYP_CD

	LEFT JOIN Abated
		ON Abated.CREATE_YEAR = A.CREATE_YEAR
		AND Abated.CREATE_MONTH = A.CREATE_MONTH
		AND Abated.PGM_TYP_CD = A.PGM_TYP_CD

	LEFT JOIN Recoup 
		ON Recoup.CREATE_YEAR = A.CREATE_YEAR
		AND Recoup.CREATE_MONTH = A.CREATE_MONTH
		AND Recoup.PGM_TYP_CD = A.PGM_TYP_CD
	
	LEFT JOIN PosAdj 
		ON PosAdj .CREATE_YEAR = A.CREATE_YEAR
		AND PosAdj.CREATE_MONTH = A.CREATE_MONTH
		AND PosAdj.PGM_TYP_CD = A.PGM_TYP_CD
	
	LEFT JOIN NegAdj
		ON NegAdj.CREATE_YEAR = A.CREATE_YEAR
		AND NegAdj.CREATE_MONTH = A.CREATE_MONTH
		AND NegAdj.PGM_TYP_CD = A.PGM_TYP_CD
	
	WHERE 
		A.CreatedDate >= GETDATE()-2190 
		AND A.PGM_TYP_CD = @Program

	GROUP BY
		A.CREATE_YEAR
		,A.CREATE_MONTH
		,A.PGM_TYP_CD
	)

--Determine Historical Execution Patterns
,HXEX AS
	(SELECT
		FY.FiscalYr
		,FY.FiscalQtr
		,FY.FiscalMo
		,A.CREATE_YEAR
		,A.CREATE_MONTH

		,(CASE

			WHEN FY.FiscalYr = @CurrFY THEN FY.Amount/
				(SELECT 
					CASE
						WHEN  @BudPos = 'Approved' THEN AppBudget
						WHEN @BudPos = 'Most Recent EA' THEN CurrEA
						WHEN @BudPos = 'Most Recent Actual' THEN CurrAct
						ELSE NULL
					END AS PA
				FROM @Budget WHERE PGM = @Program AND BudYr = @CurrFY)

			WHEN FY.FiscalYr = (@CurrFY - 1) THEN FY.Amount/
				(SELECT 
					CASE
						WHEN  @BudPos = 'Approved' THEN AppBudget
						WHEN @BudPos = 'Most Recent EA' THEN CurrEA
						WHEN @BudPos = 'Most Recent Actual' THEN CurrAct
						ELSE NULL
					END 
				FROM @Budget WHERE PGM = @Program AND BudYr = @CurrFY - 1)

			WHEN FY.FiscalYr = (@CurrFY - 2) THEN FY.Amount/
				(SELECT 
					CASE
						WHEN  @BudPos = 'Approved' THEN AppBudget
						WHEN @BudPos = 'Most Recent EA' THEN CurrEA
						WHEN @BudPos = 'Most Recent Actual' THEN CurrAct
						ELSE NULL
					END
				FROM @Budget WHERE PGM = @Program AND BudYr = @CurrFY - 2)

			WHEN FY.FiscalYr = (@CurrFY - 3) THEN FY.Amount/
				(SELECT
					CASE
						WHEN  @BudPos = 'Approved' THEN AppBudget
						WHEN @BudPos = 'Most Recent EA' THEN CurrEA
						WHEN @BudPos = 'Most Recent Actual' THEN CurrAct
						ELSE NULL
					END
				FROM @Budget WHERE PGM = @Program AND BudYr = @CurrFY - 3)

			WHEN FY.FiscalYr = (@CurrFY - 4) THEN FY.Amount/
				(SELECT
					CASE
						WHEN  @BudPos = 'Approved' THEN AppBudget
						WHEN @BudPos = 'Most Recent EA' THEN CurrEA
						WHEN @BudPos = 'Most Recent Actual' THEN CurrAct
						ELSE NULL
					END
				FROM @Budget WHERE PGM = @Program AND BudYr = @CurrFY - 4)	

			WHEN FY.FiscalYr = (@CurrFY - 5) THEN FY.Amount/
				(SELECT 
					CASE
						WHEN  @BudPos = 'Approved' THEN AppBudget
						WHEN @BudPos = 'Most Recent EA' THEN CurrEA
						WHEN @BudPos = 'Most Recent Actual' THEN CurrAct
						ELSE NULL
					END
				FROM @Budget WHERE PGM = @Program AND BudYr = @CurrFY - 5)

			ELSE NULL

		END) AS Proportion  
				
	FROM MRB026E AS A

	INNER JOIN FY
	ON A.CREATE_YEAR = FY.CREATE_YEAR
	AND A.CREATE_MONTH = FY.CREATE_MONTH

	GROUP BY 
		FY.FiscalYr
		,FY.FiscalQtr
		,FY.FiscalMo
		,A.CREATE_YEAR
		,A.CREATE_MONTH
		,FY.Amount
	)

--Main Report
SELECT DISTINCT
	FY.FiscalQtr
	,FY.FiscalMo
	,A.CREATE_MONTH
	,[PF] = 
		(SELECT 
	
			CASE
				WHEN  @BudPos = 'Approved' THEN AppBudget
				WHEN @BudPos = 'Most Recent EA' THEN CurrEA
				WHEN @BudPos = 'Most Recent Actual' THEN CurrAct
				ELSE NULL
			END
		 FROM @Budget WHERE BudYr = @CurrFY and PGM = @Program)
	
			,CASE	
				WHEN A.CREATE_MONTH = '07' THEN AVG(HXEX.Proportion)*
					(SELECT 
						CASE
							WHEN @BudPos = 'Approved' THEN AppBudget
							WHEN @BudPos = 'Most Recent EA' THEN CurrEA
							WHEN @BudPos = 'Most Recent Actual' THEN CurrAct
							ELSE NULL
						END
					FROM @Budget 
					WHERE PGM = @Program AND BudYr = @CurrFY)

				WHEN A.CREATE_MONTH = '08' THEN AVG(HXEX.Proportion)*
					(SELECT 
						CASE
							WHEN @BudPos = 'Approved' THEN AppBudget
							WHEN @BudPos = 'Most Recent EA' THEN CurrEA
							WHEN @BudPos = 'Most Recent Actual' THEN CurrAct
							ELSE NULL
						END
					FROM @Budget 
					WHERE PGM = @Program AND BudYr = @CurrFY)

				WHEN A.CREATE_MONTH = '09' THEN AVG(HXEX.Proportion)*
					(SELECT 
						CASE
							WHEN @BudPos = 'Approved' THEN AppBudget
							WHEN @BudPos = 'Most Recent EA' THEN CurrEA
							WHEN @BudPos = 'Most Recent Actual' THEN CurrAct
							ELSE NULL
						END
					FROM @Budget 
					WHERE PGM = @Program AND BudYr = @CurrFY)

				WHEN A.CREATE_MONTH = '10' THEN AVG(HXEX.Proportion)*
					(SELECT
						CASE
							WHEN @BudPos = 'Approved' THEN AppBudget
							WHEN @BudPos = 'Most Recent EA' THEN CurrEA
							WHEN @BudPos = 'Most Recent Actual' THEN CurrAct
							ELSE NULL
						END
					FROM @Budget 
					WHERE PGM = @Program AND BudYr = @CurrFY)

				WHEN A.CREATE_MONTH = '11' THEN AVG(HXEX.Proportion)*
					(SELECT
						CASE
							WHEN @BudPos = 'Approved' THEN AppBudget
							WHEN @BudPos = 'Most Recent EA' THEN CurrEA
							WHEN @BudPos = 'Most Recent Actual' THEN CurrAct
							ELSE NULL
						END
					FROM @Budget 
					WHERE PGM = @Program AND BudYr = @CurrFY)

				WHEN A.CREATE_MONTH = '12' THEN AVG(HXEX.Proportion)*
					(SELECT
						CASE
							WHEN @BudPos = 'Approved' THEN AppBudget
							WHEN @BudPos = 'Most Recent EA' THEN CurrEA
							WHEN @BudPos = 'Most Recent Actual' THEN CurrAct
							ELSE NULL
						END
					FROM @Budget 
					WHERE PGM = @Program AND BudYr = @CurrFY)

				WHEN A.CREATE_MONTH = '01' THEN AVG(HXEX.Proportion)*
					(SELECT
						CASE
							WHEN  @BudPos = 'Approved' THEN AppBudget
							WHEN @BudPos = 'Most Recent EA' THEN CurrEA
							WHEN @BudPos = 'Most Recent Actual' THEN CurrAct
							ELSE NULL
						END
					FROM @Budget 
					WHERE PGM = @Program AND BudYr = @CurrFY)

				WHEN A.CREATE_MONTH = '02' THEN AVG(HXEX.Proportion)*
					(SELECT
						CASE
							WHEN  @BudPos = 'Approved' THEN AppBudget
							WHEN @BudPos = 'Most Recent EA' THEN CurrEA
							WHEN @BudPos = 'Most Recent Actual' THEN CurrAct
							ELSE NULL
						END
					FROM @Budget 
					WHERE PGM = @Program AND BudYr = @CurrFY)

				WHEN A.CREATE_MONTH = '03' THEN AVG(HXEX.Proportion)*
					(SELECT
						CASE
							WHEN  @BudPos = 'Approved' THEN AppBudget
							WHEN @BudPos = 'Most Recent EA' THEN CurrEA
							WHEN @BudPos = 'Most Recent Actual' THEN CurrAct
							ELSE NULL
						END
					FROM @Budget 
					WHERE PGM = @Program AND BudYr = @CurrFY)
			
				WHEN A.CREATE_MONTH = '04' THEN AVG(HXEX.Proportion)*
					(SELECT
						CASE
							WHEN  @BudPos = 'Approved' THEN AppBudget
							WHEN @BudPos = 'Most Recent EA' THEN CurrEA
							WHEN @BudPos = 'Most Recent Actual' THEN CurrAct
							ELSE NULL
						END
					FROM @Budget 
					WHERE PGM = @Program AND BudYr = @CurrFY)

				WHEN A.CREATE_MONTH = '05' THEN AVG(HXEX.Proportion)*
					(SELECT
						CASE
							WHEN  @BudPos = 'Approved' THEN AppBudget
							WHEN @BudPos = 'Most Recent EA' THEN CurrEA
							WHEN @BudPos = 'Most Recent Actual' THEN CurrAct
							ELSE NULL
						END
					FROM @Budget 
					WHERE PGM = @Program AND BudYr = @CurrFY)

				WHEN A.CREATE_MONTH = '06' THEN AVG(HXEX.Proportion)*
					(SELECT
						CASE
							WHEN  @BudPos = 'Approved' THEN AppBudget
							WHEN @BudPos = 'Most Recent EA' THEN CurrEA
							WHEN @BudPos = 'Most Recent Actual' THEN CurrAct
							ELSE NULL
						END
					FROM @Budget 
					WHERE PGM = @Program AND BudYr = @CurrFY)

				ELSE NULL

			END AS ObgPlan

		,MAX(CASE
				WHEN FY.FiscalYr = @CurrFY THEN FY.Amount
				ELSE 0
			END 
		) AS Actuals

		,COUNT(DISTINCT B.CS_ID) AS CaseCount
				
	FROM MRB026E AS A
	
	INNER JOIN FY
		ON A.CREATE_YEAR = FY.CREATE_YEAR
		AND A.CREATE_MONTH = FY.CREATE_MONTH

	INNER JOIN HXEX
		ON A.CREATE_YEAR = HXEX.CREATE_YEAR
		AND A.CREATE_MONTH = HXEX.CREATE_MONTH

	LEFT JOIN MR0009E AS B
		ON B.CREATE_YEAR = A.CREATE_YEAR
		AND B.CREATE_MONTH = A.CREATE_MONTH
		AND B.PGM_TYP_CD = @Program
		AND B.CS_ID = A.CS_ID
		AND B.RECORD_TYPE = 'C'
		AND FY.FiscalYr = @CurrFY

	GROUP BY
		FY.FiscalQtr
		,FY.FiscalMo
		,A.CREATE_MONTH

	ORDER BY 
		FY.FiscalMo DESC