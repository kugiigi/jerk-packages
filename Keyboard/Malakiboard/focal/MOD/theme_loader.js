.import "keys/key_constants.js" as UI
        
var defaultTheme = {
			"fontColor": UI.fontColor,
			"selectionColor": UI.selectionColor,
			"backgroundColor": UI.backgroundColor,
			"dividerColor": UI.dividerColor,
			"annotationFontColor": UI.annotationFontColor,
			"charKeyColor": UI.charKeyColor,
			"charKeyPressedColor": UI.charKeyPressedColor,
			"actionKeyColor": UI.actionKeyColor,
			"actionKeyPressedColor": UI.actionKeyPressedColor,
			"toolkitTheme": UI.toolbarTheme,
			"popupBorderColor": UI.popupBorderColor,
			"keyBorderEnabled": UI.keyBorderEnabled,
			"charKeyBorderColor": UI.charKeyBorderColor,
			"actionKeyBorderColor": UI.actionKeyBorderColor
		}

var load = function (jsonName){
	// ENH082 - Custom theme
    if (jsonName.startsWith(fullScreenItem.customThemeCode)) {
        let _obj = fullScreenItem.findFromArray(fullScreenItem.settings.customThemes, "name", jsonName)
        if (_obj) {
            fullScreenItem.theme = Object.assign({}, _obj)
        }
	} else if (jsonName == "CustomLight") {
		fullScreenItem.theme = Object.assign({}, fullScreenItem.settings.customLightTheme)
	} else if (jsonName == "CustomDark") {
		fullScreenItem.theme = Object.assign({}, fullScreenItem.settings.customDarkTheme)
	} else {
		var xhr = new XMLHttpRequest();

		xhr.onreadystatechange = function() {
			if (xhr.readyState == 4) {
				if (xhr.status == 200) {
					if (!fullScreenItem.useCustomTheme) {
						var currentTheme = fullScreenItem.theme
						var newTheme = JSON.parse(xhr.responseText)
						
						for (var key in newTheme) {
							if (currentTheme.hasOwnProperty(key)) {
								currentTheme[key] = newTheme[key]
							}
						}
						fullScreenItem.theme = currentTheme
						console.log('successfully fetched theme');
					}
				}
				else {
					console.log('failed to fetch theme');
				}
			}
		};

		xhr.open('GET', "styles/lomiri/themes/" + jsonName + ".json", true);
		xhr.send();
	}
	// ENH082 - End
}
