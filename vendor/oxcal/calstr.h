#define FILE_STRSTR		"calstr.h"
#define FILE_INISTR		"Oxcal3.ini"
#define STR_VERSIONSTR	"v4.1001"
#define STR_VERSION			0	/*v4.1001*/
#define STR_CANCELLED	     1 	/*CANCELLED*/
#define STR_WORKING	     2	/*Working*/
#define STR_STILLWORKING     3	/*working...*/
#define STR_PLEASEWAIT	     4	/*please wait*/
#define STR_ENTERNAME	     5	/*Name must be entered*/
#define STR_ENTERDATE	     6	/*Date must be entered*/
#define STR_ENTERERROR	     7	/*Error must be entered*/
#define STR_ENTERPARMS	     8	/*Parameters must be entered*/
#define STR_INPUTERROR	     9	/*Input Error*/
#define STR_BADRESOLUTION   10	/*Invalid resolution (1..100)*/
#define STR_INVALIDPLOTNO   11	/*Invalid plot number (1..30)*/
#define STR_COMPILING	    12	/*Compiling*/
#define STR_APPLYTOCURRENT  13	/*Apply to current group*/
#define STR_CALCMENU	    14	/*&Calculate\tAlt+F10*/
#define STR_RECALCMENU	    15	/*Alter &data\tAlt+F10*/
#define STR_CALCULATING	    16	/*Calculating*/
#define STR_CHECKINGNAMES   17	/*checking names...*/
#define STR_NUMBERING	    18	/*numbering items...*/
#define STR_TESTINGREL	    19	/*testing for relations...*/
#define STR_COMPUTING	    20	/*calculating distributions...*/
#define STR_QUESTSAVE	    21	/*New data has been\nentered.  Save file\nbefore closing*/
#define STR_QUESTSAVEFILE   22	/* has\nchanged.  Save file\nbefore closing*/
#define STR_CLOSINGRUN	    23	/*Closing run*/
#define STR_SAVERUN	    24	/*Save run file*/
#define STR_QUESTDEL	    25	/*Are you sure you want to delete*/
#define STR_EDITGROUP	    26	/*Edit group*/
#define STR_RENAMETO	    27	/*Rename to*/
#define STR_OPENDATA	    28	/*Open data file*/
#define STR_OPENPLOT	    29	/*Open plot file*/
#define STR_OPENRUN	    30	/*Open run file*/
#define STR_CLOSELOG	    31	/*Close log file*/
#define STR_APPENDRUN	    32	/*Append run file*/
#define STR_KEEPPLOT	    34	/*Keep plot file*/
#define STR_DEFAULT1	    35	/*Calendar date 1*/
#define STR_DEFAULT2	    36	/*Calendar date 2*/
#define STR_CALENDARAGE	    37	/*Calendar date*/
#define STR_CALENDARYEARS   38	/*Calendar years*/
#define STR_RADIOCARBONAGE  39	/*Radiocarbon determination*/
#define STR_CALIBAGE	    40	/*Calibrated date*/
#define STR_OPTIONSHELP	    41	/* plts curv rang dist gauss norm ref bp pgno col cont solid hist grid shad ital fine vert font size*/
#define STR_PRINTERBUSY	    42	/*Printer being used*/
#define STR_CALIBPLOT	    43	/*Calibration plot*/
#define STR_GOTOPAGE	    44	/*Goto Page*/
#define STR_NEWPAGENO	    45	/*new page number*/
#define STR_OPEN	    46	/*Open*/
#define STR_SAVEAS	    47	/*Save as*/
#define STR_PRINTDOCNAME    48	/*Cal_Plot*/
#define STR_PRINTING	    49	/*Printing*/
#define STR_COMMANDPMT	    50	/*command*/
#define STR_NAMEPMT	    51	/*name date error [ENTER]*/
#define STR_EXPECTINGPMT    52	/*expecting*/
#define STR_DATEPMT	    53	/*date*/
#define STR_ERRORPMT	    54	/*error*/
#define STR_READINGCAL	    55	/*Reading calibration curve*/
#define STR_OFFSET	    56	/*Offset : */
#define STR_XTEST	    57	/*X2-Test:*/
#define STR_LIKELIHOOD      58  /*Likelihood*/
#define STR_AGREEMENT	    59	/*Agreement*/
#define STR_OVERAG	    61	/*Overall agreement*/
#define STR_DYNAMICAG	    62	/*Dynamic agreement*/
#define STR_UNDEFINED	    63	/*values undefined*/
#define STR_TOOLOW	    64	/*cannot resolve order (low)*/
#define STR_TOOHIGH	    65	/*cannot resolve order (high)*/
#define STR_USINGMCMC	    66	/*work.operation="MCMC";*/
#define STR_READINGFILES    67  /*reading in files*/
#define STR_INITIALISING    68	/*initialising*/
#define STR_FINDINDEX       69  /*finding indices*/
#define STR_DONE	    70	/*work.done=*/
#define STR_CONV	    71	/*work.convergence=*/
#define STR_RPTSTARTMCMC    72	/*( MCMC*/
#define STR_RPTENDMCMC	    73	/*) MCMC*/
#define STR_REPORTING	    74	/*reporting*/
#define STR_COLLAPSING	    75	/*collapsing arrays*/
#define STR_CALCSHIFT	    76	/*work.operation="Shift";*/
#define STR_CALCDIFF	    77	/*work.operation="Difference";*/
#define STR_PROGACTIVE	    78	/*Program active*/
#define STR_PROGWAIT	    79	/*Please wait\nuntil it has\nfinished*/
#define STR_PAGE            80	/*Page*/
#define STR_OF		    81  /*of*/
#define STR_TO		    82  /*to*/
#define STR_LINESREAD	    83	/*lines read*/
#define STR_CALCFACT        84  /*work.operation="Factor";*/
#define STR_ATEST	    85	/*Agreement test:*/
#define STR_OVERALL	    86  /*Overall*/
#define STR_PROBABILITY	    87	/*Probability*/
#define STR_SEEPLOT	    88  /*Plot file created : */
#define STR_DYNAMIC	    89  /*Dynamic*/
#define STR_CHECKINGCONV    90  /*checking convergence*/
#define STR_ABOUT	    91  /*Radiocarbon Calibration\nand Statistical Analysis Program*/
#define STR_COPYRIGHT	    92  /*(c) Copyright Christopher Bronk Ramsey 1995*/
#define STR_ADDRESS	    93  /*Research Lab for Archaeology\n6 Keble Rd\nOxford OX1 4JD*/
#define STR_OK		    94  /*work.ok=*/
#define STR_PASS	    95  /*work.passes=*/
#define STR_RESETLOG	    96  /*clear contents*/
#define STR_NORMPROB        97	/*Probability per year*/
#define STR_RELPROB	    98	/*Relative probability*/
#define STR_NONAME	    99	/*Undefined*/

