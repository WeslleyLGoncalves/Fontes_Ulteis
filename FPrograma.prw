#Include 'Protheus.ch'

User Function FPrograma()
**************************
**                      **
**************************

//	RpcSetType(3) // muda o tipo de consumo de lincen�a
//	RpcSetEnv("01","01" )    //troca de empresa e de filial

//	oProcess := MsNewProcess():New({|| TsGetFuncArray() },"Aguarde...","Lendo ...",.T.)
	oProcess := MsNewProcess():New({|| FImpArq() },"Aguarde...","Lendo ...",.T.)
	oProcess:Activate()

Return

Static Function FImpArq()
*******************************
** Ler todos os arquivos prw **
*******************************
	Local nxi		:= 1
	Local aArqDir	:= {}
	Local aSubArq := {}
	Local lRet		:= .F.
	Local aDados	:=	{}
	Local nQtdReg	:= 0
	Local cDiretorio:= ""

	Local nPos  := 0
	Local aRet  :={}
	Local nCount
	Local aType :={}
	Local aFile :={}
	Local aLine :={}
	Local aDate :={}
	Local aTime :={}

	Private aFont :={}
	Private aArqDir:={}

// Para retornar a origem da fun��o: FULL, USER, PARTNER, PATCH, TEMPLATE ou NONELocal aType
// Para retornar o nome do arquivo onde foi declarada a fun��oLocal aFile
// Para retornar o n�mero da linha no arquivo onde foi declarada a fun��oLocal aLine
// Para retornar a data do c�digo fonte compiladoLocal aDate
// Para retornar a hora do c�digo fonte compiladoLocal aTime

	aRet := GetFuncArray('*', aType, aFile, aLine, aDate,aTime) // Buscar informa��es de todas as fun��es contidas no APO
/*GetFuncArray
	For nCount := 1 To Len(aRet)
		conout("Funcao "  + cValtoChar(nCount) + "= " + aRet[nCount])
		conout("Arquivo"  + cValtoChar(nCount) + "= " + aFile[nCount])
		conout("Linha "   + cValtoChar(nCount) + "= " + aLine[nCount])
		conout("Tipo "    + cValtoChar(nCount) + "= " + aType[nCount]) //USER
		conout("Data "    + cValtoChar(nCount) + "= " + DtoC(aDate[nCount]))
		conout("Hora "    + cValtoChar(nCount) + "= " + aTime[nCount])
	Next
*/
	oProcess:SetRegua1(Len(aRet))
	oProcess:SetRegua2(0)

	//Loop para buscara so fonte customisados
	For nCount := 1 To Len(aType)
		oProcess:IncRegua1("Funcao:  " + AllTrim(aRet[nCount]))

		If aType[nCount] == "USER"
			oProcess:IncRegua2("Arquivo:  " + AllTrim(aFile[nCount]))
                     // Funcao          Arquivo       Data          Hora
			AADD(aFont,{aRet[nCount],aFile[nCount],aDate[nCount],aTime[nCount]})

		EndIf
	Next

	cDiretorio := Upper("C:\Projeto\")
	aArqDir := DIRECTORY(alltrim(cDiretorio)+ "*.*","D")  // Recebe um array com todos os arquivos do diretorio
	nQtdReg := Len(aArqDir)	//Conta total e registros

	If Len(aFont)>0
		Relato()
	EndIf

Return

Static Function Relato()
	********************************************************************
	*  Fun�ao principal
	*************
	Private oReport
	Private oSection1

	oReport := TReport():New("Fonte_Repositorio","",,{|oReport| PrintReport()},"Fonte_Repositorio")

	Pergunte(oReport:GetParam(),.F.) //Retorna a pergunta ou bloco de c�digo utilizado como par�metros do relat�rio.
	oReport:SetEnvironment(2) //Define o ambiente para impress�o. Ambiente: 1-Server e 2-Cliente
	oReport:HideParamPage()   // Desabilita a impressao da pagina de parametros.
//	oReport:SetCustomText({||"__NOLINEBREAK__" }) //TESTE
	oSection1 := TRSection():New(oReport," ",)

	TRCell():New(oSection1,"_func","","Funcao","@!",20)
	TRCell():New(oSection1,"_arqui","","Arquivo","@!",20)
	TRCell():New(oSection1,"_dt",,"Data",,4)  //,"Emissao",,10)
	TRCell():New(oSection1,"_hora","","Hora","@!",20)

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

	//Define a mensagem apresentada durante a gera��o do relat�rio.
	oReport:SetMsgPrint("Lendo Registros")

	//Seta o contador da regua
	oReport:SetMeter(Len(aFont))

	For nI:=1 To Len(aFont)

		//Inicializa a Se��o
		oSection1:Init()
		oSection1:Cell("_func" ):SetBlock({|| aFont[nI,01] })
		oSection1:Cell("_arqui"):SetBlock({|| aFont[nI,02] })
		oSection1:Cell("_dt"   ):SetBlock({|| aFont[nI,03] })
		oSection1:Cell("_hora" ):SetBlock({|| aFont[nI,04] })

		oSection1:PrintLine()
		/*Incrementa a r�gua da tela de processamento do relat�rio*/
		oReport:IncMeter()

	Next nI
		/*Finaliza se��o inicializada pelo m�todo Init.*/
//		oSection2:Finish()
		/*Finaliza se��o inicializada pelo m�todo Init.*/
		oSection1:Finish()
		/*Incrementa a r�gua da tela de processamento do relat�rio*/
		oReport:IncMeter()

Return