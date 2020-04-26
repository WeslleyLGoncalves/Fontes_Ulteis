#Include 'Protheus.ch'
#Include "TopConn.ch"
/*
+-----------+------------+----------------+-------------------+-------+---------------+
| Programa  | FLerUse    | Desenvolvedor  | WESLLEY GONCALVES | Data  | 11.09.2015    |
+-----------+------------+----------------+-------------------+-------+---------------+
| Descricao | Relatório Específico separação de mercadorias (NOVO )                   |
+-----------+-------------------------------------------------------------------------+
| Modulos   | SIGAFAT                                                                 |
+-----------+-------------------------------------------------------------------------+
| Processos |                                                                         |
+---------- +-------------+-----------------------------------------------------------+
| DATA      | PROGRAMADOR | MOTIVO                                                    |
+-----------+-------------+-----------------------------------------------------------+
*/
//TRCell():New(oSection,"VALORBRUT","TRB","VL. UNITARIO", "@E 999,999,999.99", 12,/*lPixel*/,/*CodeBlock*/)

#Include 'Protheus.ch'

User Function FLerUse()
	************************
	*  Funçao principal	   *
	************************
	
	Local   oBreak
	Private oReport
	Private cAliasQry   := GetNextAlias()//dbSelectArea(cAliasQry)
	Private cClieDe := ""
	Private cClieAte:= ""
	Private cLojDe  := ""
	Private cLojAte := ""
	Private cPerg := "FLerUse"
	
	CriaPerg()

	oReport := TReport():New("FLerUse","usuario",cPerg,{|oReport| PrintReport()},"usuario")
	Pergunte(oReport:GetParam(),.F.)
	
	oReport:nDevice		:= 4	//Envia para Spool
	oReport:nEnvironment:= 2	//Cliente
	oReport:SetPortrait()     // Define a orientacao de pagina do relatorio como retrato.
	oReport:HideParamPage()   // Desabilita a impressao da pagina de parametros.
	
	oSection1 := TRSection():New(oReport,"Usuario",cAliasQry)
	TRCell():New(oSection1,"_ID_USER"	,,"Id_Usuario",,030)
	TRCell():New(oSection1,"_NOM_USER"	,,"Nome"      ,,030)
	TRCell():New(oSection1,"_NCOMP_USER",,"Nome Compl",,030)
	TRCell():New(oSection1,"_EMAIL_USER",,"E-Mail"    ,,030)
	TRCell():New(oSection1,"_BLOQ_USER"	,,"Bloqueado" ,,030)
		
	oSection2 := TRSection():New(oReport,"Menu",)
	TRCell():New(oSection2,"_CAM_ME"	,,"Menu",,030)
	TRCell():New(oSection2,"_MOD_ME"	,,"Modulo",,030)
	
	//Objeto oReport faz a chamada da Janela de Dialogo da Impreção
	oReport:PrintDialog()
	
	If (Select(cAliasQry)!= 0)
		dbSelectArea(cAliasQry)
		dbCloseArea()
		
		If File(cAliasQry+GetDBExtension())
			FErase(cAliasQry+GetDBExtension())
		EndIf
	EndIf
	
Return