#define STR_RPTPOSTTYPE	   101	/* */
#define STR_RPTPOSTNAME	   102	/* */
#define STR_RPTPREDATE	   103	/*: */
#define STR_RPTPM	   104	/*+/-*/
#define STR_RPTBP	   105	/*BP*/
#define STR_RPTRCBP	   106	/*BP*/
#define STR_RPTBC	   107	/*BC*/
#define STR_RPTAD	   108	/*AD*/
#define STR_RPTPREMULT	   109	/*\n*/
#define STR_RPTPRESINGLE   110	/* */
#define STR_RPTPREINF	   111	/*  */
#define STR_RPTCONF	   112	/*% probability\n*/
#define STR_RPTSIGMA	   113	/* sigma\n*/
#define STR_RPTPRERANGE	   114	/*    */
#define STR_RPTPREPROP	   115	/* (*/
#define STR_RPTPOSTPROP	   116	/*) */
#define STR_RPTNOPROP	   117	/*  */
#define STR_RPTNOLIMIT	   118	/*...*/
#define STR_RPTINTERRANGE  119	/*\n*/
#define STR_RPTENDRANGE	   120	/*\n*/
#define STR_RPTENDDIST	   121	/**/
#define STR_RPTBATSEP	   122  /*\t*/
#define STR_RPTBATINTER    123  /*\n*/
#define STR_RPTCALAD       124	/*CalAD*/
#define STR_RPTCALBC	   125	/*CalBC*/
#define STR_RPTBCAD		   126	/*BC/AD*/
#define STR_RPTCALBCAD     127	/*CalBC/CalAD*/
#define STR_RPTINFINITY    128	/*Ø*/
#define STR_RPTCALBP       129	/*CalBP*/

