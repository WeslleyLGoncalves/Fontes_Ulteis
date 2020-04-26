#Include "TopConn.ch"
#INCLUDE "PROTHEUS.CH"

#DEFINE SIMPLES Char( 39 )
#DEFINE DUPLAS  Char( 34 )

#DEFINE CSSBOTAO	"QPushButton { color: #024670; "+;
	"    border-image: url(rpo:fwstd_btn_nml.png) 3 3 3 3 stretch; "+;
	"    border-top-width: 3px; "+;
	"    border-left-width: 3px; "+;
	"    border-right-width: 3px; "+;
	"    border-bottom-width: 3px }"+;
	"QPushButton:pressed {	color: #FFFFFF; "+;
	"    border-image: url(rpo:fwstd_btn_prd.png) 3 3 3 3 stretch; "+;
	"    border-top-width: 3px; "+;
	"    border-left-width: 3px; "+;
	"    border-right-width: 3px; "+;
	"    border-bottom-width: 3px }"

/*
+-----------+------------+----------------+-------------------+-------+---------------+
| Programa  | DUCONPAD   | Desenvolvedor  | WESLLEY GONCALVES | Data  | 29.08.2017    |
+-----------+------------+----------------+-------------------+-------+---------------+
| Descricao | Programa de atualiza consulta padr�o de dicionarios diferentes          |
+-----------+-------------------------------------------------------------------------+
| Modulos   | SIGACFG                                                                 |
+-----------+-------------------------------------------------------------------------+
| Processos |                                                                         |
+---------- +-------------+-----------------------------------------------------------+
| DATA      | PROGRAMADOR | MOTIVO                                                    |
+-----------+-------------+-----------------------------------------------------------+
*/
User Function DUCONPAD( cEmpAmb, cFilAmb )
	************************
	*  Fun�ao principal	  *
	************************
	Local   aSay      := {}
	Local   aButton   := {}
	Local   aMarcadas := {}
	Local   cTitulo   := "ATUALIZA��O DE DICION�RIOS E TABELAS"
	Local   cDesc1    := "Esta rotina tem como fun��o fazer  a atualiza��o  dos dicion�rios do Sistema "
	Local   cDesc2    := "Este processo deve ser executado em modo EXCLUSIVO, ou seja n�o podem haver outros"
	Local   cDesc3    := "usu�rios  ou  jobs utilizando  o sistema.  � EXTREMAMENTE recomendav�l  que  se  fa�a um"
	Local   cDesc4    := "BACKUP  dos DICION�RIOS  e da  BASE DE DADOS antes desta atualiza��o, para que caso "
	Local   cDesc5    := "ocorram eventuais falhas, esse backup possa ser restaurado."
	Local   cDesc6    := ""
	Local   cDesc7    := ""
	Local   lOk       := .F.
	Local   lAuto     := ( cEmpAmb <> NIL .or. cFilAmb <> NIL )
	
	Private oMainWnd  := NIL
	Private oProcess  := NIL
	
	#IFDEF TOP
		TCInternal( 5, "*OFF" ) // Desliga Refresh no Lock do Top
	#ENDIF
	
	__cInterNet := NIL
	__lPYME     := .F.
	
	Set Dele On
	
	// Mensagens de Tela Inicial
	aAdd( aSay, cDesc1 )
	aAdd( aSay, cDesc2 )
	aAdd( aSay, cDesc3 )
	aAdd( aSay, cDesc4 )
	aAdd( aSay, cDesc5 )
	//aAdd( aSay, cDesc6 )
	//aAdd( aSay, cDesc7 )
	
	// Botoes Tela Inicial
	aAdd(  aButton, {  1, .T., { || lOk := .T., FechaBatch() } } )
	aAdd(  aButton, {  2, .T., { || lOk := .F., FechaBatch() } } )
	
	If lAuto
		lOk := .T.
	Else
		FormBatch(  cTitulo,  aSay,  aButton )
	EndIf
	
	If lOk
		If lAuto
			aMarcadas :={{ cEmpAmb, cFilAmb, "" }}
		Else
			aMarcadas := EscEmpresa()
		EndIf
		
		If !Empty( aMarcadas )
			If lAuto .OR. MsgNoYes( "Confirma a atualiza��o dos dicion�rios ?", cTitulo )
				oProcess := MsNewProcess():New( { | lEnd | lOk := FSTProc( @lEnd, aMarcadas, lAuto ) }, "Atualizando", "Aguarde, atualizando ...", .F. )
				oProcess:Activate()
				
				If lAuto
					If lOk
						MsgStop( "Atualiza��o Realizada.", "DUCONPAD" )
					Else
						MsgStop( "Atualiza��o n�o Realizada.", "DUCONPAD" )
					EndIf
					dbCloseAll()
				Else
					If lOk
						Final( "Atualiza��o Conclu�da." )
					Else
						Final( "Atualiza��o n�o Realizada." )
					EndIf
				EndIf
				
			Else
				MsgStop( "Atualiza��o n�o Realizada.", "DUCONPAD" )
				
			EndIf
			
		Else
			MsgStop( "Atualiza��o n�o Realizada.", "DUCONPAD" )
			
		EndIf
		
	EndIf
	
