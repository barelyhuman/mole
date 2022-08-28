import std/[strutils, re]


var variableCharacters = re"^[a-zA-Z]"

var keywords = [
    "def",
    "loop",
    "print",
    "true",
    "false"
]

type
    TokenType = enum
        rootProgram,
        blockNodeDef,
        paramBlockNodeDef,
        varDefinitionNodeDef,
        leftBracket,
        rightBracket,
        identifier,
        literal,
        boolLiteral,
        numberLiteral
        stringLiteral,
        funcDef,
        varDef,
        funcIdentifierDef,
        loopDef,
        printDef,
    Token = object
        value: string
        tokenType: TokenType
    NodeRef = ref Node
    Node = object
        id: NodeRef
        parent: NodeRef
        value: string
        valueType: string
        nodeType: TokenType
        params: seq[NodeRef]
        children: seq[NodeRef]

var tokens: seq[Token]
var
    id = ""
    strLiteral = ""
    numLiteral = ""
    stringStack: seq[string]
    bracesStack: seq[string]
    flowerStack: seq[string]

proc debug(msg: string) =
    # echo "[debug]"&msg
    return

proc isKeyword(identifier: string): bool =
    for keywd in keywords:
        if identifier == keywd:
            return true
    return false

proc handleKeywordIdentifiers(identifier: string) =
    case identifier:
        of "loop":
            tokens.add(
                Token(
                    value: id,
                    tokenType: loopDef
                )
            )
        of "print":
            tokens.add(
                Token(
                    value: id,
                    tokenType: printDef
                )
            )
        of "def":
            tokens.add(
                Token(
                    value: id,
                    tokenType: funcDef
                )
            )
        of "true","false":
            tokens.add(
                Token(
                    value: identifier,
                    tokenType: boolLiteral
                )
            )
        else:
            return

proc characterAnalyse(line: string) =
    if len(line) == 0:
        return

    for i, chr in line:
        debug $chr
        case chr:
            of '+':
                tokens.add(
                        Token(
                            value: numLiteral,
                            tokenType: numberLiteral
                    )
                )
                numLiteral = ""
            of '"':
                debug "found string declaration"
                if stringStack.len > 0:
                    discard stringStack.pop()
                    tokens.add(
                        Token(
                            value: strLiteral,
                            tokenType: stringLiteral
                        )
                    )
                    strLiteral = ""
                else:
                    stringStack.add($chr)
            of '(':
                debug "adding to braces"
                bracesStack.add($chr)
                tokens.add(
                    Token(
                        value: $chr,
                        tokenType: leftBracket
                    )
                )

            of '{':
                debug "adding flower brace"
                flowerStack.add($chr)
                debug $flowerStack.len
                tokens.add(
                    Token(
                        value: $chr,
                        tokenType: leftBracket
                    )
                )

            of ')':
                debug "found ending brace,popping"
                if bracesStack.len == 0:
                    quit "error at" & line
                discard bracesStack.pop()
                tokens.add(
                    Token(
                        value: $chr,
                        tokenType: rightBracket
                    )
                )

            of '}':
                debug "found ending flower brace,popping"
                debug $flowerStack
                if flowerStack.len == 0:
                    quit "error at" & line
                discard flowerStack.pop()
                tokens.add(
                    Token(
                        value: $chr,
                        tokenType: rightBracket
                    )
                )
            of ':':
                if i+1 <= line.len-1 and line[i+1] == '=':
                    tokens.add(
                        Token(
                            value: ":=",
                            tokenType: varDef
                        )
                    )
            else:
                # possibly inside a string, let it take up
                # everything till the end of string
                if stringStack.len > 0:
                    strLiteral = strLiteral & $chr
                    debug "strLiteral:" & strLiteral
                elif match($chr, re"\d"):
                    numLiteral = numLiteral & $chr
                # if not then check if it's a variable that's
                # being used, mark as an identifier
                elif match($chr, variableCharacters):
                    id = id & chr
                    if i+1 > line.len-1:
                        if isKeyword(id):
                            handleKeywordIdentifiers(id)
                            id = ""
                        else:
                            tokens.add(
                                Token(
                                    value: id,
                                    tokenType: identifier
                                )
                            )
                            id = ""
                    elif not match($line[i+1], variableCharacters):
                        if isKeyword(id):
                            handleKeywordIdentifiers(id)
                            id = ""
                        else:
                            tokens.add(
                                Token(
                                    value: id,
                                    tokenType: identifier
                                )
                            )
                            id = ""