#define STR_OPTBCAD	   130	/*0 for BC/AD 1 for BP*/
#define STR_OPTTERSE	   131	/*0 for long prompt 1 for terse*/
#define STR_OPTLANG	   132	/*1 for macro language 0 for line input*/
#define STR_OPTSD	   133	/*1 to give range*/
#define STR_OPTWHOLE	   134	/*0 for split range 1 for whole range*/
#define STR_OPTPROB	   135	/*0 for intercept method 1 for probability*/
#define STR_OPTSIGN	   136	/*0 for 'BC' and 'AD' 1 for '+' and '-'*/
#define STR_OPTREP	   137	/*1 to save distributions*/
#define STR_OPTRPLOT	   138  /*1 to plot sequences in reverse order*/
#define STR_OPTRESOL	   139	/*calculation resolution*/
#define STR_OPTCUBIC	   140	/*0 for linear 1 for cubic interpolation*/
#define STR_OPTMAX	   141	/*limit of bp range*/
#define STR_OPTAPPEND	   142	/*filename   to append output to a file*/
#define STR_OPTWRITE	   143	/*filename   to write output to a file*/
#define STR_OPTREAD	   144	/*filename   to read input from a file*/
#define STR_OPTCAL	   145	/*filename   to use another calibration file*/
#define STR_OPTROUND	   146  /*1 to round ranges*/
#define STR_OPTUNISPAN	147	/*0 for old method 1 for uniform span prior*/
#define STR_OPTINCLCONV 148 /*1 to include convergence data in plot files*/
#define STR_ROPTNONUNISPAN    149  /*non-usp*/
#define STR_ROPTLINEAR	   150	/*lin*/
#define STR_ROPTCUBIC	   151	/*cub*/
#define STR_ROPTPROB	   152	/*prob*/
#define STR_ROPTINTER	   153	/*intr*/
#define STR_ROPTWHOLE	   154	/*whole*/
#define STR_ROPTRES	   155	/*r*/
#define STR_ROPTSD         156	/*sd*/
#define STR_ROPTUP	   157  /*strat*/
#define STR_ROPTDOWN       158  /*chron*/
#define STR_ROPTNONLIN	   159  /*inv_sq*/

#define STR_PRIOR		160	/*Calculated distributions*/
#define STR_POSTERIOR	161 /*Modelled distributions*/
#define STR_PRIORINT	162	/*Calculated intervals*/
#define STR_POSTINT		163	/*Modelled intervals*/
#define STR_INTERVALS	164	/*Intervals*/
#define STR_PLOTS		165 /*Plotted results*/
#define STR_ELEMENTS	166 /*Elements of*/
#define STR_OXCALDIR	167	/*Choose directory for OxCal output files*/

