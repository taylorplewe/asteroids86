local function validateAndShowErrorDialog(validations, errorDialogHeaderText)
	local errorLines = {}
	for errorText, invalidCheck in pairs(validations) do
		if invalidCheck() then
			table.insert(errorLines, '- ' .. errorText)
		end
	end
	if #errorLines > 0 then
		table.insert(errorLines, 1, errorDialogHeaderText)
		app.alert{ title='ERROR - Export Bitplane', text=errorLines }
		return false
	end
	return true
end

if not function()
	local validations = {
		['Sprite must be of color mode "Indexed".'] = function() return app.sprite.colorMode ~= ColorMode.INDEXED end,
	}
	return validateAndShowErrorDialog(validations, 'The script cannot continue due to the following reasons:')
end then return end

ExportDlg = Dialog('Export Bitplane')
	:file{
		id='outFile',
		label='Out file (.bin):',
		save=true,
		title='Out file (.bin)',
		filetypes={'bin'},
	}
	:button{
		id='exportBtn',
		text='Export',
		onclick=Export
	}
	:button{ text='Cancel', }
	:show{ wait=false } -- TODO might be able to not wait=false

function Export()
	local outFileName = ExportDlg.data.outFile
	local outFile = io.open(ExportDlg.data.outFile, "wb")
	if not outFile then
		app.alert{ title='File open error', text={ 'Could not open file:', '', outFileName, '' } }
		return
	end

	-- write to output file
	outFile:write(string.pack("<i4", app.sprite.width))
	outFile:write(string.pack("<i4", app.sprite.height))

	local img = Image(app.sprite.spec)
	img:drawImage(app.cel.image, app.cel.position)

	local b = 0
	local bInd = 0
	for px in img:pixels() do
		if px() ~= 0 then
			b = b | (1 << bInd)
		end

		bInd = bInd + 1
		
		if bInd == 8 then
			outFile:write(string.char(b))
			bInd = 0
			b = 0
		end
	end

	outFile:close()

	app.alert{ title='Export Success', text={ 'Bitplane written to:', '', outFileName, '' } }
	ExportDlg:close()
end