Static Function PrintReport()
	*************************************************
	*  Seleciona os titulos marcados pelo usuario.	*
	*************************************************
	
	Local oSection1 := oReport:Section(1)
	Local oSection2 := oReport:Section(2)
	Local aMtrUser  := {} 
	Local nPrinMen  := MV_PAR01
	Local nUseBlo   := MV_PAR02  
	
	aMtrUser:=AllUsers()
	
	//Define a mensagem apresentada durante a geração do relatório.
	oReport:SetMsgPrint("Lendo Registros")
	
	//Seta o contador da regua
	oReport:SetMeter(Len(aMtrUser))

	For nUs:=1 To Len(aMtrUser)
			
			If nUseBlo == 2 .and. aMtrUser[nUs,01,17]
				Loop
			EndIf				

			If oReport:nDevice == 4 //Execell
				If !oReport:lStartPage
					oReport:lStartPage:=.T.
				EndIf	
			EndIf
					
			//Inicializa a Seção
			oSection1:Init()
			cInfPed:= "Espelho para Separação Nº: " + AllTrim(SC5->C5_NUM)+ " Data: " +DToC(SC5->C5_EMISSAO)
			
			oSection1:Cell("_ID_USER"  	):SetBlock( { || aMtrUser[nUs,01,01] } )
			oSection1:Cell("_NOM_USER"  ):SetBlock( { || aMtrUser[nUs,01,02] } )
			oSection1:Cell("_NCOMP_USER"):SetBlock( { || aMtrUser[nUs,01,04] } )
			oSection1:Cell("_EMAIL_USER"):SetBlock( { || aMtrUser[nUs,01,14] } )
			oSection1:Cell("_BLOQ_USER" ):SetBlock( { || IIf(!aMtrUser[nUs,01,17],"Não","Sim") } )

			oSection1:PrintLine()

			If nPrinMen == 1
				/*Finaliza seção inicializada pelo método Init.*/
				oSection1:Finish()
				oSection2:Init()
			
				//For para ler menus do usuario
				For nMe:= 01 To Len(aMtrUser[nUs,03])
					If At('X',SubStr(aMtrUser[nUs,03,nMe],1,4))==0 //Validar ser está mmarcado no SIGACFG
						If oReport:nDevice == 4 //Execell
							If !oReport:lStartPage
								oReport:lStartPage:=.T.
							EndIf	
						EndIf
						
						nArq:= SubStr(aMtrUser[nUs,03,nMe],4)
						
						oSection2:Cell("_CAM_ME" ):SetBlock( { || nArq  } )
						oSection2:Cell("_MOD_ME" ):SetBlock( { || LerMen(nArq)  } )
						
						oSection2:PrintLine()
					EndIf
				Next nMe
			Else
				oSection2:Cell("_CAM_ME" ):Disable()
				oSection2:Cell("_MOD_ME" ):Disable()
		EndIf
				oSection2:Finish()
	Next nUr

	/*Finaliza seção inicializada pelo método Init.*/
	oSection1:Finish()
	oSection2:Finish()
	
	/*Salta uma linha baseado na altura da linha informada pelo usuário*/
	//	oSection1:Print()
	oReport:SkipLine()
	
	/*Incrementa a régua da tela de processamento do relatório*/
	oReport:IncMeter()
	
Return

Static Function CriaPerg()/*/
	ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
	±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
	±±³Programa  ³ CriaPerg ³ Autor ³ WESLLEY GONCALVES     ³ Data ³28.08.2008³±±
	±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
	±±³Descri‡…o ³A funcao estática CriaPerg faz uma seleçao e cria automati- ³±±
	±±³          ³camente as perguntas no SX1.                                ³±±
	±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
	±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß/*/
	//criacao de algumas variaveis para a inclusao das perguntas no sistema
	
	Local aArea := GetArea()
	
	PutSx1( cPerg, "01","Imprime menu?" ,"Imprime menu?" ,"Imprime menu?" ,"MV_CH1","N",01,0,1,"C","",  ,"","N","MV_PAR01","Sim","","","","Não","","","")
	PutSx1( cPerg, "02","Impr. Usuario Bloqueado?" ,"Impr. Usuario Bloqueado?" ,"Impr. Usuario Bloqueado?" ,"MV_CH2","N",01,0,1,"C","",  ,"","N","MV_PAR02","Sim","","","","Não","","","")
	//PutSx1(cGrupo,cOrdem,cPergunt,cPerSpa,cPerEng,cVar,cTipo,nTamanho,nDecimal,nPresel,cGSC,cValid,cF3,cGrpSxg,cPyme,;
		//                            cVar01,cDef01,cDefSpa1,cDefEng1,cCnt01,cDef02,cDefSpa2,cDefEng2,cDef03,cDefSpa3,cDefEng3,cDef04,cDefSpa4,cDefEng4,;
		//                           cDef05,cDefSpa5,cDefEng5,aHelpPor,aHelpEng,aHelpSpa,cHelp)
	
	RestArea(aArea)
	
Return

Static Function LerMen(cArquiv)
***************************************
**
***************************************
	Local cMod:= ""
	Local nHandle:= FOPEN(cArquiv) //, FO_READWRITE + FO_SHARED)
	
	If !File(cArquiv)
		Return('Arquivo não Localizado')
	EndIF
	
	FT_FUSE(cArquiv)
	FT_FGOTOP()
	nTotReg := FT_FRecNo()
	nMod:=0//Para pegar a primeira Tag Module
	Do While !FT_FEOF().and. nMod==0
		_cBuffer := FT_FREADLN()
		nMod:= AT("<Module>",_cBuffer)
		//Titulo Principal
		If nMod > 0
			cMod:= SubStr(_cBuffer,AT(">",_cBuffer)+1,AT("</",_cBuffer)-AT(">",_cBuffer)-1)
		EndIf
		
		FT_FSKIP()
	EndDo	
	Fclose(cArquiv) // Fecha arquivo
	If Empty(cMod)
		cMod:="Modulo não informados"
	EndIf 