#define VERB_AGE	174 /*Age*/
#define	VERB_ANTE	175	/*Before*/
#define	VERB_AXIS	176	/*Axis*/
#define	VERB_BEGIN	177	/*First*/
#define	VERB_BOUND	178	/*Boundary*/
#define	VERB_CALC	179	/*Calculate*/
#define	VERB_CALEND	180	/*C_Date*/
#define	VERB_CCOMB	181	/*C_Combine*/
#define	VERB_COMB	182	/*Combine*/
#define	VERB_COMMENT	183	/*!*/
#define	VERB_CORREL	184	/*Correlation*/
#define	VERB_CSIM	185	/*C_Simulate*/
#define	VERB_CURVE	186	/*Curve*/
#define	VERB_DATE	187	/*Date*/
#define	VERB_DELTAR	188	/*Delta_R*/
#define VERB_DEPTH  189 /*Depth_Model*/
#define	VERB_DIFF	190	/*Difference*/
#define	VERB_DSEQ	191	/*D_Sequence*/
#define	VERB_END	192	/*Last*/
#define	VERB_ERROR	193	/*Error*/
#define	VERB_EVENT	194	/*Event*/
#define VERB_EXP	195 /*Exp*/
#define	VERB_FACT	196	/*Factor*/
#define	VERB_FILE	197	/*Prior*/
#define	VERB_GAP	198	/*Gap*/
#define	VERB_LABEL	199	/*Label*/
#define	VERB_LINE	200	/*Line*/
#define VERB_MCMC	201 /*MCMC_Sample*/
#define	VERB_MIX	202	/*Mix_Curves*/
#define	VERB_NOOP	203	/*NoOp*/
#define VERB_NORMAL 204 /*N*/
#define VERB_NUMBER 205 /*Number*/
#define	VERB_OFFS	205	/*Offset*/
#define	VERB_OPTION	207	/*Options*/
#define	VERB_ORDER	208	/*Order*/
#define VERB_P		209 /*P*/
#define	VERB_PAGE	210	/*Page*/
#define	VERB_PAUDATE	211	/*PaU_Date*/
#define	VERB_PAUSIM	212	/*PaU_Simulate*/
#define	VERB_PERIOD	213	/*Period*/
#define	VERB_PHASE	214	/*Phase*/
#define	VERB_PLOT	215	/*Plot*/
#define	VERB_POST	216	/*After*/
#define	VERB_PSEQ	217	/*P_Sequence*/
#define VERB_QMODEL 218 /*Outlier_Model*/
#define	VERB_QUEST	219	/*Outlier*/
#define	VERB_RAND	220	/*R_Simulate*/
#define	VERB_RANG	221	/*Interval*/
#define	VERB_RCOMB	222	/*R_Combine*/
#define	VERB_F14C	223	/*R_F14C*/
#define	VERB_RDATE	224	/*R_Date*/
#define	VERB_RESERV	225	/*Reservoir*/
#define	VERB_SAMP	226	/*Posterior*/
#define	VERB_SAMPLE	227	/*Sample*/
#define VERB_SAP    228 /*Sapwood*/
#define	VERB_SEQ	229	/*Sequence*/
#define	VERB_SHIFT	230	/*Shift*/
#define	VERB_SIGMA	231	/*Sigma_Boundary*/
#define VERB_SMODEL 232 /*Sapwood_Model*/
#define	VERB_SPAN	233	/*Span*/
#define	VERB_SUM	234	/*Sum*/
#define	VERB_T		235	/*T*/
#define	VERB_TAQ	236	/*TAQ*/
#define	VERB_TAU	237	/*Tau_Boundary*/
#define	VERB_THUDATE	238	/*ThU_Date*/
#define	VERB_THUSIM	239	/*ThU_Simulate*/
#define VERB_TOPHAT 240 /*Top_Hat*/
#define	VERB_TPQ	241	/*TPQ*/
#define VERB_U		242	/*U*/
#define	VERB_USEQ	243	/*U_Sequence*/
#define VERB_VALUE	244 /*Probability*/
#define	VERB_VSEQ	245	/*V_Sequence*/
#define	VERB_XREF	246	/*XReference*/
#define	VERB_ZERO	247	/*Zero_Boundary*/