Return NIL

Static Function FSTProc( lEnd, aMarcadas, lAuto )
	Local   aInfo     := {}
	Local   aRecnoSM0 := {}
	Local   cAux      := ""
	Local   cFile     := ""
	Local   cFileLog  := ""
	Local   cMask     := "Arquivos Texto" + "(*.TXT)|*.txt|"
	Local   cTCBuild  := "TCGetBuild"
	Local   cTexto    := ""
	Local   cTopBuild := ""
	Local   lOpen     := .F.
	Local   lRet      := .T.
	Local   nI        := 0
	Local   nPos      := 0
	Local   nRecno    := 0
	Local   nX        := 0
	Local   oDlg      := NIL
	Local   oFont     := NIL
	Local   oMemo     := NIL
	
	Private aArqUpd   := {}
	
	If ( lOpen := MyOpenSm0(.T.) )
		
		dbSelectArea( "SM0" )
		dbGoTop()
		
		While !SM0->( EOF() )
			// S� adiciona no aRecnoSM0 se a empresa for diferente
			If aScan( aRecnoSM0, { |x| x[2] == SM0->M0_CODIGO } ) == 0 ;
					.AND. aScan( aMarcadas, { |x| x[1] == SM0->M0_CODIGO } ) > 0
				aAdd( aRecnoSM0, { Recno(), SM0->M0_CODIGO } )
			EndIf
			SM0->( dbSkip() )
		End
		
		SM0->( dbCloseArea() )
		
		If lOpen
			
			For nI := 1 To Len( aRecnoSM0 )
				
				If !( lOpen := MyOpenSm0(.F.) )
					MsgStop( "Atualiza��o da empresa " + aRecnoSM0[nI][2] + " n�o efetuada." )
					Exit
				EndIf
				
				SM0->( dbGoTo( aRecnoSM0[nI][1] ) )
				
				RpcSetType( 3 )
				RpcSetEnv( SM0->M0_CODIGO, SM0->M0_CODFIL )
				
				lMsFinalAuto := .F.
				lMsHelpAuto  := .F.
				
				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( Replicate( " ", 128 ) )
				AutoGrLog( "LOG DA ATUALIZA��O DOS DICION�RIOS" )
				AutoGrLog( Replicate( " ", 128 ) )
				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( " " )
				AutoGrLog( " Dados Ambiente" )
				AutoGrLog( " --------------------" )
				AutoGrLog( " Empresa / Filial...: " + cEmpAnt + "/" + cFilAnt )
				AutoGrLog( " Nome Empresa.......: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_NOMECOM", cEmpAnt + cFilAnt, 1, "" ) ) ) )
				AutoGrLog( " Nome Filial........: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_FILIAL" , cEmpAnt + cFilAnt, 1, "" ) ) ) )
				AutoGrLog( " DataBase...........: " + DtoC( dDataBase ) )
				AutoGrLog( " Data / Hora �nicio.: " + DtoC( Date() )  + " / " + Time() )
				AutoGrLog( " Environment........: " + GetEnvServer()  )
				AutoGrLog( " StartPath..........: " + GetSrvProfString( "StartPath", "" ) )
				AutoGrLog( " RootPath...........: " + GetSrvProfString( "RootPath" , "" ) )
				AutoGrLog( " Vers�o.............: " + GetVersao(.T.) )
				AutoGrLog( " Usu�rio TOTVS .....: " + __cUserId + " " +  cUserName )
				AutoGrLog( " Computer Name......: " + GetComputerName() )
				
				aInfo   := GetUserInfo()
				If ( nPos    := aScan( aInfo,{ |x,y| x[3] == ThreadId() } ) ) > 0
					AutoGrLog( " " )
					AutoGrLog( " Dados Thread" )
					AutoGrLog( " --------------------" )
					AutoGrLog( " Usu�rio da Rede....: " + aInfo[nPos][1] )
					AutoGrLog( " Esta��o............: " + aInfo[nPos][2] )
					AutoGrLog( " Programa Inicial...: " + aInfo[nPos][5] )
					AutoGrLog( " Environment........: " + aInfo[nPos][6] )
					AutoGrLog( " Conex�o............: " + AllTrim( StrTran( StrTran( aInfo[nPos][7], Chr( 13 ), "" ), Chr( 10 ), "" ) ) )
				EndIf
				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( " " )
				
				If !lAuto
					AutoGrLog( Replicate( "-", 128 ) )
					AutoGrLog( "Empresa : " + SM0->M0_CODIGO + "/" + SM0->M0_NOME + CRLF )
				EndIf
				
				oProcess:SetRegua1( 8 )
				
				//------------------------------------
				// Atualiza o dicion�rio
				//------------------------------------
				oProcess:IncRegua1( "Dicion�rio de arquivos" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				LerArqui()
				
				oProcess:IncRegua1( "Dicion�rio de dados" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				oProcess:IncRegua2( "" )
				
				// Altera��o f�sica dos arquivos
				__SetX31Mode( .F. )
				
				If FindFunction(cTCBuild)
					cTopBuild := &cTCBuild.()
				EndIf
				
				For nX := 1 To Len( aArqUpd )
					
					If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
						If ( ( aArqUpd[nX] >= "NQ " .AND. aArqUpd[nX] <= "NZZ" ) .OR. ( aArqUpd[nX] >= "O0 " .AND. aArqUpd[nX] <= "NZZ" ) ) .AND.;
								!aArqUpd[nX] $ "NQD,NQF,NQP,NQT"
							TcInternal( 25, "CLOB" )
						EndIf
					EndIf
					
					If Select( aArqUpd[nX] ) > 0
						dbSelectArea( aArqUpd[nX] )
						dbCloseArea()
					EndIf
					
					X31UpdTable( aArqUpd[nX] )
					
					If __GetX31Error()
						Alert( __GetX31Trace() )
						MsgStop( "Ocorreu um erro desconhecido durante a atualiza��o da tabela : " + aArqUpd[nX] + ". Verifique a integridade do dicion�rio e da tabela.", "ATEN��O" )
						AutoGrLog( "Ocorreu um erro desconhecido durante a atualiza��o da estrutura da tabela : " + aArqUpd[nX] )
					EndIf
					
					If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
						TcInternal( 25, "OFF" )
					EndIf
					
				Next nX
				
				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( " Data / Hora Final.: " + DtoC( Date() ) + " / " + Time() )
				AutoGrLog( Replicate( "-", 128 ) )
				
				RpcClearEnv()
				
			Next nI
			
			If !lAuto
				
				cTexto := "Finalizado para todas empresas selecionadas"
				
				Define Font oFont Name "Mono AS" Size 5, 12
				
				Define MsDialog oDlg Title "Atualiza��o concluida." From 3, 0 to 340, 417 Pixel
				
				@ 5, 5 Get oMemo Var cTexto Memo Size 200, 145 Of oDlg Pixel
				oMemo:bRClicked := { || AllwaysTrue() }
				oMemo:oFont     := oFont
				
				Define SButton From 153, 175 Type  1 Action oDlg:End() Enable Of oDlg Pixel // Apaga
				Define SButton From 153, 145 Type 13 Action ( cFile := cGetFile( cMask, "" ), If( cFile == "", .T., ;
					MemoWrite( cFile, cTexto ) ) ) Enable Of oDlg Pixel
				
				Activate MsDialog oDlg Center
				
			EndIf
			
		EndIf
		
	Else
		
		lRet := .F.
		
	EndIf
	
Return lRet


Static Function LerArqui()
	**************************
	*                        *
	**************************
	//Este exemplo, apresenta como o DBF corrente pode ser exibido para o usu�rio.
	//DBUseArea( .T.,"dbfcdxads", "\dadosadv609\sa1990.dbf","SSS",.T., .F. )DRIVE CTREE - CTREECDX
	
	//	Local cCami:='\wg\Tabela\SB1\sb10101.dbf'
	Local cCami:='\wg\X3_OFI\sx3'+SM0->M0_CODIGO+'01.dtc'
	
	DBUseArea( .T.,"CTREECDX", cCami,"SSS",.T., .F. )
	//	DBUseArea( .T.,"DBFCDX", cCami,"SSS",.T., .F. ) //dbfcdxads  CTREECDX
	
	//	RetArq( <cDriver>, <cArquivo>, <lDbf> )
	
	oProcess:SetRegua1(0)
	oProcess:SetRegua2(0)
	dbSelectArea("SSS")
	dbGoTop()
	I:= 0
	Do While !(EOF())
		
		oProcess:IncRegua1("Empresa: "+SM0->M0_CODIGO+ " - Campo :  " + AllTrim(SSS->(X3_CAMPO)))
		
		dbSelectArea("SX3")
		dbSetOrder(2)// X3_CAMPO
		If dbSeek(SSS->(X3_CAMPO))
			//			oProcess:IncRegua2(STRZERO(I++) )
			oProcess:IncRegua2(I++)
			
			If !AllTrim(SX3->X3_F3) == AllTrim(SSS->X3_F3)
				
				If RecLock('SX3', .F.)
					
					SX3->X3_F3 := SSS->X3_F3
					
					MsUnlock()
				EndIf
			EndIf
			
			If SX3->X3_ARQUIVO = 'SC5' .and. cEmpAnt $ '03_04'
				If RecLock('SX3', .F.)
					
					SX3->X3_BROWSE := SSS->X3_BROWSE
					
					MsUnlock()
				EndIf
			EndIf
		EndIf
		
		dbSelectArea("SSS")
		SSS->(dbSkip())
		
	EndDo
	
Return

//--------------------------------------------------------------------
Static Function EscEmpresa()
	
	//---------------------------------------------
	// Par�metro  nTipo
	// 1 - Monta com Todas Empresas/Filiais
	// 2 - Monta s� com Empresas
	// 3 - Monta s� com Filiais de uma Empresa
	//
	// Par�metro  aMarcadas
	// Vetor com Empresas/Filiais pr� marcadas
	//
	// Par�metro  cEmpSel
	// Empresa que ser� usada para montar sele��o
	//---------------------------------------------
	Local   aRet      := {}
	Local   aSalvAmb  := GetArea()
	Local   aSalvSM0  := {}
	Local   aVetor    := {}
	Local   cMascEmp  := "??"
	Local   cVar      := ""
	Local   lChk      := .F.
	Local   lOk       := .F.
	Local   lTeveMarc := .F.
	Local   oNo       := LoadBitmap( GetResources(), "LBNO" )
	Local   oOk       := LoadBitmap( GetResources(), "LBOK" )
	Local   oDlg, oChkMar, oLbx, oMascEmp, oSay
	Local   oButDMar, oButInv, oButMarc, oButOk, oButCanc
	
	Local   aMarcadas := {}
	
	
	If !MyOpenSm0(.F.)
		Return aRet
	EndIf
	
	
	dbSelectArea( "SM0" )
	aSalvSM0 := SM0->( GetArea() )
	dbSetOrder( 1 )
	dbGoTop()
	
	While !SM0->( EOF() )
		
		If aScan( aVetor, {|x| x[2] == SM0->M0_CODIGO} ) == 0
			aAdd(  aVetor, { aScan( aMarcadas, {|x| x[1] == SM0->M0_CODIGO .and. x[2] == SM0->M0_CODFIL} ) > 0, SM0->M0_CODIGO, SM0->M0_CODFIL, SM0->M0_NOME, SM0->M0_FILIAL } )
		EndIf
		
		dbSkip()
	End
	
	RestArea( aSalvSM0 )
	
	Define MSDialog  oDlg Title "" From 0, 0 To 280, 395 Pixel
	
	oDlg:cToolTip := "Tela para M�ltiplas Sele��es de Empresas/Filiais"
	
	oDlg:cTitle   := "Selecione a(s) Empresa(s) para Atualiza��o"
	
	@ 10, 10 Listbox  oLbx Var  cVar Fields Header " ", " ", "Empresa" Size 178, 095 Of oDlg Pixel
	oLbx:SetArray(  aVetor )
	oLbx:bLine := {|| {IIf( aVetor[oLbx:nAt, 1], oOk, oNo ), ;
		aVetor[oLbx:nAt, 2], ;
		aVetor[oLbx:nAt, 4]}}
	oLbx:BlDblClick := { || aVetor[oLbx:nAt, 1] := !aVetor[oLbx:nAt, 1], VerTodos( aVetor, @lChk, oChkMar ), oChkMar:Refresh(), oLbx:Refresh()}
	oLbx:cToolTip   :=  oDlg:cTitle
	oLbx:lHScroll   := .F. // NoScroll
	
	@ 112, 10 CheckBox oChkMar Var  lChk Prompt "Todos" Message "Marca / Desmarca"+ CRLF + "Todos" Size 40, 007 Pixel Of oDlg;
		on Click MarcaTodos( lChk, @aVetor, oLbx )
	
	// Marca/Desmarca por mascara
	@ 113, 51 Say   oSay Prompt "Empresa" Size  40, 08 Of oDlg Pixel
	@ 112, 80 MSGet oMascEmp Var  cMascEmp Size  05, 05 Pixel Picture "@!"  Valid (  cMascEmp := StrTran( cMascEmp, " ", "?" ), oMascEmp:Refresh(), .T. ) ;
		Message "M�scara Empresa ( ?? )"  Of oDlg
	oSay:cToolTip := oMascEmp:cToolTip
	
	@ 128, 10 Button oButInv    Prompt "&Inverter"  Size 32, 12 Pixel Action ( InvSelecao( @aVetor, oLbx, @lChk, oChkMar ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
		Message "Inverter Sele��o" Of oDlg
	oButInv:SetCss( CSSBOTAO )
	@ 128, 50 Button oButMarc   Prompt "&Marcar"    Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .T. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
		Message "Marcar usando" + CRLF + "m�scara ( ?? )"    Of oDlg
	oButMarc:SetCss( CSSBOTAO )
	@ 128, 80 Button oButDMar   Prompt "&Desmarcar" Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .F. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
		Message "Desmarcar usando" + CRLF + "m�scara ( ?? )" Of oDlg
	oButDMar:SetCss( CSSBOTAO )
	@ 112, 157  Button oButOk   Prompt "Processar"  Size 32, 12 Pixel Action (  RetSelecao( @aRet, aVetor ), oDlg:End()  ) ;
		Message "Confirma a sele��o e efetua" + CRLF + "o processamento" Of oDlg
	oButOk:SetCss( CSSBOTAO )
	@ 128, 157  Button oButCanc Prompt "Cancelar"   Size 32, 12 Pixel Action ( IIf( lTeveMarc, aRet :=  aMarcadas, .T. ), oDlg:End() ) ;
		Message "Cancela o processamento" + CRLF + "e abandona a aplica��o" Of oDlg
	oButCanc:SetCss( CSSBOTAO )
	
	Activate MSDialog  oDlg Center
	
	RestArea( aSalvAmb )
	dbSelectArea( "SM0" )
	dbCloseArea()
	
Return  aRet

Static Function MarcaTodos( lMarca, aVetor, oLbx )
	Local  nI := 0
	
	For nI := 1 To Len( aVetor )
		aVetor[nI][1] := lMarca
	Next nI
	
	oLbx:Refresh()
	
Return NIL

Static Function InvSelecao( aVetor, oLbx )
	Local  nI := 0
	
	For nI := 1 To Len( aVetor )
		aVetor[nI][1] := !aVetor[nI][1]
	Next nI
	
	oLbx:Refresh()
	
Return NIL

Static Function RetSelecao( aRet, aVetor )
	Local  nI    := 0
	
	aRet := {}
	For nI := 1 To Len( aVetor )
		If aVetor[nI][1]
			aAdd( aRet, { aVetor[nI][2] , aVetor[nI][3], aVetor[nI][2] +  aVetor[nI][3] } )
		EndIf
	Next nI
	
Return NIL

Static Function MarcaMas( oLbx, aVetor, cMascEmp, lMarDes )
	Local cPos1 := SubStr( cMascEmp, 1, 1 )
	Local cPos2 := SubStr( cMascEmp, 2, 1 )
	Local nPos  := oLbx:nAt
	Local nZ    := 0
	
	For nZ := 1 To Len( aVetor )
		If cPos1 == "?" .or. SubStr( aVetor[nZ][2], 1, 1 ) == cPos1
			If cPos2 == "?" .or. SubStr( aVetor[nZ][2], 2, 1 ) == cPos2
				aVetor[nZ][1] := lMarDes
			EndIf
		EndIf
	Next
	
	oLbx:nAt := nPos
	oLbx:Refresh()
	
Return NIL

Static Function VerTodos( aVetor, lChk, oChkMar )
	Local lTTrue := .T.
	Local nI     := 0
	
	For nI := 1 To Len( aVetor )
		lTTrue := IIf( !aVetor[nI][1], .F., lTTrue )
	Next nI
	
	lChk := IIf( lTTrue, .T., .F. )
	oChkMar:Refresh()
	
Return NIL

Static Function MyOpenSM0(lShared)
	
	Local lOpen := .F.
	Local nLoop := 0
	
	For nLoop := 1 To 20
		dbUseArea( .T., , "SIGAMAT.EMP", "SM0", lShared, .F. )
		
		If !Empty( Select( "SM0" ) )
			lOpen := .T.
			dbSetIndex( "SIGAMAT.IND" )
			Exit
		EndIf
		
		Sleep( 500 )
		
	Next nLoop
	
	If !lOpen
		MsgStop( "N�o foi poss�vel a abertura da tabela " + ;
			IIf( lShared, "de empresas (SM0).", "de empresas (SM0) de forma exclusiva." ), "ATEN��O" )
	EndIf
	
Return lOpen
