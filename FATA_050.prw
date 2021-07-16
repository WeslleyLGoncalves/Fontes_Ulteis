#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"
/*/{Protheus.doc} FATA_050
Funcao para realizar o execAuto da rotina FATA050
@type function
@version  P12
@author Weslley Goncalves
@since 15/07/2021
@return variant, return_description
/*/
User Function FATA_050()

	Local nOpc := 3
	Local oModel := Nil

	RpcSetType(3)
	RpcSetEnv("99","01")

	oModel := FWLoadModel('FATA050')

	oModel:SetOperation(nOpc)
	oModel:Activate()

	//Cabe�alho
	oModel:SetValue('SCTCAB','CT_DESCRI','TESTE_MVC')

	//Grid
	oModel:SetValue('SCTGRID','CT_SEQUEN'   ,"001")
	oModel:SetValue('SCTGRID','CT_DATA'     ,dDataBase)
	oModel:SetValue('SCTGRID','CT_VEND'     ,"000001")
	oModel:SetValue('SCTGRID','CT_REGIAO'   ,"003")
	oModel:SetValue('SCTGRID','CT_QUANT',999)
	oModel:SetValue('SCTGRID','CT_VALOR',600)

	//Nova linha na Grid
	oModel:GetModel("SCTGRID"):AddLine()

	oModel:SetValue('SCTGRID','CT_SEQUEN'     ,"002")
	oModel:SetValue('SCTGRID','CT_DATA'     ,dDataBase+1)
	oModel:SetValue('SCTGRID','CT_VEND'     ,"000001")
	oModel:SetValue('SCTGRID','CT_REGIAO'   ,"003")
	oModel:SetValue('SCTGRID','CT_QUANT',999)
	oModel:SetValue('SCTGRID','CT_VALOR',600)


	If oModel:VldData()
		oModel:CommitData()
	Else
		// Se os dados n�o foram validados obtemos a descri��o do erro para gerar LOG ou mensagem de aviso
		aErro := oModel:GetErrorMessage()
		// A estrutura do vetor com erro �:
		// [1] identificador (ID) do formul�rio de origem
		// [2] identificador (ID) do campo de origem
		// [3] identificador (ID) do formul�rio de erro
		// [4] identificador (ID) do campo de erro
		// [5] identificador (ID) do erro
		// [6] mensagem do erro
		// [7] mensagem da solu��o
		// [8] Valor atribu�do
		// [9] Valor anterior
		AutoGrLog( "Id do formul�rio de origem:" + ' [' + AllToChar( aErro[1] ) + ']' )
		AutoGrLog( "Id do campo de origem: " + ' [' + AllToChar( aErro[2] ) + ']' )
		AutoGrLog( "Id do formul�rio de erro: " + ' [' + AllToChar( aErro[3] ) + ']' )
		AutoGrLog( "Id do campo de erro: " + ' [' + AllToChar( aErro[4] ) + ']' )
		AutoGrLog( "Id do erro: " + ' [' + AllToChar( aErro[5] ) + ']' )
		AutoGrLog( "Mensagem do erro: " + ' [' + AllToChar( aErro[6] ) + ']' )
		AutoGrLog( "Mensagem da solu��o: " + ' [' + AllToChar( aErro[7] ) + ']' )
		AutoGrLog( "Valor atribu�do: " + ' [' + AllToChar( aErro[8] ) + ']' )
		AutoGrLog( "Valor anterior: " + ' [' + AllToChar( aErro[9] ) + ']' )
		MostraErro()
	EndIf


	oModel:DeActivate()

	oModel:Destroy()

	//Fecha Ambiente Atual ...
	RpcClearEnv()


Return