#define HELP_AGE	248 /*Age type conversion*/
#define	HELP_ANTE	249	/*Probability of preceding*/  
#define	HELP_AXIS	250	/*Axis limits*/   
#define	HELP_BEGIN	251	/*First of a group*/ 
#define	HELP_BOUND	252	/*Phase boundary*/   
#define	HELP_CALC	253	/*Pre-calculate*/    
#define	HELP_CALEND	254	/*Calendar date*/   
#define	HELP_CCOMB	255	/*Combine calendar dates*/  
#define	HELP_COMB	256	/*Combine probabilities*/   
#define	HELP_COMMENT	257	/*Comment*/    
#define	HELP_CORREL	258	/*Correlation*/    
#define	HELP_CSIM	259	/*Simulate calendar date*/  
#define	HELP_CURVE	260	/*Radiocarbon calibration curve*/  
#define	HELP_DATE	261	/*Date type conversion*/   
#define	HELP_DELTAR	262	/*Delta-R reservoir shift*/ 
#define HELP_DEPTH	263 /*Depth model interpolation*/ 
#define	HELP_DIFF	264	/*Age difference*/   
#define	HELP_DSEQ	265	/*Defined sequence*/   
#define	HELP_END	266	/*End of a group*/ 
#define	HELP_ERROR	267	/*Age error*/   
#define	HELP_EVENT	268	/*Undated event*/   
#define	HELP_EXP	269	/*Exponential distribution*/   
#define	HELP_FACT	270	/*Age factor*/   
#define	HELP_FILE	271	/*Prior distribution*/   
#define	HELP_GAP	272	/*Gap between/after*/   
#define	HELP_LABEL	273	/*Text label*/   
#define	HELP_LINE	274	/*Line*/
#define HELP_MCMC	275 /*MCMC Samples written to file*/
#define	HELP_MIX	276	/*Mix radiocarbon calibration curves*/ 
#define	HELP_NOOP	277	/*Null operation*/
#define HELP_NORMAL	278 /*Normal distribution*/
#define HELP_NUMBER 279 /*Number type conversion*/
#define	HELP_OFFS	280	/*Offset*/    
#define	HELP_OPTION	281	/*Program options*/   
#define	HELP_ORDER	282	/*Find event order*/  
#define HELP_P		283 /*Probability distribution*/
#define	HELP_PAGE	284	/*New page*/   
#define	HELP_PAUDATE	285	/*PaU U-series date*/  
#define	HELP_PAUSIM	286	/*Simulate PaU U-series date*/ 
#define	HELP_PERIOD	287	/*Period information*/   
#define	HELP_PHASE	288	/*Unordered group*/   
#define	HELP_PLOT	289	/*Plot group*/   
#define	HELP_POST	290	/*Probability of following*/  
#define	HELP_PSEQ	291	/*Poisson distributed sequence*/
#define	HELP_QMODEL	292	/*Outlier model*/  
#define	HELP_QUEST	293	/*Question an event*/  
#define	HELP_RAND	294	/*Simulate radiocarbon date*/  
#define	HELP_RANG	295	/*Interval*/    
#define	HELP_RCOMB	296	/*Combine radiocarbon dates*/  
#define	HELP_RDATE	267	/*Radiocarbon date*/   
#define	HELP_F14C	298	/*Radiocarbon fraction modern*/  
#define	HELP_RESERV	299	/*Reservoir time constant*/  
#define	HELP_SAMP	300	/*Sampled distribution*/   
#define	HELP_SAMPLE	301	/*Sample from a distribution*/  
#define HELP_SAP    302 /*Sapwood estimated date*/
#define	HELP_SEQ	303	/*Ordered group*/   
#define	HELP_SHIFT	304	/*Date A shifted by B*/
#define	HELP_SIGMA	305	/*1 sigma boundary*/
#define	HELP_SMODEL	306	/*Sapwood model*/ 
#define	HELP_SPAN	307	/*Span of a group*/ 
#define	HELP_SUM	308	/*Sum probabilities*/   
#define	HELP_T		309	/*T-Distribution*/  
#define	HELP_TAQ	310	/*Terminus Ante Quem*/  
#define	HELP_TAU	311	/*Exponential time constant boundary*/
#define	HELP_THUDATE	312	/*ThU U-series date*/  
#define	HELP_THUSIM	313	/*Simulate ThU U-series date*/
#define HELP_TOPHAT 314 /*Top hat distribution*/ 
#define	HELP_TPQ	315	/*Terminus Post Quem*/
#define HELP_U		316 /*Uniform probability distribution*/  
#define	HELP_USEQ	317	/*Uniform deposition sequence*/
#define HELP_VALUE	318	/*Probability of a specific value*/   
#define	HELP_VSEQ	319	/*Variable sequence*/   
#define	HELP_XREF	320	/*Cross reference*/   
#define	HELP_ZERO	321	/*Zero level phase boundary*/

#define HELP_HTMLBROWSER   322  /*HTML Browser (Netscape|Internet Explorer|...)*/
#define HELP_CONT		323	/*oxcal.htm*/
#define HELP_14I		324	/*oper_14i.htm*/
#define HELP_14P		325	/*oper_14p.htm*/
#define HELP_14A		326	/*oper_14a.htm*/
#define HELP_14L		327	/*oper_14l.htm*/
#define HELP_FULLIND    329 /*full_ind.htm*/
#define HELP_DELTA_R	329 /*http://calib.org/marine/*/

#define FILT_CALIB	   330	/*Calibration data files (*.14c,*.dta)|*.14c; *.dta||*/
#define FILT_RUNALL	   331	/*Run files (*.14i)|*.14i|All files (*.*)|*.*||*/
#define FILT_LOGALL	   332	/*Log files (*.14l)|*.14l|All files (*.*)|*.*||*/
#define FILT_PLOT	   333	/*Plot files (*.14p)|*.14p|*/
#define FILT_DATASAMP	   334	/*Data files (*.14d)|*.14d|Sample files (*.14s)|*.14s||*/
#define FILT_END	   335	/*|*/
#define FILT_ALL	   336	/*All files|*.*||*/
#define FILT_PERIOD        337  /*Periods (*.htm)|*.htm||*/
#define FILT_EXE	   338  /*Executables (*.exe)|*.exe||*/

