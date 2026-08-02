.pragma library
'use strict';

function elideText(inputText, charLimit) {
    let elideString = "..."
    charLimit = charLimit ? charLimit : 20
    let returnValue = inputText

    if (returnValue.length > charLimit) {
        returnValue = returnValue.substring(0, charLimit) + elideString
    }

    return returnValue
}

function elideMidText(inputText, charLimit) {
    let elideString = "..."
    charLimit = charLimit ? charLimit : 20
    let returnValue = inputText

    if (returnValue.length > charLimit) {
        let sideCharLimit = Math.floor((charLimit - elideString.length) / 2)
        let extraFirstChar = (charLimit - elideString.length) % 2
        let firstChars = returnValue.substring(0, sideCharLimit + extraFirstChar)
        let lastChars = returnValue.substring(returnValue.length - sideCharLimit)
        returnValue = firstChars + elideString + lastChars
    }

    return returnValue
}

function bulletText(inputText, customBullet) {
    let bulletChar = customBullet ? customBullet : "•"

    return "%1 %2".arg(bulletChar).arg(inputText)
}

function bulletTextArray(inputTextArray, customBullet) {
    let bulletChar = customBullet ? customBullet : "•"

    return bulletText(inputTextArray.join("%1%2 ".arg("\n").arg(bulletChar)), customBullet)
}

// Search urls
function escapeHtmlEntities(query) {
    return query.replace(/\W/g, encodeURIComponent)
}

function buildSearchUrl(query, template) {
    var terms = query.split(/\s/).map(escapeHtmlEntities)
    return template.replace("{searchTerms}", terms.join("+"))
}
