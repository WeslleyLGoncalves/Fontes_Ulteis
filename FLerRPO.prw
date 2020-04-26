#Include 'Protheus.ch'
User Function FLerRPO()
**************************
** Funcao principal     **
**************************

	Local nxi		:= 1
	Local aArqDir	:= {}
	Local aSubArq := {}
	Local lRet		:= .F.
	Local aDados	:=	{}

	Private aFont :={}
	Private aArqDir:={}
	Private oReport
	Private oSection1
	Private cPerg := "PergArqu"

	AjustaSx1()
	oReport := TReport():New("Fonte_Repositorio","Fonte_Repositorio",cPerg,{|oReport| PrintReport()},"Fonte_Repositorio")

	Pergunte(oReport:GetParam(),.F.) //Retorna a pergunta ou bloco de c�digo utilizado como par�metros do relat�rio.
	oReport:SetEnvironment(2)        //Define o ambiente para impress�o. Ambiente: 1-Server e 2-Cliente
	oReport:HideParamPage()          // Desabilita a impressao da pagina de parametros.

	oSection1 := TRSection():New(oReport," ",)

	TRCell():New(oSection1,"_arqui","","Arquivo","@!",20)
	TRCell():New(oSection1,"_dt",,"Data",,4)  //,"Emissao",,10)
	TRCell():New(oSection1,"_hora","","Hora","@!",20)
	TRCell():New(oSection1,"_rpo","","RPO","@!",20)
	TRCell():New(oSection1,"_rpDt","","Data_RPO","@!",20)
	TRCell():New(oSection1,"_rpTm","","Hora_RPO","@!",20)
	TRCell():New(oSection1,"_tipo","","Arquivo/RPO","@!",20)

	oSection1:AutoSize()
	//o Objeto oReport faz a chamada da Janela de Dialogo da Impre��o
	oReport:PrintDialog()

Return()

Static Function PrintReport()
	*************************************************
	*  Seleciona os titulos marcados pelo usuario.	*
	*************************************************

	Local oSection1  := oReport:Section(1)
	Local nReg:=0
	Local aSect1:={}
	Local cDiretorio:= ""
	Local nQtdReg	:= 0
	Local cAchou  := 0
	Local aRet  :={}
	Local nCount
	Local aType :={}
	Local aFile :={}
	Local aLine :={}
	Local aDate :={}
	Local aTime :={}
	Local dDt   := SToD("  /  /    ")
	Local cTm   := ""
	Local nCol  := 0
	Local nSmaCo:= 0

// Para retornar a origem da fun��o: FULL, USER, PARTNER, PATCH, TEMPLATE ou NONELocal aType
// Para retornar o nome do arquivo onde foi declarada a fun��oLocal aFile
// Para retornar o n�mero da linha no arquivo onde foi declarada a fun��oLocal aLine
// Para retornar a data do c�digo fonte compiladoLocal aDate
// Para retornar a hora do c�digo fonte compiladoLocal aTime
	aRet := GetFuncArray('*', aType, aFile, aLine, aDate,aTime) // Buscar informa��es de todas as fun��es contidas no APO

	cArquiv := MV_PAR01

	If !File(cArquiv)
		Alert("Arquivo n�o foi encontrado")
		Return()
	EndIF

	cDiretorio:= Upper(cArquiv)

	While At('\',cArquiv)>0
		nCol:= At('\',cArquiv)
		cArquiv:= SubStr(cArquiv,nCol+1)
		nSmaCo:=nSmaCo+nCol
	EndDo

	cDiretorio:= Upper(SubStr(cDiretorio,0,nSmaCo ))

	aArqDir   := DIRECTORY(alltrim(cDiretorio)+ "*.*")//,"D")  // Recebe um array com todos os arquivos do diretorio
	nQtdReg   := Len(aArqDir)	//Conta total e registros

	//Define a mensagem apresentada durante a gera��o do relat�rio.
	oReport:SetMsgPrint("Lendo Registros")

	//Seta o contador da regua
	oReport:SetMeter(Len(aFont))

	For nI:=1 To Len(aArqDir)

		nCount:=aScan(aFile,{|X| AllTrim(X)== Alltrim(aArqDir[nI,1]) })

		If nCount > 0
			dDt:= aDate[nCount]
			cTm:= aTime[nCount]
			cAchou:= "Sim"
		Else
			dDt   := SToD("  /  /    ")
			cTm   := ""
			cAchou:="N�o"
		EndIf

		//Inicializa a Se��o
		oSection1:Init()
		oSection1:Cell("_arqui"):SetBlock({|| aArqDir[nI,1] })
		oSection1:Cell("_dt"   ):SetBlock({|| aArqDir[nI,3] })
		oSection1:Cell("_hora" ):SetBlock({|| aArqDir[nI,4] })
		oSection1:Cell("_rpo"  ):SetBlock({|| cAchou })
		oSection1:Cell("_rpDt" ):SetBlock({|| dDt })
		oSection1:Cell("_rpTm" ):SetBlock({|| cTm })
		oSection1:Cell("_tipo" ):SetBlock({|| IIF(aArqDir[nI,3]==dDt,"OK","� OK" ) })

		oSection1:PrintLine()
		/*Incrementa a r�gua da tela de processamento do relat�rio*/
		oReport:IncMeter()

	Next nI
		/*Finaliza se��o inicializada pelo m�todo Init.*/
		oSection1:Finish()
		/*Incrementa a r�gua da tela de processamento do relat�rio*/
		oReport:IncMeter()

Return

User Function FBusFil()
***********************
** Fun��o para chamar

	MV_PAR01 := cGetFile("Arquivos PRW|*.PRW",OemToAnsi("Abrir Arquivo..."),,,.T.,GETF_NETWORKDRIVE + GETF_LOCALFLOPPY + GETF_LOCALHARD )

Return

Static function AjustaSx1()

	//Aqui utilizo a fun��o putSx1, ela cria a pergunta na tabela de perguntas
	PutSx1(cPerg, "01", "Arquivo"	  , "", "", "MV_CH1", "C", 40, 0, 0, "G", "U_FBusFil()", "", "", "", "MV_PAR01")

return