#define ERR_INFORM	   350	/*i : */
#define ERR_WARN	   351	/*Warning! */
#define ERR_FATAL	   352	/*Fatal Error! */
#define ERR_OPTIONSSAVED   353	/*Options Saved*/
#define ERR_COMMACTIVE	   354	/*Command line active*/
#define ERR_EXITHELP	   355	/*(exit with '}')*/
#define ERR_PROGACTIVE	   356	/*Program active*/
#define ERR_PLEASEWAIT	   357	/*please wait*/
#define ERR_CALCULATED	   358	/*Already Calculated*/
#define ERR_CALCHELP	   359	/*choose Alter data option*/
#define ERR_PLOTONLY	   360	/*Plot only window*/
#define ERR_WINDACTIVE	   361	/*Window active*/
#define ERR_NOTDATE	   362	/*Not a date*/
#define ERR_NOTCAL	   363	/*Not a calendar date*/
#define ERR_NOTRC	   364	/*Not a radiocarbon date*/
#define ERR_BADCOMMAND	   365	/*Inappropriate command*/
#define ERR_DUPLICATES	   366	/*Duplicate names found*/
#define ERR_EDITHELP	   367	/*please edit*/
#define ERR_SUBSID	   368	/*Subsidiary window*/
#define ERR_SUBSIDHELP	   369	/*close and calculate parent*/
#define ERR_FILENOTCALSAM  370	/*Wrong file type (.14d, .14s)*/
#define ERR_WRONGFILE	   371	/*Wrong file type (.14d, .14s, .14p)*/
#define ERR_FILENOTFOUND   372	/*File not found*/
#define ERR_MEMCAL	   373	/*Not enough memory for calibration curve arrays*/
#define ERR_MEMARRAY	   374	/*Not enough memory for working arrays*/
#define ERR_REFERENCES	   375	/*Ref*/
#define ERR_OUTOFRANGE	   376	/*Date out of range*/
#define ERR_NEAREND	   377	/*Date may extend out of range*/
#define ERR_PROBOUT	   378	/*Date probably out of range*/
#define ERR_BADNEST	   379	/*Inappropriate nesting*/
#define ERR_NESTEDIN	   380	/*into*/
#define ERR_SETTO	   381	/*set to*/
#define ERR_BADGAP	   382	/*Inappropriate gap error*/
#define ERR_NEGATIVE	   383	/*Negative value*/
#define ERR_MADEPOS	   384	/*forced positive*/
#define ERR_NOPARMS	   385	/*Parameters not found*/
#define ERR_DUPLNAMES	   386	/*Duplicate names*/
#define ERR_DUPLNAMESGRP   387	/*Duplicate names found in group*/
#define ERR_NOFILESFOR	   388	/*Files not found for*/
#define ERR_NOGIBBSNOS     389  /*Numbers not found*/
#define ERR_RELATION	   390	/*Error in relation*/
#define ERR_GAPCONFLICT	   391	/*Conflicting gaps used with a reference*/
#define ERR_ASSUMEGAP	   392	/*assuming gap for*/
#define ERR_TOOMANYGIBBS   393  /*Too many distributions*/
#define ERR_NOREL	   394	/*Cannot find relationship*/
#define ERR_SELFREL	   395	/*Self referential relationship*/
#define ERR_RANGEUNCERTAIN 396	/*Cannot be sure of range*/
#define ERR_NORANGE	   397	/*Cannot find range*/
#define ERR_GIBBSCOMPLETE  398	/*MCMC sample completed*/
#define ERR_GIBBSFAIL	   399	/*MCMC sample failed*/
#define ERR_GIBBSTERM	   400	/*MCMC sample terminated*/
#define ERR_GIBBSABORT	   401	/*MCMC sample aborted*/
#define ERR_ITUSED	   402	/*iterations used*/
#define ERR_DISTNULL	   403	/*NULL distribution*/
#define ERR_DISTZERO	   404	/*ZERO distribution*/
#define ERR_NORANGECALC	   405	/*Not calculating range*/
#define ERR_XESTIMATED	   406	/*X-Test value estimated*/
#define ERR_XFAILS	   407	/*X-Test fails at 5%*/
#define ERR_NOHELP	   408	/*Help file not found*/
#define ERR_NOTRENAMED	   409	/*File not renamed to*/
#define ERR_NOTOPENNED	   410	/*Unable to open*/
#define ERR_NODATA	   411	/*No data found*/
#define ERR_NOMAKE	   412	/*Cannot make array*/
#define ERR_FUNCREDEF      414  /*Value for function redefined*/
#define ERR_NOEXTRACT      415  /*Cannot extract numerical data*/
#define ERR_AFAILS         416  /*Poor agreement*/
#define ERR_BEYONDRANGE	   417  /*Number out of range*/
#define ERR_INCREASERES    418  /*make system resolution coarser*/
#define ERR_RESCHANGED     419  /*System resolution changed to*/
#define ERR_POORCONV	   420  /*Poor convergence reported in*/
#define ERR_MANYPLOTS	   421	/*Large number of plots*/
#define ERR_NONLINEAR	   422	/*Only possible for linear modelling*/
#define ERR_NONLINRES	   423	/*Incompatable non-linear resolution*/
#define ERR_DUPLBOUND      424  /*Confused boundary setup*/
#define ERR_NOBOUNDARIES   425  /*No boundaries used - check manual*/
#define ERR_XREFBOUND      426  /*Extensive use of cross referenced boundaries can cause problems*/
#define ERR_CURVEDEFINED   427	/*Curve already defined - cannot set Delta_R or Reservoir*/
#define ERR_NONGLOBALOPTIONS  428  /*Options can only be set globally*/
#define ERR_ORDERPROBLEM	429	/*Cannot resolve order*/
#define ERR_MODELPROBLEM	430 /*Model not supported in this context*/
#define ERR_ASSIGNCONFLICT	431 /*Assignement conflict*/
#define ERR_NOOUTLIERMODEL	432 /*No outlier model specified - use Outlier_Model()*/
#define ERR_NOVALUE			433 /*Cannot determine value*/
#define ERR_CONSTRAINT		434 /*Cannot apply constraint*/

