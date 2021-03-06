{DraftStoreExtension} = require 'nylas-exports'

class TemplatesDraftStoreExtension extends DraftStoreExtension

  @warningsForSending: (draft) ->
    warnings = []
    if draft.body.search(/<code[^>]*empty[^>]*>/i) > 0
      warnings.push("with an empty template area")
    warnings

  @finalizeSessionBeforeSending: (session) ->
    body = session.draft().body
    clean = body.replace(/<\/?code[^>]*>/g, '')
    if body != clean
      session.changes.add(body: clean)

  @onMouseUp: (editableNode, range, event) ->
    parent = range.startContainer?.parentNode
    parentCodeNode = null

    while parent and parent isnt editableNode
      if parent.classList?.contains('var') and parent.tagName is 'CODE'
        parentCodeNode = parent
        break
      parent = parent.parentNode

    isSinglePoint = range.startContainer is range.endContainer and range.startOffset is range.endOffset

    if isSinglePoint and parentCodeNode
      range.selectNode(parentCodeNode)
      selection = document.getSelection()
      selection.removeAllRanges()
      selection.addRange(range)

  @onTabDown: (editableNode, range, event) ->
    if event.shiftKey
      @onTabSelectNextVar(editableNode, range, event, -1)
    else
      @onTabSelectNextVar(editableNode, range, event, 1)

  @onTabSelectNextVar: (editableNode, range, event, delta) ->
    return unless range

    # Try to find the node that the selection range is
    # currently intersecting with (inside, or around)
    parentCodeNode = null
    nodes = editableNode.querySelectorAll('code.var')
    for node in nodes
      if range.intersectsNode(node)
        parentCodeNode = node

    if parentCodeNode
      if range.startOffset is range.endOffset and parentCodeNode.classList.contains('empty')
        # If the current node is empty and it's a single insertion point,
        # select the current node rather than advancing to the next node
        selectNode = parentCodeNode
      else
        # advance to the next code node
        matches = editableNode.querySelectorAll('code.var')
        matchIndex = -1
        for match, idx in matches
          if match is parentCodeNode
            matchIndex = idx
            break
        if matchIndex != -1 and matchIndex + delta >= 0 and matchIndex + delta < matches.length
          selectNode = matches[matchIndex+delta]

    if selectNode
      range.selectNode(selectNode)
      selection = document.getSelection()
      selection.removeAllRanges()
      selection.addRange(range)
      event.preventDefault()
      event.stopPropagation()

  @onInput: (editableNode, event) ->
    selection = document.getSelection()

    isWithinNode = (node) ->
      test = selection.baseNode
      while test isnt editableNode
        return true if test is node
        test = test.parentNode
      return false

    codeTags = editableNode.querySelectorAll('code.var.empty')
    for codeTag in codeTags
      if selection.containsNode(codeTag) or isWithinNode(codeTag)
        codeTag.classList.remove('empty')


module.exports = TemplatesDraftStoreExtension