proc printAST(ast: NodeRef, prefix: string = "-") =
    var printable = ""
    printable = printable & prefix & " " & $ast.nodeType
    if len(ast.value) > 0:
        printable = printable & " : " & ast.value
    echo printable
    for child in ast.children:
        printAST(child, prefix & "-")

proc constructAST() =
    var program: NodeRef
    new(program)
    program.nodeType = rootProgram

    var nodeStack: seq[NodeRef]
    nodeStack.add(program)

    for i, tok in tokens:
        case tok.tokenType:
            of leftBracket:
                var blockNode: NodeRef
                new(blockNode)

                if tok.value == "(":
                    blockNode.nodeType = paramBlockNodeDef
                if tok.value == "{":
                    blockNode.nodeType = blockNodeDef

                blockNode.parent = nodeStack[nodeStack.high]
                blockNode.parent.children.add(blockNode)
                nodeStack.add(blockNode)

            of rightBracket:
                discard nodeStack.pop()
                discard nodeStack.pop()

            of loopDef:
                var loopNode: NodeRef
                new(loopNode)
                loopNode.nodeType = loopDef
                loopNode.parent = nodeStack[nodeStack.high]
                loopNode.parent.children.add(
                    loopNode
                )
                nodeStack.add(loopNode)
            of printDef:
                var printNode: NodeRef
                new(printNode)
                printNode.nodeType = printDef
                printNode.parent = nodeStack[nodeStack.high]
                printNode.parent.children.add(
                    printNode
                )
                nodeStack.add(printNode)
            of funcDef:
                var funcNode: NodeRef
                new(funcNode)
                funcNode.nodeType = funcDef
                funcNode.parent = nodeStack[nodeStack.high]
                funcNode.parent.children.add(
                    funcNode
                )
                nodeStack.add(funcNode)
            of varDef:
                var varDefNode: NodeRef
                new(varDefNode)
                varDefNode.nodeType = varDef
                varDefNode.parent = nodeStack[nodeStack.high]
                varDefNode.parent.children.add(
                    varDefNode
                )
                nodeStack.add(varDefNode)

                var varDefinitionNode: NodeRef
                new(varDefinitionNode)
                varDefinitionNode.nodeType = varDefinitionNodeDef
                varDefinitionNode.parent = nodeStack[nodeStack.high]
                varDefinitionNode.parent.children.add(
                    varDefinitionNode
                )
                nodeStack.add(varDefinitionNode)
            of identifier:
                var idNode: NodeRef
                new(idNode)
                idNode.nodeType = identifier
                idNode.value = tok.value
                idNode.parent = nodeStack[nodeStack.high]

                if idNode.parent.nodeType == funcDef:
                    idNode.nodeType = funcIdentifierDef

                idNode.parent.children.add(
                    idNode
                )

            of stringLiteral:
                var sLiteralNode: NodeRef
                new(sLiteralNode)
                sLiteralNode.nodeType = stringLiteral
                sLiteralNode.value = tok.value
                sLiteralNode.parent = nodeStack[nodeStack.high]

                if sLiteralNode.parent.nodeType == varDef:
                    discard nodeStack.pop()
                if sLiteralNode.parent.nodeType == varDefinitionNodeDef:
                    discard nodeStack.pop()
                    discard nodeStack.pop()

                sLiteralNode.parent.children.add(
                    sLiteralNode
                )
            of numberLiteral:
                var nLiteralNode: NodeRef
                new(nLiteralNode)
                nLiteralNode.nodeType = numberLiteral
                nLiteralNode.value = tok.value
                nLiteralNode.parent = nodeStack[nodeStack.high]
                nLiteralNode.parent.children.add(
                    nLiteralNode
                )
            of boolLiteral:
                var boolLiteralNode: NodeRef
                new(boolLiteralNode)
                boolLiteralNode.nodeType = boolLiteral
                boolLiteralNode.value = tok.value
                boolLiteralNode.parent = nodeStack[nodeStack.high]
                boolLiteralNode.parent.children.add(
                    boolLiteralNode
                )
            else:
                continue
                # echo "dancing"

    printAST(program)


proc main() =
    var
        fname = "./example/main.mole"

    for line in lines fname:
        if line.isEmptyOrWhitespace():
            continue

        if line.startsWith("--"):
            # ignore comment parsing for now
            continue
        else:
            characterAnalyse(line)

    if len(strLiteral) > 0:
        tokens.add(
            Token(
                    value: strLiteral,
                    tokenType: stringLiteral
            )

        )
        strLiteral = ""

    if len(numLiteral) > 0:
        tokens.add(
            Token(
                    value: numLiteral,
                    tokenType: numberLiteral
            )
        )
        numLiteral = ""

    constructAST()

main()