#define VERB_OLDCALEND	450	/*cal*/
#define VERB_OLDDATE	451	/*date*/
#define VERB_OLDFILE	452	/*file*/
#define VERB_OLDRAND	453	/*rand*/
#define VERB_OLDASYM	454	/*asym*/
#define VERB_OLDQUEST	455 /*question*/

#define FILE_CALHELP	   463	/*OXCAL.HLP*/
#define FILE_OPT	   464	/*OxCal.dat*/
#define FILE_LAUNCH	   466	/*OxCalLaunch.dat*/
#define FILE_CALIB	   470  /*intcal98.14c*/
#define FILE_NONAME	   472  /*Untitled*/
#define FILE_DATADIR   473	/*\\Data\\*/
#define FILE_MANUALDIR 474  /*\\Manual\\*/
#define FILE_PREAMBLE  475  /*Preamble.txt*/
#define FILE_POSTAMBLE 476  /*Postamble.txt*/
#define FILE_RELFILE   477  /*OxCal.rel*/
#define FILE_TABFILE   478  /*OxCalTab.txt*/

#define EXT_WORK 	   481	/*.work*/
#define EXT_PRIOR	   482	/*.prior*/
#define EXT_LOG 	   485	/*.log*/
#define EXT_GRN		   486  /*.dta*/
#define EXT_SEAT	   487  /*.14c*/
#define EXT_EXE        488  /*.exe*/
#define EXT_JS		   489  /*.js*/
#define EXT_TXT        490  /*.txt*/
#define EXT_CSV		   491	/*.csv*/
#define EXT_PATH	   492  /*Path.dat*/

#define OPT_CURVE			500	/*Curve*/
#define OPT_CUBIC			501 /*Cubic*/
#define OPT_BCAD			502 /*BCAD*/
#define OPT_PLUSMINUS		503 /*PlusMinus*/
#define OPT_USP				504 /*UniformSpanPrior*/
#define OPT_KITERATIONS		505	/*kIterations*/
#define OPT_SD1				506 /*SD1*/
#define OPT_SD2				507 /*SD2*/
#define OPT_SD3				508 /*SD3*/
#define OPT_ROUND			509	/*Round*/
#define OPT_ROUNDBY			510 /*RoundBy*/
#define OPT_FLORUIT			511 /*Floruit*/
#define OPT_RESOLUTION		512	/*Resolution*/
#define OPT_CONVERGENCE		513 /*ConvergenceData*/
#define OPT_YEAR			514 /*Year*/
#define OPT_RAW				515 /*RawData*/
#define OPT_F14C			516 /*UseF14C*/
#define OPT_INTERCEPT		517 /*Intercept*/
#define OPT_END				518 /**/

#define JS_LIKELIHOOD		580 /*likelihood*/
#define JS_POSTERIOR		581 /*posterior*/