Return(cMod)	

Static Function LMenCom(cArquiv)
***************************************
**
***************************************
	nHandle:= FOPEN(cArquiv) //, FO_READWRITE + FO_SHARED)
	
	FT_FUSE(cArquiv)
	FT_FGOTOP()
	nTotReg := FT_FRecNo()
	
	ProcRegua(nTotReg)
	
	Do While !FT_FEOF()
		
		_cBuffer := FT_FREADLN()
		//Titulo Principal
		If AT("<Menu",_cBuffer) == 2
			FT_FSKIP()
			_cBuffer := FT_FREADLN()
			If AT("pt",_cBuffer)>0
				cTituPai:= SubStr(_cBuffer,AT("pt",_cBuffer)+4,AT("</",_cBuffer)-AT(">",_cBuffer)-1)
			EndIf
		EndIf
		
		//SubTitulos
		If AT("<Menu",_cBuffer) == 3
			
			FT_FSKIP()
			_cBuffer := FT_FREADLN()
			
			If AT("pt",_cBuffer)>0
				cTitu:= SubStr(_cBuffer,AT("pt",_cBuffer)+4,AT("</",_cBuffer)-AT(">",_cBuffer)-1)
			EndIf
		EndIf
		
		If AllTrim(cTitu)<>AllTrim(cTituAnt)
			AADD(aTitulo,{cTitu,{}})
		EndIf
		
		cTituAnt:=cTitu
		
		If AT("<MenuItem",_cBuffer)>0
			FT_FSKIP()
			_cBuffer := FT_FREADLN()
			If AT("pt",_cBuffer)>0
				cNom:=SubStr(_cBuffer,AT("pt",_cBuffer)+4,AT("</",_cBuffer)-AT(">",_cBuffer)-1)
				AADD(cNome,{cNom,""})
			EndIf
			
		EndIf
		If AT("<Function>",_cBuffer)>0
			nPos:=AScan(cNome,{|x| alltrim(x[1]) == alltrim(cNom)} )
			If nPos > 0
				While AScan(cNome,{|x| alltrim(x[1]) == alltrim(cNom)},nPos+1,Len(cNome) ) > 0
					nPos:=AScan(cNome,{|x| alltrim(x[1]) == alltrim(cNom)},nPos+1,Len(cNome) )
				EndDo
				cNome[nPos,2]:=SubStr(_cBuffer,AT(">",_cBuffer)+1,AT("</",_cBuffer)-AT(">",_cBuffer)-1)
			EndIf
		EndIf
		
		If AT("</Menu",_cBuffer) == 3
			
			nPos:=AScan(aTitulo,{|x| alltrim(x[1]) == alltrim(cTituAnt)} )
			If nPos > 0
				While AScan(aTitulo,{|x| alltrim(x[1]) == alltrim(cTituAnt)},nPos+1,Len(aTitulo) ) > 0
					nPos:=AScan(aTitulo,{|x| alltrim(x[1]) == alltrim(cTituAnt)},nPos+1,Len(aTitulo) )
				EndDo
				aTitulo[nPos,2]:=cNome
				cNome:={}
				cNoRoti:={}
				aTiMen:={}
			EndIf
			
		EndIf
		
		If AllTrim(cTituPai)<>AllTrim(cTituPaiAnt)
			AAdd(aArquivo,{ cTituPai,"" })
			nPos:=AScan(aArquivo,{|x| alltrim(x[1]) == alltrim(cTituPaiAnt)} )
			If nPos > 0
				While AScan(aArquivo,{|x| alltrim(x[1]) == alltrim(cTituPaiAnt)},nPos+1,Len(aArquivo) ) > 0
					nPos:=AScan(aArquivo,{|x| alltrim(x[1]) == alltrim(cTituPaiAnt)},nPos+1,Len(aArquivo) )
				EndDo
				aArquivo[nPos,2]:=aTitulo
				aTitulo:={}
			EndIf
		EndIf
		cTituPaiAnt:=cTituPai
		FT_FSKIP()
	EndDo
	//Para alimento o ultimo registro
	nPos:=AScan(aArquivo,{|x| alltrim(x[1]) == alltrim(cTituPaiAnt)} )
	If nPos == Len(aArquivo)
		aArquivo[nPos,2]:=aTitulo
		aTitulo:={}
	EndIf

Return(cMod)	

